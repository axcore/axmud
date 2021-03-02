# Copyright (C) 2011-2021 A S Lewis
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
# Games::Axmud::Win::Internal
# Object handling 'internal' 'grid' windows ('grid' windows whose window type is 'main', 'protocol'
#   or 'custom'). Doesn't include 'map', 'fixed', 'external' or 'free' windows

{ package Games::Axmud::Win::Internal;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::GridWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Workspace->createGridWin and ->createSimpleGridWin
        # Creates an 'internal' 'grid' window (any window that can be placed on the workspace grid,
        #   and which is created/controlled by Axmud)
        #
        # Expected arguments
        #   $number     - Unique number for this window object
        #   $winType    - The window type, any of the keys in GA::Client->constGridWinTypeHash
        #                   (except 'external')
        #   $winName    - A name for the window:
        #                   $winType    $winName
        #                   --------    --------
        #                   main        main
        #                   protocol    Any string chosen by the protocol code (default value is
        #                                   'protocol')
        #                   custom      Any string chosen by the controlling code. For task windows,
        #                                   the name of the task (e.g. 'status_task', for other
        #                                   windows, default value is 'custom'
        #   $workspaceObj
        #               - The GA::Obj::Workspace object for the workspace in which this window is
        #                   created
        #
        # Optional arguments
        #   $owner      - The owner, if known ('undef' if not). Typically it's a GA::Session or a
        #                   task (inheriting from GA::Generic::Task); could also be GA::Client. iT
        #                   Should not be another window object (inheriting from GA::Generic::Win).
        #                   The owner should have its own ->del_winObj function which is called when
        #                   $self->winDestroy is called
        #   $session    - The owner's session. If $owner is a GA::Session, that session. If it's
        #                   something else (like a task), the task's session. If $owner is 'undef',
        #                   so is $session
        #   $workspaceGridObj
        #               - The GA::Obj::WorkspaceGrid object into whose grid this window has been
        #                   placed. 'undef' in $workspaceObj->gridEnableFlag = FALSE
        #   $areaObj    - The GA::Obj::Area (a region of a workspace grid zone) which handles this
        #                   window. 'undef' in $workspaceObj->gridEnableFlag = FALSE
        #   $winmap     - The ->name of the GA::Obj::Winmap object that specifies the Gtk3::Window's
        #                   layout when it is first created. If 'undef', a default winmap is used
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $winType, $winName, $workspaceObj, $owner, $session, $workspaceGridObj,
            $areaObj, $winmap, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $winType || ! defined $winName
            || ! defined $workspaceObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that the $winType is valid
        if (
            ! $axmud::CLIENT->ivExists('constGridWinTypeHash', $winType)
            || ($winType ne 'main' && $winType ne 'protocol' && $winType ne 'custom')
        ) {
            return $axmud::CLIENT->writeError(
                'Internal window error: invalid \'internal\' window type \'' . $winType . '\'',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => 'internal_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'grid',
            # The window type, any of the keys in GA::Client->constGridWinTypeHash (except
            #   'external')
            winType                     => $winType,
            # A name for the window:
            #       $winType    $winName
            #       --------    --------
            #       main        main
            #       protocol    Any string chosen by the protocol code (default value is 'protocol')
            #       custom      Any string chosen by the controlling code. For task windows, the
            #                       name of the task (e.g. 'status_task', for other windows, default
            #                       value is 'custom'
            winName                     => $winName,
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner, if known ('undef' if not). Typically it's a GA::Session or a task
            #   (inheriting from GA::Generic::Task); could also be GA::Client. It should not be
            #   another window object (inheriting from GA::Generic::Win). The owner must have its
            #   own ->del_winObj function which is called when $self->winDestroy is called
            owner                       => $owner,
            # The owner's session ('undef' if no owner). If ->owner is a GA::Session, that session.
            #   If it's something else (like a task), the task's sesssion. If ->owner is 'undef', so
            #   is ->session
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk3::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk3::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk3::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk3 window itself is visible (after a call to
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

            # The container widget into which all other widgets are packed (usually a Gtk3::VBox or
            #   Gtk3::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,

            # Standard IVs for 'grid' windows

            # The GA::Obj::WorkspaceGrid object into whose grid this window has been placed. 'undef'
            #   in $workspaceObj->gridEnableFlag = FALSE
            # For 'main' windows only, $self->setVisibleSession changes the value of this IV every
            #   time the visible session changes
            workspaceGridObj            => $workspaceGridObj,
            # The GA::Obj::Area object for this window. An area object is a part of a zone's
            #   internal grid, handling a single window (this one). Set to 'undef' in
            #   $workspaceObj->gridEnableFlag = FALSE
            areaObj                     => $areaObj,
            # For pseudo-windows (in which a window object is created, but its widgets are drawn
            #   inside a GA::Table::PseudoWin table object), the table object created. 'undef' if
            #   this window object is a real 'grid' window
            # NB 'main' windows can't be pseudo-windows, but 'protocol' and 'custom' windows can
            pseudoWinTableObj           => undef,
            # The ->name of the GA::Obj::Winmap object that specifies the Gtk3::Window's layout when
            #   it is first created. If 'undef', a default winmap is used
            winmap                      => $winmap,

            # IVs for 'internal' windows

            # Hash of strip objects (inheriting from GA::Generic::Strip) currently packed into
            #   $self->packingBox. Hash in the form
            #       $stripHash{number} = blessed_reference_to_strip_object
            stripHash                   => {},
            # A hash of the first instance of each type of strip object that was packed into
            #   $self->packingBox and is still there (a subset of $self->stripHash)
            # For 'jealous' strip objects, we can use this hash to find a strip object of a
            #   particular type quickly. For other strip, we can use this hash to treat the first
            #   instance of a particular type as the default one
            # Hash in the form
            #   $firstStripHash{object_class} = blessed_reference_to_strip_object
            firstStripHash              => {},
            # Number of strip objects ever created for this window (used to give every strip object
            #   a number unique to the window)
            stripCount                  => 0,
            # A list of strip objects in the order in which they were packed into the window (the
            #   order in which they were created by $self->drawWidgets or the order in which they
            #   were re-packed by $self->redrawWidgets, ->addStripObj, ->hideStripObj etc)
            stripList                   => [],
            # A shortcut to the compulsory GA::Strip::Table object (also stored as a value in
            #   $self->stripHash)
            tableStripObj               => undef,
            # Leave a small gap between strip objects
            stripSpacingPixels          => 2,

            # Other IVs

            # If GA::CLIENT->shareMainWinFlag = TRUE, all sessions share the same default pane
            #   object (GA::Table::Pane) in a single shared 'main' window. In that default pane
            #   object, only one session's default textview object is visible; that session is the
            #   visible session
            # If GA::Client->shareMainWinFlag = FALSE, the GA::Session which controls this 'main'
            #   window
            # In both cases, set to 'undef' for windows that aren't 'main' windows or if there are
            #   no sessions running at all
            visibleSession              => undef,

            # Whenever some of other Axmud function wants to set (or reset) the text used in the
            #    the GA::Strip::ConnectInfo strip object, it calls $self->setHostLabel and/or
            #   ->setTimeLabel. The text is stored here so it's available immediately, if the strip
            #   object is brought into existence; if the strip object already exists, it is updated
            hostLabelText               => '',
            timeLabelText               => '',

            # Flags capturing keypresses. When these flags are TRUE, the key is held down; they're
            #   set to FALSE when the key is released (or when this window loses focus)
            # Flags set by $self->setKeyPressEvent and reset by ->setKeyReleaseEvent
            ctrlKeyFlag                 => FALSE,
            shiftKeyFlag                => FALSE,
            altKeyFlag                  => FALSE,
            altGrKeyFlag                => FALSE,
            # Flag set to FALSE if none of the CTRL, SHIFT, ALT and ALT-GR keys are held down; set
            #   to TRUE if one of those keys is held down
            modifierKeyFlag             => FALSE,

            # The actual window size (in pixels). $self->winEnable sets up a ->signal_connect to
            #   react when the window size changes, but the same ->signal_connect fires when (for
            #   example) text is written to a Gtk3::TextView
            # The new size is stored in these IVs every time the ->signal_connect fires, so we can
            #   tell if the window's actual size has changed, or not
            actualWinWidth              => undef,
            actualWinHeight             => undef,
            # A flag set to TRUE when the window is maximised, then set back to FALSE when it is
            #   unmaximised. Required for drawing gauges correctly
            maximisedFlag               => FALSE,
            # A flag set to TRUE when the window receives keyboard focus, then back to FALSE when it
            #   loses the focus
            focusFlag                   => FALSE,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

    sub winSetup {

        # Called by GA::Obj::Workspace->createGridWin or ->createSimpleGridWin
        # Creates the Gtk3::Window itself
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $title      - The window title. If 'undef' or an empty string, a default title will be
        #                   used
        #   $listRef    - Reference to a list of functions to call, just after the Gtk3::Window is
        #                   created (can be used to set up further ->signal_connects, if this
        #                   window needs them)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be opened
        #   1 on success

        my ($self, $title, $listRef, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winSetup', @_);
        }

        # Don't create a new window, if it already exists
        if ($self->enabledFlag) {

            return undef;
        }

        # Create the Gtk3::Window
        my $winWidget = Gtk3::Window->new('toplevel');
        if (! $winWidget) {

            return undef;

        } else {

            # Store the IV now, as subsequent code needs it
            $self->ivPoke('winWidget', $winWidget);
            $self->ivPoke('winBox', $winWidget);
        }

        # Set up ->signal_connects (other ->signal_connects are set up in the call to
        #   $self->winEnable() )
        $self->setDeleteEvent();            # 'delete-event'
        $self->setKeyPressEvent();          # 'key-press-event'
        $self->setKeyReleaseEvent();        # 'key-release-event'
        # Set up ->signal_connects specified by the calling function, if any
        if ($listRef) {

            foreach my $func (@$listRef) {

                $self->$func();
            }
        }

        # Set the window title. If $title wasn't specified, use a suitable default title
        if (! $title) {

            if ($self->winType eq 'main') {

                $title = $axmud::SCRIPT;

            } elsif ($self->winName) {

                $title = $self->winName;

            } else {

                # Emergency fallback - $self->winName should be set
                $title = 'Untitled window';
            }
        }

        $winWidget->set_title($title);

        # Set the window's default size and position (this will almost certainly be changed before
        #   the call to $self->winEnable() )
        if ($self->winType eq 'main') {

            $winWidget->set_default_size(
                $axmud::CLIENT->customMainWinWidth,
                $axmud::CLIENT->customMainWinHeight,
            );

            $winWidget->set_border_width($axmud::CLIENT->constMainBorderPixels);

            # When workspace grids are disabled, 'main' windows should appear in the middle of the
            #   desktop
            if (! $self->workspaceObj->gridEnableFlag) {

                $winWidget->set_position('center');
            }

        } else {

            $winWidget->set_default_size(
                $axmud::CLIENT->customGridWinWidth,
                $axmud::CLIENT->customGridWinHeight,
            );

            $winWidget->set_border_width($axmud::CLIENT->constGridBorderPixels);
        }

        # Set the icon list for this window
        $iv = $self->winType . 'WinIconList';
        $winWidget->set_icon_list($axmud::CLIENT->desktopObj->{$iv});

        # Draw the widgets used by this window
        if (! $self->drawWidgets()) {

            return undef;
        }

        # The calling function can now move the window into position, before calling
        #   $self->winEnable to make it visible, and to set up any more ->signal_connects()
        return 1;
    }

    sub winEnable {

        # Called by GA::Obj::Workspace->createGridWin or ->createSimpleGridWin
        # After the Gtk3::Window has been setup and moved into position, makes it visible and calls
        #   any further ->signal_connects that must be not be setup until the window is visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $listRef    - Reference to a list of functions to call, just after the Gtk3::Window is
        #                   created (can be used to set up further ->signal_connects, if this
        #                   window needs them)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $listRef, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

#        # For windows about to be placed on a grid, briefly minimise the window so it doesn't
#        #   appear in the centre of the desktop before being moved to its correct workspace, size
#        #   and position
#        if ($self->workspaceGridObj && $self->winWidget eq $self->winBox) {
#
#            $self->minimise();
#        }

        # Set up ->signal_connects that must not be set up until the window is visible
        $self->setConfigureEvent();         # 'configure-event'
        $self->setWindowStateEvent();       # 'window-state-event'
        $self->setFocusInEvent();           # 'focus-in-event'
        $self->setFocusOutEvent();          # 'focus-out-event'
        # Set up ->signal_connects specified by the calling function, if any
        if ($listRef) {

            foreach my $func (@$listRef) {

                $self->$func();
            }
        }

        return 1;
    }

    sub winDestroy {

        # Called by GA::Obj::WorkspaceGrid->stop or by any other function
        # Informs the window's strip objects of their imminent demise, informs the parent workspace
        #   grid (if this 'grid' window is on a workspace grid) and the desktop object, and then
        #   destroys the Gtk3::Window (if it is open)
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

        # Inform this window's strip objects of their imminent demise (in the order in which they
        #   were created
        foreach my $stripObj (sort {$a->number <=> $b->number} ($self->ivValues('stripHash'))) {

            $stripObj->objDestroy();
        }

        # Close any 'free' windows for which this window is a parent
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Inform the parent workspace grid object (if any)
        if ($self->workspaceGridObj) {

            $self->workspaceGridObj->del_gridWin($self);
        }

        # Inform the desktop object
        $axmud::CLIENT->desktopObj->del_gridWin($self);

        # Destroy the Gtk3::Window
        eval { $self->winBox->destroy(); };
        if ($@) {

            # Window can't be destroyed
            return undef;

        } else {

            $self->ivUndef('winWidget');
            $self->ivUndef('winBox');
        }

        # Inform the ->owner, if there is one
        if ($self->owner) {

            $self->owner->del_winObj($self);
        }

        return 1;
    }

    sub winDisengage {

        # Called by GA::Obj::Desktop->removeSessionWindows and GA::Obj::WorkspaceGrid->stop
        # Removes this window object from its workspace grid, but does not close the window
        # Should not be called, in general
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $session    - When called by the functions listed above, the GA::Session which is
        #                   closing; otherwise 'undef'
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be disengaged
        #   1 on success

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDisengage', @_);
        }

        # Close any 'free' windows for which this window is a parent (but not when a session is
        #   closing; in that case, only close 'free' windows connected to that session)
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            if (! $session || ($winObj->session && $winObj->session eq $session)) {

                $winObj->winDestroy();
            }
        }

        # Inform the parent workspace grid object (if any)
        if ($self->workspaceGridObj) {

            $self->workspaceGridObj->del_gridWin($self);
        }

        # Update IVs
        $self->ivUndef('workspaceGridObj');
        $self->ivUndef('areaObj');
        $self->ivUndef('session');
        if ($self->owner && $session && $self->owner eq $session) {

            $self->ivUndef('owner');
        }

        if ($self->visibleSession && $session && $self->visibleSession eq $session) {

            # Don't close tabs - assume that GA::Session->close is about to apply a new winmap
            $self->ivUndef('visibleSession');
        }

        return 1;
    }

#   sub winShowAll {}           # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup (also by $self->resetWinmap)
        # Sets up the Gtk3::Window by drawing the strip objects and table objects specified by
        #   $self->winmap (the name of a GA::Obj::Winmap object)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the winmap can't be found or if any of the widgets are
        #       not drawn
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $winmap, $winmapObj, $matchFlag, $count,
            @initList, @objList, @winzoneList,
            %checkHash,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # This function shouldn't be called by anything but $self->winSetup, but reset IVs
        #   anyway, just in case
        $self->ivUndef('packingBox');
        $self->ivEmpty('stripHash');
        $self->ivEmpty('firstStripHash');
        $self->ivPoke('stripCount', 0);
        $self->ivEmpty('stripList');
        $self->ivUndef('tableStripObj');

        # If no winmap was specified, use a default one
        if (! $self->winmap) {

            if ($self->winType eq 'main') {

                if ($axmud::CLIENT->activateGridFlag) {
                    $winmap = $axmud::CLIENT->defaultEnabledWinmap;
                } else {
                    $winmap = $axmud::CLIENT->defaultDisabledWinmap;
                }

            } else {

                $winmap = $axmud::CLIENT->defaultInternalWinmap;
            }

        } else {

            $winmap = $self->winmap;
        }

        $winmapObj = $axmud::CLIENT->ivShow('winmapHash', $winmap);
        if (! $winmapObj) {

            return undef;

        } else {

            # (Set this IV for the first time)
            $self->ivPoke('winmap', $winmapObj->name);
        }

        # Create a packing box
        my $packingBox;
        if ($winmapObj->orientation eq 'top' || $winmapObj->orientation eq 'bottom') {
            $packingBox = Gtk3::VBox->new(FALSE, 0);
        } else {
            $packingBox = Gtk3::HBox->new(FALSE, 0);
        }

        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # Update IVs immediately
        $self->ivPoke('packingBox', $packingBox);

        # Check the list of strip objects specified by the winmap. It must contain the compulsory
        #   GA::Strip::Table object; if not, add that object to the beginning of the list (so it
        #   appears first; normally at the top of the window)
        @initList = $winmapObj->stripInitList;
        if (@initList) {

            do {

                my ($packageName, $hashRef);

                $packageName = shift @initList;
                $hashRef = shift @initList;

                if ($packageName eq 'Games::Axmud::Strip::Table') {

                    $matchFlag = TRUE;
                }

            } until ($matchFlag || ! @initList);
        }

        @initList = $winmapObj->stripInitList;
        if (! $matchFlag) {

            unshift(@initList, 'Games::Axmud::Strip::Table');
        }

        # Add each strip object in turn
        $count = 0;
        do {

            my ($packageName, $hashRef, $stripObj, $spacing);

            $packageName = shift @initList;
            $hashRef = shift @initList;

            $count++;

            # Strip objects must inherit from GA::Generic::Strip and must exist (in the case of
            #   strip objects loaded from a plugin)
            if (
                $packageName =~ m/^Games\:\:Axmud\:\:Strip\:\:/
                && $axmud::CLIENT->ivExists('customStripHash', $packageName)
            ) {
                $stripObj = $packageName->new($self->stripCount, $self, %$hashRef);
                if ($stripObj) {

                    # Some strip objects are 'jealous' (only one can be opened per window)
                    if ($stripObj->jealousyFlag) {

                        # If another strip object of this type has already been created, discard the
                        #   newest one
                        if (exists $checkHash{$packageName}) {

                            $stripObj = undef;
                        }
                    }

                    # Some strip objects can't be added in Axmud blind mode
                    if ($stripObj && ! $stripObj->blindFlag && $axmud::BLIND_MODE_FLAG) {

                        $stripObj = undef;
                    }

                    # This strip object can be added
                    if ($stripObj && $stripObj->objEnable($winmapObj)) {

                        $checkHash{$packageName} = undef;

                        if ($stripObj->packingBox) {

                            if ($stripObj->allowFocusFlag) {
                                $stripObj->packingBox->set_can_focus(TRUE);
                            } else {
                                $stripObj->packingBox->set_can_focus(FALSE);
                            }
                        }

                        # Update IVs
                        $self->ivIncrement('stripCount');
                        $self->ivPush('stripList', $stripObj);
                        $self->ivAdd('stripHash', $stripObj->number, $stripObj);
                        if (! $self->ivExists('firstStripHash', $stripObj->_objClass)) {

                            $self->ivAdd('firstStripHash', $stripObj->_objClass, $stripObj);
                        }

                        if (
                            $packageName eq 'Games::Axmud::Strip::Table'
                            && ! $self->tableStripObj
                        ) {
                            $self->ivPoke('tableStripObj', $stripObj);
                        }

                        # Set the spacing between this strip object and adjacent ones
                        if (! $stripObj->spacingFlag || $count == 1 || ! @initList) {
                            $spacing = 0;
                        } else {
                            $spacing = $self->stripSpacingPixels;
                        }

                        # Add the strip object to the packing box
                        if ($stripObj->visibleFlag) {

                            if (
                                $winmapObj->orientation eq 'top'
                                || $winmapObj->orientation eq 'left'
                            ) {
                                $packingBox->pack_start(
                                    $stripObj->packingBox,
                                    $stripObj->expandFlag,
                                    $stripObj->fillFlag,
                                    $spacing,
                                );

                            } else {

                                $packingBox->pack_end(
                                    $stripObj->packingBox,
                                    $stripObj->expandFlag,
                                    $stripObj->fillFlag,
                                    $spacing,
                                );
                            }
                        }

                        # Inform all existing strip objects of this strip object's birth
                        foreach my $otherStripObj ($self->stripList) {

                            if ($stripObj ne $otherStripObj) {

                                $stripObj->notify_addStripObj($otherStripObj);
                            }
                        }
                    }
                }
            }

        } until (! @initList);

        # Now draw table objects on the GA::Strip::Table, using the layout specified by the winmap's
        #   winzones. We assume that the winmap has already checked that its winzones have valid
        #   sizes and don't overlap each other
        @winzoneList = sort {$a->number <=> $b->number} ($winmapObj->ivValues('zoneHash'));
        foreach my $winzoneObj (@winzoneList) {

            $self->tableStripObj->addTableObj(
                $winzoneObj->packageName,
                $winzoneObj->left,
                $winzoneObj->right,
                $winzoneObj->top,
                $winzoneObj->bottom,
                $winzoneObj->objName,
                $winzoneObj->initHash,
            );
        }

        # Sensitise/desensitise widgets according to current conditions
        $self->restrictMenuBars();
        $self->restrictToolbars();

        return 1;
    }

    sub redrawWidgets {

        # Can be called by anything
        # Resets the Gtk3::Window by re-packing the strip objects in $self->stripList
        # When called by $self->addStripObj, the new strip object will be packed for the first time.
        #   When called by $self->removeStripObj, the removed strip object won't be packed at all
        #
        # NB This is a legacy function that probably should not be called at all. Due to Gtk
        #   performance issues, it's nearly always better to call $self->hideStripObj,
        #   ->revealStripObj or ->replaceStripObj instead
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $winmapObj, $gaugeStripObj,
            @modList,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->redrawWidgets', @_);
        }

        # Get the winmap object specified by $self->winmap, or a default winmap, if $self->winmap
        #   is 'undef'
        $winmapObj = $self->getWinmap();

        # Empty the packing box of existing strips
        foreach my $child ($self->packingBox->get_children()) {

            $self->packingBox->remove($child);
        }

        # Get a list of existing strips that are actually visible
        foreach my $stripObj ($self->stripList) {

            if ($stripObj->visibleFlag) {

                push (@modList, $stripObj);
            }
        }

        # Re-pack all visible strips, leaving a gap between strips that aren't at the beginning or
        #   end of the list
        if (@modList) {

            for (my $count = 0; $count < (scalar @modList); $count++) {

                my ($stripObj, $spacing);

                $stripObj = $modList[$count];
                if (! $stripObj->spacingFlag || $count == 0 || $count == (scalar @modList - 1)) {
                    $spacing = 0;
                } else {
                    $spacing = $self->stripSpacingPixels;
                }

                if (
                    $winmapObj->orientation eq 'top'
                    || $winmapObj->orientation eq 'left'
                ) {
                    $self->packingBox->pack_start(
                        $stripObj->packingBox,
                        $stripObj->expandFlag,
                        $stripObj->fillFlag,
                        $spacing,
                    );

                } else {

                    $self->packingBox->pack_end(
                        $stripObj->packingBox,
                        $stripObj->expandFlag,
                        $stripObj->fillFlag,
                        $spacing,
                    );
                }
            }
        }

        # Sensitise/desensitise widgets according to current conditions
        $self->restrictMenuBars();
        $self->restrictToolbars();

        # Any Gtk3::TextViews will now be using the colours of the most recently-created
        #   Gtk3::TextView, not the colours that we want them to use. Update colours for all pane
        #   objects (GA::Table::Pane) before the forthcoming call to ->winShowAll
        $self->updateColourScheme(undef, TRUE);

        # Make everything visible
        $self->winShowAll($self->_objClass . '->redrawWidgets');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->redrawWidgets');

        # Adding/removing widgets upsets the position of the scrollbar in each tab's textview.
        #   Make sure all the textviews are scrolled to the bottom
        $self->rescrollTextViews();

        # Redraw any visible gauges, otherwise the gauge box will be visible, but the gauges
        #   themselves will have disappeared
        $gaugeStripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::GaugeBox');
        if ($gaugeStripObj && $gaugeStripObj->visibleFlag) {

            $gaugeStripObj->updateGauges();
            # (Need to call this a second time, or the re-draw doesn't work...)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->redrawWidgets');
        }

        return 1;
    }

    # ->signal_connects

    sub setDeleteEvent {

        # Called by $self->winSetup
        # Set up a ->signal_connect to watch out for the user manually closing the 'internal' window
        # If it's a 'main' window and there are no 'main' windows left, halt the client
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setDeleteEvent', @_);
        }

        if ($self->winType eq 'main' && $axmud::CLIENT->shareMainWinFlag) {

            $self->winBox->signal_connect('delete-event' => sub {

                # Prompt the user for confirmation, if required
                if (! $self->checkConnectedSessions()) {

                    # Don't close the 'main' window
                    return 1;
                }

                # Inform this window's strip objects of their imminent demise (in the order in which
                #   they were created
                foreach my $stripObj (
                    sort {$a->number <=> $b->number} ($self->ivValues('stripHash'))
                ) {
                    $stripObj->objDestroy();
                }

                # Close any 'free' windows for which this window is a parent
                foreach my $winObj ($self->ivValues('childFreeWinHash')) {

                    $winObj->winDestroy();
                }

                # Inform the parent workspace grid object (if any)
                if ($self->workspaceGridObj) {

                    $self->workspaceGridObj->del_gridWin($self);
                }

                # Inform the desktop object
                $axmud::CLIENT->desktopObj->del_gridWin($self);

                # Halt the client
                $axmud::CLIENT->stop();

                # Allow Gtk3 to close the window directly
                return undef;
            });

        } else {

            $self->winBox->signal_connect('delete-event' => sub {

                # Prompt the user for confirmation, if required
                if ($self->winType eq 'main' && ! $self->checkConnectedSessions()) {

                    # Don't close the 'main' window
                    return 1;
                }

                # Prevent Gtk3 from taking action directly. Instead redirect the request to
                #   $self->winDestroy, which does things like resetting a portion of the workspace
                #   grid, as well as actually destroying the window
                return $self->winDestroy();
            });
        }

        return 1;
    }

    sub setKeyPressEvent {

        # Called by $self->winSetup
        # Set up a ->signal_connect to watch out for certain key presses
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the ->signal_connect doesn't interfere with the key
        #       press
        #   1 if the ->signal_connect does interfere with the key press, or when the
        #       ->signal_connect is first set up

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setKeyPressEvent', @_);
        }

        $self->winBox->signal_connect('key-press-event' => sub {

            my ($widget, $event) = @_;

            # Local variables
            my (
                $keycode, $standard, $string, $directFlag, $stripObj, $paneObj, $tabObj,
                $splitScreenMode, $textView, $slice, $clipboard, $vAdjust, $high, $length,
                $modValue, $entryText, $bufferObj, $startIter, $endIter,
                @list,
            );

            # Get the system keycode for this keypress
            $keycode = Gtk3::Gdk::keyval_name($event->keyval);
            # Translate it into a standard Axmud keycode
            $standard = $axmud::CLIENT->reverseKeycode($keycode);

            # If it's a CTRL, SHIFT, ALT or ALT-GR keypress, set IVs
            if ($standard eq 'ctrl') {

                $self->ivPoke('ctrlKeyFlag', TRUE);
                $self->ivPoke('modifierKeyFlag', TRUE);

            } elsif ($standard eq 'shift') {

                $self->ivPoke('shiftKeyFlag', TRUE);
                $self->ivPoke('modifierKeyFlag', TRUE);

            } elsif ($standard eq 'alt') {

                $self->ivPoke('altKeyFlag', TRUE);
                $self->ivPoke('modifierKeyFlag', TRUE);

            } elsif ($standard eq 'alt_gr') {

                $self->ivPoke('altGrKeyFlag', TRUE);
                $self->ivPoke('modifierKeyFlag', TRUE);
            }

            # Now, create a keycode string, containing a sequence of keycodes (for example, the F5
            #   key creates a keycode string containing a single keycode - 'F5' - but CTRL+SHIFT+F5
            #   produces the keycode string 'ctrl shift f5')
            if ($self->ctrlKeyFlag) {

                if ($standard ne 'ctrl') {

                    push (@list, 'ctrl');
                }
            }

            if ($self->shiftKeyFlag) {

                if ($standard ne 'shift') {

                    push (@list, 'shift');
                }
            }

            if ($self->altKeyFlag) {

                if ($standard ne 'alt') {

                    push (@list, 'alt');
                }
            }

            if ($self->altGrKeyFlag) {

                if ($standard ne 'alt_gr') {

                    push (@list, 'alt_gr');
                }
            }

            push (@list, $standard);

            # (Below, use a keycode string, consisting of one or more standard keycodes separated by
            #   a space)
            $string = '' . join(' ', @list);

            # Get this window's entry strip object (if any)
            $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::Entry');

            # In blind mode, and if this is a 'main' window, hijack the cursor keys and the escape
            #   key for navigating the text-to-speech buffer
            if (
                (
                    ($axmud::BLIND_MODE_FLAG && $axmud::CLIENT->ttsHijackFlag)
                    || (! $axmud::BLIND_MODE_FLAG && $axmud::CLIENT->ttsForceHijackFlag)
                )
                && $self->visibleSession
                && $axmud::CLIENT->ivExists('ttsHijackKeycodeHash', $string)
            ) {
                return $self->visibleSession->pseudoCmd(
                    $axmud::CLIENT->ivShow('ttsHijackKeycodeHash', $string),
                    $self->pseudoCmdMode,
                );
            }

            # Check that direct keys are enabled, if this is a 'main' window
            if ($self->visibleSession) {

                if (
                    $self->visibleSession->currentWorld->ivExists(
                        'termOverrideHash',
                        'useDirectKeysFlag',
                    )
                ) {
                    $directFlag = $self->visibleSession->currentWorld->ivShow(
                        'termOverrideHash',
                        'useDirectKeysFlag',
                    );

                } else {

                    $directFlag = $axmud::CLIENT->useDirectKeysFlag;
                }
            }

            # If direct keys are enabled, send certain keycode strings direct to the world
            if ($directFlag && $self->visibleSession) {

                if (
                    (
                        $axmud::CLIENT->ivExists('constDirectAppKeysHash', $string)
                        && (
                            $self->visibleSession->ctrlKeypadMode eq 'alternate'
                            || $self->visibleSession->ctrlCursorMode eq 'application'
                        )
                        && $self->visibleSession->put(
                            $axmud::CLIENT->ivShow('constDirectAppKeysHash', $string),
                        )
                    ) || (
                        $axmud::CLIENT->ivExists('constDirectAltKeysHash', $string)
                        && $self->visibleSession->ctrlKeypadMode eq 'alternate'
                        && $self->visibleSession->put(
                            $axmud::CLIENT->ivShow('constDirectAltKeysHash', $string),
                        )
                    ) || (
                        $axmud::CLIENT->ivExists('constDirectKeysHash', $string)
                        && $self->visibleSession->put(
                            $axmud::CLIENT->ivShow('constDirectKeysHash', $string),
                        )
                    )
                ) {
                    # Return 1 to show that we have interfered with this keypress
                    return 1;

                } elsif (
                    $self->visibleSession->specialEchoMode eq 'enabled'
                    && (! $stripObj || ! $stripObj->specialPreserveFlag)
                    && $axmud::CLIENT->ivExists('constDirectSpecialKeysHash', $string)
                ) {
                    # Warn the entry strip object about a backspace, which should modify a partial
                    #   world command it's been storing
                    if ($stripObj && ! $stripObj->specialPreserveFlag && $string eq 'backspace') {

                        $stripObj->applyBackspace();
                    }

                    if (
                        $self->visibleSession->put(
                            $axmud::CLIENT->ivShow('constDirectSpecialKeysHash', $string),
                        )
                    ) {
                        # Return 1 to show that we have interfered with this keypress
                        return 1;
                    }
                }
            }

            # We don't want to call GA::Session->checkMacros for every keypress (that would be
            #   inefficient)
            # Instead, call it if this is a 'main' window, and if this keycode string is being used
            #   by any macro in any session (not perfectly efficient, but better)
            if (
                $self->visibleSession
                && $axmud::CLIENT->ivExists('activeKeycodeHash', $string)
                && $self->visibleSession->checkMacros($string)
            ) {
                # Return 1 to show that we have interfered with this keypress (by firing a macro)
                return 1;
            }

            # If no macro fired as a result of the keypress, then we can process some special keys

            # The first pane object in the entry strip object's ->paneObjList is the one to which
            #   keypresses are applied
            if ($stripObj) {

                $paneObj = $stripObj->ivFirst('paneObjList');

            } else {

                # If there's no entry, then use the first pane object created in this window
                $paneObj = $self->findTableObj('pane');
            }

            if ($paneObj) {

                # Get the pane's visible tab and the scrollable Gtk3::Textview
                $tabObj = $paneObj->getVisibleTab();
                if ($tabObj) {

                    $splitScreenMode = $tabObj->textViewObj->splitScreenMode;
                    if ($splitScreenMode eq 'split') {
                        $textView = $tabObj->textViewObj->textView2;
                    } else {
                        $textView = $tabObj->textViewObj->textView;
                    }
                }
            }

            # The CTRL+C combination tends to be CTRL+SHIFT+C in Gtk, which is very inconvenient.
            #   Implement a quick-and-dirty CTRL+C instead
            if ($string eq 'ctrl c' && $tabObj) {

                ($startIter, $endIter) = $tabObj->textViewObj->buffer->get_selection_bounds();
                if (defined $endIter) {

                    $slice = $tabObj->textViewObj->buffer->get_slice($startIter, $endIter, FALSE);
                    if (defined $slice && $slice ne '') {

                        $clipboard = Gtk3::Clipboard::get(Gtk3::Gdk::Atom::intern('CLIPBOARD', 0));
                        if ($clipboard) {

                            $clipboard->set_text($slice);

                            # Return 1 to show that we have interfered with this keypress
                            return 1;
                        }
                    }
                }

            # If the page up/page down/home/end keys have been pressed, scroll the vertical
            #   scrollbar containing the textview object
            } elsif (
                (
                    $standard eq 'page_up' || $standard eq 'page_down' || $standard eq 'home'
                    || $standard eq 'end'
                )
                && $tabObj
                && $axmud::CLIENT->useScrollKeysFlag
            ) {
                $vAdjust = $textView->get_vadjustment();

                # Get the lowest and highest vertical positions of the scrollbar, and the distance
                #   between them
                $high = ($vAdjust->get_upper() - $vAdjust->get_page_size());
                $length = $high - $vAdjust->get_lower();
                $modValue = $vAdjust->get_value();

                # Set the new position of the vertical scrollbar (assuming one is visible)
                if ($length) {

                    if (
                        $axmud::CLIENT->autoSplitKeysFlag
                        && $modValue >= $high
                        && (
                            (
                                $splitScreenMode ne 'split'
                                && ($standard eq 'page_up' || $standard eq 'home')
                            ) || (
                                $splitScreenMode eq 'split'
                                && ($standard eq 'page_down' || $standard eq 'end')
                            )
                        )
                    ) {
                        # Engage/disengage the textview object's split screen mode, if necessary
                        $paneObj->toggleSplitScreen();

                    } else {

                        if ($standard eq 'page_up') {

                            # Scroll up
                            if (! $axmud::CLIENT->smoothScrollKeysFlag) {
                                $modValue -= $vAdjust->get_page_size();
                            } else {
                                $modValue -= $vAdjust->get_page_increment();
                            }

                            if ($modValue < 0) {

                                $modValue = 0;
                            }

                        } elsif ($standard eq 'page_down') {

                            # Scroll down
                            if (! $axmud::CLIENT->smoothScrollKeysFlag) {
                                $modValue += $vAdjust->get_page_size();
                            } else {
                                $modValue += $vAdjust->get_page_increment();
                            }

                            if ($modValue > $high) {

                                $modValue = $high;
                            }

                        } elsif ($standard eq 'home') {

                            # Scroll to top
                            $modValue = 0;

                        } else {

                            # (End key) scroll to bottom
                            $modValue = $high;
                        }

                        $vAdjust->set_value($modValue);
                    }
                }

                # Return 1 to show that we have interfered with this keypress
                return 1;

            # If the up/down/tab arrow keys have been pressed and the client's auto-complete mode is
            #   on (i.e. set to 'auto'), apply auto-complete or navigate through command buffers
            # However, CTRL+TAB switches between tabs in the pane object. If there's an entry strip
            #   object, that object specifies which of multiple pane objects to use; if there's no
            #   strip object, the first pane object created in the window is used
            # TAB can be used instead of CTRL+TAB if there is no entry strip object in the window
            } elsif ($standard eq 'up' || $standard eq 'down' || $standard eq 'tab') {

                if (
                    ($self->ctrlKeyFlag || ! $stripObj)
                    && $standard eq 'tab'
                    && $paneObj
                    && $paneObj->notebook
                    && $axmud::CLIENT->useSwitchKeysFlag
                ) {
                    $paneObj->switchVisibleTab();

                    # Return 1 to show that we have interfered with this keypress
                    return 1;

                } elsif (
                    ! $self->modifierKeyFlag
                    && $self->visibleSession
                    && $stripObj
                    && $stripObj->entry
                    && $axmud::CLIENT->autoCompleteMode eq 'auto'
                    && $axmud::CLIENT->useCompleteKeysFlag
                ) {
                    $entryText = $stripObj->entry->get_text();
                    if (! defined $stripObj->originalEntryText) {

                        $stripObj->set_originalEntryText($entryText);
                    }

                    if ($standard eq 'tab') {

                        # Check the instruction/world command buffer for matching instructions/world
                        #   commands so we can auto-complete the instruction/world command displayed
                        #   in the command entry box
                        $bufferObj = $self->visibleSession->autoCompleteBuffer(
                            $entryText,
                            $stripObj->originalEntryText,
                        );

                    } else {

                        # Navigate through the instruction/world command buffer to find the
                        #   instruction/world command to display in the command entry box
                        $bufferObj = $self->visibleSession->navigateBuffer($standard);
                    }

                    if ($bufferObj) {

                        # Display this previous instruction in the command entry box, and select
                        #   all text
                        if ($axmud::CLIENT->autoCompleteType eq 'instruct') {
                            $stripObj->entry->set_text($bufferObj->instruct);
                        } else {
                            $stripObj->entry->set_text($bufferObj->cmd);
                        }

                        $stripObj->entry->grab_focus();

                    } else {

                        # The returned $bufferObj will be 'undef' (when GA::Client->autoCompleteMode
                        #   = 'auto') when the buffer contains nothing shorter than the text in the
                        #   command entry box
                        # $bufferObj will also be 'undef' if the buffer object is missing, for some
                        #   reason
                        $stripObj->entry->set_text('');
                    }

                    # Return 1 to show that we have interfered with this keypress
                    return 1;
                }
            }

            # Return 'undef' to show that we haven't interfered with this keypress
            return undef;
        });

        return 1;
    }

    sub setKeyReleaseEvent {

        # Called by $self->winSetup
        # Set up a ->signal_connect to watch out for certain key releases
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the ->signal_connect doesn't interfere with the key
        #       release
        #   1 if the ->signal_connect does interfere with the key release, or when the
        #       ->signal_connect is first set up

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setKeyReleaseEvent', @_);
        }

        $self->winBox->signal_connect('key-release-event' => sub {

            my ($widget, $event) = @_;

            # Local variables
            my ($keycode, $standard);

            # Get the system keycode for this keypress
            $keycode = Gtk3::Gdk::keyval_name($event->keyval);
            # Translate it into a standard Axmud keycode
            $standard = $axmud::CLIENT->reverseKeycode($keycode);

            # If it's a CTRL, SHIFT, ALT or ALT-GR keypress, set IVs
            if ($standard eq 'ctrl') {
                $self->ivPoke('ctrlKeyFlag', FALSE);
            } elsif ($standard eq 'shift') {
                $self->ivPoke('shiftKeyFlag', FALSE);
            } elsif ($standard eq 'alt') {
                $self->ivPoke('altKeyFlag', FALSE);
            } elsif ($standard eq 'alt_gr') {
                $self->ivPoke('altGrKeyFlag', FALSE);
            }

            if (
                ! $self->ctrlKeyFlag
                && ! $self->shiftKeyFlag
                && ! $self->altKeyFlag
                && ! $self->altGrKeyFlag
            ) {
                $self->ivPoke('modifierKeyFlag', FALSE);
            }

            # Return 'undef' to show that we haven't interfered with this keypress
            return undef;
        });

        return 1;
    }

    sub setConfigureEvent {

        # Called by $self->winEnable
        # Set up a ->signal_connect to watch out for changes in the window size and position
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setConfigureEvent', @_);
        }

        $self->winBox->signal_connect('configure-event' => sub {

            my ($widget, $event) = @_;

            # Has the window size actually changed, or just its position?
            if (
                ! defined $self->actualWinWidth            # Windows size checked for the first time
                || $event->width != $self->actualWinWidth
                || $event->height != $self->actualWinHeight
            ) {
                $self->ivPoke('actualWinWidth', $event->width);
                $self->ivPoke('actualWinHeight', $event->height);
            }

            # Every textview object (GA::Obj::TextView) in this window must update its size IVs,
            #   which informs the GA::Session (so it can send NAWS data to the world)
            foreach my $textViewObj ($axmud::CLIENT->desktopObj->ivValues('textViewHash')) {

                if ($textViewObj->winObj eq $self) {

                    # Update the IVs once the changes have been rendered
                    $textViewObj->set_sizeUpdateFlag();
                }
            }

            # Let the GA::Client store the most recent size and position for a window of this
            #   ->winName, if it needs to
            if ($self->winWidget) {

                $axmud::CLIENT->add_storeGridPosn(
                    $self,
                    $self->winWidget->get_position(),
                    $self->winWidget->get_size(),
                );
            }

            # Without returning 'undef', the window's strip/table objects aren't resized along with
            #   the window
            return undef;
        });

        return 1;
    }

    sub setWindowStateEvent {

        # Called by $self->winEnable
        # Set up a ->signal_connect to watch out for when the window is maximised and unmaximised
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setWindowStateEvent', @_);
        }

        $self->winBox->signal_connect('window-state-event' => sub {

            # When the window is maximised and unmaximised, gauges in the gauge box (if visible) are
            #   not redrawn properly. This block of code fixes that problem (but I don't know why it
            #   works)

            my ($widget, $event) = @_;

            if ($event->changed_mask() =~ m/maximized/) {

                # This code makes sure textview(s) in pane object(s) are scrolled to the bottom
                #   after un-maximising a window (otherwise, the scrollbar position moves
                #   confusingly)
                if (! $self->maximisedFlag) {

                    $self->ivPoke('maximisedFlag', TRUE);

                } else {

                    $self->ivPoke('maximisedFlag', FALSE);
                    $self->rescrollTextViews();
                }
            }
        });
    }

    sub setFocusInEvent {

        # Called by $self->winEnable
        # Set up a ->signal_connect to watch out for the 'internal' window receiving the focus,
        #   which should be redirected towards the GA::Strip::Entry object's Gtk3::Entry (if there
        #   is one)
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setFocusInEvent', @_);
        }

        $self->winBox->signal_connect('focus-in-event' => sub {

            my ($widget, $event) = @_;

            # Update IVs
            $self->ivPoke('focusFlag', TRUE);

            # Update the command entry box (if visible)
            my $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::Entry');
            if ($stripObj && $stripObj->entry) {

                $stripObj->entry->grab_focus();
            }

            # For 'main' windows, check active hook interfaces for all sessions using this window
            #   and fire hooks that are using the 'get_focus' hook event
            if ($self->visibleSession) {

                foreach my $session ($axmud::CLIENT->listSessions()) {

                    if ($session->mainWin && $session->mainWin eq $self) {

                        $session->checkHooks('get_focus');
                    }
                }
            }
        });

        return 1;
    }

    sub setFocusOutEvent {

        # Called by $self->winEnable
        # Set up a ->signal_connect to watch out for the 'internal' window losing the focus
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setFocusInEvent', @_);
        }

        $self->winBox->signal_connect('focus-out-event' => sub {

            my ($widget, $event) = @_;

            # Update IVs
            $self->ivPoke('focusFlag', FALSE);

            # For 'main' windows, check active hook interfaces for all sessions using this window
            #   and fire hooks that are using the 'lose_focus' hook event
            if ($self->visibleSession) {

                foreach my $session ($axmud::CLIENT->listSessions()) {

                    if ($session->mainWin && $session->mainWin eq $self) {

                        $session->checkHooks('lose_focus');
                    }
                }
            }

            # When the window loses focus, we no longer track SHIFT, ALT, CTRL or NUM LOCK
            #   keypresses. Set IVs
            $self->ivPoke('shiftKeyFlag', FALSE);
            $self->ivPoke('altKeyFlag', FALSE);
            $self->ivPoke('altGrKeyFlag', FALSE);
            $self->ivPoke('ctrlKeyFlag', FALSE);
            $self->ivPoke('modifierKeyFlag', FALSE);
        });

        return 1;
    }

    # Other functions

    sub updateColourScheme {

        # Called by GA::Cmd::UpdateColourScheme->do (usually after a colour scheme is modified) and
        #   by GA::Cmd::SetXTerm->do (when the xterm colour cube is switched)
        # Also called by $self->redrawWidgets, to neutralise Gtk3's charming tendency to redraw all
        #   our textviews the wrong colour
        # Checks all textview objects in all pane objects in this window's Gtk3::Grid and updates
        #   colours for any textview objects that use the specified colour scheme
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $colourScheme   - The name of the colour scheme (matches a key in
        #                       GA::Client->colourSchemeHash). If 'undef', all pane objects are
        #                       updated using their existing colour scheme
        #   $noDrawFlag     - TRUE when called by $self->redrawWidgets, meaning that the pane
        #                       objects are told not to call GA::Win::Generic->winShowAll or
        #                       GA::Obj::Desktop->updateWidgets as they normally would, so that
        #                       ->redrawWidgets can do it when ready. FALSE (or 'undef') otherwise
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $colourScheme, $noDrawFlag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->updateColourScheme', @_);
        }

        # If $colourScheme was specified, check it's a recognised colour scheme
        if (defined $colourScheme) {

            if (! $axmud::CLIENT->ivExists('colourSchemeHash', $colourScheme)) {

                # Update all textview objects
                $colourScheme = undef;
            }
        }

        foreach my $tableObj ($self->tableStripObj->ivValues('tableObjHash')) {

            if ($tableObj->type eq 'pane') {

                $tableObj->updateColourScheme($colourScheme, $noDrawFlag);
            }
        }

        return 1;
    }

    sub applyColourScheme {

        # Called by GA::Cmd::ApplyColourScheme->do
        # Applies a colour scheme to all textview objects in all pane objects in this window's
        #   Gtk3::Grid, replacing any colour schemes used before
        #
        # Expected arguments
        #   $colourScheme   - The name of the colour scheme to apply (matches a key in
        #                       GA::Client->colourSchemeHash)
        #
        # Return values
        #   'undef' on improper arguments or if $colourScheme doesn't exist
        #   1 on success

        my ($self, $colourScheme, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->applyColourScheme', @_);
        }

        # Check that $colourScheme exists
        if (! $axmud::CLIENT->ivExists('colourSchemeHash', $colourScheme)) {

            return undef;
        }

        foreach my $tableObj ($self->tableStripObj->ivValues('tableObjHash')) {

            if ($tableObj->type eq 'pane') {

                $tableObj->applyColourScheme(
                    undef,                  # Apply to all tabs in the pane object
                    $colourScheme,
                );
            }
        }

        return 1;
    }

    sub rescrollTextViews {

        # Can be called by anyting
        # After a change in position of any window widgets, make sure any textview(s) in pane
        #   object(s) are scrolled to the bottom (this saves a lot of user frustration)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if this isn't the 'main' window
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $stripObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->rescrollTextViews', @_);
        }

        foreach my $tableObj ($self->tableStripObj->ivValues('tableObjHash')) {

            if ($tableObj->type eq 'pane') {

                foreach my $tabObj ($tableObj->ivValues('tabObjHash')) {

                    $tabObj->textViewObj->scrollToBottom();
                }
            }
        }

        # After drawing gauges or unmaximising the window, the focus is lost from the command entry
        #   box, so restore it
        $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::Entry');
        if ($stripObj && $stripObj->entry) {

            $stripObj->entry->grab_focus();
        }

        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->rescrollTextViews');

        return 1;
    }

    sub findTableObj {

        # Can be called by anything
        # Finds the first table object of a particular type created in the compulsory table strip
        #   object, if there is one
        #
        # Expected arguments
        #   $type   - The type of table object; matches the table object's type (e.g. 'pane' for
        #               pane objects)
        #
        # Return values
        #   'undef' on improper arguments or if there is no table object of the specified type in
        #       the Gtk3::Grid
        #   Otherwise returns the table object of the specified type with the lowest ->number

        my ($self, $type, $check) = @_;

        # Local variables
        my @tableObjList;

        # Check for improper arguments
        if (! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findFirstTableObj', @_);
        }

        @tableObjList = sort {$a->number <=> $b->number}
                                ($self->tableStripObj->ivValues('tableObjHash'));

        foreach my $tableObj (@tableObjList) {

            if ($tableObj->type eq $type) {

                return $tableObj;
            }
        }

        # No table object of the right $type found
        return undef;
    }

    sub setVisibleSession {

        # Called by GA::Table::Pane->respondVisibleTab, when a session's default tab becomes the
        #   visible tab in that pane. Only called when this window is a 'main' window
        # Should not be called by anything else - call GA::Table::Pane->setVisibleTab instead
        #
        # Sets $self->visibleSession and performs a number of housekeeping duties
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $session    - The GA::Session that is the new visible session. If 'undef', there is no
        #                   visible session in this window
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my ($tabObj, $paneObj, $visibleTabObj);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setVisibleSession', @_);
        }

        # This function shouldn't be called unless this is a 'main' window
        if ($self->winType ne 'main') {

            return $self->writeError(
                'Cannot set a visible session outside a \'main\' window',
                $self->_objClass . '->setVisibleSession',
            );
        }

        # Cease navigating through instruction/world command buffers in all windows (if the user has
        #   been doing that using the 'up'/'down' arrow keys in any window)
        $axmud::CLIENT->set_instructBufferPosn();
        $axmud::CLIENT->set_cmdBufferPosn();
        foreach my $otherSession ($axmud::CLIENT->listSessions()) {

            $otherSession->set_instructBufferPosn();
            $otherSession->set_cmdBufferPosn();
        }

        # No visible session
        if (! $session) {

            # Update certain strip objects in any 'internal' window used by the old visible session
            #   (if any; the TRUE flag means 'return 'internal' windows only)
            foreach my $winObj (
                $axmud::CLIENT->desktopObj->listSessionGridWins($self->visibleSession, TRUE)
            ) {
                # Update information stored in the window's connection info strip, if visible
                $winObj->setHostLabel('');
                $winObj->setTimeLabel('');
                # Reset the window's entry box and blinkers, if visible
                $winObj->resetEntry();
                $winObj->resetBlinkers();
            }

            # Update the GA::Client's IVs
            if (
                $axmud::CLIENT->currentSession
                && $self->visibleSession
                && $axmud::CLIENT->currentSession eq $self->visibleSession
            ) {
                $axmud::CLIENT->setCurrentSession();
            }

            # Update this window's IVs
            $self->ivUndef('visibleSession');
            if ($self->winType eq 'main') {

                $self->ivUndef('workspaceGridObj');
            }

        # New visible session
        } else {

            # If this window is a 'main' window shared by all sessions...
            if (
                $axmud::CLIENT->shareMainWinFlag
                && $self->visibleSession
                && $self->visibleSession ne $session
            ) {
                # ...need to hide windows on the former visible session's workspace grids (though
                #   obviously not the shared 'main' window)
                $axmud::CLIENT->desktopObj->hideGridWins($self->visibleSession);
                # The new visible session's windows, on the other hand, need to be un-hidden
                $axmud::CLIENT->desktopObj->revealGridWins($session);

                # Fire any hooks that are using the 'not_visible' hook event
                $self->visibleSession->checkHooks('not_visible', $session->number);
            }

            # Update the GA::Client's IVs
            # ->currentSession is modified only when a 'main' window that's in focus changes its
            #   ->visibleSession (exception - if the IV isn't set at all, set it regardless of
            #   whether this window has the focus, or not)
            if (! $axmud::CLIENT->currentSession || $self->focusFlag) {

                $axmud::CLIENT->setCurrentSession($session);
            }

            # Update this window's IVs
            $self->ivPoke('visibleSession', $session);
            # For 'main' windows only, find the workspace grid used by this session (might be a
            #   shared grid), and update the IV
            if ($self->winType eq 'main' && $self->workspaceObj) {

                # (In case the grid can't be found, use a default 'undef' value)
                $self->ivUndef('workspaceGridObj');

                OUTER: foreach my $gridObj (
                    sort {$a->number <=> $b->number}
                    ($self->workspaceObj->ivValues('gridHash'))
                ) {
                    if (
                        ! defined $gridObj->owner       # Shared workspace grid
                        || $gridObj->owner eq $session
                    ) {
                        $self->ivPoke('workspaceGridObj', $gridObj);
                        last OUTER;
                    }
                }
            }

            # In case the change of visible session isn't the result of the user clicking a
            #   session's default tab, make the new visible session's default tab the visible one.
            #   If that default tab is a simple tab, then there's nothing to do
            # ($session->defaultTabObj won't be set yet, if $session->start is still executing)
            if ($session->defaultTabObj) {

                $paneObj = $session->defaultTabObj->paneObj;
                $tabObj = $paneObj->findSession($session);
                $visibleTabObj = $paneObj->getVisibleTab();
                if ($paneObj->notebook && $tabObj && $visibleTabObj && $tabObj ne $visibleTabObj) {

                    $paneObj->setVisibleTab($tabObj);
                }
            }

            # If the session's tab label is in a different colour, meaning that text had been
            #   received from the world but hadn't been viewed by the user yet, reset the flag to
            #   show that the text is now visible to the user
            $session->reset_showNewTextFlag();

            # Update information stored in the 'main' window's connection info strip, if visible
            $self->setHostLabel($session->getHostLabelText());
            $self->setTimeLabel($session->getTimeLabelText());

            # Update certain strip objects in any 'internal' window used by the new visible session
            #   (if any; the TRUE flag means 'return 'internal' windows only)
            foreach my $winObj ($axmud::CLIENT->desktopObj->listSessionGridWins($session, TRUE)) {

                # Reset the 'internal' window's entry box and blinkers, if any
                $winObj->resetEntry();
                $winObj->resetBlinkers();
            }

            # Fire any hooks that are using the 'visible_session' hook event
            $session->checkHooks('visible_session', undef);
            # Fire any hooks that are using the 'change_visible' hook event
            foreach my $otherSession ($axmud::CLIENT->listSessions()) {

                if ($otherSession ne $session) {

                    $otherSession->checkHooks('change_visible', $session->number);
                }
            }
        }

        # Update all 'internal' windows
        foreach my $winObj ($axmud::CLIENT->desktopObj->listGridWins()) {

            if (
                $winObj->winType eq 'main'
                || $winObj->winType eq 'protocol'
                || $winObj->winType eq 'custom'
            ) {
                # Sensitise/desensitise menu items in 'internal' windows, as appropriate
                $winObj->restrictMenuBars();
                $winObj->restrictToolbars();
                # Update the gauge box, if visible
                $winObj->updateGauges();

                # Sensitise or desensitise widgets, as appropriate
                $winObj->setWidgetsIfSession();
                # Update widgets, as appropriate
                $winObj->setWidgetsChangeSession();

                # Make any changes visible
                $winObj->winShowAll($self->_objClass . '->setVisibleSession');
            }
        }

        return 1;
    }

    sub checkConnectedSessions {

        # Called by $self->setDeleteEvent
        # If the user tries to manually close a 'main' window, counts the number of connected
        #   sessions (not including disconencted or 'connect offline' mode sessions) using this
        #   window as their 'main' window
        # If any are found, prompts the user for confirmation (if the GA::Client flag requires us
        #   to do that)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the window should not be closed
        #   1 if the window can be closed

        my ($self, $check) = @_;

        # Local variables
        my ($count, $choice, $msg);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->checkConnectedSessions',
                @_,
            );
        }

        if (! $axmud::CLIENT->confirmCloseMainWinFlag) {

            # The window can be closed - no confirmation required
            return 1;
        }

        # Otherwise, count connected sessions
        $count = 0;
        foreach my $session ($axmud::CLIENT->ivValues('sessionHash')) {

            if (
                $session->mainWin
                && $session->mainWin eq $self
                && $session->status eq 'connected'
            ) {
                $count++;
            }
        }

        if ($count) {

            if ($count == 1) {
                $msg = '1 connected session';
            } else {
                $msg = $count . ' connected sessions';
            }

            $choice = $self->showMsgDialogue(
                'Close \'main\' window',
                'question',
                'This window is in use by ' . $msg . '. Are you sure you want to close it?',
                'yes-no',
            );

            if ($choice && $choice eq 'yes') {

                # Allow the window to close
                return 1;

            } else {

                # Don't allow the window to close
                return undef;
            }

        } else {

            # No connected sessions, allow the window to close
            return 1;
        }
    }

    sub updateGauges {

        # Called by various functions as a shortcut to GA::Strip::GaugeBox->updateGauges
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $winmapName, $check) = @_;

        # Local variables
        my $stripObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateGauges', @_);
        }

        $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::GaugeBox');
        if ($stripObj) {

            $stripObj->updateGauges();
        }

        return 1;
    }

    sub resetEntry {

        # Called by GA::Client->set_autoCompleteMode, ->set_autoCompleteType and
        #   ->set_autoCompleteParent or any other code which needs to reset the entry box (for some
        #   reason)
        # The user can press the 'up'/'down' arrow keys to change the command displayed in the
        #   GA::Strip::Entry's command entry box
        # The new command depends on various client IVs. If those IVs are changed, the entry box
        #   must be reset
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $stripObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetEntry', @_);
        }

        $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::Entry');
        if ($stripObj) {

            $stripObj->set_originalEntryText();
            if ($stripObj->entry) {

                $stripObj->entry->set_text('');
            }
        }

        return 1;
    }

    sub setHostLabel {

        # Can be called by anything (but usually called by various functions in GA::Session, and
        #   also by $self->setVisibleSession)
        # Sets the text used in the GA::Strip::ConnectInfo strip object to display information
        #   about the current host (world)
        # If the strip object hasn't been added to the window, still store the text in
        #   $self->hostLabelText so it's available instantly if the strip object is added later
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text       - The text to display in this label. If set to 'undef', an empty string is
        #                   displayed
        #   $tooltip    - The text to display as a tooltip. If set to 'undef', no tooltip is
        #                   displayed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $text, $tooltip, $check) = @_;

        # Local variables
        my $stripObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setHostLabel', @_);
        }

        if (! $text) {

            $text = '';
        }

        $self->ivPoke('hostLabelText', $text);

        $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::ConnectInfo');
        if ($stripObj) {

            $stripObj->set_hostLabel($text, $tooltip);
        }

        return 1;
    }

    sub setTimeLabel {

        # Can be called by anything (but usually called by GA::Client->spinClientLoop, various
        #   functions in GA::Session, and also by $self->setVisibleSession)
        # Sets the text used in the GA::Strip::ConnectInfo strip object to display information about
        #   the current time
        # If the strip object hasn't been added to the window, still store the text in
        #   $self->timeLabelText so it's available instantly if the strip object is added later
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text       - The text to display in this label. If set to 'undef', an empty string is
        #                   displayed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $text, $check) = @_;

        # Local variables
        my $stripObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setTimeLabel', @_);
        }

        if (! $text) {

            $text = '';
        }

        $self->ivPoke('timeLabelText', $text);

        $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::ConnectInfo');
        if ($stripObj) {

            $stripObj->set_timeLabel($text);
        }

        return 1;
    }

    sub resetBlinkers {

        # Can be called by anything (but usually called by GA::Session->reactDisconnect and
        #   $self->setVisibleSession)
        # Resets the blinkers drawn in the GA::Strip::ConnectInfo strip object
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $stripObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetBlinkers', @_);
        }

        $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::ConnectInfo');
        if ($stripObj) {

            $stripObj->drawBlinker(-1, FALSE);
        }

        return 1;
    }

    sub setMainWinTitle {

        # Called by GA::Client->checkMainWinTitles to change each 'main' window's title to something
        #   like '*Axmud' to show that there are client files that need to be saved, or to something
        #   like 'Axmud' to show there are no client files that need to be saved
        # (Session files are handles separately by GA::Session->checkTabLabels)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag       - If set to TRUE, show an asterisk. If set to FALSE (or 'undef'), don't show
        #                   an asterisk
        #
        # Return values
        #   'undef' on improper arguments or if this window isn't a 'main' window
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setMainWinTitle', @_);
        }

        # Ignore this function call for other types of 'grid' window
        if ($self->winType eq 'main') {

            return undef;

        # Set the window title
        } elsif ($flag) {

            $self->winWidget->set_title('*' . $axmud::SCRIPT);

        } else {

            $self->winWidget->set_title($axmud::SCRIPT);
        }

        return 1;
    }

    sub setWinTitle {

        # Can be called by anything to change the text in the window's title bar
        # Does nothing if this window is a 'main' window (code should call $self->setMainWinTitle
        #   instead)
        #
        # Expected arguments
        #   $text       - The text to use
        #
        # Return values
        #   'undef' on improper arguments or if this window isn't a 'main' window
        #   1 otherwise

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setWinTitle', @_);
        }

        if ($self->enabledFlag && $self->winType ne 'main' && $self->winWidget eq $self->winBox) {

            $self->winWidget->set_title($text);
        }

        return 1;
    }

    sub restrictMenuBars {

        # Called by GA::Obj::Desktop->restrictWidgets
        # Sensitise or desensitise the menu bar in this 'internal' window, depending on current
        #   conditions. (Don't do anything if this window doesn't use a strip object for a menu bar)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if this window doesn't use a strip object for a menu
        #       bar
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $stripObj, $openFlag, $setupFlag,
            @list, @sensitiseList, @desensitiseList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restrictMenuBars', @_);
        }

        # Get the strip object
        $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::MenuBar');
        if (! $stripObj) {

            # Nothing to sensitise/desensitise
            return undef;
        }

        # Test whether this is a 'main' window with a visible session whose status is 'connected' or
        #   'offline' (for the sake of efficiency)
        if (
            $self->visibleSession
            && (
                $self->visibleSession->status eq 'connected'
                || $self->visibleSession->status eq 'offline'
            )
        ) {
            $openFlag = TRUE;
        }

        # Test whether the setup wizwin is open (in which case, almost everything is desensitised)
        OUTER: foreach my $winObj ($axmud::CLIENT->desktopObj->ivValues('freeWinHash')) {

            if ($winObj->isa('Games::Axmud::WizWin::Setup')) {

                $setupFlag = TRUE;

                # In addition, the following menu items are desensitised
                push (@desensitiseList,
                    # 'World' column
                    'connect', 'stop_client',
                    # 'Edit' column
                    'test_pattern',
                    # 'Help' column
                    'help', 'about', 'credits', 'license',
                );

                last OUTER;
            }
        }

        # Menu bar items that require a 'main' window with a visible session
        @list = (
            # 'World' column
            'reconnect', 'reconnect_offline',
            'xconnect', 'xconnect_offline',
            'quit_all',
            'exit_all',
            'stop_session',
            # 'File' column
            'test_file',
            'show_files', 'show_file_meta',
            # 'Axbasic' column
            'check_script', 'edit_script',
            # 'Plugins' column
            'load_plugin', 'show_plugin',
        );

        if (! $setupFlag && $self->visibleSession) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline'
        @list = (
            # 'World' column
            'login',
            'quit', 'qquit',
            'exit', 'xxit',
            # 'File' column
            'load_all', 'load_file',
            'save_all', 'save', 'save_options',
            'import_files',
#            'export_all_files', 'export_file',
            'export_file',
            'import_data',
            'export_data',
            'backup_restore_data',
            'disable_world_save', 'disable_save_load',
            # 'Edit' column
            'edit_quick_prefs', 'edit_client_prefs', 'edit_session_prefs',
            'edit_current_world',
            'run_locator_wiz', 'edit_world_model', 'edit_dictionary',
            'simulate',
            # 'Interfaces' column
            'active_interfaces',
            'show_triggers', 'show_aliases', 'show_macros', 'show_timers', 'show_hooks',
                'show_cmds', 'show_routes',
            # 'Tasks' column
            'freeze_tasks', 'chat_task',
            'run_locator_wiz_2',
            'other_task',
            # 'Display' column
            'open_automapper', 'open_object_viewer',
            'activate_grid', 'activate_grid_with', 'reset_grid', 'disactivate_grid',
            'win_components', 'current_layer', 'window_storage',
            'test_controls', 'test_panels',
            # 'Commands' column
            'repeat_cmd', 'repeat_second', 'repeat_interval',
            'cancel_repeat',
            # 'Axbasic' column
            'run_script', 'run_script_task',
        );

        if (! $setupFlag && $openFlag) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and whose ->currentGuild is defined
        @list = (
            # 'Edit' column
            'edit_current_guild',
            # 'Interfaces' column
            'guild_triggers', 'guild_aliases', 'guild_macros', 'guild_timers', 'guild_hooks',
                'guild_cmds', 'guild_routes',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->currentGuild) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and whose ->currentRace is defined
        @list = (
            # 'Edit' column
            'edit_current_race',
            # 'Interfaces' column
            'race_triggers', 'race_aliases', 'race_macros', 'race_timers', 'race_hooks',
                'race_cmds', 'race_routes',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->currentRace) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and whose ->currentChar is defined
        @list = (
            # 'Edit' column
            'edit_current_char',
            # 'Interfaces' column
            'char_triggers', 'char_aliases', 'char_macros', 'char_timers', 'char_hooks',
                'char_cmds', 'char_routes',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->currentChar) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and $stripObj->saveAllSessionsFlag set to FALSE
        @list = (
            # 'File' column
            'save_file',
        );

        if (! $setupFlag && $openFlag && ! $stripObj->saveAllSessionsFlag) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and whose ->recordingPausedFlag is FALSE
        @list = (
            # 'Recordings' column
            'start_stop_recording',
        );

        if (! $setupFlag && $openFlag && ! $self->visibleSession->recordingPausedFlag) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and whose ->recordingFlag is TRUE
        @list = (
            # 'Recordings' column
            'pause_recording',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->recordingFlag) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and an Advance task
        @list = (
            # 'Tasks' column
            'edit_advance_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->advanceTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a Connections task
        @list = (
            # 'Tasks' column
            'edit_connections_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->connectionsTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and an Attack task
        @list = (
            # 'Tasks' column
            'edit_attack_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->attackTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a Chat task
        @list = (
            # 'Tasks' column
            'edit_chat_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->chatTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a Channels task
        @list = (
            # 'Tasks' column
            'channels_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->channelsTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a Compass task
        @list = (
            # 'Tasks' column
            'compass_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->compassTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a Divert task
        @list = (
            # 'Tasks' column
            'divert_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->divertTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and an Inventory task
        @list = (
            # 'Tasks' column
            'inventory_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->inventoryTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a Locator task
        @list = (
            # 'Tasks' column
            'locator_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->locatorTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a RawToken task
        @list = (
            # 'Tasks' column
            'raw_token_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->rawTokenTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a Status task
        @list = (
            # 'Tasks' column
            'status_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->statusTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a System task
        @list = (
            # 'Tasks' column
            'edit_system_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->systemTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline' and a Watch task
        @list = (
            # 'Tasks' column
            'watch_task',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->watchTask) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a require a 'main' window with a visible session whose status
        #   is 'connected' or 'offline' and GA::Session->recordingFlag
        @list = (
            # 'Recordings' column
            'pause_resume_recording',
            'recording_add_line', 'recording_add_break',
            'recording_set_insertion', 'recording_cancel_insertion',
            'recording_delete_line', 'recording_delete_multi', 'recording_delete_last',
        );

        if (! $setupFlag && $openFlag && $self->visibleSession->recordingFlag) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require a require a 'main' window with a visible session whose status
        #   is 'connected' or 'offline', and either GA::Session->recordingFlag or ->recordingList
        @list = (
            # 'Recordings' column
            'show_recording', 'copy_recording',
        );

        if (
            ! $setupFlag
            && $openFlag
            && ($self->visibleSession->recordingFlag || $self->visibleSession->recordingList)
        ) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Menu bar items that require GA::Client->browserCmd
        @list = (
            # 'Help' column
            'go_website',
        );

        if (! $setupFlag && $axmud::CLIENT->browserCmd) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Sensitise/desensitise menu bar items
        $stripObj->sensitiseWidgets(@sensitiseList);
        $stripObj->desensitiseWidgets(@desensitiseList);

        # All menu items added by plugins require a 'main' window with a visible session, and the
        #   plugin itself must be must be enabled
        foreach my $plugin ($stripObj->ivKeys('pluginMenuItemHash')) {

            my ($widget, $pluginObj);

            $widget = $stripObj->ivShow('pluginMenuItemHash', $plugin);
            $pluginObj = $axmud::CLIENT->ivShow('pluginHash', $plugin);

            if (! $setupFlag && $self->visibleSession && $pluginObj->enabledFlag) {
                $widget->set_sensitive(TRUE);
            } else {
                $widget->set_sensitive(FALSE);
            }
        }

        return 1;
    }

    sub restrictToolbars {

        # Called by GA::Obj::Desktop->restrictWidgets
        # Sensitise or desensitise the toolbar in this 'internal' window, depending on current
        #   conditions. (Don't do anything if this window doesn't use a strip object for a toolbar)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if this window doesn't use a strip object for a toolbar
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $stripObj,
            @list, @sensitiseList, @desensitiseList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restrictToolbars', @_);
        }

        # Get the strip object
        $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::Toolbar');
        if (! $stripObj) {

            # Nothing to sensitise/desensitise
            return undef;
        }

        # Test whether the setup wizwin is open (in which case, everything is desensitised)
        OUTER: foreach my $winObj ($axmud::CLIENT->desktopObj->ivValues('freeWinHash')) {

            if ($winObj->isa('Games::Axmud::WizWin::Setup')) {

                foreach my $widget ($stripObj->toolbarWidgetList) {

                    $widget->set_sensitive(FALSE);
                }

                return 1;
            }
        }

        # Toolbar buttons that require a 'main' window with a visible session
        @list = $stripObj->ivKeys('requireSessionHash');

        if ($self->visibleSession) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Toolbar buttons that require a 'main' window with a visible session whose status is
        #   'connected' or 'offline'
        @list = $stripObj->ivKeys('requireConnectHash');

        if (
            $self->visibleSession
            && (
                $self->visibleSession->status eq 'connected'
                || $self->visibleSession->status eq 'offline'
            )
        ) {
            push (@sensitiseList, @list);
        } else {
            push (@desensitiseList, @list);
        }

        # Sensitise/desensitise toolbar items
        $stripObj->sensitiseWidgets(@sensitiseList);
        $stripObj->desensitiseWidgets(@desensitiseList);

        return 1;
    }

    sub setWidgetsIfSession {

        # Called by $self->setVisibleSession
        # Calls each strip object (and, for GA::Strip::Table, any child table objects) so they can
        #   sensitise or desensitise their widgets, depending on whether this window has a
        #   ->visibleSession, or not
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $flag;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setWidgetsIfSession', @_);
        }

        if ($self->visibleSession) {
            $flag = TRUE;
        } else {
            $flag = FALSE;
        }

        foreach my $stripObj ($self->ivValues('stripHash')) {

            $stripObj->setWidgetsIfSession($flag);
        }

        return 1;
    }

    sub setWidgetsChangeSession {

        # Called by $self->setVisibleSession
        # Calls each strip object (and, for GA::Strip::Table, any child table objects) so they can
        #   update their widgets when any 'main' window's ->visibleSession changes
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
                $self->_objClass . '->setWidgetsChangeSession',
                @_,
            );
        }

        foreach my $stripObj ($self->ivValues('stripHash')) {

            $stripObj->setWidgetsChangeSession();
        }

        return 1;
    }

    # Strip object functions

    sub resetWinmap {

        # Returns the window to its initial state by removing all table objects and strip objects,
        #   and applying the specified winmap (which might be the same as the previous one)
        # Useful for 'main' windows when the 'main_wait' winmap should be applied, or replaced
        #   after being replied
        # Probably not useful for other 'internal' windows, though if code needs to apply the
        #   equivalent 'internal_wait' winmap and, at some later time, replace it with something
        #   else, it can
        #
        # Expected arguments
        #   $winmapName     - The name of the new winmap
        #
        # Return values
        #   'undef' on improper arguments or if the specified winmap doesn't exist
        #   1 otherwise

        my ($self, $winmapName, $check) = @_;

        # Local variables
        my $winmapObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetWinmap', @_);
        }

        # Check the specified winmap exists
        $winmapObj = $axmud::CLIENT->ivShow('winmapHash', $winmapName);
        if (! $winmapObj) {

            return undef;
        }

        # Remove all strip objects (table objects in the compulsory Gtk3::Grid are also destroyed)
        foreach my $stripObj ($self->ivValues('stripHash')) {

            $stripObj->objDestroy();

            if ($stripObj->visibleFlag) {

                $axmud::CLIENT->desktopObj->removeWidget($self->packingBox, $stripObj->packingBox);
            }
        }

        # Remove the Gtk3::HBox or Gtk3::VBox into which everything is packed
        $axmud::CLIENT->desktopObj->removeWidget($self->winBox, $self->packingBox);

        # Update IVs
        $self->ivUndef('packingBox');
        $self->ivEmpty('stripHash');
        $self->ivEmpty('firstStripHash');
        $self->ivPoke('stripCount', 0);
        $self->ivEmpty('stripList');
        $self->ivUndef('tableStripObj');

        $self->ivPoke('winmap', $winmapObj->name);

        # Set up the window with its strip objects and table objects as if the window had just been
        #   created
        $self->drawWidgets();
        $self->winShowAll($self->_objClass . '->resetWinmap');
        # This should already be set
        $self->ivPoke('enabledFlag', TRUE);

        return 1;
    }

    sub getWinmap {

        # Called by $self->addStripObj and ->revealStripObj
        # If $self->winmap is set (to the name of a winmap object), returns the winmap object
        #   (GA::Obj::Winmap) itself
        # Otherwise returns an appropirate default winmap object
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a winmap object (GA::Obj::Winmap)

        my ($self, $check) = @_;

        # Local variables
        my $winmapObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getWinmap', @_);
        }

        $winmapObj = $axmud::CLIENT->ivShow('winmapHash', $self->winmap);
        if (! $winmapObj) {

            if ($self->winType eq 'main') {

                if ($axmud::CLIENT->activateGridFlag) {

                    $winmapObj = $axmud::CLIENT->ivShow(
                        'winmapHash',
                        $axmud::CLIENT->defaultEnabledWinmap,
                    );

                } else {

                    $winmapObj = $axmud::CLIENT->ivShow(
                        'winmapHash',
                        $axmud::CLIENT->defaultDisabledWinmap,
                    );
                }

            } else {

                $winmapObj = $axmud::CLIENT->ivShow(
                    'winmapHash',
                    $axmud::CLIENT->defaultInternalWinmap,
                );
            }
        }

        return $winmapObj;
    }

    sub addStripObj {

        # Can be called by anything (strip objects are also created by $self->drawWidgets() )
        # Adds a strip object (inheriting from GA::Generic::Strip) to the list of strip objects that
        #   can be displayed in this window (whether the Gtk widget is actually drawn, or not,
        #   depends on the value of the strip object's ->visibleFlag)
        #
        # Expected arguments
        #   $packageName    - The package name for the strip object to add, e.g.
        #                       GA::Strip::GaugeBox. This function can't be used to add the
        #                       compulsory GA::Strip::Table which already exists
        #
        # Optional arguments
        #   $index           - The new strip object's position in the window. Strip objects are
        #                       stored in $self->stripList, in the order in which they're drawn
        #                       (which could be top to bottom, bottom to top, left to right or right
        #                       to left). $index specifies the position in that list at which the
        #                       new strip object is inserted. If $index is 0, the strip object is
        #                       inserted at the beginning of the list. If $index is 1, it's inserted
        #                       second, if $index is 2, it's inserted third, and so on. If $index is
        #                       -1, it's inserted last. If $index is 'undef', or if its index is
        #                       outside the list, the strip object is inserted at the beginning of
        #                       the list
        #   %initHash        - If specified, a reference to a hash containing arbitrary data to use
        #                       as the strip object's initialisation settings (may be an empty
        #                       hash). The strip object should use default initialisation settings
        #                       unless it can succesfully interpret one or more of the key-value
        #                       pairs in the hash, if there are any)
        #
        # Return values
        #   'undef' on improper arguments or if the strip object can't be added
        #   Otherwise returns the strip object added

        my ($self, $packageName, $index, %initHash) = @_;

        # Local variables
        my ($winmapObj, $stripObj, $spacing, $posn, $gaugeStripObj);

        # Check for improper arguments
        if (! defined $packageName) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addStripObj', @_);
        }

        # Get the winmap object specified by $self->winmap, or a default winmap, if $self->winmap
        #   is 'undef'
        $winmapObj = $self->getWinmap();

        # Set the position in the ordered list of strip objects at which the new strip object will
        #   be inserted
        if (
            ! defined $index
            || $index < -1           # Sanity check
            || $index >= scalar ($self->stripList)
        ) {
            $index = 0;
        }

        # Strip objects must inherit from GA::Generic::Strip and must exist (in the case of strip
        #   objects loaded from a plugin)
        if (
            ! $packageName =~ m/^Games\:\:Axmud\:\:Strip\:\:/
            || ! $axmud::CLIENT->ivExists('customStripHash', $packageName)
        ) {
            return undef;
        }

        # Create the strip object
        $stripObj = $packageName->new($self->stripCount, $self, %initHash);
        if (! $stripObj) {

            return undef;
        }

        # Some strip objects are 'jealous' (only one can be opened per window). If so, and if
        #   another strip object of this type has already been created, discard the new one
        if ($stripObj->jealousyFlag && $self->ivExists('firstStripHash', $packageName)) {

            return undef;
        }

        # Some strip objects can't be added in Axmud blind mode
        if (! $stripObj->blindFlag && $axmud::BLIND_MODE_FLAG) {

            return undef;
        }

        # Draw the strip object's widgets
        if (! $stripObj->objEnable($winmapObj)) {

            return undef;

        } else {

            if ($stripObj->allowFocusFlag) {
                $stripObj->packingBox->set_can_focus(TRUE);
            } else {
                $stripObj->packingBox->set_can_focus(FALSE);
            }
        }

        # Make the strip object visible, if the flag is set
        if ($stripObj->visibleFlag) {

            # Pack the newly-visible strip, leaving a gap if it's not at the beginning or end of the
            #   list
            # If $index is -1, it means 'pack at the end'
            if ($index == 0 || $index == -1) {
                $spacing = 0;
            } else {
                $spacing = $self->stripSpacingPixels;
            }

            if ($index > -1) {

                $self->packingBox->pack_start(
                    $stripObj->packingBox,
                    $stripObj->expandFlag,
                    $stripObj->fillFlag,
                    $spacing,
                );

                if ($index > 0) {

                    $self->packingBox->reorder_child($stripObj->packingBox, $posn);
                }

            } else {

                $self->packingBox->pack_end(
                    $stripObj->packingBox,
                    $stripObj->expandFlag,
                    $stripObj->fillFlag,
                    $spacing,
                );
            }
        }

        # Update IVs
        $self->ivAdd('stripHash', $stripObj->number, $stripObj);
        if (! $self->ivExists('firstStripHash', $packageName)) {

            $self->ivAdd('firstStripHash', $packageName, $stripObj);
        }

        $self->ivIncrement('stripCount');
        $self->ivSplice('stripList', $index, 0, $stripObj);

        if ($packageName eq 'Games::Axmud::Strip::Table') {

            $self->ivPoke('tableStripObj', $stripObj);
        }

        # Notify all other strip objects of the new strip object's birth
        foreach my $otherStripObj (
            sort {$a->number <=> $b->number} ($self->ivValues('stripHash'))
        ) {
            if ($otherStripObj ne $stripObj) {

                $otherStripObj->notify_addStripObj($stripObj);
            }
        }

        # Sensitise/desensitise widgets according to current conditions
        $self->restrictMenuBars();
        $self->restrictToolbars();

        # Make everything visible
        $self->winShowAll($self->_objClass . '->addStripObj');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->addStripObj');

        # Adding/removing widgets upsets the position of the scrollbar in each tab's textview.
        #   Make sure all the textviews are scrolled to the bottom
        $self->rescrollTextViews();

        # Redraw any visible gauges, otherwise the gauge box will be visible, but the gauges
        #   themselves will have disappeared
        $gaugeStripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::GaugeBox');
        if ($gaugeStripObj && $gaugeStripObj->visibleFlag) {

            $gaugeStripObj->updateGauges();
            # (Need to call this a second time, or the re-draw doesn't work...)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->addStripObj');
        }

        return $stripObj;
    }

    sub removeStripObj {

        # Can be called by anything
        # Removes a strip object (inheriting from GA::Generic::Strip) from the list of strip objects
        #   that can be displayed in this window (whether the Gtk widget was actually drawn, or not,
        #   depends on the value of the strip object's ->visibleFlag)
        # Can't be used to remove the compulsory GA::Strip::Table object
        #
        # Expected arguments
        #   $stripObj   - The strip object to remove
        #
        # Return values
        #   'undef' on improper arguments, if $stripObj is the compulsory GA::Strip::Table object
        #       or if the object doesn't exist
        #   1 otherwise

        my ($self, $stripObj, $check) = @_;

        # Local variables
        my (
            $gaugeStripObj,
            @stripList, @resetList,
        );

        # Check for improper arguments
        if (! defined $stripObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->removeStripObj', @_);
        }

        # The GA::Strip::Table object is compulsory, also check that the strip object actually
        #   exists in the window
        if (
            $stripObj->_objClass eq 'Games::Axmud::Strip::Table'
            || ! $self->ivExists('stripHash', $stripObj->number)
        ) {
            return undef
        }

        # Tell the strip object it's about to be removed, so it can do any necessary tidying up
        $stripObj->objDestroy();
        # Remove the Gtk3 widget that's contains the whole strip
        $axmud::CLIENT->desktopObj->removeWidget($self->packingBox, $stripObj->packingBox);

        # Remove the object by updating IVs
        $self->ivDelete('stripHash', $stripObj->number);

        foreach my $otherObj ($self->stripList) {

            if ($otherObj ne $stripObj) {

                push (@stripList, $otherObj);
            }
        }

        $self->ivPoke('stripList', @stripList);

        # $self->firstStripHash contains the earliest-created instance of this type of strip object.
        #   Update or reset it
        $self->ivDelete('firstStripHash', $stripObj->_objClass);
        @resetList = sort {$a->number <=> $b->number} ($self->ivValues('stripHash'));
        OUTER: foreach my $otherObj (@resetList) {

            if ($otherObj->_objClass eq $stripObj->_objClass) {

                $self->ivAdd('firstStripHash', $otherObj->_objClass, $otherObj);
                last OUTER;
            }
        }

        # Notify all other strip objects of this strip object's demise
        foreach my $otherStripObj (
            sort {$a->number <=> $b->number} ($self->ivValues('stripHash'))
        ) {
            if ($otherStripObj ne $stripObj) {

                $otherStripObj->notify_removeStripObj($stripObj);
            }
        }

        # Sensitise/desensitise widgets according to current conditions
        $self->restrictMenuBars();
        $self->restrictToolbars();

        # Make everything visible
        $self->winShowAll($self->_objClass . '->removeStripObj');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->removeStripObj');

        # Hack to resolve a Gtk3 issue, in which a white area appears at the bottom of textviews
        #   when the gauge strip object is removed (and possibly in similar situations)
        foreach my $tableObj ($self->tableStripObj->ivValues('tableObjHash')) {

            if ($tableObj->type eq 'pane') {

                foreach my $tabObj ($tableObj->ivValues('tabObjHash')) {

                    $tabObj->textViewObj->insertNewLine();
                }
            }
        }

        # Adding/removing widgets upsets the position of the scrollbar in each tab's textview.
        #   Make sure all the textviews are scrolled to the bottom
        $self->rescrollTextViews();

        # Redraw any visible gauges, otherwise the gauge box will be visible, but the gauges
        #   themselves will have disappeared
        $gaugeStripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::GaugeBox');
        if ($gaugeStripObj && $gaugeStripObj->visibleFlag) {

            $gaugeStripObj->updateGauges();
            # (Need to call this a second time, or the re-draw doesn't work...)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->removeStripObj');
        }

        return 1;
    }

    sub addStrip {

        # Convenient shortcut to $self->addStripObj, which expects a package name like
        #   GA::Strip::GaugeBox as an argument
        #
        # This function accepts a string, which can be any of the following (case-insensitive):
        #   'menu' / 'menubar' / 'menu_bar'                 - adds a GA::Strip::MenuBar
        #   'tool' / 'toolbar' / 'tool_bar'                 - adds a GA::Strip::Toolbar
        #   'gauge' / 'gaugebox' / 'gauge_box'              - adds a GA::Strip::GaugeBox
        #   'entry'                                         - adds a GA::Strip::Entry
        #   'connect' / 'info' / 'connectinfo' / 'connect_info'
        #                                                   - adds a GA::Strip::ConnectInfo
        #
        # The string can also be a part of the package name itself. For example, if you create your
        #   own GA::Strip::MyObject (inheriting from GA::Strip::Custom), then this function expects
        #   the string 'MyObject' (case-sensitive)
        # NB This function is not able to check that the package actually exists, although Axmud's
        #   built-in strip objects always exist
        # NB This function can't be used to add the compulsory GA::Strip::Table which already
        #   exists
        #
        # Expected arguments
        #   $string     - The string described above
        #
        # Optional arguments
        #   $index      - The new strip object's position in the window. Strip objects are stored in
        #                   $self->stripList, in the order in which they're drawn (which could be
        #                   top to bottom, bottom to top, left to right or right to left). $index
        #                   specifies the position in that list at which the new strip object is
        #                   inserted. If $index is 0, the strip object is inserted at the beginning
        #                   of the list. If $index is 1, it's inserted second, if $index is 2, it's
        #                   inserted third, and so on. If $index is 'undef', or if its index is
        #                   outside the list, the strip object is inserted at the beginning of the
        #                   list
        #
        # Return values
        #   'undef' on improper arguments or if the strip object can't be added
        #   Otherwise returns the strip object added

        my ($self, $string, $index, $check) = @_;

        # Local variables
        my $packageName;

        # Check for improper arguments
        if (! defined $string || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addStrip', @_);
        }

        # Convert $string into a package name
        $packageName = $self->convertPackageName($string);
        if (! $packageName || $packageName eq 'Games::Axmud::Strip::Table') {

            return undef;

        } else {

            return $self->addStripObj($packageName, $index);
        }
    }

    sub removeStrip {

        # Convenient shortcut to $self->removeStripObj, which expects a package name like
        #   GA::Strip::GaugeBox as an argument
        #
        # This function accepts a string, which can be any of the following (case-insensitive):
        #   'menu' / 'menubar' / 'menu_bar'                 - adds a GA::Strip::MenuBar
        #   'tool' / 'toolbar' / 'tool_bar'                 - adds a GA::Strip::Toolbar
        #   'gauge' / 'gaugebox' / 'gauge_box'              - adds a GA::Strip::GaugeBox
        #   'entry'                                         - adds a GA::Strip::Entry
        #   'connect' / 'info' / 'connectinfo' / 'connect_info'
        #                                                   - adds a GA::Strip::ConnectInfo
        #
        # The string can also be a part of the package name itself. For example, if you create your
        #   own GA::Strip::MyObject (inheriting from GA::Strip::Custom), then this function expects
        #   the string 'MyObject' (case-sensitive)
        #
        # After converting the string into a package name, this function calls $self->removeStripObj
        #   to remove the earliest-created instance of that strip object, if any exists
        # NB This function is not able to check that the package actually exists, although Axmud's
        #   built-in strip objects always exist
        # NB This function can't be used to remove the compulsory GA::Strip::Table
        #
        # Expected arguments
        #   $string     - The string described above
        #
        # Return values
        #   'undef' on improper arguments or if no strip object is removed
        #   1 if a strip object is removed

        my ($self, $string, $check) = @_;

        # Local variables
        my ($packageName, $stripObj);

        # Check for improper arguments
        if (! defined $string || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->removeStrip', @_);
        }

        # Convert $string into a package name
        $packageName = $self->convertPackageName($string);
        if (! $packageName || $packageName eq 'Games::Axmud::Strip::Table') {

            return undef;
        }

        # Find the earliest-created instance of that strip object
        $stripObj = $self->ivShow('firstStripHash', $packageName);
        if (! $stripObj) {

            return undef;

        } else {

            return $self->removeStripObj($stripObj);
        }
    }

    sub hideStripObj {

        # Can be called by anything
        # Hides a visible strip object; the strip object remains in the list of strip objects this
        #   window can display, but the Gtk widget itself is no longer drawn
        # Can't be used to hide the compulsory GA::Strip::Table object
        #
        # Expected arguments
        #   $stripObj   - The strip object to hide
        #
        # Return values
        #   'undef' on improper arguments, if $stripObj is the compulsory GA::Strip::Table object,
        #       if the object doesn't exist or if it is already hidden
        #   1 otherwise

        my ($self, $stripObj, $check) = @_;

        # Local variables
        my $gaugeStripObj;

        # Check for improper arguments
        if (! defined $stripObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->hideStripObj', @_);
        }

        # The GA::Strip::Table object is compulsory, also check that the strip object actually
        #   exists in the window object's list of strip objects and is actually visible
        if (
            $stripObj->_objClass eq 'Games::Axmud::Strip::Table'
            || ! $self->ivExists('stripHash', $stripObj->number)
            || ! $stripObj->visibleFlag
        ) {
            return undef
        }

        # Remove the Gtk3 widget that contains the whole strip
        $axmud::CLIENT->desktopObj->removeWidget($self->packingBox, $stripObj->packingBox);
        # Update IVs
        $stripObj->set_visibleFlag(FALSE);

        # Sensitise/desensitise widgets according to current conditions
        $self->restrictMenuBars();
        $self->restrictToolbars();

        # Make everything visible
        $self->winShowAll($self->_objClass . '->hideStripObj');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->hideStripObj');

        # Hack to resolve a Gtk3 issue, in which a white area appears at the bottom of textviews
        #   when the gauge strip object is removed (and possibly in similar situations)
        foreach my $tableObj ($self->tableStripObj->ivValues('tableObjHash')) {

            if ($tableObj->type eq 'pane') {

                foreach my $tabObj ($tableObj->ivValues('tabObjHash')) {

                    $tabObj->textViewObj->insertNewLine();
                }
            }
        }

        # Adding/removing widgets upsets the position of the scrollbar in each tab's textview.
        #   Make sure all the textviews are scrolled to the bottom
        $self->rescrollTextViews();

        # Redraw any visible gauges, otherwise the gauge box will be visible, but the gauges
        #   themselves will have disappeared
        $gaugeStripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::GaugeBox');
        if ($gaugeStripObj && $gaugeStripObj->visibleFlag) {

            $gaugeStripObj->updateGauges();
            # (Need to call this a second time, or the re-draw doesn't work...)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->hideStripObj');
        }

        return 1;
    }

    sub revealStripObj {

        # Can be called by anything
        # Reveals a hidden strip object; the strip object was  still in the list of strip objects
        #   this window can display, but the Gtk widget itself was not drawn, so draw it and add it
        #   to the window
        #
        # Expected arguments
        #   $stripObj   - The strip object to reveal
        #
        # Return values
        #   'undef' on improper arguments, if the object doesn't exist, if it is already visible or
        #       if there's an error in revealing it
        #   1 otherwise

        my ($self, $stripObj, $check) = @_;

        # Local variables
        my ($winmapObj, $count, $posn, $spacing, $gaugeStripObj);

        # Check for improper arguments
        if (! defined $stripObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->revealStripObj', @_);
        }

        # Get the winmap object specified by $self->winmap, or a default winmap, if $self->winmap
        #   is 'undef'
        $winmapObj = $self->getWinmap();

        # Check that the strip object actually exists in the window object's list of strip objects
        #   and is actually hidden
        if (! $self->ivExists('stripHash', $stripObj->number) || $stripObj->visibleFlag) {

            return undef
        }

        # Find the strip object's position in the list of visible strip objects
        $count = 0;
        OUTER: foreach my $otherObj ($self->stripList) {

            if ($otherObj eq $stripObj) {

                $posn = $count;
                last OUTER;

            } elsif ($otherObj->visibleFlag) {

                $count++;
            }
        }

        if (! defined $posn) {

            # Strip object is missing (for some unlikely reason)
            return undef;
        }

        # Draw the strip object's widgets
        if (! $stripObj->objEnable($winmapObj)) {

            return undef;
        }

        # Pack the newly-visible strip, leaving a gap if it's not at the beginning or end of the
        #   list
        if (! $count || $posn == ($count - 1)) {
            $spacing = 0;
        } else {
            $spacing = $self->stripSpacingPixels;
        }

        $self->packingBox->pack_start(
            $stripObj->packingBox,
            $stripObj->expandFlag,
            $stripObj->fillFlag,
            $spacing,
        );

        if ($posn != 0) {

            $self->packingBox->reorder_child($stripObj->packingBox, $posn);
        }

        # Update IVs
        $stripObj->set_visibleFlag(TRUE);

        # Sensitise/desensitise widgets according to current conditions
        $self->restrictMenuBars();
        $self->restrictToolbars();

        # Make everything visible
        $self->winShowAll($self->_objClass . '->revealStripObj');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->revealStripObj');

        # Adding/removing widgets upsets the position of the scrollbar in each tab's textview.
        #   Make sure all the textviews are scrolled to the bottom
        $self->rescrollTextViews();

        # Redraw any visible gauges, otherwise the gauge box will be visible, but the gauges
        #   themselves will have disappeared
        $gaugeStripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::GaugeBox');
        if ($gaugeStripObj && $gaugeStripObj->visibleFlag) {

            $gaugeStripObj->updateGauges();
            # (Need to call this a second time, or the re-draw doesn't work...)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->revealStripObj');
        }

        return 1;
    }

    sub replaceStripObj {

        # Can be called by anything
        # If a strip object has been redrawn for any reason, replace the old Gtk widget with the
        #   new one. The strip object's ->packingBox IV must already have been set to the new Gtk
        #   widget before calling this function
        #
        # Expected arguments
        #   $stripObj   - The strip object to replace
        #
        # Return values
        #   'undef' on improper arguments, if the object doesn't exist or if it hidden
        #   1 otherwise

        my ($self, $stripObj, $check) = @_;

        # Local variables
        my ($count, $posn, $spacing, $gaugeStripObj);

        # Check for improper arguments
        if (! defined $stripObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->replaceStripObj', @_);
        }

        # Check that the strip object actually exists in the window object's list of strip objects
        #   and is actually visible
        if (! $self->ivExists('stripHash', $stripObj->number) || ! $stripObj->visibleFlag) {

            return undef
        }

        # Find the strip object's position in the list of visible strip objects
        $count = 0;
        OUTER: foreach my $otherObj ($self->stripList) {

            if ($otherObj eq $stripObj) {

                $posn = $count;
                last OUTER;

            } elsif ($otherObj->visibleFlag) {

                $count++;
            }
        }

        if (! defined $posn) {

            # Strip object is missing (for some unlikely reason)
            return undef;
        }


        # Remove the old Gtk3 widget that contains the whole strip
        $axmud::CLIENT->desktopObj->removeWidget($self->packingBox, $stripObj->packingBox);
        # Pack the newly-visible strip, leaving a gap if it's not at the beginning or end of the
        #   list
        if (! $count || $posn == ($count - 1)) {
            $spacing = 0;
        } else {
            $spacing = $self->stripSpacingPixels;
        }

        $self->packingBox->pack_start(
            $stripObj->packingBox,
            $stripObj->expandFlag,
            $stripObj->fillFlag,
            $spacing,
        );

        if ($posn != 0) {

            $self->packingBox->reorder_child($stripObj->packingBox, $posn);
        }

        # Sensitise/desensitise widgets according to current conditions
        $self->restrictMenuBars();
        $self->restrictToolbars();

        # Make everything visible
        $self->winShowAll($self->_objClass . '->replaceStripObj');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->replaceStripObj');

        # Redraw any visible gauges, otherwise the gauge box will be visible, but the gauges
        #   themselves will have disappeared
        $gaugeStripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::GaugeBox');
        if ($gaugeStripObj && $gaugeStripObj->visibleFlag) {

            $gaugeStripObj->updateGauges();
            # (Need to call this a second time, or the re-draw doesn't work...)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->replaceStripObj');
        }

        return 1;
    }

    sub getStrip {

        # Convenient method for getting the blessed reference of the earliest-created instance of a
        #   type of strip object
        #
        # This function accepts a string, which can be any of the following (case-insensitive):
        #   'menu' / 'menubar' / 'menu_bar'                 - converts to GA::Strip::MenuBar
        #   'tool' / 'toolbar' / 'tool_bar'                 - converts to GA::Strip::Toolbar
        #   'table'                                         - converts to GA::Strip::Table
        #   'gauge' / 'gaugebox' / 'gauge_box'              - converts to GA::Strip::GaugeBox
        #   'search' / 'searchbox' / 'search_box'           - converts to GA::Strip::SearchBox
        #   'entry'                                         - converts to GA::Strip::Entry
        #   'connect' / 'info' / 'connectinfo' / 'connect_info'
        #                                                   - converts to GA::Strip::ConnectInfo
        #
        # The string can also be a part of the package name itself. For example, if you create your
        #   own GA::Strip::MyObject (inheriting from GA::Strip::Custom), then this function expects
        #   the string 'MyObject' (case-sensitive)
        #
        # Expected arguments
        #   $string     - The string described above
        #
        # Return values
        #   'undef' on improper arguments or if a strip object of that type doesn't exist in the
        #       window
        #   Otherwise returns the blessed reference to the earliest-created instance of the
        #       specified type of strip object

        my ($self, $string, $check) = @_;

        # Local variables
        my $packageName;

        # Check for improper arguments
        if (! defined $string || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->getStrip', @_);
        }

        # Convert $string into a package name
        $packageName = $self->convertPackageName($string);
        if (! $packageName || $packageName eq 'Games::Axmud::Strip::Table') {

            return undef;
        }

        # Return the earliest-created instance of that strip object (return 'undef' if none exists)
        return $self->ivShow('firstStripHash', $packageName);
    }

    sub convertPackageName {

        # Called by $self->addStrip, ->getStrip and $self->removeStrip
        # Converts a simple string (e.g. 'menu' into the package name of a strip object (e.g.
        #   'Games::Axmud::Strip::MenuBar'
        #
        # This function accepts a string, which can be any of the following (case-insensitive):
        #   'menu' / 'menubar' / 'menu_bar'                 - converts to GA::Strip::MenuBar
        #   'tool' / 'toolbar' / 'tool_bar'                 - converts to GA::Strip::Toolbar
        #   'table'                                         - converts to GA::Strip::Table
        #   'gauge' / 'gaugebox' / 'gauge_box'              - converts to GA::Strip::GaugeBox
        #   'search' / 'searchbox' / 'search_box'           - converts to GA::Strip::SearchBox
        #   'entry'                                         - converts to GA::Strip::Entry
        #   'connect' / 'info' / 'connectinfo' / 'connect_info'
        #                                                   - converts to GA::Strip::ConnectInfo
        #
        # The string can also be a part of the package name itself. For example, if you create your
        #   own GA::Strip::MyObject (inheriting from GA::Strip::Custom), then this function expects
        #   the string 'MyObject' (case-sensitive)
        #
        # Expected arguments
        #   $string     - The string to convert
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a strip object's package name

        my ($self, $string, $check) = @_;

        # Local variables
        my $packageName;

        # Check for improper arguments
        if (! defined $string || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->convertPackageName', @_);
        }

        if (
            lc($string) eq 'menu' || lc($string) eq 'menubar' || lc($string) eq 'menu_bar'
        ) {
            $packageName = 'Games::Axmud::Strip::MenuBar';

        } elsif (
            lc($string) eq 'tool' || lc($string) eq 'toolbar' || lc($string) eq 'tool_bar'
        ) {
            $packageName = 'Games::Axmud::Strip::Toolbar';

        } elsif (
            lc($string) eq 'gauge' || lc($string) eq 'gaugebox' || lc($string) eq 'gauge_box'
        ) {
            $packageName = 'Games::Axmud::Strip::GaugeBox';

        } elsif (
            lc($string) eq 'search' || lc($string) eq 'searchbox' || lc($string) eq 'search_box'
        ) {
            $packageName = 'Games::Axmud::Strip::SearchBox';

        } elsif (lc($string) eq 'entry') {

            $packageName = 'Games::Axmud::Strip::Entry';

        } elsif (
            lc($string) eq 'connect' || lc($string) eq 'info' || lc($string) eq 'connectinfo'
            || lc($string) eq 'connect_info'
        ) {
            $packageName = 'Games::Axmud::Strip::ConnectInfo';

        } else {

            $packageName = 'Games::Axmud::Strip::' . $string;
        }

        return $packageName;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub stripHash
        { my $self = shift; return %{$self->{stripHash}}; }
    sub firstStripHash
        { my $self = shift; return %{$self->{firstStripHash}}; }
    sub stripCount
        { $_[0]->{stripCount} }
    sub stripList
        { my $self = shift; return @{$self->{stripList}}; }
    sub tableStripObj
        { $_[0]->{tableStripObj} }
    sub stripSpacingPixels
        { $_[0]->{stripSpacingPixels} }

    sub visibleSession
        { $_[0]->{visibleSession} }

    sub hostLabelText
        { $_[0]->{hostLabelText} }
    sub timeLabelText
        { $_[0]->{timeLabelText} }

    sub ctrlKeyFlag
        { $_[0]->{ctrlKeyFlag} }
    sub shiftKeyFlag
        { $_[0]->{shiftKeyFlag} }
    sub altKeyFlag
        { $_[0]->{altKeyFlag} }
    sub altGrKeyFlag
        { $_[0]->{altGrKeyFlag} }
    sub modifierKeyFlag
        { $_[0]->{modifierKeyFlag} }

    sub actualWinWidth
        { $_[0]->{actualWinWidth} }
    sub actualWinHeight
        { $_[0]->{actualWinHeight} }
    sub maximisedFlag
        { $_[0]->{maximisedFlag} }
    sub focusFlag
        { $_[0]->{focusFlag} }
}

# Package must return a true value
1
