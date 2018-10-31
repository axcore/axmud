# Copyright (C) 2011-2018 A S Lewis
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program. If not,
# see <http://www.gnu.org/licenses/>.
#
#
# Games:Axmud::OtherWin::About
# The About window, showing Axmud quick help, licenses, etc
#
# Games::Axmud::OtherWin::Connect
# The Connections window, allowing the user to open a connection to a world
#
# Games::Axmud::OtherWin::ClientConsole
# The Client Console window, which can display system messages when there is no session running
#
# Games::Axmud::OtherWin::QuickInput
# The Quick Input window, containing a textview in which the user can type text, and some widgets to
#   specify what should be done with the text
#
# Games::Axmud::OtherWin::QuickWord
# The Quick Word window, containing various widgets for adding words to the current dictionary
#
# Games::Axmud::OtherWin::SessionConsole
# The Session Console window, which can display system messages when it's not possible to display
#   them in the 'main' window
#
# Games::Axmud::OtherWin::Simulate
# The Simulate window, allowing the user to simulates various things, such as receiving text from a
#   world
#
# Games::Axmud::OtherWin::SourceCode
# The Source Code Viewer window, containing a textview to show the source code for a world model
#   object
#
# Games::Axmud::OtherWin::Viewer
# The object viewer window

{ package Games::Axmud::OtherWin::About;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the About window, which displays information usually displayed
        #   by the ';about' command, as well as credits, quick help and the GPL/LGPL licenses
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       'first_tab' => The tab to open when the window is created - 'about',
        #                           'credits', 'help', 'license' or 'license_2'. If not specified or
        #                           'undef', the first tab is opened
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Local variables
        my ($widthPixels, $heightPixels);

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Only one About window can be open at a time
        if ($axmud::CLIENT->aboutWin) {

            $axmud::CLIENT->aboutWin->restoreFocus();
            return undef;
        }

        # Set the window size. Use a slightly smaller window than the default, unless the user has
        #   specified their own default size, in which case use that
        if ($axmud::CLIENT->customFreeWinWidth == $axmud::CLIENT->constFreeWinWidth) {
            $widthPixels = $axmud::CLIENT->constFreeWinWidth - 50;
        } else {
            $widthPixels = $axmud::CLIENT->customFreeWinWidth;
        }

        if ($axmud::CLIENT->customFreeWinHeight == $axmud::CLIENT->constFreeWinHeight) {
            $heightPixels = $axmud::CLIENT->constFreeWinHeight - 50;
        } else {
            $heightPixels = $axmud::CLIENT->customFreeWinHeight;
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (for some 'free' windows, the same as the window type)
            winName                     => 'about',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,       # Gtk2::VBox

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $widthPixels,
            heightPixels                => $heightPixels,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $axmud::SCRIPT . ' information',
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # IVs for this type of window

            # Widgets
            notebook                    => undef,       # Gtk2::Notebook
            button                      => undef,       # Gtk2::Button
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

    sub winEnable {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->winSetup
        # After the Gtk2::Window has been setup and moved into position, makes it visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my $firstTab;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

        # This type of window is unique (only one can be open at any time); inform the GA::Client
        #   it has opened
        $axmud::CLIENT->set_aboutWin($self);

        # If a tab to show on startup was specified, open it
        $firstTab = $self->ivShow('configHash', 'first_tab');
        if (defined $firstTab) {

            # (Window is open at the 'about' tab by default, so we don't have to check that
            #   $firstTab is set to 'about')
            if ($firstTab eq 'credits') {
                $self->notebook->set_current_page(1);
            } elsif ($firstTab eq 'help') {
                $self->notebook->set_current_page(2);
            } elsif ($firstTab eq 'peek') {
                $self->notebook->set_current_page(3);
            } elsif ($firstTab eq 'changes') {
                $self->notebook->set_current_page(4);
            } elsif ($firstTab eq 'install') {
                $self->notebook->set_current_page(5);
            } elsif ($firstTab eq 'license') {
                $self->notebook->set_current_page(6);
            } elsif ($firstTab eq 'license_2') {
                $self->notebook->set_current_page(7);
            }
        }

        return 1;
    }

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

    sub winDestroy {

        # Can be called by anything
        # Updates IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the window can't be destroyed or if it has already
        #       been destroyed
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDestroy', @_);
        }

        if (! $self->winBox) {

            # Window already destroyed in a previous call to this function
            return undef;
        }

        # Close any 'free' windows for which this window is a parent
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Destroy the Gtk2::Window
        eval { $self->winBox->destroy(); };
        if ($@) {

            # Window can't be destroyed
            return undef;

        } else {

            $self->ivUndef('winWidget');
            $self->ivUndef('winBox');
        }

        # Inform the owner and the desktop object of this 'free' window's demise
        $axmud::CLIENT->desktopObj->del_freeWin($self);
        if ($self->owner) {

            $self->owner->del_childFreeWin($self);
        }

        # This type of window is unique (only one can be open at any time); inform the GA::Client
        #   it has closed
        $axmud::CLIENT->set_aboutWin();

        return 1;
    }

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the About window with its standard widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $file, $fileHandle,
            @aboutList, @helpList, @peekList, @changesList, @installList, @licenseList,
            @license2List,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # Create an image on the left
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_start($hBox, TRUE, TRUE, 0);

        my $vBox = Gtk2::VBox->new(FALSE, 0);
        $hBox->pack_start($vBox, FALSE, FALSE, 0);

        my $frame = Gtk2::Frame->new(undef);
        $vBox->pack_start($frame, FALSE, FALSE, 0);
        $frame->set_size_request(64, 64);
        $frame->set_shadow_type('etched-in');

        my $image = Gtk2::Image->new_from_file($axmud::CLIENT->getDialogueIcon());
        $frame->add($image);

        # Create a notebook on the right
        my $notebook = Gtk2::Notebook->new();
        $hBox->pack_start($notebook, TRUE, TRUE, $self->spacingPixels);
        $notebook->set_scrollable(TRUE);

        # Create a button at the bottom
        my $hBox2 = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_end($hBox2, FALSE, FALSE, 0);

        # The button's label includes some extra space characters to make it a little easier to
        #   click on
        my $button = Gtk2::Button->new('  OK  ');
        $hBox2->pack_end($button, FALSE, FALSE, 0);
        $button->signal_connect('clicked' => sub {

            $self->winDestroy();
        });

        # Add the 'about' tab to the notebook
        push (@aboutList,
            $axmud::SCRIPT . ' v' . $axmud::VERSION . ' (' . $axmud::DATE . ') by '
            . $axmud::AUTHORS,
            $axmud::COPYRIGHT,
            'Website: ' . $axmud::URL,
            ' ',                                # Empty line
            @axmud::LICENSE_LIST,
        );

        $self->addTab($notebook, '_About', TRUE, @aboutList);

        # Add the 'credits' tab to the notebook
        $self->addTab($notebook, '_Credits', TRUE, @axmud::CREDIT_LIST);

        # Load the quick help file
        $file = $axmud::SHARE_DIR . '/help/misc/quickhelp';
        if (! (-e $file)) {

            push (@helpList, 'Quick help file missing');

        } else {

            if (! open($fileHandle, $file)) {

                push (@helpList, 'Unable to read quick help file');

            } else {

                @helpList = <$fileHandle>;
                close($fileHandle);
            }
        }

        # Add the 'help' tab to the notebook
        $self->addTab($notebook, 'Quick _help', FALSE, @helpList);

        # Load the peek/poke help file
        $file = $axmud::SHARE_DIR . '/help/misc/peekpoke';
        if (! (-e $file)) {

            push (@peekList, 'Peek/poke help file missing');

        } else {

            if (! open($fileHandle, $file)) {

                push (@peekList, 'Unable to read peek/poke help file');

            } else {

                @peekList = <$fileHandle>;
                close($fileHandle);
            }
        }

        # Add the 'peek/poke' tab to the notebook
        $self->addTab($notebook, '_Peek/Poke', FALSE, @peekList);

        # Load the CHANGES file
        $file = $axmud::SHARE_DIR . '/../CHANGES';
        if (! (-e $file)) {

            push (@peekList, 'Changes file missing');

        } else {

            if (! open($fileHandle, $file)) {

                push (
                    @changesList,
                    'Unable to read changes file',
                );

            } else {

                @changesList = <$fileHandle>;
                close($fileHandle);
            }
        }

        # Add the 'changes' tab to the notebook
        $self->addTab($notebook, 'Cha_nges', FALSE, @changesList);

        # Load the INSTALL file
        $file = $axmud::SHARE_DIR . '/../INSTALL';
        if (! (-e $file)) {

            push (@peekList, 'Install file missing');

        } else {

            if (! open($fileHandle, $file)) {

                push (
                    @installList,
                    'Unable to read install file',
                );

            } else {

                @installList = <$fileHandle>;
                close($fileHandle);
            }
        }

        # Add the 'install' tab to the notebook
        $self->addTab($notebook, '_Installation', FALSE, @installList);

        # Load the GPL license file
        $file = $axmud::SHARE_DIR . '/../COPYING';
        if (! (-e $file)) {

            push (@licenseList, 'License file missing. Go to <http://www.gnu.org/licenses/>');

        } else {

            if (! open($fileHandle, $file)) {

                push (
                    @licenseList,
                    'Unable to read license file. Go to <http://www.gnu.org/licenses/>',
                );

            } else {

                @licenseList = <$fileHandle>;
                close($fileHandle);
            }
        }

        # Add the 'license' tab to the notebook
        $self->addTab($notebook, '_GPL License', FALSE, @licenseList);

        # Load the LGPL license file
        $file = $axmud::SHARE_DIR . '/../COPYING.LESSER';
        if (! (-e $file)) {

            push (@license2List, 'License file missing. Go to <http://www.gnu.org/licenses/>');

        } else {

            if (! open($fileHandle, $file)) {

                push (
                    @license2List,
                    'Unable to read license file. Go to <http://www.gnu.org/licenses/>',
                );

            } else {

                @license2List = <$fileHandle>;
                close($fileHandle);
            }
        }

        # Add the 'license' tab to the notebook
        $self->addTab($notebook, '_LGPL License', FALSE, @license2List);

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('notebook', $notebook);
        $self->ivPoke('button', $button);

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub addTab {

        # Called by $self->drawWidgets
        # Adds a tab to the About window's notebook
        #
        # Expected arguments
        #   $notebook       - The Gtk2::Notebook to which the tab must be added
        #   $label          - The tab's label text
        #
        # Optional arguments
        #   $newlineFlag    - TRUE if a newline character should be added to every line in @list,
        #                       FALSE if not (because the contents of @list were loaded from a file
        #                       and already contain newline characters)
        #   @list           - A list of lines to add to the Gtk2::TextView (can be an empty list)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $notebook, $label, $newlineFlag, @list) = @_;

        # Check for improper arguments
        if (! defined $notebook || ! defined $label) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addTab', @_);
        }

        # Add the tab
        my $tab = Gtk2::Label->new_with_mnemonic($label);

        my $scroller = Gtk2::ScrolledWindow->new();
        $notebook->append_page($scroller, $tab);
        $scroller->set_policy('automatic', 'automatic');

        # Create a textview using the system's preferred colours and fonts
        my $textView = Games::Axmud::Widget::TextView::Gtk2->new();
        $scroller->add_with_viewport($textView);
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);
        $textView->set_editable(FALSE);
        $textView->set_cursor_visible(FALSE);

        # Fill the textview
        if (! $newlineFlag) {
            $buffer->set_text(join("", @list));
        } else {
            $buffer->set_text(join("\n", @list));
        }

        return 1
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub notebook
        { $_[0]->{notebook} }
    sub button
        { $_[0]->{button} }
}

{ package Games::Axmud::OtherWin::Connect;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Connections window, which displays a list of world
        #   profiles and invites the user to connect to one of them
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Local variables
        my ($widthPixels, $heightPixels);

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Only one Connections window can be open at a time
        if ($axmud::CLIENT->connectWin) {

            $axmud::CLIENT->connectWin->restoreFocus();
            return undef;
        }

        # Set the window size. Use a slightly smaller window than the default, unless the user has
        #   specified their own default size, in which case use that
        if ($axmud::CLIENT->customFreeWinWidth == $axmud::CLIENT->constFreeWinWidth) {

            $widthPixels = $axmud::CLIENT->customFreeWinWidth + 50;

        } else {

            # (Adjust the additional 50 pixels by the same ratio)
            $widthPixels = $axmud::CLIENT->customFreeWinWidth + (
                50 * int($axmud::CLIENT->customFreeWinWidth / $axmud::CLIENT->constFreeWinWidth)
            );
        }

        $heightPixels = $axmud::CLIENT->customFreeWinHeight;

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (for some 'free' windows, the same as the window type)
            winName                     => 'connect' ,
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $widthPixels,
            heightPixels                => $heightPixels,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $axmud::SCRIPT . ' Connections',
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # IVs for this type of window

            # Widgets
            hPaned                      => undef,       # Gtk2::HPaned
            # Left section widgets
            vBox                        => undef,       # Gtk2::VBox
            frame                       => undef,       # Gtk2::Frame
            image                       => undef,       # Gtk2::Image
            hBox                        => undef,       # Gtk2::HBox
            objModel                    => undef,       # Gtk2::TreeStore
            treeView                    => undef,       # Gtk2::TreeView
            treeViewColumn              => undef,       # Gtk2::TreeViewColumn
            scroller                    => undef,       # Gtk2::ScrolledWindow
            # Right section widgets
            scroller2                   => undef,       # Gtk2::ScrolledWindow
            table                       => undef,       # Gtk2::Table
            # Strip widgets
            preConfigButton             => undef,       # Gtk2::RadioToolButton
            otherWorldButton            => undef,       # Gtk2::RadioToolButton
            sortAzButton                => undef,       # Gtk2::RadioToolButton
            sortZaButton                => undef,       # Gtk2::RadioToolButton
            sortRandButton              => undef,       # Gtk2::RadioToolButton
            searchButton                => undef,       # Gtk2::Button
            cancelSearchButton          => undef,       # Gtk2::Button
            consoleButton               => undef,       # Gtk2::Button
            # Table widgets
            entry                       => undef,       # Gtk2::Entry
            entry2                      => undef,       # Gtk2::Entry
            entry3                      => undef,       # Gtk2::Entry
            radioButton                 => undef,       # Gtk2::RadioButton
            radioButton2                => undef,       # Gtk2::RadioButton
            radioButton3                => undef,       # Gtk2::RadioButton
            radioButton4                => undef,       # Gtk2::RadioButton
            checkButton                 => undef,       # Gtk2::CheckButton
            comboBox                    => undef,       # Gtk2::ComboBox
            addCharButton               => undef,       # Gtk2::Button
            editPwdButton               => undef,       # Gtk2::Button
            editAccButton               => undef,       # Gtk2::Button
            websiteLabel                => undef,       # Gtk2::Label
            connectionLabel             => undef,       # Gtk2::Label
            descripTextView             => undef,       # Gtk2::TextView
            descripBuffer               => undef,       # Gtk2::TextBuffer
            createWorldButton           => undef,       # Gtk2::Button
            resetWorldButton            => undef,       # Gtk2::Button
            offlineButton               => undef,       # Gtk2::Button
            connectButton               => undef,       # Gtk2::Button

            # Tooltips widget used by all buttons
            tooltips                    => undef,       # Gtk2::Tooltips

            # Path to the default icon to use in the top-left corner
            defaultIcon                 => $axmud::CLIENT->getClientLogo(),
            # The size of the image containing each world's icon (or the default icon)
            imageWidth                  => 300,
            imageHeight                 => 200,
            # Standard size of the Gtk2::Table used (a 12x12 table, with a spare cell around every
            #   border)
            tableWidth                  => 13,
            tableHeight                 => 13,

            # A hash linking all the world names listed in the treeview to their corresponding
            #   world profile object. Hash in the form
            #       $worldHash{name} = blessed_reference_to_world_profile
            # ...where 'name' can be the world's ->name or its ->longName, depending on how it was
            #   displayed in the treeview
            # NB ->worldHash also contains an entry in the form
            #       $worldHash{create_new_world_string} = undef;
            worldHash                   => {},
            # A hash of GA::Obj::MiniWorld objects, which store changes made to the profiles in the
            #   Connections window until it's time to copy them into the main world profile object.
            #   Hash in the form
            #       $miniWorldHash{profile} = blessed_reference_to_the_mini_world_object
            miniWorldHash               => {},
            # The GA::Profile::World that's currently displayed in the window. If the user is
            #   creating a new world from here, set to 'undef' (even if the entry box for the new
            #   world's name contains text)
            worldObj                    => undef,
            # The GA::Obj::MiniWorld that stores the changes being made by the user to the table
            #   widgets. For an existing world profile, the mini-world exists in $self->worldHash;
            #   otherwise it's a temporary GA::Obj::MiniWorld that might (or might not) be stored as
            #   a world profile, at some point
            miniWorldObj                => undef,
            # Flag set to TRUE when $self->resetTableWidgets or $self->updateTableWidgets are
            #   changing the value displayed in the table widgets; this stops the mini-world object
            #   from being modified (the mini-world object should only store changes made by the
            #   user)
            updateFlag                  => undef,

            # First line displayed in the Gtk2::TreeView
            newWorldString              => '<b><i>Create new world</i></b>',
            # First line displayed in the Gtk2::ComboBox
            noCharString                => '<no character>',
            # First line displayed in 'information' section
            noWebsiteString             => 'Websites: (no websites)',
            # Second line
            noConnectString             => 'Connections: 0',

            # Current search terms. If 'undef', all worlds are listed; otherwise, only those worlds
            #   matching one or both search terms are listed
            searchRegex                 => undef,
            searchLanguage              => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

    sub winEnable {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->winSetup
        # After the Gtk2::Window has been setup and moved into position, makes it visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

        # Fill the treeview
        $self->resetTreeView($self->treeView);

        # The 'connect' button should have focus
        $self->connectButton->grab_focus();

        # This type of window is unique (only one can be open at any time); inform the GA::Client
        #   it has opened
        $axmud::CLIENT->set_connectWin($self);

        return 1;
    }

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

    sub winDestroy {

        # Can be called by anything
        # Updates IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the window can't be destroyed or if it has already
        #       been destroyed
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDestroy', @_);
        }

        if (! $self->winBox) {

            # Window already destroyed in a previous call to this function
            return undef;
        }

        # Close any 'free' windows for which this window is a parent
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Destroy the Gtk2::Window
        eval { $self->winBox->destroy(); };
        if ($@) {

            # Window can't be destroyed
            return undef;

        } else {

            $self->ivUndef('winWidget');
            $self->ivUndef('winBox');
        }

        # Inform the owner and the desktop object of this 'free' window's demise
        $axmud::CLIENT->desktopObj->del_freeWin($self);
        if ($self->owner) {

            $self->owner->del_childFreeWin($self);
        }

        # This type of window is unique (only one can be open at any time); inform the GA::Client
        #   it has closed
        $axmud::CLIENT->set_connectWin();

        return 1;
    }

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the Connections window with its standard widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, $self->spacingPixels);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # Create a Gtk2::Tooltips object, used by various buttons
        my $tooltips = Gtk2::Tooltips->new();

        # Update IVs immediately, so various buttons can use the tooltips
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('tooltips', $tooltips);

        # Create a horizontal pane to divide the window in two, with an image/treeview on the
        #   left, and everything else on the right
        my $hPaned = Gtk2::HPaned->new();
        $packingBox->pack_start($hPaned, TRUE, TRUE, 0);

        # On the left, create a vertical packing box, with an image at the top, a strip of buttons
        #   in the middle and a treeview at the bottom
        my $vBox = Gtk2::VBox->new(FALSE, $self->spacingPixels);
        $hPaned->add1($vBox);

        # Create a frame containing an image
        my $frame = Gtk2::Frame->new(undef);
        $vBox->pack_start($frame, FALSE, FALSE, 0);
        $frame->set_border_width(3);
        my $image = Gtk2::Image->new_from_file($self->defaultIcon);
        $frame->add($image);

        # Create a strip of buttons
        my $hBox = Gtk2::HBox->new(FALSE, FALSE);
        $vBox->pack_start($hBox, FALSE, FALSE, 0);

        # Create a treeview
        my $objModel = Gtk2::TreeStore->new('Glib::String');
        my $treeView = Gtk2::TreeView->new($objModel);
        $treeView->set_enable_search(FALSE);
        $treeView->get_selection->signal_connect('changed' => sub {

            if (! $self->updateFlag) {

                my ($selection) = @_;

                $self->selectWorldCallback($selection);
            }
        });

        # Append a single column to the treeview
        my $treeViewColumn = Gtk2::TreeViewColumn->new_with_attributes(
            'Pre-configured and played worlds',
            Gtk2::CellRendererText->new,
            markup => 0,
        );

        $treeView->append_column($treeViewColumn);

        # Make the treeview scrollable
        my $scroller = Gtk2::ScrolledWindow->new();
        $vBox->pack_start($scroller, TRUE, TRUE, 0);
        $scroller->add($treeView);
        $scroller->set_policy(qw/automatic automatic/);

        # Respond to clicks on the treeview
        $treeView->get_selection->set_mode('browse');

        # Add a table on the right of the window, inside a scroller
        my $scroller2 = Gtk2::ScrolledWindow->new();
        $hPaned->add2($scroller2);
        $scroller2->set_policy(qw/automatic automatic/);

        my $table = Gtk2::Table->new($self->tableHeight, $self->tableWidth, FALSE);
        $scroller2->add_with_viewport($table);
        $table->set_col_spacings($self->spacingPixels);
        $table->set_row_spacings($self->spacingPixels);

        # Store the widgets as IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('hPaned', $hPaned);
        $self->ivPoke('vBox', $vBox);
        $self->ivPoke('frame', $frame);
        $self->ivPoke('image', $image);
        $self->ivPoke('hBox', $hBox);
        $self->ivPoke('objModel', $objModel);
        $self->ivPoke('treeView', $treeView);
        $self->ivPoke('treeViewColumn', $treeViewColumn);
        $self->ivPoke('scroller', $scroller);
        $self->ivPoke('scroller2', $scroller2);
        $self->ivPoke('table', $table);
        $self->ivPoke('tooltips', $tooltips);

        # Add buttons to the button strip
        $self->createStripButtons();
        # Add various widgets to the Gtk2::Table
        $self->createTableWidgets();

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub createStripButtons {

        # Called by $self->drawWidgets
        # Draws widgets in the button strip on the left of the window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $allString,
            @comboList,
            %hash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createStripButtons', @_);
        }

        # Compile a list of languages used by all basic world objects. Put 'English' at the top
        #   because most basic worlds use it
        foreach my $basicObj ($axmud::CLIENT->ivValues('constBasicWorldHash')) {

            if ($basicObj->language && $basicObj->language ne 'English') {

                $hash{$basicObj->language} = undef;
            }
        }

        @comboList = sort {lc($a) cmp lc($b)} (keys %hash);
        unshift (@comboList, 'English');

        $allString = '<all languages>';
        unshift (@comboList, $allString);

        # Add widgets
        my $button = Gtk2::RadioToolButton->new(undef);
        $self->hBox->pack_start($button, FALSE, FALSE, 0);
        $button->set_active(TRUE);
        $button->set_icon_widget(
            Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_config.png')
        );
        $button->set_label('PC');
        $button->set_tooltip_text('Pre-configured and played worlds');
        $button->signal_connect('toggled' => sub {

            if ($button->get_active()) {

                $self->resetTreeView();
            }
        });

        my $button2 = Gtk2::RadioToolButton->new($button);
        $self->hBox->pack_start($button2, FALSE, FALSE, 0);
        $button2->set_icon_widget(
            Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_other.png')
        );
        $button2->set_label('Other');
        $button2->set_tooltip_text('Other worlds');
        $button2->signal_connect('toggled' => sub {

            if ($button2->get_active()) {

                $self->resetTreeView();
            }
        });

        my $separator = Gtk2::SeparatorToolItem->new();
        $self->hBox->pack_start($separator, TRUE, TRUE, 0);

        my $button3 = Gtk2::RadioToolButton->new(undef);
        $self->hBox->pack_start($button3, FALSE, FALSE, 0);
        $button3->set_icon_widget(
            Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_sort_a.png')
        );
        $button3->set_active(TRUE);
        $button3->set_label('az');
        $button3->set_tooltip_text('Sort A-Z');
        $button3->signal_connect('toggled' => sub {

            if ($button3->get_active()) {

                $self->resetTreeView();
            }
        });

        my $button4 = Gtk2::RadioToolButton->new($button3);
        $self->hBox->pack_start($button4, FALSE, FALSE, 0);
        $button4->set_icon_widget(
            Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_sort_z.png')
        );
        $button4->set_label('za');
        $button4->set_tooltip_text('Sort Z-A');
        $button4->signal_connect('toggled' => sub {

            if ($button4->get_active()) {

                $self->resetTreeView();
            }
        });

        my $button5 = Gtk2::RadioToolButton->new($button4);
        $self->hBox->pack_start($button5, FALSE, FALSE, 0);
        $button5->set_icon_widget(
            Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_sort_random.png')
        );
        $button5->set_label('rnd');
        $button5->set_tooltip_text('Sort randomly');
        $button5->signal_connect('toggled' => sub {

            if ($button5->get_active()) {

                $self->resetTreeView();
            }
        });
        # (Allow multiple re-clicking of the random button)
        $button5->signal_connect('clicked' => sub {

            if ($button5->get_active()) {

                $self->resetTreeView();
            }
        });

        my $separator2 = Gtk2::SeparatorToolItem->new();
        $self->hBox->pack_start($separator2, TRUE, TRUE, 0);

        my $button6 = Gtk2::Button->new();
        $self->hBox->pack_start($button6, FALSE, FALSE, 0);
        $button6->set_image(
            Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_search.png')
        );
        $button6->set_tooltip_text('Search worlds');
        $button6->signal_connect('clicked' => sub {

            # Open a dialogue window
            my ($regex, $language) = $self->showEntryComboDialogue(
                'Search worlds',
                'Enter a search pattern:',
                '(And/or) search by language:',
                \@comboList,
            );

            if (! defined $regex) {

                # Cancel search terms
                $self->ivUndef('searchRegex');
                $self->ivUndef('searchLanguage');

            } else {

                # Apply search terms
                if ($regex eq '') {
                    $self->ivUndef('searchRegex');
                } else {
                    $self->ivPoke('searchRegex', $regex);
                }

                if ($language eq $allString) {
                    $self->ivUndef('searchLanguage');
                } else {
                    $self->ivPoke('searchLanguage', $language);
                }
            }

            # Update the treeview
            $self->resetTreeView();

            # Update the button icon
            if (! defined $self->searchRegex && ! defined $self->searchLanguage) {

                $button6->set_image(
                    Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_search.png')
                );

            } else {

                $button6->set_image(
                    Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_apply.png')
                );
            }
        });

        my $button7 = Gtk2::Button->new();
        $self->hBox->pack_start($button7, FALSE, FALSE, 0);
        $button7->set_image(
            Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_clear.png')
        );
        $button7->set_tooltip_text('Cancel search');
        $button7->signal_connect('clicked' => sub {

            # Cancel search terms
            $self->ivUndef('searchRegex');
            $self->ivUndef('searchLanguage');

            # Update the treeview
            $self->resetTreeView();

            # Update the button icon
            $button6->set_image(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_search.png')
            );
        });

        my $button8 = Gtk2::Button->new();
        $self->hBox->pack_start($button8, FALSE, FALSE, 0);

        if (! $axmud::CLIENT->systemMsgList) {

            $button8->set_image(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_console.png')
            );

        } else {

            $button8->set_image(
                Gtk2::Image->new_from_file(
                    $axmud::SHARE_DIR . '/icons/connect/icon_console_alert.png',
                )
            );
        }

        $button8->set_tooltip_text('Show Client Console window');
        $button8->signal_connect('clicked' => sub {

            # Open an Client Console window
            $self->createFreeWin(
                'Games::Axmud::OtherWin::ClientConsole',
                $self,
                undef,      # No GA::Session
                undef,      # Let the window set its own title
            );
        });

        # Store the widgets as IVs
        $self->ivPoke('preConfigButton', $button);
        $self->ivPoke('otherWorldButton', $button2);
        $self->ivPoke('sortAzButton', $button3);
        $self->ivPoke('sortZaButton', $button4);
        $self->ivPoke('sortRandButton', $button5);
        $self->ivPoke('searchButton', $button6);
        $self->ivPoke('cancelSearchButton', $button7);
        $self->ivPoke('consoleButton', $button8);

        return 1;
    }

    sub createTableWidgets {

        # Called by $self->drawWidgets
        # Draws widgets in the table on the right of the window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createTableWidgets', @_);
        }

        $self->addLabel($self->table, '<i><u>World connection settings</u></i>',
            1, 8, 1, 2);
        if (@axmud::TEST_MODE_LOGIN_LIST) {

            # Button used for Axmud development, and only visible if the user has edited the
            #   contents of /scripts/axmud.pl or /scripts/baxmud.pl, in order to modify the global
            #   variable @TEST_MODE_LOGIN_LIST
            my $testButton = $self->addButton(
                $self->table,
                \&testModeCallback,
                'TEST MODE SETUP',
                'Use @TEST_MODE_LOGIN_LIST values',
                8, 12, 1, 2);
        }

        # GA::Profile::World ->name
        $self->addLabel($self->table, 'Name',
            1, 4, 2, 3);

        my $entry = $self->addEntry($self->table, undef, undef, TRUE,
            4, 12, 2, 3);
        $entry->signal_connect('changed' => sub {

            # If the text inside the entry changes, we record that fact by creating (or replacing) a
            #   key-value pair in $self->miniWorldObj. If the entry is emptied, we record that by
            #   removing the key-value pair.
            # However, when $self->resetTableWidgets and ->updateTableWidgets are changing all the
            #   table widgets (after the user selects a world from the treeview), $self->updateFlag
            #   is set to TRUE, and we don't make any changes to the mini-world object
            if (! $self->updateFlag) {

                my $text = $entry->get_text();

                if ($text) {
                    $self->miniWorldObj->ivAdd('propHash', 'name', $text);
                } else {
                    $self->miniWorldObj->ivDelete('propHash', 'name');
                }
            }
        });
        $self->tooltips->set_tip(
            $entry,
            'World profile name: maximum 16 characters; A-Z, a-z, 0-9 and underlines (not first'
            . ' character); must not be ' . $axmud::NAME_ARTICLE . ' reserved word',
        );

        # ->dns, ->ipv4 or ->ipv6
        $self->addLabel($self->table, 'Host',
            1, 4, 3, 4);
        my $entry2 = $self->addEntry($self->table, undef, undef, TRUE,
            4, 12, 3, 4);
        $entry2->signal_connect('changed' => sub {

            if (! $self->updateFlag) {

                my $text = $entry2->get_text();

                if ($text) {

                    $self->miniWorldObj->ivAdd('propHash', 'host', $text);
                    $self->addCharButton->set_sensitive(TRUE);
                    $self->offlineButton->set_sensitive(TRUE);
                    $self->connectButton->set_sensitive(TRUE);

                } else {

                    $self->miniWorldObj->ivDelete('propHash', 'host');
                    $self->addCharButton->set_sensitive(FALSE);
                    $self->offlineButton->set_sensitive(FALSE);
                    $self->connectButton->set_sensitive(FALSE);
                }
            }
        });
        $self->tooltips->set_tip($entry2, 'e.g. \'deathmud.com\'; using IPV4, IPV6 or DNS');

        # ->port
        $self->addLabel($self->table, 'Port',
            1, 4, 4, 5);
        my $entry3 = $self->addEntry($self->table, undef, undef, TRUE,
            4, 8, 4, 5, 5, 5);
        $self->tooltips->set_tip($entry3, 'e.g. 5000');
        $entry3->signal_connect('changed' => sub {

            if (! $self->updateFlag) {

                my $text = $entry3->get_text();

                if ($text) {
                    $self->miniWorldObj->ivAdd('propHash', 'port', $text);
                } else {
                    $self->miniWorldObj->ivDelete('propHash', 'port');
                }
            }
        });

        # ->protocol
        $self->addLabel($self->table, 'Protocol',
            1, 4, 5, 6);

        my ($group, $radioButton) = $self->addRadioButton(
            $self->table, undef, undef, 'Default', TRUE, TRUE,
            4, 6, 5, 6);

        my ($group2, $radioButton2) = $self->addRadioButton(
            $self->table, undef, $group, 'Telnet', FALSE, TRUE,
            6, 8, 5, 6);

        my ($group3, $radioButton3) = $self->addRadioButton(
            $self->table, undef, $group2, 'SSH', FALSE, TRUE,
            8, 10, 5, 6);

        my ($group4, $radioButton4) = $self->addRadioButton(
            $self->table, undef, $group3, 'SSL', FALSE, TRUE,
            10, 12, 5, 6);

        # ->passwordHash, ->accountHash, ->lastConnectChar, ->loginMode (etc)
        $self->addLabel($self->table, 'Character',
            1, 4, 6, 7);
        my $comboBox = $self->resetComboBox();

        my $checkButton = $self->addCheckButton($self->table, undef, FALSE, TRUE,
            8, 12, 6, 7);
        $checkButton->set_label('No auto-login');
        $checkButton->signal_connect('toggled' => sub {

            if (! $self->updateFlag) {

                # (The state of the checkbutton isn't stored as an IV in a world profile, so the
                #   mini-world object has a separate IV to store it)
                $self->miniWorldObj->ivPoke('noAutoLoginFlag', $checkButton->get_active());
            }
        });

        my $addCharButton = $self->addButton(
            $self->table,
            \&addCharCallback,
            'Add',
            'Add a new character profile',
            4, 6, 7, 8);

        my $editPwdButton = $self->addButton(
            $self->table,
            \&editPasswordCallback,
            'Password',
            'Edit the selected character\'s password',
            6, 8, 7, 8);

        my $editAccButton = $self->addButton(
            $self->table,
            \&editAccountCallback,
            'Account name',
            'Edit the selected character\'s associated account name',
            8, 12, 7, 8);

        my $websiteLabel = $self->addLabel($self->table, $self->noWebsiteString,
            1, 12, 8, 9);
        $websiteLabel->signal_connect('activate-link' => sub {

            my $link = $websiteLabel->get_current_uri();
            if ($link) {

                $axmud::CLIENT->openURL($link);
            }
        });

        my $connectionLabel = $self->addLabel($self->table, $self->noConnectString,
            1, 12, 9, 10);

        # ->worldDescrip
        my $descripTextView = $self->addTextView(
            $self->table,
            undef,
            undef,
            undef,
            FALSE,
            1, 12, 10, 11);
        my $descripBuffer = $descripTextView->get_buffer();
        # Don't want horizontal scrolling
        $descripTextView->set_wrap_mode('word-char');

        my $createWorldButton = $self->addButton(
            $self->table,
            undef,
            'Create world',
            'Create a world profile',
            1, 5, 11, 12);
        $createWorldButton->signal_connect('clicked' => sub {

            if (! $self->worldObj || $self->otherWorldButton->get_active()) {
                $self->createWorldCallback();
            } else {
                $self->applyChangesCallback();
            }
        });

        my $resetWorldButton = $self->addButton(
            $self->table,
            \&resetWorldCallback,
            'Reset world',
            'Reset the values displayed in this window to those actually stored by the selected'
            . ' world profile',
            5, 7, 11, 12);

        my $offlineButton = $self->addButton(
            $self->table,
            undef,
            'Connect offline',
            'Connect to this world in \'offline\' mode',
            7, 10, 11, 12);
        $offlineButton->signal_connect('clicked' => sub {

            $self->connectWorldCallback(TRUE);
        });

        my $connectButton = $self->addButton(
            $self->table,
            undef,
            # (Add a bit of space, so the Connect button isn't much smaller than the other 3)
            '   Connect   ',
            'Connect to this world',
            10, 12, 11, 12);
        $connectButton->signal_connect('clicked' => sub {

            $self->connectWorldCallback(FALSE);
        });

        # Store the widgets as IVs
        $self->ivPoke('entry', $entry);
        $self->ivPoke('entry2', $entry2);
        $self->ivPoke('entry3', $entry3);
        $self->ivPoke('radioButton', $radioButton);
        $self->ivPoke('radioButton2', $radioButton2);
        $self->ivPoke('radioButton3', $radioButton3);
        $self->ivPoke('radioButton4', $radioButton4);
        $self->ivPoke('checkButton', $checkButton);
        $self->ivPoke('comboBox', $comboBox);
        $self->ivPoke('addCharButton', $addCharButton);
        $self->ivPoke('editPwdButton', $editPwdButton);
        $self->ivPoke('editAccButton', $editAccButton);
        $self->ivPoke('websiteLabel', $websiteLabel);
        $self->ivPoke('connectionLabel', $connectionLabel);
        $self->ivPoke('descripTextView', $descripTextView);
        $self->ivPoke('descripBuffer', $descripBuffer);
        $self->ivPoke('createWorldButton', $createWorldButton);
        $self->ivPoke('resetWorldButton', $resetWorldButton);
        $self->ivPoke('offlineButton', $offlineButton);
        $self->ivPoke('connectButton', $connectButton);

        return 1;
    }

    sub resetTreeView {

        # Called by $self->winEnable, ->createWorldCallback, ->applyChangesCallback and
        #   ->resetWorldCallback
        # Fills the object tree on the left of the window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $treeView       - The GTK::TreeView object just created (if 'undef', $self->treeView is
        #                       used)
        #   $selectWorld    - The world to select (if 'undef', this function chooses which world to
        #                       select). Only applied when the list of pre-configured worlds is
        #                       displayed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $treeView, $selectWorld, $check) = @_;

        # Local variables
        my (
            $displayFlag, $sortMode, $regex, $model, $matchPointer, $treeSelection,
            @faveList, @otherList, @objList, @initList, @displayList,
            %worldHash, %nameHash, %checkHash, %displayHash, %miniWorldHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetTreeView', @_);
        }

        # Set the Gtk2::TreeView, if not specified
        if (! $treeView) {

            $treeView = $self->treeView;
        }

        # Decide which list should be displayed. Default display mode is 'undef', representing
        #   a list of world profiles
        if ($self->otherWorldButton->get_active()) {

            $displayFlag = TRUE;
        }

        # Update the treeview's title
        if (! $displayFlag) {
            $self->treeViewColumn->set_title('Pre-configured and played worlds');
        } else {
            $self->treeViewColumn->set_title('Other worlds');
        }

        # Decide how the worlds should be sorted
        if ($self->sortZaButton->get_active()) {
            $sortMode = 'za';
        } elsif ($self->sortRandButton->get_active()) {
            $sortMode = 'rand';
        } else {
            $sortMode = 'az';
        }

        if (! $displayFlag) {

            # Display list of world profiles

            # Import the hash of world profiles. If search terms have been applied, remove any
            #   worlds that don't match
            $regex = $self->searchRegex;
            foreach my $worldObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                my ($dictObj, $language);

                if ($worldObj->dict) {

                    $dictObj = $axmud::CLIENT->ivShow('dictHash', $worldObj->dict);
                    if ($dictObj) {

                        $language = $dictObj->language;
                    }
                }

                if (
                    (
                        ! defined $regex
                        || $worldObj->name =~ m/$regex/i
                        || $worldObj->longName =~ m/$regex/i
                    ) && (
                        ! defined $self->searchLanguage
                        || ($language && (lc($language) eq lc($self->searchLanguage)))
                    )
                ) {
                    $worldHash{$worldObj->name} = $worldObj;
                }
            }

            # For each world, decide which name to use. Create a hash in the form
            #   $nameHash{profile_name} = displayed_name
            #   (where 'displayed_name' is the long name, if available, or the profile name, if not)
            # At the same time, create a parallel hash to check for duplicate long names, in the
            #   form
            #       $checkHash{long_name} = profile_name
            # If duplicate long names are found, 'displayed_name' should include both the long name
            #   and the profile name
            foreach my $worldObj (values %worldHash) {

                my ($otherWorld, $otherWorldObj);

                if ($worldObj->longName) {

                    if ($worldObj->longName eq $self->newWorldString) {

                        $nameHash{$worldObj->name}
                            = $worldObj->longName . ' (' . $worldObj->name . ')';
                        $checkHash{$worldObj->longName} = $worldObj->name;

                    } elsif (exists $checkHash{$worldObj->longName}) {

                        # Amend both entries to include the long name and the profile name
                        $otherWorld = $checkHash{$worldObj->longName};
                        $otherWorldObj = $worldHash{$otherWorld};

                        $nameHash{$worldObj->name}
                            = $worldObj->longName . ' (' . $worldObj->name . ')';
                        # (There's already an entry in $checkHash matching ->longName)
                        $nameHash{$otherWorld}
                            = $otherWorldObj->longName . ' (' . $otherWorldObj->name . ')';

                    } else {

                        # Not a duplicate, so just display the long name
                        $nameHash{$worldObj->name} = $worldObj->longName;
                        $checkHash{$worldObj->longName} = $worldObj->name;
                    }

                } else {

                    # Just display the profile name
                    $nameHash{$worldObj->name} = $worldObj->name;
                }
            }

            # Remove all favourite worlds from %worldHash, so they can be displayed first
            foreach my $name ($axmud::CLIENT->favouriteWorldList) {

                if (exists $worldHash{$name}) {

                    push (@faveList, $worldHash{$name});
                    delete $worldHash{$name};

                    # If $selectWorld was not specified, the first world in the favourite world list
                    #   should be selected
                    if (! $selectWorld) {

                        $selectWorld = $name;
                    }
                }
            }

            # Now sort the remaining world profiles by frequency of usage (and then, alphabetically
            #   or randomly, depending on which radio buttons are active)
            @otherList = sort {

                my $aName = lc($nameHash{$a->name});
                my $bName = lc($nameHash{$b->name});

                # Sort, ignoring initial articles. Don't bother ignoring articles in languages other
                #   than English, because the basic mudlist contains only a couple of items that
                #   would be affected
                $aName =~ s/^(the|a)\s//;
                $bName =~ s/^(the|a)\s//;

                if ($a->numberConnects > $b->numberConnects) {
                    -1;
                } elsif ($b->numberConnects > $a->numberConnects) {
                    1;
                } elsif ($sortMode eq 'az') {
                    $aName cmp $bName;
                } elsif ($sortMode eq 'za') {
                    $bName cmp $aName;
                } elsif (int(rand(2))) {
                    -1;
                } else {
                    1;
                }

            } (values %worldHash);

            # Combine the two lists, with favourite worlds first, followed by everything else
            @objList = (@faveList, @otherList);

            # Worlds that have never been connected should be shown in italics
            foreach my $worldObj (@objList) {

                my $displayName = $nameHash{$worldObj->name};

                if (! $worldObj->numberConnects) {

                    $displayName = "<i>" . $displayName . "</i>";
                }

                push (@displayList, $displayName);
                $displayHash{$displayName} = $worldObj;
            }

        } else {

            # Display basic mudlist

            # Display basic mudlist, sorted alphabetically or randomly, depending on which radio
            #   buttons are active)
            @initList = sort {

                my $aName = lc($a->longName);
                my $bName = lc($b->longName);

                # Sort, ignoring initial articles. Don't bother ignoring articles in languages other
                #   than English, because the basic mudlist contains only a couple of items that
                #   would be affected
                $aName =~ s/^(the|a)\s//;
                $bName =~ s/^(the|a)\s//;

                if ($sortMode eq 'az') {
                    $aName cmp $bName;
                } elsif ($sortMode eq 'za') {
                    $bName cmp $aName;
                } elsif (int(rand(2))) {
                    -1;
                } else {
                    1;
                }

            } ($axmud::CLIENT->ivValues('constBasicWorldHash'));

            # Remove any worlds for which a world profile actually exists (the same world shouldn't
            #   appear in both lists)
            # If any search terms have been applied, remove any worlds that don't match
            $regex = $self->searchRegex;
            foreach my $obj (@initList) {

                if (
                    (
                        ! $axmud::CLIENT->ivExists('worldProfHash', $obj->name)
                    ) && (
                        ! defined $regex
                        || $obj->name =~ m/$regex/i
                        || $obj->longName =~ m/$regex/i
                    ) && (
                        ! defined $self->searchLanguage
                        || lc($obj->language) eq lc($self->searchLanguage)
                    )
                ) {
                    push (@objList, $obj);
                }
            }

            # All worlds should be in italics
            foreach my $obj (@objList) {

                my $displayName = "<i>" . $obj->longName . "</i>";

                push (@displayList, $displayName);
                $displayHash{$displayName} = $obj;
            }
        }

        # The first item in the list should be a 'create new world' string
        unshift (@displayList, $self->newWorldString);
        $displayHash{$self->newWorldString} = undef;     # Not linked to a world profile

        # If the treeview already exists, stop it from calling $self->selectWorldCallback while
        #   we're modifying its contents
        $self->ivPoke('updateFlag', TRUE);

        # Fill a model of the tree, not the tree itself
        if (! $treeView) {
            $model = $self->treeView->get_model();
        } else {
            $model = $treeView->get_model();
        }

        # Empty the treeview
        $model->clear();

        # Display each world in the treeview
        foreach my $displayName (@displayList) {

            my ($pointer, $displayObj);

            $pointer = $model->append(undef);
            $displayObj = $displayHash{$displayName};

            $model->set($pointer, 0 => $displayName);

            if ($selectWorld && $displayObj && $selectWorld eq $displayObj->name) {

                # This line must be selected
                $matchPointer = $pointer;
            }
        }

        # For each world, create a GA::Obj::MiniWorld, which stores any changes made to the world's
        #   data in the Connections window, so that they can be copied into the main world
        #   profile at the right time
        # However, don't replace an existing GA::Obj::MiniWorld
        foreach my $obj (@objList) {

            my (
                $miniWorldObj,
                %passwordHash,
                %accountHash,
            );

            if ($self->ivExists('miniWorldHash', $obj->name)) {

                # Use the existing mini-world object
                $miniWorldObj = $self->ivShow('miniWorldHash', $obj->name);

            } elsif (! $displayFlag) {

                # Create a new mini-world object corresponding to an existing world profile
                # The object requires a copy of the world profile's ->passwordHash and ->accountHash
                %passwordHash = $obj->passwordHash;
                %accountHash = $obj->accountHash;

                # Create the object
                $miniWorldObj = Games::Axmud::Obj::MiniWorld->new(
                    $obj,
                    $obj->lastConnectChar,      # May be 'undef'
                    $obj->loginAccountMode,
                    \%passwordHash,
                    \%accountHash,
                );

            } else {

                # Create a new mini-world object NOT corresponding to an existing world profile
                $miniWorldObj = Games::Axmud::Obj::MiniWorld->new($obj);
            }

            if ($miniWorldObj) {

                $miniWorldHash{$miniWorldObj->name} = $miniWorldObj;
            }
        }

        # Store the hashes as IVs
        $self->ivPoke('worldHash', %displayHash);
        $self->ivPoke('miniWorldHash', %miniWorldHash);

        # Update complete
        $self->ivPoke('updateFlag', FALSE);

        # Select a world, if one was specified in the calling functions; otherwise select the
        #   'Create new world' line. This automatically causes $self->updateTableWidgets or
        #   $self->resetTableWidgets to be called
        $treeSelection = $self->treeView->get_selection();
        if ($matchPointer) {
            $treeSelection->select_iter($matchPointer);
        } else {
            $treeSelection->select_iter($model->get_iter_first());
        }

        return 1;
    }

    sub resetTableWidgets {

        # Called by $self->selectWorldCallback when the user clicks on the 'Create new world' line
        #   in the treeview
        # Resets IVs and resets the widgets in the window's Gtk2::Table, ready for the user to
        #   enter details for a new world
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetTableWidgets', @_);
        }

        # Reset the IV which stores the currently displayed world
        $self->ivUndef('worldObj');
        # Create a temporary GA::Obj::MiniWorld to store the changes
        $self->ivPoke('miniWorldObj', Games::Axmud::Obj::MiniWorld->new());
        # Set a flag to TRUE to stop the mini-world object being updated, as we change the values
        #   displayed in the table's widgets
        $self->ivPoke('updateFlag', TRUE);

        # Reset the 'create world' button's label and tooltips (it gets modified by
        #   $self->updateTableWidgets)
        $self->createWorldButton->set_label('Create world');
        $self->tooltips->set_tip(
            $self->createWorldButton,
            'Create a world profile',
        );

        # Reset the table widgets
        $self->entry->set_text('');
        $self->entry2->set_text('');
        $self->entry3->set_text('');
        $self->checkButton->set_active(FALSE);

        $self->radioButton->set_active(TRUE);

        my $comboBox = $self->resetComboBox(TRUE);
        $self->ivPoke('comboBox', $comboBox);

        $self->websiteLabel->set_text($self->noWebsiteString);
        $self->connectionLabel->set_text($self->noConnectString);
        $self->descripBuffer->set_text('');

        # (These calls eliminate flashing when the screenshot is updated rapidly, for example when
        #   the user scrolls through the list of worlds)
        $self->winShowAll($self->_objClass . '->resetTableWdigets');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->resetTableWidgets');

        # Update the world screenshot, using the default logo
        # If a logo for this world exists, use it; otherwise use the default logo
        my $image = Gtk2::Image->new_from_file($self->defaultIcon);
        $axmud::CLIENT->desktopObj->removeWidget($self->frame, $self->image);
        $self->frame->add($image);
        $self->ivPoke('image', $image);

        # (A repeat of those calls eliminates it entirely)
        $self->winShowAll($self->_objClass . '->resetTableWidgets');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->resetTableWidgets');

        # The entry box for the world's name must be made editable
        $self->entry->set_editable(TRUE);
        # The 'pwd' / 'account' buttons start insensitive, but can be sensitised if the user selects
        #   a character
        $self->editPwdButton->set_sensitive(FALSE);
        $self->editAccButton->set_sensitive(FALSE);
        # The 'reset world' button must be insensitive when there isn't a corresponding world
        #   profile
        $self->resetWorldButton->set_sensitive(FALSE);
        # The 'add', 'connect offline' and 'connect to world' buttons must be insensitive until the
        #   user at least types something in the 'host address' entry box
        $self->addCharButton->set_sensitive(FALSE);
        $self->offlineButton->set_sensitive(FALSE);
        $self->connectButton->set_sensitive(FALSE);

        # Update complete
        $self->ivPoke('updateFlag', FALSE);

        # The call to ->show_all() causes the image to appear
        $self->winShowAll($self->_objClass . '->resetTableWidgets');

        return 1;
    }

    sub updateTableWidgets {

        # Called by $self->selectWorldCallback when the user clicks on a line in the treeview
        #   corresponding to a world profile
        # Also called by $self->testModeLoginCallback
        #
        # Updates IVs and updates the widgets in the window's Gtk2::Table, so they show details
        #   about the world
        #
        # Expected arguments
        #   $worldObj   - The GA::Profile::World object corresponding to the clicked line
        #   $line       - The text of the treeview line that the user clicked
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $worldObj, $line, $check) = @_;

        # Local variables
        my (
            $displayFlag, $modName, $host, $port, $website, $connections, $logoPath,
            @charList,
        );

        # Check for improper arguments
        if (! defined $worldObj || ! defined $line || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateTableWidgets', @_);
        }

        # Decide which list should be displayed. Default display mode is 'undef', representing
        #   a list of world profiles
        if ($self->otherWorldButton->get_active()) {

            $displayFlag = TRUE;
        }

        # Set the IV which stores the currently displayed world
        $self->ivPoke('worldObj', $worldObj);
        # Get the equivalent GA::Obj::MiniWorld
        $self->ivPoke('miniWorldObj', $self->ivShow('miniWorldHash', $worldObj->name));
        # Set a flag to TRUE to stop the mini-world object being updated, as we change the values
        #   displayed in the table's widgets
        $self->ivPoke('updateFlag', TRUE);

        # Modify the 'create world' button's label and tooltips (it gets reset by
        #   $self->resetTableWidgets)
        if (! $displayFlag) {

            $self->createWorldButton->set_label('Apply changes');
            $self->tooltips->set_tip(
                $self->createWorldButton,
                'Apply changes to this world profile',
            );

        } else {

            $self->createWorldButton->set_label('Create world');
            $self->tooltips->set_tip(
                $self->createWorldButton,
                'Create a world profile',
            );
        }

        # Display details about the world. For each IV, if there's an entry in the mini-world
        #   object, then use its value; otherwise use the value stored in the world profile itself

        # 'World name' (we don't consult the mini-world object - the world name can't be changed,
        #   once a world profile is created)
        $modName = '<i>' . $worldObj->name . '</i>';    # Matches $line for a world never connected
        if (
            $self->preConfigButton->get_active()
            && $worldObj->name ne $line
            && $worldObj->name ne $modName
            && $worldObj->longName
        ) {
            $self->entry->set_text($worldObj->longName . ' (' . $worldObj->name . ')');
        } else {
            $self->entry->set_text($worldObj->name);
        }

        # 'Host address', 'Port'
        if (! $displayFlag) {

            ($host, $port) = $worldObj->getConnectDetails();

        } else {

            $host = $worldObj->host;
            $port = $worldObj->port;
        }

        if ($self->miniWorldObj->ivExists('propHash', 'host')) {
            $self->entry2->set_text($self->miniWorldObj->ivShow('propHash', 'host'));
        } else {
            $self->entry2->set_text($host);
        }

        if ($self->miniWorldObj->ivExists('propHash', 'port')) {
            $self->entry3->set_text($self->miniWorldObj->ivShow('propHash', 'port'));
        } else {
            $self->entry3->set_text($port);
        }

        # 'Auto-login'
        if (! $displayFlag && $self->miniWorldObj->noAutoLoginFlag) {
            $self->checkButton->set_active(TRUE);
        } else {
            $self->checkButton->set_active(FALSE);
        }

        # 'Character'
        if (! $displayFlag) {

            @charList = sort {lc($a) cmp lc($b)} ($self->miniWorldObj->ivKeys('passwordHash'));
        }

        my $comboBox = $self->resetComboBox(TRUE, @charList);
        $self->ivPoke('comboBox', $comboBox);

        # 'Websites'
        $website = 'Websites:';

        if (! $displayFlag) {

            if (! $worldObj->worldURL && ! $worldObj->referURL) {

                $website .= ' (no websites)';

            } else {

                if ($worldObj->worldURL) {

                    $website .= ' <a href="' . $worldObj->worldURL . '">Website</a>';
                }

                if ($worldObj->referURL) {

                    $website .= ' <a href="' . $worldObj->referURL . '">Referrer</a>';
                }
            }

        } else {

            $website .= ' (n/a)';
        }

        $self->websiteLabel->set_markup($website);

        # 'Connections'
        if (! $displayFlag) {

            $connections = 'Connections: ' . $worldObj->numberConnects;
            if ($worldObj->lastConnectDate && $worldObj->lastConnectTime) {

                $connections .= ', most recent: ' . $worldObj->lastConnectDate . ' at '
                                    . $worldObj->lastConnectTime;
            }

        } else {

            $connections = 'Connections: (n/a)';
        }

        $self->connectionLabel->set_markup($connections);

        # (Descrip)
        if ($self->miniWorldObj->ivExists('propHash', 'descrip')) {

            $self->descripBuffer->set_text($self->miniWorldObj->ivShow('propHash', 'descrip'));

        } elsif (! $displayFlag && $worldObj->worldDescrip) {

            $self->descripBuffer->set_text($worldObj->worldDescrip);

        } elsif (! $displayFlag) {

            $self->descripBuffer->set_text('');

        } else {

            $self->descripBuffer->set_text(
                'This world profile won\'t be created until you click one of the buttons below',
            )
        }

        # Move the 'descrip' textview's scrollbar to the top, in case the user has been browsing
        #   another world's description
        $self->descripTextView->scroll_to_iter(
            $self->descripBuffer->get_start_iter(),
            0.0,
            TRUE,
            0,
            1,
        );

        # If a logo for this world exists, use it; otherwise use the default logo
        if (! $displayFlag) {

            $logoPath = $axmud::DATA_DIR . '/logos/' . $worldObj->name . '.png';
        }

        if ($displayFlag || ! (-e $logoPath)) {

            $logoPath = $axmud::CLIENT->getClientLogo($worldObj->adultFlag);
        }

        # (These calls eliminate flashing when the screenshot is updated rapidly, for example when
        #   the user scrolls through the list of worlds)
        $self->winShowAll($self->_objClass . '->updateTableWidgets');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->updateTableWidgets');

        # Update the world screenshot
        my $image = Gtk2::Image->new_from_file($logoPath);
        $axmud::CLIENT->desktopObj->removeWidget($self->frame, $self->image);
        $self->frame->add($image);
        $self->ivPoke('image', $image);

        # (A repeat of those calls eliminates it entirely)
        $self->winShowAll($self->_objClass . '->updateTableWidgets');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->updateTableWidgets');

        # The entry box for the world's name must not be changed
        $self->entry->set_editable(FALSE);
        # The 'add' button must be sensitive
        $self->addCharButton->set_sensitive(TRUE);
        # The 'pwd'/'account' buttons start sensitised if there's a selected character, but
        #   desensitised if not
        if ($self->miniWorldObj->selectChar) {

            $self->editPwdButton->set_sensitive(TRUE);
            $self->editAccButton->set_sensitive(TRUE);

        } else {

            $self->editPwdButton->set_sensitive(FALSE);
            $self->editAccButton->set_sensitive(FALSE);
        }

        # The 'reset world' button must be sensitive
        $self->resetWorldButton->set_sensitive(TRUE);
        # If the world profile doesn't have a ->dns, ->ipv4 or ->ipv6 value, Axmud obviously won't
        #   be able to connect to the world. Make the connect buttons desensitised until the user
        #   types something in the 'host address' entry box
        if (! $host) {

            $self->offlineButton->set_sensitive(FALSE);
            $self->connectButton->set_sensitive(FALSE);

        } else {

            # Otherwise, these two buttons start sensitised
            $self->offlineButton->set_sensitive(TRUE);
            $self->connectButton->set_sensitive(TRUE);
        }

        # Update complete
        $self->ivPoke('updateFlag', FALSE);

        # The call to ->show_all() causes the image to appear
        $self->winShowAll($self->_objClass . '->updateTableWidgets');

        return 1;
    }

    sub resetComboBox {

        # Called by $self->createTableWidgets, ->resetTableWidgets and ->updateTableWidgets
        # Not sure how to empty a Gtk2::ComboBox, so we'll just destroy the old one, and replace it
        #   with a new one
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $destroyFlag    - If TRUE, a combobox already exists, and must be deleted. If FALSE (or
        #                       'undef'), the combobox is being drawn for the first time
        #   @charList       - A list of characters to display in the combobpx. If empty, the
        #                       combobox will contain only the '<no character>' string. If not
        #                       empty, the '<no character>' is added to @charList as the first item
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the Gtk2::ComboBox created

        my ($self, $destroyFlag, @charList) = @_;

        # Local variables
        my ($count, $index);

        # (No improper arguments to check)

        # If a Gtk2::ComboBox already exists, destroy it
        if ($destroyFlag) {

            $axmud::CLIENT->desktopObj->removeWidget($self->table, $self->comboBox);
       }

        # Create a new combobox
        unshift (@charList, $self->noCharString);
        my $comboBox = $self->addComboBox($self->table, undef, \@charList, undef,
            4, 8, 6, 7);

        # If the current mini-world object specifies a character, make that the combobox's active
        #   item. Otherwise, make the '<no character>' string the active item
        $index = 0;
        if ($self->miniWorldObj && $self->miniWorldObj->selectChar) {

            $count = -1;
            OUTER: foreach my $string (@charList) {

                $count++;

                if ($string eq $self->miniWorldObj->selectChar) {

                    $index = $count;
                    last OUTER;
                }
            }
        }

        $comboBox->set_active($index);
        # Also, the 'pwd'/'account' buttons should only be sensitised when there's a selected
        #   character
        if ($self->miniWorldObj) {

            if ($self->miniWorldObj->selectChar) {

                $self->editPwdButton->set_sensitive(TRUE);
                $self->editAccButton->set_sensitive(TRUE);

            } else {

                $self->editPwdButton->set_sensitive(FALSE);
                $self->editAccButton->set_sensitive(FALSE);
            }
        }

        # Now we can add the combobox's ->signal_connect, which updates the mini-world object when
        #   a character is selected
        $comboBox->signal_connect('changed' => sub {

            my $char = $comboBox->get_active_text();

            if ($char eq $self->noCharString) {

                $self->miniWorldObj->ivUndef('selectChar');
                # When no character is selected, the 'pwd'/'account' buttons must be desensitised
                $self->editPwdButton->set_sensitive(FALSE);
                $self->editAccButton->set_sensitive(FALSE);

            } else {

                $self->miniWorldObj->ivPoke('selectChar', $char);
                # When no character is selected, the 'pwd'/'account' buttons must be desensitised
                $self->editPwdButton->set_sensitive(TRUE);
                $self->editAccButton->set_sensitive(TRUE);
            }
        });

        # The call to ->show_all() makes the new combobox visible
        $self->winShowAll($self->_objClass . '->resetComboBox');

        return $comboBox;
    }

    sub updateProfile {

        # Called by $self->applyChangesCallback and ->connectWorldCallback
        # Copies changes to values, stored in the specified mini-world object, to the corresponding
        #   world profile (if it exists)
        #
        # Expected arguments
        #   $miniWorldObj   - A GA::Obj::MiniWorld
        #
        # Return values
        #   'undef' on improper arguments or if there is no world profile to update
        #   1 otherwise

        my ($self, $miniWorldObj, $check) = @_;

        # Local variables
        my (
            $worldObj, $profFlag, $host, $port, $descrip,
            %newHash,
        );

        # Check for improper arguments
        if (! defined $miniWorldObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateProfile', @_);
        }

        # Import the equivalent world profile object, for convenience
        $worldObj = $miniWorldObj->worldObj;
        # Is it actually a world profile, or is it a basic world object (GA::Obj::BasicWorld), which
        #   has different IVs?
        if (! $worldObj->isa('Games::Axmud::Profile::World')) {

            # It's a basic world object; nothing for this function to do
            return undef;
        }

        # (We can't change the profile's ->name)

        # ->host
        $host = $miniWorldObj->ivShow('propHash', 'host');
        if ($host && $host =~ m/\w/) {

            $host = $axmud::CLIENT->trimWhitespace($host);

            if ($profFlag) {

                if ($axmud::CLIENT->ipv6Check($host)) {
                    $worldObj->ivPoke('ipv6', $host);
                } elsif ($axmud::CLIENT->ipv4Check($host)) {
                    $worldObj->ivPoke('ipv4', $host);
                } else {
                    $worldObj->ivPoke('dns', $host);
                }

            } else {

                $worldObj->ivPoke('dns', $host);
            }
        }

        $port = $self->miniWorldObj->ivShow('propHash', 'port');
        if ($port && $port =~ m/\w/) {

            $port = $axmud::CLIENT->trimWhitespace($port);
            $worldObj->ivPoke('port', $port);
        }

        $descrip = $self->miniWorldObj->ivShow('propHash', 'descrip');
        if ($descrip) {

            $worldObj->ivPoke('worldDescrip', $descrip);
        }

        # Characters, now. The data stored in the mini-world object's ->newPasswordHash (consisting
        #   of new characters, and existing characters with new passwords) is copied into the world
        #   profile's ->newPasswordHash; it's up to GA::Session->setupProfiles to create new
        #   character profiles, the next time this world is a current world
        %newHash = $self->miniWorldObj->newPasswordHash;
        foreach my $char (keys %newHash) {

            my $pass = $newHash{$char};    # May be 'undef'

            $worldObj->ivAdd('newPasswordHash', $char, $pass);
        }

        # The same applies to the mini-world object's ->newAccountHash
        %newHash = $self->miniWorldObj->newAccountHash;
        foreach my $char (keys %newHash) {

            my $account = $newHash{$char};    # May be 'undef'

            $worldObj->ivAdd('newAccountHash', $char, $account);
        }

        return 1;
    }

    # Response methods

    sub selectWorldCallback {

        # Callback, called by anonymous subroutine in $self->drawWidgets when the user clicks on
        #   any world in the treeview
        # Copies information from the selected world profile into the table widgets on the right
        #   side of the window
        #
        # Expected arguments
        #   $selection  - A Gtk2::TreeSelection corresponding to the selected item in the treeview
        #
        # Return values
        #   'undef' on improper arguments or if the selection can't be matched to something in
        #       $self->worldList
        #   1 otherwise

        my ($self, $selection, $check) = @_;

        # Local variables
        my ($model, $iter, $line, $worldObj);

        # Check for improper arguments
        if (! defined $selection || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->selectWorldCallback', @_);
        }

        # Get the text of the selected line
        ($model, $iter) = $selection->get_selected();
        if (! $iter) {

            return undef;

        } else {

            $line = $model->get($iter, 0);
            if (! $self->ivExists('worldHash', $line)) {

                return undef;

            } else {

                $worldObj = $self->ivShow('worldHash', $line);
                if (! $worldObj) {

                    # The user has clicked on the 'Create new world' line
                    $self->resetTableWidgets();

                } else {

                    $self->updateTableWidgets($worldObj, $line);
                }

                return 1;
            }
        }
    }

    sub addCharCallback {

        # Callback, called by anonymous subroutine in $self->createTableWidgets when the user clicks
        #   on the 'add' button
        # Adds a character (and optionally a password) to ->passwordHash in the GA::Obj::MiniWorld
        #   corresponding to the current world
        #
        # Expected arguments
        #   $widget     - The Gtk2::Button clicked
        #
        # Return values
        #   'undef' on improper arguments or if an invalid character name is supplied
        #   1 otherwise

        my ($self, $widget, $check) = @_;

        # Local variables
        my (
            $string, $char, $pass, $account,
            @charList,
        );

        # Check for improper arguments
        if (! defined $widget || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addCharCallback', @_);
        }

        # Prompt the user to enter a username/password/account. The password/account are optional
        $string = 'Associated account name';
        if ($self->miniWorldObj->loginAccountMode eq 'unknown') {
            $string .= ' <i>(if required)</i>';
        } elsif ($self->miniWorldObj->loginAccountMode eq 'not_required') {
            $string .= ' <i>(not required)</i>';
        } elsif ($self->miniWorldObj->loginAccountMode eq 'required') {
            $string .= ' <i>(recommended)</i>';
        }

        ($char, $pass, $account) = $self->showTripleEntryDialogue(
            'Add character',
            'Enter a username',
            'Enter a password <i>(optional)</i>',
            $string,
            undef,              # No maximum chars
            2,                  # Obscure password text (only)
            TRUE,               # Don't remove the '<' and '>' characters
        );

        if ($char) {

            # Trim leading/trailing whitespace from the name, password and account name
            $char = $axmud::CLIENT->trimWhitespace($char);
            if ($pass) {

                $pass = $axmud::CLIENT->trimWhitespace($pass);
            }

            if ($account) {

                $account = $axmud::CLIENT->trimWhitespace($account);
            }

            # Check that the name is be a valid profile name
            if (
                ! $axmud::CLIENT->nameCheck($char, 16)
                || $axmud::CLIENT->ivExists('worldProfHash', $char)
            ) {
                $self->showMsgDialogue(
                    'Add character',
                    'error',
                    '\'' . $char . '\' is not a valid character profile name',
                    'ok',
                );

                return undef;
            }

            # Update the current mini-world object
            if ($pass) {

                $self->miniWorldObj->ivAdd('passwordHash', $char, $pass);
                $self->miniWorldObj->ivAdd('newPasswordHash', $char, $pass);

            } else {

                $self->miniWorldObj->ivAdd('passwordHash', $char, undef);
                $self->miniWorldObj->ivAdd('newPasswordHash', $char, undef);
            }

            if ($account) {

                $self->miniWorldObj->ivAdd('accountHash', $char, $account);
                $self->miniWorldObj->ivAdd('newAccountHash', $char, $account);

            } else {

                $self->miniWorldObj->ivAdd('accountHash', $char, undef);
                $self->miniWorldObj->ivAdd('newAccountHash', $char, undef);
            }

            $self->miniWorldObj->ivPoke('selectChar', $char);

            # Redraw the combobox
            @charList = sort {lc($a) cmp lc($b)} ($self->miniWorldObj->ivKeys('passwordHash'));
            my $comboBox = $self->resetComboBox(TRUE, @charList);
            $self->ivPoke('comboBox', $comboBox);
        }

        return 1;
    }

    sub editPasswordCallback {

        # Callback, called by anonymous subroutine in $self->createTableWidgets when the user clicks
        #   on the 'pwd' button
        # Edits the password of an existing character, storing the changes in the current mini-world
        #   object's ->passwordHash and ->newPasswordHash
        #
        # Expected arguments
        #   $widget     - The Gtk2::Button clicked
        #
        # Return values
        #   'undef' on improper arguments or if no character is selected
        #   1 otherwise

        my ($self, $widget, $check) = @_;

        # Local variables
        my ($char, $currentPass, $newPass);

        # Check for improper arguments
        if (! defined $widget || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->editPasswordCallback', @_);
        }

        # Get the character displayed in the combobox
        $char = $self->comboBox->get_active_text();
        if (! $char || $char eq $self->noCharString) {

            # No character to edit
            return undef;
        }

        # Get the current password for this character (if any)
        $currentPass = $self->miniWorldObj->ivShow('passwordHash', $char);

        # Prompt the user to enter a new password
        $newPass = $self->showEntryDialogue(
            'Edit password',
            'Enter a new password for the \'' . $char . '\' character',
            undef,              # No maximum chars
            $currentPass,
            TRUE,               # Obscure text in the entry box
        );

        # If the user didn't close the window manually...
        if (defined $newPass) {

            if ($newPass) {

                $self->miniWorldObj->ivAdd('passwordHash', $char, $newPass);
                $self->miniWorldObj->ivAdd('newPasswordHash', $char, $newPass);

            } else {

                $self->miniWorldObj->ivAdd('passwordHash', $char, undef);
                $self->miniWorldObj->ivAdd('newPasswordHash', $char, undef);
            }
        }

        return 1;
    }

    sub editAccountCallback {

        # Callback, called by anonymous subroutine in $self->createTableWidgets when the user clicks
        #   on the 'account' button
        # Edits the associated account for an existing character, storing the changes in the current
        #   mini-world object's ->accountHash and ->newAccountHash
        #
        # Expected arguments
        #   $widget     - The Gtk2::Button clicked
        #
        # Return values
        #   'undef' on improper arguments or if no character is selected
        #   1 otherwise

        my ($self, $widget, $check) = @_;

        # Local variables
        my ($string, $char, $currentAccount, $newAccount);

        # Check for improper arguments
        if (! defined $widget || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->editAccountCallback', @_);
        }

        # Get the character displayed in the combobox
        $char = $self->comboBox->get_active_text();
        if (! $char || $char eq $self->noCharString) {

            # No character to edit
            return undef;
        }

        # Get the current account for this character (if any)
        $currentAccount = $self->miniWorldObj->ivShow('accountHash', $char);

        # Prompt the user to enter a new password
        $string = "Enter the new account name associated with the\n\'" . $char . "\' character";
        if ($self->miniWorldObj->loginAccountMode eq 'not_required') {
            $string .= ' (not required for this world)';
        } elsif ($self->miniWorldObj->loginAccountMode eq 'required') {
            $string .= ' (recommended for this world)';
        } else {
            $string .= ' (if required for this world)';
        }

        $newAccount = $self->showEntryDialogue(
            'Edit account',
            $string,
            undef,              # No maximum chars
            $currentAccount,
            FALSE,              # Don't obscure text in the entry box
        );

        # If the user didn't close the window manually...
        if (defined $newAccount) {

            if ($newAccount) {

                $self->miniWorldObj->ivAdd('accountHash', $char, $newAccount);
                $self->miniWorldObj->ivAdd('newAccountHash', $char, $newAccount);

            } else {

                $self->miniWorldObj->ivAdd('accountHash', $char, undef);
                $self->miniWorldObj->ivAdd('newAccountHash', $char, undef);
            }
        }

        return 1;
    }

    sub createWorldCallback {

        # Callback, called by anonymous subroutine in $self->createTableWidgets when the user clicks
        #   the 'create world' button
        # When the currently-selected treeview item is 'create new world', creates a new world
        #   profile, and updates it with the data stored in $self->miniWorldObj
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $invalidString, $generalString, $name, $host, $port, $worldObj, $fileObj, $dictObj,
            $miniObj,
            %pwdHash, %accHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createWorldCallback', @_);
        }

        if ($self->worldObj && $self->preConfigButton->get_active()) {

            # This function shouldn't have been called (->applyChangesCallback should have been
            #   called instead)
            return undef;
        }

        # Set a few strings to use in 'dialogue' windows
        $invalidString = ' can contain letters, numbers and underline characters (except the first'
            . ' character), but not spaces. Reserved names like \'' . $axmud::SCRIPT
            . '\' are not allowed. The maximum length is 16 characters.';
        $generalString = 'Failed to create the new world profile (many apologies)';

        # Check that the name specified by the user is valid
        $name = $self->entry->get_text();
        if (! $name) {

            $self->showMsgDialogue(
                'Missing name',
                'error',
                'You must specify a name for this world. World profile names' . $invalidString,
                'ok',
            );

            return undef;

        } elsif (! $axmud::CLIENT->nameCheck($name, 16)) {

            $self->showMsgDialogue(
                'Invalid name',
                'error',
                '\'' . $name . '\' is an invalid world profile name. Names' . $invalidString,
                'ok',
            );

            return undef;
        }

        # Check that the user entered a host address
        $host = $self->entry2->get_text();
        if (! $name) {

            $self->showMsgDialogue(
                'Missing host address',
                'error',
                'You must specify a host address, e.g. \'dead-souls.net\'. IPV4, IPV6 or DNS'
                . ' addresses can be used.',
                'ok',
            );

            return undef;
        }

        # If the port was specified, check that it is valid
        $port = $self->entry3->get_text();
        if (! $axmud::CLIENT->intCheck($port, 0, 65535)) {

            $self->showMsgDialogue(
                'Invalid port',
                'error',
                '\'' . $port . '\' is an invalid port. Specify a value in the range 0-65535, or'
                . ' leave the box empty to use the default port.',
                'ok',
            );

            return undef;
        }

        # Create the new world profile. Cheat a bit by pretending the GA::Client is a
        #   GA::Session. (Rest of this function adapted from code in GA::Cmd::AddWorld->do)
        $worldObj = Games::Axmud::Profile::World->new($axmud::CLIENT, $name);
        if ($worldObj) {

            # Create a file object for the world profile
            $fileObj = Games::Axmud::Obj::File->new('worldprof', $name);
        }

        if (! $worldObj || ! $fileObj) {

            $self->showMsgDialogue(
                'General error',
                'error',
                $generalString,
                'ok',
            );

            return undef;
        }

        # If a dictionary object with the same name as the world doesn't already exist, create it.
        #   Otherwise use the existing one
        if (! $axmud::CLIENT->ivExists('dictHash', $name)) {

            # (Again, cheat a bit by pretending the GA::Client is a GA::Session)
            $dictObj = Games::Axmud::Obj::Dict->new($axmud::CLIENT, $name);
            if (! $dictObj) {

                $self->showMsgDialogue(
                    'General error',
                    'error',
                    $generalString,
                    'ok',
                );

                return undef;

            } else {

                # Update client IVs with the new dictionary
                $axmud::CLIENT->add_dict($dictObj);
            }
        }

        # Update client IVs with the new profile and file object
        $axmud::CLIENT->add_fileObj($fileObj);
        $axmud::CLIENT->add_worldProf($worldObj);

        # Update the world profile's IVs using the values stored in the mini-world object
        if ($axmud::CLIENT->ipv6Check($host)) {
            $worldObj->ivPoke('ipv6', $host);
        } elsif ($axmud::CLIENT->ipv4Check($host)) {
            $worldObj->ivPoke('ipv4', $host);
        } else {
            $worldObj->ivPoke('dns', $host);
        }

        if ($port) {

            # (Otherwise the world profile continues using the generic port, 23)
            $worldObj->ivPoke('port', $port);
        }

        # If the basic mudlist is displayed, we can set a couple of other IVs, too
        if ($self->worldObj && $self->otherWorldButton->get_active()) {

            $worldObj->ivPoke('longName', $self->worldObj->longName);
            $worldObj->ivPoke('adultFlag', $self->worldObj->adultFlag);
        }

        # Create a new mini-world object, replacing the temporary one stored in $self->miniWorldObj,
        #   and store it in the hash of mini-world objects which have corresponding world
        #   profiles
        %pwdHash = $self->miniWorldObj->passwordHash;
        %accHash = $self->miniWorldObj->accountHash;
        $miniObj = Games::Axmud::Obj::MiniWorld->new(
            $worldObj,
            $self->miniWorldObj->selectChar,
            $self->miniWorldObj->loginAccountMode,
            \%pwdHash,
            \%accHash,
        );

        if ($miniObj) {

            $self->ivAdd('miniWorldHash', $worldObj->name, $miniObj);
        }

        # Reset the treeview, specifying that the new world profile should be selected (the call to
        #   ->resetTreeView also creates a new mini-world object corresponding to $worldObj)
        if ($self->otherWorldButton->get_active()) {

            # Make sure the list of pre-configured worlds is now visible
            $self->preConfigButton->set_active(TRUE);
        }

        $self->resetTreeView(undef, $worldObj->name);

        return 1;
    }

    sub applyChangesCallback {

        # Callback, called by anonymous subroutine in $self->createTableWidgets when the user clicks
        #   the 'apply changes' button
        #
        # When the currently-selected treeview item is not 'create new world', updates the current
        #   world profile with any user-entered values stored in the current mini-world object
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $name;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->applyChangesCallback', @_);
        }

        if (! $self->worldObj) {

            # This function shouldn't have been called (->createWorldCallback should have been
            #   called instead)
            return undef;
        }

        # Copy changes from the current mini-world object into the corresponding world profile
        $self->updateProfile($self->miniWorldObj);

        # Reset the mini-world object - the empty IVs mean that the world profile stores the
        #   same data
        $self->miniWorldObj->reset();

        # Reset the treeview, specifying that the existing world profile should still be selected
        #   this updates table widgets)
        $name = $self->worldObj->name;
        $self->resetTreeView(undef, $name);

        # Display a confirmation
        $self->showMsgDialogue(
            'World updated',
            'info',
            'The \'' . $name . '\' world profile has been updated (but data files have not been'
            . ' saved - use the \';save\' command when you start a new session)',
            'ok',
        );

        return 1;
    }

    sub resetWorldCallback {

        # Callback, called by anonymous subroutine in $self->createTableWidgets when the user clicks
        #   the 'reset world' button
        # Creates a new mini-world object to replace the old one, then resets the treeview which
        #   causes all the table widgets to display the values actually stored in the world profile
        #
        # Expected arguments
        #   $widget     - The Gtk2::Button clicked
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $widget, $check) = @_;

        # Local variables
        my (
            $miniObj,
            %pwdHash, %accHash,
        );

        # Check for improper arguments
        if (! defined $widget || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetWorldCallback', @_);
        }

        if (! $self->worldObj) {

            # This function shouldn't have been called (->createWorldCallback should have been
            #   called instead)
            return undef;
        }

        if ($self->preConfigButton->get_active()) {

            # Create a new mini-world object corresponding to an existing world profile
            %pwdHash = $self->worldObj->passwordHash;
            %accHash = $self->worldObj->accountHash;
            $miniObj = Games::Axmud::Obj::MiniWorld->new(
                $self->worldObj,
                $self->worldObj->lastConnectChar,   # May be undef
                $self->worldObj->loginAccountMode,
                \%pwdHash,
                \%accHash,
            );

        } else {

            # Create a new mini-world object NOT corresponding to an existing world profile
            $miniObj = Games::Axmud::Obj::MiniWorld->new($self->worldObj);
        }

        if ($miniObj) {

            $self->ivAdd('miniWorldHash', $self->worldObj->name, $miniObj);
        }

        # Reset the treeview, specifying that the same world profile should be selected (the call to
        #   ->resetTreeView also creates a new mini-world object corresponding to $worldObj)
        $self->resetTreeView(undef, $self->worldObj->name);

        return 1;
    }

    sub connectWorldCallback {

        # Callback, called by anonymous subroutine in $self->createTableWidgets when the user clicks
        #   the 'connect to world' or 'connect offline' buttons
        # Starts a new GA::Session, passing it information from this window (such as the selected
        #   world and character)
        #
        # Expected arguments
        #   $offlineFlag    - Set to TRUE if the user clicked on the 'connect offline' button; set
        #                       to FALSE if the user clicked on the 'connect to world' button
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $offlineFlag, $check) = @_;

        # Local variables
        my (
            $displayFlag, $applyFlag, $msg, $response, $worldName, $tempFlag, $altHost, $altPort,
            $altChar, $altPass, $altAccount, $host, $port, $pass, $char, $account, $protocol,
            @miniList,
        );

        # Check for improper arguments
        if (! defined $offlineFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->connectWorldCallback', @_);
        }

        # Remember which list was displayed, as the Connections window is about to be destroyed
        if ($self->otherWorldButton->get_active()) {

            $displayFlag = TRUE;
        }

        # Before doing anything, check that the maximum number of sessions hasn't already been
        #   reached
        if ($axmud::CLIENT->ivPairs('sessionHash') >= $axmud::CLIENT->sessionMax) {

            if ($axmud::CLIENT->sessionMax == 1) {

                $self->showMsgDialogue(
                    'Session limit reached',
                    'error',
                    'Can\'t open a new session (only one session allowed - use the'
                    . ' \';maxsession\' command to change this)',
                    'ok',
                );

            } else {

                $self->showMsgDialogue(
                    'Session limit reached',
                    'error',
                    'Can\'t open a new session (' . $axmud::SCRIPT . ' has reached its limit of '
                    . $self->sessionMax . ' sessions)',
                    'ok',
                );
            }

            return undef;
        }

        # If the user has made any changes to the values displayed in table widgets, that would be
        #   applied to the world profile when the 'store changes' button is clicked, we need to ask
        #   the user if they want to apply those changes now

        # Compile a list of mini-world objects whose values have been modified, but not stored in
        #   the corresponding world profiles. Also set a flag if the selected mini-world has been
        #   modified, but not stored
        foreach my $miniObj ($self->ivValues('miniWorldHash')) {

            if ($miniObj->propHash || $miniObj->newPasswordHash || $miniObj->newAccountHash) {

                push (@miniList, $miniObj);

                if ($miniObj eq $self->miniWorldObj) {

                    $applyFlag = TRUE;
                }
            }
        }

        if (@miniList) {

            # Unstored values; prompt the user to ask if they'd like to apply them before continuing
            $msg = 'You haven\'t applied your changes to ';
            if (! $applyFlag) {

                if (@miniList == 1) {
                    $msg .= '1 world'
                } else {
                    $msg .= scalar @miniList . ' worlds'
                }

            } else {

                if (@miniList == 1) {
                    $msg .= 'the selected world';
                } else {
                    $msg .= scalar @miniList . ' worlds (including the selected one)';
                }
            }

            $msg .= '. Do you want to apply them now?';

            $response = $self->showMsgDialogue(
                'Apply changes',
                'question',
                $msg,
                'yes-no',
                'yes',
            );

            if ($response && $response eq 'yes') {

                # Apply the changes for each modified mini-world object
                foreach my $miniObj (@miniList) {

                    $self->updateProfile($miniObj);
                }

                if (! $self->worldObj) {

                    # Earlier there was no corresponding world profile object, but now there is one.
                    #   Use it
                    $self->ivPoke(
                        'worldObj',
                        $axmud::CLIENT->ivShow('worldProfHash', $self->miniWorldObj->name),
                    );
                }
            }
        }

        # Set the chosen $protocl, or leave 'undef' to use the world profile's default protocol
        if ($self->radioButton2->get_active()) {
            $protocol = 'telnet';
        } elsif ($self->radioButton3->get_active()) {
            $protocol = 'ssh';
        } elsif ($self->radioButton4->get_active()) {
            $protocol = 'ssl';
        }

        # Now we can connect to the world. Close this window, so it doesn't get in the way
        $self->winDestroy();

        if ($self->worldObj) {

            if (! $displayFlag) {

                # The user has selected a world with an existing world profile
                $tempFlag = FALSE;
                $worldName = $self->worldObj->name;

                # Get the world profile's usual connection details, in case the mini-world object
                #   doesn't specify them
                ($altHost, $altPort, $altChar, $altPass, $altAccount)
                    = $self->worldObj->getConnectDetails($self->miniWorldObj->selectChar);

                # Decide which connection details to use
                $host = $self->miniWorldObj->ivShow('propHash', 'host');
                if (! $host) {

                    $host = $altHost;
                }

                $port = $self->miniWorldObj->ivShow('propHash', 'port');
                if (! $port) {

                    $port = $altPort;
                }


            } else {

                # The user has selected a world from the basic mudlist, for which no world profile
                #   exists yet
                $tempFlag = FALSE;
                $worldName = $self->worldObj->name;
                $host = $self->worldObj->host;
                $port = $self->worldObj->port;
            }

            $char = $self->miniWorldObj->selectChar;    # May be 'undef'
            if ($char) {

                $pass = $self->miniWorldObj->ivShow(
                    'passwordHash',
                    $self->miniWorldObj->selectChar,
                );

                $account = $self->miniWorldObj->ivShow(
                    'accountHash',
                    $self->miniWorldObj->selectChar,
                );
            }

            # If the user selected no auto-login, reset the password and account name (the
            #   GA::Session won't attempt an auto-login, without knowing the password)
            if ($self->miniWorldObj->noAutoLoginFlag) {

                $pass = undef;
                $account = undef;
            }

        } else {

            # The user has selected a world without an existing world profile, and has declined
            #   to create a profile in the earlier 'dialogue' window (if one was presented)
            $worldName = $self->miniWorldObj->ivShow('propHash', 'name');
            if ($worldName) {

                $worldName = $axmud::CLIENT->trimWhitespace($worldName);
                $tempFlag = FALSE;

            } else {

                # The user didn't specify a world name. Ask the GA::Client to supply us with a name
                #   for a temporary profile
                $tempFlag = TRUE;
                $worldName = $axmud::CLIENT->getTempProfName();
                if (! $worldName) {

                    # No available names (an extremely unlikely situation)
                    $axmud::CLIENT->mainWin->showMsgDialogue(
                        'Failed connection',
                        'error',
                        'General error while connection to the world',
                        'ok',
                    );

                    return undef;
                }
            }

            # Decide which connection details to use (the 'host' value is always defined when this
            #   function is called)
            $host = $axmud::CLIENT->trimWhitespace($self->miniWorldObj->ivShow('propHash', 'host'));
            $port = $self->miniWorldObj->ivShow('propHash', 'port');
            if (! defined $port) {

                $port = 23;

            } else {

                $port = $axmud::CLIENT->trimWhitespace($port);
            }

            $char = $self->miniWorldObj->selectChar;    # May be 'undef'

            if ($char) {

                $pass = $self->miniWorldObj->ivShow(
                    'passwordHash',
                    $self->miniWorldObj->selectChar,
                );

                $account = $self->miniWorldObj->ivShow(
                    'accountHash',
                    $self->miniWorldObj->selectChar,
                );
            }

            # If the user selected no auto-login, reset the password/account name (the GA::Session
            #   won't attempt an auto-login, without knowing the password)
            if ($self->miniWorldObj->noAutoLoginFlag) {

                $pass = undef;
                $account = undef;
            }
        }

        # Start the session
        if (
            ! $axmud::CLIENT->startSession(
                $worldName,
                $host,
                $port,
                $char,
                $pass,
                $account,
                $protocol,          # If 'undef', default protocol used
                undef,              # No login mode
                $offlineFlag,
                $tempFlag,
            )
        ) {
            # Display a confirmation
            $axmud::CLIENT->mainWin->showMsgDialogue(
                'Failed connection',
                'error',
                'General error while connecting to \'' . $worldName . '\'',
                'ok',
            );

            return undef;

        } else {

            # This GA::OtherWin::Connect is now finished
            return 1;
        }
    }

    sub testModeCallback {

        # Function used for Axmud development
        # $self->createTableWidgets creates a button that's only visible if the user has edited the
        #   contents of /scripts/axmud.pl or /scripts/baxmud.pl, in order to modify the global
        #   variable @TEST_MODE_LOGIN_LIST
        # The button, if visible and if clicked, calls this function, which uses the contents of
        #   the global variable to set the visible world, address, port, character and password, as
        #   if the user had entered those values manually
        #
        # Expected arguments
        #   $testButton     - The Gtk2::Button that was clicked
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $testButton, $check) = @_;

        # Local variables
        my (
            $worldObj,
            @testList, @charList,
        );

        # Check for improper arguments
        if (! defined $testButton || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->testModeCallback', @_);
        }

        # Import the global variable (for convenience)
        @testList = @axmud::TEST_MODE_LOGIN_LIST;

        # If the global variable refers to a world, for which a world profile already exists,
        #   update table widgets as if the user had entered the global variable's value manually
        if (defined $testList[0]) {

            $worldObj = $axmud::CLIENT->ivShow('worldProfHash', $testList[0]);
            if ($worldObj) {

                # Update table widgets for this world, unless that world is already the visible one
                if (! $self->worldObj || $worldObj ne $self->worldObj) {

                    $self->updateTableWidgets($worldObj, $worldObj->longName);
                }

                # Update table widgets again, using the values stored in @TEST_MODE_LOGIN_LIST

                # World DNS/IP address
                if (defined $testList[1]) {

                    $self->entry2->set_text($testList[1]);
                }

                # World port
                if (defined $testList[2]) {

                    $self->entry3->set_text($testList[2]);
                }

                # Character name and password
                if (defined $testList[3] && defined $testList[4]) {

                    $self->miniWorldObj->ivAdd('passwordHash', $testList[3], $testList[4]);
                    $self->miniWorldObj->ivAdd('newPasswordHash', $testList[3], $testList[4]);

                    $self->miniWorldObj->ivPoke('selectChar', $testList[3]);

                    # Redraw the combobox
                    @charList
                        = sort {lc($a) cmp lc($b)} ($self->miniWorldObj->ivKeys('passwordHash'));

                    my $comboBox = $self->resetComboBox(TRUE, @charList);
                    $self->ivPoke('comboBox', $comboBox);
                }
            }
        }

        return 1;
    }

    ##################
    # Accessors - set

    sub set_consoleButton {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_consoleButton', @_);
        }

        if (! $flag) {

            # No system messages to display in the Client Console window
            $self->consoleButton->set_image(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . '/icons/connect/icon_console.png'),
            );

        } else {

            # At least one system message to display in the Client Console window
            $self->consoleButton->set_image(
                Gtk2::Image->new_from_file(
                    $axmud::SHARE_DIR . '/icons/connect/icon_console_alert.png',
                ),
            );
        }

        return 1;
    }

    ##################
    # Accessors - get

    sub hPaned
        { $_[0]->{hPaned} }
    sub vBox
        { $_[0]->{vBox} }
    sub frame
        { $_[0]->{frame} }
    sub image
        { $_[0]->{image} }
    sub hBox
        { $_[0]->{hBox} }
    sub objModel
        { $_[0]->{objModel} }
    sub treeView
        { $_[0]->{treeView} }
    sub treeViewColumn
        { $_[0]->{treeViewColumn} }
    sub scroller
        { $_[0]->{scroller} }
    sub scroller2
        { $_[0]->{scroller2} }
    sub table
        { $_[0]->{table} }
    sub preConfigButton
        { $_[0]->{preConfigButton} }
    sub otherWorldButton
        { $_[0]->{otherWorldButton} }
    sub sortAzButton
        { $_[0]->{sortAzButton} }
    sub sortZaButton
        { $_[0]->{sortZaButton} }
    sub sortRandButton
        { $_[0]->{sortRandButton} }
    sub searchButton
        { $_[0]->{searchButton} }
    sub cancelSearchButton
        { $_[0]->{cancelSearchButton} }
    sub consoleButton
        { $_[0]->{consoleButton} }
    sub entry
        { $_[0]->{entry} }
    sub entry2
        { $_[0]->{entry2} }
    sub entry3
        { $_[0]->{entry3} }
    sub checkButton
        { $_[0]->{checkButton} }
    sub radioButton
        { $_[0]->{radioButton} }
    sub radioButton2
        { $_[0]->{radioButton2} }
    sub radioButton3
        { $_[0]->{radioButton3} }
    sub radioButton4
        { $_[0]->{radioButton4} }
    sub comboBox
        { $_[0]->{comboBox} }
    sub addCharButton
        { $_[0]->{addCharButton} }
    sub editPwdButton
        { $_[0]->{editPwdButton} }
    sub editAccButton
        { $_[0]->{editAccButton} }
    sub websiteLabel
        { $_[0]->{websiteLabel} }
    sub connectionLabel
        { $_[0]->{connectionLabel} }
    sub descripTextView
        { $_[0]->{descripTextView} }
    sub descripBuffer
        { $_[0]->{descripBuffer} }
    sub createWorldButton
        { $_[0]->{createWorldButton} }
    sub resetWorldButton
        { $_[0]->{resetWorldButton} }
    sub offlineButton
        { $_[0]->{offlineButton} }
    sub connectButton
        { $_[0]->{connectButton} }

    sub tooltips
        { $_[0]->{tooltips} }

    sub defaultIcon
        { $_[0]->{defaultIcon} }
    sub imageWidth
        { $_[0]->{imageWidth} }
    sub imageHeight
        { $_[0]->{imageHeight} }
    sub tableWidth
        { $_[0]->{tableWidth} }
    sub tableHeight
        { $_[0]->{tableHeight} }

    sub worldHash
        { my $self = shift; return %{$self->{worldHash}}; }
    sub miniWorldHash
        { my $self = shift; return %{$self->{miniWorldHash}}; }
    sub worldObj
        { $_[0]->{worldObj} }
    sub miniWorldObj
        { $_[0]->{miniWorldObj} }
    sub updateFlag
        { $_[0]->{updateFlag} }

    sub newWorldString
        { $_[0]->{newWorldString} }
    sub noCharString
        { $_[0]->{noCharString} }
    sub noWebsiteString
        { $_[0]->{noWebsiteString} }
    sub noConnectString
        { $_[0]->{noConnectString} }

    sub searchRegex
        { $_[0]->{searchRegex} }
    sub searchLanguage
        { $_[0]->{searchLanguage} }
}

{ package Games::Axmud::OtherWin::ClientConsole;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Client Console window, which can display system messages
        #   when there is no session running
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Only one Client Console window can be open at a time
        if ($axmud::CLIENT->consoleWin) {

            $axmud::CLIENT->consoleWin->restoreFocus();
            return undef;
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (for some 'free' windows, the same as the window type)
            winName                     => 'console',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,       # Gtk2::VBox

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => 600,
            heightPixels                => 300,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $axmud::SCRIPT . ' client console',
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # IVs for this window
            textView                    => undef,       # Gtk2::TextView
            buffer                      => undef,       # Gtk2::TextBuffer
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

    sub winEnable {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->winSetup
        # After the Gtk2::Window has been setup and moved into position, makes it visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

        # This type of window is unique (only one can be open at any time); inform the GA::Client
        #   it has opened
        $axmud::CLIENT->set_consoleWin($self);

        # If any system messages have been stored, we can display them now
        @list = $axmud::CLIENT->systemMsgList;
        if (@list) {

            do {

                my ($type, $msg);

                $type = shift @list;
                $msg = shift @list;

                $self->update($type, $msg);

            } until (! @list);
        }

        # Each system message is displayed here only once
        $axmud::CLIENT->reset_systemMsg();

        return 1;
    }

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

    sub winDestroy {

        # Can be called by anything
        # Updates IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the window can't be destroyed or if it has already
        #       been destroyed
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDestroy', @_);
        }

        if (! $self->winBox) {

            # Window already destroyed in a previous call to this function
            return undef;
        }

        # Close any 'free' windows for which this window is a parent
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Destroy the Gtk2::Window
        eval { $self->winBox->destroy(); };
        if ($@) {

            # Window can't be destroyed
            return undef;

        } else {

            $self->ivUndef('winWidget');
            $self->ivUndef('winBox');
        }

        # Inform the owner and the desktop object of this 'free' window's demise
        $axmud::CLIENT->desktopObj->del_freeWin($self);
        if ($self->owner) {

            $self->owner->del_childFreeWin($self);
        }

        # This type of window is unique (only one can be open at any time); inform the GA::Client
        #   it has closed
        $axmud::CLIENT->set_consoleWin();

        return 1;
    }

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the Client Console window with its standard widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # Create a textview
        my $scroller = Gtk2::ScrolledWindow->new(undef, undef);
        $packingBox->pack_start($scroller, TRUE, TRUE, 0);
        $scroller->set_shadow_type('etched-out');
        $scroller->set_policy('automatic', 'automatic');
        $scroller->set_border_width(5);

        # Use a textview with default colours/fonts
        $axmud::CLIENT->desktopObj->getTextViewStyle('main');
        my $textView = Gtk2::TextView->new();
        $scroller->add($textView);
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);
        $textView->set_editable(FALSE);
        $textView->set_cursor_visible(FALSE);
        $textView->can_focus(FALSE);
        $textView->set_wrap_mode('word-char');      # Wrap words if possible, characters if not

        # Create a mark at the end of the buffer, with right gravity, so that whenever text is
        #   inserted, we can scroll to that mark (and the mark stays at the end)
        my $endMark = $buffer->create_mark('end', $buffer->get_end_iter(), FALSE);

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('textView', $textView);
        $self->ivPoke('buffer', $buffer);

        # Create some colour tags, so that system messages can be displayed in their usual colours
        $self->createColourTags();

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub createColourTags {

        # Called by $self->drawWidgets
        # Create some Gtk2::TextTags, so that system messages can be shown in their usual colours
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->update', @_);
        }

        $self->buffer->create_tag(
            'system',
            'foreground'
                => $axmud::CLIENT->returnRGBColour($axmud::CLIENT->customShowSystemTextColour),
        );

        $self->buffer->create_tag(
            'error',
            'foreground'
                => $axmud::CLIENT->returnRGBColour($axmud::CLIENT->customShowErrorColour),
        );

        $self->buffer->create_tag(
            'warning',
            'foreground'
                => $axmud::CLIENT->returnRGBColour($axmud::CLIENT->customShowWarningColour),
        );

        $self->buffer->create_tag(
            'debug',
            'foreground'
                => $axmud::CLIENT->returnRGBColour($axmud::CLIENT->customShowDebugColour),
        );

        $self->buffer->create_tag(
            'improper',
            'foreground'
                => $axmud::CLIENT->returnRGBColour($axmud::CLIENT->customShowImproperColour),
        );

        return 1;
    }

    sub update {

        # Called by $self->winEnable and $axmud::CLIENT->add_systemMsg
        # Adds a system message to the window's textview
        #
        # Expected arguments
        #   $type   - The type of message (which determines the colour in which it's displayed) -
        #               'system', 'error', 'warning', 'debug' or 'improper'. If an invalid value or
        #               'undef', then the error message colour is used
        #   $msg    - The message to display. If 'undef' (for some reason), nothing is displayed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $type, $msg, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->update', @_);
        }

        if ($self->enabledFlag && defined $msg) {

            if (
                ! defined $type
                || (
                    $type ne 'system' && $type ne 'error' && $type ne 'warning' && $type ne 'debug'
                    && $type ne 'improper'
                )
            ) {
                $type = 'error';
            }

            # Only one newline character at the end of the message
            chomp $msg;
            $self->buffer->insert_with_tags_by_name(
                $self->buffer->get_end_iter(),
                $msg . "\n",
                $type,
            );

            # Scroll to the bottom
            $self->textView->scroll_to_mark($self->buffer->get_mark('end'), 0.0, TRUE, 0, 0);

            $self->winShowAll($self->_objClass . '->update');
        }

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub textView
        { $_[0]->{textView} }
    sub buffer
        { $_[0]->{buffer} }
}

{ package Games::Axmud::OtherWin::McpSimpleEdit;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Mcp::SimpleEdit->msg
        # Creates a new instance of the MCP Simple Edit window (an 'other' window). The window
        #   contains a textview in which the user can type text, and some widgets that specify what
        #   should be done with the text
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       'mcp_reference' - Supplied by the server's MCP message; a machine-
        #                           readable string that identifies the text to be sent back to the
        #                           server
        #                       'mcp_name' - Supplied by the server's MCP message; a human-readable
        #                           string to show the user what text is being edited
        #                       'mcp_content' - Supplied by the server's MCP message; the text to
        #                           edit; a string containing one or more lines joined with single
        #                           newline characters
        #                       'mcp_type' - The type of text being edited - 'string-list' or
        #                           'moo-code' for multiple lines (this window isn't called for
        #                           'string')
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (can be unique to this type of window object, or can be the
            #   same as ->winType)
            winName                     => 'mcp_simple_edit',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => int($axmud::CLIENT->constFreeWinWidth * 0.66),
            heightPixels                => int($axmud::CLIENT->constFreeWinHeight * 0.66),
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title
            title                       => 'MCP edit: ' . $configHash{'mcp_name'},
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

#   sub winEnable {}        # Inherited from GA::Generic::FreeWin

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}       # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the Gtk2::Window by drawing the window's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $title;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # At the top, create a textview
        my $scroller = Gtk2::ScrolledWindow->new(undef, undef);
        $packingBox->pack_start($scroller, TRUE, TRUE, 0);
        $scroller->set_shadow_type('etched-out');
        $scroller->set_policy('automatic', 'automatic');
        $scroller->set_border_width(0);

        # Create a textview with default colours/fonts
        $axmud::CLIENT->desktopObj->getTextViewStyle($self->winType);
        my $textView = Gtk2::TextView->new();
        $scroller->add($textView);
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);
        $textView->set_editable(TRUE);
        $textView->set_cursor_visible(TRUE);
        # ->signal_connect appears below

        # Set the initial contents of the textview
        $buffer->set_text($self->ivShow('configHash', 'mcp_content'));

        # At the bottom, create a button strip in a horizontal packing box
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_end($hBox, FALSE, FALSE, 0);

        # Create some buttons
        my $cancelButton = Gtk2::Button->new('Cancel');
        $hBox->pack_start($cancelButton, TRUE, TRUE, $self->borderPixels);
        $cancelButton->signal_connect('clicked' => sub {

            $self->winDestroy();
        });
        $cancelButton->set_sensitive(FALSE);

        my $saveButton = Gtk2::Button->new('Save');
        $hBox->pack_start($saveButton, TRUE, TRUE, $self->borderPixels);
        $saveButton->signal_connect('clicked' => sub {

            $self->doSave($buffer);
            $cancelButton->set_sensitive(FALSE);
        });

        my $saveCloseButton = Gtk2::Button->new('Save and close');
        $hBox->pack_end($saveCloseButton, TRUE, TRUE, $self->borderPixels);
        $saveCloseButton->signal_connect('clicked' => sub {

            $self->doSave($buffer);
            $self->winDestroy();
        });

        # ->signal_connect from above
        $buffer->signal_connect('changed' => sub {

            $cancelButton->set_sensitive(TRUE);
        });

        # Update IVs (not worth storing widgets other than the main packing box)
        $self->ivPoke('packingBox', $packingBox);

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub doSave {

        # Called by $self->drawWidgets
        # 'Saves' the contents of the window by sending an MSP message to the world
        #
        # Expected arguments
        #   $buffer     - The window's Gtk2::Buffer
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $buffer, $check) = @_;

        # Local variables
        my (
            $text,
            @list,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->doSave', @_);
        }

        $text = $axmud::CLIENT->desktopObj->bufferGetText($buffer);
        @list = split(/\n/, $text);

        # Send the MCP message (one or more multiline parts)
        $self->session->mcpSendMultiLine(
            'dns-org-mud-moo-simpleedit-set',
                'reference',
                $self->ivShow('configHash', 'mcp_reference'),
                'content',
                \@list,
                'type',
                $self->ivShow('configHash', 'mcp_type'),
        );

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::OtherWin::QuickInput;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Quick Input window (an 'other' window). The window contains
        #   a textview in which the user can type text, and some widgets that specify what should be
        #   done with the text
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (can be unique to this type of window object, or can be the
            #   same as ->winType)
            winName                     => 'quick_input',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => int($axmud::CLIENT->constFreeWinWidth * 0.66),
            heightPixels                => int($axmud::CLIENT->constFreeWinHeight * 0.66),
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title
            title                       => 'Quick input window',
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

#   sub winEnable {}        # Inherited from GA::Generic::FreeWin

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}       # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the Gtk2::Window by drawing the window's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $title;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # At the top, create a textview
        my $scroller = Gtk2::ScrolledWindow->new(undef, undef);
        $packingBox->pack_start($scroller, TRUE, TRUE, 0);
        $scroller->set_shadow_type('etched-out');
        $scroller->set_policy('automatic', 'automatic');
        $scroller->set_border_width(0);

        # Create a textview with default colours/fonts
        $axmud::CLIENT->desktopObj->getTextViewStyle($self->winType);
        my $textView = Gtk2::TextView->new();
        $scroller->add($textView);
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);
        $textView->set_editable(TRUE);
        $textView->set_cursor_visible(TRUE);

        # At the bottom, create a button strip in a horizontal packing box
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_end($hBox, FALSE, FALSE, 0);

        # Create some buttons
        my $radioButton = Gtk2::RadioButton->new(undef, 'Execute instructions');
        $hBox->pack_start($radioButton, 0, 0, $self->spacingPixels);

        my $checkButton = Gtk2::CheckButton->new_with_label('(ignore empty lines)');
        $hBox->pack_start($checkButton, 0, 0, $self->spacingPixels);

        my $radioButton2 = Gtk2::RadioButton->new($radioButton, 'Run as a script');
        $hBox->pack_start($radioButton2, 0, 0, $self->spacingPixels);

        my $okButton = Gtk2::Button->new('Send');
        $hBox->pack_end($okButton, TRUE, TRUE, $self->borderPixels);

        # ->signal_connects for the buttons
        $radioButton->signal_connect('toggled' => sub {

            if ($radioButton->get_active()) {

                $checkButton->set_sensitive(TRUE);
                $okButton->set_label('Send');
            }
        });

        $radioButton2->signal_connect('toggled' => sub {

            if ($radioButton2->get_active()) {

                $checkButton->set_active(FALSE);
                $checkButton->set_sensitive(FALSE);
                $okButton->set_label('Run');
            }
        });

        $okButton->signal_connect('clicked' => sub {

            my (
                $text,
                @cmdList, @finalList,
            );

            $text = $axmud::CLIENT->desktopObj->bufferGetText($buffer);

            # If the textview contains some text, and if the calling GA::Session still exists...
            if ($text && $axmud::CLIENT->ivExists('sessionHash', $self->session->number)) {

                if ($radioButton->get_active()) {

                    # Split the text into lines
                    @cmdList = split(/\n/, $text);

                    # Ignore empty lines, if required
                    if (! $checkButton->get_active()) {

                        @finalList = @cmdList;

                    } else {

                        # Remove empty lines
                        foreach my $cmd (@cmdList) {

                            if (! ($cmd =~ m/^\s*$/)) {

                                push (@finalList, $cmd);
                            }
                        }
                    }

                    # Send as instructions
                    foreach my $instruct (@finalList) {

                        $self->session->doInstruct($instruct);
                    }

                } else {

                    # Save the script as a temporary file, and execute it
                    $self->runScript($text);
                }
            }
        });

        # Update IVs (not worth storing widgets other than the main packing box)
        $self->ivPoke('packingBox', $packingBox);

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub runScript {

        # Called by $self->drawWidgets when the user clicks the 'Run' button
        # Runs the contents of the window as an Axbasic script
        #
        # Expected arguments
        #   $text       - The contents of the Gtk2::TextBuffer
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $text, $check) = @_;

        # Local variables
        my (
            $path, $fileHandle,
            @list,
        );

        # Check for improper arguments
        if (! defined $text || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->runScript', @_);
        }

        # Split $text into lines
        @list = split(/\n/, $text);

        # Save the script as a temporary file
        $path = $axmud::DATA_DIR . '/data/temp/quick.bas';

        # Open the file for writing, overwriting previous contents
        if (! open ($fileHandle, ">$path")) {

            return undef;
        }

        foreach my $line (@list) {

            $line .= "\n";
        }

        print $fileHandle @list;

        if (! close $fileHandle) {

            return undef;
        }

        # Run the script
        $self->session->pseudoCmd('runscript -p ' . $path, $self->pseudoCmdMode);

        # Delete the temporary file
        unlink $path;

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::OtherWin::QuickWord;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Quick Word window (an 'other' window). The window contains
        #   various widgets for adding words to the current dictionary
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (can be unique to this type of window object, or can be the
            #   same as ->winType)
            winName                     => 'quick_word',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,       # Gtk2::VBox

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            # (Actual width/height will be more, in order to fit in all the packed widgets)
            widthPixels                 => int($axmud::CLIENT->constFreeWinWidth * 0.33),
            heightPixels                => int($axmud::CLIENT->constFreeWinHeight * 0.33),
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title
            title                       => $title,
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

#   sub winEnable {}        # Inherited from GA::Generic::FreeWin

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}       # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the Gtk2::Window by drawing the window's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $spacing, $dictObj, $comboBoxCount,
            @currentRoomList, @typeList,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Standard spacing
        $spacing = $axmud::CLIENT->constFreeSpacingPixels;
        # Import the current Locator task (if any) and current dictionary
        $dictObj = $self->session->currentDict;

        # A list of word types in the order they'll appear in their combobox
        @typeList = (
            'sentient',
            'creature',
            'portable',
            'decoration',
            'race',
            'guild',
            'weapon',
            'armour',
            'garment',
            'adjective',
            'pseudo-noun',
            'pseudo-adjective',
            'pseudo-object',
        );

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # Create an image on the left
        my $hBox = Gtk2::HBox->new(FALSE, $spacing);
        $packingBox->pack_start($hBox, FALSE, FALSE, 0);

        my $vBox = Gtk2::VBox->new(FALSE, 0);
        $hBox->pack_start($vBox, FALSE, FALSE, 0);

        my $frame = Gtk2::Frame->new(undef);
        $vBox->pack_start($frame, FALSE, FALSE, 0);
        $frame->set_size_request(64, 64);
        $frame->set_shadow_type('etched-in');

        my $image = Gtk2::Image->new_from_file($axmud::CLIENT->getDialogueIcon());
        $frame->add($image);

        # Create a VBox on the right, full of editing widgets
        my $vBox2 = Gtk2::VBox->new(FALSE, $spacing);
        $hBox->pack_start($vBox2, FALSE, FALSE, 0);

        # Add three radio buttons and an entry box/combo for each (->signal_connects follow)
        my $radioButton = Gtk2::RadioButton->new(undef, 'Enter a word...');
        my $radioGroup = $radioButton->get_group();
        $vBox2->pack_start($radioButton, FALSE, FALSE, 0);

        my $entry = Gtk2::Entry->new();
        $vBox2->pack_start($entry, FALSE, FALSE, 0);

        my $radioButton2 = Gtk2::RadioButton->new(
            $radioGroup,
            '...or select a word from the current room...',
        );
        $vBox2->pack_start($radioButton2, FALSE, FALSE, 0);

        my $comboBox = Gtk2::ComboBox->new_text();
        $vBox2->pack_start($comboBox, FALSE, FALSE, 0);
        $comboBox->set_active(FALSE);
        # Starts desensitised
        $comboBox->set_sensitive(FALSE);

        my $radioButton3 = Gtk2::RadioButton->new(
            $radioGroup,
            '...or select an unknown word',
        );
        $vBox2->pack_start($radioButton3, FALSE, FALSE, 0);

        my $comboBox2 = Gtk2::ComboBox->new_text();
        $vBox2->pack_start($comboBox2, FALSE, FALSE, 0);
        $comboBox2->set_active(FALSE);
        # Starts desensitised
        $comboBox2->set_sensitive(FALSE);

        my $separator = Gtk2::HSeparator->new();
        $vBox2->pack_start($separator, FALSE, FALSE, 0);

        # Add a fourth widget group, comboboxes to select the types of word
        my $label = Gtk2::Label->new('What kind of word is this?');
        $vBox2->pack_start($label, FALSE, FALSE, 0);
        $label->set_alignment(0, 0.5);

        my $hBox2 = Gtk2::HBox->new(FALSE, 0);
        $vBox2->pack_start($hBox2, FALSE, FALSE, 5);

        my $comboBox3 = Gtk2::ComboBox->new_text();
        $hBox2->pack_start($comboBox3, TRUE, TRUE, 0);
        foreach my $type (@typeList) {

            $comboBox3->append_text($type);
        }
        $comboBox3->set_active(FALSE);

        my $comboBox4 = Gtk2::ComboBox->new_text();
        $hBox2->pack_end($comboBox4, TRUE, TRUE, 0);
        $comboBox4->set_active(FALSE);
        $comboBox4->set_sensitive(FALSE);

        # And a fifth group to specify replacement strings for pseudo nouns, adjectives and objects
        my $label2 = Gtk2::Label->new('Replacement string (if any)');
        $vBox2->pack_start($label2, FALSE, FALSE, 0);
        $label2->set_alignment(0, 0.5);

        my $entry2 = Gtk2::Entry->new();
        $vBox2->pack_start($entry2, FALSE, FALSE, 0);
        # Entry starts insensitive
        $entry2->set_sensitive(FALSE);

        my $separator2 = Gtk2::HSeparator->new();
        $vBox2->pack_start($separator2, FALSE, FALSE, 0);

        # Finally, at buttons at the bottom of the window
        my $tooltips = Gtk2::Tooltips->new();

        my $label3 = Gtk2::Label->new('');
        $vBox2->pack_start($label3, FALSE, FALSE, 0);
        $label3->set_alignment(0, 0.5);

        my $hBox3 = Gtk2::HBox->new(FALSE, 0);
        $vBox2->pack_start($hBox3, FALSE, FALSE, 0);

        my $button = Gtk2::Button->new('Add word');
        $hBox3->pack_start($button, TRUE, TRUE, 0);
        $tooltips->set_tip($button, 'Add this word');

        my $button2 = Gtk2::Button->new('Ignore word');
        $hBox3->pack_start($button2, TRUE, TRUE, 0);
        $button2->set_sensitive(FALSE);     # Starts desensitised
        $tooltips->set_tip($button, 'Ignore (don\'t use) this word');

        my $button3 = Gtk2::Button->new('Refresh');
        $hBox3->pack_start($button3, TRUE, TRUE, 0);
        $button3->signal_connect('clicked' => sub {

            $self->refreshCombos($dictObj, $comboBox, $comboBox2);
        });

        my $button4 = Gtk2::Button->new('Close');
        $hBox3->pack_end($button4, TRUE, TRUE, 0);
        $button4->signal_connect('clicked' => sub {

            $self->winDestroy();
        });
        $tooltips->set_tip($button4, 'Close the window');

        # Set the initial contents of the first two comboboxes
        $self->refreshCombos($dictObj, $comboBox, $comboBox2);

        # ->signal_connects

        # Radio buttons. Toggling them sensitises/desensitises the first three widgets
        $radioButton->signal_connect('toggled' => sub {

            if ($radioButton->get_active()) {

                $entry->set_sensitive(TRUE);
                $comboBox->set_sensitive(FALSE);
                $comboBox2->set_sensitive(FALSE);
                $button2->set_sensitive(FALSE);
            }
        });

        $radioButton2->signal_connect('toggled' => sub {

            if ($radioButton2->get_active()) {

                $entry->set_sensitive(FALSE);
                $comboBox->set_sensitive(TRUE);
                $comboBox2->set_sensitive(FALSE);
                $button2->set_sensitive(FALSE);
            }
        });

        $radioButton3->signal_connect('toggled' => sub {

            if ($radioButton3->get_active()) {

                $entry->set_sensitive(FALSE);
                $comboBox->set_sensitive(FALSE);
                $comboBox2->set_sensitive(TRUE);
                $button2->set_sensitive(TRUE);
            }
        });

        # Fourth group
        $comboBox3->signal_connect('changed' => sub {

            my $type = $comboBox3->get_active_text();
            if ($type) {

                # Empty the 'type of portable/decoration' combobox, in case we need to refill it
                if ($comboBoxCount) {

                    for (my $count = ($comboBoxCount - 1); $count >= 0; $count--) {

                        $comboBox4->remove_text($count);
                    }
                }

                # Refill the lower combobox, if necessary
                if ($type eq 'portable') {

                    foreach my $custom ($dictObj->portableTypeList) {

                        $comboBox4->append_text($custom);
                    }

                    $comboBox4->set_active(FALSE);
                    $comboBox4->set_sensitive(TRUE);
                    $comboBoxCount = scalar $dictObj->portableTypeList;

                } elsif ($type eq 'decoration') {

                    foreach my $custom ($dictObj->decorationTypeList) {

                        $comboBox4->append_text($custom);
                    }

                    $comboBox4->set_active(FALSE);
                    $comboBox4->set_sensitive(TRUE);
                    $comboBoxCount = scalar $dictObj->decorationTypeList;

                } else {

                    # If it's not a portable or decoration, the lower combobox must be insensitive
                    $comboBox4->set_sensitive(FALSE);
                    $comboBoxCount = 0;
                }

                if (
                    $type eq 'pseudo-noun'
                    || $type eq 'pseudo-adjective'
                    || $type eq 'pseudo-object'
                ) {
                    # Make the replacement string entry sensitive
                    $entry2->set_sensitive(TRUE);

                } else {

                    # Empty the box and make it insensitive
                    $entry2->set_text('');
                    $entry2->set_sensitive(FALSE);
                }
            }
        });

        # 'Add word' button
        $button->signal_connect('clicked' => sub {

            my (
                $word, $wordType, $category, $replace, $cmd, $result, $msg,
                @newList,
            );

            # Get the word to add
            if ($radioButton->get_active()) {
                $word = $entry->get_text();
            } elsif ($radioButton2->get_active()) {
                $word = $comboBox->get_active_text();
            } elsif ($radioButton3->get_active()) {
                $word = $comboBox2->get_active_text();
            }

            # Get the type of word, and the category (for portables/decorations)
            $wordType = $comboBox3->get_active_text();
            $category = $comboBox4->get_active_text();

            # Get the replacement string for pseudos
            $replace = $entry2->get_text();

            if ($word && $wordType) {

                # Prepare the client command to use
                $cmd = 'addword ';

                if ($wordType eq 'sentient') {
                    $cmd .= '-s <' . $word . '>';
                } elsif ($wordType eq 'creature') {
                    $cmd .= '-k <' . $word . '>';
                } elsif ($wordType eq 'race') {
                    $cmd .= '-r <' . $word . '>';
                } elsif ($wordType eq 'guild') {
                    $cmd .= '-g <' . $word . '>';
                } elsif ($wordType eq 'weapon') {
                    $cmd .= '-w <' . $word . '>';
                } elsif ($wordType eq 'armour') {
                    $cmd .= '-a <' . $word . '>';
                } elsif ($wordType eq 'garment') {
                    $cmd .= '-e <' . $word . '>';
                } elsif ($wordType eq 'adjective') {
                    $cmd .= '-j <' . $word . '>';
                } elsif ($wordType eq 'portable' && $category) {
                    $cmd .= '-p <' . $word . '> <' . $category . '>';
                } elsif ($wordType eq 'decoration' && $category) {
                    $cmd .= '-d <' . $word . '> <' . $category . '>';
                } elsif ($wordType eq 'pseudo-noun' && $replace) {

                    # Replacement string compulsory for pseudo-nouns
                    $cmd .= '-x <' . $replace . '> <' . $word . '>';

                } elsif ($wordType eq 'pseudo-adjective') {

                    # Replacement optional for pseudo-adjectives
                    $cmd .= '-y <' . $replace . '> <' . $word . '>';

                } elsif ($wordType eq 'pseudo-object') {

                    # Replacement optional for pseudo-objects
                    $cmd .= '-v <' . $word . '> <' . $replace . '>';
                }

                # Add the word
                $result = $self->session->pseudoCmd($cmd, $self->pseudoCmdMode);

                # Prepare a confirmation to show in the last Gtk2::Label
                if ($result) {

                    if ($wordType eq 'portable' || $wordType eq 'decoration') {

                        $msg = '<i>Added ' . $wordType . ' (' . $category . ') \'' . $word
                                . '\'</i>';

                    } else {

                        $msg = '<i>Added ' . $wordType . ' \'' . $word . '\'</i>';
                    }

                } else {

                    $msg = '<i>Failed to add ' . $wordType . ' \'' . $word . '\'</i>';
                }

            } else {

                # Clear the confirmation label
                $msg = '';
            }

            # Show the confirmation message
            $label3->set_markup($msg);

            if ($result) {

                # If we've just added a word from the room, it should be removed from the combo
                # If we've just added an unknown word, the dictionary's list of unknown words will
                #   have changed. Update the combo
                if (
                    $radioButton2->get_active()
                    || $radioButton3->get_active()
                ) {
                    $self->refreshCombos($dictObj, $comboBox, $comboBox2);
                }
            }
        });

        # 'Ignore word' button
        $button2->signal_connect('clicked' => sub {

            my $word = $comboBox2->get_active_text();
            if ($word) {

                $label3->set_markup('Ignoring \'' . $word . '\'');

                # Remove this word from the current dictionary's unknown word collection
                $self->session->currentDict->ivDelete('unknownWordHash', $word);

                # Update the combos
                $self->refreshCombos($dictObj, $comboBox, $comboBox2);
            }
        });

        # Update IVs (not worth storing widgets other than the main packing box)
        $self->ivPoke('packingBox', $packingBox);

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub refreshCombos {

        # Called by $self->drawWidgets
        # Refreshes the contents of the first two comboboxes
        #
        # Expected arguments
        #   $dictObj    - The current dictionary
        #   $comboBox, $comboBox2
        #               - The comboboxes to refresh
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $dictObj, $comboBox, $comboBox2, $check) = @_;

        # Local variables
        my (
            $taskObj,
            @unknownList, @collectedList,
            %wordHash,
        );

        # Check for improper arguments
        if (! defined $dictObj || ! defined $comboBox || ! defined $comboBox2 || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->refreshCombos', @_);
        }

        # Import the current Locator task (if any)
        $taskObj = $self->session->locatorTask;

        # Compile a list of words (which aren't already in the dictionary) from objects in the
        #   Locator task's current room
        if (
            $taskObj
            && $taskObj->roomObj
            && $taskObj->roomObj->tempObjList
        ) {
            OUTER: foreach my $obj ($taskObj->roomObj->tempObjList) {

                my @wordList;

                push (@wordList,
                    $obj->noun,
                    $obj->otherNounList,
                    $obj->adjList,
                    $obj->pseudoAdjList,
                    $obj->unknownWordList,
                );

                foreach my $word (@wordList) {

                    # If the word isn't in the current dictionary, mark it to be added to the
                    #   combobox. Use a hash to eliminate duplicates
                    if (
                        ! $dictObj->ivExists('combNounHash', $word)
                        && ! $dictObj->ivExists('combAdjHash', $word)
                    ) {
                        $wordHash{$word} = undef;
                    }
                }
            }

            # Convert the hash to a sorted list
            @unknownList = sort {lc($a) cmp lc($b)} (keys %wordHash);
        }

        # Import the list of unknown words collected by the Locator task and stored in the current
        #   dictionary
        @collectedList = sort {lc($a) cmp lc($b)} ($dictObj->ivKeys('unknownWordHash'));

        # Refresh the combos
        my $treeModel = $comboBox->get_model();
        $treeModel->clear();

        foreach my $item (@unknownList) {

            $comboBox->append_text($item);
        }

        $comboBox->set_active(0);

        my $treeModel2 = $comboBox2->get_model();
        $treeModel2->clear();

        foreach my $item (@collectedList) {

            $comboBox2->append_text($item);
        }

        $comboBox2->set_active(0);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::OtherWin::PatternTest;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Pattern test window, which allows the user to to test
        #   patterns (regexes) on the fly
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Local variables
        my ($widthPixels, $heightPixels);

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (for some 'free' windows, the same as the window type)
            winName                     => 'pattern_test',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,       # Gtk2::VBox

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $axmud::CLIENT->customFreeWinWidth,
            heightPixels                => $axmud::CLIENT->customFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => 'Pattern tester',
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # IVs for this type of window

            # Tooltips widget used by all buttons
            tooltips                    => undef,       # Gtk2::Tooltips

            # Standard size of the Gtk2::Table used (a 12x12 table, with a spare cell around every
            #   border)
            tableWidth                  => 13,
            tableHeight                 => 13,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

#   sub winEnable {}        # Inherited from GA::Generic::FreeWin

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}     # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the Pattern Test window with its standard widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # Create a Gtk2::Tooltips object, used by various buttons
        my $tooltips = Gtk2::Tooltips->new();

        # Update IVs immediately, so various buttons can use the tooltips
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('tooltips', $tooltips);

        # Create an image on the left
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_start($hBox, TRUE, TRUE, 0);

        my $vBox = Gtk2::VBox->new(FALSE, 0);
        $hBox->pack_start($vBox, FALSE, FALSE, 0);

        my $frame = Gtk2::Frame->new(undef);
        $vBox->pack_start($frame, FALSE, FALSE, 0);
        $frame->set_size_request(64, 64);
        $frame->set_shadow_type('etched-in');

        my $image = Gtk2::Image->new_from_file($axmud::CLIENT->getDialogueIcon());
        $frame->add($image);

        # Create a table inside a scroller on the right
        my $scroller = Gtk2::ScrolledWindow->new();
        $hBox->pack_start($scroller, TRUE, TRUE, $self->spacingPixels);
        $scroller->set_policy(qw/automatic automatic/);

        my $table = Gtk2::Table->new($self->tableHeight, $self->tableWidth, FALSE);
        $scroller->add_with_viewport($table);
        $table->set_col_spacings($self->spacingPixels);
        $table->set_row_spacings($self->spacingPixels);

        # Create a button at the bottom to close the window
        my $hBox2 = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_end($hBox2, FALSE, FALSE, 0);

        # The button's label includes some extra space characters to make it a little easier to
        #   click on
        my $okButton = Gtk2::Button->new('  OK  ');
        $hBox2->pack_end($okButton, FALSE, FALSE, 0);
        $okButton->signal_connect('clicked' => sub {

            $self->winDestroy();
        });

        # Add some editing widgets. The ->signal_connect appear below
        $self->addLabel($table, '<b>Pattern / regular expression / regex tester</b>',
            1, 12, 1, 2);

        $self->addLabel($table, 'Pattern',
            1, 3, 2, 3);
        my $entry = $self->addEntry($table, undef, undef, TRUE,
            3, 12, 2, 3);
        $entry->set_icon_from_stock('secondary', 'gtk-no');

        $self->addLabel($table, 'Line',
            1, 3, 3, 4);
        my $entry2 = $self->addEntry($table, undef, undef, TRUE,
            3, 12, 3, 4);

        $self->addLabel($table, 'Substitution',
            1, 3, 4, 5);
        my $entry3 = $self->addEntry($table, undef, undef, TRUE,
            3, 12, 4, 5);

        my $button = $self->addButton(
            $table,
            undef,
            'Test the pattern\'s validity',
            'Test the pattern\'s validity',
            1, 6, 5, 6);

        my $button2 = $self->addButton(
            $table,
            undef,
            'Match the pattern against the line',
            'i.e. $line =~ m/$pattern/',
            6, 12, 5, 6);
        $button2->set_sensitive(FALSE);

        my $button3 = $self->addButton(
            $table,
            undef,
            'Use the pattern to apply the substitution to the line',
            'i.e. $line =~ s/$pattern/$substitution/',
            1, 8, 6, 7);
        $button3->set_sensitive(FALSE);

        my $button4 = $self->addButton(
            $table,
            undef,
            'Clear all',
            'Clear all the entry boxes',
            8, 12, 6, 7);

        $self->addLabel($table, 'Result',
            1, 3, 7, 8);
        my $entry4 = $self->addEntry($table, undef, undef, TRUE,
            3, 12, 7, 8);
        $entry4->set_editable(FALSE);

        # Add a simple list to show group substrings
        @columnList = (
            'Substring #', 'int',
            'Matching substring', 'text',
        );

        my $frame2 = Gtk2::Frame->new(undef);
        $table->attach_defaults($frame2, 1, 12, 8, 12);
        $frame2->set_border_width(0);

        my $scroller2 = Gtk2::ScrolledWindow->new();
        $frame2->add($scroller2);
        $scroller2->set_shadow_type('none');
        $scroller2->set_policy('automatic', 'automatic');
        $scroller2->set_border_width(0);
        $scroller2->set_size_request(-1, 180);

        my $slWidget = Games::Axmud::Gtk::Simple::List->new(@columnList);
        $scroller2->add($slWidget);

        # ->signal_connects
        $entry->signal_connect('changed' => sub {

            my $regex = $entry->get_text();

            # GA::Client->regexCheck returns 'undef' for a valid regex, or an error message for an
            #   invalid one
            if (
                defined $regex
                && $regex ne ''
                && ! defined $axmud::CLIENT->regexCheck($regex)
            ) {
                $entry->set_icon_from_stock('secondary', 'gtk-yes');

                if (length $entry2->get_text() > 0) {
                    $button2->set_sensitive(TRUE);
                } else {
                    $button2->set_sensitive(FALSE);
                }

                if (length $entry3->get_text() > 0) {
                    $button3->set_sensitive(TRUE);
                } else {
                    $button3->set_sensitive(FALSE);
                }

            } else {

                $entry->set_icon_from_stock('secondary', 'gtk-no');
                $button2->set_sensitive(FALSE);
                $button3->set_sensitive(FALSE);
            }
        });

        $entry2->signal_connect('changed' => sub {

            my ($regex, $line, $substitution);

            $regex = $entry->get_text();
            $line = $entry2->get_text();
            $substitution = $entry3->get_text();

            if (
                ! defined $axmud::CLIENT->regexCheck($regex)
                && length $line > 0
            ) {
                $button2->set_sensitive(TRUE);
                if (length $substitution > 0) {
                    $button3->set_sensitive(TRUE);
                } else {
                    $button3->set_sensitive(FALSE);
                }

            } else {

                $button2->set_sensitive(FALSE);
                $button3->set_sensitive(FALSE);
            }
        });

        $entry3->signal_connect('changed' => sub {

            my ($regex, $line, $substitution);

            $regex = $entry->get_text();
            $line = $entry2->get_text();
            $substitution = $entry3->get_text();

            if (
                ! defined $axmud::CLIENT->regexCheck($regex)
                && length $line > 0
                && length $substitution > 0
            ) {
                $button3->set_sensitive(TRUE);
            } else {
                $button3->set_sensitive(FALSE);
            }
        });

        $button->signal_connect('clicked' => sub {

            my ($regex, $result);

            $regex = $entry->get_text();

            if (! defined $regex || $regex eq '') {

                $entry4->set_text('');

            } else {

                $result = $axmud::CLIENT->regexCheck($regex);
                if (! defined $result) {

                    $entry4->set_text('<Pattern is valid>');
                    $entry4->set_icon_from_stock('secondary', 'gtk-yes');

                } else {

                    # Perl error message
                    $entry4->set_text($result);
                    $entry4->set_icon_from_stock('secondary', 'gtk-no');
                }
            }
        });

        $button2->signal_connect('clicked' => sub {

            my (
                $regex, $line, $count,
                @grpStringList, @dataList,
            );

            $regex = $entry->get_text();
            $line = $entry2->get_text();

            @grpStringList = ($line =~ m/$regex/);
            if (@grpStringList) {

                if ((scalar @-) > 1) {

                    $count = 0;
                    foreach my $grpString (@grpStringList) {

                        $count++;
                        push (@dataList, [$count, $grpString]);
                    }
                }

                $entry4->set_text('<Pattern matches the line>');
                $entry4->set_icon_from_stock('secondary', 'gtk-yes');
                @{$slWidget->{data}} = @dataList;

            } else {

                $entry4->set_text('<Pattern does NOT match the line>');
                $entry4->set_icon_from_stock('secondary', 'gtk-no');
                @{$slWidget->{data}} = ();
            }
        });

        $button3->signal_connect('clicked' => sub {

            my ($regex, $line, $substitution);

            $regex = $entry->get_text();
            $line = $entry2->get_text();
            $substitution = $entry3->get_text();

            if ($line =~ s/$regex/$substitution/) {

                $entry4->set_text($line);
                $entry4->set_icon_from_stock('secondary', 'gtk-yes');
                @{$slWidget->{data}} = ();

            } else {

                $entry4->set_text('<Pattern does NOT match the line>');
                $entry4->set_icon_from_stock('secondary', 'gtk-no');
                @{$slWidget->{data}} = ();
            }
        });

        $button4->signal_connect('clicked' => sub {

            $entry->set_text('');
            $entry->set_icon_from_stock('secondary', undef);

            $entry2->set_text('');
            $entry3->set_text('');

            $entry4->set_icon_from_stock('secondary', undef);
            $entry4->set_text('');

            @{$slWidget->{data}} = ();
        });

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub tooltips
        { $_[0]->{tooltips} }

    sub tableWidth
        { $_[0]->{tableWidth} }
    sub tableHeight
        { $_[0]->{tableHeight} }
}

{ package Games::Axmud::OtherWin::SessionConsole;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::OtherWin::ClientConsole Games::Axmud::Generic::OtherWin
        Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Session Console window, which can display system messages
        #   when it's not possible to display them in the 'main' window
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Only one Session Console window can be open per session
        if (! $session) {

            return undef;

        } elsif ($session->consoleWin) {

            $session->consoleWin->restoreFocus();
            return undef;
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (for some 'free' windows, the same as the window type)
            winName                     => 'console',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,       # Gtk2::VBox

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => 600,
            heightPixels                => 300,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $axmud::SCRIPT . ' session console #' . $session->number,
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # IVs for this window
            textView                    => undef,       # Gtk2::TextView
            buffer                      => undef,       # Gtk2::TextBuffer
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

    sub winEnable {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->winSetup
        # After the Gtk2::Window has been setup and moved into position, makes it visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

        # This type of window is unique (only one can be open per session); inform the GA::Session
        #   it has opened
        $self->session->set_consoleWin($self);

        # If any system messages have been stored, we can display them now
        @list = $self->session->systemMsgList;
        if (@list) {

            do {

                my ($type, $msg);

                $type = shift @list;
                $msg = shift @list;

                $self->update($type, $msg);

            } until (! @list);
        }

        # Each system message is displayed here only once
        $self->session->reset_systemMsg();

        return 1;
    }

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

    sub winDestroy {

        # Can be called by anything
        # Updates IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the window can't be destroyed or if it has already
        #       been destroyed
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDestroy', @_);
        }

        if (! $self->winBox) {

            # Window already destroyed in a previous call to this function
            return undef;
        }

        # Close any 'free' windows for which this window is a parent
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Destroy the Gtk2::Window
        eval { $self->winBox->destroy(); };
        if ($@) {

            # Window can't be destroyed
            return undef;

        } else {

            $self->ivUndef('winWidget');
            $self->ivUndef('winBox');
        }

        # Inform the owner and the desktop object of this 'free' window's demise
        $axmud::CLIENT->desktopObj->del_freeWin($self);
        if ($self->owner) {

            $self->owner->del_childFreeWin($self);
        }

        # This type of window is unique (only one can be open per session); inform the GA::Session
        #   it has closed
        $self->session->set_consoleWin();

        return 1;
    }

#   sub winShowAll {}       # Inherited from GA::Generic::Win

#   sub drawWidgets {}      # Inherited from GA::OtherWin::ClientConsole

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

#   sub createColourTags {} # Inherited from GA::OtherWin::ClientConsole

#   sub update {}           # Inherited from GA::OtherWin::ClientConsole

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::OtherWin::Simulate;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Simulate window (an 'other' window). The window contains a
        #   textview in which the user can type text. When the 'Simulate' button is clicked, the
        #   contents of the textview (if any) is combined into a single string (with multiple lines
        #   separated by newline characters). The string is then used in a ';simulateworld' command,
        #   and appears in the session's default textview, as if it had been received from the world
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       'type' => Which client command to use with the contents of the
        #                           textview, when the 'Simulate' button is clicked - 'world' or
        #                           'prompt'. If not specified, 'world' is used
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Set the values to use for some standard window IVs
        if (defined $configHash{'type'} && $configHash{'type'} eq 'prompt') {
            $title = 'Simulate prompt';
        } else {
            $title = 'Simulate world';
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (can be unique to this type of window object, or can be the
            #   same as ->winType)
            winName                     => 'simulate',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => int($axmud::CLIENT->constFreeWinWidth * 0.66),
            heightPixels                => int($axmud::CLIENT->constFreeWinHeight * 0.66),
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title
            title                       => $title,
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

#   sub winEnable {}        # Inherited from GA::Generic::FreeWin

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}       # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the Gtk2::Window by drawing the window's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $width, $height, $title, $sampleText, $sampleUnderlay,
            @tagList,
            %prettyHash, %reversePrettyHash, %ansiHash,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Import the list of Axmud standard colour/style tags (which also includes the dummy tags
        #   like 'bold', 'reverse_off' and 'attribs_off')
        @tagList = $axmud::CLIENT->constColourStyleList;
        # (For convenience, add 'attribs_off' to both the beginning and end of the list)
        unshift(@tagList, 'attribs_off');
        # Also import the hash of pretty names for each standard tag, in which the keys are the
        #   items in @tagList
        %prettyHash = $axmud::CLIENT->constPrettyTagHash;
        # Use a reverse hash too, so we can work out which combobox item was selected
        %reversePrettyHash = reverse %prettyHash;

        # Prepare a hash of ANSI escape sequences which the user can insert at any place in the
        #   textview, in the form
        #       $ansiHash{tag} = number_of_ANSI_escape_sequence
        %ansiHash = (
            (reverse $axmud::CLIENT->constANSIColourHash),
            (reverse $axmud::CLIENT->constANSIStyleHash),
        );

        $ansiHash{'bold'} = 1;
        $ansiHash{'bold_off'} = 22;
        $ansiHash{'reverse'} = 7;
        $ansiHash{'reverse_off'} = 27;
        $ansiHash{'conceal'} = 8;
        $ansiHash{'conceal_off'} = 28;
        $ansiHash{'attribs_off'} = 0;

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # At the top, create a textview
        my $scroller = Gtk2::ScrolledWindow->new(undef, undef);
        $packingBox->pack_start($scroller, TRUE, TRUE, 0);
        $scroller->set_shadow_type('etched-out');
        $scroller->set_policy('automatic', 'automatic');
        $scroller->set_border_width(0);

        # Create a textview with default colours/fonts
        $axmud::CLIENT->desktopObj->getTextViewStyle($self->winType);
        my $textView = Gtk2::TextView->new();
        $scroller->add($textView);
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);
        $textView->set_editable(TRUE);
        $textView->set_cursor_visible(TRUE);

        # At the bottom, create a button strip in a horizontal packing box
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_end($hBox, FALSE, FALSE, 0);

        # Create a combo
        my $comboBox = Gtk2::ComboBox->new_text();
        $hBox->pack_start($comboBox, 0, 0, $self->borderPixels);
        $title = 'Add an ANSI escape sequence:';
        $sampleText = 'Sample xterm-256 text colour';
        $sampleUnderlay = 'Sample xterm-256 underlay colour';
        $comboBox->append_text($title);
        foreach my $tag (@tagList) {

            $comboBox->append_text($prettyHash{$tag});

            # GA::Client->constColourStyleList doesn't include xterm colour tags, so we'll insert
            #   a sample text and a sample underlay colour right just before the style tags
            if ($tag eq 'ul_white') {

                $comboBox->append_text($sampleText);
                $comboBox->append_text($sampleUnderlay);
            }
        }

        $comboBox->set_active(0);

        # Create the 'Add' button
        my $addButton = Gtk2::Button->new('Apply');
        $hBox->pack_start($addButton, 0, 0, $self->spacingPixels);
        $addButton->signal_connect('clicked' => sub {

            my ($prettyTag, $tag, $ansi);

            $prettyTag = $comboBox->get_active_text();
            if ($prettyTag) {

                if ($prettyTag eq $sampleText) {

                    # Use an example xterm-256 text colour (dark grey)
                    $ansi = chr(27) . '[38;5;234m';

                } elsif ($prettyTag eq $sampleUnderlay) {

                    # Use an example xterm-256 underlay colour (light orange)
                    $ansi = chr(27) . '[48;5;214m';

                } elsif ($prettyTag ne $title) {

                    # Get an Axmud colour/style tag (or one of the dummy tags like 'bold',
                    #   'reverse_off' and 'attribs_off')
                    $tag = $reversePrettyHash{$prettyTag};
                    # Convert it to an ANSI escape sequence
                    $ansi = chr(27) . '[' . $ansiHash{$tag} . 'm';
                }

                if ($ansi) {

                    $buffer->insert_at_cursor($ansi);
                }
            }
        });

        # Create the 'Simulate' button
        my $okButton = Gtk2::Button->new('Simulate');
        $hBox->pack_end($okButton, 0, 0, $self->borderPixels);
        $okButton->signal_connect('clicked' => sub {

            my ($text, $type);

            $text = $axmud::CLIENT->desktopObj->bufferGetText($buffer);
            $type = $self->ivShow('configHash', 'type');

            # If the textview contains some text, and if the calling GA::Session still exists...
            if ($text && $axmud::CLIENT->ivExists('sessionHash', $self->session->number)) {

                if ($type eq 'prompt') {

                    # Simulate a prompt received from the world. The TRUE argument means that the
                    #   'main' window's blinker shouldn't be turned on.
                    chomp $text;
                    $self->session->processIncomingData($text, TRUE);

                } else {

                    # Simulate text received from the world. The TRUE argument means that the main
                    #   window's blinker shouldn't be turned on.
                    $self->session->processIncomingData($text, TRUE);
                }
            }
        });

        # Create the 'Close' button
        my $cancelButton = Gtk2::Button->new('Close');
        $hBox->pack_end($cancelButton, 0, 0, $self->spacingPixels);
        $cancelButton->signal_connect('clicked' => sub {

            $self->winDestroy();
        });

        # Update IVs (not worth storing widgets other than the main packing box)
        $self->ivPoke('packingBox', $packingBox);

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::OtherWin::SourceCode;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Source Code Viewer (an 'other' window). The window contains
        #   a textview in which the source code for a world model object can be displayed (but not
        #   edited)
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       'model_obj' => Blessed reference to the model object whose source
        #                           code should be shown (GA::ModelObj::Room, etc). If not
        #                           specified, the window doesn't open
        #                       'virtual_flag' => If TRUE, the model is a room object, and we need
        #                           to view the file stored in the object's ->virtualAreaPath IV.
        #                           If not specified, FALSE (or 'undef'), we need to view the file
        #                           stored in the object's ->sourceCodePath IV
        #                       'path' => If defined, the filepath to use (which may be different to
        #                           the one stored in the object's ->virtualAreaPath). If not
        #                           specified, an empty string or 'undef', the object's
        #                           ->sourceCodePath is used. Ignored if 'virtual_flag' is TRUE
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (can be unique to this type of window object, or can be the
            #   same as ->winType)
            winName                     => 'source_code',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $axmud::CLIENT->customFreeWinWidth,
            heightPixels                => $axmud::CLIENT->customFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title
            title                       => 'Source code viewer',
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # IVs for this window

            # Full path to the file loaded
            file                        => undef,
            # The model object whose corresponding source code should be displayed
            modelObj                    => undef,
            # The contents of the source code file, once read by $self->readFile
            lineList                    => [],
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

    sub winSetup {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->new
        # Creates the Gtk2::Window itself
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be opened
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winSetup', @_);
        }

        # Before doing anything, try to read the file (and don't open this window if it can't be
        #   done)
        if (! $self->readFile()) {

            return undef;
        }

        # Create the Gtk2::Window
        my $winWidget = Gtk2::Window->new('toplevel');
        if (! $winWidget) {

            return undef;

        } else {

            # Store the IV now, as subsequent code needs it
            $self->ivPoke('winWidget', $winWidget);
            $self->ivPoke('winBox', $winWidget);
        }

        # Set up ->signal_connects
        $self->setDeleteEvent();            # 'delete-event'

        # Set the window title
        $winWidget->set_title($self->title);

        # Set the window's default size and position
        $winWidget->set_default_size($self->widthPixels, $self->heightPixels);
        $winWidget->set_border_width($self->borderPixels);
        $winWidget->set_position('center');

        # Set the icon list for this window
        $iv = $self->winType . 'WinIconList';
        $winWidget->set_icon_list($axmud::CLIENT->desktopObj->$iv);

        # Draw the widgets used by this window
        if (! $self->drawWidgets()) {

            return undef;
        }

        # The calling function can now call $self->winEnable to make the window visible
        return 1;
    }

#   sub winEnable {}        # Inherited from GA::Generic::FreeWin

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}       # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the Gtk2::Window by drawing the window's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # At the top, create a textview
        my $frame = Gtk2::Frame->new($self->title);
        $packingBox->pack_start($frame, TRUE, TRUE, 0);
        # Update the frame label
        $frame->set_label(
            'World model room #' . $self->modelObj->number . ' (' .  $self->file . ')',
        );
        $frame->set_border_width(0);

        my $scroller = Gtk2::ScrolledWindow->new(undef, undef);
        $frame->add($scroller);
        $scroller->set_shadow_type('etched-out');
        $scroller->set_policy('automatic', 'automatic');
        $scroller->set_border_width(5);

        # Create a textview with default colours/fonts
        $axmud::CLIENT->desktopObj->getTextViewStyle($self->winType);
        my $textView = Gtk2::TextView->new();
        $scroller->add($textView);
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);
        $textView->set_editable(FALSE);
        $textView->set_cursor_visible(FALSE);

        # Copy the contents of the file to the textview
        $buffer->set_text(join("\n", $self->lineList));

        # At the bottom, create a button strip in a horizontal packing box
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_end($hBox, FALSE, FALSE, 0);

        # Add a single button
        my $button = Gtk2::Button->new(' Close ');
        $hBox->pack_end($button, 0, 0, $self->borderPixels);
        $button->signal_connect('clicked' => sub {

            $self->winDestroy();
        });

        # Update IVs (not worth storing widgets other than the main packing box)
        $self->ivPoke('packingBox', $packingBox);

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub readFile {

        # Called by $self->winSetup before creating the Gtk2::Window
        # Performs a few checks, displaying a 'dialogue' window if the source code viewer window
        #   can't be opened for one reason or another
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the window should not be opened
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $worldModelObj, $obj, $virtualFlag, $sourcePath, $errorMsg, $file, $fileName,
            $fileHandle,
            @lineList,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->readFile', @_);
        }

        # Import the world model (for convenience)
        $worldModelObj = $self->session->worldModelObj;
        # Import some values from $self->configHash (for convenience)
        $obj = $self->ivShow('configHash', 'model_obj');
        $virtualFlag = $self->ivShow('configHash', 'virtual_flag');
        $sourcePath = $self->ivShow('configHash', 'path');

        # Check that the model object knows the source code of the equivalent mudlib object
        if (! $obj->sourceCodePath && ! $sourcePath) {

            $errorMsg = 'World model object #' . $obj->number . ' has no source code file set';

        } elsif ($virtualFlag) {

            if ($obj->category ne 'room') {

                $errorMsg = 'World model object #' . $obj->number . ' is not a room';

            } elsif (! $obj->virtualAreaPath) {

                $errorMsg = 'World model object #' . $obj->number . ' has no virtual area file set';
            }
        }

        if ($errorMsg) {

            $self->showMsgDialogue(
                'View source code',
                'error',
                $errorMsg,
                'ok',
            );

            return undef;
        }

        # Set the file to be displayed. If the current world model defines a mudlib directory,
        #   the object's ->mudlibPath is relative to that; otherwise it's an absolute path
        if ($worldModelObj->mudlibPath) {
            $file = $worldModelObj->mudlibPath;
        } else {
            $file = '';
        }

        if ($sourcePath && ! $virtualFlag) {

            # Use a different file than the one stored in the room object
            $fileName = $sourcePath;

        } elsif ($virtualFlag && $obj->category eq 'room') {

            # This is a room in a virtual area
            $fileName = $obj->virtualAreaPath;

        } else {

            # Any other kind of model object
            $fileName = $obj->sourceCodePath;
        }

        $file .= $fileName;

        # Add the file extension, if set
        if ($worldModelObj->mudlibExtension) {

            $file .= $worldModelObj->mudlibExtension;
        }

        # Check the file exists
        if (! (-e $file)) {

            $self->showMsgDialogue(
                'View source code',
                'error',
                'Can\'t find the file \'' . $file . '\'',
                'ok',
            );

            return undef;
        }

        # Open the file for reading
        if (! open ($fileHandle, "<$file")) {

            $self->showMessageDialogue(
                'View source code',
                'error',
                'Couldn\'t open the file ' . $file,
                'ok',
            );

            return undef;
        }

        # Read the file
        while (defined (my $line = <$fileHandle>)) {

            chomp $line;
            push (@lineList, $line);
        }

        # Close the file
        if (! close $fileHandle) {

            $self->showMsgDialogue(
                'View source code',
                'error',
                'Couldn\'t read the file ' . $file,
                'ok',
            );

            return undef;
        }

        # File read successfully. Update IVs
        $self->ivPoke('file', $file);
        $self->ivPoke('modelObj', $obj);
        $self->ivPoke('lineList', @lineList);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub file
        { $_[0]->{file} }
    sub modelObj
        { $_[0]->{modelObj} }
    sub lineList
        { my $self = shift; return @{$self->{lineList}}; }
}

{ package Games::Axmud::OtherWin::Viewer;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::OtherWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the object viewer window, which provides easy access to Axmud's
        #   stored data
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments or if no $session was specified
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Object viewer windows are unique to their session. If no $session is specified, refuse to
        #   create a window object
        if (! $session) {

            return undef;
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'viewer',
            # A name for the window (for some 'free' windows, the same as the window type)
            winName                     => 'viewer',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $axmud::CLIENT->customFreeWinWidth,
            heightPixels                => $axmud::CLIENT->customFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            # (A border width of 1 pixel or more would leave the background photo exposed)
            borderPixels                => 0,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $axmud::SCRIPT . ' object viewer',
            # Hash containing any number of key-value pairs needed for this particular 'free'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # IVs for this type of window

            # Widgets

            # Background image
            pixbuf                      => undef,       # Gtk2::Gdk::Pixbuf
            # A horizontal pane, dividing the treeview on the left from everything else on the right
            hPaned                      => undef,       # Gtk2::HPaned
            # The treeview components
            treeViewModel               => undef,       # Gtk2::TreeStore
            treeView                    => undef,       # Gtk2::TreeView
            treeViewScroller            => undef,       # Gtk2::ScrolledWindow
            # Another horizontal pane, dividing the strip of buttons on the right from everything
            #   in the middle
            hPaned2                     => undef,       # Gtk2::HPaned
            # The notebook
            notebook                    => undef,       # Gtk2::Notebook
            # A second vertical packing box containing the strip of buttons
            vBox                        => undef,       # Gtk2::VBox
            # The buttons themselves (children of $self->vBox2) - also contains any separators used
            #   in the button strip
            buttonList                  => [],

            # The object viewer window is divided into three areas - a treeview on the left,
            #   something in the middle, and a strip of buttons on the right (which are sometimes
            #   invisible)
            # The widths of these areas (in pixels). When the strip of buttons is hidden, the middle
            #   area swallows up the right area, and the right area is hidden
            leftWidth                   => int ($axmud::CLIENT->constFreeWinWidth * 0.3),
            centreWidth                 => int ($axmud::CLIENT->constFreeWinWidth * 0.5),
            rightWidth                  => int ($axmud::CLIENT->constFreeWinWidth * 0.2),

            # Which layout the notebook is using:
            #   'empty'     - contains nothing
            #   'list'      - a GA::Gtk::Simple::List on the left, and buttons on the right
            #   'text'      - a Gtk2::TextView
            notebookMode                => 'empty',
            # Which kind of notebook is currently being displayed - namely, which header in the
            #   treeview was the last one clicked (matches a key in $self->headerHash)
            notebookCurrentHeader       => undef,
            # When the user double-clicks an item in the notebook's list, the reference of the
            #   function which should be called in response (usually to make double-clicking the
            #   equivalent of clicking on one of the buttons)
            # Set to 'undef' if nothing should happen
            notebookSelectRef           => undef,

            # Hash of treeview headers, in the form
            #   $headerHash{header_string} = ref_of_subroutine
            headerHash                  => {},

            # List of notebok 'tab_name's in the same order used in the window
            #   (match the keys of ->notebookTabHash)
            notebookTabList             => [],
            # Hash of notebook tabs, in the form
            #   $notebookTagHash{tab_name} = reference_to_Gtk2::Label_of_tab
            notebookTabHash             => {},
            # Hash of data lists displayed in the notebook, in the form
            #   $notebookDataHash{tab_name} = reference_to_GA::Gtk::Simple::List
            notebookDataHash            => {},

            # To access Axbasic's default data, $self->setupTreeView creates a dummy
            #   Language::Axbasic::Script object, which is stored here so that functions like
            #   $self->axbasicHeader can use it
            dummyScriptObj              => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

    sub winEnable {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->winSetup
        # After the Gtk2::Window has been setup and moved into position, makes it visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

        # This type of window is unique to its GA::Session (only one can be open at any time, per
        #   session); inform the session it has opened
        $self->session->set_viewerWin($self);

        return 1;
    }

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

    sub winDestroy {

        # Can be called by anything
        # Updates IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the window can't be destroyed or if it has already
        #       been destroyed
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDestroy', @_);
        }

        if (! $self->winBox) {

            # Window already destroyed in a previous call to this function
            return undef;
        }

        # Close any 'free' windows for which this window is a parent
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Destroy the Gtk2::Window
        eval { $self->winBox->destroy(); };
        if ($@) {

            # Window can't be destroyed
            return undef;

        } else {

            $self->ivUndef('winWidget');
            $self->ivUndef('winBox');
        }

        # Inform the owner and the desktop object of this 'free' window's demise
        $axmud::CLIENT->desktopObj->del_freeWin($self);
        if ($self->owner) {

            $self->owner->del_childFreeWin($self);
        }

        # This type of window is unique to its GA::Session (only one can be open at any time, per
        #   session); inform the session it has closed
        $self->session->set_viewerWin();

        return 1;
    }

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the object viewer window with its standard widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Set up the window's background photo
        my $image = $axmud::SHARE_DIR . '/images/viewerbg.jpg';
        my $back_pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($image);
        my ($pixmap, $mask) = $back_pixbuf->render_pixmap_and_mask(255);
        my $style = $self->winWidget->get_style();
        $style = $style->copy();
        $style->bg_pixmap('normal', $pixmap);
        $self->winWidget->set_style($style);

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # Create a horizontal pane to divide the window into two, with the treeview on the left, and
        #   everything else on the right
        my $hPaned = Gtk2::HPaned->new();
        $packingBox->pack_start($hPaned, TRUE, TRUE, 0);

        # Add a treeview on the left of the window
        my $treeViewModel = Gtk2::TreeStore->new('Glib::String');
        my $treeView = Gtk2::TreeView->new($treeViewModel);
        $treeView->set_enable_search(FALSE);
        # Append a single column to the treeview
        $treeView->append_column(
            Gtk2::TreeViewColumn->new_with_attributes(
                'Objects',
                Gtk2::CellRendererText->new,
                text => 0,
            )
        );

        # Make the treeview scrollable
        my $treeViewScroller = Gtk2::ScrolledWindow->new();
        $hPaned->add1($treeViewScroller);
        $treeViewScroller->add($treeView);
        $treeViewScroller->set_policy(qw/automatic automatic/);

        # Make the branches of the list tree clickable, so the rows can be expanded and collapsed
        $treeView->signal_connect('row_activated' => \&treeViewRowActivated, $self);
        # Respond to clicks on the treeview
        $treeView->get_selection->set_mode('browse');
        $treeView->get_selection->signal_connect('changed' => \&treeViewChanged, $self);

        # Fill the tree
        $self->setupTreeView($treeView);

        # Add a notebook on the right. Later, this might be replaced by a second Gtk2::HPaned
        my $notebook = Gtk2::Notebook->new();
        $hPaned->add2($notebook);
        $notebook->set_scrollable(TRUE);

        $hPaned->set_position($self->leftWidth);
        $hPaned->child1_shrink(FALSE);
        $hPaned->child1_resize(FALSE);
        $hPaned->child2_shrink(FALSE);
        $hPaned->child2_resize(FALSE);

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('pixbuf', $back_pixbuf);
        $self->ivPoke('hPaned', $hPaned);
        $self->ivPoke('treeViewModel', $treeViewModel);
        $self->ivPoke('treeView', $treeView);
        $self->ivPoke('treeViewScroller', $treeViewScroller);
        $self->ivPoke('notebook', $notebook);

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    # Set up widgets

    sub setupTreeView {

        # Called by $self->enable
        # Fills the object tree on the left of the window
        #
        # Expected arguments
        #   $treeView  - The Gtk2::TreeView widget
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $treeView, $check) = @_;

        # Local variables
        my (
            $model, $pointer, $child, $grandChild, $greatGrandChild, $greatGreatGrandChild,
            $scriptObj,
            @sortedList, @functionList, @taskList,
            %functionHash,
        );

        # Check for improper arguments
        if (! defined $treeView || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupTreeView', @_);
        }

        # Fill a model of the tree, not the tree itself
        $model = $treeView->get_model();
        $model->clear();

        # Profiles
        $pointer = $model->append(undef);
        $model->set($pointer, 0 => 'Profiles');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'All profiles');
        $self->ivAdd('headerHash', 'All profiles', 'allProfHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Current profiles');
        $self->ivAdd('headerHash', 'Current profile', 'currentProfHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Profile templates');
        $self->ivAdd('headerHash', 'Profile templates', 'templateHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Profile priority list');
        $self->ivAdd('headerHash', 'Profile priority list', 'profPriorityHeader');

        # Cages
        $pointer = $model->append(undef);
        $model->set($pointer, 0 => 'Cages');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'All cages');
        $self->ivAdd('headerHash', 'All cages', 'allCageHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Current cages');
        $self->ivAdd('headerHash', 'Current cages', 'currentCageHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Active interfaces');
        $self->ivAdd('headerHash', 'Active interfaces', 'activeInterfaceHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Interface models');
        $self->ivAdd('headerHash', 'Interface models', 'interfaceModelHeader');

        # Dictionaries
        $pointer = $model->append(undef);
        $model->set($pointer, 0 => 'Dictionaries');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'All dictionaries');
        $self->ivAdd('headerHash', 'All dictionaries', 'allDictHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Current dictionary');
        $self->ivAdd('headerHash', 'Current dictionary', 'currentDictHeader');

        # Tasks
        $pointer = $model->append(undef);
        $model->set($pointer, 0 => 'Tasks');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'Available tasks');
        $self->ivAdd('headerHash', 'Available tasks', 'availableTaskHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Current tasklist');
        $self->ivAdd('headerHash', 'Current tasklist', 'currentTaskHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Global initial tasklist');
        $self->ivAdd('headerHash', 'Global initial tasklist', 'initialTaskHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Custom tasklist');
        $self->ivAdd('headerHash', 'Custom tasklist', 'customTaskHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Task package names');
        $self->ivAdd('headerHash', 'Task package names', 'taskPackageHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Task labels');
        $self->ivAdd('headerHash', 'Task labels', 'taskLabelHeader');

        # World model
        $pointer = $model->append(undef);
        $model->set($pointer, 0 => 'World model');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'All objects');
        $self->ivAdd('headerHash', 'All objects', 'allModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Regions');
        $self->ivAdd('headerHash', 'Regions', 'regionModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Rooms');
        $self->ivAdd('headerHash', 'Rooms', 'roomModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Weapons');
        $self->ivAdd('headerHash', 'Weapons', 'weaponModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Armours');
        $self->ivAdd('headerHash', 'Armours', 'armourModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Garments');
        $self->ivAdd('headerHash', 'Garments', 'garmentModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Characters');
        $self->ivAdd('headerHash', 'Characters', 'charModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Minions');
        $self->ivAdd('headerHash', 'Minions', 'minionModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Sentients');
        $self->ivAdd('headerHash', 'Sentients', 'sentientModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Creatures');
        $self->ivAdd('headerHash', 'Creatures', 'creatureModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Portables');
        $self->ivAdd('headerHash', 'Portables', 'portableModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Decorations');
        $self->ivAdd('headerHash', 'Decorations', 'decorationModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Custom objects');
        $self->ivAdd('headerHash', 'Custom objects', 'customModelHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Exits');
        $self->ivAdd('headerHash', 'Exits', 'exitModelHeader');

        # Buffers
        $pointer = $model->append(undef);
        $model->set($pointer, 0 => 'Buffers');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'Display buffer');
        $self->ivAdd('headerHash', 'Display buffer', 'displayBufferHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Instruction buffer');
        $self->ivAdd('headerHash', 'Instruction buffer', 'instructBufferHeader');
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Command buffer');
        $self->ivAdd('headerHash', 'Command buffer', 'cmdBufferHeader');

        # Other objects
        $pointer = $model->append(undef);
        $model->set($pointer, 0 => 'Other objects');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'Chat contacts');
        $self->ivAdd('headerHash', 'Chat contacts', 'chatContactHeader');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'Colour schemes');
        $self->ivAdd('headerHash', 'Colour schemes', 'colourSchemeHeader');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'Keycode objects');
        $self->ivAdd('headerHash', 'Keycode objects', 'keycodeHeader');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'TTS configurations');
        $self->ivAdd('headerHash', 'TTS configurations', 'ttsHeader');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'Winmaps');
        $self->ivAdd('headerHash', 'Winmaps', 'winmapHeader');

        $child = $model->append($pointer);
        $model->set($child, 0 => 'Zonemaps');
        $self->ivAdd('headerHash', 'Zonemaps', 'zonemapHeader');

        # Help
        $pointer = $model->append(undef);
        $model->set($pointer, 0 => 'Help');

        # Quick help
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Quick help');
        $self->ivAdd('headerHash', 'Quick help', 'quickHelpHeader');

        # Client command Help
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Client commands');

        $grandChild = $model->append($child);
        $model->set($grandChild, 0 => 'Categorised commands');

        foreach my $item ($axmud::CLIENT->clientCmdPrettyList) {

            if (index ($item, '@') == 0) {

                # It's a group heading, so remove the @ character
                $item =~ s/\@//;
                $greatGrandChild = $model->append($grandChild);
                $model->set($greatGrandChild, 0 => $item);

            } else {

                # It's a client command, which begins with ; to distinguish it from Axbasic items
                $item = $axmud::CLIENT->cmdSep . lc($item);
                $greatGreatGrandChild = $model->append($greatGrandChild);
                $model->set($greatGreatGrandChild, 0 => $item);
                $self->ivAdd('headerHash', $item, 'cmdHeader');
            }
        }

        $grandChild = $model->append($child);
        $model->set($grandChild, 0 => 'Sorted commands');

        @sortedList = sort {$a cmp $b} ($axmud::CLIENT->clientCmdList);
        foreach my $item (@sortedList) {

            # It's a client command, which begins with ; to distinguish it from Axbasic items
            $item = $axmud::CLIENT->cmdSep . lc($item);
            $greatGrandChild = $model->append($grandChild);
            $model->set($greatGrandChild, 0 => $item);
            $self->ivAdd('headerHash', $item, 'cmdHeader');
        }

        # Axbasic Help

        # Create a dummy LA::Script object so we can access the default instance variables and help
        #   functions
        $scriptObj = Language::Axbasic::Script->new($self->session);
        if ($scriptObj) {

            $child = $model->append($pointer);
            $model->set($child, 0 => $axmud::BASIC_NAME . ' help');

            $grandChild = $model->append($child);
            $model->set($grandChild, 0 => 'Keywords');

            foreach my $item ($scriptObj->keywordList) {

                $greatGrandChild = $model->append($grandChild);
                $model->set($greatGrandChild, 0 => $item);
                $self->ivAdd('headerHash', $item, 'axbasicKeywordHeader');
            }

            $grandChild = $model->append($child);
            $model->set($grandChild, 0 => 'Modern keywords');

            foreach my $item ($scriptObj->modernKeywordList) {

                $greatGrandChild = $model->append($grandChild);
                $model->set($greatGrandChild, 0 => $item);
                $self->ivAdd('headerHash', $item, 'axbasicKeywordHeader');
            }

            $grandChild = $model->append($child);
            $model->set($grandChild, 0 => 'Primitive keywords');

            foreach my $item ($scriptObj->primKeywordList) {

                $greatGrandChild = $model->append($grandChild);
                $model->set($greatGrandChild, 0 => $item);
                $self->ivAdd('headerHash', $item, 'axbasicKeywordHeader');
            }

            $grandChild = $model->append($child);
            $model->set($grandChild, 0 => 'Weak keywords');

            @sortedList = sort {$a cmp $b} ($scriptObj->ivKeys('weakKeywordHash'));
            foreach my $item (@sortedList) {

                $greatGrandChild = $model->append($grandChild);
                $model->set($greatGrandChild, 0 => $item);
                $self->ivAdd('headerHash', $item, 'axbasicKeywordHeader');
            }

            $grandChild = $model->append($child);
            $model->set($grandChild, 0 => 'Client keywords');

            foreach my $item ($scriptObj->clientKeywordList) {

                $greatGrandChild = $model->append($grandChild);
                $model->set($greatGrandChild, 0 => $item);
                $self->ivAdd('headerHash', $item, 'axbasicKeywordHeader');
            }

            $grandChild = $model->append($child);
            $model->set($grandChild, 0 => 'Task keywords');

            foreach my $item ($scriptObj->taskKeywordList) {

                $greatGrandChild = $model->append($grandChild);
                $model->set($greatGrandChild, 0 => $item);
                $self->ivAdd('headerHash', $item, 'axbasicKeywordHeader');
            }

            $grandChild = $model->append($child);
            $model->set($grandChild, 0 => 'Intrinsic functions');

            %functionHash = $scriptObj->funcArgHash;
            @functionList = sort {$a cmp $b} (keys %functionHash);
            foreach my $item (@functionList) {

                $greatGrandChild = $model->append($grandChild);
                $model->set($greatGrandChild, 0 => $item);
                $self->ivAdd('headerHash', $item, 'axbasicFuncHeader');
            }

            # (Store the dummy script object, so that functions like $self->axbasicHeader can use
            #   it)
            $self->ivPoke('dummyScriptObj', $scriptObj);
        }

        # Task Help
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Task help');

        @taskList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('taskPackageHash'));
        foreach my $task (@taskList) {

            $grandChild = $model->append($child);
            $model->set($grandChild, 0 => $task);
            $self->ivAdd('headerHash', $task, 'taskHeader');
        }

        # Peek/poke help
        $child = $model->append($pointer);
        $model->set($child, 0 => 'Peek/poke strings');
        $self->ivAdd('headerHash', 'Peek/poke strings', 'peekPokeHelpHeader');

        return 1;
    }

    sub refreshNotebook {

        # Called by $self->currentProfHeader, $self->allProfHeader, (etc etc)
        # Populates the notebook with tabs and a list, using the supplied arguments
        # (Header functions which need a textview, rather than a simple list, call
        #   ->refreshTextView)
        #
        # Expected arguments
        #   $tabListRef     - a reference to a hash of tabs, in the format
        #                   [
        #                       'tab_name' => 'tab_mnemonic',
        #                       'tab_name' => 'tab_mnemonic',
        #                       'tab_name' => 'tab_mnemonic',
        #                       ...
        #                   ]
        #
        #   $columnListRef  - a list of columns used in the call to GA::Gtk::Simple::List->new, in
        #                       the format
        #                   [
        #                       'column_name' => 'type',
        #                       'column_name' => 'type',
        #                       'column_name' => 'type',
        #                       ...
        #                   ]
        #
        #   $dataHashRef    - a reference to a hash. The keys are the same as the keys in
        #                       $tabListRef; the corresponding values contain a reference to a
        #                       two-dimensional list of data to be displayed in the
        #                       GA::Gtk::Simple::List, in the form
        #                   [
        #                       [row0_cell0, row0_cell1, row0cell2...],
        #                       [row1_cell0, row1_cell1, row1cell2...],
        #                       [row2_cell0, row2_cell1, row2cell2...],
        #                       ...
        #                   ]
        #
        # Optional arguments
        #   $buttonListRef  - a reference to a list of buttons, in the format
        #                   [
        #                       'button_name', 'tooltip', 'callback_sub_ref',
        #                       'button_name', 'tooltip', 'callback_sub_ref',
        #                       'button_name', 'tooltip', 'callback_sub_ref',
        #                       ...
        #                   ]
        #                   - if $buttonListRef is 'undef', no buttons are displayed
        #
        #   $scrollFlag     - if set to TRUE, the Gtk2::ScrolledWindow is scrolled to the bottom;
        #                       if FALSE (or 'undef'), it remains scrolled to the top
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $tabListRef, $columnListRef, $dataHashRef, $buttonListRef, $scrollFlag,
            $check,
        ) = @_;

        # Local variables
        my (
            $number, $tooltips, $dataListRef,
            @tabList, @columnList, @buttonList, @scrollerList,
            %dataHash,
        );

        # Check for improper arguments
        if (
            ! defined $tabListRef || ! defined $columnListRef || ! defined $dataHashRef
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->refreshNotebook', @_);
        }

        # Dereference the supplied arguments
        @tabList = @$tabListRef;
        @columnList = @$columnListRef;
        %dataHash = %$dataHashRef;
        if ($buttonListRef) {

            @buttonList = @$buttonListRef;
        };

        # Remove the existing tabs and buttons (if any)
        $self->resetNotebook();

        # If a button list was not visible, but should now be visible, do some repacking
        if (! $self->hPaned2 && $buttonListRef) {

            $axmud::CLIENT->desktopObj->removeWidget($self->hPaned, $self->notebook);

            # Add a second horizontal pane on the right of the first one
            # In this pane, a notebook is on the left, and a strip of buttons is on the right
            my $hPaned2 = Gtk2::HPaned->new();
            $self->hPaned->add2($hPaned2);

            # Repack the notebook on the left of $hPaned2
            $hPaned2->add1($self->notebook);

            # Add a second vertical packing box for the strip of buttons
            my $vBox = Gtk2::VBox->new(FALSE, 0);
            $hPaned2->add2($vBox);

            $self->hPaned->set_position($self->leftWidth);
            $self->hPaned->child1_shrink(TRUE);
            $self->hPaned->child1_resize(FALSE);
            $self->hPaned->child2_shrink(FALSE);
            $self->hPaned->child2_resize(FALSE);

            $hPaned2->set_position($self->centreWidth);
            $hPaned2->child1_shrink(FALSE);
            $hPaned2->child1_resize(FALSE);
            $hPaned2->child2_shrink(TRUE);
            $hPaned2->child2_resize(FALSE);

            # Update IVs
            $self->ivPoke('hPaned2', $hPaned2);
            $self->ivPoke('vBox', $vBox);

        # Likewise, if the button list was visible and is no longer required, do some repacking
        } elsif ($self->hPaned2 && ! $buttonListRef) {

            $axmud::CLIENT->desktopObj->removeWidget($self->hPaned2, $self->notebook);
            $axmud::CLIENT->desktopObj->removeWidget($self->hPaned, $self->hPaned2);

            $self->hPaned->add2($self->notebook);

            $self->hPaned->set_position($self->leftWidth);
            $self->hPaned->child1_shrink(TRUE);
            $self->hPaned->child1_resize(FALSE);
            $self->hPaned->child2_shrink(FALSE);
            $self->hPaned->child2_resize(FALSE);

            # Update IVs
            $self->ivUndef('hPaned2');
            $self->ivUndef('vBox');
        }

        # Create new tabs in the notebook
        do {

            my (
                $tab, $mnemonic, $slWidget, $scroller, $label, $slWidgetRef, $button, $count,
                $vAdjust,
                @ownColumnList,
            );

            $tab = shift @tabList;
            $mnemonic = shift @tabList;

            # Add a simple list
            $slWidget = Games::Axmud::Gtk::Simple::List->new(@columnList);
            # Make each row double-clickable
            $slWidget->signal_connect('row_activated' => sub {

                # If doubling-clicking on a row is equivalent to something else, call the specified
                #   function to make it happen
                if ($self->notebookSelectRef) {

                    &{$self->notebookSelectRef};
                }
            });

            # Make the simple list scrollable
            $scroller = Gtk2::ScrolledWindow->new();
            $scroller->set_policy('automatic', 'automatic');
            $scroller->add($slWidget);
            push (@scrollerList, $scroller);

            # Fill the columns with data
            $dataListRef = $dataHash{$tab};
            @{$slWidget->{data}} = @$dataListRef;

            # Make all columns of type 'bool' (which are composed of checkbuttons) non-activatable,
            #   so that the user can't click them on and off
            if (@columnList) {

                $count = -1;
                @ownColumnList = @columnList;

                do {

                    my ($title, $type);

                    $title = shift @ownColumnList;
                    $type = shift @ownColumnList;

                    $count++;

                    if ($type eq 'bool') {

                        my ($cellRenderer) = $slWidget->get_column($count)->get_cell_renderers();
                        $cellRenderer->set(activatable => FALSE);
                    }

                } until (! @ownColumnList);
            }

            # Give the tab a label
            $label = Gtk2::Label->new_with_mnemonic($tab);
            $label->set_markup_with_mnemonic($mnemonic);
            # Add the tab to the notebook
            $self->notebook->append_page($scroller, $label);

            # Update IVs
            $self->ivAdd('notebookTabHash', $tab, $label);
            $self->ivPush('notebookTabList', $tab);
            $self->ivAdd('notebookDataHash', $tab, $slWidget);

        } until (! @tabList);

        # Displaying a list of objects puts the notebook in 'list' mode
        $self->ivPoke('notebookMode', 'list');

        # Add an strip of buttons at the top of $self->vBox
        if (@buttonList) {

            $tooltips = Gtk2::Tooltips->new();

            do {

                my ($name, $tip, $method, $btn);

                $name = shift @buttonList;
                $tip = shift @buttonList;
                $method = shift @buttonList;

                $btn = Gtk2::Button->new($name);
                $btn->signal_connect('clicked' => sub {

                    $self->$method();
                });
                $tooltips->set_tip($btn, $tip);

                $self->vBox->pack_start($btn, FALSE, FALSE, 0);
                $self->ivPush('buttonList', $btn);

            } until (! @buttonList);

            $tooltips->enable();
        }

        # Add a separator just beneath these buttons
        my $separator = Gtk2::HSeparator->new();
        $self->vBox->pack_start($separator, FALSE, FALSE, 10);
        $self->ivPush('buttonList', $separator);

        # Add two standard buttons at the bottom of $self->vBox, regardless of the type of list
        #   displayed
        my $btn = Gtk2::Button->new('Refresh list');
        $btn->signal_connect('clicked' => sub {

            $self->updateNotebook();
        });
        $tooltips->set_tip($btn, 'Refresh this list');
        $self->vBox->pack_start($btn, FALSE, FALSE, 0);
        $self->ivPush('buttonList', $btn);

        my $btn2 = Gtk2::Button->new('Exit viewer');
        $btn2->signal_connect('clicked' => sub {

            $self->winDestroy();
        });
        $tooltips->set_tip($btn2, 'Close the ' . $axmud::SCRIPT . ' object viewer');
        $self->vBox->pack_start($btn2, FALSE, FALSE, 0);
        $self->ivPush('buttonList', $btn2);

        # Set the width of the notebook, depending on whether there are any buttons to display
        if ($buttonListRef) {
            $self->hPaned2->set_position($self->centreWidth);
        } else {
            $self->hPaned2->set_position($self->centreWidth + $self->rightWidth);
        }

        # Render the changes
        $self->winShowAll($self->_objClass . '->refreshNotebook');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->refreshNotebook');

        # If $scrollFlag is set, we can now scroll the Gtk2::ScrolledWindow to the bottom
        if ($scrollFlag) {

            foreach my $scroller (@scrollerList) {

                my $vAdjust = $scroller->get_vadjustment;

                $vAdjust->set_value(
                    $vAdjust->lower + (($vAdjust->upper - $vAdjust->page_size) - $vAdjust->lower)
                );
            }

            $self->winShowAll($self->_objClass . '->refreshNotebook');
        }

        return 1;
    }

    sub resetNotebook {

        # Called by $self->refreshNotebook
        # Resets the notebook, removing tabs and buttons
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is no notebook to reset
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $number;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetNotebook', @_);
        }

        # If the notebook doesn't exist, there's nothing to reset
        if (! $self->notebook) {

            return undef;
        }

        # Remove the existing tabs (if any)
        if (
            $self->notebookMode eq 'list'
            || $self->notebookMode eq 'text'
        ) {
            $number = $self->notebook->get_n_pages();
            if ($number) {

                for (my $count = 0; $count < $number; $count++) {

                    $self->notebook->remove_page(0);
                }
            }

            $self->ivEmpty('notebookTabHash');
            $self->ivEmpty('notebookTabList');
            $self->ivEmpty('notebookDataHash');
        }

        # Remove the existing buttons (if any)
        if ($self->buttonList) {

            foreach my $button ($self->buttonList) {

                $button->destroy;
            }

            $self->ivEmpty('buttonList');
        }

        return 1;
    }

    sub refreshTextView {

        # Called by $self->cmdHeader (etc)
        # Creates a Gtk2::TextView in the notebook, and writes the supplied text to it
        # (Header functions which need a simple list, rather than a textview, call
        #   ->refreshNotebook)
        #
        # Expected arguments
        #   $tab    - The title of the notebook tab
        #   @list   - A list of lines to display in the textview
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $tab, @list) = @_;

        # Local variables
        my $label;

        # Check for improper arguments
        if (! defined $tab) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->refreshTextView', @_);
        }

        # If the button strip is visible, do some repacking
        if ($self->hPaned2) {

            $axmud::CLIENT->desktopObj->removeWidget($self->hPaned2, $self->notebook);
            $axmud::CLIENT->desktopObj->removeWidget($self->hPaned, $self->hPaned2);

            $self->hPaned->add2($self->notebook);

            $self->hPaned->set_position($self->leftWidth);
            $self->hPaned->child1_shrink(FALSE);
            $self->hPaned->child1_resize(FALSE);
            $self->hPaned->child2_shrink(FALSE);
            $self->hPaned->child2_resize(FALSE);
        }

        # Update IVs
        $self->ivUndef('hPaned2');
        $self->ivUndef('vBox');

        # Remove the existing notebook content
        $self->resetNotebook();

        # Create a scrolled window
        my $scrolled = Gtk2::ScrolledWindow->new(undef, undef);
        $scrolled->set_shadow_type('etched-out');
        $scrolled->set_policy('automatic', 'automatic');
        $scrolled->set_border_width(5);

        # Create a textview with default colours/fonts
        $axmud::CLIENT->desktopObj->getTextViewStyle($self->winType);
        my $textView = Gtk2::TextView->new();
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);
        $textView->set_editable(FALSE);

        # Copy the text into the textview
        $buffer->set_text(join("\n", @list));

        # Complete setup
        $scrolled->add($textView);

        # Add a label
        $label = Gtk2::Label->new_with_mnemonic($tab);
        $self->notebook->append_page($scrolled, $label);

        # Render the changes
        $self->winShowAll($self->_objClass . '->refreshTextView');

        # Update IVs
        $self->ivAdd('notebookTabHash', $tab, $label);
        $self->ivPoke('notebookMode', 'text');

        return 1;
    }

    sub updateNotebook {

        # Called whenever the current notebook changes (when a new profile or cage is created or
        #   deleted - eg by $self->refreshNotebook)
        # Updates the notebook by calling the same method called when a header in the treeview is
        #   selected
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @list   - The rows in the notebook's GA::Gtk::Simple::List which should be marked as
        #               'selected' (as if the user had clicked on them). If the list is empty,
        #               no rows are marked as 'selected'
        #
        # Return values
        #   'undef' on improper arguments or if the notebook isn't displaying anything
        #   1 otherwise

        my ($self, @list) = @_;

        # Local variables
        my ($method, $currentTab);

        # (No improper arguments to check)

        if (
            $self->notebookCurrentHeader
            && $self->ivExists('headerHash', $self->notebookCurrentHeader)
        ) {
            # Remember the currently selected tab
            $currentTab = $self->notebook->get_current_page();

            # Call the method specified by $self->headerHash
            $method = $self->ivShow('headerHash', $self->notebookCurrentHeader);
            $self->$method($self->notebookCurrentHeader);

            # If @list isn't empty, mark some of the rows as selected
            if (@list) {

                $self->notebookSetSelectedLines(@list);
            }

            # Open the previously selected tab
            $self->notebook->set_current_page($currentTab);

            return 1;

        } else {

            return undef;
        }
    }

    # Notebook support functions

    sub notebookGetTab {

        # Can be called by anything
        # Finds the name of the current tab in the notebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the name (label) of the tab

        my ($self, $check) = @_;

        # Local variables
        my $number;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notebookGetTab', @_);
        }

        $number = $self->notebook->get_current_page();
        return $self->ivIndex('notebookTabList', $number);
    }

    sub notebookGetData {

        # Can be called by anything
        # Finds the data displayed in the GA::Gtk::Simple::List of the current notebook tab
        #   (use ->notebookGetSelectedData to get only the selected data)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the reference to the selected data, matching
        #       GA::Gtk::Simple::List->{data}

        my ($self, $check) = @_;

        # Local variables
        my $tabName;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notebookGetData', @_);
        }

        $tabName = $self->notebookGetTab();
        return $self->ivShow('notebookDataHash', $tabName);
    }

    sub notebookGetSelectedData {

        # Can be called by anything
        # Gets the data displayed in the selected line of the GA::Gtk::Simple::List of the current
        #   notebook tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list, each element containing a list reference with all the data in
        #       a selected row

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef,
            @emptyList, @selectList, @returnList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->notebookGetSelectedData', @_);
            return @emptyList,
        }

        $dataRef = $self->notebookGetData();
        @selectList = $dataRef->get_selected_indices();

        foreach my $index (@selectList) {

            push (@returnList, ${$dataRef->{data}}[$index]);
        }

        return @returnList;
    }

    sub notebookGetSelectedLines {

        # Can be called by anything
        # Gets a list containing the number of each selected line in the GA::Gtk::Simple::List of
        #   the current notebook tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the list of selected line numbers

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef,
            @emptyList, @returnList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->notebookGetSelectedLines', @_);
            return @emptyList,
        }

        $dataRef = $self->notebookGetData();
        @returnList = $dataRef->get_selected_indices();

        return @returnList;
    }

    sub notebookSetSelectedLines {

        # Can be called by anything, but usually by $self->updateNotebook
        # Selects lines in the GA::Gtk::Simple::List of the current notebook tab, as if the user had
        #   clicked on them
        #
        # Expected arguments
        #   @list       - List of indices in the GA::Gtk::Simple::List to select
        #
        # Return values
        #   1

        my ($self, @list) = @_;

        # Local variables
        my $dataRef;

        # (No improper arguments to check)

        $dataRef = $self->notebookGetData();
        foreach my $index (@list) {

            $dataRef->select($index);
        }

        return 1;
    }

    sub getMnemonic {

        # Called by $self->setTabList_prof and several other functions
        # Given the label of a tab - e.g. 'world' - create a label mnemonic, e.g. '_world' (which
        #   the user can select with the ALT+W key combination)
        # The calling function supplies a hash of letters that have already been used for other
        #   mnemonics, so that each label can be selected with a different key combination (for as
        #   long as there are spare letters remaining)
        #
        # Expected arguments
        #   $string     - The string to process, e.g. 'world'
        #   $hashRef    - Reference to a hash of mnemonics already used, in the form
        #                   $hash{letter} = undef
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the modified string

        my ($self, $string, $hashRef, $check) = @_;

        # Check for improper arguments
        if (! defined $string || ! defined $hashRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getMnemonic', @_);
        }

        if (! $string) {

            # Can't process an empty string
            return $string;
        }

        # Dereference the supplied hash (for convenience)

        # Examine each letter of $string in turn, looking for one which hasn't already been used as
        #   a mnemonic
        for (my $count = 0; $count < length($string); $count++) {

            my $letter = lc(substr($string, $count, 1));

            if (! exists $$hashRef{$letter}) {

                # Insert an underline at this location
                substr($string, $count, 0, '_');
                # This mnemonic is no longer available
                $$hashRef{$letter} = undef;

                return $string;
            }
        }

        # Cannot add an underline to $string; all of its letters are already in use. Return the
        #   unmodified string
        return $string
    }

    # Treeview header responses - profiles

    sub allProfHeader {

        # Called by ->treeViewChanged when the user clicks on the 'All profiles' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $shortTabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @shortTabList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->allProfHeader', @_);
        }

        # Prepare the list of tabs
        ($tabListRef, $shortTabListRef) = $self->setTabList_prof();
        # Prepare the list of column headings
        $columnListRef = $self->setColumnList_prof();
        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_prof();

        # Prepare the data to be displayed. Each item in @$shortTabListRef is a profile category,
        #   e.g. 'world' or 'char'
        @shortTabList = @$shortTabListRef;
        foreach my $tab (@shortTabList) {

            my (@profList, @sortedList, @dataList);

            if ($tab eq 'world') {

                # Add world profiles from the GA::Client's hash
                @profList = sort {lc($a->name) cmp lc($b->name)}
                                ($axmud::CLIENT->ivValues('worldProfHash'));

                foreach my $profObj (@profList) {

                    my ($flag, $listRef);

                    if ($profObj eq $self->session->currentWorld) {
                        $flag = TRUE;
                    } else {
                        $flag = FALSE;
                    }

                    $listRef = [$flag, $profObj->name, $profObj->category];
                    push (@dataList, $listRef);
                }

            } else {

                # Add non-world profiles from the current GA::Session
                foreach my $profObj ($self->session->ivValues('profHash')) {

                    if ($profObj->category eq $tab) {

                        push (@profList, $profObj);
                    }
                }

                @sortedList = sort {lc($a->name) cmp lc($b->name)} (@profList);
                foreach my $profObj (@sortedList) {

                    my ($flag, $listRef);

                    if (
                        $self->session->ivExists('currentProfHash', $tab)
                        && $self->session->ivShow('currentProfHash', $tab) eq $profObj
                    ) {
                        $flag = TRUE;
                    } else {
                        $flag = FALSE;
                    }

                    $listRef = [$flag, $profObj->name, $profObj->category];
                    push (@dataList, $listRef);
                }
            }

            $dataHash{$tab} = \@dataList;
        }

        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_prof();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub currentProfHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Current profiles' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $shortTabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @shortTabList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->currentProfHeader', @_);
        }

        # Prepare the list of tabs
        ($tabListRef, $shortTabListRef) = $self->setTabList_prof();
        # Prepare the list of column headings
        $columnListRef = $self->setColumnList_prof();
        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_prof();

        # Prepare the data to be displayed. Each item in @$shortTabListRef is a profile category,
        #   e.g. 'world' or 'char'
        @shortTabList = @$shortTabListRef;
        foreach my $tab (@shortTabList) {

            my @dataList;

            # Add all current profiles from the current GA::Session (there should only be one from
            #   each category of profile, so no need to sort the list alphabetically)
            foreach my $profObj ($self->session->ivValues('currentProfHash')) {

                my $listRef;

                if ($profObj->category eq $tab) {

                    # The TRUE argument marks this as a current profile
                    $listRef = [TRUE, $profObj->name, $profObj->category];
                    push (@dataList, $listRef);
                }
            }

            $dataHash{$tab} = \@dataList;
        }

        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_prof();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub templateHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Profile templates' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @objList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->templateHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Profile templates', 'Profile _templates',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Fixed' => 'bool',
            'Template category' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new template profile', 'buttonAdd_template',
            'Edit', 'Edit the selected template profile', 'buttonEdit_template',
            'Clone', 'Clone the selected template profile', 'buttonClone_template',
            'Delete', 'Delete the selected template profile', 'buttonDelete_template',
            'Dump', 'Display the list of template in the \'main\' window', 'buttonDump_template',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @objList = sort {lc($a->category) cmp lc($b->category)}
                        ($self->session->ivValues('templateHash'));
        OUTER: foreach my $templObj (@objList) {

            my $listRef = [$templObj->constFixedFlag, $templObj->category];

            push (@dataList, $listRef);
        }

        $dataHash{'Profile templates'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_template();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub profPriorityHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Profile priority' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef, $count,
            @dataList, @otherList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->profPriorityHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Profile priority list', 'Profile _priority list',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Priority' => 'text',
            'Category' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Move to top', 'Profile category has the highest priority',
                'buttonMoveTop_profPriority',
            'Move up', 'Profile category has a higher priority',
                'buttonMoveUp_profPriority',
            'Move down', 'Profile category has a lower priority',
                'buttonMoveDown_profPriority',
            'Give priority', 'Add the selected category to the priority list',
                'buttonGivePriority_profPriority',
            'Lose priority', 'Remove the selected category from the priority list',
                'buttonLosePriority_profPriority',
            'Reset list', 'Use the default priority list',
                'buttonResetList_profPriority',
        ];

        # Compile the data to display
        $dataHashRef = $self->compileList_profPriority();

        # (Nothing happens if the user double-clicks on a row)

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    # Treeview header responses - dictionaries

    sub allDictHeader {

        # Called by ->treeViewChanged when the user clicks on the 'All dictionaries' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @objList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->allDictHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Dictionary' => '_Dictionary',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Current' => 'bool',
            'Name' => 'text',
            'Language' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new dictionary', 'buttonAdd_dict',
            'Edit', 'Edit the selected dictionary', 'buttonEdit_dict',
            'Set current', 'Set the current dictionary', 'buttonSet_dict',
            'Clone', 'Clone the selected dictionary', 'buttonClone_dict',
            'Delete', 'Delete the selected dictinoary', 'buttonDelete_dict',
            'Dump', 'Display a list of dictionaries in the \'main\' window', 'buttonDump_dict',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @objList = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('dictHash'));
        OUTER: foreach my $dictObj (@objList) {

            my ($listRef, $flag);

            if ($dictObj eq $self->session->currentDict) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            $listRef = [$flag, $dictObj->name, $dictObj->language];
            push (@dataList, $listRef);
        }

        $dataHash{'Dictionary'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_dict();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub currentDictHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Current dictionaries' header in
        #   the treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->currentDictHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Dictionary' => '_Dictionary',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Current' => 'bool',
            'Name' => 'text',
            'Language' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new dictionary', 'buttonAdd_dict',
            'Edit', 'Edit the selected dictionary', 'buttonEdit_dict',
            'Set current', 'Set the current dictionary', 'buttonSet_dict',
            'Clone', 'Clone the selected dictionary', 'buttonClone_dict',
            'Delete', 'Delete the selected dictinoary', 'buttonDelete_dict',
            'Dump', 'Display a list of dictionaries in the \'main\' window', 'buttonDump_dict',

        ];

        # Prepare the data to be displayed (there is only one tab, and there should be only one
        #   dictionary to display)
        OUTER: foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

            my $listRef;

            if ($dictObj eq $self->session->currentDict) {

                $listRef = [TRUE, $dictObj->name, $dictObj->language];
                push (@dataList, $listRef);
            }
        }

        $dataHash{'Dictionary'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_dict();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    # Treeview header responses - tasks

    sub availableTaskHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Available tasks' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @objList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->availableTaskHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Available tasks' => '_Available tasks',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Built-in' => 'bool',
            'Task name' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Start', 'Start a new task with default settings', 'buttonStart_availableTask',
            'Start options', 'Start a new task with non-standard settings',
                'buttonStartOptions_availableTask',
            'Add initial', 'Add a new task to the global initial tasklist',
                'buttonAddInitial_availableTask',
            'Add custom', 'Add a new task to the custom tasklist',
                'buttonAddCustom_availableTask',
            'Halt', 'Halt all currently-running copies of the selected task',
                'buttonHalt_availableTask',
            'Kill', 'Kill all currently-running copies of the selected task',
                'buttonKill_availableTask',
            'Pause', 'Pauses all currently-running copies of the selected task',
                'buttonPause_availableTask',
            'Safe resume', 'Resume all tasks paused with the pause button',
                'buttonSafeResume_task',
            'Reset', 'Reset all currently-running copies of the selected task',
                'buttonReset_availableTask',
            'Help', 'Shows help for the selected task', 'buttonHelp_availableTask',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @objList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('taskPackageHash'));
        OUTER: foreach my $packageName (@objList) {

            my ($listRef, $flag);

            if ($axmud::CLIENT->ivExists('constTaskPackageHash', $packageName)) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            $listRef = [$flag, $packageName];
            push (@dataList, $listRef);

        }

        $dataHash{'Available tasks'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the 'start' button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonStart_availableTask();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub currentTaskHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Current tasklist' header in the
        #   treeview
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains). Not specified
        #               when called by GA::Session->taskLoop
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @objList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->currentTaskHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Current tasklist' => '_Current tasklist',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Name' => 'text',       # ->name
            'Type' => 'text',       # ->category
            'Jealous' => 'bool',    # ->jealousyFlag
            'Stage' => 'text',      # ->stage
            'Status' => 'text',     # ->status
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Edit', 'Edit a task\'s settings and parameters', 'buttonEdit_task',
            'Halt', 'Halt a task (gracefully)', 'buttonHalt_task',
            'Halt all', 'Halt all tasks (gracefully)', 'buttonHaltAll_task',
            'Kill', ' Kill (stop) a task immediately (not recommended)', 'buttonKill_task',
            'Kill all', 'Kill (stop) all tasks immediately (not recommended)', 'buttonKillAll_task',
            'Pause', 'Pause a task', 'buttonPause_task',
            'Pause all', 'Pause all tasks', 'buttonPauseAll_task',
            'Safe resume', 'Resume all tasks paused with the pause button', 'buttonSafeResume_task',
            'Reset', 'Reset a task', 'buttonReset_task',
            'Reset all', 'Reset all tasks', 'buttonResetAll_task',
            '(Un)freeze all', 'Freeze (or unfreeze) all running tasks', 'buttonFreezeAll_task',
            'Dump', 'Dump the list of running tasks to the \'main\' window', 'buttonDump_task',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @objList = sort {lc($a->uniqueName) cmp lc($b->uniqueName)}
                        ($self->session->ivValues('currentTaskHash'));

        OUTER: foreach my $taskObj (@objList) {

            my $listRef = [
                $taskObj->uniqueName, $taskObj->category, $taskObj->jealousyFlag,
                $taskObj->stage, $taskObj->status,
            ];

            push (@dataList, $listRef);

        }

        $dataHash{'Current tasklist'} = \@dataList;
        $dataHashRef = \%dataHash;

        # (Nothing happens when user double-clicks on line)

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub initialTaskHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Global initial tasklist' header
        #   in the treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->initialTaskHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Global initial tasklist' => '_Global initial tasklist',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Name' => 'text',       # ->uniqueName
            'Type' => 'text',       # ->category
            'Jealous' => 'bool',    # ->jealousyFlag
            'Stage' => 'text',      # ->stage
            'Status' => 'text',     # ->status
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Edit', 'Edit the selected task', 'buttonEdit_initialTask',
            'Move up', 'Move the selected task up', 'buttonMoveUp_initialTask',
            'Move down', 'Move the selected task down', 'buttonMoveDown_initialTask',
            'Delete', 'Delete a task from the global initial tasklist', 'buttonDelete_initialTask',
            'Delete all', 'Delete all tasks from the global initial tasklist',
                'buttonDeleteAll_initialTask',
            'Dump', 'Dump the list of initial tasks to the \'main\' window',
                'buttonDump_initialTask',
        ];

        # Prepare the data to be displayed (there is only one tab)
        OUTER: foreach my $taskName ($axmud::CLIENT->initTaskOrderList) {

            my ($taskObj, $listRef);

            $taskObj = $axmud::CLIENT->ivShow('initTaskHash', $taskName);
            $listRef = [
                $taskObj->uniqueName, $taskObj->category, $taskObj->jealousyFlag,
                $taskObj->stage, $taskObj->status,
            ];

            push (@dataList, $listRef);

        }

        $dataHash{'Global initial tasklist'} = \@dataList;
        $dataHashRef = \%dataHash;

        # (Nothing happens when user double-clicks on line)

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub customTaskHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Custom tasklist' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @labelList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->customTaskHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Custom tasklist' => '_Custom tasklist',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Name' => 'text',       # key in GA::Client->customTaskHash
            'Task' => 'text',       # ->name
            'Type' => 'text',       # ->category
            'Jealous' => 'bool',    # ->jealousyFlag
            'Stage' => 'text',      # ->stage
            'Status' => 'text',     # ->status
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Start', 'Start the selected custom task', 'buttonStart_customTask',
            'Edit', 'Edit the selected task', 'buttonEdit_customTask',
            'Delete', 'Delete a task from the global initial tasklist', 'buttonDelete_customTask',
            'Delete all', 'Delete all tasks from the global initial tasklist',
                'buttonDeleteAll_customTask',
            'Dump', 'Dump the list of custom tasks to the \'main\' window',
                'buttonDump_customTask',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @labelList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('customTaskHash'));
        OUTER: foreach my $label (@labelList) {

            my ($taskObj, $listRef);

            $taskObj = $axmud::CLIENT->ivShow('customTaskHash', $label);
            $listRef = [
                $label, $taskObj->name, $taskObj->category,
                $taskObj->jealousyFlag, $taskObj->stage, $taskObj->status,
            ];

            push (@dataList, $listRef);

        }

        $dataHash{'Custom tasklist'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the 'start' button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonStart_customTask();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub taskPackageHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Task package names' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $shortTabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @list, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->taskPackageHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Task package names' => 'Task _package names',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Built-in' => 'bool',
            'Standard task name' => 'text',
            'Package name' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new task package name', 'buttonAdd_taskPackage',
            'Edit', 'Edit a new task package name', 'buttonEdit_taskPackage',
            'Delete', 'Delete an existing task package name', 'buttonDelete_taskPackage',
            'Reset', 'Reset all task package names to defaults', 'buttonReset_taskPackage',
            'Reset All', 'Reset all task package names to defaults', 'buttonResetAll_taskPackage',
            'Dump', 'Dump the list of task package names to the \'main\' window',
                'buttonDump_taskPackage',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @list = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('taskPackageHash'));
        foreach my $standardName (@list) {

            my ($flag, $listRef);

            if ($axmud::CLIENT->ivExists('constTaskPackageHash', $standardName)) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            $listRef = [
                $flag,
                $standardName,
                $axmud::CLIENT->ivShow('taskPackageHash', $standardName),
            ];
            push (@dataList, $listRef);
        }

        $dataHash{'Task package names'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_taskPackage();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub taskLabelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Task labels' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $shortTabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @list, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->taskLabelHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Task labels' => 'Task _labels',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Built-in' => 'bool',
            'Label' => 'text',
            'Standard task name' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new task label', 'buttonAdd_taskLabel',
            'Delete', 'Delete an existing task label', 'buttonDelete_taskLabel',
            'Empty labels', 'Empties all labels attached to a particular task',
                'buttonEmpty_taskLabel',
            'Reset', 'Reset all task labels to defaults', 'buttonReset_taskLabel',
            'Reset All', 'Resets all task labels to defaults', 'buttonResetAll_taskLabel',
            'Dump', 'Dumps the list of task labels to the \'main\' window', 'buttonDump_taskLabel',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @list = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('taskLabelHash'));
        foreach my $label (@list) {

            my ($flag, $listRef);

            if ($axmud::CLIENT->ivExists('constTaskLabelHash', $label)) {
                $flag = TRUE;
            } else {
                $flag = FALSE,
            }

            $listRef = [
                $flag,
                $label,
                $axmud::CLIENT->ivShow('taskLabelHash', $label),
            ];

            push (@dataList, $listRef);
        }

        $dataHash{'Task labels'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_taskLabel();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    # Treeview header responses - cages

    sub allCageHeader {

        # Called by ->treeViewChanged when the user clicks on the 'All cages' header in the treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $shortTabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @shortTabList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->allCageHeader', @_);
        }

        # Prepare the list of tabs
        ($tabListRef, $shortTabListRef) = $self->setTabList_cage();
        # Prepare the list of column headings
        $columnListRef = $self->setColumnList_cage();
        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_cage();

        # Prepare the data to be displayed
        @shortTabList = @$shortTabListRef;
        OUTER: foreach my $tab (@shortTabList) {

            my (@cageList, @dataList);

            @cageList = $self->getSortedCages($tab);

            # @cageList contains a sorted list of cages. Convert that list into one that can be
            #   displayed in a GA::Gtk::Simple::List, in columns
            foreach my $cageObj (@cageList) {

                my ($flag, $listRef);

                if (
                    $self->session->ivExists('currentCageHash', $cageObj->name)
                    && $self->session->ivShow('currentCageHash', $cageObj->name) eq $cageObj
                ) {
                    $flag = TRUE;
                } else {
                    $flag = FALSE;
                }

                $listRef = [$flag, $cageObj->name];
                push (@dataList, $listRef);
            }

            $dataHash{$tab} = \@dataList;
        }

        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_cage();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub currentCageHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Current cages' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $shortTabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @shortTabList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->currentCageHeader', @_);
        }

        # Prepare the list of tabs
        ($tabListRef, $shortTabListRef) = $self->setTabList_cage();
        # Prepare the list of column headings
        $columnListRef = $self->setColumnList_cage();
        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_cage();

        # Prepare the data to be displayed
        @shortTabList = @$shortTabListRef;
        OUTER: foreach my $tab (@shortTabList) {

            my (@cageList, @dataList);

            @cageList = $self->getSortedCages($tab);

            foreach my $cageObj (@cageList) {

                my $listRef;

                if (
                    $self->session->ivExists('currentCageHash', $cageObj->name)
                    && $self->session->ivShow('currentCageHash', $cageObj->name) eq $cageObj
                ) {
                    # The TRUE argument marks this as a current cage
                    $listRef = [TRUE, $cageObj->name];
                    push (@dataList, $listRef);
                }
            }

            $dataHash{$tab} = \@dataList;
        }

        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_cage();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub activeInterfaceHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Active interfaces' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @shortTabList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->activeInterfaceHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'All' => 'A_ll',
            'Dependent' => '_Dependent',
            'Independent' => 'I_ndependent',
            'Trigger' => '_Trigger',
            'Alias' => '_Alias',
            'Macro' => '_Macro',
            'Timer' => 'T_imer',
            'Hook' => '_Hook',
        ];

        @shortTabList = (
            'All', 'Dependent', 'Independent',
            'Trigger', 'Alias', 'Macro', 'Timer', 'Hook',
        );

        # Prepare the list of column headings
        $columnListRef = [
            '#' => 'int',
            'Enab.' => 'bool',
            'Indep.' => 'bool',
            'Cat.' => 'text',
            'Name' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Edit', 'Edit the selected interface', 'buttonEdit_activeInterface',
            'Dump', 'Display this list of interfaces in the \'main\' window',
                'buttonDump_activeInterface',
        ];

        # Prepare the data to be displayed
        foreach my $tab (@shortTabList) {

            my (@interfaceList, @dataList);

            @interfaceList = sort {$a->number <=> $b->number}
                ($self->session->ivValues('interfaceNumHash'));

            foreach my $interfaceObj (@interfaceList) {

                my $listRef;

                if (
                    $tab eq 'All'
                    || ($tab eq 'Dependent' && ! $interfaceObj->indepFlag)
                    || ($tab eq 'Independent' && $interfaceObj->indepFlag)
                    || lc($tab) eq $interfaceObj->category
                ) {
                    $listRef = [
                        $interfaceObj->number,
                        $interfaceObj->enabledFlag,
                        $interfaceObj->indepFlag,
                        $interfaceObj->category,
                        $interfaceObj->name,
                    ];

                    push (@dataList, $listRef);
                }
            }

            $dataHash{$tab} = \@dataList;
        }

        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_activeInterface();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub interfaceModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Interface models' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @categoryList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->interfaceModelHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Interface models' => '_Interface models',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Category' => 'text',
            'Stimulus' => 'text',
            'Response' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'View', 'View the selected interface model', 'buttonView_interfaceModel',
            'Dump', 'Display this list of interface models in the \'main\' window',
                'buttonDump_interfaceModel',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @categoryList = ('trigger', 'alias', 'macro', 'timer', 'hook');
        foreach my $category (@categoryList) {

            my ($modelObj, $listRef);

            $modelObj = $axmud::CLIENT->ivShow('interfaceModelHash', $category);
            $listRef = [$modelObj->category, $modelObj->stimulusName, $modelObj->responseName];
            push (@dataList, $listRef);
        }

        $dataHash{'Interface models'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonView_interfaceModel();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    # Treeview header responses - world model

    sub modelHeader {

        # Called by $self->allModelHeader, $self->regionModelHeader etc, after a call by
        #   ->treeViewChanged when the user clicks on one of the items under the 'world model'
        #   header in the treeview
        #
        # Expected arguments
        #   $tabName        - What to display on the tab, e.g. 'Weapons'
        #   $tabShortCut    - e.g. '_Weapons'
        #   $iv             - The GA::Obj::WorldModel IV storing all the world model objects of a
        #                       certain type, e.g. 'regionModelHash', 'weaponModelHash' (or even
        #                       'modelHash')
        #   $buttonListRef  - Reference to a list containing the buttons to use for this category of
        #                       world model object (usually defined by $self->setButtonList_model,
        #                       but some types of object specify their own buttons)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $tabName, $tabShortCut, $iv, $buttonListRef, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $wmObj, $dataHashRef,
            @objList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (
            ! defined $tabName || ! defined $tabShortCut || ! defined $iv
            || ! defined $buttonListRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->modelHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            $tabName => $tabShortCut,
        ];

        # Prepare the list of column headings
        $columnListRef = $self->setColumnList_model();

        # Import the world model object (for convenience)
        $wmObj = $self->session->worldModelObj;
        # Prepare the data to be displayed (there is only one tab). Rather than sort the model
        #   objects by number (which might take a long time), check every number between 1 and
        #   GA::Obj::WorldModel->modelObjCount, using only objects which are actually stored in $iv
        if ($wmObj->modelObjCount) {

            for (my $count = 1; $count <= $wmObj->modelObjCount; $count++) {

                if (exists $wmObj->{$iv}{$count}) {

                    push (@objList, $wmObj->{$iv}{$count});
                }
            }
        }

        OUTER: foreach my $obj (@objList) {

            my $listRef = [$obj->number, $obj->category, $obj->name];
            push (@dataList, $listRef);
        }

        $dataHash{$tabName} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_model();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub allModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'All objects' header in the
        #   treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my @buttonList;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->allModelHeader', @_);
        }

        # Prepare the list of buttons. This list is the same as the standard list of buttons, but
        #   without the 'add' button
        @buttonList = (
            'Edit', 'Edit the selected world model object', 'buttonEdit_model',
            'Delete', 'Delete the selected world model object', 'buttonDelete_model',
            'Dump', 'Displays a list of all world model objects in the \'main\' window',
                'buttonDump_model',
            'Edit model', 'Edit the world model itself', 'buttonEdit_worldModel',
        );

        return $self->modelHeader(
            'All objects',
            'A_ll objects',
            'modelHash',
            \@buttonList,
        );
    }

    sub regionModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Regions' header in the treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my @buttonList;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->regionModelHeader', @_);
        }

        # Prepare the list of buttons
        @buttonList = (
            'Add', 'Add a region object to the world model', 'buttonAddRegion_model',
            'Add temporary',
                'Add a temporary region object to the world model', 'buttonAddTempRegion_model',
            'Edit region', 'Edit the selected region model object', 'buttonEdit_model',
            'Edit regionmap', 'Edit the selected region\' regionmap', 'buttonEdit_regionmap',
            'Delete', 'Delete the selected region model object', 'buttonDeleteRegion_model',
            'Dump', 'Displays a list of all world model objects in the \'main\' window',
                'buttonDump_model',
        );

        return $self->modelHeader(
            'Regions',
            'Regio_ns',
            'regionModelHash',
            \@buttonList,
        );
    }

    sub roomModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Rooms' header in the treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my @buttonList;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->roomModelHeader', @_);
        }

        # Prepare the list of buttons
        @buttonList = (
            'Edit', 'Edit the selected world model object', 'buttonEdit_model',
            'Delete', 'Delete the selected room model object', 'buttonDeleteRoom_model',
            'Dump', 'Displays a list of all world model objects in the \'main\' window',
                'buttonDump_model',
        );

        return $self->modelHeader(
            'Rooms',
            '_Rooms',
            'roomModelHash',
            \@buttonList,
        );
    }

    sub weaponModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Weapons' header in the treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my $buttonListRef;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->weaponModelHeader', @_);
        }

        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_model();

        return $self->modelHeader(
            'Weapons',
            '_Weapons',
            'weaponModelHash',
            $buttonListRef,
        );
    }

    sub armourModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Armours' header in the treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my $buttonListRef;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->armourModelHeader', @_);
        }

        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_model();

        return $self->modelHeader(
            'Armours',
            '_Armours',
            'armourModelHash',
            $buttonListRef,
        );
    }

    sub garmentModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Garments' header in the treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my $buttonListRef;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->garmentModelHeader', @_);
        }

        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_model();

        return $self->modelHeader(
            'Garments',
            '_Garments',
            'garmentModelHash',
            $buttonListRef,
        );
    }

    sub charModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Characters' header in the
        #   treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my @buttonList;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->charModelHeader', @_);
        }

        # Prepare the list of buttons
        @buttonList = (
            'Add', 'Add a player character to the world model', 'buttonAddChar_model',
            'Edit', 'Edit the selected character object', 'buttonEdit_model',
            'Delete', 'Delete the selected character object', 'buttonDelete_model',
            'Dump', 'Displays a list of all world model characters in the \'main\' window',
                'buttonDumpChar_model',
        );

        return $self->modelHeader(
            'Characters',
            '_Characters',
            'charModelHash',
            \@buttonList,
        );
    }

    sub minionModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Minions' header in the treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my $buttonListRef;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->minionModelHeader', @_);
        }

        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_model();

        return $self->modelHeader(
            'Minions',
            '_Minions',
            'minionModelHash',
            $buttonListRef,
        );
    }

    sub sentientModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Sentients' header in the treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my $buttonListRef;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sentientModelHeader', @_);
        }

        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_model();

        return $self->modelHeader(
            'Sentients',
            '_Sentients',
            'sentientModelHash',
            $buttonListRef,
        );
    }

    sub creatureModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Creatures' header in the treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my $buttonListRef;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->creatureModelHeader', @_);
        }

        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_model();

        return $self->modelHeader(
            'Creatures',
            'Crea_tures',
            'creatureModelHash',
            $buttonListRef,
        );
    }

    sub portableModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Portables' header in the treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my $buttonListRef;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->portableModelHeader', @_);
        }

        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_model();

        return $self->modelHeader(
            'Portables',
            '_Portables',
            'portableModelHash',
            $buttonListRef,
        );
    }

    sub decorationModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Decorations' header in the
        #   treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my $buttonListRef;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->decorationModelHeader', @_);
        }

        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_model();

        return $self->modelHeader(
            'Decorations',
            '_Decorations',
            'decorationModelHash',
            $buttonListRef,
        );
    }

    sub customModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Custom objects' header in the
        #   treeview
        # The code to display the tab is basically the same for all categories of world model
        #   object, so all categories call a single function
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   The return value of $self->modelHeader, otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my $buttonListRef;

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->customModelHeader', @_);
        }

        # Prepare the list of buttons
        $buttonListRef = $self->setButtonList_model();

        return $self->modelHeader(
            'Custom',
            'C_ustom',
            'customModelHash',
            $buttonListRef,
        );
    }

    sub exitModelHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Exits' header in the treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $buttonListRef, $wmObj, $dataHashRef,
            @objList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->exitModelHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Exits' => '_Exits',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Exit #' => 'int',
            'Room #' => 'int',
            'Nominal dir' => 'text',
            'Map dir' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add an exit to the exit model', 'buttonAdd_exitModel',
            'Edit', 'Edit the selected exit', 'buttonEdit_exitModel',
            'Delete', 'Delete the selected exit from the exit model', 'buttonDelete_exitModel',
            'Dump', 'Dump the contents of the exit model in the \'main\' window',
                        'buttonDump_exitModel',
        ];

        # Import the world model object (for convenience)
        $wmObj = $self->session->worldModelObj;
        # Prepare the data to be displayed (there is only one tab). Rather than sort the exit model
        #   objects by number (which might take a long time), check every number between 1 and
        #   GA::Obj::WorldModel->exitObjCount, using only objects which are actually stored in $iv
        if ($wmObj->exitObjCount) {

            for (my $count = 1; $count <= $wmObj->exitObjCount; $count++) {

                if (exists $wmObj->{'exitModelHash'}{$count}) {

                    push (@objList, $wmObj->{'exitModelHash'}{$count});
                }
            }
        }

        foreach my $exitObj (@objList) {

            my ($listRef, $mapDir);

            if ($exitObj->mapDir) {
                $mapDir = $exitObj->mapDir;
            } else {
                $mapDir = 'unallocatable';
            }

            $listRef = [$exitObj->number, $exitObj->parent, $exitObj->dir, $mapDir];
            push (@dataList, $listRef);
        }

        $dataHash{'Exits'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_exitModel();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    # Treeview header responses - buffers

    sub displayBufferHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Display buffer' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @objList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->displayBufferHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Display buffer' => '_Display buffer',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Line' => 'int',
            'Time' => 'int',
            'Text' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Dump 20', 'Display the most recent 20 lines in the \'main\' window',
                'buttonDump20_displayBuffer',
            'Dump all', 'Display all lines in the \'main\' window', 'buttonDumpAll_displayBuffer',
            'Status', 'Display the display buffer\'s status in the \'main\' window',
                'buttonStatus_displayBuffer',
            'View line', 'View the selected line in an \'edit\' window', 'buttonView_displayBuffer',
            'Test pattern', 'Test a pattern (regex) against this line', 'buttonTest_displayBuffer',
            'Save buffer', 'Save lines from the display buffer to file', 'buttonSave_displayBuffer',
            'Save both', 'Save lines from the display and command buffers to file',
                'buttonSaveBoth_displayBuffer',
        ];

        # Prepare the data to be displayed (there is only one tab). Rather than sort the buffer
        #   objects by number (which might take a while), check every number between
        #   GA::Session->displayBufferFirst and ->displayBufferLast
        if (defined $self->session->displayBufferLast) {

            for (
                my $count = $self->session->displayBufferFirst;
                $count <= $self->session->displayBufferLast;
                $count++
            ) {
                # There shouldn't be any missing buffer objects, but just in case...
                if (exists $self->session->{'displayBufferHash'}{$count}) {

                    push (@objList, $self->session->{'displayBufferHash'}{$count});
                }
            }
        }

        foreach my $bufferObj (@objList) {

            my $listRef = [
                $bufferObj->number,
                int ($bufferObj->time),
                $bufferObj->modLine,
            ];
            push (@dataList, $listRef);
        }

        $dataHash{'Display buffer'} = \@dataList;
        $dataHashRef = \%dataHash;

        # (Do nothing when a line is double-clicked)

        # Display all of this in the notebook
        return $self->refreshNotebook(
            $tabListRef,
            $columnListRef,
            $dataHashRef,
            $buttonListRef,
            TRUE,                   # Scroll to bottom
        );
    }

    sub instructBufferHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Instruction buffer' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @objList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->instructBufferHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Instruction buffer' => '_Instruction buffer',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Line' => 'int',
            'Type' => 'text',
            'Time' => 'int',
            'Instruction' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Dump 20', 'Display the most recent 20 instructions in the \'main\' window',
                'buttonDump20_instructBuffer',
            'Dump all', 'Display all instructions in the \'main\' window',
                'buttonDumpAll_instructBuffer',
            'Status', 'Display the instruction buffer\'s status in the \'main\' window',
                'buttonStatus_instructBuffer',
            'View line', 'View the selected line in an \'edit\' window',
                'buttonView_instructBuffer',
        ];

        # Prepare the data to be displayed (there is only one tab). Rather than sort the buffer
        #   objects by number (which might take a while), check every number between
        #   GA::Session->instructBufferFirst and ->instructBufferLast
        if ($self->session->instructBufferCount) {

            for (
                my $count = $self->session->instructBufferFirst;
                $count <= $self->session->instructBufferLast;
                $count++
            ) {
                # There shouldn't be any missing buffer objects, but just in case...
                if (exists $self->session->{'instructBufferHash'}{$count}) {

                    push (@objList, $self->session->{'instructBufferHash'}{$count});
                }
            }
        }

        foreach my $bufferObj (@objList) {

            my ($listRef, $time);

            # During the session's setup, client commands (notably ';setguild', ';setrace',
            #   ';setchar') might be executed before GA::Session->sessionTime has been initialised
            $time = $bufferObj->time;
            if (! defined $time) {

                $time = 0;
            }

            $listRef = [
                $bufferObj->number,
                $bufferObj->type,
                int ($time),
                $bufferObj->instruct,
            ];

            push (@dataList, $listRef);
        }

        $dataHash{'Instruction buffer'} = \@dataList;
        $dataHashRef = \%dataHash;

        # (Do nothing when a line is double-clicked)

        # Display all of this in the notebook
        return $self->refreshNotebook(
            $tabListRef,
            $columnListRef,
            $dataHashRef,
            $buttonListRef,
            TRUE,                   # Scroll to bottom
        );
    }

    sub cmdBufferHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Command buffer' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @objList, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->cmdBufferHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Command buffer' => '_Command buffer',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Line' => 'int',
            'Time' => 'int',
            'Command' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Dump 20', 'Display the most recent 20 commands in the \'main\' window',
                'buttonDump20_cmdBuffer',
            'Dump all', 'Display all commands in the \'main\' window', 'buttonDumpAll_cmdBuffer',
            'Status', 'Display the command buffer\'s status in the \'main\' window',
                'buttonStatus_cmdBuffer',
            'View line', 'View the selected line in an \'edit\' window', 'buttonView_cmdBuffer',
            'Save buffer', 'Save lines from the command buffer to file', 'buttonSave_cmdBuffer',
            'Save both', 'Save lines from the text and command buffers to file',
                'buttonSaveBoth_displayBuffer',
        ];

        # Prepare the data to be displayed (there is only one tab). Rather than sort the buffer
        #   objects by number (which might take a while), check every number between
        #   GA::Session->cmdBufferFirst and ->cmdBufferLast
        if ($self->session->cmdBufferCount) {

            for (
                my $count = $self->session->cmdBufferFirst;
                $count <= $self->session->cmdBufferLast;
                $count++
            ) {
                # There shouldn't be any missing buffer objects, but just in case...
                if (exists $self->session->{'cmdBufferHash'}{$count}) {

                    push (@objList, $self->session->{'cmdBufferHash'}{$count});
                }
            }
        }

        foreach my $bufferObj (@objList) {

            my $listRef = [
                $bufferObj->number,
                int ($bufferObj->time),
                $bufferObj->cmd,
            ];
            push (@dataList, $listRef);
        }

        $dataHash{'Command buffer'} = \@dataList;
        $dataHashRef = \%dataHash;

        # (Do nothing when a line is double-clicked)

        # Display all of this in the notebook
        return $self->refreshNotebook(
            $tabListRef,
            $columnListRef,
            $dataHashRef,
            $buttonListRef,
            TRUE,                   # Scroll to bottom
        );
    }

    # Treeview header responses - other objects

    sub chatContactHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Chat contacts' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @list, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chatContactHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Chat contact' => '_Chat contact',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Name' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new chat contact', 'buttonAdd_chatContact',
            'Edit', 'Edit the selected chat contact', 'buttonEdit_chatContact',
            'Delete', 'Delete the selected chat contact', 'buttonDelete_chatContact',
            'Dump', 'Display a list of chat contacts in the \'main\' window',
                'buttonDump_chatContact',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @list = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('chatContactHash'));
        OUTER: foreach my $obj (@list) {

            push (@dataList, [$obj->name]);
        }

        $dataHash{'Chat contact'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_chatContact();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub colourSchemeHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Colour schemes' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @list, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->colourSchemeHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Colour scheme' => '_Colour scheme',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Standard' => 'bool',
            'Name' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new colour scheme object', 'buttonAdd_colourScheme',
            'Edit', 'Edit the selected colour scheme object', 'buttonEdit_colourScheme',
            'Delete', 'Delete the selected colour scheme object', 'buttonDelete_colourScheme',
            'Dump', 'Display a list of colour scheme objects in the \'main\' window',
                'buttonDump_colourScheme',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @list = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('colourSchemeHash'));
        OUTER: foreach my $obj (@list) {

            my ($flag, $listRef);

            if (
                $axmud::CLIENT->ivExists('constGridWinTypeHash', $obj->name)
                || $axmud::CLIENT->ivExists('constFreeWinTypeHash', $obj->name)
            ) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            $listRef = [$flag, $obj->name];
            push (@dataList, $listRef);
        }

        $dataHash{'Colour scheme'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_colourScheme();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub keycodeHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Keycode objects' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @list, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->keycodeHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Keycode' => '_Keycode',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Current' => 'bool',
            'Customised' => 'bool',
            'Name' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new keycode object', 'buttonAdd_keycode',
            'Set current', 'Set the current keycode object', 'buttonSet_keycode',
            'Clone', 'Clone the selected keycode object', 'buttonClone_keycode',
            'Edit', 'Edit the selected keycode object', 'buttonEdit_keycode',
            'Reset', 'Resets the selected keycode object', 'buttonReset_keycode',
            'Delete', 'Delete the selected keycode object', 'buttonDelete_keycode',
            'Dump', 'Display a list of keycode objects in the \'main\' window',
                'buttonDump_keycode',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @list = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('keycodeObjHash'));
        OUTER: foreach my $obj (@list) {

            my ($flag, $listRef);

            if ($axmud::CLIENT->currentKeycodeObj && $axmud::CLIENT->currentKeycodeObj eq $obj) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            $listRef = [$flag, $obj->customisedFlag, $obj->name];
            push (@dataList, $listRef);
        }

        $dataHash{'Keycode'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_keycode();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub ttsHeader {

        # Called by ->treeViewChanged when the user clicks on the 'TTS configurations' header in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @list, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'TTS configuration' => '_TTS configuration',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Name' => 'text',
            'Engine' => 'text',
            'Voice' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new TTS configuration', 'buttonAdd_tts',
            'Clone', 'Clone the selected TTS configuration', 'buttonClone_tts',
            'Edit', 'Edit the selected TTS configuration', 'buttonEdit_tts',
            'Delete', 'Delete the selected TTS configuration', 'buttonDelete_tts',
            'Dump', 'Display a list of TTS configurations in the \'main\' window', 'buttonDump_tts',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @list = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('ttsObjHash'));
        OUTER: foreach my $obj (@list) {

            my $listRef = [$obj->name, $obj->engine, $obj->voice];
            push (@dataList, $listRef);
        }

        $dataHash{'TTS configuration'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_tts();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub winmapHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Winmaps' header in the treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @list, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->winmapHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Winmap' => '_Winmap',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Standard' => 'bool',
            'Full' => 'bool',
            'Name' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new winmap', 'buttonAdd_winmap',
            'Clone', 'Clone the selected winmap', 'buttonClone_winmap',
            'Edit', 'Edit the selected winmap', 'buttonEdit_winmap',
            'Delete', 'Delete the selected winmap', 'buttonDelete_winmap',
            'Dump', 'Display a list of winmaps in the \'main\' window', 'buttonDump_winmap',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @list = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('winmapHash'));
        OUTER: foreach my $obj (@list) {

            my ($flag, $listRef);

            if ($axmud::CLIENT->ivExists('standardWinmapHash', $obj->name)) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            $listRef = [$flag, $obj->fullFlag, $obj->name];
            push (@dataList, $listRef);
        }

        $dataHash{'Winmap'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_winmap();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    sub zonemapHeader {

        # Called by ->treeViewChanged when the user clicks on the 'Zonemaps' header in the treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $tabListRef, $columnListRef, $dataHashRef, $buttonListRef,
            @list, @dataList,
            %dataHash,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->zonemapHeader', @_);
        }

        # Prepare the list of tabs
        $tabListRef = [
            'Zonemap' => '_Zonemap',
        ];

        # Prepare the list of column headings
        $columnListRef = [
            'Standard' => 'bool',
            'Full' => 'bool',
            'Temporary' => 'bool',
            'Name' => 'text',
        ];

        # Prepare the list of buttons
        $buttonListRef = [
            'Add', 'Add a new zonemap', 'buttonAdd_zonemap',
            'Clone', 'Clone the selected zonemap', 'buttonClone_zonemap',
            'Edit', 'Edit the selected zonemap', 'buttonEdit_zonemap',
            'Delete', 'Delete the selected zonemap', 'buttonDelete_zonemap',
            'Dump', 'Display a list of zonemaps in the \'main\' window', 'buttonDump_zonemap',
        ];

        # Prepare the data to be displayed (there is only one tab)
        @list = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('zonemapHash'));
        OUTER: foreach my $obj (@list) {

            my ($flag, $listRef);

            if ($axmud::CLIENT->ivExists('standardZonemapHash', $obj->name)) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            $listRef = [$flag, $obj->fullFlag, $obj->tempFlag, $obj->name];
            push (@dataList, $listRef);
        }

        $dataHash{'Zonemap'} = \@dataList;
        $dataHashRef = \%dataHash;

        # Which function to call if the user double-clicks on a row in the list - in this case, it's
        #   equivalent to the edit button
        $self->ivPoke('notebookSelectRef', sub {

            $self->buttonEdit_zonemap();
        });

        # Display all of this in the notebook
        return $self->refreshNotebook($tabListRef, $columnListRef, $dataHashRef, $buttonListRef);
    }

    # Treeview header responses - help

    sub quickHelpHeader {

        # Called by ->treeViewChanged when the user clicks on one of the quick help item in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $file, $fileHandle,
            @list,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->quickHelpHeader', @_);
        }

        # Load the quick help file
        $file = $axmud::SHARE_DIR . '/help/misc/quickhelp';
        if (-e $file && open($fileHandle, $file)) {

            @list = <$fileHandle>;
            close($fileHandle);

            foreach my $item (@list) {

                chomp $item;
            }
        }

        # Display the help in the notebook
        return $self->refreshTextView($item, @list);
    }

    sub peekPokeHelpHeader {

        # Called by ->treeViewChanged when the user clicks on one of the peek/poke help item in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $file, $fileHandle,
            @list,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->peekPokeHelpHeader', @_);
        }

        # Load the quick help file
        $file = $axmud::SHARE_DIR . '/help/misc/peekpoke';
        if (-e $file && open($fileHandle, $file)) {

            @list = <$fileHandle>;
            close($fileHandle);

            foreach my $item (@list) {

                chomp $item;
            }
        }

        # Display the help in the notebook
        return $self->refreshTextView($item, @list);
    }

    sub cmdHeader {

        # Called by ->treeViewChanged when the user clicks on one of the client commands in the
        #   treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $cmd, $obj,
            @list,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->cmdHeader', @_);
        }

        # Remove the command sigil from the beginning of $item
        $cmd = substr($item, length($axmud::CLIENT->cmdSep));
        # Get the blessed reference of the command object for this command
        $obj = $axmud::CLIENT->ivShow('clientCmdHash', $cmd);

        # Get the first three lines of the help text
        push (@list, $obj->getHelpStart());
        # Call the help function for the command to fetch the command-specific text
        push (@list, $obj->help($self->session));
        # Fetch the final three lines of the help text; add an extra blank line
        push (@list, $obj->getHelpEnd(), ' ');

        # (Do nothing when a line is double-clicked)

        # Display the help in the notebook
        return $self->refreshTextView($item, @list);
    }

    sub axbasicKeywordHeader {

        # Called by ->treeViewChanged when the user clicks on one of the Axbasic keyword help topics
        #   in the treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $obj,
            @list,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->axbasicKeywordHeader', @_);
        }

        # Get the ';axbasichelp' command object (rather than going through GA::Generic::Cmd)
        $obj = $axmud::CLIENT->ivShow('clientCmdHash', 'axbasichelp');
        # Get the help for the keyword $item
        @list = $obj->abHelp($self->session, $item, 'keyword');

        # (Do nothing when a line is double-clicked)

        # Display the help in the notebook
        return $self->refreshTextView($item, @list);
    }

    sub axbasicFuncHeader {

        # Called by ->treeViewChanged when the user clicks on one of the Axbasic intrinsic function
        #   help topics in the treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $obj,
            @list,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->axbasicFuncHeader', @_);
        }

        # Get the ';axbasichelp' command object (rather than going through GA::Generic::Cmd)
        $obj = $axmud::CLIENT->ivShow('clientCmdHash', 'axbasichelp');
        # Get the help for the keyword $item
        @list = $obj->abHelp($self->session, $item, 'func');

        # (Do nothing when a line is double-clicked)

        # Display the help in the notebook
        return $self->refreshTextView($item, @list);
    }

    sub taskHeader {

        # Called by ->treeViewChanged when the user clicks on one of the tasks in the treeview
        #
        # Expected arguments
        #   $item   - The treeview item that was clicked (i.e. the text it contains)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $item, $check) = @_;

        # Local variables
        my (
            $cmdObj, $packageName, $prettyName,
            @list,
        );

        # Check for improper arguments
        if (! defined $item || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->taskHeader', @_);
        }

        # Get the ';taskhelp' command object (rather than going through GA::Generic::Cmd)
        $cmdObj = $axmud::CLIENT->ivShow('clientCmdHash', 'taskhelp');

        # Get the package name for the task
        $packageName = $cmdObj->findTaskPackageName($self->session, $item);
        # Remove the 'Games::Axmud::Task::' bit...
        $prettyName =~ s/^Games\:\:Axmud\:\:Task\:\://;
        # Get the help for the task
        @list = $cmdObj->taskHelp($self->session, $prettyName);

        # (Do nothing when a line is double-clicked)

        # Display the help in the notebook
        return $self->refreshTextView($prettyName, @list);
    }

    # Header support functions

    sub setTabList_prof {

        # Called by $self->allProfHeader and ->currentProfHeader
        # Sets up the list of tabs appropriate for displaying profiles in the notebook list, in the
        #   form
        #   [
        #       'tab_name' => 'tab_mnemonic',
        #       'tab_name' => 'tab_mnemonic',
        #       'tab_name' => 'tab_mnemonic',
        #       ...
        #   ]
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list containing two list references:
        #       - the first is the list described above
        #       - the second is a list of 'tab_name's

        my ($self, $check) = @_;

        # Local variables
        my (
            @emptyList, @categoryList, @tabList,
            %mnemonicHash,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->setTabList_prof', @_);
            return @emptyList;
        }

        # Display the tabs in reverse priority order (i.e. so that 'world' is always first)
        @categoryList = reverse $self->session->profPriorityList;
        foreach my $category (@categoryList) {

            # Add to the list the pair 'world' and 'W_orld', the pair 'char' and 'C_har', etc
            push (
                @tabList,
                $category,
                $self->getMnemonic(ucfirst($category), \%mnemonicHash),
            );
        }

        return (\@tabList, \@categoryList);
    }

    sub setColumnList_prof {

        # Called by $self->allProfHeader and ->currentProfHeader
        # Sets up the list of column titles appropriate for displaying profiles in the notebook
        #   list, in the form
        #   [
        #       'column_name' => 'type',
        #       'column_name' => 'type',
        #       'column_name' => 'type',
        #       ...
        #   ]
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a reference to the list described above

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setColumnList_prof', @_);
        }

        @list = (
            'Current' => 'bool',
            'Profile Name' => 'text',
            'Category' => 'text',
        );

        return \@list;
    }

    sub setButtonList_prof {

        # Called by $self->allProfHeader and ->currentProfHeader
        # Sets up the list of buttons appropriate for manipulating profiles in the notebook list,
        #   in the form
        #   [
        #       'button_name', 'tooltip', 'callback_sub_ref',
        #       'button_name', 'tooltip', 'callback_sub_ref',
        #       'button_name', 'tooltip', 'callback_sub_ref',
        #       ...
        #   ]
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a reference to the list described above

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setButtonList_prof', @_);
        }

        @list = (
            'Add', 'Add a new profile', 'buttonAdd_prof',
            'Edit', 'Edit the selected profile', 'buttonEdit_prof',
            'Set current', 'Set a current profile', 'buttonSet_prof',
            'Unset current', 'Unset the current profile', 'buttonUnset_prof',
            'Clone', 'Clone the selected profile', 'buttonClone_prof',
            'Delete', 'Delete the selected profile', 'buttonDelete_prof',
            'Dump', 'Display this list of profiles in the \'main\' window', 'buttonDump_prof',
            'Dump all', 'Display a list of all profiles in the \'main\' window',
                'buttonDumpAll_prof',
        );

        return \@list;
    }

    sub compileList_profPriority {

        # Called by $self->profPriorityHeader
        # Compiles the data to be displayed in a Gtk2::SimpleList, and converts it into a reference
        #   to a hash
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a reference to the has described above

        my ($self, $check) = @_;

        # Local variables
        my (
            $count, $dataHashRef,
            @dataList, @otherList,
            %dataHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->compileList_profPriority',
                @_,
            );
        }

        # A numbered list of categories comes first, containing everything in
        #   $self->session->profPriorityList
        # Then follows an unnumbered list of any remaining categories which aren't in the priority
        #   list

        # Numbered categories (in priority list)
        $count = 0;
        OUTER: foreach my $category ($self->session->profPriorityList) {

            my $listRef;

            $count++;
            $listRef = [$count, $category];
            push (@dataList, $listRef);
        }

        # Unnumbered categories (not in priority list). Compile a list of unnumbered categories.
        #   First check the default priority list
        OUTER: foreach my $defaultCategory ($axmud::CLIENT->constProfPriorityList) {

            INNER: foreach my $numberedCategory ($self->session->profPriorityList) {

                if ($defaultCategory eq $numberedCategory) {

                    next OUTER;
                }
            }

            # One of the default categories (world, guild, race, char) is missing from the priority
            #   list
            push (@otherList, $defaultCategory);
        }

        # Next check profile template categories
        OUTER: foreach my $category ($self->session->ivKeys('templateHash')) {

            INNER: foreach my $numberedCategory ($self->session->profPriorityList) {

                if ($category eq $numberedCategory) {

                    next OUTER;
                }
            }

            # This template category is missing from the priority list
            push (@otherList, $category);
        }

        # Add the unnumbered categories to the displayed list
        @otherList = sort {lc($a) cmp lc($b)} (@otherList);
        foreach my $category (@otherList) {

            my $listRef = ['-', $category];
            push (@dataList, $listRef);
        }

        # Display the list
        $dataHash{'Profile priority list'} = \@dataList;
        $dataHashRef = \%dataHash;

        return $dataHashRef;
    }

    sub setTabList_cage {

        # Called by $self->allCageHeader and ->currentCageHeader
        # Sets up the list of tabs appropriate for displaying cages in the notebook list, in the
        #   form
        #   [
        #       'tab_name' => 'tab_mnemonic',
        #       'tab_name' => 'tab_mnemonic',
        #       'tab_name' => 'tab_mnemonic',
        #       ...
        #   ]
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list containing two list references:
        #       - the first is the list described above
        #       - the second is a list of 'tab_name's

        my ($self, $check) = @_;

        # Local variables
        my (
            @emptyList, @tabList, @typeList,
            %mnemonicHash,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->setTabList_cage', @_);
            return @emptyList;
        }

        foreach my $type ($axmud::CLIENT->cageTypeList) {

            # Add to the list the pair 'trigger' and 't_rigger', the pair 'alias' and 'a_lias', etc
            push (
                @tabList,
                lc($type),
                $self->getMnemonic($type, \%mnemonicHash),
            );

            # Everything in @list is upper-case, so reduce it to lower-case
            push (@typeList, lc($type));
        }

        return (\@tabList, \@typeList);
    }

    sub setColumnList_cage {

        # Called by $self->allCageHeader and ->currentCageHeader
        # Sets up the list of column titles appropriate for displaying cages in the notebook list,
        #   in the form
        #   [
        #       'column_name' => 'type',
        #       'column_name' => 'type',
        #       'column_name' => 'type',
        #       ...
        #   ]
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a reference to the list described above

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setColumnList_cage', @_);
        }

        @list = (
            'Current' => 'bool',
            'Cage Name' => 'text',
        );

        return \@list;
    }

    sub setButtonList_cage {

        # Called by $self->allCageHeader and ->currentCageHeader
        # Sets up the list of buttons appropriate for manipulating cages in the notebook list, in
        #   the form
        #   [
        #       'button_name', 'tooltip', 'callback_sub_ref',
        #       'button_name', 'tooltip', 'callback_sub_ref',
        #       'button_name', 'tooltip', 'callback_sub_ref',
        #       ...
        #   ]
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a reference to the list described above

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments

        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setButtonList_cage', @_);
        }

        @list = (
            'Edit', 'Edit the selected cage', 'buttonEdit_cage',
            'Dump', 'Display this list of cages in the \'main\' window', 'buttonDump_cage',
            'Dump all', 'Display a list of all cages in the \'main\' window', 'buttonDumpAll_cage',
        );

        return \@list;
    }

    sub getSortedCages {

        # Called by $self->allCageHeader and $self->currentCageHeader
        # Returns a list of cages to be displayed in a single tab, sorted in the priority order of
        #   each cage's associated profile
        #
        # Expected arguments
        #   $tab    - The name of the tab, which corresponds to a profile category ('world', 'char',
        #               etc)
        #
        # Return values
        #   An empty list on improper arguments
        #   The sorted list of cages otherwise

        my ($self, $tab, $check) = @_;

        # Local variables
        my (
            @emptyList, @cageList, @spareList, @lonelyList, @sortedList,
            %cageHash,
        );

        # Check for improper arguments
        if (! defined $tab || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getSortedCages', @_);
            return @emptyList;
        }

        # Get a hash of cages belonging to this tab
        foreach my $cageObj ($self->session->ivValues('cageHash')) {

            if ($cageObj->cageType eq $tab) {

                if (
                    defined $cageObj->profCategory
                    && $self->session->ivExists('currentCageHash', $cageObj->name)
                ) {
                    $cageHash{$cageObj->profCategory} = $cageObj;

                } else {

                    # Not a current cage - leave it until the end
                    push (@spareList, $cageObj);
                }
            }
        }

        # Sort the list in priority order
        foreach my $category ($self->session->profPriorityList) {

            if (exists $cageHash{$category}) {

                push (@cageList, $cageHash{$category});
                delete $cageHash{$category};
            }
        }

        if (%cageHash) {

            # These cages are associated with profiles which aren't in the profile priority list
            @lonelyList = sort {lc($a->name) cmp lc($b->name)} (values %cageHash);
            push (@cageList, @lonelyList);
        }

        # Add all the cages for non-current profiles
        @sortedList = sort {lc($a->name) cmp lc($b->name)} (@spareList);
        push (@cageList, @sortedList);

        return @cageList;
    }

    sub setColumnList_model {

        # Called by $self->allModelHeader, $self->regionModelHeader, etc
        # Sets up the list of column titles appropriate for displaying model objects in the notebook
        #   list, in the form
        #   [
        #       'column_name' => 'type',
        #       'column_name' => 'type',
        #       'column_name' => 'type',
        #       ...
        #   ]
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a reference to the list described above

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setColumnList_model', @_);
        }

        @list = (
            'Model #' => 'int',
            'Category' => 'text',
            'Name' => 'text',
        );

        return \@list;
    }

    sub setButtonList_model {

        # Called by $self->allModelHeader, $self->regionModelHeader, etc (most world model object
        #   tabs use this function, but a few - such as the tab for characters - specify their own
        #   buttons)
        # Sets up the list of buttons appropriate for manipulating model objects in the notebook
        #   list, in the form
        #   [
        #       'button_name', 'tooltip', 'callback_sub_ref',
        #       'button_name', 'tooltip', 'callback_sub_ref',
        #       'button_name', 'tooltip', 'callback_sub_ref',
        #       ...
        #   ]
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a reference to the list described above

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setButtonList_model', @_);
        }

        @list = (
            'Add', 'Add an object to the world model', 'buttonAdd_model',
            'Edit', 'Edit the selected world model object', 'buttonEdit_model',
            'Delete', 'Delete the selected world model object', 'buttonDelete_model',
            'Dump', 'Displays a list of all world model objects in the \'main\' window',
                'buttonDump_model',
        );

        return \@list;
    }

    # Treeview callbacks

    sub treeViewRowActivated {

        # Treeview's 'row_activated' callback - expands and collapses parts of the tree
        # Defined in $self->enable
        #
        # Expected arguments
        #   $tree           - The Gtk2::TreeView widget
        #   $path, $column  - The clicked cell
        #   $self           - This Perl object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($tree, $path, $column, $self, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $tree || ! defined $path || ! defined $column || ! defined $self
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->treeViewRowActivated', @_);
        }

        if ($tree->row_expanded($path)) {

            $tree->collapse_row($path);

        } else {

            $tree->expand_row($path, FALSE);
        }

        return 1;
    }

    sub treeViewChanged {

        # Treeview's 'changed' callback - responds to clicks on the tree
        # Defined in $self->winEnable
        #
        # Expected arguments
        #   $selection  - Gtk2::Selection
        #   $self       - This Perl object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($selection, $self, $check) = @_;

        # Local variables
        my ($model, $iter, $type, $method);

        # Check for improper arguments
        if (! defined $selection || ! defined $self || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->treeViewChanged', @_);
        }

        ($model, $iter) = $selection->get_selected();
        if (! $iter) {

            return undef;

        } else {

            $type = $model->get($iter, 0);
        }

        # Is the clicked item a header? If so, call its function
        if ($self->ivExists('headerHash', $type)) {

            # ->notebookSelectRef's default value is 'undef'; the function we're about to call will
            #   set it, if need be
            $self->ivPoke('notebookSelectRef', undef);
            # Remember which type of notebook we're about to display
            $self->ivPoke('notebookCurrentHeader', $type);

            # Call the function to create this type of notebook
            $method = $self->ivShow('headerHash', $type);
            $self->$method($type);
        }

        return 1;
    }

    # Profile button callbacks

    sub buttonAdd_prof {

        # Callback: Adds a profile (equivalent to ';addworld', ';addchar', etc)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if a temporary profile object can't be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $world, $profObj, $templObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_prof', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new profile
        $slWidget->get_selection->unselect_all();

        # Create a temporary profile, to store the changes the user will make
        $world = $self->session->currentWorld->name;

        if ($tab eq 'world') {
            $profObj = Games::Axmud::Profile::World->new($self->session, '<temp>', TRUE);
        } elsif ($tab eq 'guild') {
            $profObj = Games::Axmud::Profile::Guild->new($self->session, '<temp>', $world, TRUE);
        } elsif ($tab eq 'race') {
            $profObj = Games::Axmud::Profile::Race->new($self->session, '<temp>', $world, TRUE);
        } elsif ($tab eq 'char') {
            $profObj = Games::Axmud::Profile::Char->new($self->session, '<temp>', $world, TRUE);
        } else {

            # Find the matching template profile
            if ($self->session->ivExists('templateHash', $tab)) {

                $templObj = $self->session->ivShow('templateHash', $tab);

                # Spawn a new custom profile
                $profObj = $templObj->spawn(
                    $self->session,
                    '<temp>',
                    $self->session->currentWorld->name,
                    TRUE,
                );
            }
        }

        if (! $profObj) {

            # Can't edit anything
            return undef;

        } else {

            # Open up an 'edit' window to create the new object, replacing the temporary one we've
            #   just created
            if ($tab eq 'world') {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::World',
                    $self,
                    $self->session,
                    'Edit world profile \'' . $profObj->name . '\'',
                    $profObj,
                    TRUE,           # Temporary object
                );

            } elsif ($tab eq 'guild') {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::Guild',
                    $self,
                    $self->session,
                    'Edit guild profile \'' . $profObj->name . '\'',
                    $profObj,
                    TRUE,           # Temporary object
                );

            } elsif ($tab eq 'race') {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::Race',
                    $self,
                    $self->session,
                    'Edit race profile \'' . $profObj->name . '\'',
                    $profObj,
                    TRUE,           # Temporary object
                );

            } elsif ($tab eq 'char') {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::Char',
                    $self,
                    $self->session,
                    'Edit character profile \'' . $profObj->name . '\'',
                    $profObj,
                    TRUE,           # Temporary object
                );

            } else {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::Custom',
                    $self,
                    $self->session,
                    'Edit ' . $profObj->category . ' profile \'' . $profObj->name . '\'',
                    $profObj,
                    TRUE,           # Temporary object
                );
            }
        }

        return 1;
    }

    sub buttonEdit_prof {

        # Callback: Edits a profile (equivalent to ';editworld', ';editchar', etc)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $dataRef, $profName, $profObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_prof', @_);
        }

        # Get the selected tab
        $tab = $self->notebookGetTab();
        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The profile name is the second item of data
        $profName = $dataList[1];
        if (! $profName) {

            # Can't continue
            return undef;
        }

        # Get the profile itself
        if ($tab eq 'world') {
            $profObj = $axmud::CLIENT->ivShow('worldProfHash', $profName);
        } else {
            $profObj = $self->session->ivShow('profHash', $profName);
        }

        if (! $profObj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            if ($tab eq 'world') {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::World',
                    $self,
                    $self->session,
                    'Edit world profile \'' . $profName . '\'',
                    $profObj,
                    FALSE,                  # Not temporary
                );

            } elsif ($tab eq 'guild') {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::Guild',
                    $self,
                    $self->session,
                    'Edit guild profile \'' . $profName . '\'',
                    $profObj,
                    FALSE,                  # Not temporary
                );

            } elsif ($tab eq 'race') {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::Race',
                    $self,
                    $self->session,
                    'Edit race profile \'' . $profName . '\'',
                    $profObj,
                    FALSE,                  # Not temporary
                );

            } elsif ($tab eq 'char') {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::Char',
                    $self,
                    $self->session,
                    'Edit char profile \'' . $profName . '\'',
                    $profObj,
                    FALSE,                  # Not temporary
                );

            } else {

                $self->createFreeWin(
                    'Games::Axmud::EditWin::Profile::Custom',
                    $self,
                    $self->session,
                    'Edit ' . $profObj->category . ' profile \'' . $profName . '\'',
                    $profObj,
                    FALSE,                  # Not temporary
                );
            }

            return 1;
        }
    }

    sub buttonSet_prof {

        # Callback: Sets a current profile (equivalent to ';setworld', ';setchar', etc)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $dataRef, $profName, $profObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonSet_prof', @_);
        }

        # Get the selected tab
        $tab = $self->notebookGetTab();
        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The profile name is the second item of data
        $profName = $dataList[1];
        if (! $profName) {

            # Can't continue
            return undef;
        }

        # Get the profile itself (to check it still exists)
        if ($tab eq 'world') {
            $profObj = $axmud::CLIENT->ivShow('worldProfHash', $profName);
        } else {
            $profObj = $self->session->ivShow('profHash', $profName);
        }

        if (! $profObj) {

            # Can't continue
            return undef;
        }

        # Set the profile
        if ($profObj->category eq 'world') {
            $self->session->pseudoCmd('setworld ' . $profName, $self->pseudoCmdMode);
        } elsif ($profObj->category eq 'guild') {
            $self->session->pseudoCmd('setguild ' . $profName, $self->pseudoCmdMode);
        } elsif ($profObj->category eq 'race') {
            $self->session->pseudoCmd('setrace ' . $profName, $self->pseudoCmdMode);
        } elsif ($profObj->category eq 'char') {
            $self->session->pseudoCmd('setchar ' . $profName, $self->pseudoCmdMode);
        } else {
            $self->session->pseudoCmd('setcustomprofile ' . $profName, $self->pseudoCmdMode);
        }

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonUnset_prof {

        # Callback: Unsets a current profile (equivalent to ';unsetguild', ';unsetchar', etc)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the user tries to unset a current world profile
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $profObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonUnset_prof', @_);
        }

        # Get the selected tab
        $tab = $self->notebookGetTab();

        # There is no ';unsetworld' command
        if ($tab eq 'world') {

            $self->showMsgDialogue(
                'Unset profile',
                'warning',
                'Current world profiles can\'t be unset',
                'ok',
            );

            return undef;
        }

        # Unset the current profile for the category displayed in this tab
        if ($tab eq 'guild') {
            $self->session->pseudoCmd('unsetguild', $self->pseudoCmdMode);
        } elsif ($tab eq 'race') {
            $self->session->pseudoCmd('unsetrace', $self->pseudoCmdMode);
        } elsif ($tab eq 'char') {
            $self->session->pseudoCmd('unsetchar', $self->pseudoCmdMode);
        } else {

            $profObj = $self->session->ivShow('currentProfHash', $tab);
            if ($profObj) {

                $self->session->pseudoCmd(
                    'unsetcustomprofile ' . $profObj->name,
                    $self->pseudoCmdMode,
                );
            }
        }

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonClone_prof {

        # Callback: Clones the selected profile (equivalent to ';cloneworld', ';clonechar', etc)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $dataRef, $profName, $profObj, $cloneName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonClone_prof', @_);
        }

        # Get the selected tab
        $tab = $self->notebookGetTab();
        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The profile name is the second item of data
        $profName = $dataList[1];
        if (! $profName) {

            # Can't continue
            return undef;
        }

        # Get the profile itself
        if ($tab eq 'world') {
            $profObj = $axmud::CLIENT->ivShow('worldProfHash', $profName);
        } else {
            $profObj = $self->session->ivShow('profHash', $profName);
        }

        if (! $profObj) {

            # Can't continue
            return undef;
        }

        # Prompt the user for the name of the clone (max 16 chars)
        $cloneName = $self->showEntryDialogue(
            'Clone profile',
            "Enter a name for the clone\n<i>Max 16 chars: A-Z a-z _ 0-9</i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($cloneName) {

            # Clone the profile
            if ($profObj->category eq 'world') {

                $self->session->pseudoCmd(
                    'cloneworld ' . $profName . ' ' . $cloneName,
                    $self->pseudoCmdMode,
                );

            } elsif ($profObj->category eq 'guild') {

                $self->session->pseudoCmd(
                    'cloneguild ' . $profName . ' ' . $cloneName,
                    $self->pseudoCmdMode,
                );

            } elsif ($profObj->category eq 'race') {

                $self->session->pseudoCmd(
                    'clonerace ' . $profName . ' ' . $cloneName,
                    $self->pseudoCmdMode,
                );

            } elsif ($profObj->category eq 'char') {

                $self->session->pseudoCmd(
                    'clonechar ' . $profName . ' ' . $cloneName,
                    $self->pseudoCmdMode,
                );

            } else {

                $self->session->pseudoCmd(
                    'clonecustomprofile ' . $profName . ' ' . $cloneName,
                    $self->pseudoCmdMode,
                );
            }

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonDelete_prof {

        # Callback: Deletes a profile (equivalent to ';deleteworld', ';deletechar', etc)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $dataRef, $profName, $profObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_prof', @_);
        }

        # Get the selected tab
        $tab = $self->notebookGetTab();
        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The profile name is the second item of data
        $profName = $dataList[1];
        if (! $profName) {

            # Can't continue
            return undef;
        }

        # Get the profile itself (to check it still exists)
        if ($tab eq 'world') {
            $profObj = $axmud::CLIENT->ivShow('worldProfHash', $profName);
        } else {
            $profObj = $self->session->ivShow('profHash', $profName);
        }

        if (! $profObj) {

            # Can't continue
            return undef;
        }

        # Delete the profile
        if ($profObj->category eq 'world') {
            $self->session->pseudoCmd('deleteworld ' . $profName, $self->pseudoCmdMode);
        } elsif ($profObj->category eq 'guild') {
            $self->session->pseudoCmd('deleteguild ' . $profName, $self->pseudoCmdMode);
        } elsif ($profObj->category eq 'race') {
            $self->session->pseudoCmd('deleterace ' . $profName, $self->pseudoCmdMode);
        } elsif ($profObj->category eq 'char') {
            $self->session->pseudoCmd('deletechar ' . $profName, $self->pseudoCmdMode);
        } else {
            $self->session->pseudoCmd('deletecustomprofile ' . $profName, $self->pseudoCmdMode);
        }

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_prof {

        # Callback: Displays profiles in the 'main' window (equivalent to ';listword',
        #   ';listchar' etc)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $tab;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_prof', @_);
        }

        # Get the selected tab
        $tab = $self->notebookGetTab();

        # Display the list
        if ($tab eq 'world') {
            $self->session->pseudoCmd('listworld', $self->pseudoCmdMode);
        } elsif ($tab eq 'guild') {
            $self->session->pseudoCmd('listguild', $self->pseudoCmdMode);
        } elsif ($tab eq 'race') {
            $self->session->pseudoCmd('listrace', $self->pseudoCmdMode);
        } elsif ($tab eq 'char') {
            $self->session->pseudoCmd('listchar', $self->pseudoCmdMode);
        } else {

            # (Actually lists all custom profiles based on the same template)
            $self->session->pseudoCmd('listcustomprofile ' . $tab, $self->pseudoCmdMode);
        }

        return 1;
    }

    sub buttonDumpAll_prof {

        # Callback: Displays all profiles in the 'main' window (equivalent to ';listprofile')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDumpAll_prof', @_);
        }

        # Display the list of profiles
        $self->session->pseudoCmd('listprofile', $self->pseudoCmdMode);

        return 1;
    }

    # Template button callbacks

    sub buttonAdd_template {

        # Callback: Adds a profile template (equivalent to ';addtemplate')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if a temporary profile template object can't be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $templObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_template', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new profile template
        $slWidget->get_selection->unselect_all();

        # Create a temporary template
        $templObj = Games::Axmud::Profile::Template->new($self->session, '<temp>', TRUE);
        if (! $templObj) {

            # Can't edit anything
            return undef;

        } else {

            # Open up an 'edit' window to create the new object, replacing the temporary one we've
            #   just created
            $self->createFreeWin(
                'Games::Axmud::EditWin::Profile::Template',
                $self,
                $self->session,
                'Edit \'' . $templObj->category . '\' profile template',
                $templObj,
                TRUE,           # Temporary object
            );
        }

        return 1;
    }

    sub buttonEdit_template {

        # Callback: Edits a profile template (equivalent to ';edittemplate')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $category, $templObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_template', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The template category is the second item of data
        $category = $dataList[1];
        if (! $category) {

            # Can't continue
            return undef;
        }

        # Get the template itself
        $templObj = $self->session->ivShow('templateHash', $category);
        if (! $templObj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Profile::Template',
                $self,
                $self->session,
                'Edit \'' . $category . '\' profile template',
                $templObj,
                FALSE,                  # Not temporary
            );

            return 1;
        }
    }

    sub buttonClone_template {

        # Callback: Clones the selected profile template (equivalent to ';clonetemplate')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $category, $templObj, $cloneCategory,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonClone_template', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The template category is the second item of data
        $category = $dataList[1];
        if (! $category) {

            # Can't continue
            return undef;
        }

        # Get the template itself
        $templObj = $self->session->ivShow('templateHash', $category);
        if (! $templObj) {

            # Can't continue
            return undef;
        }

        # Prompt the user for the category of the clone (max 16 chars)
        $cloneCategory = $self->showEntryDialogue(
            'Clone template',
            "Enter a category for the clone\n<i>Max 16 chars: A-Z a-z _ 0-9</i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($cloneCategory) {

            # Clone the template
            $self->session->pseudoCmd(
                'clonetemplate ' . $category . ' ' . $cloneCategory,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonDelete_template {

        # Callback: Deletes a profile template (equivalent to ';deletetemplate')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $category, $templObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_template', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The template category is the second item of data
        $category = $dataList[1];
        if (! $category) {

            # Can't continue
            return undef;
        }

        # Get the template itself (to check it still exists)
        $templObj = $self->session->ivShow('templateHash', $category);
        if (! $templObj) {

            # Can't continue
            return undef;
        }

        # Delete the template
        $self->session->pseudoCmd('deletetemplate ' . $category, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_template {

        # Callback: Displays profile templates in the 'main' window (equivalent to ';listtemplate')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_template', @_);
        }

        # Display the list of profile templates
        $self->session->pseudoCmd('listtemplate', $self->pseudoCmdMode);

        return 1;
    }

    # Profile priority button callbacks

    sub buttonMoveTop_profPriority {

        # Callback: Moves a category of profile to the top of the priority list (comparable to
        #   ';setprofilepriority')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected or if the selected item can't be
        #       moved to the top
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $index, $priority, $category,
            @priorityList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonMoveTop_profPriority',
                @_,
            );
        }

        # Import the priority list
        @priorityList = $self->session->profPriorityList;

        # Import the GA::Gtk::Simple::List and find the currently selected line and the data it
        #   contains
        ($index, $priority, $category) = $self->profPriorityData();
        if (! defined $index) {

            return undef;
        }

        # $index must be at least 2nd in the list (element 1), else it can't be moved up
        if ($index) {

            # Move the item to the top of the priority list
            splice(@priorityList, $index, 1);
            unshift(@priorityList, $category);
        }

        # Now, try using the client command ';setprofilepriority' with @priorityList as the
        #   argument. The command checks whether the new arrangement is allowed
        if (
            ! $self->session->pseudoCmd(
                'setprofilepriority ' . join(' ', @priorityList),
                $self->pseudoCmdMode,
            )
        ) {
            return undef;

        } else {

            # Update the notebook (if the priority list has actually changed)
            # The single argument makes sure the same item is selected
            $self->updateNotebook(0);
            return 1;
        }
    }

    sub buttonMoveUp_profPriority {

        # Callback: Moves a category of profile up the priority list (comparable to
        #   ';setprofilepriority')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected or if the selected item can't be
        #       moved up
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $index, $priority, $category,
            @priorityList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonMoveUp_profPriority',
                @_,
            );
        }

        # Import the priority list
        @priorityList = $self->session->profPriorityList;

        # Import the GA::Gtk::Simple::List and find the currently selected line and the data it
        #   contains
        ($index, $priority, $category) = $self->profPriorityData();
        if (! defined $index) {

            return undef;
        }

        # $index must be at least 2nd in the list (element 1), else it can't be moved up
        if ($index) {

            # Move the item up in the priority list
            splice(@priorityList, $index, 1);
            splice(@priorityList, ($index - 1), 0, $category);
        }

        # Now, try using the client command ';setprofilepriority' with @priorityList as the
        #   argument. The command checks whether the new arrangement is allowed
        if (
            ! $self->session->pseudoCmd(
                'setprofilepriority ' . join(' ', @priorityList),
                $self->pseudoCmdMode,
            )
        ) {
            return undef;

        } else {

            # Update the notebook (if the priority list has actually changed)
            # The single argument makes sure the same item is selected
            $self->updateNotebook($index - 1);
            return 1;
        }
    }

    sub buttonMoveDown_profPriority {

        # Callback: Moves a category of profile down the priority list (comparable to
        #   ';setprofilepriority')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected or if the selected item can't be
        #       moved down
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $index, $priority, $category,
            @priorityList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonMoveDown_profPriority',
                @_,
            );
        }

        # Import the priority list
        @priorityList = $self->session->profPriorityList;

        # Import the GA::Gtk::Simple::List and find the currently selected line and the data it
        #   contains
        ($index, $priority, $category) = $self->profPriorityData();
        if (! defined $index) {

            return undef;
        }

        # Move the item down in the priority list
        splice(@priorityList, $index, 1);
        splice(@priorityList, ($index + 1), 0, $category);

        # Now, try using the client command ';setprofilepriority' with @priorityList as the
        #   argument. The command checks whether the new arrangement is allowed
        if (
            ! $self->session->pseudoCmd(
                'setprofilepriority ' . join(' ', @priorityList),
                $self->pseudoCmdMode,
            )
        ) {
            return undef;

        } else {

            # Update the notebook (if the priority list has actually changed)
            # The single argument makes sure the same item is selected
            $self->updateNotebook($index + 1);
            return 1;
        }
    }

    sub buttonGivePriority_profPriority {

        # Callback: Takes a category of profile which isn't in the priority list and moves it into
        #   the priority list (comparable to ';setprofilepriority')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected, if the selected item is already
        #       in the priority list or if the 'give priority' operation fails
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $index, $priority, $category,
            @priorityList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonGivePriority_profPriority',
                @_,
            );
        }

        # Import the priority list
        @priorityList = $self->session->profPriorityList;

        # Import the GA::Gtk::Simple::List and find the currently selected line and the data it
        #   contains
        ($index, $priority, $category) = $self->profPriorityData();
        # If the category is already marked as being in the priority list, do nothing
        if (! defined $priority || $priority ne '-') {

            return undef;
        }

        # Add the category to the top of the priority list
        unshift (@priorityList, $category);

        # Now, try using the client command ';setprofilepriority' with @priorityList as the
        #   argument. The command checks whether the new arrangement is allowed
        if (
            ! $self->session->pseudoCmd(
                'setprofilepriority ' . join(' ', @priorityList),
                $self->pseudoCmdMode,
            )
        ) {
            return undef;

        } else {

            # Update the notebook (if the priority list has actually changed)
            # The single argument makes sure the same item is selected
            $self->updateNotebook(0);
            return 1;
        }
    }

    sub buttonLosePriority_profPriority {

        # Callback: Moves a category of profile out of the priority list entirely (comparable to
        #   ';setprofilepriority')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected or if the selected item isn't
        #       already in the priority list
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $index, $priority, $category,
            @priorityList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonLosePriority_profPriority',
                @_,
            );
        }

        # Import the priority list
        @priorityList = $self->session->profPriorityList;

        # Import the GA::Gtk::Simple::List and find the currently selected line and the data it
        #   contains
        ($index, $priority, $category) = $self->profPriorityData();
        # If the category is already marked as not being in the priority list, do nothing
        if (! defined $priority || $priority eq '-') {

            return undef;
        }

        # Remove the category from the priority list
        splice (@priorityList, $index, 1);

        # Now, try using the client command ';setprofilepriority' with @priorityList as the
        #   argument. The command checks whether the new arrangement is allowed
        if (
            ! $self->session->pseudoCmd(
                'setprofilepriority ' . join(' ', @priorityList),
                $self->pseudoCmdMode,
            )
        ) {
            return undef;

        } else {

            # Update the notebook (if the priority list has actually changed)
            # Use no arguments, so that no item is selected (can't easily predict where in the list
            #   the profile will now occur)
            $self->updateNotebook();
            return 1;
        }
    }

    sub buttonResetList_profPriority {

        # Callback: Resets the profile priority list to the default list (comparable to
        #   ';setprofilepriority', with no arguments)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonResetList_profPriority',
                @_,
            );
        }

        $self->session->pseudoCmd('setprofilepriority', $self->pseudoCmdMode);
        $self->updateNotebook();

        return 1;
    }

    # Cage button callbacks

    sub buttonEdit_cage {

        # Callback: Edits a cage (equivalent to ';editcage')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $cageNamee, $cageObj, $package,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_cage', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The cage's name is the second item of data
        $cageNamee = $dataList[1];
        if (! $cageNamee) {

            # Can't continue
            return undef;
        }

        # Get the cage object itself
        $cageObj = $self->session->ivShow('cageHash', $cageNamee);
        if (! $cageObj) {

            # Can't continue
            return undef;

        } else {

            # Work out the package name of the correct cage 'edit' window
            if ($axmud::CLIENT->ivExists('pluginCageEditWinHash', $cageObj->cageType)) {

                # Cage 'edit' window added by a plugin
                $package = $axmud::CLIENT->ivShow('pluginCageEditWinHash', $cageObj->cageType);

            } else {

                # Built-in cage 'edit' window
                $package = 'Games::Axmud::EditWin::Cage::' . ucfirst($cageObj->cageType);
            }

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                $package,
                $self,
                $self->session,
                'Edit ' . $cageObj->cageType . ' cage \'' . $cageObj->name . '\'',
                $cageObj,
                FALSE,                          # Not temporary
            );

            return 1;
        }
    }

    sub buttonDump_cage {

        # Callback: Displays the list of cages to the 'main' window (equivalent to
        #   ';listcage <switch>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_cage', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Dump the data
        if ($tab eq 'cmd') {
            $self->session->pseudoCmd('listcage -c', $self->pseudoCmdMode);
        } elsif ($tab eq 'trigger') {
            $self->session->pseudoCmd('listcage -t', $self->pseudoCmdMode);
        } elsif ($tab eq 'alias') {
            $self->session->pseudoCmd('listcage -a', $self->pseudoCmdMode);
        } elsif ($tab eq 'macro') {
            $self->session->pseudoCmd('listcage -m', $self->pseudoCmdMode);
        } elsif ($tab eq 'timer') {
            $self->session->pseudoCmd('listcage -i', $self->pseudoCmdMode);
        } elsif ($tab eq 'hook') {
            $self->session->pseudoCmd('listcage -h', $self->pseudoCmdMode);
        } elsif ($tab eq 'route') {
            $self->session->pseudoCmd('listcage -r', $self->pseudoCmdMode);
        } else {

            # Non-standard cages - list them all together
            $self->session->pseudoCmd('listcage -x', $self->pseudoCmdMode);
        }

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDumpAll_cage {

        # Callback: Displays a list of all cages to the 'main' window (equivalent to
        #   ';listcage')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $standard, $package);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDumpAll_cage', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Dump the data
        $self->session->pseudoCmd('listcage', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    # Dictionary button callbacks

    sub buttonAdd_dict {

        # Callback: Adds a dictionary (equivalent to ';adddictionary')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if a temporary dictionary object can't be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $dictObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_dict', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new dictionary
        $slWidget->get_selection->unselect_all();

        # Create a temporary dictionary
        $dictObj = Games::Axmud::Obj::Dict->new($self->session, '<temp>', 'English', TRUE);
        if (! $dictObj) {

            # Can't edit anything
            return undef;

        } else {

            # Open up an 'edit' window to create the new object, replacing the temporary one we've
            #   just created
            $self->createFreeWin(
                'Games::Axmud::EditWin::Dict',
                $self,
                $self->session,
                'Edit dictionary \'' . $dictObj->name . '\'',
                $dictObj,
                TRUE,           # Temporary object
            );
        }

        return 1;
    }

    sub buttonEdit_dict {

        # Callback: Edits a dictionary (equivalent to ';editdictionary')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $dictName, $dictObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_dict', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The dictionary name is the second item of data
        $dictName = $dataList[1];
        if (! $dictName) {

            # Can't continue
            return undef;
        }

        # Get the dictionary itself
        $dictObj = $axmud::CLIENT->ivShow('dictHash', $dictName);
        if (! $dictObj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Dict',
                $self,
                $self->session,
                'Edit dictionary \'' . $dictName . '\'',
                $dictObj,
                FALSE,                  # Not temporary
            );

            return 1;
        }
    }

    sub buttonSet_dict {

        # Callback: Sets the current dictionary (equivalent to ';setdictionary')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $dictName, $dictObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonSet_dict', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The dictionary name is the second item of data
        $dictName = $dataList[1];
        if (! $dictName) {

            # Can't continue
            return undef;
        }

        # Get the dictionary itself
        $dictObj = $axmud::CLIENT->ivShow('dictHash', $dictName);
        if (! $dictObj) {

            # Can't continue
            return undef;
        }

        # Set the dictionary
        $self->session->pseudoCmd('setdictionary ' . $dictName, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonClone_dict {

        # Callback: Clones the selected dictionary (equivalent to ';clonedictionary')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $dictName, $dictObj, $cloneName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonClone_dict', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The dictionary name is the second item of data
        $dictName = $dataList[1];
        if (! $dictName) {

            # Can't continue
            return undef;
        }

        # Get the dictionary itself
        $dictObj = $axmud::CLIENT->ivShow('dictHash', $dictName);
        if (! $dictObj) {

            # Can't continue
            return undef;
        }

        # Prompt the user for the name of the clone (max 16 chars)
        $cloneName = $self->showEntryDialogue(
            'Clone dictionary',
            "Enter a name for the clone\n<i>Max 16 chars: A-Z a-z _ 0-9</i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($cloneName) {

            # Clone the dictionary
            $self->session->pseudoCmd(
                'clonedictionary ' . $dictName . ' ' . $cloneName,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonDelete_dict {

        # Callback: Deletes a dictionary (equivalent to ';deletedictionary')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $dictName, $dictObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_dict', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The dictionary name is the second item of data
        $dictName = $dataList[1];
        if (! $dictName) {

            # Can't continue
            return undef;
        }

        # Get the dictionary itself
        $dictObj = $axmud::CLIENT->ivShow('dictHash', $dictName);
        if (! $dictObj) {

            # Can't continue
            return undef;
        }

        # Delete the dictionary
        $self->session->pseudoCmd('deletedictionary ' . $dictName, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_dict {

        # Callback: Displays a list of dictionaries in the 'main' window (equivalent to
        #   ';listdictionary')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $ref);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_dict', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list of dictionaries
        $self->session->pseudoCmd('listdictionary', $self->pseudoCmdMode);

        return 1;
    }

    # Tasklist button callbacks - Available tasks

    sub buttonStart_availableTask {

        # Callback: Starts the selected task (equivalent to ';starttask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonStart_availableTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $taskName = $dataList[1];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            $self->session->pseudoCmd('starttask ' . $taskName, $self->pseudoCmdMode);
        }

        return 1;
    }

    sub buttonStartOptions_availableTask {

        # Callback: Starts the selected task after prompting the user to specify task settings
        #   using a GA::PrefWin::TaskStart window (equivalent to ';starttask <task> <switches>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonStartOptions_availableTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $taskName = $dataList[1];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Open up a task start 'pref' window to specify task settings
            $self->createFreeWin(
                'Games::Axmud::PrefWin::TaskStart',
                $self,
                $self->session,
                '\'' . $taskName . '\' task preferences',
                undef,                                      # No ->editObj
                FALSE,                                      # Not temporary
                # Config
                'type'  => 'current',                       # Current tasklist
                'task_name' => $taskName,
            );
        }

        return 1;
    }

    sub buttonAddInitial_availableTask {

        # Callback: Adds a new task to the global initial tasklist after prompting the user to
        #   specify task settings using a GA::PrefWin::TaskStar window (equivalent to
        #   ';addinitialtask <task> <switches>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonAddInitial_availableTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $taskName = $dataList[1];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Open up a task start 'pref' window to specify task settings
            $self->createFreeWin(
                'Games::Axmud::PrefWin::TaskStart',
                $self,
                $self->session,
                '\'' . $taskName . '\' task preferences',
                undef,                                      # No ->editObj
                FALSE,                                      # Not temporary
                # Config
                'type'  => 'global_initial',                # Global initial tasklist
                'task_name' => $taskName,
            );
        }

        return 1;
    }

    sub buttonAddCustom_availableTask {

        # Callback: Adds a new task to the custom tasklist after prompting the user to specify task
        #   settings using a GA::PrefWin::TaskStar window (equivalent to
        #   ';addcustomtask <task> <name> <switches>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonAddCustom_availableTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $taskName = $dataList[1];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Open up a task start 'pref' window to specify task settings
            $self->createFreeWin(
                'Games::Axmud::PrefWin::TaskStart',
                $self,
                $self->session,
                '\'' . $taskName . '\' task preferences',
                undef,                                      # No ->editObj
                FALSE,                                      # Not temporary
                # Config
                'type'  => 'custom',                        # Custom tasklist
                'task_name' => $taskName,
            );
        }

        return 1;
    }

    sub buttonHalt_availableTask {

        # Callback: Halts gracefully all copies of the selected task (equivalent to
        #   ';halttask <task>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonHalt_availableTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $taskName = $dataList[1];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Halt gracefully all copies of this task
            $self->session->pseudoCmd('halttask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonKill_availableTask {

        # Callback: Kills all copies of the selected task (equivalent to ';killtask <task>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonKill_availableTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $taskName = $dataList[1];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Kill all copies of this task
            $self->session->pseudoCmd('killtask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonPause_availableTask {

        # Callback: Pauses all copies of the selected task (equivalent to ';pausetask <task>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonPause_availableTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $taskName = $dataList[1];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Pause all copies of this task
            $self->session->pseudoCmd('pausetask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonSafeResume_task {

        # Callback: Resumes all tasks safely (equivalent to ';resumetask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonSafeResume_task', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Reumse paused tasks
        $self->session->pseudoCmd('resumetask', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonReset_availableTask {

        # Callback: Resets all copies of the selected task (equivalent to ';resettask <task>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonReset_availableTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $taskName = $dataList[1];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Pause all copies of this task
            $self->session->pseudoCmd('resettask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonHelp_availableTask {

        # Callback: Shows help for the selected task (equivalent to ';taskhelp <task>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonHelp_availableTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $taskName = $dataList[1];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Pause all copies of this task
            $self->session->pseudoCmd('taskhelp ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    # Tasklist button callbacks - Current tasklist

    sub buttonEdit_task {

        # Callback: Edits the selected task (equivalent to ';edittask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName, $taskObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_task', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The unique task name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;
        }

        # Get the task reference itself
        $taskObj = $self->session->ivShow('currentTaskHash', $taskName);
        if (! $taskObj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Task',
                $self,
                $self->session,
                'Edit ' . $taskObj->prettyName . ' task',
                $taskObj,
                FALSE,                          # Not temporary
                # Config
                'edit_flag' => FALSE,           # Some IVs for current tasks not editable
            );

            return 1;
        }
    }

    sub buttonHalt_task {

        # Callback: Halts the selected task gracefully (equivalent to ';halttask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonHalt_task', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The unique task name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Halt the task
            $self->session->pseudoCmd('halttask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonHaltAll_task {

        # Callback: Halts all tasks gracefully (equivalent to ';halttask -a')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonHaltAll_task', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Halt all tasks
        $self->session->pseudoCmd('halttask -a', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonKill_task {

        # Callback: Kills the selected task immediately (equivalent to ';killtask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonKill_task', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The unique task name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Kill the task
            $self->session->pseudoCmd('killtask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonKillAll_task {

        # Callback: Kills all tasks immediately (equivalent to ';killtask -a')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonKillAll_task', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Halt all tasks
        $self->session->pseudoCmd('killtask -a', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonPause_task {

        # Callback: Pauses the selected task (equivalent to ';pausetask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonPause_task', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The unique task name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Pause the task
            $self->session->pseudoCmd('pausetask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonPauseAll_task {

        # Callback: Pauses all tasks (equivalent to ';pausetask -a')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $ref);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonPauseAll_task', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Pause all tasks
        $self->session->pseudoCmd('pausetask -a', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonReset_task {

        # Callback: Resets the selected task (equivalent to ';resettask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonReset_task', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The unique task name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Reset the task
            $self->session->pseudoCmd('resettask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonResetAll_task {

        # Callback: Resets all tasks (equivalent to ';resettask -a')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonResetAll_task', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Halt all tasks
        $self->session->pseudoCmd('resettask -a', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonFreezeAll_task {

        # Callback: Freezes (or unfreezes) all tasks immediately (equivalent to ';freezetask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonFreezeAll_task', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Freeze/unfreeze all tasks
        $self->session->pseudoCmd('freezetask', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_task {

        # Callback: Displays the list of running tasks in the 'main' window (equivalent to
        #   ';listtask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_task', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display list of tasks
        $self->session->pseudoCmd('listtask', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    # Tasklist button callbacks - Global initial tasklist

    sub buttonEdit_initialTask {

        # Callback: Edit a task from the global initial tasklist (equivalent to ';editinitialtask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName, $taskObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_initialTask', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The initial task name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;
        }

        # Get the task reference itself
        $taskObj = $axmud::CLIENT->ivShow('initTaskHash', $taskName);
        if (! $taskObj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Task',
                $self,
                $self->session,
                'Edit ' . $taskObj->prettyName . ' task',
                $taskObj,
                FALSE,                          # Not temporary
                # Config
                'edit_flag' => TRUE,            # Some IVs for initial tasks are editable
            );

            return 1;
        }
    }

    sub buttonMoveUp_initialTask {

        # Callback: Moves a global initial task up in the ordered list (no equivalent client
        #   command)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $index, $taskName,
            @taskList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonMoveUp_initialTask',
                @_,
            );
        }

        # Import the ordered list of global initial tasks
        @taskList = $axmud::CLIENT->initTaskOrderList;

        # Import the GA::Gtk::Simple::List and find the currently selected line and the data it
        #   contains
        ($index, $taskName) = $self->initialTaskData();
        if (! defined $index) {

            return undef;
        }

        # $index must be at least 2nd in the list (element 1), else it can't be moved up
        if ($index) {

            # Move the item up the ordered list
            splice(@taskList, $index, 1);
            splice(@taskList, ($index - 1), 0, $taskName);

            # Update the client IV
            $axmud::CLIENT->set_initTaskOrderList(@taskList);
            # Update the notebook (the single argument makes sure the same item is selected)
            $self->updateNotebook($index - 1);
        }

        return 1;
    }

    sub buttonMoveDown_initialTask {

        # Callback: Moves a global initial task down in the ordered list (no equivalent client
        #   command)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected or if the selected item can't be
        #       moved down
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $index, $taskName,
            @taskList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonMoveDown_initialTask',
                @_,
            );
        }

        # Import the ordered list of global initial tasks
        @taskList = $axmud::CLIENT->initTaskOrderList;

        # Import the GA::Gtk::Simple::List and find the currently selected line and the data it
        #   contains
        ($index, $taskName) = $self->initialTaskData();
        if (! defined $index) {

            return undef;
        }

        # $index must not be last in the list, else it can't be moved down
        if ($taskList[-1] ne $taskName) {

            # Move the item down the ordered list
            splice(@taskList, $index, 1);
            splice(@taskList, ($index + 1), 0, $taskName);

            # Update the client IV
            $axmud::CLIENT->set_initTaskOrderList(@taskList);
            # Update the notebook (the single argument makes sure the same item is selected)
            $self->updateNotebook($index + 1);
        }

        return 1;
    }

    sub buttonDelete_initialTask {

        # Callback: Delete a task from the global initial tasklist (equivalent to
        #   ';deleteinitialtask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDelete_initialTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The initial task name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Delete the initial task
            $self->session->pseudoCmd('deleteinitialtask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();

            return 1;
        }
    }

    sub buttonDeleteAll_initialTask {

        # Callback: Delete all tasks from the global initial tasklist (equivalent to
        #   ';deleteinitialtask -a')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDeleteAll_initialTask',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Delete all initial tasks
        $self->session->pseudoCmd('deleteinitialtask -a', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_initialTask {

        # Callback: Display list of initial tasks to the 'main' window (equivalent to
        #   ';listinitialtask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_initialTask', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display initial tasks
        $self->session->pseudoCmd('listinitialtask', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    # Tasklist button callbacks - Custom tasklist

    sub buttonStart_customTask {

        # Callback: Starts a task from the custom tasklist (equivalent to ';startcustomtask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonStart_customTask', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The custom task's name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Start the task
            $self->session->pseudoCmd('startcustomtask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();

            return 1;
        }
    }

    sub buttonEdit_customTask {

        # Callback: Edit a task from the custom tasklist (equivalent to ';editcustomtask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName, $taskObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_customTask', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The custom task's name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;
        }

        # Get the task object itself
        $taskObj = $axmud::CLIENT->ivShow('customTaskHash', $taskName);
        if (! $taskObj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Task',
                $self,
                $self->session,
                'Edit ' . $taskObj->prettyName . ' task',
                $taskObj,
                FALSE,                          # Not temporary
                # Config
                'edit_flag' => TRUE,            # Some IVs for custom tasks are editable
            );

            return 1;
        }
    }

    sub buttonDelete_customTask {

        # Callback: Delete a task from the custom tasklist (equivalent to ';deletecustomtask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDelete_customTask',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The custom task's name is the first item of data
        $taskName = $dataList[0];
        if (! $taskName) {

            # Can't continue
            return undef;

        } else {

            # Delete the task
            $self->session->pseudoCmd('deletecustomtask ' . $taskName, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();

            return 1;
        }
    }

    sub buttonDeleteAll_customTask {

        # Callback: Delete all tasks from the custom tasklist (equivalent to ';deletecustomtask -a')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDeleteAll_customTask',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Delete all custom tasks
        $self->session->pseudoCmd('deletecustomtask -a', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_customTask {

        # Callback: Display list of custom tasks in the 'main' window (equivalent to
        #   ';listcustomtask')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $ref);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_customTask', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Dump custom tasks
        $self->session->pseudoCmd('listcustomtask', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    # Tasklist button callbacks - Task packages

    sub buttonAdd_taskPackage {

        # Callback: Add a task package name (equivalent to ';addtaskpackage')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $standard, $package);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_taskPackage', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're starting a new task package name
        $slWidget->get_selection->unselect_all();

        ($standard, $package) = $self->showDoubleEntryDialogue(
            'Add task package name',
            'Standard task name',
            'Task package name',
        );

        if (defined $standard && defined $package) {

            $self->session->pseudoCmd(
                'addtaskpackage ' . $standard . ' ' . $package,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        };

        return 1;
    }

    sub buttonEdit_taskPackage {

        # Callback: Edits a task package name (no client command equivalent)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       item no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $standard, $package,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_taskPackage', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $standard = $dataList[1];
        if (! $standard) {

            # Can't continue
            return undef;
        }

        # Prompt for a new package name
        $package = $self->showEntryDialogue(
            'Edit task package name',
            'Enter a task package name for \'' . $standard . '\'',
            undef,          # No max chars
        );

        if (defined $package) {

            $self->session->pseudoCmd(
                'addtaskpackage ' . $standard . ' ' . $package,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        };

        return 1;
    }

    sub buttonDelete_taskPackage {

        # Callback: Deletes a task package name (equivalent to ';deletetaskpackage')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       item no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $standard,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDelete_taskPackage',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $standard = $dataList[1];
        if (! $standard) {

            # Can't continue
            return undef;

        } else {

            # Delete the task package
            $self->session->pseudoCmd('deletetaskpackage ' . $standard, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        };

        return 1;
    }

    sub buttonReset_taskPackage {

        # Callback: Reset a task package name to its default (equivalent to
        #   ';resettaskpackage <name>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the user
        #       declines to continue the operation
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $standard, $result,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonReset_taskPackage',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The standard task name is the second item of data
        $standard = $dataList[1];
        if (! $standard) {

            # Can't continue
            return undef;
        }

        # If it's not one of the built-in tasks, we need to show a warning message
        if (! $axmud::CLIENT->ivExists('constTaskPackageHash', $standard)) {

            $result = $self->showMsgDialogue(
                'Reset task package name',
                'warning',
                'The task \'' . $standard . '\' isn\'t a built-in task, so resetting its package'
                . ' name will cause it to disappear from this list. You won\'t be able to run the'
                . ' task until you enter a new package name for it. Continue?',
                'yes-no',
            );

            if ($result ne 'yes') {

                return undef;
            }
        }

        # Reset the task package
        $self->session->pseudoCmd('resettaskpackage ' . $standard, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonResetAll_taskPackage {

        # Callback: Resets all task package names to default (equivalent to
        #   ';resettaskpackage')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the user declines to continue the operation
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $result, $count, $text);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonResetAll_taskPackage',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Count the number of tasks which aren't built-in tasks, but which have package names
        $count = 0;
        foreach my $taskName ($axmud::CLIENT->ivKeys('taskPackageHash')) {

            if (! $axmud::CLIENT->ivExists('constTaskPackageHash', $taskName)) {

                $count++;
            }
        }

        if ($count) {

            if ($count == 1) {

                $text = 'This list contains 1 task which isn\'t a built-in task. Resetting all'
                    . ' task package names will cause this task to disappear from the list.'
                    . ' You won\'t be able to run it until you enter a new package name'
                    . ' for it. Continue?';

            } else {

                $text = 'This list contains ' . $count . ' tasks which aren\'t built-in tasks.'
                    . ' Resetting all package names will cause these tasks to disappear from the'
                    . ' list. You won\'t be able to run them until you enter new package names for'
                    . ' them. Continue?';
            }

            $result = $self->showMsgDialogue(
                'Reset task package name',
                'warning',
                $text,
                'yes-no',
            );

            if ($result ne 'yes') {

                return undef;
            }
        }

        # Reset all task packages
        $self->session->pseudoCmd('resettaskpackage', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_taskPackage {

        # Callback: Displays the list of task package names in the 'main' window (equivalent to
        #   ';listtaskpackage')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $standard, $package);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonHaltAll_task', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Dump the data
        $self->session->pseudoCmd('listtaskpackage -d', $self->pseudoCmdMode);
        $self->session->pseudoCmd('listtaskpackage', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    # Tasklist button callbacks - Task labels

    sub buttonAdd_taskLabel {

        # Callback: Adds a task label (equivalent to ';addtasklabel')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $slWidget, $label, $standard,
            @comboList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_taskLabel', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Get a sorted list of standard task names
        @comboList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('taskPackageHash'));

        # Prompt the user for a label
        ($label, $standard) = $self->showEntryComboDialogue(
            'Add task label',
            'Task label',
            'Standard task name',
            \@comboList,
        );

        if (defined $label && defined $standard) {

            $self->session->pseudoCmd(
                'addtasklabel ' . $standard . ' ' . $label,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        };

        return 1;
    }

    sub buttonDelete_taskLabel {

        # Callback: Delete a task label (equivalent to ';deletetasklabel')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $label,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_taskLabel', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The label is the second item of data
        $label = $dataList[1];
        if (! $label) {

            # Can't continue
            return undef;

        } else {

            # Delete the label
            $self->session->pseudoCmd('deletetasklabel ' . $label, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        };

        return 1;
    }

    sub buttonEmpty_taskLabel {

        # Callback: Empty task labels attached to a particular task (equivalent to
        #   ';addtasklabel <name>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the user declines to continue the operation
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $slWidget, $standard,
            @comboList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEmpty_taskLabel', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Get a sorted list of standard task names
        @comboList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('taskPackageHash'));

        # Prompt the user to choose a task
        $standard = $self->showComboDialogue(
            'Empty labels',
            'Select the task which should have all its labels emptied',
            FALSE,
            \@comboList,
        );

        if ($standard) {

            $self->session->pseudoCmd('addtasklabel ' . $standard, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        };

        return 1;
    }

    sub buttonReset_taskLabel {

        # Callback: Reset task labels attached to a particular task (equivalent to
        #   ';resettasklabel <name>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $slWidget, $standard,
            @comboList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonReset_taskLabel', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Get a sorted list of standard task names
        @comboList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('taskPackageHash'));

        # Prompt the user to choose a task
        $standard = $self->showComboDialogue(
            'Reset labels',
            'Select the task which should have all its labels reset',
            FALSE,
            \@comboList,
        );

        if ($standard) {

            $self->session->pseudoCmd('resettasklabel ' . $standard, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        };

        return 1;
    }

    sub buttonResetAll_taskLabel {

        # Callback: Resets all task labels to defaults (equivalent to ';resettasklabel')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonResetAll_taskLabel',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Reset all task labels
        $self->session->pseudoCmd('resettasklabel', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_taskLabel {

        # Callback: Displays the list of task labels in the 'main' window (equivalent to
        #   ';listtasklabel')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_taskLabel', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Dump the data
        $self->session->pseudoCmd('listtasklabel -b', $self->pseudoCmdMode);
        $self->session->pseudoCmd('listtasklabel', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    # Interfaces and interface model callbacks

    sub buttonEdit_activeInterface {

        # Callback: Edits an active interface (equivalent to ';editactiveinterface')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $interfaceNum, $interfaceObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonEdit_activeInterface',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The interface's number is the first item of data
        $interfaceNum = $dataList[0];
        if (! $interfaceNum) {

            # Can't continue
            return undef;
        }

        # Get the interface object itself
        $interfaceObj = $self->session->ivShow('interfaceNumHash', $interfaceNum);
        if (! $interfaceObj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Interface::Active',
                $self,
                $self->session,
                'Edit active ' . $interfaceObj->category . ' interface \'' . $interfaceObj->name
                . '\'',
                $interfaceObj,
                FALSE,                          # Not temporary
            );

            return 1;
        }
    }

    sub buttonDump_activeInterface {

        # Callback: Displays the list of active interfaces to the 'main' window (equivalent to
        #   ';listactiveinterface' <switch>)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDump_activeInterface',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Dump the data
        if ($tab eq 'All') {

            $self->session->pseudoCmd('listactiveinterface -n', $self->pseudoCmdMode);

        } elsif ($tab eq 'Dependent') {

            $self->session->pseudoCmd('listactiveinterface -d', $self->pseudoCmdMode);

        } elsif ($tab eq 'Independent') {

            $self->session->pseudoCmd('listactiveinterface -i', $self->pseudoCmdMode);

        } else {

            # Trigger, Alias (etc) tabs
            $self->session->pseudoCmd('listactiveinterface -c ' . lc($tab), $self->pseudoCmdMode);
        }

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonView_interfaceModel {

        # Callback: Views an interface model object (equivalent to ';editinterfacemodel')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $interfaceModelName, $interfaceModelObj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonView_interfaceModel',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The interface model's name is the first item of data
        $interfaceModelName = $dataList[0];
        if (! $interfaceModelName) {

            # Can't continue
            return undef;
        }

        # Get the interface model object itself
        $interfaceModelObj = $axmud::CLIENT->ivShow('interfaceModelHash', $interfaceModelName);
        if (! $interfaceModelObj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::InterfaceModel',
                $self,
                $self->session,
                'Edit ' . $interfaceModelObj->category . ' interface model',
                $interfaceModelObj,
                FALSE,                          # Not temporary
            );

            return 1;
        }
    }

    sub buttonDump_interfaceModel {

        # Callback: Displays the list of interface models to the 'main' window (equivalent to
        #   ';listinterfacemodel' <switch>)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDump_interfaceModel',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Dump the data
        $self->session->pseudoCmd('listinterfacemodel', $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    # World model callbacks

    sub buttonAdd_model {

        # Callback: Adds a world model object (equivalent to ';addmodelobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $slWidget, $objName, $objParent, $string,
            %switchHash, %typeHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_model', @_);
        }

        # Compile a quick hash of switches accepted by ;addmodelobject
        %switchHash = (
            'Weapons'           => '-w',
            'Armours'           => '-a',
            'Garments'          => '-g',
            'Characters'        => '-c',
            'Minions'           => '-m',
            'Sentients'         => '-s',
            'Creatures'         => '-k',
            'Portables'         => '-p',
            'Decorations'       => '-d',
            'Custom'            => '-u',
        );

        # Also a hash to convert the tab name to the type of model object
        %typeHash = (
            'Weapons'           => 'weapon',
            'Armours'           => 'armour',
            'Garments'          => 'garment',
            'Characters'        => 'char',
            'Minions'           => 'minion',
            'Sentients'         => 'sentient',
            'Creatures'         => 'creature',
            'Portables'         => 'portable',
            'Decorations'       => 'decoration',
            'Custom'            => 'custom',
        );

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new model object
        $slWidget->get_selection->unselect_all();

        # Prompt to get a name for the object
        ($objName, $objParent) = $self->showDoubleEntryDialogue(
            'Add \'' . $typeHash{$tab} . '\' model object',
            'Object name',
            'Parent # (optional)',
        );

        if ($objName) {

            if ($objParent) {
                $string = '<' . $objName . '> ' . $objParent;
            } else {
                $string = '<' . $objName . '>';
            }

            # Add the new world model object
            $self->session->pseudoCmd(
                'addmodelobject ' . $switchHash{$tab} . ' ' . $string,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonAddRegion_model {

        # Callback: Adds a region model object (equivalent to ';addregion')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $slWidget, $objName, $objParent, $string,
            %switchHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAddRegion_model', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new model object
        $slWidget->get_selection->unselect_all();

        # Prompt to get a name for the object
        ($objName, $objParent) = $self->showDoubleEntryDialogue(
            'Add region model object',
            'Region name',
            'Parent region name (optional)',
        );

        if ($objName) {

            if ($objParent) {
                $string = '<' . $objName . '> ' . $objParent;
            } else {
                $string = '<' . $objName . '>';
            }

            # Add the new region model object
            $self->session->pseudoCmd(
                'addregion ' . $string,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonAddChar_model {

        # Callback: Adds a character model object (equivalent to ';addplayercharacter')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $slWidget, $objName, $objParent, $string,
            %switchHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAddChar_model', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new model object
        $slWidget->get_selection->unselect_all();

        # Prompt to get a name for the object
        ($objName, $objParent) = $self->showDoubleEntryDialogue(
            'Add character model object',
            'Character name',
            'Parent object # (optional)',
            16,                 # Max length 16 characters, to match profile name maximum
        );

        if ($objName) {

            if ($objParent) {
                $string = '<' . $objName . '> ' . $objParent;
            } else {
                $string = '<' . $objName . '>';
            }

            # Add the new region model object
            $self->session->pseudoCmd(
                'addplayercharacter ' . $string,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonAddTempRegion_model {

        # Callback: Adds a temporary region model object (equivalent to ';addregion -t')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $tab, $slWidget, $objName, $objParent, $string,
            %switchHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonAddTempRegion_model',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new model object
        $slWidget->get_selection->unselect_all();

        # Prompt to get a name for the object
        ($objName, $objParent) = $self->showDoubleEntryDialogue(
            'Add temporary region model object',
            'Region name',
            'Parent region name (optional)',
        );

        if ($objName) {

            if ($objParent) {
                $string = '<' . $objName . '> <' . $objParent . '>';
            } else {
                $string = '<' . $objName . '>';
            }

            # Add the new region model object
            $self->session->pseudoCmd(
                'addregion ' . $string . ' -t',
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonEdit_model {

        # Callback: Edits a world model object (equivalent to ';editmodelobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number, $obj, $package,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_model', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The world model object's unique number is the first item of data
        $number = $dataList[0];
        if (! $number) {

            # Can't continue
            return undef;
        }

        # Get the world model object itself
        $obj = $self->session->worldModelObj->ivShow('modelHash', $number);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            $package = 'Games::Axmud::EditWin::ModelObj::' . ucfirst($obj->category);

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::ModelObj::' . ucfirst($obj->category),
                $self,
                $self->session,
               'Edit ' . $obj->category . ' model object #' . $obj->number,
                $obj,
                FALSE,
            );
        }

        return 1;
    }

    sub buttonEdit_worldModel {

        # Callback: Edits a world model object (equivalent to ';editmodel')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_worldModel', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new model object
        $slWidget->get_selection->unselect_all();

        # Open up an 'edit' window to edit the world model
        $self->createFreeWin(
            'Games::Axmud::EditWin::WorldModel',
            $self,
            $self->session,
            'Edit world model',
            $self->session->worldModelObj,
            FALSE,
        );

        return 1;
    }

    sub buttonEdit_regionmap {

        # Callback: Edits a regionmap corresponding to the selected world model object (equivalent
        #   to ';editregionmap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_regionmap', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The regionmap's name is the third item of data
        $name = $dataList[2];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Get the regionmap object itself
        $obj = $self->session->worldModelObj->ivShow('regionmapHash', $name);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Regionmap',
                $self,
                $self->session,
                'Edit regionmap \'' . $obj->name . '\'',
                $obj,
                FALSE,
            );
        }

        return 1;
    }

    sub buttonDelete_model {

        # Callback: Deletes a world model object (equivalent to ';deletemodelobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_model', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The model object number is the first item of data
        $number = $dataList[0];
        if (! $number) {

            # Can't continue
            return undef;
        }

        # Delete the world model object
        $self->session->pseudoCmd('deletemodelobject ' . $number, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDeleteRegion_model {

        # Callback: Deletes a region model object (equivalent to ';deleteregion')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDeleteRegion_model',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The model object number is the first item of data
        $number = $dataList[0];
        if (! $number) {

            # Can't continue
            return undef;
        }

        # Delete the region model object
        $self->session->pseudoCmd('deleteregion ' . $number, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDeleteRoom_model {

        # Callback: Deletes a room model object (equivalent to ';deleteroom')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDeleteRoom_model', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The model object number is the first item of data
        $number = $dataList[0];
        if (! $number) {

            # Can't continue
            return undef;
        }

        # Delete the room model object
        $self->session->pseudoCmd('deleteroom ' . $number, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_Model {

        # Callback: Displays a list of world model objects in the 'main' window (equivalent to
        #   ';dumpmodel')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_Model', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list
        $self->session->pseudoCmd('dumpmodel', $self->pseudoCmdMode);

        return 1;
    }

    sub buttonDumpChar_model {

        # Callback: Displays a list of character model objects in the 'main' window (equivalent to
        #   ';listplayercharacter -a')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDumpChar_model', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list
        $self->session->pseudoCmd('listplayercharacter -a', $self->pseudoCmdMode);

        return 1;
    }

    sub buttonAdd_exitModel {

        # Callback: Adds an exit model object (equivalent to ';addexit')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $obj, $objName, $objParent, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_exitModel', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new model object
        $slWidget->get_selection->unselect_all();

        # Prompt to get a name for the object
        ($objName, $objParent) = $self->showDoubleEntryDialogue(
            'Add exit object',
            'Nominal direction',
            'Parent room #',
            32,     # Max chars for directions
        );

        if ($objName && $objParent) {

            if ($objParent) {
                $string = $objName . ' ' . $objParent;
            } else {
                $string = $objName;
            }

            # Add the new exit model object
            $self->session->pseudoCmd('addexit ' . $string, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonEdit_exitModel {

        # Callback: Edits an exit model object (equivalent to ';editexit')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_exitModel', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The exit model object's unique number is the first item of data
        $number = $dataList[0];
        if (! $number) {

            # Can't continue
            return undef;
        }

        # Get the world model object itself
        $obj = $self->session->worldModelObj->ivShow('exitModelHash', $number);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Exit',
                $self,
                $self->session,
                'Edit exit model object #' . $obj->number,
                $obj,
                FALSE,                          # Not temporary
            );
        }

        return 1;
    }

    sub buttonDelete_exitModel {

        # Callback: Deletes an exit model object (equivalent to ';deleteexit')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_exitModel', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The model object number is the first item of data
        $number = $dataList[0];
        if (! $number) {

            # Can't continue
            return undef;
        }

        # Delete the exit model object
        $self->session->pseudoCmd('deleteexit ' . $number, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_exitModel {

        # Callback: Displays a list of exit model objects in the 'main' window (equivalent to
        #   ';dumpexitmodel')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_exitModel', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list
        $self->session->pseudoCmd('dumpexitmodel', $self->pseudoCmdMode);

        return 1;
    }

    # Buffer callbacks

    sub buttonDump20_displayBuffer {

        # Callback: Display a list of the 20 most recent lines from the display buffer in the
        #   'main' window (equivalent to ';dumpdisplaybuffer <start> <stop>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDump20_displayBuffer',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Don't do anything if no lines have been received
        if ($self->session->displayBufferFirst) {

            # Work out the line numbers
            $stop = $self->session->displayBufferLast;
            $start = $self->session->displayBufferLast - 19;
            if ($start < 1) {

                $start = 1;
            }

            # Display the lines
            $self->session->pseudoCmd(
                'dumpdisplaybuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        }

        return 1;
    }

    sub buttonDumpAll_displayBuffer {

        # Callback: Display a list of all lines from the display buffer in the 'main' window
        #   (equivalent to ';dumpdisplaybuffer <first line> <last line>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDumpAll_displayBuffer',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Don't do anything if no lines have been received
        if ($self->session->displayBufferFirst) {

            # Work out the line numbers
            $stop = $self->session->displayBufferLast;
            $start = $self->session->displayBufferFirst;

            # Display the lines
            $self->session->pseudoCmd(
                'dumpdisplaybuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        }

        return 1;
    }

    sub buttonStatus_displayBuffer {

        # Callback: Display the display buffer's status in the 'main' window (equivalent to
        #   ';displaybuffer')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonStatus_displayBuffer',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the display buffer status
        $self->session->pseudoCmd('displaybuffer', $self->pseudoCmdMode);

        return 1;
    }

    sub buttonView_displayBuffer {

        # Callback: Views the selected display buffer line in an 'edit' window (equivalent to
        #   ';editdisplaybuffer')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonView_displayBuffer',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The line number is the first item of data
        $number = $dataList[0];
        if (! defined $number) {

            # Can't continue
            return undef;
        }

        # Get the corresponding display buffer object
        $obj = $self->session->ivShow('displayBufferHash', $number);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Buffer::Display',
                $self,
                $self->session,
                'Edit display buffer line #' . $number,
                $obj,
                FALSE,                          # Not temporary
            );
        }

        return 1;
    }

    sub buttonTest_displayBuffer {

        # Callback: Tets the selected display buffer line against a pattern supplied by the user in
        #   a 'dialogue' window (no corresponding client command)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number, $obj, $pattern, $msg, $type,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonTest_displayBuffer',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The line number is the first item of data
        $number = $dataList[0];
        if (! defined $number) {

            # Can't continue
            return undef;
        }

        # Get the corresponding display buffer object
        $obj = $self->session->ivShow('displayBufferHash', $number);
        if (! $obj) {

            # Can't continue
            return undef;
        }

        # Prompt the user for a regex
        $pattern = $self->showEntryDialogue(
            'Test original line',
            'Enter a pattern (regex) to test against line #' . $number,
            undef,              # No max chars
        );

        if ($pattern) {

            if ($axmud::CLIENT->regexCheck($pattern)) {

                $msg = 'Invalid pattern (regular expression)';
                $type = 'error';

            } elsif ($obj->stripLine =~ m/$pattern/) {

                $msg = 'Pattern MATCHES line #' . $number;
                $type = 'info';

            } else {

                $msg = 'Pattern does NOT match line #' . $number;
                $type = 'error';
            }

            # Display the result
            $self->showMsgDialogue(
                'Test result',
                $type,
                $msg,
                'ok',
            );
        }

        return 1;
    }

    sub buttonSave_displayBuffer {

        # Callback: Saves the display buffer to file (equivalent to ';savebuffer -t')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonSave_displayBuffer',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Save the display buffer to file
        $self->session->pseudoCmd('savebuffer -d', $self->pseudoCmdMode);

        return 1;
    }

    sub buttonSaveBoth_displayBuffer {

        # Callback: Saves the text and command buffers to file (equivalent to ';savebuffer')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonSaveBoth_displayBuffer',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Save the text and command buffers to file
        $self->session->pseudoCmd('savebuffer', $self->pseudoCmdMode);

        return 1;
    }

    sub buttonDump20_instructBuffer {

        # Callback: Display a list of the 20 most recent lines from the instruction buffer in the
        #   'main' window (equivalent to ';dumpinstructionbuffer <start> <stop>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDump20_instructBuffer',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Don't do anything if no lines have been received
        if ($self->session->instructBufferFirst) {

            # Work out the line numbers
            $stop = $self->session->instructBufferLast;
            $start = $self->session->instructBufferLast - 19;
            if ($start < 1) {

                $start = 1;
            }

            # Display the lines
            $self->session->pseudoCmd(
                'dumpinstructionbuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        }

        return 1;
    }

    sub buttonDumpAll_instructBuffer {

        # Callback: Display a list of all lines from the instruction buffer in the 'main' window
        #   (equivalent to ';dumpcommandbuffer <first line> <last line>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDumpAll_instructBuffer',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Don't do anything if no lines have been received
        if ($self->session->instructBufferFirst) {

            # Work out the line numbers
            $stop = $self->session->instructBufferLast;
            $start = $self->session->instructBufferFirst;

            # Display the lines
            $self->session->pseudoCmd(
                'dumpinstructionbuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        }

        return 1;
    }

    sub buttonStatus_instructBuffer {

        # Callback: Display the instruction buffer's status in the 'main' window (equivalent to
        #   ';cmdbuffer')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonStatus_instructBuffer',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the instruction buffer status
        $self->session->pseudoCmd('instructionbuffer', $self->pseudoCmdMode);

        return 1;
    }

    sub buttonView_instructBuffer {

        # Callback: Views the selected intruction buffer line in an 'edit' window (equivalent to
        #   ';editinstructionbuffer')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonView_instructBuffer',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The line number is the first item of data
        $number = $dataList[0];
        if (! defined $number) {

            # Can't continue
            return undef;
        }

        # Get the corresponding instruction buffer object
        $obj = $self->session->ivShow('instructBufferHash', $number);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to view the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Buffer::Instruct',
                $self,
                $self->session,
                'Edit instruction buffer item #' . $number,
                $obj,
                FALSE,                          # Not temporary
            );
        }

        return 1;
    }

    sub buttonDump20_cmdBuffer {

        # Callback: Display a list of the 20 most recent lines from the command buffer in the
        #   'main' window (equivalent to ';dumpcommandbuffer <start> <stop>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump20_cmdBuffer', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Don't do anything if no lines have been received
        if ($self->session->cmdBufferFirst) {

            # Work out the line numbers
            $stop = $self->session->cmdBufferLast;
            $start = $self->session->cmdBufferLast - 19;
            if ($start < 1) {

                $start = 1;
            }

            # Display the lines
            $self->session->pseudoCmd(
                'dumpcommandbuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        }

        return 1;
    }

    sub buttonDumpAll_cmdBuffer {

        # Callback: Display a list of all lines from the command buffer in the 'main' window
        #   (equivalent to ';dumpcommandbuffer <first line> <last line>')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDumpAll_cmdBuffer',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Don't do anything if no lines have been received
        if ($self->session->cmdBufferFirst) {

            # Work out the line numbers
            $stop = $self->session->cmdBufferLast;
            $start = $self->session->cmdBufferFirst;

            # Display the lines
            $self->session->pseudoCmd(
                'dumpcommandbuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        }

        return 1;
    }

    sub buttonStatus_cmdBuffer {

        # Callback: Display the command buffer's status in the 'main' window (equivalent to
        #   ';cmdbuffer')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonStatus_cmdBuffer', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the command buffer status
        $self->session->pseudoCmd('commandbuffer', $self->pseudoCmdMode);

        return 1;
    }

    sub buttonView_cmdBuffer {

        # Callback: Views the selected command buffer line in an 'edit' window (equivalent to
        #   ';editcommandbuffer')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $number, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonView_cmdBuffer', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The line number is the first item of data
        $number = $dataList[0];
        if (! defined $number) {

            # Can't continue
            return undef;
        }

        # Get the corresponding command buffer object
        $obj = $self->session->ivShow('cmdBufferHash', $number);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to view the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Buffer::Cmd',
                $self,
                $self->session,
                'Edit world command buffer item #' . $number,
                $obj,
                FALSE,                          # Not temporary
            );
        }

        return 1;
    }

    sub buttonSave_cmdBuffer {

        # Callback: Saves the command buffer to file (equivalent to ';savebuffer -c')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $start, $stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonSave_cmdBuffer', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Save the command buffer to file
        $self->session->pseudoCmd('savebuffer -c', $self->pseudoCmdMode);

        return 1;
    }

    # Chat contact button callbacks

    sub buttonAdd_chatContact {

        # Callback: Add a chat contact object (equivalent to ';addcontact')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $name, $ip);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_chatContact', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new chat contact
        $slWidget->get_selection->unselect_all();

        # Prompt the user for the name of the chat contact object
        ($name, $ip) = $self->showDoubleEntryDialogue(
            'Add chat contact',
            "Enter a name for the object\n<i>Max 16 chars: A-Z a-z _ 0-9</i>",
            "Enter the contact's IP address\n<i>e.g. 100.101.102.103</i>",
            16,     # Max chars
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($name && $ip) {

            # Add the new chat contact
            $self->session->pseudoCmd('addcontact ' . $name . ' ' . $ip, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonEdit_chatContact {

        # Callback: Edits a chat contact object (equivalent to ';editcontact')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_chatContact', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The colour scheme's name is the first item of data
        $name = $dataList[0];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Get the chat contact itself
        $obj = $axmud::CLIENT->ivShow('chatContactHash', $name);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::ChatContact',
                $self,
                $self->session,
                'Edit contact \'' . $obj->name . '\'',
                $obj,
                FALSE,                          # Not temporary
            );

            return 1;
        }
    }

    sub buttonDelete_chatContact {

        # Callback: Deletes a chat contact object (equivalent to ';deletecontact')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDelete_chatContact',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The chat contact object name is the first item of data
        $name = $dataList[0];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Delete the chat contact
        $self->session->pseudoCmd('deletecontact ' . $name, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_chatContact {

        # Callback: Displays a list of chat contact objects in the 'main' window (equivalent to
        #   ';listcontact')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_chatContact', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list
        $self->session->pseudoCmd('listcontact', $self->pseudoCmdMode);

        return 1;
    }

    # Colour scheme button callbacks

    sub buttonAdd_colourScheme {

        # Callback: Add a colour scheme object (equivalent to ';addcolourscheme')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $name);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_colourScheme', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new colour scheme
        $slWidget->get_selection->unselect_all();

        # Prompt the user for the name of the colour scheme object
        $name = $self->showEntryDialogue(
            'Add colour scheme',
            "Enter a name for the object\n<i>Max 16 chars: A-Z a-z _ 0-9</i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($name) {

            # Add the new colour scheme
            $self->session->pseudoCmd('addcolourscheme ' . $name, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonEdit_colourScheme {

        # Callback: Edits a colour scheme object (equivalent to ';editcolourscheme')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonEdit_colourScheme',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The colour scheme's name is the second item of data
        $name = $dataList[1];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Get the colour scheme itself
        $obj = $axmud::CLIENT->ivShow('colourSchemeHash', $name);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::ColourScheme',
                $self,
                $self->session,
                'Edit colour scheme \'' . $name . '\'',
                $obj,
                FALSE,                          # Not temporary
            );

            return 1;
        }
    }

    sub buttonDelete_colourScheme {

        # Callback: Deletes a colour scheme object (equivalent to ';deletecolourscheme')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDelete_colourScheme',
                @_,
            );
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The colour scheme object name is the second item of data
        $name = $dataList[1];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Delete the colour scheme
        $self->session->pseudoCmd('deletecolourscheme ' . $name, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_colourScheme {

        # Callback: Displays a list of colour scheme objects in the 'main' window (equivalent to
        #   ';listcolourscheme')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->buttonDump_colourScheme',
                @_,
            );
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list
        $self->session->pseudoCmd('listcolourscheme', $self->pseudoCmdMode);

        return 1;
    }

    # Keycode button callbacks

    sub buttonAdd_keycode {

        # Callback: Add a keycode object (equivalent to ';addkeycodeobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $name);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_keycode', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new keycode object
        $slWidget->get_selection->unselect_all();

        # Prompt the user for the name of the keycode object
        $name = $self->showEntryDialogue(
            'Add keycode object',
            "Enter a name for the object\n<i>Max 16 chars: A-Z a-z _ 0-9</i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($name) {

            # Add the new keycode object
            $self->session->pseudoCmd('addkeycodeobject ' . $name, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonSet_keycode {

        # Callback: Sets the current keycode object (equivalent to ';setkeycodeobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonSet_keycode', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The keycode object name is the third item of data
        $name = $dataList[2];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Set the current keycode object
        $self->session->pseudoCmd('setkeycodeobject ' . $name, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonClone_keycode {

        # Callback: Clones the selected keycode object (equivalent to ';clonekeycodeobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $cloneName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonClone_keycode', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The keycode object name is the third item of data
        $name = $dataList[2];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Prompt the user for the name of the clone
        $cloneName = $self->showEntryDialogue(
            'Clone keycode object',
            "Enter a name for the clone\n<i>Max 16 chars: A-Z a-z _ 0-9 </i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($cloneName) {

            # Clone the keycode object
            $self->session->pseudoCmd(
                'clonekeycodeobject ' . $name . ' ' . $cloneName,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonEdit_keycode {

        # Callback: Edits a keycode object (equivalent to ';editkeycodeobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_keycode', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The keycode object's name is the third item of data
        $name = $dataList[2];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Get the keycode object itself
        $obj = $axmud::CLIENT->ivShow('keycodeObjHash', $name);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Keycode',
                $self,
                $self->session,
                'Edit keycode object \'' . $name . '\'',
                $obj,
                FALSE,                          # Not temporary
            );

            return 1;
        }
    }

    sub buttonReset_keycode {

        # Callback: Resets the selected keycode object (equivalent to ';resetkeycodeobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $cloneName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonReset_keycode', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The keycode object name is the third item of data
        $name = $dataList[2];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Reset the keycode object
        $self->session->pseudoCmd('resetkeycodeobject ' . $name, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDelete_keycode {

        # Callback: Deletes a keycode object (equivalent to ';deletekeycodeobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_keycode', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The keycode object name is the third item of data
        $name = $dataList[2];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Delete the keycode object
        $self->session->pseudoCmd('deletekeycodeobject ' . $name, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_keycode {

        # Callback: Displays a list of keycode objects in the 'main' window (equivalent to
        #   ';listkeycodeobject')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_keycode', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list
        $self->session->pseudoCmd('listkeycodeobject', $self->pseudoCmdMode);

        return 1;
    }

    # TTS configuration button callbacks

    sub buttonAdd_tts {

        # Callback: Add a TTS configuration (equivalent to ';addconfig')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $name, $engine);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_tts', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new TTS configuration
        $slWidget->get_selection->unselect_all();

        # Prompt the user for the name of the TTS configuration and the engine to use
        ($name, $engine) = $self->showEntryComboDialogue(
            'Add TTS configuration',
            "Enter a name for the object\n(Max 16 chars: A-Z a-z _ 0-9)",
            "Select the speech engine",
            [$axmud::CLIENT->constTTSList],
            16,     # Max chars
        );

        if ($name) {

            # Add the new TTS configuration
            $self->session->pseudoCmd('addconfig ' . $name . ' ' . $engine, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonClone_tts {

        # Callback: Clones the selected TTS configuration (equivalent to ';cloneconfig')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $cloneName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonClone_tts', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The keycode object name is the first item of data
        $name = $dataList[0];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Prompt the user for the name of the clone
        $cloneName = $self->showEntryDialogue(
            'Clone TTS configuration',
            "Enter a name for the clone\n<i>Max 16 chars: A-Z a-z _ 0-9 </i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($cloneName) {

            # Clone the TTS configuration
            $self->session->pseudoCmd(
                'cloneconfig ' . $name . ' ' . $cloneName,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonEdit_tts {

        # Callback: Edits a TTS configuration (equivalent to ';editconfig')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_tts', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The TTS configuration's name is the first item of data
        $name = $dataList[0];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Get the TTS configuration itself
        $obj = $axmud::CLIENT->ivShow('ttsObjHash', $name);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::TTS',
                $self,
                $self->session,
                'Edit text-to-speech configuration \'' . $name . '\'',
                $obj,
                FALSE,                          # Not temporary
            );

            return 1;
        }
    }

    sub buttonDelete_tts {

        # Callback: Deletes a TTS configuration (equivalent to ';deleteconfig')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_tts', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The TTS configuration name is the first item of data
        $name = $dataList[0];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Delete the TTS configuration
        $self->session->pseudoCmd('deleteconfig ' . $name, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_tts {

        # Callback: Displays a list of TTS configurations in the 'main' window (equivalent to
        #   ';listconfig')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_tts', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list
        $self->session->pseudoCmd('listconfig', $self->pseudoCmdMode);

        return 1;
    }

    # Winmap button callbacks

    sub buttonAdd_winmap {

        # Callback: Add a winmap (equivalent to ';addwinmap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $name);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_winmap', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new winmap
        $slWidget->get_selection->unselect_all();

        # Prompt the user for the name of the winmap
        $name = $self->showEntryDialogue(
            'Add winmap',
            "Enter a name for the object\n<i>Max 16 chars: A-Z a-z _ 0-9</i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($name) {

            # Add the new winmap
            $self->session->pseudoCmd('addwinmap ' . $name, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonClone_winmap {

        # Callback: Clones the selected winmap (equivalent to ';clonewinmap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $cloneName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonClone_winmap', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The keycode object name is the third item of data
        $name = $dataList[2];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Prompt the user for the name of the clone
        $cloneName = $self->showEntryDialogue(
            'Clone winmap',
            "Enter a name for the clone\n<i>Max 16 chars: A-Z a-z _ 0-9 </i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($cloneName) {

            # Clone the winmap
            $self->session->pseudoCmd(
                'clonewinmap ' . $name . ' ' . $cloneName,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonEdit_winmap {

        # Callback: Edits a winmap (equivalent to ';editwinmap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_winmap', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The winmap's name is the third item of data
        $name = $dataList[2];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Get the winmap itself
        $obj = $axmud::CLIENT->ivShow('winmapHash', $name);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Winmap',
                $self,
                $self->session,
                'Edit winmap \'' . $obj->name . '\'',
                $obj,
                FALSE,                          # Not temporary
            );

            return 1;
        }
    }

    sub buttonDelete_winmap {

        # Callback: Deletes a winmap (equivalent to ';deletewinmap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_winmap', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The winmap name is the third item of data
        $name = $dataList[2];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Delete the winmap
        $self->session->pseudoCmd('deletewinmap ' . $name, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_winmap {

        # Callback: Displays a list of winmaps in the 'main' window (equivalent to ';listwinmap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_winmap', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list
        $self->session->pseudoCmd('listwinmap', $self->pseudoCmdMode);

        return 1;
    }

    # Zonemap button callbacks

    sub buttonAdd_zonemap {

        # Callback: Add a zonemap (equivalent to ';addzonemap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget, $name);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonAdd_zonemap', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list, because we're creating a new zonemap
        $slWidget->get_selection->unselect_all();

        # Prompt the user for the name of the zonemap
        $name = $self->showEntryDialogue(
            'Add zonemap',
            "Enter a name for the object\n<i>Max 16 chars: A-Z a-z _ 0-9</i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($name) {

            # Add the new zonemap
            $self->session->pseudoCmd('addzonemap ' . $name, $self->pseudoCmdMode);

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonClone_zonemap {

        # Callback: Clones the selected zonemap (equivalent to ';clonezonemap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $cloneName,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonClone_zonemap', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The keycode object name is the fourth item of data
        $name = $dataList[3];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Prompt the user for the name of the clone
        $cloneName = $self->showEntryDialogue(
            'Clone zonemap',
            "Enter a name for the clone\n<i>Max 16 chars: A-Z a-z _ 0-9 </i>",
            16,     # Max chars
            undef,
            undef,
            TRUE,   # Don't remove the <i>
        );

        if ($cloneName) {

            # Clone the zonemap
            $self->session->pseudoCmd(
                'clonezonemap ' . $name . ' ' . $cloneName,
                $self->pseudoCmdMode,
            );

            # Update the notebook
            $self->updateNotebook();
        }

        return 1;
    }

    sub buttonEdit_zonemap {

        # Callback: Edits a zonemap (equivalent to ';editzonemap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no line is selected in the notebook or if the selected
        #       object no longer exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name, $obj,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonEdit_zonemap', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The zonemap's name is the fourth item of data
        $name = $dataList[3];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Get the zonemap itself
        $obj = $axmud::CLIENT->ivShow('zonemapHash', $name);
        if (! $obj) {

            # Can't continue
            return undef;

        } else {

            # Open up an 'edit' window to edit the object
            $self->createFreeWin(
                'Games::Axmud::EditWin::Zonemap',
                $self,
                $self->session,
                'Edit zonemap \'' . $obj->name . '\'',
                $obj,
                FALSE,                          # Not temporary
            );

            return 1;
        }
    }

    sub buttonDelete_zonemap {

        # Callback: Deletes a zonemap (equivalent to ';deletezonemap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no line is selected in the notebook
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $name,
            @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDelete_zonemap', @_);
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return undef;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The zonemap name is the fourth item of data
        $name = $dataList[3];
        if (! $name) {

            # Can't continue
            return undef;
        }

        # Delete the zonemap
        $self->session->pseudoCmd('deletezonemap ' . $name, $self->pseudoCmdMode);

        # Update the notebook
        $self->updateNotebook();

        return 1;
    }

    sub buttonDump_zonemap {

        # Callback: Displays a list of zonemaps in the 'main' window (equivalent to ';listzonemap')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tab, $slWidget);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonDump_zonemap', @_);
        }

        # Get the selected tab, and from there the tab's GA::Gtk::Simple::List
        $tab = $self->notebookGetTab();
        $slWidget = $self->ivShow('notebookDataHash', $tab);

        # Unselect everything in the list
        $slWidget->get_selection->unselect_all();

        # Display the list
        $self->session->pseudoCmd('listzonemap', $self->pseudoCmdMode);

        return 1;
    }

    # Callback support functions

    sub profPriorityData {

        # Called by $self->buttonMoveTop_profPriority, $self->buttonMoveUp_profPriority, etc
        # Works out which part of the currrent notebook's GA::Gtk::Simple::List is selected and
        #   accesses the data on the selected row
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments or if no row is selected
        #   Otherwise returns a list containing three arguments:
        #       $count      - The position of the category within the current priority list,
        #                       $self->session->profPriorityList (or 'undef' if the category is not
        #                       in the priority list)
        #       $priority   - The priority of the category on the selected line (1+, or '-' for not
        #                       in the priority list)
        #       $category   - The category on the selected line

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $priority, $category, $count,
            @emptyList, @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->profPriorityData', @_);
            return @emptyList;
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return @emptyList;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The current priority (if any) is the first item of data
        $priority = $dataList[0];
        # The selected category is the second item of data
        $category = $dataList[1];

        # Can't continue if either is unavailable, or if the selected category isn't on the priority
        #   list yet (use the 'give priority' button instead)
        if (! $priority || ! $category) {

            # Can't continue
            return @emptyList;

        } elsif ($priority eq '-') {

            # Category isn't in the current priority list
            return (undef, $priority, $category);
        }

        # Import the priority list; check that $category is somewhere to be found within it
        $count = -1;
        foreach my $item ($self->session->profPriorityList) {

            $count++;

            if ($category eq $item) {

                return ($count, $priority, $category);
            }
        }

        # Category not found (this shouldn't happen unless the IV has been modified, since the
        #   window last updated its simple list)
        return @emptyList;
    }

    sub initialTaskData {

        # Called by $self->buttonMoveUp_initialTask and $self->buttonMoveUp_profPriority
        # Works out which part of the currrent notebook's GA::Gtk::Simple::List is selected and
        #   accesses the data on the selected row
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments or if no row is selected
        #   Otherwise returns a list containing two arguments:
        #       $count      - The position of the category within the current priority list,
        #                       $self->session->profPriorityList (or 'undef' if the category is not
        #                       in the priority list)
        #       $priority   - The priority of the category on the selected line (1+, or '-' for not
        #                       in the priority list)
        #       $category   - The category on the selected line

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataRef, $taskName, $count,
            @emptyList, @list, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->profPriorityData', @_);
            return @emptyList;
        }

        # Import the currently selected portions of the notebook list
        @list = $self->notebookGetSelectedData();
        if (! @list) {

            # Nothing selected
            return @emptyList;
        }

        # @list is a list of references to anonymous lists; each of these anonymous lists contains
        #   a single row of the list
        $dataRef = $list[0];
        @dataList = @$dataRef;
        # The selected initial task is the first item of data
        $taskName = $dataList[0];
        if (! defined $taskName) {

            return @emptyList;
        }

        # Import the ordered list of global initial tasks; check that $taskName is somewhere to be
        #   found within it
        $count = -1;
        foreach my $item ($axmud::CLIENT->initTaskOrderList) {

            $count++;

            if ($taskName eq $item) {

                return ($count, $taskName);
            }
        }

        # Task not found (this shouldn't happen unless the IV has been modified, since the
        #   window last updated its simple list)
        return @emptyList;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub pixbuf
        { $_[0]->{pixbuf} }
    sub hPaned
        { $_[0]->{hPaned} }
    sub treeViewModel
        { $_[0]->{treeViewModel} }
    sub treeView
        { $_[0]->{treeView} }
    sub treeViewScroller
        { $_[0]->{treeViewScroller} }
    sub hPaned2
        { $_[0]->{hPaned2} }
    sub notebook
        { $_[0]->{notebook} }
    sub vBox
        { $_[0]->{vBox} }
    sub buttonList
        { my $self = shift; return @{$self->{buttonList}}; }

    sub leftWidth
        { $_[0]->{leftWidth} }
    sub centreWidth
        { $_[0]->{centreWidth} }
    sub rightWidth
        { $_[0]->{rightWidth} }

    sub notebookMode
        { $_[0]->{notebookMode} }
    sub notebookCurrentHeader
        { $_[0]->{notebookCurrentHeader} }
    sub notebookSelectRef
        { $_[0]->{notebookSelectRef} }

    sub headerHash
        { my $self = shift; return %{$self->{headerHash}}; }

    sub notebookTabList
        { my $self = shift; return @{$self->{notebookTabList}}; }
    sub notebookTabHash
        { my $self = shift; return %{$self->{notebookTabHash}}; }
    sub notebookDataHash
        { my $self = shift; return %{$self->{notebookDataHash}}; }

    sub dummyScriptObj
        { $_[0]->{dummyScriptObj} }
}

# Package must return a true value
1
