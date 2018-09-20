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
# Games::Axmud::WizWin::XXX
# Handles all 'wiz' windows, inheriting from GA::Generic::WizWin

{ package Games::Axmud::WizWin::Setup;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::WizWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Setup 'wiz' window, created by GA::Client->start when Axmud
        #   first runs, to let the user specify some initialisation settings
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
        #   $title          - A string to use as the window title. If 'undef', a generic title is
        #                       used
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'wiz' window; for example, for example,
        #                       GA::PrefWin::TaskStart uses it to specify a task name and type.
        #                       Set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be created
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Local variables
        my (
            @pageList,
            %taskSettingHash,
        );

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # This window must only be opened when GA::Client->start wants to open it
        if (! $axmud::CLIENT->showSetupWizWinFlag || $axmud::CLIENT->sessionCount) {

            return undef;
        }

        # Set the values to use for some standard window IVs
        if (! $title) {

            $title = $axmud::SCRIPT . ' setup wizard';
        }

        # Initial settings for some IVs depends on the system. There is no window tiling on MS
        #   Windows (yet), so reduce the number of tabs in this wizwin, and the number of task
        #   windows that open by default
        if ($^O eq 'MSWin32') {

            @pageList                   = (
                'intro',    # Corresponds to function $self->introPage
                'task',
                'sigil',
                'last',
            );

            %taskSettingHash            = (
                'status_win'            => FALSE,
                'status_gauge'          => TRUE,
                'locator_win'           => FALSE,
            );

        } else {

            @pageList                   = (
                'intro',
                'zonemap',
                'task',
                'sigil',
                'last',
            );

            %taskSettingHash            = (
                'status_win'            => TRUE,
                'status_gauge'          => TRUE,
                'locator_win'           => TRUE,
            );
        }

        # Setup
        my $self = {
            _objName                    => 'wiz_win_' . $number,
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
            winType                     => 'wiz',
            # A name for the window (for 'config' windows, the same as the window type)
            winName                     => 'setup_wiz',
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
            widthPixels                 => $axmud::CLIENT->constFreeWinWidth,
            heightPixels                => $axmud::CLIENT->constFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $title,
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # Standard IVs for 'wiz' windows

            # Widgets

            # A vertical pane, with the main area above, and a button strip below
            scroller                    => undef,       # Gtk2::ScrolledWindow
            hAdjustment                 => undef,       # Gtk2::Adjustment
            vAdjustment                 => undef,       # Gtk2::Adjustment
            table                       => undef,       # Gtk2::Table
            hBox                        => undef,       # Gtk2::HBox
            tooltips                    => undef,       # Gtk2::Tooltips
            nextButton                  => undef,       # Gtk2::Button
            previousButton              => undef,       # Gtk2::Button
            cancelButton                => undef,       # Gtk2::Button

            # The default size of the table on each page
            tableWidth                  => 12,
            tableHeight                 => 32,

            # Three flags that can be set by any page, to prevent one of three buttons from being
            #   made sensitive (temporarily)
            disableNextButtonFlag       => FALSE,
            disablePreviousButtonFlag   => FALSE,
            disableCancelButtonFlag     => FALSE,

            # The names of pages, in order of appearance
            pageList                    => \@pageList,
            # The number of the current page (first page is 0)
            currentPage                 => 0,

            # Two hashes for using the 'Next' / 'Previous' buttons to skip around the pages, rather
            #   than going to the actual next or previous page (as normal)
            # The current page should add an entry to the hash, if necessary; the entry is removed
            #   by ->buttonPrevious or ->buttonNext as soon as either button is clicked
            # Hashes in the form
            #   $hash{current_page_number} = page_number_if_button_clicked
            # NB The first page's number is 0, so the fourth page will be page 3, not page 4
            specialNextButtonHash       => {},
            specialPreviousButtonHash   => {},

            # IVs for this type of 'wiz' window

            # Corresponds to same IV in GA::Client
            shareMainWinFlag            => TRUE,
            # Default zonemap for the first workspace, stored in GA::Client->initWorkspaceHash -
            #   'basic', 'extended', 'widescreen', 'horizontal2', 'vertical2' or, representing
            #   GA::Client->activateGridFlag = TRUE, the value 'none'
            zonemap                     => 'basic',
            # Flag set to TRUE if $self->zonemapPage decides to switch the zonemap to 'widescreen',
            #   so that this happens only once (i.e. if the Previous button is clicked, we don't
            #   want to switch the zonemap back to widescreen a second time)
            widescreenFlag              => FALSE,

            # Initial tasks
            taskInitHash                => {
                'status'                => TRUE,
                'locator'               => TRUE,
                'attack'                => FALSE,
                'compass'               => FALSE,
                'channels'              => FALSE,
                'divert'                => FALSE,
                'inventory'             => FALSE,
                'launch'                => FALSE,
                'notepad'               => FALSE,
            },
            # Initial task settings
            taskSettingHash             => \%taskSettingHash,
            # Instruction sigils
            sigilHash                   => {
                'echo'                  => FALSE,
                'perl'                  => FALSE,
                'script'                => FALSE,
                'multi'                 => FALSE,
                'speed'                 => FALSE,
                'bypass'                => FALSE,
            },
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

#   sub winEnable {}        # Inherited from GA::Generic::WizWin

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

        # Local variables
        my $result;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDestroy', @_);
        }

        # Most of the code is in the generic function
        $result = $self->Games::Axmud::Generic::WizWin::winDestroy();
        if ($result) {

            # Window closed. The Connections window must now be opened
            $axmud::CLIENT->mainWin->quickFreeWin('Games::Axmud::OtherWin::Connect');
        }

        return $result;
    }

#   sub winShowAll {}       # Inherited from GA::Generic::Win

#   sub drawWidgets {}      # Inherited from GA::Generic::WizWin

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub saveChanges {

        # Called by $self->buttonNext when the user clicks the 'Finish' button
        # Saves changes to the current world profile and/or current dictionary, before closing the
        #   window
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
            $zonemapObj,
            @taskList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->saveChanges', @_);
        }

        # Update Client IVs
        if (! $self->shareMainWinFlag) {
            $axmud::CLIENT->set_shareMainWinFlag(FALSE);
        } else {
            $axmud::CLIENT->set_shareMainWinFlag(TRUE);
        }

        if ($self->zonemap eq 'none') {

            $axmud::CLIENT->set_activateGridFlag(TRUE);
            $axmud::CLIENT->desktopObj->defaultWorkspaceObj->disableWorkspaceGrids();
            $axmud::CLIENT->desktopObj->defaultWorkspaceObj->reset_defaultZonemap();

        } else {

            $axmud::CLIENT->ivAdd('initWorkspaceHash', 0, $self->zonemap);
            $zonemapObj = $axmud::CLIENT->ivShow('zonemapHash', $self->zonemap);
            if ($zonemapObj) {

                $axmud::CLIENT->desktopObj->defaultWorkspaceObj->set_defaultZonemap($zonemapObj);
            }
        }

        # Add initial tasks (if any) in a set order
        @taskList = qw(status locator attack compass channels divert inventory launch notepad);
        foreach my $name (@taskList) {

            my $taskObj;

            if ($self->ivShow('taskInitHash', $name)) {

                $taskObj = $axmud::CLIENT->addGlobalInitTask($name . '_task');  # e.g. 'status_task'
                if ($taskObj) {

                    if ($name eq 'status') {

                        if (! $self->ivShow('taskSettingHash', 'status_win')) {
                            $taskObj->set_startWithWinFlag(FALSE);
                        } else {
                            $taskObj->set_startWithWinFlag(TRUE);
                        }

                        if (! $self->ivShow('taskSettingHash', 'status_gauge')) {
                            $taskObj->set_gaugeFlag(FALSE);
                        } else {
                            $taskObj->set_gaugeFlag(TRUE);
                        }

                    } elsif ($name eq 'locator') {

                        if (! $self->ivShow('taskSettingHash', 'locator_win')) {
                            $taskObj->set_startWithWinFlag(FALSE);
                        } else {
                            $taskObj->set_startWithWinFlag(TRUE);
                        }
                    }
                }
            }
        }

        # Enable instruction sigils, in no particular order
        foreach my $sigil ($self->ivKeys('sigilHash')) {

            if ($self->ivShow('sigilHash', $sigil)) {

                $axmud::CLIENT->toggle_sigilFlag($sigil);
            }
        }

        # All changes made. Close the window
        $self->winDestroy();

        return 1;
    }

    # Standard callbacks

    sub buttonCancel {

        # 'Cancel' button callback
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $taskObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonCancel', @_);
        }

        # Close the window
        $self->winDestroy();

        # Do the average user a favour by adding the Status and Locator tasks to the global initial
        #   tasklist, even if they clicked the 'Cancel' button
        # (Of course, if the user closed the window some other way, no initial tasks are added)
        $taskObj = $axmud::CLIENT->addGlobalInitTask('status_task');
        if ($taskObj) {

            $taskObj->set_gaugeFlag(TRUE);
        }

        $axmud::CLIENT->addGlobalInitTask('locator_task');

        return 1;
    }

    # Window pages

    sub introPage {

        # Intro page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my @spacingList;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->introPage', @_);
        }

        # Intro
        $self->addLabel($self->table, '<b>\'Main\' windows (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            "<i>Please take a moment to customise " . $axmud::SCRIPT . ", or click the"
            . " <b>Cancel</b> button to use default settings.</i>",
            1, 12, 1, 2);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/shared.png',
            undef,
            1, 3, 3, 5);

        my ($radioButton, $radioButton2, $group);
        ($group, $radioButton) = $self->addRadioButton(
            $self->table,
            undef,
            undef,
            undef,
            FALSE,
            TRUE,
            4, 5, 3, 4);

        $self->addLabel(
            $self->table,
            "All connections <b>share</b> a single \'main\' window.",
            5, 12, 3, 4);

        $self->addLabel(
            $self->table,
            "<i>This is a good choice if you have a small monitor, or if you often connect\n"
            . "to several worlds at a time. You can click the tabs at the top of each window\n"
            . "to switch between connections.</i>",
            5, 12, 4, 5);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/single.png',
            undef,
            1, 3, 6, 8);

        ($group, $radioButton2) = $self->addRadioButton(
            $self->table,
            undef,
            $group,
            undef,
            FALSE,
            TRUE,
            4, 5, 6, 7);

         $self->addLabel(
            $self->table,
            "All connections have <b>their own</b> \'main\' window.",
            5, 12, 6, 7);

         $self->addLabel(
            $self->table,
            "<i>This is a good choice if you have a large monitor (or several monitors), or\n"
            . "if you rarely connect to more than one world at a time.</i>",
            5, 12, 7, 8);

        # (->signal_connects from above)
        if ($self->shareMainWinFlag) {
            $radioButton->set_active(TRUE);
        } else {
            $radioButton2->set_active(TRUE);
        }

        $radioButton->signal_connect('toggled' => sub {

            if ($radioButton->get_active()) {

                $self->ivPoke('shareMainWinFlag', TRUE);
                $self->ivPoke('zonemap', 'basic');
            }
        });

        $radioButton2->signal_connect('toggled' => sub {

            if ($radioButton2->get_active()) {

                $self->ivPoke('shareMainWinFlag', FALSE);
                $self->ivPoke('zonemap', 'horizontal');
            }
        });

        # Add a few empty labels to get the spacing right
        @spacingList = (5);
        foreach my $row (@spacingList) {

            $self->addLabel($self->table, '',
                1, 12, $row, ($row + 1));
        }

        return 12;
    }

    sub zonemapPage {

        # Zonemap page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my @spacingList;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->zonemapPage', @_);
        }

        # Zonemaps
        $self->addLabel($self->table, '<b>Zonemaps (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            "<i>A zonemap is a plan for arranging windows on the desktop. Select the best zonemap"
            . " for your system.</i>",
            1, 12, 1, 2);

        if ($self->shareMainWinFlag) {

            $self->addSimpleImage(
                $self->table,
                $axmud::SHARE_DIR . '/icons/setup/basic_zonemap.png',
                undef,
                1, 4, 3, 6);

            my ($radioButton, $radioButton2, $radioButton3, $group);
            ($group, $radioButton) = $self->addRadioButton(
                $self->table,
                undef,
                undef,
                'Basic',
                FALSE,
                TRUE,
                4, 6, 4, 5);

            $self->addSimpleImage(
                $self->table,
                $axmud::SHARE_DIR . '/icons/setup/extended_zonemap.png',
                undef,
                7, 10, 3, 5);

            ($group, $radioButton2) = $self->addRadioButton(
                $self->table,
                undef,
                $group,
                'Extended',
                FALSE,
                TRUE,
                10, 12, 4, 5);

            $self->addSimpleImage(
                $self->table,
                $axmud::SHARE_DIR . '/icons/setup/widescreen_zonemap.png',
                undef,
                1, 4, 7, 10);

            ($group, $radioButton3) = $self->addRadioButton(
                $self->table,
                undef,
                $group,
                'Widescreen',
                FALSE,
                TRUE,
                4, 6, 8, 9);

            # (->signal_connects from above)

            # As a convenience for users, auto-set the 'widescreen' zonemap (but only do this once,
            #   otherwise widescreen will be re-selected if the 'Previous' button is clicked
            # Use 1800, rather than 1920, as the test in case there are desktop panels on the
            #   left and/or right sides

            if (
                defined $self->workspaceObj->currentWidth
                && $self->workspaceObj->currentWidth >= 1800
                && ! $self->widescreenFlag
            ) {
                $radioButton3->set_active(TRUE);
                $self->ivPoke('zonemap', 'widescreen');
                $self->ivPoke('widescreenFlag', TRUE);

            } elsif ($self->zonemap eq 'basic') {

                $radioButton->set_active(TRUE);

            } elsif ($self->zonemap eq 'extended') {

                $radioButton2->set_active(TRUE);

            } else {

                $radioButton3->set_active(TRUE);
            }

            $radioButton->signal_connect('toggled' => sub {

                if ($radioButton->get_active()) {

                    $self->ivPoke('zonemap', 'basic');
                }
            });

            $radioButton2->signal_connect('toggled' => sub {

                if ($radioButton2->get_active()) {

                    $self->ivPoke('zonemap', 'extended');
                }
            });

            $radioButton3->signal_connect('toggled' => sub {

                if ($radioButton3->get_active()) {

                    $self->ivPoke('zonemap', 'widescreen');
                }
            });

        } else {

            $self->addSimpleImage(
                $self->table,
                $axmud::SHARE_DIR . '/icons/setup/horizontal_zonemap.png',
                undef,
                1, 4, 3, 6);

            my ($radioButton, $radioButton2, $radioButton3, $group);
            ($group, $radioButton) = $self->addRadioButton(
                $self->table,
                undef,
                $group,
                'Horizontal',
                FALSE,
                TRUE,
                4, 6, 4, 5);

            $self->addSimpleImage(
                $self->table,
                $axmud::SHARE_DIR . '/icons/setup/vertical_zonemap.png',
                undef,
                7, 10, 3, 6);

            ($group, $radioButton2) = $self->addRadioButton(
                $self->table,
                undef,
                $group,
                'Vertical',
                FALSE,
                TRUE,
                10, 12, 4, 5);

            $self->addSimpleImage(
                $self->table,
                $axmud::SHARE_DIR . '/icons/setup/no_zonemap.png',
                undef,
                1, 4, 7, 10);

            ($group, $radioButton3) = $self->addRadioButton(
                $self->table,
                undef,
                $group,
                'No zonemap',
                FALSE,
                TRUE,
                4, 6, 8, 9);

            # (->signal_connects from above)
            if ($self->zonemap eq 'horizontal') {
                $radioButton->set_active(TRUE);
            } elsif ($self->zonemap eq 'vertical') {
                $radioButton2->set_active(TRUE);
            } else {
                $radioButton3->set_active(TRUE);
            }

            $radioButton->signal_connect('toggled' => sub {

                if ($radioButton->get_active()) {

                    $self->ivPoke('zonemap', 'horizontal2');
                }
            });

            $radioButton2->signal_connect('toggled' => sub {

                if ($radioButton2->get_active()) {

                    $self->ivPoke('zonemap', 'vertical2');
                }
            });

            $radioButton3->signal_connect('toggled' => sub {

                if ($radioButton3->get_active()) {

                    $self->ivPoke('zonemap', 'none');
                }
            });
        }

        # Add a few empty labels to get the spacing right
        @spacingList = (
            2,
            6,
            10, 11,
        );

        foreach my $row (@spacingList) {

            $self->addLabel($self->table, '',
                11, 12, $row, ($row + 1));
        }

        return 12;
    }

    sub taskPage {

        # Task page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my (
            $noneFlag,
            @signalList, @signalList2,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->taskPage', @_);
        }

        # Tasks
        $self->addLabel($self->table, '<b>Tasks (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            "<i>Choose which of " . $axmud::SCRIPT . "'s built-in tasks (if any) should start at"
            . " the beginning of every session.</i>",
            1, 10, 1, 2);
        my $button = $self->addButton(
            $self->table,
            undef,
            'Select all', 'Select/deselect all tasks',
            10, 12, 1, 2);

        # Recommended tasks
        $self->addLabel($self->table, '<u>Recommended tasks</u>',
            1, 12, 2, 3);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/status_task.png',
            undef,
            1, 2, 3, 5);

        my $checkButton = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskInitHash', 'status'),
            TRUE,
            2, 6, 3, 4);
        $checkButton->set_label('Status task');
        my $checkButton2 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskSettingHash', 'status_win'),
            TRUE,
            2, 4, 4, 5);
        $checkButton2->set_label('Show task window');
        my $checkButton3 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskSettingHash', 'status_gauge'),
            TRUE,
            4, 6, 4, 5);
        $checkButton3->set_label('Show gauges');

        $self->addLabel(
            $self->table,
            "<i>Tracks information about the character, such as their\n"
            . "health and energy points. It's essential for the gauges\n"
            . "that appear near the bottom of the 'main' window.</i>",
            1, 6, 6, 7);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/locator_task.png',
            undef,
            7, 8, 3, 5);

        my $checkButton4 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskInitHash', 'locator'),
            TRUE,
            8, 12, 3, 4);
        $checkButton4->set_label('Locator task');
        my $checkButton5 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskSettingHash', 'locator_win'),
            TRUE,
            8, 12, 4, 5);
        $checkButton5->set_label('Show task window');

        $self->addLabel(
            $self->table,
            "<i>Tracks the character\'s position in the world. It\'s essential\n"
            . "for the automapper, but neither the Locator nor Status task\n"
            . "windows actually need to be open.</i>",
            7, 12, 6, 7);

        # Optional tasks
        $self->addLabel($self->table, '<u>Optional tasks</u>',
            1, 12, 7, 8);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/attack_task.png',
            undef,
            1, 2, 8, 9);

        my $checkButton6 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskInitHash', 'attack'),
            TRUE,
            2, 6, 8, 9);
        $checkButton6->set_label('Attack task');
        $self->addLabel(
            $self->table,
            "<i>Tracks the character\'s fights and interactions,\n"
            . "updating current profiles as it goes.</i>",
            2, 6, 9, 10);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/compass_task.png',
            undef,
            1, 2, 10, 11);

        my $checkButton7 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskInitHash', 'compass'),
            TRUE,
            2, 6, 10, 11);
        $checkButton7->set_label('Compass task');
        $self->addLabel(
            $self->table,
            "<i>A convenient way to enable and disable keypad\n"
            . "macros for moving around the world.</i>",
            2, 6, 11, 12);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/divert_task.png',
            undef,
            1, 2, 12, 13);

        my $checkButton8 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskInitHash', 'divert'),
            TRUE,
            2, 4, 12, 13);
        $checkButton8->set_label('Channels task, or');
        my $checkButton9 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskInitHash', 'divert'),
            TRUE,
            4, 6, 12, 13);
        $checkButton9->set_label('Divert task');
        $self->addLabel(
            $self->table,
            "<i>Diverts social messages and tells to a separate\n"
            . "task window. Channels tasks have multiple tabs.</i>",
            2, 6, 13, 14);

        # (Right column)
        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/inventory_task.png',
            undef,
            7, 8, 8, 9);

        my $checkButton10 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskInitHash', 'inventory'),
            TRUE,
            8, 12, 8, 9);
        $checkButton10->set_label('Inventory task');
        $self->addLabel(
            $self->table,
            "<i>Keeps track of the character's inventory and\n"
            . "displays a summary in its own task window.</i>",
            8, 12, 9, 10);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/launch_task.png',
            undef,
            7, 8, 10, 11);

        my $checkButton11 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskInitHash', 'launch'),
            TRUE,
            8, 12, 10, 11);
        $checkButton11->set_label('Launch task');
        $self->addLabel(
            $self->table,
            "<i>A convenient method for selecting and running\n"
            . $axmud::BASIC_NAME . " scripts.</i>",
            8, 12, 11, 12);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/notepad_task.png',
            undef,
            7, 8, 12, 13);

        my $checkButton12 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('taskInitHash', 'notepad'),
            TRUE,
            8, 12, 12, 13);
        $checkButton12->set_label('Notepad task');
        $self->addLabel(
            $self->table,
            "<i>Write your notes here. They will be waiting for\n"
            . "you, the next time you connect to the world.</i>",
            8, 12, 13, 14);

        # (->signal_connects from above)
        $button->signal_connect('clicked' => sub {

            if (! $noneFlag) {

                # 'Select all'
                $checkButton->set_active(TRUE);
                $checkButton4->set_active(TRUE);
                $checkButton6->set_active(TRUE);
                $checkButton7->set_active(TRUE);
                $checkButton8->set_active(TRUE);
                $checkButton9->set_active(FALSE);
                $checkButton10->set_active(TRUE);
                $checkButton11->set_active(TRUE);
                $checkButton12->set_active(TRUE);

                # Next button click is 'Select none'
                $button->set_label('Select none');
                $noneFlag = TRUE;

            } else {

                # 'Select none'
                $checkButton->set_active(FALSE);
                $checkButton2->set_active(FALSE);
                $checkButton3->set_active(FALSE);
                $checkButton4->set_active(FALSE);
                $checkButton5->set_active(FALSE);
                $checkButton6->set_active(FALSE);
                $checkButton7->set_active(FALSE);
                $checkButton8->set_active(FALSE);
                $checkButton9->set_active(FALSE);
                $checkButton10->set_active(FALSE);
                $checkButton11->set_active(FALSE);
                $checkButton12->set_active(FALSE);

                # Next button click is 'Select all'
                $button->set_label('Select all');
                $noneFlag = FALSE;
            }
        });

        @signalList = (
            $checkButton    => 'status',
            $checkButton4   => 'locator',
            $checkButton6   => 'attack',
            $checkButton7   => 'compass',
            $checkButton8   => 'channels',
            $checkButton9   => 'divert',
            $checkButton10  => 'inventory',
            $checkButton11  => 'launch',
            $checkButton12  => 'notepad',
        );

        do {

            my ($widget, $key);

            $widget = shift @signalList;
            $key = shift @signalList;

            $widget->signal_connect('toggled' => sub {

                if (! $widget->get_active()) {

                    $self->ivAdd('taskInitHash', $key, FALSE);

                    if ($key eq 'status' && $widget eq $checkButton) {

                        # If no Status task, don't show task window or gauges
                        $checkButton2->set_active(FALSE);
                        $checkButton3->set_active(FALSE);

                    } elsif ($key eq 'locator' && $widget eq $checkButton4) {

                        # If not Locator task, don't show task window
                        $checkButton5->set_active(FALSE);
                    }

                } else {

                    if ($key eq 'channels' && $widget eq $checkButton8) {

                        # If Channels selected, don't select Divert
                        $checkButton9->set_active(FALSE);
                        $self->ivAdd('taskInitHash', 'channels', TRUE);
                        $self->ivAdd('taskInitHash', 'divert', FALSE);

                    } elsif ($key eq 'divert' && $widget eq $checkButton9) {

                        $checkButton8->set_active(FALSE);
                        $self->ivAdd('taskInitHash', 'divert', TRUE);
                        $self->ivAdd('taskInitHash', 'channels', FALSE);

                    } else {

                        $self->ivAdd('taskInitHash', $key, TRUE);
                    }
                }
            });

        } until (! @signalList);

        @signalList2 = (
            $checkButton2   => 'status_win',
            $checkButton3   => 'status_gauge',
            $checkButton5   => 'locator_win',
        );

        do {

            my ($widget, $key);

            $widget = shift @signalList2;
            $key = shift @signalList2;

            $widget->signal_connect('toggled' => sub {

                if (! $widget->get_active()) {
                    $self->ivAdd('taskSettingHash', $key, FALSE);
                } else {
                    $self->ivAdd('taskSettingHash', $key, TRUE);
                }
            });

        } until (! @signalList2);

        return 14;
    }

    sub sigilPage {

        # Sigil page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my (
            $noneFlag,
            @signalList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sigilPage', @_);
        }

        # Commands
        $self->addLabel($self->table, '<b>Commands (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            "<i>Some types of command start with a special character (sigil). Choose which sigils"
            . " to enable.</i>",
            1, 10, 1, 2);
        my $button = $self->addButton(
            $self->table,
            undef,
            'Select all', 'Select/deselect all sigils',
            10, 12, 1, 2);

        # Compulsory sigils
        $self->addLabel($self->table, '<u>Compulsory sigils</u>',
            1, 12, 2, 3);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/client_sigil.png',
            undef,
            1, 2, 3, 4);

        my $checkButton = $self->addCheckButton($self->table, undef, TRUE, FALSE,
            2, 6, 3, 4);
        $checkButton->set_label('Client commands');

        $self->addLabel(
            $self->table,
            "<i>Client commands are processed by " . $axmud::SCRIPT . " directly, not sent\n"
            . "to the world.</i>",
            1, 6, 4, 5);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/forced_sigil.png',
            undef,
            7, 8, 3, 4);

        my $checkButton2 = $self->addCheckButton($self->table, undef, TRUE, FALSE,
            8, 12, 3, 4);
        $checkButton2->set_label('Forced world commands');

        $self->addLabel(
            $self->table,
            "<i>Everything after the commas is sent directly to the world;\n"
            . "useful for world commands beginning with an " . $axmud::SCRIPT . " sigil.</i>",
            7, 12, 4, 5);

        # Optional sigils
        $self->addLabel($self->table, '<u>Optional sigils</u>',
            1, 12, 5, 6);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/echo_sigil.png',
            undef,
            1, 2, 6, 7);

        my $checkButton3 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('sigilHash', 'echo'),
            TRUE,
            2, 6, 6, 7);
        $checkButton3->set_label('Echo commands');
        $self->addLabel(
            $self->table,
            "<i>Everything after the quote is displayed in the\n"
            . "'main' window as a system message.</i>",
            2, 6, 7, 8);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/perl_sigil.png',
            undef,
            1, 2, 8, 9);

        my $checkButton4 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('sigilHash', 'perl'),
            TRUE,
            2, 6, 8, 9);
        $checkButton4->set_label('Perl commands');
        $self->addLabel(
            $self->table,
            "<i>Everything after the forward slash is executed\n"
            . "as a mini-Perl programme.</i>",
            2, 6, 9, 10);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/script_sigil.png',
            undef,
            1, 2, 10, 11);

        my $checkButton5 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('sigilHash', 'script'),
            TRUE,
            2, 6, 10, 11);
        $checkButton5->set_label('Script commands');
        $self->addLabel(
            $self->table,
            "<i>A quick way to run " . $axmud::BASIC_NAME . " scripts. Everything\n"
            . "after the ampersand is the name of the script.</i>",
            2, 6, 11, 12);

        # (Right column)
        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/multi_sigil.png',
            undef,
            7, 8, 6, 7);

        my $checkButton6 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('sigilHash', 'multi'),
            TRUE,
            8, 12, 6, 7);
        $checkButton6->set_label('Multi commands');
        $self->addLabel(
            $self->table,
            "<i>Sends a world command to every session (or every\n"
            . "session connected to the same world.)</i>",
            8, 12, 7, 8);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/speedwalk_sigil.png',
            undef,
            7, 8, 8, 9);

        my $checkButton7 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('sigilHash', 'speed'),
            TRUE,
            8, 12, 8, 9);
        $checkButton7->set_label('Speedwalk commands');
        $self->addLabel(
            $self->table,
            "<i>Speedwalk commands can be simple, e.g. <b>.3n</b>\n"
            . "or complex, e.g. <b>3[close]wO(sw)(sw)</b></i>",
            8, 12, 9, 10);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/bypass_sigil.png',
            undef,
            7, 8, 10, 11);

        my $checkButton8 = $self->addCheckButton(
            $self->table,
            undef,
            $self->ivShow('sigilHash', 'bypass'),
            TRUE,
            8, 12, 10, 11);
        $checkButton8->set_label('Bypass commands');
        $self->addLabel(
            $self->table,
            "<i>Sends a command to the world immediately,\n"
            . "bypassing any queued world commands.</i>",
            8, 12, 11, 12);

        # (->signal_connects from above)
        $button->signal_connect('clicked' => sub {

            if (! $noneFlag) {

                # 'Select all'
                $checkButton3->set_active(TRUE);
                $checkButton4->set_active(TRUE);
                $checkButton5->set_active(TRUE);
                $checkButton6->set_active(TRUE);
                $checkButton7->set_active(TRUE);
                $checkButton8->set_active(TRUE);

                # Next button click is 'Select none'
                $button->set_label('Select none');
                $noneFlag = TRUE;

            } else {

                # 'Select none'
                $checkButton3->set_active(FALSE);
                $checkButton4->set_active(FALSE);
                $checkButton5->set_active(FALSE);
                $checkButton6->set_active(FALSE);
                $checkButton7->set_active(FALSE);
                $checkButton8->set_active(FALSE);

                # Next button click is 'Select all'
                $button->set_label('Select all');
                $noneFlag = FALSE;
            }
        });

        @signalList = (
            $checkButton3   => 'echo',
            $checkButton4   => 'perl',
            $checkButton5   => 'script',
            $checkButton6   => 'multi',
            $checkButton7   => 'speed',
            $checkButton8   => 'bypass',
        );

        do {

            my ($widget, $key);

            $widget = shift @signalList;
            $key = shift @signalList;

            $widget->signal_connect('toggled' => sub {

                if (! $widget->get_active()) {
                    $self->ivAdd('sigilHash', $key, FALSE);
                } else {
                    $self->ivAdd('sigilHash', $key, TRUE);
                }
            });

        } until (! @signalList);

        return 14;
    }

    sub lastPage {

        # Last page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my (@verboseList, @shortList, @briefList);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->lastPage', @_);
        }

        $self->addLabel($self->table, '<b>Finished (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            "<i>" . $axmud::SCRIPT . " isn't like other MUD clients. Click the help icon at any"
            . " time to read about its most important features.</i>",
            1, 12, 1, 2);

        $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/setup/help.png',
            undef,
            1, 12, 2, 11);

        $self->addLabel(
            $self->table,
            "<b>Click the Finish button to get started!</b>",
            1, 12, 11, 12,
            0.5, 0.5);

        return 12;
    }

    # Support functions

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub shareMainWinFlag
        { $_[0]->{shareMainWinFlag} }
    sub zonemap
        { $_[0]->{zonemap} }
    sub widescreenFlag
        { $_[0]->{widescreenFlag} }

    sub taskInitHash
        { my $self = shift; return %{$self->{taskInitHash}}; }
    sub taskSettingHash
        { my $self = shift; return %{$self->{taskSettingHash}}; }
    sub sigilHash
        { my $self = shift; return %{$self->{sigilHash}}; }
}

{ package Games::Axmud::WizWin::Locator;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::WizWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of the Locator 'wiz' window, which assists with setting up world
        #   profile IVs used mostly by the Locator task
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
        #   $title          - A string to use as the window title. If 'undef', a generic title is
        #                       used
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'wiz' window; for example, for example,
        #                       GA::PrefWin::TaskStart uses it to specify a task name and type.
        #                       Set to an empty hash if not required
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

        # Set the values to use for some standard window IVs
        if (! $title) {

            $title = 'Locator wizard';
        }

        # Setup
        my $self = {
            _objName                    => 'wiz_win_' . $number,
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
            winType                     => 'wiz',
            # A name for the window (for 'config' windows, the same as the window type)
            winName                     => 'locator_wiz',
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
            widthPixels                 => $axmud::CLIENT->constFreeWinWidth,
            heightPixels                => $axmud::CLIENT->constFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $title,
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # Standard IVs for 'wiz' windows

            # Widgets

            # A vertical pane, with the main area above, and a button strip below
            scroller                    => undef,       # Gtk2::ScrolledWindow
            hAdjustment                 => undef,       # Gtk2::Adjustment
            vAdjustment                 => undef,       # Gtk2::Adjustment
            table                       => undef,       # Gtk2::Table
            hBox                        => undef,       # Gtk2::HBox
            tooltips                    => undef,       # Gtk2::Tooltips
            nextButton                  => undef,       # Gtk2::Button
            previousButton              => undef,       # Gtk2::Button
            cancelButton                => undef,       # Gtk2::Button

            # The default size of the table on each page
            tableWidth                  => 12,
            tableHeight                 => 32,

            # Three flags that can be set by any page, to prevent one of three buttons from being
            #   made sensitive (temporarily)
            disableNextButtonFlag       => FALSE,
            disablePreviousButtonFlag   => FALSE,
            disableCancelButtonFlag     => FALSE,

            # The names of pages, in order of appearance
            pageList                    => [
                'intro',            # Corresponds to function $self->introPage
                'directions',
                'dictionary',
                'statements',
                'capture',
                'analysis',
                'analysis2',
                'last',
            ],
            # The number of the current page (first page is 0)
            currentPage                 => 0,

            # Two hashes for using the 'Next' / 'Previous' buttons to skip around the pages, rather
            #   than going to the actual next or previous page (as normal)
            # The current page should add an entry to the hash, if necessary; the entry is removed
            #   by ->buttonPrevious or ->buttonNext as soon as either button is clicked
            # Hashes in the form
            #   $hash{current_page_number} = page_number_if_button_clicked
            # NB The first page's number is 0, so the fourth page will be page 3, not page 4
            specialNextButtonHash       => {},
            specialPreviousButtonHash   => {},

            # IVs for this type of 'wiz' window

            # A hash of custom primary directions, in the form
            #   $hash{standard_primary_direction} = custom_primary_direction
            customPrimaryDirHash        => {},         # Set below
            # A hash of custom abbreviated primary directions, in the form
            #   $hash{standard_primary_direction} = custom_primary_abbreviated_direction
            customPrimaryAbbrevHash     => {},         # Set below
            # NB For both these hashes, if the user empties an entry box, the value is set to
            #   'undef' - in that case, the value stored in the current dictionary isn't changed

            # Lists of definite/indefinite articles, to be stored in the current dictionary
            #   (replacing the contents of the same IVs)
            definiteList                => [],
            indefiniteList              => [],
            # List of words for 'and'/'or', to be stored in the current dictionary (replacing the
            #   contents of the same IVs)
            andList                     => [],
            orList                      => [],
            # A list of numbers from 1-10, which replaces key-value pairs in the current
            #   dictionary's ->numberHash
            numberList                  => [],
            # A list of contents markers initially imported from
            #   GA::Profile::World->contentPatternList
            markerList                  => [],

            # Hash to show which of the IVs above have been changed by the user, in the form
            #   $hash{iv} = flag
            # where 'flag' is TRUE if the IV has been changed, FALSE if not
            # $self->updateTextView modifies the hash for a number of IVs, but only the 7 IVs above
            #   are checked at the end of the setup process
            ivChangeHash                => {},

            # Hash of room statement component types. Includes components specified by
            #   GA::Profile::World, as well as one components used by this 'wiz' window only:
            #   'outside_statement'. Hash in the form
            #       $hash{component_type} = short_description
            componentTypeHash           => {
                # Component used by this window only
                'outside_statement'     => 'Line outside the statement',
                # Components specified by GA::Profile::World
#               'anchor'                => 'Line is the anchor line',   # Not required here
                'ignore_line'           => 'Ignore this line',
                'verb_title'            => 'Room title (verbose)',
                'verb_descrip'          => 'Description (verbose)',
                'verb_exit'             => 'Exit list (verbose)',
                'verb_content'          => 'Contents list (verbose)',
                'verb_special'          => 'Special contents list',
                'brief_title'           => 'Room title (brief)',
                'brief_exit'            => 'Exit list (brief)',
                'brief_title_exit'      => 'Room title/exit list (brief)',
                'brief_exit_title'      => 'Exit list/room title (brief)',
                'brief_content'         => 'Contents list (brief)',
#               'mudlib_path'           => 'Path to the mudlib file'    # Not required here
#               'custom'                => 'Custom component',          # Not required here
            },
            # A list of verbose room statement components - a selection of the keys in
            #   $self->componentTypeHash
            verboseComponentList        => [
                'outside_statement',
                'ignore_line',
                'verb_title',
                'verb_descrip',
                'verb_special',
                'verb_exit',
                'verb_content',
            ],
            # A list of short verbose room statement components - a selection of the keys in
            #   $self->componentTypeHash
            shortComponentList          => [
                'outside_statement',
                'ignore_line',
                'verb_title',
                'verb_special',
                'verb_exit',
                'verb_content',
            ],
            # A list of brief room statement components - a selection of the keys in
            #   $self->componentTypeHash
            briefComponentList          => [
                'outside_statement',
                'ignore_line',
                'brief_title',
                'brief_exit',
                'brief_title_exit',
                'brief_exit_title',
                'brief_content',
            ],

            # A list of consecutive GA::Buffer::Display objects for analysis
            bufferObjList               => [],
            # A corresponding list specifying to which type of component each buffer object in
            #   $self->bufferObjList belongs (matches keys in $self->componentTypeHash)
            bufferTypeList              => [],

            # How many analyses have been completed
            analysisCount               => 0,
            # The current analysis is of which type? ('verbose', 'short' or 'brief')
            analysisType                => 'verbose',
            # How many recently-received lines to analyse,, by default
            analysisLength              => 8,
            # The minimum and maximum number of recently-received lines to analyse
            analysisMinLength           => 6,
            analysisMaxLength           => 16,
            # How many lines to increase/decrease this number at a time
            analysisInc                 => 2,
            # A hash containing an analysis of ->bufferObjList, compiled by
            #   $self->collectComponentGroups, in the form
            #   $hash{component_name} = reference_to_list_of_lines
            # ...where 'reference_to_list_of_lines' contains a list of indexes in ->bufferObjList
            #   in the range 0 to ($self->analysisLength - 1)
            analysisHash                => {},

            # After an analysis is complete, the list of new GA::Obj::Component objects created
            #   (the IV used depends on the current value of $self->analysisType)
            verboseComponentObjList     => [],
            shortComponentObjList       => [],
            briefComponentObjList       => [],

            # IVs which are set by various pages, which are transferred directly to the current
            #   world profile when the setup process is complete. A hash in the form
            #   $profUpdateHash{iv} = scalar
            #   $profUpdateHash{iv} = list_reference
            profUpdateHash              => {},

            # A list of exit names ('north', 'up', etc) extracted from the 'verb_exit' component
            #   during the analysis
            analysisExitList            => [],
            # Some values extracted from the 'brief_title_exit' and 'brief_exit_title' components,
            #   stored by $self->analyseComponent and retrieved by $self->analysisPage
            tempStartText               => undef,
            tempStopText                => undef,
            tempDelimList               => [],

            # The languages set by buttons in the first two pages, matching the ->name IV of a
            #   phrasebook object (Games::Axmud::Obj::Phrasebook)
            # Set to 'undef' if no language button was used, or if the 'reset' button is clicked
            dirPageLang                 => undef,
            dictPageLang                => undef,
            # When directions are displayed by $self->directionsPage, the directions don't appear in
            #   the same order they appear in a phrasebook object (Games::Axmud::Obj::Phrasebook).
            #   This hash converts indexes in a phrasebook object's ->primaryDirList and
            #   ->primaryAbbrevDirList into an entry box number
            indexConvertHash            => {
                0                       => 0,       # n     / n
                1                       => 10,      # nne   / ne
                2                       => 1,       # ne    / e
                3                       => 11,      # ene   / se
                4                       => 2,       # e     / s
                5                       => 12,      # ese   / sw
                6                       => 3,       # se    / w
                7                       => 13,      # sse   / nw
                8                       => 4,       # s     / u
                9                       => 14,      # ssw   / d
                10                      => 5,       # sw    / nne
                11                      => 15,      # wsw   / ene
                12                      => 6,       # w     / ese
                13                      => 16,      # wnw   / sse
                14                      => 7,       # nw    / ssw
                15                      => 17,      # nnw   / wsw
                16                      => 8,       # u     / wnw
                17                      => 9,       # d     / nnw
            },
        };

        # Bless the object into existence
        bless $self, $class;

        # Set up the direction IVs using the current dictionary
        $self->resetDirs();
        # Set the other word/phrase IVs using the current dictonary
        $self->resetOtherWords();
        # Set the initial list of contents markers
        $self->ivPoke('markerList', $self->session->currentWorld->contentPatternList);

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

#   sub winEnable {}        # Inherited from GA::Generic::WizWin

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}       # Inherited from GA::Generic::WizWin

#   sub winShowAll {}       # Inherited from GA::Generic::Win

#   sub drawWidgets {}      # Inherited from GA::Generic::WizWin

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub saveChanges {

        # Called by $self->buttonNext when the user clicks the 'Finish' button
        # Saves changes to the current world profile and/or current dictionary, before closing the
        #   window
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
            $profObj, $dictObj, $declineString, $choice, $string, $pbObjDir, $pbObjDict, $dictFlag,
            @numberList, @comboList,
            %primaryHash, %abbrevHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->saveChanges', @_);
        }

        # Save changes to the current world profile
        $profObj = $self->session->currentWorld;

        # Component lists
        if ($self->verboseComponentObjList) {

            $profObj->ivEmpty('verboseComponentList');

            foreach my $componentObj ($self->verboseComponentObjList) {

                # Add the component object itself to the profile
                $profObj->ivAdd('componentHash', $componentObj->name, $componentObj);

                # For 'verb_content' and 'brief_content' components, the marker patterns stored in
                #   GA::Profile::World->contentPatternList must also be added to the component
                #   itself
                $self->updateContentComponent($componentObj);

                # The special 'anchor' component must be inserted before the component which
                #   contains exits (which acts as our anchor line)
                $self->insertAnchor($profObj, 'verboseComponentList', $componentObj->type);
                $profObj->ivPush('verboseComponentList', $componentObj->name);
            }
        }

        if ($self->shortComponentObjList) {

            $profObj->ivEmpty('shortComponentList');

            foreach my $componentObj ($self->shortComponentObjList) {

                $profObj->ivAdd('componentHash', $componentObj->name, $componentObj);

                $self->insertAnchor($profObj, 'shortComponentList', $componentObj->type);
                $profObj->ivPush('shortComponentList', $componentObj->name);
            }
        }

        if ($self->briefComponentObjList) {

            $profObj->ivEmpty('briefComponentList');

            foreach my $componentObj ($self->briefComponentObjList) {

                $profObj->ivAdd('componentHash', $componentObj->name, $componentObj);

                $self->insertAnchor($profObj, 'briefComponentList', $componentObj->type);
                $profObj->ivPush('briefComponentList', $componentObj->name);
            }
        }

        # IVs stored in $self->profUpdateHash
        foreach my $key ($self->ivKeys('profUpdateHash')) {

            my (
                $value,
                @list,
            );

            $value = $self->ivShow('profUpdateHash', $key);

            # For list IVs, $value is a reference to a list. De-reference it
            if (substr($key, -4) eq 'List') {

                @list = @$value;
            }

            # Set scalar IVs
            if (
                $key eq 'verboseAnchorOffset' || $key eq 'shortAnchorOffset'
                || $key eq 'briefAnchorOffset'
            ) {
                $profObj->ivPoke($key, $value);

            # Replace some list IVs...
            } elsif ($key eq 'verboseExitDelimiterList' || $key eq 'briefExitDelimiterList') {

                $profObj->ivPoke($key, @list);

            # ...update other list IVs, adding new values to old ones (but not adding duplicates)
            } elsif (
                $key eq 'verboseAnchorPatternList' || $key eq 'shortAnchorPatternList'
                || $key eq 'briefAnchorPatternList' || $key eq 'verboseExitLeftMarkerList'
                || $key eq 'verboseExitRightMarkerList' || $key eq 'briefExitLeftMarkerList'
                || $key eq 'briefExitRightMarkerList'
            ) {
                $self->updateProfileList($profObj, $key, @list);
            }
        }

        # IVs stored in $self->markerList (replace the current contents of the world profile's IV
        if ($self->markerList) {

            $profObj->ivPoke('contentPatternList', $self->markerList);
        }

        # Check the world profile's ->verboseExitNonDelimiterList, and remove any items that have
        #   been added to ->verboseExitDelimiterList
        $self->checkDelimiters($profObj, 'verboseExitDelimiterList', 'verboseExitNonDelimiterList');
        # Check the world profile's ->briefExitNonDelimiterList, and remove any items that have been
        #   added to ->briefExitDelimiterList
        $self->checkDelimiters($profObj, 'briefExitDelimiterList', 'briefExitNonDelimiterList');

        # Save changes to the current dictionary
        $dictObj = $self->session->currentDict;
        # Import lists/hashes for simplicity
        %primaryHash = $self->customPrimaryDirHash;
        %abbrevHash = $self->customPrimaryAbbrevHash;
        @numberList = $self->numberList;

        foreach my $standardDir (keys %primaryHash) {

            # If the value in the key-value pair is defined, the user has changed it
            if (defined $primaryHash{$standardDir}) {

                $dictObj->ivAdd('primaryDirHash', $standardDir, $primaryHash{$standardDir});
                $dictFlag = TRUE;
            }
        }

        foreach my $standardDir (keys %abbrevHash) {

            if (defined $abbrevHash{$standardDir}) {

                $dictObj->ivAdd('primaryAbbrevHash', $standardDir, $abbrevHash{$standardDir});
                $dictFlag = TRUE;
            }
        }

        if ($dictFlag) {

            # Update the dictionary's ->primaryOppHash and ->primaryOppAbbrevHash IVs
            $dictObj->updateOppDirHash();
        }

        if ($self->ivShow('ivChangeHash', 'definiteList')) {

            $dictObj->ivPoke('definiteList', $self->definiteList);
        }

        if ($self->ivShow('ivChangeHash', 'indefiniteList')) {

            $dictObj->ivPoke('indefiniteList', $self->indefiniteList);
        }

        if ($self->ivShow('ivChangeHash', 'andList')) {

            $dictObj->ivPoke('andList', $self->andList);
        }

        if ($self->ivShow('ivChangeHash', 'orList')) {

            $dictObj->ivPoke('orList', $self->orList);
        }

        if ($self->ivShow('ivChangeHash', 'numberList')) {

            if (@numberList && (scalar @numberList) == 10) {

                for (my $num = 1; $num <= 10; $num++) {

                    $dictObj->ivAdd(
                        'numberHash',
                        shift @numberList,
                        $num,
                    );
                }
            }
        }

        # If the user clicked one of the language buttons in either of the first two windows, ask
        #   them if they'd like to set the dictionary's language
        # $self->dirPageLang and ->dictPageLang, if set, are the names of the equivalent phrasebook
        #   objects
        if ($self->dirPageLang) {

            $pbObjDir = $axmud::CLIENT->ivShow('constPhrasebookHash', $self->dirPageLang);
        }

        if ($self->dictPageLang) {

            $pbObjDict = $axmud::CLIENT->ivShow('constPhrasebookHash', $self->dirPageLang);
        }

        if ($pbObjDir && $pbObjDict && $pbObjDir->name ne $pbObjDict->name) {

            # Open a 'dialogue' window with a combobox, so the user can choose between the languages
            $declineString = 'Don\'t change the language';

            # @comboList should only contain languages that aren't the current dictionary's language
            push (@comboList, $declineString);

            if ($pbObjDir->targetName ne $dictObj->language) {

                push (@comboList, $pbObjDir->targetName);
            }

            if ($pbObjDict->targetName ne $dictObj->language) {

                push (@comboList, $pbObjDict->targetName);
            }

            # Prompt the user
            $choice = $self->showComboDialogue(
                'Change dictionary language',
                'Do you want to change the current dictionary\'s language?',
                FALSE,
                \@comboList,
            );

            if ($choice && $choice ne $declineString) {

                $dictObj->ivPoke('language', $choice);
                # Also set the dictionary's noun-adjective word order, while we're at it
                if ($pbObjDir->targetName eq $choice) {
                    $dictObj->ivPoke('nounPosn', $pbObjDir->nounPosn);
                } else {
                    $dictObj->ivPoke('nounPosn', $pbObjDict->nounPosn);
                }
            }

        } elsif ($pbObjDir || $pbObjDict) {

            # Open a 'dialogue' window with yes/no buttons, so the user can choose a language
            if ($pbObjDir) {
                $string = $pbObjDir->targetName;
            } else {
                $string = $pbObjDict->targetName;
            }

            $choice = $self->showMsgDialogue(
                'Change dictionary language',
                'question',
                'Do you want to change the current dictionary\'s language to \'' . $string . '\'?',
                'yes-no',
            );

            if ($choice && $choice eq 'yes') {

               $dictObj->ivPoke('language', $string);
                if ($pbObjDir->targetName eq $choice) {
                    $dictObj->ivPoke('nounPosn', $pbObjDir->nounPosn);
                } else {
                    $dictObj->ivPoke('nounPosn', $pbObjDict->nounPosn);
                }
            }
        }

        # All changes made. Reset the Locator task, if it's open, which will hopefully work now;
        #   then close the window
        if ($self->session->locatorTask) {

            $self->session->pseudoCmd('resetlocatortask', $self->pseudoCmdMode);
        }

        $self->winDestroy();

        return 1;
    }

    # Window pages

    sub introPage {

        # Intro page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->introPage', @_);
        }

        # Intro
        $self->addLabel($self->table, '<b>Locator wizard (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);

        my $image = $self->addSimpleImage(
            $self->table,
            $axmud::SHARE_DIR . '/icons/system/mapper_medium.png',
            undef,
            1, 6, 3, 10);

        $self->addLabel(
            $self->table,
            "This wizard teaches the current world profile and the\ncurrent dictionary how to read"
            . " room statements (also\ncalled \'room descriptions\') in the game world.",
            7, 12, 3, 4);

        $self->addLabel(
            $self->table,
            "The Locator task and the Automapper window <b>won\'t work\nat all</b> until the wizard"
            . " has finished (unless you are using a\npre-configured world).",
            7, 12, 5, 6);

        $self->addLabel(
            $self->table,
            "Use the <b>Next</b> and <b>Previous</b> buttons to navigate between\npages.",
            7, 12, 7, 8);

        $self->addLabel(
            $self->table,
            "(You can also configure world profiles and dictionaries\nby using their 'edit'"
            . " windows.)",
            7, 12, 9, 10);

        # Add a few empty labels to get the spacing right
        @list = (1, 2, 10, 11);
        foreach my $row (@list) {

            $self->addLabel($self->table, '',
                1, 12, $row, ($row + 1));
        }

        return 12;
    }

    sub directionsPage {

        # Directions page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my (
            $row,
            @phrasebookList, @entryList, @entryAbbrevList, @dirList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->directionsPage', @_);
        }

        # Get a sorted list of phrasebook objects
        @phrasebookList = sort {$a->targetName cmp $b->targetName}
                            ($axmud::CLIENT->ivValues('constPhrasebookHash'));

        # Primary directions
        $self->addLabel($self->table, '<b>Primary directions (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);

        $self->addLabel(
            $self->table,
            $axmud::SCRIPT . "\'s primary directions are the eight usual cardinal directions"
            . " (\'north\', \'east\', \'southwest\'\nand so on), the eight lesser-used cardinal"
            . " directions (\'eastnortheast\', \'southsouthwest\' and\nso on) plus the directions"
            . " \'up\' and \'down\'.",
            1, 12, 1, 2);
        $self->addLabel(
            $self->table,
            "The Automapper window draws all exits as one of these primary directions. An exit"
            . " called\n\'north\' is always drawn pointing towards the top of the map,"
            . " but you can choose how exits\ncalled \'enter\', \'out\' and \'portal\' are drawn.",
            1, 12, 2, 3);
        $self->addLabel(
            $self->table,
            "If the world\'s language is not English, or if it uses a different set of primary"
            . " directions, you\ncan set them below. Otherwise, just click the <b>Next</b> button.",
            1, 12, 3, 4);

        # Column titles, used twice so that 'northnortheast' (etc) appear towards the bottom
        $self->addLabel($self->table, '<u>Primary direction</u>',
            1, 3, 4, 5);
        $self->addLabel($self->table, '<u>Custom primary direction</u>',
            3, 6, 4, 5);
        $self->addLabel($self->table, '<u>Custom abbreviation</u>',
            6, 9, 4, 5);
        $self->addLabel($self->table, '<u>Primary direction</u>',
            1, 3, 15, 16);
        $self->addLabel($self->table, '<u>Custom primary direction</u>',
            3, 6, 15, 16);
        $self->addLabel($self->table, '<u>Custom abbreviation</u>',
            6, 9, 15, 16);

        # Entry boxes for each custom direction. Compose a list of directions, using the usual
        #   eight cardinal directions first, then up/down, then the rarer cardinal directions
        @dirList = $axmud::CLIENT->constShortPrimaryDirList;
        foreach my $dir ($axmud::CLIENT->constPrimaryDirList) {

            if (! $axmud::CLIENT->ivExists('constShortPrimaryDirHash', $dir)) {

                push (@dirList, $dir);
            }
        }

        $row = 4;
        foreach my $standardDir (@dirList) {

            $row++;
            # Leave a gap between up/down and the rarer cardinal directions
            if ($standardDir eq 'northnortheast') {

                $row++;
            }

            $self->addLabel($self->table, $standardDir,
                1, 3, $row, ($row + 1));

            my $entry = $self->addEntry(
                $self->table,
                undef,
                $self->ivShow('customPrimaryDirHash', $standardDir),
                TRUE,
                3, 6, $row, ($row + 1));
            $entry->signal_connect('changed' => sub {

                my $text = $entry->get_text();

                if ($text) {

                    $self->ivAdd('customPrimaryDirHash', $standardDir, $text);

                } else {

                    # Don't overwrite the current dictionary's stored direction
                    $self->ivAdd('customPrimaryDirHash', $standardDir, undef);
                }

                # Mark the IV as having been changed
                $self->ivAdd('ivChangeHash', 'customPrimaryDirHash', TRUE);
            });
            push (@entryList, $entry);

            my $entry2 = $self->addEntry(
                $self->table,
                undef,
                $self->ivShow('customPrimaryAbbrevHash', $standardDir),
                TRUE,
                6, 9, $row, ($row + 1),
                8);             # Restrict entry box width
            $entry2->signal_connect('changed' => sub {

                my $text = $entry2->get_text();

                if ($text) {

                    $self->ivAdd('customPrimaryAbbrevHash', $standardDir, $text);

                } else {

                    # Don't overwrite the current dictionary's stored direction
                    $self->ivAdd('customPrimaryAbbrevHash', $standardDir, undef);
                }

                # Mark the IV as having been changed
                $self->ivAdd('ivChangeHash', 'customPrimaryAbbrevHash', TRUE);
            });
            push (@entryAbbrevList, $entry2);
        }

        # Reset directions button
        my $button = $self->addButton(
            $self->table,
            undef,
            'Reset directions', 'Reset the lists of primary directions',
            9, 12, 4, 5);
        # ->signal_connect appears further down...

        $row = 4;
        foreach my $pbObj (@phrasebookList) {

            $row++;

            my $button2 = $self->addButton(
                $self->table,
                undef,
                $pbObj->targetName,
                'Use ' . ucfirst($pbObj->name) . ' language directions',
                9, 12, $row, ($row + 1));

            $button2->signal_connect('clicked' => sub {

                $self->ivPoke('dirPageLang', $pbObj->name);

                for (my $count = 0; $count < 18; $count++) {

                    my $index = $self->ivShow('indexConvertHash', $count);

                    # Update the entry boxes, which automatically updates stored IVs
                    $entryList[$index]->set_text($pbObj->ivIndex('primaryDirList', $count));
                    $entryAbbrevList[$index]->set_text(
                        $pbObj->ivIndex('primaryAbbrevDirList', $count),
                    );
                }
            });
        }

        # ->signal_connect for the 'reset' button
        $button->signal_connect('clicked' => sub {

            my $index;

            # Reset the IVs ->customPrimaryDirHash and ->customPrimaryAbbrevHash
            $self->resetDirs();

            # Reset the language
            $self->ivUndef('dirPageLang');

            # There are eighteen (standard) primary directions
            $index = -1;
            foreach my $standardDir (@dirList) {

                $index++;

                # Update the entry boxes, which automatically updates stored IVs
                if (defined $self->ivShow('customPrimaryDirHash', $standardDir)) {

                    $entryList[$index]->set_text(
                        $self->ivShow('customPrimaryDirHash', $standardDir),
                    );
                }

                if (defined $self->ivShow('customPrimaryAbbrevHash', $standardDir)) {

                    $entryAbbrevList[$index]->set_text(
                        $self->ivShow('customPrimaryAbbrevHash', $standardDir),
                    );
                }
            }

            # Mark the IVs as not having been changed
            $self->ivAdd('ivChangeHash', 'customPrimaryDirHash', FALSE);
            $self->ivAdd('ivChangeHash', 'customPrimaryAbbrevHash', FALSE);
        });

        return ($row + 1);
    }

    sub dictionaryPage {

        # Dictionary page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my (
            $row,
            @phrasebookList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->dictionaryPage', @_);
        }

        # Get a sorted list of phrasebook objects
        @phrasebookList = sort {$a->targetName cmp $b->targetName}
                            ($axmud::CLIENT->ivValues('constPhrasebookHash'));

        # Dictionary words
        $self->addLabel($self->table, '<b>Dictionary words (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            "In order to work out what\'s in the current room, " . $axmud::SCRIPT
            . " tries to analyse lines like these:",
            1, 12, 1, 2);
        $self->addLabel(
            $self->table,
            '<i>Three orcs, two lamps and a giraffe are here.</i>',
            2, 12, 2, 3);
        $self->addLabel(
            $self->table,
            "Many worlds use the exact words \'five\', \'the\' and \'or\', but if this world"
            . " uses another set of\nwords, you can enter them below.  Otherwise, just click the"
            . " <b>Next</b> button.",
            1, 12, 3, 4);
        $self->addLabel(
            $self->table,
            "<b>Hint:</b> Each box should contain one word (or phrase) per line.",
            1, 12, 4, 5);

        # First column
        $self->addLabel($self->table, '<u>Articles</u>',
            1, 3, 5, 6);
        $self->addLabel($self->table, '<i>\'the\'</i>',
            1, 3, 6, 7);
        my $textView = $self->addTextView($self->table, undef, undef, undef, TRUE,
            1, 3, 7, 11);
        my $buffer = $textView->get_buffer();
        if ($self->definiteList) {

            $buffer->set_text(join("\n", $self->definiteList));
        }
        $self->textViewSignalConnect($buffer, 'definiteList');

        $self->addLabel($self->table, '<i>\'a / an\'</i>',
            1, 3, 11, 12);
        my $textView2 = $self->addTextView($self->table, undef, undef, undef, TRUE,
            1, 3, 12, 16);
        my $buffer2 = $textView2->get_buffer();
        if ($self->indefiniteList) {

            $buffer2->set_text(join("\n", $self->indefiniteList));
        }
        $self->textViewSignalConnect($buffer2, 'indefiniteList');

        # Second column
        $self->addLabel($self->table, '<u>Conjunctions</u>',
            3, 6, 5, 6);
        $self->addLabel($self->table, '<i>\'and\'</i>',
            3, 6, 6, 7);
        my $textView3 = $self->addTextView($self->table, undef, undef, undef, TRUE,
            3, 6, 7, 11);
        my $buffer3 = $textView3->get_buffer();
        if ($self->andList) {

            $buffer3->set_text(join("\n", $self->andList));
        }
        $self->textViewSignalConnect($buffer3, 'andList');

        $self->addLabel($self->table, '<i>\'or\'</i>',
            3, 6, 11, 12);
        my $textView4 = $self->addTextView($self->table, undef, undef, undef, TRUE,
            3, 6, 12, 16);
        my $buffer4 = $textView4->get_buffer();
        if ($self->orList) {

            $buffer4->set_text(join("\n", $self->orList));
        }
        $self->textViewSignalConnect($buffer4, 'orList');

        # Third column
        $self->addLabel($self->table, '<u>Numbers</u>',
            6, 9, 5, 6);
        $self->addLabel($self->table, '<i>\'one\' - \'ten\'</i>',
            6, 9, 6, 7);
        my $textView5 = $self->addTextView($self->table, undef, undef, undef, TRUE,
            6, 9, 7, 16);
        my $buffer5 = $textView5->get_buffer();
        if ($self->numberList) {

            $buffer5->set_text(join("\n", $self->numberList));
        }
        $self->textViewSignalConnect($buffer5, 'numberList');

        # Fourth column

        # Reset list button
        my $button = $self->addButton(
            $self->table,
            undef,
            'Reset words',
            'Reset the lists of words and phrases',
            9, 12, 5, 6);
        # ->signal_connect appears further down...

        # Add one button for each language supported by this object
        $row = 6;
        foreach my $pbObj (@phrasebookList) {

            $row++;

            my $button2 = $self->addButton(
                $self->table,
                undef,
                $pbObj->targetName,
                'Use ' . ucfirst($pbObj->name) . ' language terms',
                9, 12, $row, ($row + 1));

            $button2->signal_connect('clicked' => sub {

                $self->ivPoke('dictPageLang', $pbObj->name);

                # Update the textviews
                $buffer->set_text(join("\n", $pbObj->definiteList));
                $buffer2->set_text(join("\n", $pbObj->indefiniteList));
                $buffer3->set_text(join("\n", $pbObj->andList));
                $buffer4->set_text(join("\n", $pbObj->orList));
                $buffer5->set_text(join("\n", $pbObj->numberList));
            });
        }

        # ->signal_connect for the 'reset' button
        $button->signal_connect('clicked' => sub {

            # Reset the IVs ->definiteList, ->indefiniteList, ->andList, ->orList and ->numberList
            $self->resetOtherWords();

            # Reset the language
            $self->ivUndef('dictPageLang');

            # Update the textviews
            $buffer->set_text(join("\n", $self->definiteList));
            $buffer2->set_text(join("\n", $self->indefiniteList));
            $buffer3->set_text(join("\n", $self->andList));
            $buffer4->set_text(join("\n", $self->orList));
            $buffer5->set_text(join("\n", $self->numberList));

            # Update the hash of changed IVs
            $self->ivAdd('ivChangeHash', 'definiteList', FALSE);
            $self->ivAdd('ivChangeHash', 'indefiniteList', FALSE);
            $self->ivAdd('ivChangeHash', 'andList', FALSE);
            $self->ivAdd('ivChangeHash', 'orList', FALSE);
            $self->ivAdd('ivChangeHash', 'numberList', FALSE);
        });

        return 16;
    }

    sub statementsPage {

        # Statements page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->statementsPage', @_);
        }

        $self->addLabel($self->table, '<b>Room statements (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            "In " . $axmud::SCRIPT . " terminology, a \'room statement\' is a complete description"
            . " of a room. Each statement\nconsists of several different components which occur"
            . " in a predictable order.",
            1, 12, 1, 2);
        $self->addLabel(
            $self->table,
            $axmud::SCRIPT . " distinguishes between \'verbose\', \'short verbose\' and \'brief\'"
            . " statements. The components\nof a \'verbose\' room statement usually include:",
            1, 12, 2, 3);

        # Example room taken from the DeadSouls mudlib
        $self->addLabel($self->table, "<b>The room title</b>",
            1, 4, 3, 4);
        $self->addLabel($self->table, "<i>Village Road Intersection</i>",
            5, 12, 3, 4);

        $self->addLabel($self->table, "<b>The room description</b>",
            1, 4, 4, 5);
        $self->addLabel(
            $self->table,
            "<i>You are in the main intersection of the village. Saquivor\nroad extends north and"
            . " south, intersected east to west\nby a road that leads west toward a wilderness, and"
            . " east\ntoward shore.</i>",
            5, 12, 4, 5);

        $self->addLabel($self->table, "<b>The special contents list</b>",
            1, 4, 5, 6);
        $self->addLabel($self->table, "<i>There is a sign here you can read.</i>",
            5, 12, 5, 6);

        $self->addLabel($self->table, "<b>The exit list</b>",
            1, 4, 6, 7);
        $self->addLabel($self->table, "<i>Obvious exits: south, north, east, west</i>",
            5, 12, 6, 7);

        $self->addLabel($self->table, "<b>The contents list</b>",
            1, 4, 7, 8);
        $self->addLabel($self->table, "<i>A great clock tower is here.</i>",
            5, 12, 7, 8);

        $self->addLabel(
            $self->table,
            "A \'brief\' room statement often includes the following components:",
            1, 12, 8, 9);

        # Imaginary example
        $self->addLabel($self->table, "<b>Room title/exit list</b>",
            1, 4, 9, 10);
        $self->addLabel($self->table, "<i>Main intersection [s, n, e, w]</i>",
            5, 12, 9, 10);

        $self->addLabel($self->table, "<b>The contents list</b>",
            1, 4, 10, 11);
        $self->addLabel($self->table, "<i>A great clock tower is here.</i>",
            5, 12, 10, 11);

        $self->addLabel(
            $self->table,
            "Alternatively, some worlds allow you to use \'short verbose\' room statements, which"
            . " are usually\njust like \'verbose\' room statements, but without the room"
            . " description component.",
            1, 12, 11, 12);

        $self->addLabel(
            $self->table,
            "<b>You should now type the world\'s \'look\' command (or simply move to another room)"
            . "\nso that a <u>whole room statement</u> is visible - when you\'re ready, click on"
            . " \'Next\'.</b>",
            1, 12, 12, 13);

        return 13;
    }

    sub capturePage {

        # Capture page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my (
            $row,
            @labelList, @entryList, @comboList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->capturePage', @_);
        }

        # Add initial labels
        $self->addLabel(
            $self->table,
            '<b>Room statement capture (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            "Starting from the top, please identify the component to which every line belongs.",
            1, 12, 1, 2);

        # Add some widgets immediately below the labels
        my $button = $self->addButton(
            $self->table,
            undef,
            'Update lines',
            'Use the most recently-received lines',
            1, 3, 2, 3);
        my $button2 = $self->addButton(
            $self->table,
            undef,
            'More lines',
            'Use more lines',
            3, 5, 2, 3);
        my $button3 = $self->addButton(
            $self->table,
            undef,
            'Fewer lines',
            'Use fewer lines',
            5, 7, 2, 3);

        my ($radioButton, $radioButton2, $radioButton3, $group);
        ($group, $radioButton) = $self->addRadioButton(
            $self->table,
            undef,
            undef,
            'Verbose',
            FALSE,
            TRUE,
            8, 10, 2, 3);
        ($group, $radioButton2) = $self->addRadioButton(
            $self->table,
            undef,
            $group,
            'Short verbose',
            FALSE,
            TRUE,
            10, 11, 2, 3);
        ($group, $radioButton3) = $self->addRadioButton(
            $self->table,
            undef,
            $group,
            'Brief',
            FALSE,
            TRUE,
            11, 12, 2, 3);

        # ->signal_connects appear further down...
        if ($self->analysisType eq 'short') {
            $radioButton2->set_active(TRUE);
        } elsif ($self->analysisType eq 'brief') {
            $radioButton3->set_active(TRUE);
        }

        # Set the row at which the remaining widgets start to be drawn
        $row = 3;

        # Add a list of entry and comboboxes, one for each line of recently-received text
        $self->capturePage_drawWidgets($row, \@labelList, \@entryList, \@comboList);

        # If no capture has yet been performed, set their initial values
        if (! $self->bufferObjList) {

            # No capture has yet been performed, so set their initial values
            $self->capturePage_resetWidgets(\@entryList, \@comboList);

        } else {

            # Show data in the entries and comboboxes from the previous capture
            $self->capturePage_updateWidgets(\@entryList, \@comboList);
        }

        # Give the comboboxes their own ->signal_connect methods
        $self->capturePage_connectCombos(\@comboList);

        # Here's the ->signal_connect methods from earlier
        $button->signal_connect('clicked' => sub {

            # 'Update list' button. Reset the list of lines recently received from the world
            $self->capturePage_resetWidgets(\@entryList, \@comboList);
            $self->capturePage_connectCombos(\@comboList);
        });

        $button2->signal_connect('clicked' => sub {

            # 'More lines' button. Add more lines to the number displayed, then re-draw the entries
            #   and comboboxes.
            $self->ivPoke('analysisLength', $self->analysisLength + $self->analysisInc);

            # Prevent the user from setting more lines than the maximum by desensitising the button
            if ($self->analysisLength >= $self->analysisMaxLength) {
                $button2->set_sensitive(FALSE);
            } else {
                $button2->set_sensitive(TRUE);
            }

            # (The opposite button must be sensitised)
            $button3->set_sensitive(TRUE);

            # Redraw the entries and comboboxes
            $self->capturePage_drawWidgets($row, \@labelList, \@entryList, \@comboList);
            $self->capturePage_resetWidgets(\@entryList, \@comboList);
            $self->capturePage_connectCombos(\@comboList);

            # Make the changes visible
            $self->winShowAll($self->_objClass . '->capturePage');
        });

        $button3->signal_connect('clicked' => sub {

            # 'Fewer lines' button. Remove more lines to the number displayed, then re-draw the
            #   entries and comboboxes.
            $self->ivPoke('analysisLength', $self->analysisLength - $self->analysisInc);

            # Prevent the user setting fewer lines than the minimum by desensitising the button
            if ($self->analysisLength <= $self->analysisMinLength) {
                $button3->set_sensitive(FALSE);
            } else {
                $button3->set_sensitive(TRUE);
            }

            # (The opposite button must be sensitised)
            $button2->set_sensitive(TRUE);

            # Redraw the entries and comboboxes
            $self->capturePage_drawWidgets($row, \@labelList, \@entryList, \@comboList);
            $self->capturePage_resetWidgets(\@entryList, \@comboList);
            $self->capturePage_connectCombos(\@comboList);

            # Make the changes visible
            $self->winShowAll($self->_objClass . '->capturePage');
        });

        $radioButton->signal_connect('toggled' => sub {

            if ($radioButton->get_active()) {

                $self->ivPoke('analysisType', 'verbose');
            }

            # Redraw the entries and comboboxes
            $self->capturePage_drawWidgets($row, \@labelList, \@entryList, \@comboList);
            $self->capturePage_resetWidgets(\@entryList, \@comboList);
            $self->capturePage_connectCombos(\@comboList);

            # Make the changes visible
            $self->winShowAll($self->_objClass . '->capturePage');
        });

        $radioButton2->signal_connect('toggled' => sub {

            if ($radioButton2->get_active()) {

                $self->ivPoke('analysisType', 'short');
            }

            # Redraw the entries and comboboxes
            $self->capturePage_drawWidgets($row, \@labelList, \@entryList, \@comboList);
            $self->capturePage_resetWidgets(\@entryList, \@comboList);
            $self->capturePage_connectCombos(\@comboList);

            # Make the changes visible
            $self->winShowAll($self->_objClass . '->capturePage');
        });

        $radioButton3->signal_connect('toggled' => sub {

            if ($radioButton3->get_active()) {

                $self->ivPoke('analysisType', 'brief');
            }

            # Redraw the entries and comboboxes
            $self->capturePage_drawWidgets($row, \@labelList, \@entryList, \@comboList);
            $self->capturePage_resetWidgets(\@entryList, \@comboList);
            $self->capturePage_connectCombos(\@comboList);

            # Make the changes visible
            $self->winShowAll($self->_objClass . '->capturePage');
        });

        return ($row + scalar @entryList + 1);
    }

    sub capturePage_drawWidgets {

        # Called by $self->capturePage
        # Draws a Gtk2::Entry and a Gtk2::Combobox, one for each line in the display buffer
        #   displayed on this page
        #
        # Expected arguments
        #   $startRow       - The row on which the first entry/combobox is drawn
        #   $labelListRef   - Reference to a list of Gtk2::Labels at the beginning of each line
        #                       (an empty list if none have been drawn yet)
        #   $entryListRef   - Reference to a list of Gtk2::Entry boxes in which to display received
        #                       lines (an empty list if none have been drawn yet)
        #   $comboListRef   - Reference to a list of Gtk2::ComboBoxes in which to display components
        #                       (an empty list if none have been drawn yet)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $startRow, $labelListRef, $entryListRef, $comboListRef, $check) = @_;

        # Local variables
        my $row;

        # Check for improper arguments
        if (
            ! defined $startRow || ! defined $labelListRef || ! defined $entryListRef
            || ! defined $comboListRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->capturePage_drawWidgets',
                @_,
            );
        }

        # If any labels/entries/combo boxes have already been drawn, remove them from the table
        if (@$labelListRef) {

            foreach my $label (@$labelListRef) {

                $axmud::CLIENT->desktopObj->removeWidget($self->table, $label);
            }

            @$labelListRef = ();

            foreach my $entry (@$entryListRef) {

                $axmud::CLIENT->desktopObj->removeWidget($self->table, $entry);
            }

            @$entryListRef = ();

            foreach my $comboBox (@$comboListRef) {

                $axmud::CLIENT->desktopObj->removeWidget($self->table, $comboBox);
            }

            @$comboListRef = ();
        }

        # Add a list of entry boxes, one for each line
        $row = $startRow;
        for (my $line = 0; $line < $self->analysisLength; $line++) {

            $row++;

            my $label = $self->addLabel($self->table, '#' . ($line + 1),
                1, 2, $row, ($row + 1));

            push (@$labelListRef, $label);

            my $entry = $self->addEntry($self->table, undef, undef, TRUE,
                2, 9, $row, ($row + 1),
                40);    # Fixed width
            # (Rather than desensitising the entry boxes, just make them un-editable)
            $entry->set_editable(FALSE);

            push (@$entryListRef, $entry);
        }

        # Add combo boxes, one for each entry box
        $row = $startRow;
        for (my $line = 0; $line < $self->analysisLength; $line++) {

            my (@componentList, @comboList);

            $row++;

            # The comboboxes show the default list of components (for verbose, short verbose or
            #   brief statements)
            if ($self->analysisType eq 'verbose') {
                @componentList = $self->verboseComponentList;
            } elsif ($self->analysisType eq 'short') {
                @componentList = $self->shortComponentList;
            } elsif ($self->analysisType eq 'brief') {
                @componentList = $self->briefComponentList;
            }

            foreach my $component (@componentList) {

                push (@comboList, $self->ivShow('componentTypeHash', $component));
            }

            my $comboBox = $self->addComboBox($self->table, undef, \@comboList, undef,
                9, 12, $row, ($row + 1));

            push (@$comboListRef, $comboBox);
        }

        return 1;
    }

    sub capturePage_resetWidgets {

        # Called by $self->capturePage, sometimes after a call to $self->capturePage_drawWidgets
        # Resets the entry/combo boxes (one for each line in the display buffer displayed on this
        #   page)
        #
        # Expected arguments
        #   $entryListRef   - Reference to a list of Gtk2::Entry boxes in which to display received
        #                       lines
        #   $comboListRef   - Reference to a list of Gtk2::ComboBox-s in which to display components
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the list of lines displayed

        my ($self, $entryListRef, $comboListRef, $check) = @_;

        # Local variables
        my (
            $startLine, $stopLine, $count,
            @emptyList, @entryList, @lineList,
        );

        # Check for improper arguments
        if (! defined $entryListRef || ! defined $comboListRef || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->capturePage_resetWidgets', @_);
            return @emptyList;
        }

        $self->ivEmpty('bufferObjList');
        $self->ivEmpty('bufferTypeList');

        # Show the last $self->analysisLength lines received by the world, but don't exceed the
        #   boundaries of the display buffer
        if ($self->session->displayBufferCount) {

            $stopLine = $self->session->displayBufferLast;
            $startLine = $self->session->displayBufferLast - ($self->analysisLength - 1);

            if ($startLine < $self->session->displayBufferFirst) {

                # Don't look before the first line in the buffer
                $startLine = $self->session->displayBufferFirst;
            }
        }

        if ($startLine && $stopLine) {

            $count = -1;

            for (my $line = $startLine; $line <= $stopLine; $line++) {

                my ($bufferObj, $text, $entry);

                $count++;

                $bufferObj = $self->session->ivShow('displayBufferHash', $line);
                $text = $bufferObj->modLine;

                # Set the value displayed in the entry box numbered $count
                $entry = $$entryListRef[$count];
                $entry->set_text($text);
                push (@lineList, $text);

                # Update the record stored in the IV
                $self->ivPush('bufferObjList', $bufferObj);
            }
        }

        # Reset the comboboxes to contain the first component in the component list (which is
        #   'outside_statement' for verbose, short verbose and brief statements)
        foreach my $comboBox (@$comboListRef) {

            $comboBox->set_active(0);

            if ($self->analysisType eq 'verbose') {
                $self->ivPush('bufferTypeList', $self->ivFirst('verboseComponentList'));
            } elsif ($self->analysisType eq ' short') {
                $self->ivPush('bufferTypeList', $self->ivFirst('shortComponentList'));
            } else {
                $self->ivPush('bufferTypeList', $self->ivFirst('briefComponentList'));
            }
        }

        return @lineList;
    }

    sub capturePage_updateWidgets {

        # Called by $self->capturePage
        # Updates the entry/combo boxes (one for each line in the display buffer displayed on this
        #   page) after the initial call to ->capturePage, in order to display data from the last
        #   capture
        #
        # Expected arguments
        #   $entryListRef   - Reference to a list of Gtk2::Entry boxes in which to display received
        #                       lines
        #   $comboListRef   - Reference to a list of Gtk2::ComboBox-s in which to display components
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $entryListRef, $comboListRef, $check) = @_;

        # Local variables
        my (
            $count,
            @bufferObjList,
        );

        # Check for improper arguments
        if (! defined $entryListRef || ! defined $comboListRef || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->capturePage_updateWidgets',
                @_,
            );
        }

        # Import the previously-captured list of display buffer objects
        @bufferObjList = $self->bufferObjList;

        # Update the entry boxes
        $count = -1;
        foreach my $bufferObj (@bufferObjList) {

            my $entry;

            $count++;

            $entry = $$entryListRef[$count];
            $entry->set_text($bufferObj->modLine);
        }

        # Update the combos
        $count = -1;
        OUTER: foreach my $component ($self->bufferTypeList) {

            my ($combo, $posn);

            $count++;
            $combo = $$comboListRef[$count];

            if (defined $combo) {

                # Find the position of the component in the ordered list
                if ($self->analysisType eq 'verbose') {
                    $posn = $self->ivFind('verboseComponentList', $component);
                } elsif ($self->analysisType eq 'short') {
                    $posn = $self->ivFind('shortComponentList', $component);
                } else {
                    $posn = $self->ivFind('briefComponentList', $component);
                }

                # Set the combobox to that position (if it was found)
                if (defined $posn) {

                    $combo->set_active($posn);
                }
            }
        }

        return 1;
    }

    sub capturePage_connectCombos {

        # Called by $self->capturePage, usually after a call to ->capturePage_drawWidgets
        # Gives each combobox a ->signal_connect method
        #
        # Expected arguments
        #   $comboListRef   - Reference to a list of Gtk2::ComboBoxes in which to display components
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $comboListRef, $check) = @_;

        # Check for improper arguments
        if (! defined $comboListRef || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->capturePage_connectCombos',
                @_,
            );
        }

        OUTER: foreach my $comboBox (@$comboListRef) {

            $comboBox->signal_connect('changed' => sub {

                my ($textIndex, $match, $updateFlag);

                $textIndex = $comboBox->get_active();

                # Find the index of this combobox, as stored in $comboListRef
                INNER: for (my $count = 0; $count < $self->analysisLength; $count++) {

                    if ($$comboListRef[$count] eq $comboBox) {

                        $match = $count;
                        last INNER;
                    }
                }

                # Update the record stored in the IV
                if ($self->analysisType eq 'verbose') {

                    $self->ivReplace(
                        'bufferTypeList',
                        $match,
                        $self->ivIndex('verboseComponentList', $textIndex),
                    );

                } elsif ($self->analysisType eq 'short') {

                    $self->ivReplace(
                        'bufferTypeList',
                        $match,
                        $self->ivIndex('shortComponentList', $textIndex),
                    );

                } else {

                    $self->ivReplace(
                        'bufferTypeList',
                        $match,
                        $self->ivIndex('briefComponentList', $textIndex),
                    );
                }

                # Change the contents of every combobox beneath this one to match
                if ($match < ($self->analysisLength - 1)) {

                    $$comboListRef[$match + 1]->set_active($textIndex);
                }
            });
        }

        return 1;
    }

    sub analysisPage {

        # Analysis page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my ($result, $msg, $row, $string, $listRef, $bufferObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->analysisPage', @_);
        }

        $self->addLabel($self->table, '<b>Analysis (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);

        # Perform the analysis of the data gathered in the previous page
        ($result, $msg) = $self->analyseLines();

        # Analysis failed
        if (! $result) {

            $self->addLabel($self->table, 'Room statement analysis <u>FAILED</u>. Failure message:',
                1, 12, 1, 2);
            $self->addLabel($self->table, '<i>' . $msg . '</i>',
                1, 12, 2, 3);
            $self->addLabel(
                $self->table,
                "Try analysing a different room statement. Send your character to the new room,"
                . " then click\nthe <b>\'Previous\'</b> button to return to the previous page.",
                1, 12, 3, 4);
            $self->addLabel(
                $self->table,
                "(N.B. The wizard uses a set of rules which are stricter than the normal rules. If"
                . " you want to\ndo something that\'s not allowed here, you can try editing the"
                . " world profile directly\nusing its 'edit' window.)",
                1, 12, 4, 5);

            # If the user had already analysed a room statement, allow them to move on to the last
            #   page (skipping the next one); otherwise, de-sensitise the 'Next' button, forcing
            #   them to go back
            if ($self->analysisCount) {

                # Allow moving on to the last page
                $self->addLabel(
                    $self->table,
                    "If you\'re happy to use the results of previous analyses, click the"
                    . " <b>\'Next\'</b> button to complete the\nsetup process.",
                    1, 12, 5, 6);

                    # Special rule for the \'next\' button: it returns to page 8
                    $self->ivAdd('specialNextButtonHash', $self->currentPage, 7);

            } else {

                # Force the user to go back
                $self->ivPoke('disableNextButtonFlag', TRUE);
            }

            # Add a few empty labels, so that the paragraphs in the window aren't spaced so oddly
            for (my $row = 6; $row < 12; $row++) {

                $self->addLabel($self->table, '',
                    1, 12, $row, ($row + 1),
                );
            }

            return 12;

        # Analysis succeeded in verbose/short verbose mode
        } elsif ($self->analysisType eq 'verbose' || $self->analysisType eq 'short') {

            $self->ivIncrement('analysisCount');

            if ($self->analysisType eq 'verbose') {
                $string = 'Verbose';
            } else {
                $string = 'Short verbose';
            }

            $self->addLabel(
                $self->table,
                "$string room statement analysis <u>successful</u>. If the results seems to be in"
                . " order, click the <b>\'Next\'</b>\nbutton to see the rest of the analysis.",
                1, 12, 1, 2);
            $self->addLabel(
                $self->table,
                "Otherwise, try analysing a different room statement. Send your character to the"
                . " new room, then\nclick the <b>\'Previous\'</b> button to return to the previous"
                . " page.",
                1, 12, 2, 3);

            # Left column
            $self->addLabel($self->table, '<i>Room title</i>',
                1, 6, 3, 4);
            my $entry = $self->addEntry($self->table, undef, undef, TRUE,
                1, 6, 4, 5);
            $entry->set_editable(FALSE);
            if ($self->ivExists('analysisHash', 'verb_title')) {

                $listRef = $self->ivShow('analysisHash', 'verb_title');
                # The wizard requires that the 'verb_title' component is only one line
                $bufferObj = $self->ivIndex('bufferObjList', $$listRef[0]);
                $entry->set_text($bufferObj->modLine);
            }
            # Add a few empty labels below the entry for padding
            for (my $row = 5; $row < 7; $row++) {

                $self->addLabel($self->table, '',
                    1, 6, $row, ($row + 1),
                );
            }

            $self->addLabel($self->table, '<i>Verbose description</i>',
                1, 6, 7, 8);
            my $textView = $self->addTextView($self->table, undef, undef, undef, FALSE,
                1, 6, 8, 11);
            $self->updateTextView($textView, 'verb_descrip');

            # Right column
            $self->addLabel($self->table, '<i>Exit list</i>',
                7, 12, 3, 4);
            my $textView2 = $self->addTextView($self->table, undef, undef, undef, FALSE,
                7, 12, 4, 7);
            $self->updateTextView($textView2, 'verb_exit');

            $self->addLabel($self->table, '<i>Individual exits</i>',
                7, 12, 7, 8);
            my $textView3 = $self->addTextView($self->table, undef, undef, undef, FALSE,
                7, 12, 8, 11);
            if ($self->analysisExitList) {

                my $buffer3 = $textView3->get_buffer();
                $buffer3->set_text(join("\n", $self->analysisExitList));
            }

            return 12;

        # Analysis succeeded in brief mode
        } elsif ($self->analysisType eq 'brief') {

            my ($component, $button, $posn, $title);

            $self->ivIncrement('analysisCount');

            $self->addLabel(
                $self->table,
                "Brief room statement analysis <u>successful</u>.",
                1, 12, 1, 2);

            # For convenience, set which component contains the exit line
            if ($self->ivExists('analysisHash', 'brief_title_exit')) {
                $component = 'brief_title_exit';
            } elsif ($self->ivExists('analysisHash', 'brief_exit_title')) {
                $component = 'brief_exit_title';
            } else {
                $component = 'brief_exit';
            }

            # If the 'brief_title_exit' or 'brief_exit_title' components were specified, prompt the
            #   user to confirm which part of the line contains the room title
            if (
                (
                    ! $self->ivExists('profUpdateHash', 'briefExitLeftMarkerList')
                    && $component eq 'brief_title_exit'
                ) || (
                    ! $self->ivExists('profUpdateHash', 'briefExitRightMarkerList')
                    && $component eq 'brief_exit_title'
                )
            ) {
                # (The instructions don't need to be repeated, after the user has completed this
                #   page once before)
                $self->addLabel(
                    $self->table,
                    "Please confirm which part of the line containing the room title and exit list"
                    . " is the room title\nitself, then click the <b>\'Test\'</b> button. For"
                    . " example, in the line:",
                    1, 12, 2, 3);
                $self->addLabel($self->table, "<i>Town Centre (n, s, e, w)</i>",
                    2, 12, 3, 4);
                $self->addLabel(
                    $self->table,
                    "...you should copy and paste the <u>Town Centre</u> part (but not the first"
                    . " bracket) into the box below.",
                    1, 12, 4, 5);

                # Leave a small gap
                $row = 6;

            } else {

                # Leave a small gap
                $row = 3;
            }

            # (Each of the three components has only line)
            $listRef = $self->ivShow('analysisHash', $component);
            $bufferObj = $self->ivIndex('bufferObjList', $$listRef[0]);

            if ($component eq 'brief_title_exit') {

                $self->addLabel($self->table, 'Room title / exit list',
                    1, 3, $row, ($row + 1));

            } elsif ($component eq 'brief_exit_title') {

                $self->addLabel($self->table, 'Exit list / room title',
                    1, 3, $row, ($row + 1));

            } else {

                $self->addLabel($self->table, 'Exit list',
                    1, 3, $row, ($row + 1));
            }

            my $entry = $self->addEntry($self->table, undef, $bufferObj->modLine, TRUE,
                4, 12, $row, ($row + 1));
            $entry->set_editable(FALSE);

            $self->addLabel($self->table, 'Room title part',
                1, 3, ($row + 1), ($row + 2));
            my $entry2 = $self->addEntry($self->table, undef, undef, TRUE,
                4, 12, ($row + 1), ($row + 2));

            # If this page has already been completed, we can fill in the room title part
            if (
                $self->ivExists('profUpdateHash', 'briefExitLeftMarkerList')
                && $component eq 'brief_title_exit'
            ) {
                # The room title is everything to the left of the marker
                $listRef = $self->ivShow('profUpdateHash', 'briefExitLeftMarkerList');
                OUTER: foreach my $marker (@$listRef) {

                    $posn = index($bufferObj->modLine, $marker);
                    if ($posn > -1) {

                        $title = substr($bufferObj->modLine, 0, $posn);
                        last OUTER;
                    }
                }

            } elsif (
                $self->ivExists('profUpdateHash', 'briefExitRightMarkerList')
                && $component eq 'brief_exit_title'
            ) {
                # The room title is everything to the right of the marker
                $listRef = $self->ivShow('profUpdateHash', 'briefExitRightMarkerList');
                OUTER: foreach my $marker (@$listRef) {

                    $posn = index($bufferObj->modLine, $marker);
                    if ($posn > -1) {

                        $title = substr($bufferObj->modLine, ($posn + length($marker)));
                        last OUTER;
                    }
                }
            }

            # Display the room title, if we have it
            if ($title) {

                $entry2->set_text($title);
            }

            $button = $self->addButton(
                $self->table,
                undef,
                'Test',
                'Test the line containing the list of exits',
                1, 12, ($row + 2), ($row + 3));
            # ->signal_connect follows...

            # Middle left column
            $self->addLabel($self->table, '<i>Room title</i>',
                1, 6, ($row + 3), ($row + 4));
            my $entry3 = $self->addEntry($self->table, undef, undef, TRUE,
                1, 6, ($row + 4), ($row + 5));
            $entry3->set_editable(FALSE);

            # Middle right column
            $self->addLabel($self->table, '<i>Individual exits</i>',
                7, 12, ($row + 3), ($row + 4));
            my $entry4 = $self->addEntry($self->table, undef, undef, TRUE,
                7, 12, ($row + 4), ($row + 5));
            $entry4->set_editable(FALSE);

            # Bottom portion
            $self->addLabel(
                $self->table,
                "If the results seem to be in order, click the <b>\'Next\'</b> button. Otherwise,"
                . " try analysing a\ndifferent room statement. Send your character to the new room,"
                . " then click the <b>\'Previous\'</b> button.",
                1, 12, ($row + 5), ($row + 6));

            if ($component eq 'brief_exit') {

                # Add a few empty labels to make the spacing between widgets better
                for (my $count = ($row + 5); $count < ($row + 9); $count++) {

                    $self->addLabel($self->table, '',
                        1, 12, $count, ($count + 1));
                }

            } else {

                # Add just a single label to make the spacing between widgets better
                $self->addLabel($self->table, '',
                    1, 12, ($row + 5), ($row + 6));
            }

            # 'Test' button signal_connect
            $button->signal_connect('clicked' => sub {

                my (
                    $lineText, $startText, $stopText, $qmStartText, $qmStopText, $errorMsg,
                    $newStartText, $newStopText, $foundFlag, $pattern,
                    @exitList,
                );

                $title = $entry2->get_text();
                if ($title) {

                    # The line stored in $bufferObj->modLine is in the form
                    #   <start_text><exit><delimiter><exit><delimiter><exit><stop_text>
                    # For the 'brief_title_exit' component, the room title will be somewhere in
                    #   <start_text>; for the 'brief_exit_title' component, the room title will be
                    #   somewhere in <stop_text>.
                    # The remainding portions of <start_text> and <stop_text> will comprise the
                    #   brief exit markers stored in GA::Profile::World->briefExitLeftMarkerList and
                    #   ->briefExitRightMarkerList
                    $lineText = $bufferObj->modLine;
                    $startText = $newStartText = $self->tempStartText;
                    $stopText = $newStopText = $self->tempStopText;
                    $qmStartText = quotemeta($startText);
                    $qmStopText = quotemeta($stopText);

                    $errorMsg = "Test failed (usually because the room title contains a direction,"
                                    . " e.g. \'The northeast corner of the square\').\n\n"
                                    . "Click the \'Previous\' button and try a room with a"
                                    . " different title.";

                    if ($component eq 'brief_title_exit' && $lineText =~ m/$qmStartText/) {

                        # Remove everything up to and including the room title, leaving the rest as
                        #   the left marker
                        $posn = index($startText, $title);
                        if ($posn < 0) {

                            $self->showMsgDialogue(
                                'Room title test',
                                'error',
                                $errorMsg,
                                'ok',
                            );

                        } else {

                            $newStartText = substr($startText, ($posn + (length $title)));
                            $foundFlag = TRUE;
                        }

                    } elsif ($component eq 'brief_exit_title' && $lineText =~ m/$qmStopText/) {

                        # Remove everything from the room title onwards, leaving the rest as the
                        #   right marker
                        $posn = index($stopText, $title);
                        if ($posn < 0) {

                            $self->showMsgDialogue(
                                'Test brief title/exit',
                                'error',
                                $errorMsg,
                                'ok',
                            );

                        } else {

                            $newStopText = substr($stopText, 0, $posn);
                            $foundFlag = TRUE;
                        }
                    }

                    if ($foundFlag) {

                        # Try to extract a list of exits, ready for display. Remove the
                        #    <start_text> and <stop_text> parts from the line...
                        $lineText =~ s/$qmStartText//;
                        $lineText =~ s/$qmStopText//;
                        @exitList = $self->testExtractExits($lineText);

                        if (@exitList) {

                            # Success! Update $self->profUpdateHash
                            $self->profileUpdatePush(
                                'briefExitLeftMarkerList',
                                quotemeta($newStartText),
                            );

                            $self->profileUpdatePush(
                                'briefExitRightMarkerList',
                                quotemeta($newStopText),
                            );

                            $self->profileUpdatePush(
                                'briefExitDelimiterList',
                                $self->tempDelimList,
                            );

                            # Update the entry boxes
                            $entry3->set_text($title);
                            $entry4->set_text(join(' ', @exitList));

                            # As we did for 'brief_exit', compile a regex in the form
                            #   '<start_text>(.*)<stop_text>'
                            $pattern = quotemeta($newStartText) . '(.*)' . quotemeta($newStopText);
                            # To cope with a <start_text> part (or even a <stop_text> part) which is
                            #   'There are four obvious exits:', go through the pattern, removing
                            #   any number words (or numerals!)
                            $pattern = $self->processPattern($pattern);
                            # Store the results
                            $self->profileUpdatePush('briefAnchorPatternList', $pattern);
                            $self->ivAdd('profUpdateHash', 'briefAnchorOffset', 1);

                            # For consistency, also store the analysed exit list
                            $self->ivPoke('analysisExitList', @exitList);
                        }
                    }
                }
            });

            # For the 'brief_exit' component, there is no room title to display, so desensitise the
            #   entry boxes and the 'Test' button
            if ($component eq 'brief_exit') {

                $entry2->set_sensitive(FALSE);
                $entry3->set_sensitive(FALSE);
                $button->set_sensitive(FALSE);

                # Also fill $entry4, as if the 'Text' button had already been clicked
                $entry4->set_text(join(' ', $self->analysisExitList));
            }

            return ($row + 9);
        }
    }

    sub analysis2Page {

        # Analysis2 page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my ($component, $listRef);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->analysis2Page', @_);
        }

        # Contents analysis
        $self->addLabel($self->table, '<b>Contents analysis (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            $axmud::SCRIPT . " needs some more details so it can analyse lists of objects. For"
            . " example, in the lines:",
            1, 12, 1, 2);
        $self->addLabel($self->table, '<i>A stick of dynamite is here.</i>',
            2, 12, 2, 3);
        $self->addLabel(
            $self->table,
            '<i>Three orcs, two lamps and a giraffe are here.</i>',
            2, 12, 3, 4);
        $self->addLabel(
            $self->table,
            "..." . $axmud::SCRIPT . " needs to know that the patterns <i>\'is here\'</i> and"
            . " <i>\'are here\'</i> mean that there are objects\nin this room.",
            1, 12, 4, 5);
        $self->addLabel(
            $self->table,
            "Please examine the contents list on the left (it will be empty if you didn\'t allocate"
            . " any\ncontents components). If the box on the right doesn\'t contain the correct"
            . " patterns,\nyou can add them now.",
            1, 12, 5, 6);

        $self->addLabel(
            $self->table,
            "<b>Hint:</b> The patterns are Perl regular expressions, so you can use special"
            . " characters like <u>\\s</u>\nand <u>(.*)</u>",
            1, 12, 6, 7);

        if ($self->ivExists('analysisHash', 'verb_content')) {
            $component = 'verb_content';
        } elsif ($self->ivExists('analysisHash', 'brief_content')) {
            $component = 'brief_content';
        }

        # Left column
        $self->addLabel($self->table, '<i>Room statement\'s contents list</i>',
            1, 6, 7, 8);
        my $textView = $self->addTextView($self->table, undef, undef, undef, FALSE,
            1, 6, 8, 9);
        my $buffer = $textView->get_buffer();
        if ($component && ($component eq 'verb_content' || $component eq 'brief_content')) {

            $self->updateTextView($textView, $component);
        }

        # Right column
        $self->addLabel($self->table, '<i>Marker patterns (e.g. \'is here.\')</i>',
            7, 12, 7, 8);
        my $textView2 = $self->addTextView($self->table, undef, undef, undef, TRUE,
            7, 12, 8, 9);
        my $buffer2 = $textView2->get_buffer();
        if ($self->markerList) {

            $buffer2->set_text(join("\n", $self->markerList));
        }
        $self->textViewSignalConnect($buffer2, 'markerList');

        # Bottom area
        if ($component) {

            $self->addLabel(
                $self->table,
                "If you like, you can test the patterns by clicking the <b>\'Test\'</b> button."
                . " When\nyou\'re satisfied, click the <b>\'Next\'</b> button at the bottom of the"
                . " window.",
                1, 9, 9, 10);
            my $button = $self->addButton(
                $self->table,
                undef,
                'Test',
                'Test the contents patterns',
                9, 12, 9, 10);
            # ->signal_connect appears just below...

            $self->addLabel($self->table, '<i>List of objects</i>',
                1, 12, 10, 11);
            my $textView3 = $self->addTextView($self->table, undef, undef, undef, FALSE,
                1, 12, 11, 12);
            my $buffer3 = $textView3->get_buffer();

            $button->signal_connect('clicked' => sub {

                my (@stringList, @modList);

                # Use the standard object parsing code to convert the room's contents list into
                #    a list of non-model objects
                $listRef = $self->ivShow('analysisHash', $component);

                foreach my $line (@$listRef) {

                    my $bufferObj = $self->ivIndex('bufferObjList', $line);
                    push (@stringList, $bufferObj->modLine);
                }

                # We can't use GA::Obj::WorldModel->parseObj, because that function uses the
                #   current world's ->contentPatternList - whereas we want to test the new content
                #   markers in $textView2
                # For each line in turn, perform a substitution - but only once per line
                OUTER: foreach my $string (@stringList) {

                    INNER: foreach my $regex ($self->markerList) {

                        if ($string =~ m/$regex/) {

                            $string =~ s/$regex//;
                            next OUTER;
                        }
                    }
                }

                $buffer3->set_text(join("\n", @stringList));
            });

        } else {

            $self->addLabel(
                $self->table,
                "When you\'re ready, click the \'Next\' button at the bottom of the window.",
                1, 12, 9, 10);
        }

        return 12;
    }

    sub lastPage {

        # Last page - called by $self->setupTable or ->expandTable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of table rows used

        my ($self, $check) = @_;

        # Local variables
        my (@verboseList, @shortList, @briefList);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->lastPage', @_);
        }

        $self->addLabel($self->table, '<b>Checklist (' . $self->getPageString() . ')</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $self->table,
            "The world profile will now be updated to use the components displayed below. The"
            . " current\ndictionary will also be updated with any modifications you made earlier.",
            1, 12, 1, 2);
        $self->addLabel(
            $self->table,
            "Click <b>\'Finish\'</b> to complete the setup process or click <b>\'Previous\'</b> to"
            . " capture another room\nstatement.",
            1, 12, 2, 3);

        # Left column
        $self->addLabel($self->table, '<u>Verbose statements</u>',
            1, 4, 3, 4);
        $self->addLabel($self->table, 'Analysis complete',
            1, 3, 4, 5);
        my $checkButton = $self->addCheckButton($self->table, undef, FALSE, FALSE,
            3, 4, 4, 5);
        if ($self->verboseComponentObjList) {

            $checkButton->set_active(TRUE);
        }

        $self->addLabel($self->table, 'Set in profile',
            1, 3, 5, 6);
        my $checkButton2 = $self->addCheckButton($self->table, undef, FALSE, FALSE,
            3, 4, 5, 6);
        if ($self->session->currentWorld->verboseComponentList) {

            $checkButton2->set_active(TRUE);
        }

        $self->addLabel($self->table, 'Component list:',
            1, 4, 6, 7);
        my $textView = $self->addTextView($self->table, undef, undef, undef, FALSE,
            1, 4, 7, 10);
        my $buffer = $textView->get_buffer();
        foreach my $componentObj ($self->verboseComponentObjList) {

            push (@verboseList, $componentObj->name);
        }
        $buffer->set_text(join("\n", @verboseList));

        # Middle column
        $self->addLabel($self->table, '<u>Short verbose statements</u>',
            5, 8, 3, 4);
        $self->addLabel($self->table, 'Analysis complete',
            5, 7, 4, 5);
        my $checkButton3 = $self->addCheckButton($self->table, undef, FALSE, FALSE,
            7, 8, 4, 5);
        if ($self->shortComponentObjList) {

            $checkButton3->set_active(TRUE);
        }

        $self->addLabel($self->table, 'Set in profile',
            5, 7, 5, 6);
        my $checkButton4 = $self->addCheckButton($self->table, undef, FALSE, FALSE,
            7, 8, 5, 6);
        if ($self->session->currentWorld->shortComponentList) {

            $checkButton4->set_active(TRUE);
        }

        $self->addLabel($self->table, 'Component list:',
            5, 8, 6, 7);
        my $textView2 = $self->addTextView($self->table, undef, undef, undef, FALSE,
            5, 8, 7, 10);
        my $buffer2 = $textView2->get_buffer();
        foreach my $componentObj ($self->shortComponentObjList) {

            push (@shortList, $componentObj->name);
        }
        $buffer2->set_text(join("\n", @shortList));

        # Right column
        $self->addLabel($self->table, '<u>Brief statements</u>',
            9, 12, 3, 4);
        $self->addLabel($self->table, 'Analysis complete',
            9, 11, 4, 5);
        my $checkButton5 = $self->addCheckButton($self->table, undef, FALSE, FALSE,
            11, 12, 4, 5);
        if ($self->briefComponentObjList) {

            $checkButton5->set_active(TRUE);
        }

        $self->addLabel($self->table, 'Set in profile',
            9, 11, 5, 6);
        my $checkButton6 = $self->addCheckButton($self->table, undef, FALSE, FALSE,
            11, 12, 5, 6);
        if ($self->session->currentWorld->briefComponentList) {

            $checkButton6->set_active(TRUE);
        }

        $self->addLabel($self->table, 'Component list:',
            9, 12, 6, 7);
        my $textView3 = $self->addTextView($self->table, undef, undef, undef, FALSE,
            9, 12, 7, 10);
        my $buffer3 = $textView3->get_buffer();
        foreach my $componentObj ($self->briefComponentObjList) {

            push (@briefList, $componentObj->name);
        }
        $buffer3->set_text(join("\n", @briefList));

        # Special rule for the \'previous\' button: it returns to page 5
        $self->ivAdd('specialPreviousButtonHash', $self->currentPage, 4);

        return 12;
    }

    # Support functions

    sub resetDirs {

        # Called by $self->new or ->directionsPage
        # Sets (or resets) several direction IVs
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetDirs', @_);
        }

        $self->ivPoke('customPrimaryDirHash', $self->session->currentDict->primaryDirHash);
        $self->ivPoke('customPrimaryAbbrevHash', $self->session->currentDict->primaryAbbrevHash);

        return 1;
    }

    sub resetOtherWords {

        # Called by $self->new or ->dictionaryPage
        # Sets (or resets) word and phrase IVs
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
            $dictObj,
            @numberList,
            %numberHash, %newHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetOtherWords', @_);
        }

        # Import the current dictionary (for convenience)
        $dictObj = $self->session->currentDict;

        # Set/reset IVs
        $self->ivPoke('definiteList', $dictObj->definiteList);
        $self->ivPoke('indefiniteList', $dictObj->indefiniteList);
        $self->ivPoke('andList', $dictObj->andList);
        $self->ivPoke('orList', $dictObj->orList);

        # $self->numberList is a bit trickier. Import %numberHash, in the form
        #   $hash{word} = numeral
        %numberHash = $dictObj->numberHash;
        # Check every key-value pair, looking for the first occurence of each numeral from
        #   1 to 10
        OUTER: for (my $count = 1; $count <= 10; $count++) {

            INNER: foreach my $key (%numberHash) {

                my $value = $numberHash{$key};

                if (defined $value && $value == $count) {

                    if ($newHash{$value}) {

                        # We've already added this numeral
                        next INNER;

                    } else {

                        # Use this numeral
                        $newHash{$value} = undef;
                        push (@numberList, $key);
                        last INNER;
                    }
                }
            }
        }

        $self->ivPoke('numberList', @numberList);

        return 1;
    }

    sub analyseLines {

        # Called by $self->analysisPage to analyse a room statement gathered in the 'Capture' page
        # Analyses the room statement. First performs some checks, and returns an error message if
        #   any of the checks fail. Otherwise, calls $self->analyseComponent for each component in
        #   turn
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   Returns an empty list on improper arguments
        #   Otherwise, returns a list in the form (1, undef) on success, or (undef, failure_message)
        #       on failure

        my ($self, $check) = @_;

        # Local variables
        my (
            $count, $msg, $previous, $anchorLineIndex, $anchorComponent, $flag,
            @emptyList, @componentList, @componentObjList,
            %analysisHash,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->analyseLines', @_);
            return @emptyList;
        }

        # The statement's components are spread across up to $self->analysisLength lines
        # Divide these lines into groups, one for each component, by compiling a hash in the form
        #   $hash{component_name} = reference_to_list_of_lines
        # Store the hash as $self->analysisHash
        $self->collectComponentGroups();

        # For speed, import $self->analysisHash
        %analysisHash = $self->analysisHash;

        # Check 1: The wizard uses the first line of the first component containing exits as the
        #   the anchor line (the user can, of course, designate any part of the room statement as
        #   the anchor line by using the world profile's 'edit' window)
        # There must be exactly one (no more, no less) components containing exits
        $count = 0;
        foreach my $component (keys %analysisHash) {

            if (
                $component eq 'verb_exit' || $component eq 'brief_exit'
                || $component eq 'brief_title_exit' || $component eq 'brief_exit_title'
            ) {
                $count++;
            }
        }

        if (! $count) {

            $msg = "At least one line must be marked as containing exits (currently, no lines are"
                    . " marked as\nbelonging to one of the components that contains exits).",

            return (0, $msg);

        } elsif ($count > 1) {

            $msg = "No more than one component containing exits can be specified (you specified "
                    . $count . " components\nwhich contain exits).";

            return (0, $msg);
        }

        # Check 2: There must be either 0 or 1 components containing the room title (specifically,
        #   the user can't have both 'brief_title' and 'brief_title_exit' / 'brief_exit_title')
        $count = 0;
        foreach my $component (keys %analysisHash) {

            if (
                $component eq 'verb_title' || $component eq 'brief_title'
                || $component eq 'brief_title_exit' || $component eq 'brief_exit_title'
            ) {
                $count++;
            }
        }

        if ($count > 1) {

            $msg = "No more than one component containing the room title can be specified (you"
                    . " specified " . $count . "\ncomponents which contain a room title).";

            return (0, $msg);
        }

        # Check 3: The wizard requires that some components are a maximum of one line long (the user
        #   is free, once again, to specify any size in the world profile's 'edit' window)
        foreach my $component (keys %analysisHash) {

            my $listRef;

            if (
                $component eq 'verb_title' || $component eq 'brief_title'
                || $component eq 'brief_exit' || $component eq 'brief_title_exit'
                || $component eq 'brief_exit_title'
            ) {
                $listRef = $analysisHash{$component};

                if (@$listRef > 1) {

                    $msg = "Components which contain the room title cannot be longer than 1 line.",

                    return (0, $msg);
                }
            }
        }

        # Check 4: The wizard requires that most components are contiguous; i.e. you can't have the
        #   verbose description on lines 2, 3 and 8 (the user is free, once again, to specify
        #   non-contiguous components in the world profile's 'edit' window)
        # However, the 'outside_statement' and 'ignore_line' don't have to be contiguous
        foreach my $component (keys %analysisHash) {

            my ($listRef, $previousLine);

            # Two components are allowed to be split up...
            if ($component ne 'outside_statement' && $component ne 'ignore_line') {

                $listRef = $analysisHash{$component};

                foreach my $line (@$listRef) {

                    if (defined $previousLine && $line != ($previousLine + 1)) {

                        # The component is not contiguous
                        $msg = "Components can\'t be split up - for example, you can\'t have a"
                                . " description component on\nlines 2, 3, and 8. (Exception:"
                                . " \'ignore\' lines can be placed anywhere.)";
                        return (0, $msg);

                    } else {

                        $previousLine = $line;
                    }
                }
            }
        }

        # Check 5: the user may have used 'ignore_line' rather than 'outside_statement' at the
        #   beginning and end of the list. Convert the former to the latter
        $self->convertIgnoreLines();

        # Check 6: there must be no more than 2 'outside_component' groups - one starting at the
        #   first line, one ending at the last line. ('ignore_line' can be used anywhere, in any
        #   order)
        if (! $self->checkOutsideGroups()) {

            $msg = "You can\'t mark a line in the middle of the room statement as being outside it."
                    . " Try marking\nthem as lines to ignore, instead.";
            return (0, $msg);
        }

        # Get a list of components, in the order in which they occur
        foreach my $component ($self->bufferTypeList) {

            if (
                ! $previous                     # This is the first component
                || $component ne $previous      # This is the next component
            ) {
                push (@componentList, $component);
                $previous = $component;
            }
        }

        # Decide which line is going to be the anchor line (it's the first line of the first
        #   component containing exits)
        OUTER: for (my $line = 0; $line < $self->analysisLength; $line++) {

            my $component;

            if (defined $self->ivIndex('bufferObjList', $line)) {

                $component = $self->ivIndex('bufferTypeList', $line);

                if (
                    $component eq 'verb_exit' || $component eq 'brief_exit'
                    || $component eq 'brief_title_exit' || $component eq 'brief_exit_title'
                ) {
                    # This is the anchor line. $anchorLineIndex records its position in
                    #   $self->bufferObjList (not the number of the display buffer line itself)
                    $anchorLineIndex = $line;
                    $anchorComponent = $component;
                    last OUTER;
                }
            }
        }

        # For each component in turn, create a GA::Obj::Component object
        foreach my $component (@componentList) {

            my ($componentObj, $listRef);

            # Don't analyse the 'outside_statement' component, obviously
            if ($component ne 'outside_statement') {

                $listRef = $analysisHash{$component};

                ($componentObj, $msg) = $self->analyseComponent(
                    $anchorLineIndex,
                    $component,
                    @$listRef,
                );

                if (! $componentObj) {

                    return (undef, $msg);

                } else {

                    push (@componentObjList, $componentObj);
                }
            }
        }

        # Store the list of component objects
        if ($self->analysisType eq 'verbose') {
            $self->ivPoke('verboseComponentObjList', @componentObjList);
        } elsif ($self->analysisType eq 'short') {
            $self->ivPoke('shortComponentObjList', @componentObjList);
        } elsif ($self->analysisType eq 'brief') {
            $self->ivPoke('briefComponentObjList', @componentObjList);
        }

        # Analysis successful!
        return (1, undef);
    }

    sub analyseComponent {

        # Called by $self->analyseLines to analyse one or more lines comprising a single component
        # Analyses the lines. If successful, creates a new GA::Obj::Component object for the
        #   component and sets other IVs ready for them to be copied into the world profile. If not
        #   successful, returns an error message for ->analysisPage to display
        #
        # Expected arguments
        #   $anchorLineIndex    - The index of $self->bufferObjList that contains the buffer object
        #                           for the anchor line
        #   $component          - The component's type, e.g. 'verb_title'
        #   @indexList          - A list of of indexes in $self->bufferObjList, each one
        #                           corresponding to a GA::Buffer::Display object. Each index is in
        #                           the range 0 to ($self->analysisLength - 1)
        #
        # Return values
        #   Returns an empty list on improper arguments
        #   Otherwise, returns a list in the form (component_object, undef) on success, or
        #       (undef, failure_message) on failure

        my ($self, $anchorLineIndex, $component, @indexList) = @_;

        # Local variables
        my (
            $componentObj, $beforeAnchorFlag, $firstObj, $lastObj, $previousObj, $nextObj,
            $componentName, $matchFlag,
            @emptyList, @bufferObjList, @originalObjList, @tagList,
        );

        # Check for improper arguments
        if (! defined $anchorLineIndex || ! defined $component || ! @indexList) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->analyseComponent', @_);
            return @emptyList;
        }

        # Does this component occur before the anchor line?
        if ($indexList[-1] < $anchorLineIndex) {
            $beforeAnchorFlag = TRUE;
        } else {
            $beforeAnchorFlag = FALSE;      # Need defined value for a function call
        }

        # Get a list of the GA::Buffer::Display objects in this component
        foreach my $index (@indexList) {

            push (@bufferObjList, $self->ivIndex('bufferObjList', $index));
        }

        # If the component occurs before the anchor line, then we analyse the component's buffer
        #   objects in reverse order
        # (NB In some cases, we need the buffer objects in their original order, so we'll create a
        #   list for that, too)
        @originalObjList = @bufferObjList;
        if ($beforeAnchorFlag) {

            @bufferObjList = reverse @bufferObjList;
        }

        # For convenience, get the first and last buffer objects (which might be the same). In this
        #   context, 'first'/'last' mean 'the first/last buffer object to be analysed'
        $firstObj = $bufferObjList[0];
        $lastObj = $bufferObjList[-1];

        # Get the buffer object which precedes the component ('precedes' means 'the Locator task
        #   would analyse it before $firstObj'). If there is no such object, $previousObj is 'undef'
        if ($beforeAnchorFlag) {
            $previousObj = $self->session->ivShow('displayBufferHash', ($firstObj->number + 1));
        } else {
            $previousObj = $self->session->ivShow('displayBufferHash', ($firstObj->number - 1));
        }

        # Get the buffer object which follows the component ('follows' means 'the Locator task
        #   would analyse it after $lastObj'). If there is no such object, $nextObj is 'undef'
        if ($beforeAnchorFlag) {
            $nextObj = $self->session->ivShow('displayBufferHash', ($firstObj->number - 1));
        } else {
            $nextObj = $self->session->ivShow('displayBufferHash', ($firstObj->number + 1));
        }

        # A component of the same type could appear in two or all three of the types of room
        #   statement (verbose, short verbose and brief), and have different characteristics in
        #   each one. Therefore, give each component a unique name (not already in use by the
        #   world profile's component hash)
        $componentName = $self->setComponentName($component);

        # Create a new component object
        $componentObj = Games::Axmud::Obj::Component->new(
            $self->session,
            $self->session->currentWorld,
            $componentName,
            $component,
            TRUE,                           # Temporary component (can be made permanent later)
        );

        if (! $componentObj) {

            return (undef, "General component error");
        }

        # Configure the component, starting with its size. The wizard demands that six components
        #   have a fixed size; all others have an optional size
        if (
            $component eq 'verb_title' || $component eq 'brief_title' || $component eq 'brief_exit'
            || $component eq 'brief_title_exit' || $component eq 'brief_exit_title'
        ) {
            # Fixed size - 1 line
            $componentObj->ivPoke('size', 1);

        } elsif ($component eq 'verb_exit') {

            # ('verb_exit' components should be treated as single lines, by default)
            $componentObj->ivPoke('combineLinesFlag', TRUE);

            # If this component was the last one, or if the size of the component was one line
            #   (this will be the case nearly every time this wizard is used), assume that the
            #   component has a fixed size of 1
            if ((scalar @indexList) > 1) {

                $matchFlag = $self->checkVerbExitSize($beforeAnchorFlag, @indexList);
            }

            if ($matchFlag || (scalar @indexList) == 1) {

                # This component was the last one besides 'outside_statement' components (or the
                #   first one, if moving backwards)
                # Use a fixed size of 1
                $componentObj->ivPoke('size', 1);

            } else {

                # Use a minimum size of 1
                $componentObj->ivPoke('size', 0);
                $componentObj->ivPoke('minSize', 1);
            }

        } elsif ($component eq 'ignore_line') {

            # Fixed size - the number of lines specified by the user
            $componentObj->ivPoke('size', scalar @indexList);

        } else {

            # Use other IVs to find the size
            $componentObj->ivPoke('size', 0);

            # Set the minimum size. For optional components - those that might appear in the room
            #   statement, or might not, depending on the room - the minimum size is set to 0
            if (
                $component eq 'verb_content' || $component eq 'verb_special'
                || $component eq 'brief_content'
            ) {
                # Optional component
                $componentObj->ivPoke('minSize', 0);
            } else {
                $componentObj->ivPoke('minSize', 1);
            }
        }

        if (! $componentObj->size) {

            # The component object specifies several IVs for patterns and Axmud colour/style tags
            #   which mark the extent of the component. There's no way we can guess which patterns
            #   might appear in all of the world's room statements, but we can guess which tags are
            #   being used

            # If there are any colour/style tags used by $firstObj but not used in the preceding
            #   line, $previousObj...
            @tagList = $self->compareTags($firstObj, $previousObj);
            if (@tagList) {

                # Store them
                $componentObj->ivPoke('startTagList', @tagList);
            }

            # If there are any colour/style tags used by $lastObj but not used in the following
            #   line, $nextObj...
            @tagList = $self->compareTags($lastObj, $nextObj);
            if (@tagList) {

                # Store them
                $componentObj->ivPoke('stopBeforeNoTagList', @tagList);

            } else {

                # Conversely, if there are any colour/style tags used in the following line,
                #   $nextObj, but not used in $lastObj...
                @tagList = $self->compareTags($nextObj, $lastObj);
                if (@tagList) {

                    # Store them
                    $componentObj->ivPoke('stopBeforeTagList', @tagList);

                } else {

                    # Otherwise, for components before the anchor line, we'll have to assume that
                    #   they stop at the earliest-received line starting with a capital letter
                    if ($beforeAnchorFlag) {

                        $componentObj->ivPoke('upperCount', 1);

                    # For components at/after the anchor line, we'll have to assume that they
                    #   stop at the latest-received line containing no alphanumeric characters
                    } else {

                        $componentObj->ivPoke('stopBeforeMode', 'no_letter_num');
                    }
                }
            }
        }

        # Set the contents of ->profUpdateHash, which in turn is used by $self->saveChanges to
        #   update the world profile
        if ($component eq 'verb_exit') {

            my (
                $string, $msg, $exitCount, $subString,
                @list, @sortedExitList, @sortedPosnList, @extractedExitList,
                %exitPosnHash,
            );

            # Empty the temporary list of exits from previous analyses
            $self->ivEmpty('analysisExitList');

            # The 'verb_exit' component can consist of more than one line. If it does, usually it's
            #   because the world has split a long list of exits into two lines; recombine them
            #   into a single string
            $string = '';
            foreach my $bufferObj (@originalObjList) {

                if ($string) {
                    $string .= ' ' . $bufferObj->modLine;
                } else {
                    $string = $bufferObj->modLine;
                }
            }

            # Get a sorted list of recognised primary directions by length, largest first, and
            #   eliminate those directions which haven't been set (and are therefore 'undef')
            @list = $self->eliminateUndefsFromList(
                $self->ivValues('customPrimaryDirHash'),
                $self->ivValues('customPrimaryAbbrevHash'),
            );

            @sortedExitList = sort {(length $b) <=> (length $a)} (@list);

            # Find the position of each exit in the string. When an exit which matches one of the
            #   directions in @sortedExitList is found, add it to a hash; in this way, when we find
            #   the exit 'northeast', we can ignore the exits 'north' and 'east' found at the same
            #   position
            # The hash is in the form
            #   $exitPosnHash{offset} = exit_name
            %exitPosnHash = $self->extractExits($string, @sortedExitList);
            if (! %exitPosnHash) {

                $msg = "You marked a line as containing a list of exits, but no exits in recognised"
                        . " primary directions\nwere found on that line. Either try a different"
                        . " room, or go back to the first page and modify\nthe list of primary"
                        . " directions.";
                return (0, $msg);
            }

            # Otherwise, at least one exit was found. Sort the keys of %exitPosnHash so that we get
            #   a list of exits found, in the order in which they occured
            @sortedPosnList = sort {$a <=> $b} (keys %exitPosnHash);
            $exitCount = scalar (@sortedPosnList);

            # Also save the list of exit names (for display on the next page)
            foreach my $posn (@sortedPosnList) {

                push (@extractedExitList, $exitPosnHash{$posn});
            }

            $self->ivPush('analysisExitList', @extractedExitList);

            # Update $self->profUpdateHash as necessary
            if ($exitCount == 1) {

                my ($thisPosn, $thisExit, $pattern);

                # Assume that $string is in the form <start_text><exit><stop_text>
                $thisPosn = $sortedPosnList[0];
                $thisExit = $exitPosnHash{$thisPosn};  # e.g. 'north'

                # Convert $string into a regex in the form '^<start_text>(.*)<stop_text>'
                $pattern = '^' . quotemeta(substr($string, 0, $thisPosn)) . '(.*)'
                                . quotemeta(substr($string, ($thisPosn + length ($thisExit))));

                # Store the result
                if ($self->analysisType eq 'verbose') {

                    $self->profileUpdatePush('verboseAnchorPatternList', $pattern);
                    $self->ivAdd('profUpdateHash', 'verboseAnchorOffset', 1);

                } elsif ($self->analysisType eq 'short') {

                    $self->profileUpdatePush('shortAnchorPatternList', $pattern);
                    $self->ivAdd('profUpdateHash', 'shortAnchorOffset', 1);
                }

                # Convert $string into a regex in the form '^<start_text>', and remove any number
                #   words or numerals (e.g. convert 'There are six exits' to 'There are (.*) exits')
                $pattern = '^' . quotemeta(substr($string, 0, $thisPosn));
                $pattern = $self->processPattern($pattern);
                # Store the result
                $self->profileUpdatePush('verboseExitLeftMarkerList', $pattern);

                # Convert $string into a regex in the form '<stop_text>' and remove any number words
                #   or numerals
                $subString = substr($string, ($thisPosn + length ($thisExit)));
                $pattern = quotemeta($subString);
                $pattern = $self->processPattern($pattern);
                # If '<stop_text>' contains only empty space, use an empty string (if the pattern
                #   contains a space character, and one of the delimiters is also a space
                #   character, this confuses the Locator task)
                if (! ($subString =~ m/\S/)) {

                    $pattern = '';
                }

                # Store the result
                if ($pattern) {

                    $self->profileUpdatePush('verboseExitRightMarkerList', $pattern);
                }

            } else {

                my (
                    $startText, $lastPosn, $lastExit, $stopText, $pattern,
                    @delimList,
                );

                # Assume that $string is in the form
                #   <start_text><exit><delimiter><exit><delimiter><exit><stop_text>
                # Get <start_text> and <stop_text>
                $startText = substr($string, 0, $sortedPosnList[0]);
                $lastPosn = $sortedPosnList[-1];
                $lastExit = $exitPosnHash{$lastPosn};
                $stopText = substr($string, ($lastPosn + length ($lastExit)));

                # Get a list of <delimiter>s
                OUTER: for (my $count = 0; $count < ($exitCount - 1); $count++) {

                    my ($thisPosn, $thisExit, $nextPosn, $delim, $flag);

                    $thisPosn = $sortedPosnList[$count];
                    $thisExit = $exitPosnHash{$thisPosn};
                    $nextPosn = $sortedPosnList[$count + 1];

                    $delim = substr(
                        $string,
                        ($thisPosn + length($thisExit)),
                        ($nextPosn - $thisPosn - length($thisExit)),
                    );

                    # Check $delim against the delimiters already in @delimList. If it's not already
                    #   there, add it
                    INNER: foreach my $otherDelim (@delimList) {

                        if ($otherDelim eq $delim) {

                            $flag = TRUE;
                            last INNER;
                        }
                    }

                    if (! $flag) {

                        push (@delimList, $delim);
                    }
                }

                # Compile a regex in the form '^<start_text>(.*)<stop_text>'
                $pattern = '^' . quotemeta($startText) . '(.*)' . quotemeta($stopText);
                # To cope with a <start_text> part (or even a <stop_text> part) which is 'There are
                #   four obvious exits:', go through the pattern, removing any number words (or
                #   numerals!)
                $pattern = $self->processPattern($pattern);

                # Store the results
                if ($self->analysisType eq 'verbose') {

                    $self->profileUpdatePush('verboseAnchorPatternList', $pattern);
                    $self->ivAdd('profUpdateHash', 'verboseAnchorOffset', 1);

                } elsif ($self->analysisType eq 'short') {

                    $self->profileUpdatePush('shortAnchorPatternList', $pattern);
                    $self->ivAdd('profUpdateHash', 'shortAnchorOffset', 1);
                }

                # Compile regexes in the form '^start_text>' and '<stop_text>', and remove any
                #   number words or numerals (e.g. convert 'There are six exits' to
                #   'There are (.*) exits')
                # Then store the results
                $pattern = '^' . quotemeta($startText);
                $pattern = $self->processPattern($pattern);
                $self->profileUpdatePush('verboseExitLeftMarkerList', $pattern);

                $pattern = quotemeta($stopText);
                $pattern = $self->processPattern($pattern);
                # If '<stop_text>' contains only empty space, use an empty string (if the pattern
                #   contains a space character, and one of the delimiters is also a space
                #   character, this confuses the Locator task)
                if (! ($stopText =~ m/\S/)) {

                    $pattern = '';
                }

                if ($pattern) {

                    $self->profileUpdatePush('verboseExitRightMarkerList', $pattern);
                }

                $self->profileUpdatePushSort('verboseExitDelimiterList', @delimList);
            }

        } elsif (
            $component eq 'brief_exit'
            || $component eq 'brief_title_exit'
            || $component eq 'brief_exit_title'
        ) {
            my (
                $thisBufferObj, $string, $msg, $exitCount, $startText, $lastPosn, $lastExit,
                $stopText, $pattern,
                @list, @sortedExitList, @sortedPosnList, @extractedExitList, @delimList,
                %exitPosnHash,
            );

            # Empty the temporary list of exits from previous analyses
            $self->ivEmpty('analysisExitList');

            # The 'verb_exit' component can consist of more than one line, but the wizard requires
            #   that these three components must be all on line. For compatibility with the code
            #   above, extract the text of the line into a $string
            $thisBufferObj = $bufferObjList[0];
            $string = $thisBufferObj->modLine;

            # Get a sorted list of recognised primary directions by length, largest first, and
            #   eliminate those directions which haven't been set (and are therefore 'undef')
            # For the 'verb_exit' component, only non-abbreviated directions are expected; however,
            #   here we'll assume that both abbreviated and unabbreviated directions are possible
            @list = (
                $self->eliminateUndefsFromList($self->ivValues('customPrimaryDirHash')),
                $self->eliminateUndefsFromList($self->ivValues('customPrimaryAbbrevHash')),
            );

            @sortedExitList = sort {(length $b) <=> (length $a)} (@list);

            # Find the position of each exit in the string. When an exit which matches one of the
            #   directions in @sortedExitList is found, add it to a hash; in this way, when we find
            #   the exit 'ne', we can ignore the exits 'n' and 'e' found at the same position
            # The hash is in the form
            #   $exitPosnHash{offset} = exit_name
            %exitPosnHash = $self->extractExits($string, @sortedExitList);
            if (! %exitPosnHash) {

                $msg = "You marked a line as containing a list of exits, but no exits in recognised"
                        . " primary (abbreviated)\ndirections were found on that line. Either try a"
                        . " different room, or go back to the first page and\nmodify the list of"
                        . " primary abbreviated directions.";
                return (0, $msg);
            }

            # Otherwise, at least one exit was found. Sort the keys of %exitPosnHash so that we get
            #   a list of exits found, in the order in which they occured
            @sortedPosnList = sort {$a <=> $b} (keys %exitPosnHash);
            $exitCount = scalar (@sortedPosnList);

            # Also save the list of exit names (for display on the next page)
            foreach my $posn (@sortedPosnList) {

                push (@extractedExitList, $exitPosnHash{$posn});
            }

            $self->ivPush('analysisExitList', @extractedExitList);

            # Update $self->profUpdateHash as necessary. Assume that $string is in the form
            #   <start_text><exit><delimiter><exit><delimiter><exit><stop_text>
            # ...where <start_text> or <stop_text>, if present, can contain either the room title
            #   or another <delimiter>

            # Get <start_text> and <stop_text>
            $startText = substr($string, 0, $sortedPosnList[0]);
            $lastPosn = $sortedPosnList[-1];
            $lastExit = $exitPosnHash{$lastPosn};
            $stopText = substr($string, ($lastPosn + length ($lastExit)));

            # Get a list of <delimiter>s
            OUTER: for (my $count = 0; $count < ($exitCount - 1); $count++) {

                my ($thisPosn, $thisExit, $nextPosn, $delim, $flag);

                $thisPosn = $sortedPosnList[$count];
                $thisExit = $exitPosnHash{$thisPosn};
                $nextPosn = $sortedPosnList[$count + 1];

                $delim = substr(
                    $string,
                    ($thisPosn + length($thisExit)),
                    ($nextPosn - $thisPosn - length($thisExit)),
                );

                # Check $delim against the delimiters already in @delimList. If it's not already
                #   there, add it
                INNER: foreach my $otherDelim (@delimList) {

                    if ($otherDelim eq $delim) {

                        $flag = TRUE;
                        last INNER;
                    }
                }

                if (! $flag) {

                    push (@delimList, $delim);
                }
            }

            if ($component eq 'brief_exit') {

                # Compile a regex in the form '^<start_text>(.*)<stop_text>'
                $pattern = '^' . quotemeta($startText) . '(.*)' . quotemeta($stopText);
                # To cope with a <start_text> part (or even a <stop_text> part) which is 'There are
                #   four obvious exits:', go through the pattern, removing any number words (or
                #   numerals!)
                $pattern = $self->processPattern($pattern);

                # Store the results
                $self->profileUpdatePush('briefAnchorPatternList', $pattern);
                $self->ivAdd('profUpdateHash', 'briefAnchorOffset', 1);

                $self->profileUpdatePush('briefExitLeftMarkerList', '^' . quotemeta($startText));

                if ($stopText) {

                    $self->profileUpdatePush('briefExitRightMarkerList', quotemeta($stopText));
                }

                $self->profileUpdatePushSort('briefExitDelimiterList', @delimList);

            } else {

                # For the 'brief_title_exit' and 'brief_exit_title' components, we need to store
                #   the substrings and delimiter list temporarily so that $self->analysisPage can
                #   retrieve them
                $self->ivPoke('tempStartText', $startText);
                $self->ivPoke('tempStopText', $stopText);
                $self->ivPoke('tempDelimList', @delimList);
            }
        }

        # Analysis complete
        return ($componentObj, undef);
    }

    sub collectComponentGroups {

        # Called by $self->analyseLines
        # Compile the IV ->analysisHash by grouping lines of each component together
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my %hash;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->collectComponentGroups', @_);
        }

        # The statement's components are spread across up to $self->analysisLength lines
        # Divide these lines into groups, one for each component, by compiling a hash in the form
        #   $hash{component_name} = reference_to_list_of_lines
        #       e.g. $hash{'verb_descrip'} = [3, 4, 5]
        for (my $line = 0; $line < $self->analysisLength; $line++) {

            my ($component, $listRef);

            if (defined $self->ivIndex('bufferObjList', $line)) {

                $component = $self->ivIndex('bufferTypeList', $line);

                if (! exists $hash{$component}) {

                    $hash{$component} = [$line];

                } else {

                    $listRef = $hash{$component};
                    push (@$listRef, $line);

                    $hash{$component} = $listRef;
                }
            }
        }

        # Save the compiled list as an IV
        $self->ivPoke('analysisHash', %hash);

        return 1;
    }

    sub convertIgnoreLines {

        # Called by $self->analyseLines
        # The user may have used 'ignore_line' rather than 'outside_statement' at the beginning
        #   and end of the list. If so, convert the former to the latter
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertIgnoreLines', @_);
        }

        # Start from the beginning...
        OUTER: for (my $line = 0; $line < $self->analysisLength; $line++) {

            my $type = $self->ivIndex('bufferTypeList', $line);

            if ($type ne 'outside_statement' && $type ne 'ignore_line') {

                last OUTER;

            } elsif ($type eq 'ignore_line') {

                # Convert an 'ignore' to an 'outside'
                $self->ivReplace('bufferTypeList', $line, 'outside_statement');
            }
        }

        # Work back from the end...
        OUTER: for (my $line = ($self->analysisLength - 1); $line >= 0; $line--) {

            my $type = $self->ivIndex('bufferTypeList', $line);

            if ($type ne 'outside_statement' && $type ne 'ignore_line') {

                last OUTER;

            } elsif ($type eq 'ignore_line') {

                # Convert an 'ignore' to an 'outside'
                $self->ivReplace('bufferTypeList', $line, 'outside_statement');
            }
        }

        return 1;
    }

    sub checkOutsideGroups {

        # Called by $self->analyseLines
        # There must be no more than 2 'outside_statement' components - one starting at the first
        #   line, one ending at the last line ('ignore_line' can be used anywhere, in any order)
        # This function checks whether any 'outside_statement' components in the analysed lines
        #   comply with these rules
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the check fails (the 'outside_component' groups are
        #       unacceptable)
        #   1 if the check succeeds or if there are no 'outside_component' groups in the analysed
        #       lines

        my ($self, $check) = @_;

        # Local variables
        my ($line, $group1Start, $group1Stop, $group2Start, $group2Stop);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkOutsideGroups', @_);
        }

        if ($self->ivExists('analysisHash', 'outside_statement')) {

            $line = -1;

            do {

                $line++;

                if ($self->ivIndex('bufferTypeList', $line) eq 'outside_statement') {

                    # First line of group 1
                    if (! defined $group1Start) {

                        $group1Start = $line;

                    # First line of group 2
                    } elsif (defined $group1Stop && ! defined $group2Start) {

                        $group2Start = $line;

                    # Start of an illegal third group
                    } elsif (defined $group1Stop && defined $group2Stop) {

                        # Check has failed
                        return undef;
                    }

                } elsif (defined $group1Start && ! defined $group1Stop) {

                    # Last line of group 1
                    $group1Stop = ($line - 1);

                } elsif (defined $group2Start && ! defined $group2Stop) {

                    # Last line of group 2
                    $group2Stop = ($line - 1);
                }

            } until ($line >= ($self->analysisLength - 1));

            # Check for groups that extended all the way to the end
            if (defined $group1Start && ! defined $group1Stop) {

                $group1Stop = $self->analysisLength - 1;
            }

            if (defined $group2Start && ! defined $group2Stop) {

                $group2Stop = $self->analysisLength - 1;
            }

            # Check that 2nd group (if it exists) doesn't stop before the end
            if (defined $group2Start && $group2Stop != ($self->analysisLength - 1)) {

                # Check has failed
                return undef;
            }

            # Check that 1st group (if there are two) doesn't start after the beginning
            if (defined $group2Start && $group1Start != 0) {

                # Check has failed
                return undef;
            }
        }

        # Check successful
        return 1;
    }

    sub checkVerbExitSize {

        # Called by $self->analyseComponent when analysing a 'verb_exit' component
        # Checks whether this component is the last one (besides 'outside_statement' components),
        #   so that we can set the component's size
        #
        # Expected arguments
        #   $beforeAnchorFlag
        #       - Flag set to TRUE if this component occurs before the anchor line, FALSE if it
        #           occurs after the anchor line
        #   @indexList
        #       - A list of of indexes in $self->bufferObjList, each one corresponding to an
        #            GA::Buffer::Display object
        #
        # Return values
        #   'undef' on improper arguments or if there is another component after the 'verb_exit'
        #       component
        #   1 if the 'verb_exit' component is the last one (besides 'outisde_statement' components)

        my ($self, $beforeAnchorFlag, @indexList) = @_;

        # Local variables
        my ($lastIndex, $nextIndex, $step, $exitFlag, $thisIndex);

        # Check for improper arguments
        if (! defined $beforeAnchorFlag || ! @indexList) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkVerbExitSize', @_);
        }

        # Is this 'verb_exit' component the last one (besides 'outside_statement' components?)
        if ($beforeAnchorFlag) {

            $lastIndex = $indexList[0];
            $nextIndex = $lastIndex - 1;
            $step = -1;

        } else {

            $lastIndex = $indexList[-1];
            $nextIndex = $lastIndex + 1;
            $step = 1;
        }

        $thisIndex = $nextIndex;

        do {

            if ($thisIndex < 0 || $thisIndex >= scalar @indexList) {

                # This 'verb_exit' component is the last one (besides 'outside_statement'
                #   components)
                return 1;

            } elsif ($self->ivIndex('bufferTypeList', $thisIndex) ne 'outside_statement') {

                # This 'verb_exit' component is the not the last one
                $exitFlag = TRUE;

            } else {

                # Keep looking
                $thisIndex = $thisIndex + $step;
            }

        } until ($exitFlag);

        return undef;
    }

    sub processPattern {

        # Called by $self->analyseComponent
        # The calling function has compiled a pattern to represent the exit list, in the form
        #   ^<start_text><list_of_exits><stop_text>
        # To guard against the possibility that <start_text> might read something like 'There are
        #   four obvious exits', we need to remove any known number words (and numerals),
        #   replacing them with '(.*)'
        #
        # Expected arguments
        #   $pattern    - The pattern to process
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the processed pattern

        my ($self, $pattern, $check) = @_;

        # Local variables
        my (@numberList, @sortedList);

        # Check for improper arguments
        if (! defined $pattern || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->processPattern', @_);
        }

        # Get a list of words, 'one', 'two', 'three'...
        # If the user didn't define any number words in the first page, use the current dictionary
        if ($self->numberList) {

            @numberList = $self->numberList;

        } else {

            @numberList = $self->session->currentDict('numberHash');
        }

        # Sort the words/phrases in order of size, so that (for example) if $pattern contains the
        #   word 'nineteen', we don't remove the word 'nine' (leaving 'teen')
        @sortedList = sort {length($a) <=> length($b)} (@numberList);

        # Replace number words
        foreach my $item (@numberList) {

            $pattern =~ s/$item/(.*)/g;
        }

        # Replace numerals
        $pattern =~ s/\d+//g;

        return $pattern;
    }

    sub extractExits {

        # Called by $self->analyseComponent
        # Finds the position of each exit (which matches a recognised custom primary direction) in a
        #   string which represents one or more buffer lines in a single component
        # Adds the exits to a hash, and returns them
        #
        # Expected arguments
        #   $string   - The line of text to process
        #
        # Optional arguments
        #   @exitList   - A list of either custom primary directions ('northeast', 'north') or
        #                   custom abbreviated primary directions ('ne', n'), sorted by length,
        #                   largest first. If an empty list, no exits can be extracted (and an
        #                   empty list is returned)
        #
        # Return values
        #   An empty list on improper arguments or if $string contains none of the exits in
        #       @exitList
        #   Otherwise, returns a hash in the form
        #       $exitPosnHash{character_number} = direction_name

        my ($self, $string, @exitList) = @_;

        # Local variables
        my (
            @emptyList,
            %exitPosnHash,
        );

        # Check for improper arguments
        if (! defined $string) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->extractExits', @_);
            return @emptyList;
        }

        # In some worlds, the list of exits in the room statement is capitalised (e.g.
        #   'Exits: North South East'
        # Guard against this unfortunate tendency by making sure $string contains no capitals
        $string = lc($string);

        # Find the position of each exit in turn
        OUTER: foreach my $exit (@exitList) {

            my ($posn, $nextPosn, $exitFlag);

            do {

                my ($previousChar, $nextChar);

                if (defined $nextPosn) {

                    # Keep looking after the last position checked
                    $posn = index($string, $exit, $nextPosn);
                    $nextPosn = undef;

                } else {

                    # Start looking from the beginning of the line
                    $posn = index($string, $exit);
                }

                # Check that the exit is surrounded by non-alphanumeric characters
                if ($posn > 0) {

                    $previousChar = substr($string, ($posn - 1), 1);
                }

                if ($posn < (length ($string) - 1)) {

                    $nextChar = substr($string, ($posn + length($exit)), 1);
                }

                # If the exit is preceded or followed by an alphanumeric character, then assume
                #   we've found 'south' in the word 'southeast'
                if ($posn > -1) {

                    if (
                        (defined $previousChar && $previousChar =~ m/\w/)
                        || (defined $nextChar && $nextChar =~ m/\w/)
                    ) {
                        $nextPosn = $posn + 1;

                    } else {

                        # Found an exit. Add it to the hash...
                        $exitPosnHash{$posn} = $exit;
                        # ...and move on to the next exit
                        $exitFlag = TRUE;
                    }
                }

            } until ($posn < 0 || $exitFlag);
        }

        return %exitPosnHash;       # May be an empty hash
    }

    sub testExtractExits {

        # Called by $self->analysisPage, for brief room statements only, after the user clicks the
        #   'Test' button
        # Extracts a list of exits from a string, from which the room title and/or brief exit
        #   markers have already been removed
        #
        # Expected arguments
        #   $string     - The string to process
        #
        # Return values
        #   Am empty list on improper arguments
        #   Otherwise returns the list of exits

        my ($self, $string, $check) = @_;

        # Local variables
        my (@emptyList, @delimList, @tempArray, @returnArray);

        # Check for improper arguments
        if (! defined $string || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->testExtractExits', @_);
            return @emptyList;
        }

        # In some worlds, the list of exits in the room statement is capitalised (e.g.
        #   'Exits: North South East'
        # Guard against this unfortunate tendency by making sure $string contains no capitals
        $string = lc($string);

        # $self->tempDelimList contains a list of brief exit delimiters stored by the previous page.
        #   Sort the delimiter list by size, so that a delimiter which is just a comma isn't
        #   processed before a delimiter which is <, > - which would be ignored, if the comma
        #   had already been extracted
        @delimList = sort {length ($b) <=> length ($a)} ($self->tempDelimList);

        # Initialise @returnArray with the string containing the list of exits to process
        push (@returnArray, $string);
        foreach my $delim (@delimList) {

            # For each delimiter, move everything already in @returnArray into @tempArray
            # For each element now in @tempArray, split it into a list using the delimiter, and push
            #   it back into @returnArray
            # After each iteration, @returnArray will contain the same number of, or more, elements
            #   than it did before
            @tempArray = @returnArray;
            @returnArray = ();
            foreach my $item (@tempArray) {

                my @list = split ($delim, $item);
                push (@returnArray, @list);
            }
        }

        return @returnArray;
    }

    sub textViewSignalConnect {

        # Called by several functions
        # Extracts the data from a textview buffer (added with $self->addTextView). Splits it
        #   into lines of text, removes leading/trailing whitespace, and stores the result in one
        #   of this object's list IVs
        # (Code used is very similar to the ->signal_connect in GA::Generic::EditWin->addTextView)
        #
        # Expected arguments
        #   $buffer     - The Gtk2::TextView's buffer
        #   $iv         - The list IV in which the lines should be stored
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $buffer, $iv, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->textViewSignalConnect', @_);
        }

        $buffer->signal_connect('changed' => sub {

            my (
                $text,
                @list, @finalList,
            );

            $text = $axmud::CLIENT->desktopObj->bufferGetText($buffer);

            # Split the contents of the textview into a list of lines, separated by newline
            #   characters
            @list = split("\n", $text);
            # Remove any empty lines and leading/trailing whitespace
            foreach my $line (@list) {

                if ($line) {

                    $line =~ s/^\s*//;  # Remove leading whitespace
                    $line =~ s/\s*$//;  # Remove trailing whitepsace

                    (push @finalList, $line);
                }

            }

            # Set the IV
            $self->ivPoke($iv, @finalList);

            # Update the hash of changed IVs
            $self->ivAdd('ivChangeHash', $iv, TRUE);
        });

        return 1;
    }

    sub updateTextView {

        # Called by $self->analysisPage and later pages
        # Fills a Gtk2::TextView with the lines in a single component
        #
        # Expected arguments
        #   $textView   - The Gtk2::TextView to fill up
        #   $component  - The component to use - a key in $self->analysisHash
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $textView, $component, $check) = @_;

        # Local variables
        my (
            $textViewBuffer, $listRef,
            @bufferObjList, @stringList,
        );

        # Check for improper arguments
        if (! defined $textView || ! defined $component || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateTextView', @_);
        }

        $textViewBuffer = $textView->get_buffer();

        # If $component doesn't exist as a key in $self->analysisHash - meaning that the user
        #   didn't allocate any lines to this component - just make sure the textview is empty
        if (! $self->ivExists('analysisHash', $component)) {

            $textViewBuffer->set_text('');

        } else {

            $listRef = $self->ivShow('analysisHash', $component);

            foreach my $line (@$listRef) {

                my $textViewBufferObj = $self->ivIndex('bufferObjList', $line);

                push (@stringList, $textViewBufferObj->modLine);
            }

            $textViewBuffer->set_text(join("\n", @stringList));
        }

        return 1;
    }

    sub eliminateUndefsFromList {

        # Called by several functions which use values from key-value pairs in the hashes
        #   $self->customPrimaryDirHash and ->customPrimaryAbbrevHash, in which the values might be
        #   set to 'undef'
        # Given a list of elements, eliminates all those which are set to 'undef', and returns
        #   the modified list
        # e.g. in the list ('north', 'south', undef, undef, 'east'), returns
        #   ('north', 'south', 'east')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @list       - A list (usually of custom primary directions)
        #
        # Return values
        #   Returns the modified list

        my ($self, @list) = @_;

        # Local variables
        my @returnArray;

        # (No improper arguments to check)
        foreach my $item (@list) {

            if (defined $item) {

                push (@returnArray, $item);
            }
        }

        return @returnArray;
    }

    sub compareTags {

        # Called by $self->analyseComponent
        # Compares two GA::Buffer::Display objects. Returns a list of all the Axmud colour/style
        #   tags that appear in the first object, but not the second (ignores the dummy tags
        #   like 'bold', 'reverse_off' and 'attribs_off')
        #
        # Expected arguments
        #   $firstObj, $secondObj   - The two buffer objects to compare
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list of all the Axmud colour/style tags that appear in the first
        #       object, but not the second (ignoring dummy tags); may be an empty list

        my ($self, $firstObj, $secondObj, $check) = @_;

        # Local variables
        my (@emptyList, @returnArray);

        # Check for improper arguments
        if (! defined $firstObj || ! defined $secondObj || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->compareTags', @_);
            return @emptyList;
        }

        foreach my $tag ($firstObj->ivKeys('tagHash')) {

            if (
                ! $secondObj->ivExists('tagHash', $tag)
                && ! $axmud::CLIENT->ivExists('constDummyTagHash', $tag)
            ) {
                push (@returnArray, $tag);
            }
        }

        # Operation complete
        return @returnArray;
    }

    sub profileUpdatePush {

        # Called by $self->analysisPage and analyseComponent
        #
        # The IV $self->profUpdateHash holds any data with which the world profile must be updated,
        #   when $self->saveChanges is called. The hash is in the form:
        #   profUpdateHash{$iv} = scalar
        #   profUpdateHash{$iv} = list_reference
        #
        # This function adds a new key-value pair for a list IV (but not for a scalar IV).
        # If the key already exists, a list of values is added to 'list_reference', however,
        #   duplicate values are not added
        # If the key doesn't yet exist, a new 'list_reference' is created
        #
        # Expected arguments
        #   $iv         - A list IV (a key in $self->profUpdateHash)
        #
        # Optional arguments
        #   @itemList   - A list of items to add to the corresponding value in $self->profUpdateHash
        #                   (can be an empty list)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, @itemList) = @_;

        # Local variables
        my $listRef;

        # Check for improper arguments
        if (! defined $iv) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->profileUpdatePush', @_);
        }

        if ($self->ivExists('profUpdateHash', $iv)) {

            $listRef = $self->ivShow('profUpdateHash', $iv);
        }

        OUTER: foreach my $newItem (@itemList) {

            INNER: foreach my $oldItem (@$listRef) {

                if ($newItem eq $oldItem) {

                    # Don't add the duplicate
                    next OUTER;
                }
            }

            # Not a duplicate
            push (@$listRef, $newItem);
        }

        $self->ivAdd('profUpdateHash', $iv, $listRef);

        return 1;
    }

    sub profileUpdatePushSort {

        # Called by $self->analysisPage and analyseComponent
        # Companion to $self->profileUpdatePush, called for delimiter lists which need to be
        #   sorted, longest first
        #
        # Expected arguments
        #   $iv         - A list IV (a key in $self->profUpdateHash)
        #
        # Optional arguments
        #   @itemList   - A list of items to add to the corresponding value in $self->profUpdateHash
        #                   (can be an empty list)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, @itemList) = @_;

        # Local variables
        my $listRef;

        # Check for improper arguments
        if (! defined $iv) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->profileUpdatePush', @_);
        }

        if ($self->ivExists('profUpdateHash', $iv)) {

            $listRef = $self->ivShow('profUpdateHash', $iv);
        }

        OUTER: foreach my $newItem (@itemList) {

            INNER: foreach my $oldItem (@$listRef) {

                if ($newItem eq $oldItem) {

                    # Don't add the duplicate
                    next OUTER;
                }
            }

            # Not a duplicate
            push (@$listRef, $newItem);
        }

        @$listRef = sort {length($b) <=> length($a)} (@$listRef);
        $self->ivAdd('profUpdateHash', $iv, $listRef);

        return 1;
    }

    sub updateProfileList {

        # Called by $self->saveChanges
        #
        # Updates a world profile list IV with new values, preserving any existing ones. However,
        #   duplicate values are not added
        #
        # Expected arguments
        #   $profObj    - The current world profile
        #   $iv         - An IV in the current world profile
        #
        # Optional arguments
        #   @list       - A list of values to add to the list IV (if an empty list, no values are
        #                   added)
        #
        # Return values
        #   'undef' on improper arguments or if @list is empty
        #   1 otherwise

        my ($self, $profObj, $iv, @list) = @_;

        # Local variables
        my @profList;

        # Check for improper arguments
        if (! defined $profObj || ! defined $iv) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateProfileList', @_);
        }

        # If @list is empty, there's nothing to do
        if (! @list) {

            return undef;
        }

        # Import the contents of the profile's IV (for convenience)
        @profList = $profObj->$iv;

        # Update the list
        OUTER: foreach my $item (@list) {

            INNER: foreach my $profItem (@profList) {

                if ($item eq $profItem) {

                    # Don't add the duplicate
                    next OUTER;
                }
            }

            # Not a duplicate
            push (@profList, $item);
        }

        # Store the new contents of the IV
        $profObj->ivPoke($iv, @profList);

        return 1;
    }

    sub insertAnchor {

        # Called by $self->saveChanges
        #
        # When the world profile's ->verboseComponentList, ->shortComponentList or
        #   ->briefComponentList is rewritten, we must insert the special 'anchor' component just
        #   before the component containing exits (which acts as our anchor line)
        #
        # Expected arguments
        #   $profObj    - The current world profile
        #   $iv         - A list IV in the current world profile (one of the IVs listed above)
        #   $component  - The name of the component about to be inserted into the list IV
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $profObj, $iv, $component, $check) = @_;

        # Check for improper arguments
        if (! defined $profObj || ! defined $iv || ! defined $component || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->insertAnchor', @_);
        }

        if (
            $component eq 'verb_exit' || $component eq 'brief_exit'
            || $component eq 'brief_title_exit' || $component eq 'brief_exit_title'
        ) {
            $profObj->ivPush($iv, 'anchor');
        }

        return 1;
    }

    sub checkDelimiters {

        # Called by $self->saveChanges
        #
        # When the world profile's ->verboseExitDelimiterList IV is updated, we must check that none
        #   of its values are in ->verboseExitNonDelimiterList and, if so, they must be removed from
        #   the latter
        # We can do the same with ->briefExitDelimiterList and ->briefExitNonDelimiterList
        #
        # Expected arguments
        #   $profObj    - The current world profile
        #   $listIV     - Set to 'verboseExitDelimiterList' or 'briefExitDelimiterList'
        #   $nonListIV  - Set to 'verboseExitNonDelimiterList' or 'briefExitNonDelimiterList'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $profObj, $listIV, $nonListIV, $check) = @_;

        # Local variables
        my (@newList);

        # Check for improper arguments
        if (! defined $profObj || ! defined $listIV || ! defined $nonListIV || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkDelimiters', @_);
        }

        OUTER: foreach my $nonDelim ($profObj->$nonListIV) {

            INNER: foreach my $delim ($profObj->$listIV) {

                if ($delim eq $nonDelim) {

                    # Remove the non-delimiter by not adding it to @newList
                    next OUTER;
                }
            }

            # Preserve the non-delimiter by adding it to @newList
            push (@newList, $nonDelim);
        }

        # Update the IV
        $profObj->ivPoke($nonListIV, @newList);

        return 1;
    }

    sub setComponentName {

        # Called by $self->analyseComponent
        #
        # A component of the same type could appear in two or all three of the types of room
        #   statement (verbose, short verbose and brief), and have different characteristics in
        #   each one. Therefore, give each component a unique name (not already in use by the
        #   world profile's component hash)
        #
        # Expected arguments
        #   $type       - The component type, e.g. 'verb_descrip'
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the unique component name

        my ($self, $type, $check) = @_;

        # Local variables
        my ($count, $name);

        # Check for improper arguments
        if (! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setComponentName', @_);
        }

        # Try the name 'type_1', then 'type_2', 'type_3', etc
        # To prevent any (extremely unlikely) infinite loops, give up at 9999
        $count = 0;
        # Most pre-configured worlds use components whose names are the same as their type; if
        #   that's the case, the first new component is 'type_2' rather than 'type_1'
        if ($self->session->currentWorld->ivExists('componentHash', $type)) {

            $count = 1;
        }

        do {

            my $flag;

            $count++;
            $name = $type . '_' . $count;

            # Check that the world profile doesn't have an existing component with this name
            if ($self->session->currentWorld->ivExists('componentHash', $name)) {

                $flag = TRUE;
            }

            # Check that the wizard hasn't already created any components with this name for a
            #   different type of room description
            if (! $flag && $self->analysisType ne 'verbose') {

                OUTER: foreach my $componentObj ($self->verboseComponentObjList) {

                    if ($componentObj->name eq $name) {

                        $flag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $flag && $self->analysisType ne 'short') {

                OUTER: foreach my $componentObj ($self->shortComponentObjList) {

                    if ($componentObj->name eq $name) {

                        $flag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $flag && $self->analysisType ne 'brief') {

                OUTER: foreach my $componentObj ($self->briefComponentObjList) {

                    if ($componentObj->name eq $name) {

                        $flag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $flag) {

                # The component $name is available
                return $name;
            }

        } until ($count >= 9999);

        # Escape an (extremely unlikely) infinite loop by just using the name $type
        return $type;
    }

    sub updateContentComponent {

        # Called by $self->saveChanges
        #
        # $self->markerList contains the content marker patterns, e.g. 'is here' and 'are here'. The
        #   markers should also be added to components of the 'verb_content' and 'brief_content', by
        #   default (would be confusing for the user, if they had to do it themselves using the
        #   'edit' window)
        #
        # Expected arguments
        #   $componentObj   - The GA::Obj::Component to process (can be of any type, but only the
        #                       types 'verb_content' and 'brief_content' are modified)
        #
        # Return values
        #   'undef' on improper arguments or if no modifications are needed
        #   1 otherwise

        my ($self, $componentObj, $check) = @_;

        # Check for improper arguments
        if (! defined $componentObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateContentComponent', @_);
        }

        # Do nothing if $componentObj is of the wrong type, or if the list of content marker
        #   patterns in $self->markerList has been emptied
        if (
            ! $self->markerList
            || ($componentObj->type ne 'verb_content' && $componentObj->type ne 'brief_content')
        ) {
            return undef;
        }

        # Use the marker patterns as patterns which mark the start of the component
        $componentObj->ivPush('startPatternList', $self->markerList);
        # Any line which doesn't contain one of these patterns marks the end of the component
        $componentObj->ivPush('stopBeforeNoPatternList', $self->markerList);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub customPrimaryDirHash
        { my $self = shift; return %{$self->{customPrimaryDirHash}}; }
    sub customPrimaryAbbrevHash
        { my $self = shift; return %{$self->{customPrimaryAbbrevHash}}; }

    sub definiteList
        { my $self = shift; return @{$self->{definiteList}}; }
    sub indefiniteList
        { my $self = shift; return @{$self->{indefiniteList}}; }
    sub andList
        { my $self = shift; return @{$self->{andList}}; }
    sub orList
        { my $self = shift; return @{$self->{orList}}; }
    sub numberList
        { my $self = shift; return @{$self->{numberList}}; }
    sub markerList
        { my $self = shift; return @{$self->{markerList}}; }

    sub ivChangeHash
        { my $self = shift; return %{$self->{ivChangeHash}}; }

    sub componentTypeHash
        { my $self = shift; return %{$self->{componentTypeHash}}; }
    sub verboseComponentList
        { my $self = shift; return @{$self->{verboseComponentList}}; }
    sub shortComponentList
        { my $self = shift; return @{$self->{shortComponentList}}; }
    sub briefComponentList
        { my $self = shift; return @{$self->{briefComponentList}}; }

    sub bufferObjList
        { my $self = shift; return @{$self->{bufferObjList}}; }
    sub bufferTypeList
        { my $self = shift; return @{$self->{bufferTypeList}}; }

    sub analysisCount
        { $_[0]->{analysisCount} }
    sub analysisType
        { $_[0]->{analysisType} }
    sub analysisLength
        { $_[0]->{analysisLength} }
    sub analysisMinLength
        { $_[0]->{analysisMinLength} }
    sub analysisMaxLength
        { $_[0]->{analysisMaxLength} }
    sub analysisInc
        { $_[0]->{analysisInc} }
    sub analysisHash
        { my $self = shift; return %{$self->{analysisHash}}; }

    sub verboseComponentObjList
        { my $self = shift; return @{$self->{verboseComponentObjList}}; }
    sub shortComponentObjList
        { my $self = shift; return @{$self->{shortComponentObjList}}; }
    sub briefComponentObjList
        { my $self = shift; return @{$self->{briefComponentObjList}}; }

    sub profUpdateHash
        { my $self = shift; return %{$self->{profUpdateHash}}; }

    sub analysisExitList
        { my $self = shift; return @{$self->{analysisExitList}}; }
    sub tempStartText
        { $_[0]->{tempStartText} }
    sub tempStopText
        { $_[0]->{tempStopText} }
    sub tempDelimList
        { my $self = shift; return @{$self->{tempDelimList}}; }

    sub dirPageLang
        { $_[0]->{dirPageLang} }
    sub dictPageLang
        { $_[0]->{dictPageLang} }
    sub indexConvertHash
        { my $self = shift; return %{$self->{indexConvertHash}}; }
}

# Package must return true
1
