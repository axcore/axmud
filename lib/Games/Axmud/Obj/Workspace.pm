# Copyright (C) 2011-2024 A S Lewis
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
# Games::Axmud::Obj::Workspace
# The workspace object. Arranges windows on a workspace grid on a single workspace

{ package Games::Axmud::Obj::Workspace;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Desktop->add_workspace()
        #
        # Expected arguments
        #   $number     - Unique number for this workspace object
        #   $systemNum  - The corresponding system workspace number (0 if not known)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $systemNum, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $systemNum || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'workspace_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # Unique number for this workspace object (across all sessions)
            number                      => $number,
            # The corresponding system workspace number (0 if not known)
            systemNum                   => $systemNum,

            # The current size of the workspace, set by $self->start
            currentWidth                => undef,
            currentHeight               => undef,
            # The size of any panels detected by the call to $self->findPanelSize, which tries to
            #   detect panel sizes for this workspace. If detection fails, it uses values specified
            #   by IVs in GA::Client instead
            panelLeftSize               => undef,
            panelRightSize              => undef,
            panelTopSize                => undef,
            panelBottomSize             => undef,
            # The size of window controls detected by the call to $self->findWinControlSize, which
            #   creates test windows to determine the sizes. If the test fails, Axmud uses values
            #   specified by GA::Client instead
            controlsLeftSize            => undef,
            controlsRightSize           => undef,
            controlsTopSize             => undef,
            controlsBottomSize          => undef,

            # Registry hash of workspace grid objects that have been created on this workspace (a
            #   subset of GA::Obj::Desktop->gridHash). Hash in the form
            #   $gridHash{number} = blessed_reference_to_workspace_grid_object
            gridHash                    => {},
            # In some cases workspace grids are not enabled on this workspace, in which case this
            #   flag is set by $self->start
            #       TRUE    - workspace grids are enabled on this workspace (the default setting)
            #       FALSE   - workspace grids are disabled on this workspace (and this is the only
            #                   workspace used by Axmud - see comments in GA::Obj::Desktop->new).
            #                   Axmud doesn't change the position of any windows, which are left
            #                   where the system's window manager puts them. Window controls are
            #                   compulsory
            gridEnableFlag              => TRUE,
            # The name of the default zonemap to use for this workspace (which initially depends on
            #   GA::Client->initWorkspaceHash). Set only while $self->gridEnableFlag remains set
            #   to TRUE
            defaultZonemap              => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    sub start {

        # Called by GA::Obj::Desktop->start for the default (first) workspace and by
        #   GA::Obj::Desktop->useWorkspace thereafter
        # Finds the actual size of the available workspace available to Axmud (the total workspace,
        #   minus any panels/taskbars), if possible. If not possible, artificially sets the size
        #   of the available workspace according to various IVs
        #
        # Expected arguments
        #   $zonemap    - The default zonemap to use for this workspace
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $zonemap, $check) = @_;

        # Local variables
        my ($screen, $msg);

        # Check for improper arguments
        if (! defined $zonemap || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->start', @_);
        }

        if (! $axmud::CLIENT->desktopObj->gridPermitFlag) {

            # Workspace grids are disabled in general
            $self->ivPoke('gridEnableFlag', FALSE);

        } else {

            # Test whether the workspace is too small
            # NB Due to technical limitations, we assume that the values returned by this test
            #   apply to all workspaces, on systems where multiple workspaces are available
            $screen = Gtk3::Gdk::Screen::get_default();
            $self->ivPoke('currentWidth', $screen->get_width());
            $self->ivPoke('currentHeight', $screen->get_height());

            if (
                $self->currentWidth < $axmud::CLIENT->constWorkspaceMinWidth
                || $self->currentHeight < $axmud::CLIENT->constWorkspaceMinHeight
            ) {
                # Test failed
                $self->ivPoke('gridEnableFlag', FALSE);

                $axmud::CLIENT->writeWarning(
                    'Workspace ' . $self->number . ' smaller than minimum - disabling workspace'
                    . ' grids',
                    $self->_objClass . '->start',
                );
            }
        }

        if ($self->gridEnableFlag && $self->currentWidth && $self->currentHeight) {

            # Set the default zonemap for this workspace
            $self->ivPoke('defaultZonemap', $zonemap);

            # Test whether the workspace is too big and, if so, reduce the size of the available
            #   workspace used by workspace grids
            if (
                $self->currentWidth > $axmud::CLIENT->constWorkspaceMaxWidth
                && $self->currentHeight > $axmud::CLIENT->constWorkspaceMaxHeight
            ) {
                $self->ivPoke('currentWidth', $axmud::CLIENT->constWorkspaceMaxWidth);
                $self->ivPoke('currentHeight', $axmud::CLIENT->constWorkspaceMaxHeight);
                $msg = 'Desktop width and height';

            } elsif ($self->currentWidth > $axmud::CLIENT->constWorkspaceMaxWidth) {

                $self->ivPoke('currentWidth', $axmud::CLIENT->constWorkspaceMaxWidth);
                $msg = 'Desktop width';

            } elsif ($self->currentHeight > $axmud::CLIENT->constWorkspaceMaxHeight) {

                $self->ivPoke('currentHeight', $axmud::CLIENT->constWorkspaceMaxHeight);
                $msg = 'Desktop height';
            }

            if ($msg) {

                $axmud::CLIENT->writeWarning(
                    $msg . ' exceeds maximum, reducing desktop size to '
                        . $self->currentWidth . 'x' . $self->currentHeight,
                    $self->_objClass . '->setup',
                );
            }

            # Find the size of panels (taskbars), if possible
            $self->findPanelSize();
        }

        # Find the size of the window controls on this workspace, by creating two test windows in
        #   opposite corners and checking their actual size and position with what was expected
        $self->findWinControlSize();

        # If workspace grids are enabled, set up workspace grids for each existing session (but
        #   don't set up any workspace grids if there are no sessions running yet; each new session
        #   creates its own workspace grids)
        if ($axmud::CLIENT->sessionHash) {

            if (! $axmud::CLIENT->shareMainWinFlag) {

                # Create a shared workspace grid
                $self->addWorkspaceGrid();

            } else {

                # Create a workspace grid for each existing session
                foreach my $session ($axmud::CLIENT->listSessions()) {

                    $self->addWorkspaceGrid($session);
                }
            }
        }

        # Operation complete
        return 1;
    }

    sub stop {

        # Called by GA::Obj::Desktop->del_workspace and (for the default workspace) by
        #   GA::Obj::Desktop->stop
        # Shuts down any workspace grid objects for this workspace (which closes its windows)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($count, $msg);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->stop', @_);
        }

        # Close down workspace grid objects
        foreach my $gridObj (sort {$a->number <=> $b->number} ($self->ivValues('gridHash'))) {

            $self->removeWorkspaceGrid($gridObj);
        }

        # Check there are no workspace grids left (for error-detection purposes)
        $count = $self->ivPairs('gridHash');
        if ($count) {

            if ($count == 1) {
                $msg = 'There was 1';
            } else {
                $msg = 'There were ' . $count;
            }

            $msg .= ' un-closed workspace grids when the parent workspace closed';

            $axmud::CLIENT->writeWarning($msg, $self->_objClass . '->stop');
        }

        # In certain (rare) circumstances (such as when Axmud starts in blind mode, and the user
        #   manually closes the dialogue window created by GA::Client->connectBlind), the spare
        #   'main' window will still exist. If it does, close it now to prevent an error
        if (
            $axmud::CLIENT->mainWin
            && $axmud::CLIENT->mainWin->owner eq $axmud::CLIENT
            && $axmud::CLIENT->mainWin->workspaceObj eq $self
        ) {
            $axmud::CLIENT->mainWin->winDestroy();
        }

        return 1;
    }

    # General functions

    sub addWorkspaceGrid {

        # Called by $self->start or GA::Session->setMainWin
        # Adds a workspace grid object to this workspace, and sets it up (if allowed)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $session    - (GA::Client->shareMainWinFlag = TRUE) The GA::Session object which
        #                   controls this workspace grid
        #               - (GA::Client->shareMainWinFlag = FALSE) 'undef' (the grid is shared between
        #                   all sessions)
        #   $zonemap    - The zonemap to use to set up the workspace grid object. If 'undef',
        #                   $self->defaultZonemap is used
        #
        # Return values
        #   'undef' on improper arguments, if workspace grids can't be created in general or if
        #       the operation fails
        #   Otherwise returns workspace grid object added

        my ($self, $session, $zonemap, $check) = @_;

        # Local variables
        my ($gridObj, $result);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addWorkspaceGrid', @_);
        }

        if (
            # Workspace grids are disactivated generally (at the user's request)
            ! $axmud::CLIENT->activateGridFlag
            # Axmud cannot create workspace grids, because the desktop is too small, etc
            || ! $axmud::CLIENT->desktopObj->gridPermitFlag
            # # Workspace grids are disabled on this workspace
            || ! $self->gridEnableFlag
        ) {
            # Workspace grids are disabled on this workspace
            return undef;
        }

        # Add the workspace grid object
        $gridObj = $axmud::CLIENT->desktopObj->add_grid($self, $session);
        if (! $gridObj) {

            # Operation failed
            return undef;

        } else {

            # Also update our own IV
            $self->ivAdd('gridHash', $gridObj->number, $gridObj);
        }

        # Set up the new workspace grid object
        if ($zonemap) {
            $result = $gridObj->start($zonemap);
        } else {
            $result = $gridObj->start($self->defaultZonemap);
        }

        if (! $result) {

            # Setup failed; discard this workspace grid
            $axmud::CLIENT->desktopObj->del_grid($gridObj);
            $self->ivDelete('gridHash', $gridObj->number);

            return undef;

        } else {

            return $gridObj;
        }
    }

    sub removeWorkspaceGrid {

        # Called by $self->stop, ->disableWorkspaceGrids and
        #   GA::Obj::Desktop->removeSessionWorkspaceGrids
        # Removes a workspace grid object from this workspace (which closes all its windows), and
        #   informs GA::Obj::Desktop
        #
        # Expected arguments
        #   $gridObj    - The GA::Obj::WorkspaceGrid to remove
        #
        # Optional arguments
        #   $session    - If defined, that session's 'main' window is disengaged (removed from its
        #                   workspace grid, but not destroyed)
        #
        # Return values
        #   'undef' on improper arguments or if the operation fails
        #   1 otherwise

        my ($self, $gridObj, $session, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeWorkspaceGrid', @_);
        }

        # Shut down the workspace grid object
        if (! $axmud::CLIENT->desktopObj->del_grid($gridObj, $session)) {

            return undef;

        } else {

            # Update our own IVs
            $self->ivDelete('gridHash', $gridObj->number);

            return 1;
        }
    }

    sub enableWorkspaceGrids {

        # Called by GA::Obj::Desktop->activateWorkspaceGrids and GA::Cmd::ActivateGrid->do
        # Enables workspace grids on this workspace. Creates workspace grids for every session (or a
        #   single workspace grid, if sessions don't share a 'main' window), places existing
        #   windows on the correct grid and updates IVs
        # If grids are already enabled on this workspace, does nothing
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $zonemap    - If specified, the name of the zonemap (matches a key in
        #                   GA::Client->zonemapHash) to be used as the default zonemap on this
        #                   workspace (and which is applied to every new workspace grid)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $zonemap, $check) = @_;

        # Local variables
        my (
            $zonemapObj,
            @gridList, @winList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->enableWorkspaceGrids', @_);
        }

        if (! $self->gridEnableFlag) {

            # Update IVs
            $self->ivPoke('gridEnableFlag', TRUE);

            # If a zonemap was specified, it's the default zonemap for this workspace
            if (defined $zonemap && $axmud::CLIENT->ivExists('zonemapHash', $zonemap)) {

                $self->ivPoke('defaultZonemap', $zonemap);
            }

            # Get a sorted list of 'grid' window objects
            @winList = sort {$a->number <=> $b->number}
                        ($axmud::CLIENT->desktopObj->ivValues('gridWinHash'));

            # Create workspace grids
            if ($axmud::CLIENT->shareMainWinFlag) {

                # Create a grid for every session
                foreach my $session ($axmud::CLIENT->listSessions()) {

                    my $gridObj = $self->addWorkspaceGrid($session, $zonemap);
                    if ($gridObj) {

                        push (@gridList, $gridObj);

                        # All 'grid' windows on this workspace controlled by the session should be
                        #   placed onto this grid. Start by updating the workspace object's IV
                        foreach my $winObj (@winList) {

                            if (
                                $winObj->workspaceObj eq $self
                                && $winObj->session
                                && $winObj->session eq $session
                            ) {
                                $gridObj->add_gridWin($winObj);
                            }
                        }
                    }
                }

            } else {

                # Create a single grid shared by all sessions
                my $gridObj = $self->addWorkspaceGrid(undef, $zonemap);
                if ($gridObj) {

                    push (@gridList, $gridObj);

                    # All 'grid' windows on this workspace controlled by the session should be
                    #   placed onto this grid. Start by updating the workspace object's IV
                    foreach my $winObj (@winList) {

                        if ($winObj->workspaceObj eq $self) {

                            $gridObj->add_gridWin($winObj);
                        }
                    }
                }
            }

            # Get the default zonemap object for this workspace
            $zonemapObj = $axmud::CLIENT->ivShow('zonemapHash', $self->defaultZonemap);

            # For any workspace grid object assigned a window, we can use the normal reset code to
            #   have the windows places on the grid, as if they had been opened there
            foreach my $gridObj (@gridList) {

                if ($gridObj->gridWinHash) {

                    $gridObj->applyZonemap($zonemapObj);
                }
            }
        }

        return 1;
    }

    sub disableWorkspaceGrids {

        # Called by GA::Obj::Desktop->disactivateWorkspaceGrids and GA::Cmd::DisactivateGrid->do
        # Disables workspace grids on this workspace and updates IVs. If grids are already
        #   disabled on this workspace, does nothing
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->disableWorkspaceGrids', @_);
        }

        if ($self->gridEnableFlag) {

            foreach my $gridObj ($self->ivValues('gridHash')) {

                my @list;

                # Import the grid's windows and reset its IVs, so that the windows aren't closed
                #   when the grid object is removed
                @list = $gridObj->ivValues('gridWinHash');
                $gridObj->reset_gridWinHash();

                # Remove the workspace grid
                $self->removeWorkspaceGrid($gridObj);

                # Update the window object's IVs
                foreach my $winObj (@list) {

                    $winObj->set_workspaceGridObj();
                    $winObj->set_areaObj();
                }
            }

            # Update IVs
            $self->ivPoke('gridEnableFlag', FALSE);
        }

        return 1;
    }

    sub findWorkspaceGrid {

        # Can be called by anything
        # If GA::Client->shareMainWinFlag is TRUE, each session controls a different workspace
        #   grid in this workspace. Finds the workspace grid object controlled by a specified
        #   session, and returns it
        # If GA::Client->shareMainWinFlag is FALSE, all sessions share a single workspace grid on
        #   each workspace. Returns the shared workspace grid object
        #
        # Expected arguments
        #   $session    - The GA::Session which controls a workspace grid
        #
        # Return values
        #   'undef' on improper arguments or if there are no matching workspace grid objects
        #   Otherwise returns the first matching GA::Obj::WorkspaceGrid object

        my ($self, $session, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findWorkspaceGrid', @_);
        }

        # Sort workspace grid objects in the order in which they were created (there shouldn't be
        #   more than one workspace grid object controlled by a particular session, nor should
        #   there be more than one workspace grid object controlled by no sessions, but we'll
        #   return the earliest-created one anyway)
        @list = sort {$a->number <=> $b->number} ($self->ivValues('gridHash'));

        if (! $axmud::CLIENT->shareMainWinFlag) {

            # All sessions share a workspace grid
            return $list[0];

        } else {

            # Find a workspace grid object controlled a GA::Session, if one was specified
            foreach my $obj (@list) {

                if (! defined $obj->owner || $obj->owner eq $session) {

                    return $obj;
                }
            }
        }

        # No matching workspace grid found
        return undef;
    }

    sub findPanelSize {

        # Called by $self->start or GA::Cmd::TestPanel->do
        # Tries to find the sizes of any panels (taskbars) on this workspace. (It's rather unlikely
        #   that different workspaces will use different panel sizes, but Axmud checks panel sizes
        #   on every workspace it uses anyway)
        # If the test succeeds, uses those sizes to reduce the size of the available workspace by
        #   setting $self->panelLeftSize, etc. (If GA::Client->customPanelLeftSize (etc) are set,
        #   those values take precedence over the test values)
        # If the test fails and $self->panelLeftSize (etc) have never been set for this workspace,
        #   sets them using GA::Client->customPanelLeftSize or ->constPanelLeftSize (etc)
        #
        # Returns the actual sizes detected - not the new values of $self->panelLeftSize, etc
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $timeout    - A timeout for the test, in seconds. If not defined, a default timeout is
        #                   used
        #
        # Return values
        #   An empty list on improper arguments or if the test fails
        #   Otherwise returns the detected sizes of panels/taskbars detected (which might not match
        #       the values stored in $self->panelLeftSize, etc), a list in the form
        #       (left, right, top, bottom)

        my ($self, $timeout, $check) = @_;

        # Local variables
        my (
            $xPos, $yPos, $width, $height, $left, $right, $top, $bottom,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findPanelSize', @_);
            return @emptyList;
        }

        # Try to detect panel sizes
        ($xPos, $yPos, $width, $height) = $self->testPanelSize($timeout);
        # If the test succeeded, perform some sanity checking (just in case)
        if (defined $xPos && ($xPos < 0 || $yPos < 0 || $width < 0 || $height < 0)) {

            # Sanity check fails, therefore the test fails
            $xPos = undef;
        }

        # Respond to the test
        if (! defined $xPos) {

            # Test failed

            # If panel sizes have never been set for this workspace, set them now
            if (! defined $self->controlsLeftSize) {

                if (defined $axmud::CLIENT->customPanelLeftSize) {
                    $self->ivPoke('panelLeftSize', $axmud::CLIENT->customPanelLeftSize);
                } else {
                    $self->ivPoke('panelLeftSize', $axmud::CLIENT->constPanelLeftSize);
                }

                if (defined $axmud::CLIENT->customPanelRightSize) {
                    $self->ivPoke('panelRightSize', $axmud::CLIENT->customPanelRightSize);
                } else {
                    $self->ivPoke('panelRightSize', $axmud::CLIENT->constPanelRightSize);
                }

                if (defined $axmud::CLIENT->customPanelTopSize) {
                    $self->ivPoke('panelTopSize', $axmud::CLIENT->customPanelTopSize);
                } else {
                    $self->ivPoke('panelTopSize', $axmud::CLIENT->constPanelTopSize);
                }

                if (defined $axmud::CLIENT->customPanelBottomSize) {
                    $self->ivPoke('panelBottomSize', $axmud::CLIENT->customPanelBottomSize);
                } else {
                    $self->ivPoke('panelBottomSize', $axmud::CLIENT->constPanelBottomSize);
                }
            }

            return @emptyList;

        } else {

            # Test successful. Work out panel sizes
            $left = $xPos;
            $right = $self->currentWidth - $width - $left;
            $top = $yPos;
            $bottom = $self->currentHeight - $height - $top;

            # Store the detected sizes unless GA::Client->customPanelLeftSize (etc) are set, as
            #   those values take precedence
            if (defined $axmud::CLIENT->customPanelLeftSize) {
                $self->ivPoke('panelLeftSize', $axmud::CLIENT->customPanelLeftSize);
            } else {
                $self->ivPoke('panelLeftSize', $left);
            }

            if (defined $axmud::CLIENT->customPanelRightSize) {
                $self->ivPoke('panelRightSize', $axmud::CLIENT->customPanelRightSize);
            } else {
                $self->ivPoke('panelRightSize', $right);
            }

            if (defined $axmud::CLIENT->customPanelTopSize) {
                $self->ivPoke('panelTopSize', $axmud::CLIENT->customPanelTopSize);
            } else {
                $self->ivPoke('panelTopSize', $top);
            }

            if (defined $axmud::CLIENT->customPanelBottomSize) {
                $self->ivPoke('panelBottomSize', $axmud::CLIENT->customPanelBottomSize);
            } else {
                $self->ivPoke('panelBottomSize', $bottom);
            }

            # Return the results of the test (not the size of the available workspace)
            return ($left, $right, $top, $bottom);
        }
    }

    sub testPanelSize {

        # Called by $self->findPanelSize
        # Creates a maximised test window and returns its position and size
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $timeout    - A timeout, in seconds. If not defined, a default timeout is used
        #
        # Return values
        #   An empty list on improper arguments or if the test fails
        #   Otherwise returns the detected sizes of panels/taskbars detected, a list in the form
        #       (left, right, top, bottom)

        my ($self, $timeout, $check) = @_;

        # Local variables
        my (
            $testWinName, $initSize, $startTime, $checkTime, $regionX, $regionY, $regionWidth,
            $regionHeight,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->testPanelSize', @_);
            return @emptyList;
        }

        # Prepare the test window's title bar
        $testWinName = $axmud::SCRIPT . ' panel test';
        # The test window's size can be measured once it is no longer its original size
        $initSize = 100;
        # If no timeout was specified, use the default one
        if (! defined $timeout) {

            $timeout = 1;
        }

        # Create a test window with maximum opacity, so the user doesn't see it
        my $testWin = Gtk3::Window->new('toplevel');
        $testWin->set_title($testWinName);
        $testWin->set_border_width(0);
        $testWin->set_size_request($initSize, $initSize);
        $testWin->set_decorated(FALSE);
        $testWin->set_opacity(0);
        $testWin->set_icon_list($axmud::CLIENT->desktopObj->{dialogueWinIconList});
        $testWin->set_skip_taskbar_hint(TRUE);
        $testWin->set_skip_pager_hint(TRUE);
        $testWin->show_all();

        # If using X11::WMCtrl, we can move the test window to the correct workspace (if not, there
        #   is only one workspace in use, anyway)
        if ($axmud::CLIENT->desktopObj->wmCtrlObj) {

            $axmud::CLIENT->desktopObj->wmCtrlObj->move_to($testWinName, $self->systemNum);
        }

        $testWin->maximize();
        $testWin->show_all();

        # Initialise the timeout (a time in seconds)
        $startTime = $axmud::CLIENT->getTime();

        # The window will not become maximised immediately, so we keep looking on a loop until it
        #   does on until the timeout expires
        do {

            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->testWinControls');
            ($regionX, $regionY, $regionWidth, $regionHeight)
                = $self->getWinGeometry($testWin->get_window());

            $checkTime = $axmud::CLIENT->getTime();

        } until (
            ($regionWidth != $initSize && $regionHeight != $initSize)
            || $checkTime > ($startTime + $timeout)
        );

        $testWin->destroy();

        if ($regionWidth == $initSize || $regionHeight == $initSize) {

            # Test failed
            return @emptyList;

        } else {

            # Test successful
            return ($regionX, $regionY, $regionWidth, $regionHeight);
        }
    }

    sub findWinControlSize {

        # Called by $self->start or GA::Cmd::TestWindowControls->do
        # Tries to find the sizes of window controls, the edges around windows added by desktop's
        #   window manager. (It's extremely unlikely that different workspaces will use different
        #   window controls, but Axmud checks windows controls on every workspace it uses anyway)
        # Create two test windows in opposite corners of the workspace and compare their actual size
        #   and position with what was expected
        # If the test succeeds, sets $self->controlsLeftSize, etc. (If
        #   GA::Client->customControlsLeftSize (etc) are set, those values take precedence over
        #   the test values)
        # If the test fails and $self->controlsLeftSize (etc) have never been set for this
        #   workspace, sets them using GA::Client->customControlsLeftSize or
        #   ->constControlsLeftSize (etc)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments or if either test fails
        #   Otherwise returns the detected sizes of window controls (which might not match the
        #       values stored in $self->controlsLeftSize, etc), a list in the form
        #       (left, right, top, bottom)

        my ($self, $check) = @_;

        # Local variables
        my (
            $left, $right, $top, $bottom,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findWinControlSize', @_);
            return @emptyList;
        }

        # Try to detect window controls sizes. Create first test window near the top-left corner of
        #   this workspace
        ($left, $top) = $self->testWinControls(FALSE);
        # Create second test window near the bottom-right corner
        ($right, $bottom) = $self->testWinControls(TRUE);

        # If the test succeeded, perform some sanity checking (just in case)
        if (
            defined $left
            && defined $right
            && (
                $left < 0 || $left > 200
                || $top < 0 || $top > 200
                || $right < 0 || $right > 200
                || $bottom < 0 || $bottom > 200
            )
        ) {
            # Sanity check fails, therefore the test fails
            $left = undef;
        }

        # Respond to the test
        if (! defined $left || ! defined $right) {

            # Test failed

            # If window controls sizes have never been set for this workspace, set them now
            if (! defined $self->controlsLeftSize) {

                if (defined $axmud::CLIENT->customControlsLeftSize) {
                    $self->ivPoke('controlsLeftSize', $axmud::CLIENT->customControlsLeftSize);
                } else {
                    $self->ivPoke('controlsLeftSize', $axmud::CLIENT->constControlsLeftSize);
                }

                if (defined $axmud::CLIENT->customControlsRightSize) {
                    $self->ivPoke('controlsRightSize', $axmud::CLIENT->customControlsRightSize);
                } else {
                    $self->ivPoke('controlsRightSize', $axmud::CLIENT->constControlsRightSize);
                }

                if (defined $axmud::CLIENT->customControlsTopSize) {
                    $self->ivPoke('controlsTopSize', $axmud::CLIENT->customControlsTopSize);
                } else {
                    $self->ivPoke('controlsTopSize', $axmud::CLIENT->constControlsTopSize);
                }

                if (defined $axmud::CLIENT->customControlsBottomSize) {
                    $self->ivPoke('controlsBottomSize', $axmud::CLIENT->customControlsBottomSize);
                } else {
                    $self->ivPoke('controlsBottomSize', $axmud::CLIENT->constControlsBottomSize);
                }
            }

            return @emptyList;

        } else {

            # Test successful

            # DEBUG v2.0
            # MS Windows adds extra pixels to the window width and height (for unknown reasons);
            #   compensate for that, if required
            if ($^O eq 'MSWin32' && $axmud::CLIENT->mswinWinPosnTweakFlag) {

                # N.B. The $top value is OK
                $left = 0;
                $right = 0;
                $bottom = 0;
            }

            # Store the detected sizes unless GA::Client->customControlsLeftSize (etc) are set, as
            #   those values take precedence
            if (defined $axmud::CLIENT->customControlsLeftSize) {
                $self->ivPoke('controlsLeftSize', $axmud::CLIENT->customControlsLeftSize);
            } else {
                $self->ivPoke('controlsLeftSize', $left);
            }

            if (defined $axmud::CLIENT->customControlsRightSize) {
                $self->ivPoke('controlsRightSize', $axmud::CLIENT->customControlsRightSize);
            } else {
                $self->ivPoke('controlsRightSize', $right);
            }

            if (defined $axmud::CLIENT->customControlsTopSize) {
                $self->ivPoke('controlsTopSize', $axmud::CLIENT->customControlsTopSize);
            } else {
                $self->ivPoke('controlsTopSize', $top);
            }

            if (defined $axmud::CLIENT->customControlsBottomSize) {
                $self->ivPoke('controlsBottomSize', $axmud::CLIENT->customControlsBottomSize);
            } else {
                $self->ivPoke('controlsBottomSize', $bottom);
            }

            # Return the results of the test (not the stored controls sizes)
            return ($left, $right, $top, $bottom);
        }
    }

    sub testWinControls {

        # Called by $self->findWinControlSize
        # Creates a test window in one of two opposite corners of this workspace and, by testing its
        #   actual coordinates against its expected coordinates, finds out the size of two of the
        #   window controls used by the current desktop theme
        #
        # Expected arguments
        #   $gravityFlag        - FALSE to use top-left corner, TRUE to use bottom-right corner
        #
        # Return values
        #   Returns an empty list on improper arguments or if the window's position on the desktop
        #       can't be found
        #   Otherwise returns a list in the form
        #       ($gravityFlag = FALSE) - The list (size_of_left_control, size_of_top_control)
        #       ($gravityFlag = TRUE) - The list (size_of_bottom_control, size_of_right_control)

        my ($self, $gravityFlag, $check) = @_;

        # Local variables
        my (
            $testWinName, $testWinSize, $testWinDistance, $checkTime, $matchFlag, $regionX,
            $regionY, $regionWidth, $regionHeight, $clientX, $clientY,
            @emptyList, @nameList,
        );

        # Check for improper arguments
        if (! defined $gravityFlag || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->testWinControls', @_);
            return @emptyList;
        }

        # This test requires that window panels have been set in an earlier call to
        #   $self->findPanelSize; if they haven't, then this test fails
        if (
            ! defined $self->panelLeftSize
            || ! defined $self->panelRightSize
            || ! defined $self->panelTopSize
            || ! defined $self->panelBottomSize
        ) {
            return @emptyList;
        }

        # Prepare the test window's title bar
        if (! $gravityFlag) {
            $testWinName = $axmud::SCRIPT . '_test_1';
        } else {
            $testWinName = $axmud::SCRIPT . '_test_2';
        }

        # Prepare the width and height of the test window in pixels
        $testWinSize = 100;
        # Set the distance from the corner in pixels
        $testWinDistance = 100;

        # Create the test window
        my $testWin = Gtk3::Window->new('toplevel');
        $testWin->set_title($testWinName);
        $testWin->set_border_width(0);
        $testWin->set_size_request($testWinSize, $testWinSize);
        $testWin->set_decorated(TRUE);
        $testWin->set_opacity(0);
        $testWin->set_skip_taskbar_hint(TRUE);
        $testWin->set_skip_pager_hint(TRUE);

        if (! $gravityFlag) {

            # Position the test window near the top-left corner
            $testWin->move(
                ($self->panelLeftSize + $testWinDistance),
                ($self->panelTopSize + $testWinDistance),
            );

        } else {

            # Position the test window near the bottom-right corner
            $testWin->move(
                ($self->currentWidth - $self->panelRightSize - $testWinDistance - $testWinSize),
                ($self->currentHeight - $self->panelBottomSize - $testWinDistance - $testWinSize),
            );
        }

        # Set the window's gravity
        if (! $gravityFlag) {
            $testWin->set_gravity('GDK_GRAVITY_NORTH_WEST');
        } else {
            $testWin->set_gravity('GDK_GRAVITY_SOUTH_EAST');
        }

        # Use standard 'dialogue' window icons
        $testWin->set_icon_list($axmud::CLIENT->desktopObj->{dialogueWinIconList});

        # Make the window visible, briefly
        $testWin->show_all();
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->testWinControls');

        # If using X11::WMCtrl, we can move the test window to the correct workspace (if not, there
        #   is only one workspace in use, anyway)
        if ($axmud::CLIENT->desktopObj->wmCtrlObj) {

            # Very rarely, the call to X11::WMCtrl->get_windows() produces an unexplainable error.
            #   This nudge seems to prevent it from happening
            $axmud::CLIENT->desktopObj->wmCtrlObj->get_window_manager();

            # In some cases, X11::WMCtrl doesn't know about the test window (despite the call to
            #   ->updateWidgets just above). Wait for up to a second and, if X11::WMCtrl still
            #   hasn't spotted the new window, regard the test as a failure
            $checkTime = $axmud::CLIENT->getTime() + 1;
            do {

                OUTER: foreach my $hashRef ($axmud::CLIENT->desktopObj->wmCtrlObj->get_windows()) {

                    if ($$hashRef{'title'} eq $testWinName) {

                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }

            } until ($matchFlag || $axmud::CLIENT->getTime() > $checkTime);

            if (! $matchFlag) {

                # Test failed
                return @emptyList;

            } else {

                # Can move the window to its workspace without triggering an error (providing we do
                #   a quick ->updateWidgets first)
                $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->testWinControls');
                $axmud::CLIENT->desktopObj->wmCtrlObj->move_to($testWinName, $self->systemNum);
            }
        }

        # Get the window's actual position on the desktop
        ($regionX, $regionY, $regionWidth, $regionHeight, $clientX, $clientY)
            = $self->getWinGeometry($testWin->get_window());

        # Destroy the test window, now that we have all the data we want
        $testWin->destroy();

        # Return the window controls sizes as a list
        if (! $gravityFlag) {

            # Return size of the left and top window controls
            return (
                ($clientX - ($self->panelLeftSize + $testWinDistance)),
                ($clientY - ($self->panelTopSize + $testWinDistance)),
            )

        } else {

            # Return size of the right and bottom window controls
            return (
                (
                    $self->currentWidth - $self->panelRightSize - $testWinDistance - $testWinSize
                    - $clientX
                ),
                (
                    $self->currentHeight - $self->panelBottomSize - $testWinDistance - $testWinSize
                    - $clientY
                ),
            )
        }
    }

    sub getWinGeometry {

        # Can be called by any function, e.g. by $self->testWinControls
        # Gets the actual size and position of a Gdk::Window
        #
        # Expected arguments
        #   $gdkWin     - The Gdk::Window to use
        #
        # Return values
        #   An empty list on improper arguments or if the test fails
        #   Otherwise a list in groups of 4, showing the size and position of the window region (the
        #       window's visible size and position), and then the size and position of the window's
        #       client area (i.e. not taking into account the window's title bar):
        #       (
        #           $regionX, $regionY, $regionWidth, $regionHeight,
        #           $clientX, $clientY, $clientWidth, $clientHeight,
        #       )

        my ($self, $gdkWin, $check) = @_;

        # Local variables
        my (
            $regionX, $regionY, $clientX, $clientY, $clientWidth, $clientHeight,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $gdkWin || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getWinGeometry', @_);
            return @emptyList;
        }

        # Make sure all drawing operations are complete
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->getWinGeometry');

        # Get the position of the visible window
        ($regionX, $regionY) = $gdkWin->get_root_origin();
        # Get the position of the window's client area
        ($clientX, $clientY) = $gdkWin->get_origin();
        # Get the size of the window's client area; the size of the window region can be calculated
        #   by adding the ttitle bar
        $clientWidth = $gdkWin->get_width();
        $clientHeight = $gdkWin->get_height();

        # Return the results
        return (
            $regionX,
            $regionY,
            $clientWidth + ($clientX - $regionX),
            $clientHeight + ($clientY - $regionY),
            $clientX,
            $clientY,
            $clientWidth,
            $clientHeight,
        );
    }

    sub matchWinList {

        # Called GA::GrabWindowCmd->do or any other code
        # Compares a list of patterns - e.g. ('Notepad', 'Firefox') - against a list of windows on
        #   this workspace. Returns a list of internal IDs for the matching windows
        # The patterns are treated as regexes (so 'Notepad' and '^Note' are both acceptable). The
        #   pattern match is case-insensitive
        #
        # NB This function does nothing if X11::WMCtrl is not available
        #
        # Expected arguments
        #   $number         - The number of windows to match. 1 - return only the first matching
        #                       window; 7 - return only the first 7 matching windows, 0 - return all
        #                       matching windows
        #
        # Optional arguments
        #   @patternList    - A list of patterns matching one or more window titles. If an empty
        #                       list, no matching occurs
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list (which may be an empty list) in groups of 2 for each matching
        #       window, in the form
        #           (window_title, window_internal_id)

        my ($self, $number, @patternList) = @_;

        # Local variables
        my (
            $count,
            @emptyList, @returnList,
        );

        # Check for improper arguments
        if (! defined $number) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->matchWinList', @_);
        }

        # Can't do anything without X11::WMCtrl
        if (! $axmud::CLIENT->desktopObj->wmCtrlObj) {

            return @emptyList;
        }

        # Cycle through the list of windows on all workspaces, ignoring any windows that aren't on
        #   this workspace
        $count = 0;
        OUTER: foreach my $hashRef ($axmud::CLIENT->desktopObj->wmCtrlObj->get_windows()) {

            my $title;

            if ($$hashRef{'workspace'} == $self->systemNum) {

                # X11::WMCtrl handles a string containing both the window's title and the hostname
                #   of the X client drawing the window; however, when that hostname is 'N/A',
                #   X11::WMCtrl is unable to remove it, so we'll have to do that ourselves
                $title = $$hashRef{'title'};
                $title =~ s/^\sN\/A\s//;

                INNER: foreach my $pattern (@patternList) {

                    if ($title =~ m/$pattern/i) {

                        # A matching window was found
                        push (@returnList, $title, $$hashRef{'id'});
                        $count++;

                        # Do we have enough matching windows now?
                        if ($number > 0 && $count >= $number) {

                            # We have enough matching windows
                            return @returnList;

                        } else {

                            # Look for the next matching window
                            next OUTER;
                        }
                    }
                }
            }
        }

        # Operation complete
        return @returnList;
    }

    sub moveResizeWin {

        # Can be called by any function (but not used by $self->testWinControls, which calls
        #   Gtk3::Window->move and ->resize directly)
        # Moves a window to a specific position on the workspace and resizes it
        # Calls to this function should usually be followed by a call to
        #   GA::Obj::Zone->restackWin() and/or GA::Generic::Win->restoreFocus
        #
        # Expected arguments
        #   $winObj     - The window object (anything inheriting from GA::Generic::Win) whose
        #                   window should be moved and/or resized
        #
        # Optional arguments
        #   $xPosPixels, $yPosPixels
        #               - The new position of the window (both set to 'undef' if the position isn't
        #                   to be changed)
        #   $widthPixels, $heightPixels
        #               - The new size of the window (both set to 'undef' if the size isn't to be
        #                   changed)
        #
        # Notes
        #   The following combinations of arguments lists are acceptable:
        #       ($winObj, $xPosPixels, $yPosPixels, $widthPixels, $heightPixels)
        #       ($winObj, $xPosPixels, $yPosPixels, undef, undef)
        #       ($winObj, undef, undef, $widthPixels, $heightPixels)
        #       ($winObj, undef, undef, undef, undef)
        #   Any other combination, for example the following one, will cause an error
        #       ($winObj, $xPosPixels, $yPosPixels, undef, $heightPixels)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be moved (because a non-external
        #       window object doesn't have its ->winWidget set)
        #   1 otherwise

        my ($self, $winObj, $xPosPixels, $yPosPixels, $widthPixels, $heightPixels, $check) = @_;

        # Local variables
        my $title;

        # Check for improper arguments
        if (
            ! defined $winObj
            || (defined $xPosPixels && ! defined $yPosPixels)
            || (! defined $xPosPixels && defined $yPosPixels)
            || (defined $widthPixels && ! defined $heightPixels)
            || (! defined $widthPixels && defined $heightPixels)
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->moveResizeWin', @_);
        }

        if ($winObj->winType ne 'external') {

            # Move the window to the correct workspace, if possible
            if ($axmud::CLIENT->desktopObj->wmCtrlObj) {

                # Give the window a unique name, so WMCtrl can find it
                my $title = $winObj->winWidget->get_title();
                $winObj->winWidget->set_title($axmud::SCRIPT . int(rand(1_000_000_000)));

                # Move the window
                $axmud::CLIENT->desktopObj->wmCtrlObj->move_to(
                    $winObj->winWidget->get_title(),
                    $self->systemNum,
                );

                # Restore the original title
                $winObj->winWidget->set_title($title);
            }

            # Resize the window, if that was specified
            if (defined $widthPixels) {

                $winObj->winWidget->resize($widthPixels, $heightPixels);
            }

            # Move the window, if that was specified
            # $winObj->winWidget is occasionally set to 'undef' just before this line. It's a very
            #   difficult error to reproduce, so I'm not sure what the cause is
            if ($winObj->winWidget && defined $xPosPixels) {

                # DEBUG v2.0
                # MS Windows adds extra pixels to the X position (for unknown reasons); compensate
                #   for that, if required
                if ($^O eq 'MSWin32' && $axmud::CLIENT->mswinWinPosnTweakFlag) {

                    $xPosPixels -= 7;
                }

                $winObj->winWidget->move($xPosPixels, $yPosPixels);
            }

        } else {

            # X11::WMCtrl expects -1 values, rather than undef
            if (! defined $xPosPixels) {

                $xPosPixels = -1;
                $yPosPixels = -1;
            }

            if (! defined $widthPixels) {

                $widthPixels = -1;
                $heightPixels = -1;
            }

            # Move the window to the correct workspace
            $axmud::CLIENT->desktopObj->wmCtrlObj->wmctrl(
                '-r',
                $winObj->internalID,
                '-t',
                $self->systemNum,
                '-i',
            );

            # Set the window's size and position
            $axmud::CLIENT->desktopObj->wmCtrlObj->wmctrl(
                '-r',
                $winObj->internalID,
                "-e 0,$xPosPixels,$yPosPixels,$widthPixels,$heightPixels",
                '-i',
            );
        }

        # Operation complete
        return 1;
    }

    # Window creation

    sub createGridWin {

        # Can be called by anything
        #
        # Creates a 'grid' window object. 'external' windows use GA::Win::External objects; other
        #   kinds of 'grid' window use GA::Win::Internal. (This function isn't used to create 'free'
        #   windows; call GA::Generic::Win->createFreeWin for that)
        # If the window itself doesn't exist, creates it using the specified size and coordinates,
        #   in the specified layer, on the workspace $self->systemNum
        # If the window already exists, resizes and moves it using the specified size and
        #   coordinates
        # If workspace grids are available and the window's specified position is occupied by
        #   another window, moves the specified window to another position in the zone, if possible
        # If workspace grids aren't available, ignores the specified coordinates (if supplied), and
        #   lets the desktop's window manager decide where to put the window
        #
        # NB If the calling function wants the window to appear on a particular workspace only, it
        #   can call this function directly
        # If the calling function wants the window to appear on the first available workspace, it
        #   can call GA::Obj::Desktop->listWorkspaces to get an ordered list of workspaces, with
        #   the preferred workspace (if specified) first in the list. The calling function can then
        #   call this function for each workspace on the list until a new window object is actually
        #   created
        #
        # NB 'main' windows should only be created by code in GA::Client or GA::Session.
        #   'protocol' and 'external' windows should only be created by code in GA::Session
        # If you write your own plugins, don't use them to create your own 'main', 'protocol' or
        #   'external' windows. You can create as many 'map', 'fixed' or 'custom' windows as you
        #   like, though
        #
        # Expected arguments
        #   $winType        - The window type; one of the 'grid' window types specified by
        #                       GA::Client->constGridWinTypeHash
        #   $winName        - A name for the window:
        #                       $winType    $winName
        #                       --------    --------
        #                       main        main
        #                       map         map
        #                       protocol    Any string chosen by the protocol code (default value is
        #                                       'protocol')
        #                       fixed       Any string chosen by the controlling code (default value
        #                                       is 'fixed')
        #                       custom      Any string chosen by the controlling code. For task
        #                                       windows, the name of the task (e.g. 'status_task',
        #                                       for other windows, default value is 'custom'
        #                       external    The 'external' window's name (e.g. 'Notepad')
        #
        # Optional arguments
        #   $winTitle       - The text to use in the window's title bar. If 'undef', a default
        #                       window title is used
        #   $winmapName     - The name of the GA::Obj::Winmap object that specifies the
        #                       Gtk3::Window's layout when it is first created. If 'undef', a
        #                       default winmap is used. Ignored for 'map', 'fixed' and 'external'
        #                       windows which should have no winmap
        #   $packageName    - 'main', 'protocol' and 'custom' windows are created via a call to
        #                       GA::Win::Internal->new(). 'external' windows are created via a
        #                       call to GA::Win::External->new(). However, the calling function
        #                       can specify its own $packageName, if required. It's expected that
        #                       the package should inherit from GA::Win::Internal or
        #                       GA::Win::External
        #                   - 'map' windows are created via a call to GA::Win::Map->new(). If the
        #                       calling function specifies its own $packageName, it's expected that
        #                       the package either inherits from GA::Win::Map, or provides a
        #                       similar range of functions for other parts of the Axmud code to call
        #                   - $packageName must be specified when creating a 'fixed' window. If not,
        #                       an error is produced
        #   $winWidget      - The Gtk3::Window, if it already exists and it is known (otherwise
        #                       set to 'undef')
        #   $internalID     - For 'external' windows, the window internal ID, provided by
        #                       X11::WMCtrl ('undef' for other types of window)
        #   $owner          - The owner, if known. Can be any blessed reference, typically it's an
        #                       GA::Session or a task (inheriting from GA::Generic::Task). The owner
        #                       must have a ->del_winObj function, which is called when this window
        #                       closes
        #   $session        - The owner's session. If $owner is a GA::Session, that session. If
        #                       it's something else (like a task), the task's session. If $owner is
        #                       'undef', so is $session. If $owner is GA::Client, then $session
        #                       should be 'undef'
        #   $workspaceGrid  - The number of the workspace grid to use (matches a key in
        #                       $self->gridHash). Should be set when GA::CLIENT->shareMainWinFlag
        #                       is TRUE. If 'undef' (when GA::Client->shareMainWinFlag = FALSE, or
        #                       if the calling function forgot to specify a workspace), uses the
        #                       workspace grid with the lowest number, on the assumption that it's
        #                       a single workspace grid shared by all sessions
        #   $zone           - Within the workspace grid, the zone number to use (matches a key in
        #                       GA::Obj::WorkspaceGrid->zoneHash). If 'undef' (or if
        #                       $workspaceGrid is 'undef'), this function will choose the zone. If
        #                       set, and the specified $zone is reserved for other windows, this
        #                       function will choose a different zone. Ignored if workspace grids
        #                       are not available
        #   $layer          - Which layer the window should be put in. If 'undef' and zones are
        #                       enabled, the default layer is used. Ignored if workspace grids are
        #                       not available
        #   $xPosPixels, $yPosPixels
        #                   - The desired position of the top left-hand corner of the window in
        #                       pixels, with (0, 0) representing the top left-hand pixel on the
        #                       workspace. (If either or both is 'undef', this function will decide
        #                       the position. Ignored if $zone is specified)
        #   $widthPixels, $heightPixels
        #                   - The desired size of the window, in pixels. (If either or both is
        #                       'undef', this function will decide the size of the window. Ignored
        #                       if $zone is specified)
        #   $beforeListRef, $afterListRef
        #                   - References to a list of functions in the window object. Any functions
        #                       in the first list are called just after the Gtk3::Window is created.
        #                       Any functions in the second list are called just after the
        #                       window is made visible. These functions should be used to set up
        #                       additional ->signal_connects for this type of window, if they are
        #                       required
        #
        # Return values
        #   'undef' on improper arguments, if the window object can't be created, or if the window
        #       itself can't be created (when it doesn't already exist)
        #   Blessed reference to the newly-created window object on success

        my (
            $self, $winType, $winName, $winTitle, $winmapName, $packageName, $winWidget,
            $internalID, $owner, $session, $workspaceGrid, $zone, $layer, $xPosPixels, $yPosPixels,
            $widthPixels, $heightPixels, $beforeListRef, $afterListRef, $check,
        ) = @_;

        # Local variables
        my (
            $complainant, $pluginName, $pluginObj, $zoneSpecifiedFlag, $workspaceGridObj, $zoneObj,
            $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $areaObj, $winmapObj, $winObj,
            @geometryList,
        );

        # Check for improper arguments
        if (! defined $winType || ! defined $winName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createGridWin', @_);
        }

        # Any error messages (besides improper arguments errors) should be written via the
        #   GA::Session, if there is one, or the GA::Client, if not
        if ($session) {
            $complainant = $session;
        } else {
            $complainant = $axmud::CLIENT;
        }

        # Check $winType is valid
        if (! $axmud::CLIENT->ivExists('constGridWinTypeHash', $winType)) {

            return $complainant->writeError(
                'Invalid \'grid\' window type \'' . $winType . '\'',
                $self->_objClass . '->createGridWin',
            );

        # Check that $owner and $session are (in combination) valid values
        } elsif (
            (defined $owner && ! defined $session && $owner->_objClass ne 'Games::Axmud::Client')
            || (defined $session && ! defined $owner)
        ) {
            return $complainant->writeError(
                'Invalid owner/session arguments',
                $self->_objClass . '->createGridWin',
            );

        # No session may open a second 'main' window
        } elsif ($winType eq 'main' && $session && $session->mainWin) {

            return $complainant->writeError(
                'Cannot create second \'main\' window for session #' . $session->number,
                $self->_objClass . '->createGridWin',
            );


        # For 'fixed' windows, we must have received a package name
        } elsif ($winType eq 'fixed' && ! $packageName) {

            return $complainant->writeError(
                'Cannot create \'fixed\' windows without a specified package name',
                $self->_objClass . '->createGridWin',
            );
        }

        # If a package name was specified and it was added by a plugin, check that the plugin is
        #   enabled
        if ($packageName) {

            $pluginName = $axmud::CLIENT->ivShow('pluginGridWinHash', $packageName);
            if ($pluginName) {

                $pluginObj = $axmud::CLIENT->ivShow('pluginHash', $pluginName);
                if ($pluginObj && ! $pluginObj->enabledFlag) {

                    return $complainant->writeError(
                        'Cannot create the window because the \'' . $pluginName . '\' plugin is'
                        . ' disabled',
                        $self->_objClass . '->createGridWin',
                    );
                }
            }
        }

        # Workspace grids and zones are disabled for this workspace. Axmud doesn't change the
        #   position of any windows. Windows are left where the system's window manager puts them.
        #   Window controls are compulsory
        if (! $self->gridEnableFlag || ! $axmud::CLIENT->activateGridFlag) {

            return $self->createSimpleGridWin(
                $winType, $winName, $winTitle, $winmapName, $packageName, $winWidget, $internalID,
                $owner, $session, $xPosPixels, $yPosPixels, $widthPixels, $heightPixels,
                $beforeListRef, $afterListRef,
            );
        }

        # Workspace grids and zones are enabled for this workspace

        # We need to remember if $zone was specified when this function was called, or not, because
        #   the way that $widthPixels/$heightPixels and $xPosPixels/$yPosPixels are used depends on
        #   it
        $zoneSpecifiedFlag = FALSE;
        if (defined $workspaceGrid && defined $zone) {

            $zoneSpecifiedFlag = TRUE;

            # Check the workspace grid and zone exist; if either do not, reset the variables so
            #   that the next block of code can choose its own zone
            $workspaceGridObj = $self->ivShow('gridHash', $workspaceGrid);
            if ($workspaceGridObj) {

                $zoneObj = $workspaceGridObj->ivShow('zoneHash', $zone);
            }

            if (! $zoneObj) {

                # The specified zone number, $zone, doesn't exist
                $complainant->writeWarning(
                    'The specified zone #' . $zone . ' in workspace grid #' . $workspaceGrid
                    . ' doesn\'t exist',
                    $self->_objClass . '->createGridWin',
                );
            }

            # Tidy up
            if (! $zoneObj) {

                $zone = undef;
            }

            if (! $workspaceGridObj) {

                $workspaceGrid = undef;
            }

        } elsif (defined $xPosPixels && defined $yPosPixels) {

            # Either the workspace grid or the zone weren't specified, but we can use
            #   $xPosPixels / $yPosPixels to choose them
            if (defined $workspaceGrid) {

                # Use $xPosPixels/$yPosPixels to choose a zone on the specified workspace
                $workspaceGridObj = $self->ivShow('gridHash', $workspaceGrid);

            } else {

                # Use $xPosPixels/$yPosPixels to choose a zone in the correct workspace grid (the
                #   one controlled by $session)
                $workspaceGridObj = $self->findWorkspaceGrid($session);
                if ($workspaceGridObj) {

                    $workspaceGrid = $workspaceGridObj->number;
                }
            }

            if ($workspaceGridObj) {

                $zoneObj = $workspaceGridObj->findZone($xPosPixels, $yPosPixels);
                if ($zoneObj) {

                    $zone = $zoneObj->number;

                    # If this zone is reserved for certain types of windows, not including this kind
                    #   of window, don't use the specified zone
                    if (! $zoneObj->checkWinAllowed($winType, $winName, $session)) {

                        # Window not allowed in this zone
                        $complainant->writeWarning(
                            '\'' . $winType . '\' windows aren\'t allowed in zone #' . $zone,
                            $self->_objClass . '->createGridWin',
                        );

                        $zoneObj = undef;
                    }
                }
            }

            # Tidy up
            if (! $zoneObj) {

                $zone = undef;
            }

            if (! $workspaceGridObj) {

                $workspaceGrid = undef;
            }
        }

        # Now, if the zone still hasn't been set, decide which zone to use
        if (! defined $zone) {

            # If no workspace grid is yet specified, choose one (the one controlled by $session)
            if (! defined $workspaceGridObj) {

                $workspaceGridObj = $self->findWorkspaceGrid($session);
                if (! $workspaceGridObj) {

                    return $complainant->writeWarning(
                        'Cannot find a workspace grid onto which window \'' . $winName
                        . '\' can be placed',
                        $self->_objClass . '->createGridWin',
                    );

                } else {

                    $workspaceGrid = $workspaceGridObj->number;
                }
            }

            # Check that the workspace grid actually contains some zones
            if (! $workspaceGridObj->zoneHash) {

                return $complainant->writeWarning(
                    'There are no zones on the workspace grid in which to put the window \''
                    . $winName . '\', window was not allocated to a zone',
                    $self->_objClass . '->createGridWin',
                );

            } else {

                $zoneObj = $self->chooseZone(
                    $workspaceGridObj,
                    $winType,
                    $winName,
                    $winWidget,
                    $internalID,
                    $owner,
                    $session,
                );

                if (! $zoneObj) {

                    # All available zones are full. Error message has been displayed
                    return undef;

                } else {

                    $zone = $zoneObj->number;
                }
            }
        }

        # If $zone wasn't specified when this function was called and one (but not both) of
        #   $widthPixels / $heightPixels weren't specified, use default values for the width and
        #   height
        # Exception: if this window is a 'main' window and it's the first window ever created,
        #   assume that the Axmud is still setting up. If there is more than one zone, set the
        #   'main' window to fill the zone. If there is only one zone, use the default 'main' window
        #   size
        ($widthPixels, $heightPixels) = $self->chooseWinSize(
            $winType,
            $workspaceGridObj,
            $zoneObj,
            $zoneSpecifiedFlag,
            $widthPixels,
            $heightPixels,
        );

        # Choose the exact size and position of the window inside its zone, taking into account such
        #   factors as other windows in the zone
        (
            $layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $xPosPixels, $yPosPixels,
            $widthPixels, $heightPixels,
        ) = $self->chooseWinPosn(
            $complainant,
            $winType,
            $zoneSpecifiedFlag,
            $workspaceGridObj,
            $widthPixels,
            $heightPixels,
            $zoneObj,
            $layer,
            $xPosPixels,
            $yPosPixels,
        );

        if (! defined $layer) {

            # Zone is full
            return undef;
        }

        # Create a GA::Obj::Area within the zone (which handles the new window, and is the same
        #   size as it)
        $areaObj = $zoneObj->addArea(
            $layer,
            $xPosBlocks,
            $yPosBlocks,
            $widthBlocks,
            $heightBlocks,
            $xPosPixels,
            $yPosPixels,
            $widthPixels,
            $heightPixels,
            $session,
        );

        if (! $areaObj) {

            # Checks failed
            return undef;
        }

        # Convert a winmap name to a winmap object. If no winmap was specified, use a default one
        $winmapObj = $self->getWinmap($winType, $winmapName, $zoneObj);
        # We need to specify a winmap name or 'undef' in the call to ->new
        if ($winmapObj) {
            $winmapName = $winmapObj->name;
        } else {
            $winmapName = undef;
        }

        # Create a new window object
        if (! defined $packageName) {

            if ($winType eq 'external') {

                $packageName = 'Games::Axmud::Win::External';

            } elsif ($winType eq 'map') {

                $packageName = 'Games::Axmud::Win::Map';

            } else {

                # $winType is 'main', 'protocol', 'custom'
                $packageName = 'Games::Axmud::Win::Internal';
            }
        }

        $winObj = $packageName->new(
            $axmud::CLIENT->desktopObj->gridWinCount,
            $winType,
            $winName,
            $self,
            $owner,
            $session,
            $workspaceGridObj,
            $areaObj,
            $winmapName,
        );

        # (The check for ->winType makes sure that plugins don't create, for example, a 'free'
        #   window and then try to add it via a call to GA::Client->createGridWin)
        if (! $winObj || $winObj->winCategory ne 'grid' || $winObj->winType ne $winType) {

            # Something or other failed. Update the zone
            $zoneObj->removeArea($areaObj);

            return undef;
        }

        # Update the GA::Obj::Desktop object's registry of all 'grid' windows
        $axmud::CLIENT->desktopObj->add_gridWin($winObj);
        # Tell the workspace grid object and area object they have received a new window
        $workspaceGridObj->add_gridWin($winObj);
        $areaObj->set_win($winObj);

        # Move the window to its correct workspace, size and position
        if ($winType ne 'external') {

            # Create a new Gtk3::Window widget at the specified size and position (but don't make
            #   it visible yet)
            if (! $winObj->winSetup($winTitle, $beforeListRef)) {

                # Something or other failed. Update the zone
                $zoneObj->removeArea($areaObj);

                return undef;
            }

            # Make the window actually visible, if it's not already visible
            if (! $winObj->enabledFlag) {

                $winObj->winEnable($afterListRef);
            }

            # Move the window to its correct workspace, size and position
            $self->moveResizeWin(
                $winObj,
                $xPosPixels,
                $yPosPixels,
                $widthPixels,
                $heightPixels,
            );

#            # For 'grid' windows, $winObj->winEnable created the window in a minimised state so it
#            #   didn't appear to jump around on the desktop. Unminimise it now
#            $winObj->unminimise();

            # Update the GA::Client's hash of stored window positions (if required)
            if ($winObj->winWidget) {

                $axmud::CLIENT->add_storeGridPosn(
                    $winObj,
                    $winObj->winWidget->get_position(),
                    $winObj->winWidget->get_size(),
                );
            }

        } else {

            # Update the 'external' window object's IVs
            if (! $winObj->winSetup($internalID)) {

                # Something or other failed. Update the zone
                $zoneObj->removeArea($areaObj);

                return undef;
            }

            $self->moveResizeWin(
                $winObj,
                ($xPosPixels - $self->controlsLeftSize),
                ($yPosPixels - $self->controlsTopSize),
                $widthPixels,
                $heightPixels,
            );

            # Make the window actually visible, if it's not already visible
            if (! $winObj->enabledFlag) {

                $winObj->winEnable($afterListRef);
            }

            # If this 'external' window has already been grabbed to the workspace grid with
            #   ';grabwindow' and then removed from it with ';banishwindow', it will be minimised.
            #   In any case, if the window is minimised, it should be unminimised before being
            #   restacked
            $winObj->unminimise();
        }

        # The workspace grid's new current layer is the layer in which this window will be
        #   placed (so that it's visible to the user immediately)
        $workspaceGridObj->set_currentLayer($layer);

        # Make sure all windows on the workspace grid are stacked correctly, so that windows in
        #   lower layers are beneath windows in higher layers (but windows in a layer higher than
        #   the workspace grid's current layer are minimised)
        $zoneObj->restackWin();

        # GA::Obj::Zone->adjustSingleWin is called above to fill in small gaps in the zone. Now,
        #   if the zone is wide enough (and its orientation is 'horizontal') or high enough (and its
        #   orientation is 'vertical') for only one area of the zone's default size, then consider
        #   expanding all of the areas in the zone to fill gaps that are bigger than a gridblock
        #   or two, but still not big enough to hold another area
        # If it would be better to reduce all the area sizes in order to make room for another
        #   area, some time in the future, do that instead. Leave enough room for an area of the
        #   default size
        # If the global flag isn't set allowing these adjustments, or if the zone has a maximum of 1
        #   area, don't make any adjustments
        if (
            $axmud::CLIENT->gridAdjustmentFlag
            && $zoneObj->areaMax != 1
            && (
                # Windows are stacked horizontally, and there's only room for one (default size)
                #   window in each row
                (
                    $zoneObj->orientation eq 'horizontal'
                    && $zoneObj->heightBlocks >= $zoneObj->defaultAreaHeight
                    && $zoneObj->heightBlocks < ($zoneObj->defaultAreaHeight * 2)
                # Windows are stacked vertically, and there's only room for one (default size)
                #   window in each column
                ) || (
                    $zoneObj->orientation eq 'vertical'
                    && $zoneObj->widthBlocks >= $zoneObj->defaultAreaWidth
                    && $zoneObj->widthBlocks < ($zoneObj->defaultAreaWidth * 2)
                )
            )
        ) {
            $zoneObj->adjustMultipleWin($layer);
        }

        # If a GA::Session was specified, restore focus to its 'main' window
        if ($session && $session->mainWin) {

            $session->mainWin->restoreFocus();
        }

        # Return the blessed reference of the new window object to show success
        return $winObj;
    }

    sub createSimpleGridWin {

        # Called by $self->createGridWin if workspace grids aren't available for this workspace,
        #   when we don't have to bother with trying to make the window fit in a particular position
        #   on the workspace
        # (When workspace grids are available, $self->createGridWin does the job itself)
        #
        # Also called by GA::Obj::Desktop->start to create the spare 'main' window when Axmud first
        #   runs (and before the Connections window opens)
        #
        # Expected arguments
        #   $winType        - The window type; one of the 'grid' window types specified by
        #                       GA::Client->constGridWinTypeHash
        #   $winName        - A name for the window:
        #                       $winType    $winName
        #                       --------    --------
        #                       main        main
        #                       map         map
        #                       protocol    Any string chosen by the protocol code (default value is
        #                                       'protocol')
        #                       fixed       Any string chosen by the controlling code (default value
        #                                       is 'fixed')
        #                       custom      Any string chosen by the controlling code. For task
        #                                       windows, the name of the task (e.g. 'status_task',
        #                                       for other windows, default value is 'custom'
        #                       external    The 'external' window's name (e.g. 'Notepad')
        #
        # Optional arguments
        #   $winTitle       - The text to use in the window's title bar. If 'undef', a default
        #                       window title is used
        #   $winmapName     - The name of the GA::Obj::Winmap object that specifies the
        #                       Gtk3::Window's layout when it is first created. If 'undef', a
        #                       default winmap is used. Ignored for 'map', 'fixed' and 'external'
        #                       windows which should have no winmap
        #   $packageName    - 'main', 'protocol' and 'custom' windows are created via a call to
        #                       GA::Win::Internal->new(). 'external' windows are created via a
        #                       call to GA::Win::External->new(). However, the calling function
        #                       can specify its own $packageName, if required. It's expected that
        #                       the package should inherit from GA::Win::Internal or
        #                       GA::Win::External
        #                   - 'map' windows are created via a call to GA::Win::Map->new(). If the
        #                       calling function specifies its own $packageName, it's expected that
        #                       the package either inherits from GA::Win::Map, or provides a
        #                       similar range of functions for other parts of the Axmud code to call
        #                   - $packageName must be specified when creating a 'fixed' window. If not,
        #                       an error is produced
        #   $winWidget      - The Gtk3::Window, if it already exists and it is known (otherwise
        #                       set to 'undef')
        #   $internalID     - For 'external' windows, the window internal ID, provided by
        #                       X11::WMCtrl ('undef' for other types of window)
        #   $owner          - The owner, if known. Can be any blessed reference, typically it's an
        #                       GA::Session or a task (inheriting from GA::Generic::Task). The owner
        #                       must have a ->del_winObj function, which is called when this window
        #                       closes
        #   $session        - The owner's session. If $owner is a GA::Session, that session. If
        #                       it's something else (like a task), the task's session. If $owner is
        #                       'undef', so is $session. If $owner is GA::Client, then $session
        #                       should be 'undef'
        #   $xPosPixels, $yPosPixels
        #                   - The desired position of the top left-hand corner of the window in
        #                       pixels, with (0, 0) representing the top left-hand pixel on the
        #                       workspace. (If either or both is 'undef', this function will decide
        #                       the position. Ignored if $zone is specified)
        #   $widthPixels, $heightPixels
        #                   - The desired size of the window, in pixels. (If either or both is
        #                       'undef', this function will decide the size of the window)
        #   $beforeListRef, $afterListRef
        #                   - References to a list of functions in the window object. Any functions
        #                       in the first list are called just after the Gtk3::Window is created.
        #                       Any functions in the second list are called just after the
        #                       window is made visible. These functions should be used to set up
        #                       additional ->signal_connects for this type of window, if they are
        #                       required
        #
        # Return values
        #   'undef' on improper arguments, if the window object can't be created, or if the window
        #       itself can't be created (when it doesn't already exist)
        #   Blessed reference to the newly-created window object on success

        my (
            $self, $winType, $winName, $winTitle, $winmapName, $packageName, $winWidget,
            $internalID, $owner, $session, $xPosPixels, $yPosPixels, $widthPixels, $heightPixels,
            $beforeListRef, $afterListRef, $check,
        ) = @_;

        # Local variables
        my (
            $listRef, $winmapObj, $winObj,
            @geometryList,
        );

        # Check for improper arguments
        if (! defined $winType || ! defined $winName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createSimpleGridWin', @_);
        }

        # If the GA::Client IV stores a position/size for a window with this $winName, we might be
        #   able to use it (but never for 'external' windows)
        $listRef = $axmud::CLIENT->ivShow('storeGridPosnHash', $winName);
        if ($winType ne 'external' && defined $listRef) {

            # $listRef is in the form (x y wid hei)
            if (
                ! defined $xPosPixels
                && ! defined $yPosPixels
                && defined $$listRef[0]
                && defined $$listRef[1]
            ) {
                $xPosPixels = $$listRef[0];
                $yPosPixels = $$listRef[1];
            }

            if (
                ! defined $widthPixels
                && ! defined $heightPixels
                && defined $$listRef[2]
                && defined $$listRef[3]
            ) {
                $widthPixels = $$listRef[2];
                $heightPixels = $$listRef[3];
            }
        }

        # If no size is still not specified, use a default size (and let the system's window manager
        #   set its own position)
        if (! defined $widthPixels || ! defined $heightPixels) {

            if ($winType eq 'main') {

                $widthPixels = $axmud::CLIENT->customMainWinWidth;
                $heightPixels = $axmud::CLIENT->customMainWinHeight;

            } else {

                $widthPixels = $axmud::CLIENT->customGridWinWidth;
                $heightPixels = $axmud::CLIENT->customGridWinHeight;
            }
        }

        # Convert a winmap name to a winmap object. If no winmap was specified, use a default one
        $winmapObj = $self->getWinmap($winType, $winmapName);
        if (! defined $winmapObj) {

            # No winmap name specified, or winmap doesn't exist, so use a default winmap
            if ($winType eq 'main') {

                if ($self->gridEnableFlag && $axmud::CLIENT->activateGridFlag) {

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

            } elsif ($winType ne 'external') {

                $winmapObj
                    = $axmud::CLIENT->ivShow('winmapHash', $axmud::CLIENT->defaultInternalWinmap);
            }
        }

        # We need to specify a winmap name or 'undef' in the call to ->new
        if ($winmapObj) {
            $winmapName = $winmapObj->name;
        } else {
            $winmapName = undef;
        }

        # Create a new window object
        if (! defined $packageName) {

            if ($winType eq 'external') {

                $packageName = 'Games::Axmud::Win::External';

            } elsif ($winType eq 'map') {

                $packageName = 'Games::Axmud::Win::Map';

            } else {

                # $winType is 'main', 'protocol', 'custom'
                $packageName = 'Games::Axmud::Win::Internal';
            }
        }

        $winObj = $packageName->new(
            $axmud::CLIENT->desktopObj->gridWinCount,
            $winType,
            $winName,
            $self,
            $owner,
            $session,
            undef,
            undef,
            $winmapName,
        );

        # (The check for ->winType makes sure that plugins don't create, for example, a 'free'
        #   window and then try to add it via a call to GA::Client->createGridWin)
        if (! $winObj || $winObj->winCategory ne 'grid' || $winObj->winType ne $winType) {

            # Something or other failed
            return undef;
        }

        # Update the GA::Obj::Desktop object's registry of all 'grid' windows
        $axmud::CLIENT->desktopObj->add_gridWin($winObj);

        # Move the window to its correct workspace, size and position
        if ($winType ne 'external') {

            # Create a new Gtk3::Window widget (but don't make it visible yet)
            if (! $winObj->winSetup($winTitle, $beforeListRef)) {

                # Something or other failed
                return undef;
            }

            # If a size and/or position were specified, move the window
            if (
                (defined $xPosPixels && defined $yPosPixels)
                || (defined $widthPixels && defined $heightPixels)
            ) {
                $self->moveResizeWin(
                    $winObj,
                    $xPosPixels,
                    $yPosPixels,
                    $widthPixels,
                    $heightPixels,
                );
            }

            # Make the window actually visible, if it's not already visible
            if (! $winObj->enabledFlag) {

                $winObj->winEnable($afterListRef);
            }

            # Update the GA::Client's hash of stored window positions (if required)
            if ($winObj->winWidget) {

                $axmud::CLIENT->add_storeGridPosn(
                    $winObj,
                    $winObj->winWidget->get_position(),
                    $winObj->winWidget->get_size(),
                );
            }

        } else {

            # Update the 'external' window object's IVs
            if (! $winObj->winSetup($internalID)) {

                # Something or other failed
                return undef;
            }

            # If a size and/or position were specified, move the window
            if (
                (defined $xPosPixels && defined $yPosPixels)
                || (defined $widthPixels && defined $heightPixels)
            ) {
                $self->moveResizeWin(
                    $winObj,
                    ($xPosPixels - $self->controlsLeftSize),
                    ($yPosPixels - $self->controlsTopSize),
                    $widthPixels,
                    $heightPixels,
                );
            }

            # Make the window actually visible, if it's not already visible
            if (! $winObj->enabledFlag) {

                $winObj->winEnable($afterListRef);
            }

            # If this 'external' window has already been grabbed to the workspace grid with
            #   ';grabwindow' and then removed from it with ';banishwindow', it will be minimised.
            #   In any case, if the window is minimised, it should be unminimised before being
            #   restacked
            $axmud::CLIENT->desktopObj->wmCtrlObj->unminimize($internalID);
        }

        # Windows created via this function always have the focus (unlike those created by calls to
        #   $self->createGridWin, in which the 'main' windows is always given focus)
        $winObj->restoreFocus();

        # Return the blessed reference of the new window object to show success
        return $winObj;
    }

    sub chooseZone {

        # Called by $self->createGridWin, when that function is asked to create a window in an
        #   unspecified zone
        # Also called by GA::Session->setMainWin when there are no sessions, to move the spare
        #   'main' window into the first available zone
        #
        # Decides which zone in the specified workspace grid to place the window. If it's not
        #   possible to place the window in any of them, returns 'undef'
        #
        # Expected arguments
        #   $workspaceGridObj
        #                   - The GA::Obj::WorkspaceGrid object which will receive the new window
        #   $winType        - The window type; one of the 'grid' window types specified by
        #                       GA::Client->constGridWinTypeHash
        #   $winName        - The window name
        #                       $winType    $winName
        #                       --------    --------
        #                       main        main
        #                       map         map
        #                       protocol    Any string chosen by the protocol code (default value is
        #                                       'protocol')
        #                       fixed       Any string chosen by the controlling code (default value
        #                                       is 'fixed')
        #                       custom      Any string chosen by the controlling code. For task
        #                                       windows, the name of the task (e.g. 'status_task',
        #                                       for other windows, default value is 'custom'
        #                       external    The 'external' window's name (e.g. 'Notepad')
        #
        # Optional arguments
        #   $winWidget      - The Gtk3::Window, if it already exists and it is known (otherwise set
        #                       to 'undef')
        #   $internalID     - For 'external' windows, the window internal ID, provided by
        #                       X11::WMCtrl ('undef' for other types of window)
        #   $owner          - The owner, if known. Can be any blessed reference, typically it's an
        #                       GA::Session or a task (inheriting from GA::Generic::Task)
        #   $session        - The owner's session. If $owner is a GA::Session, that session. If
        #                       it's something else (like a task), the task's session. If $owner is
        #                       'undef', so is $session
        #
        # Return values
        #   'undef' on improper arguments or if no zone is available for this window
        #   Otherwise, returns the chosen GA::Obj::Zone

        my (
            $self, $workspaceGridObj, $winType, $winName, $winWidget, $internalID, $owner, $session,
            $check,
        ) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (
            ! defined $workspaceGridObj || ! defined $winType || ! defined $winName
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->chooseZone', @_);
        }

        # Choose zones in the following order:
        #   1. If it's a zone reserved for this window or for this window's session, choose it
        #   2. If it's an unreserved/unowned zone and the current layer isn't full, use it
        #   3. If it's an unreserved/unowned zone and any of its layers aren't full, use it
        @list = sort {$a->number <=> $b->number} ($workspaceGridObj->ivValues('zoneHash'));

        # 1. If it's a zone reserved for this window or for this window's session, choose it
        foreach my $zoneObj (@list) {

            my $areaCount;

            if ($zoneObj->reservedFlag || $zoneObj->owner) {

                # Is this window allowed in this zone, and if the zone has a maximum number of
                #   areas, is there room for another area in the zone? (A GA::Obj::Area handles
                #   the part of the zone's internal grid occupied by a single window)
                if ($zoneObj->checkWinAllowed($winType, $winName, $session)) {

                    # The window is allowed in this zone, but is the zone already full?
                    $areaCount = $zoneObj->ivPairs('areaHash');
                    if (
                        ($zoneObj->areaMax && $areaCount < $zoneObj->areaMax)
                        || (! $zoneObj->areaMax)
                    ) {
                        # The window is allowed in this zone
                        return $zoneObj;
                    }
                }
            }
        }

        # 2. If it's an unreserved zone and the current layer isn't full, use it
        foreach my $zoneObj (@list) {

            my $areaCount;

            if (
                ! $zoneObj->reservedFlag
                && ! $zoneObj->owner
                && ($zoneObj->visibleAreaMax || ! $zoneObj->multipleLayerFlag)
            ) {
                # This is a zone with a maximum number of areas specified per layer. Is there room
                #   for another area in the current layer?
                if ($zoneObj->checkWinAllowed($winType, $winName, $session)) {

                    # Count the number of areas in the current layer
                    $areaCount = 0;
                    foreach my $areaObj ($zoneObj->ivValues('areaHash')) {

                        if ($areaObj->layer == $workspaceGridObj->currentLayer) {

                            $areaCount++;
                        }
                    }

                    if (
                        ($zoneObj->visibleAreaMax && $areaCount < $zoneObj->visibleAreaMax)
                        || (! $zoneObj->multipleLayerFlag && $areaCount < $zoneObj->areaMax)
                    ) {
                        # Window allowed; use this zone
                        return $zoneObj;
                    }
                }
            }
        }

        # 3. If it's an unreserved zone and any of its layers aren't full, use it
        foreach my $zoneObj (@list) {

            my $areaCount;

            if (! $zoneObj->reservedFlag && ! $zoneObj->owner) {

                # This is a non-reserved zone. If the zone has a maximum number of areas, is there
                #   room for another area in the zone?
                $areaCount = $zoneObj->ivPairs('areaHash');
                if (
                    ($zoneObj->areaMax && $areaCount < $zoneObj->areaMax)
                    || (! $zoneObj->areaMax)
                ) {
                    # Window allowed; use this zone
                    return $zoneObj;
                }
            }
        }

        # No zone found
        return undef;
    }

    sub chooseWinSize {

        # Called by $self->createGridWin after choosing the zone into which a window will be placed,
        #   returns the size the window should have
        # Also called by GA::Obj::WorkspaceGrid->applyZonemap
        #
        # Expected arguments
        #   $winType    - The window type; one of the 'grid' window types specified by
        #                   GA::Client->constGridWinTypeHash
        #   $workspaceGridObj
        #               - The GA::Obj::WorkspaceGrid object which will receive the new window
        #   $zoneObj    - Blessed reference to the GA::Obj::Zone object, handling the zone in which
        #                   the window will be placed
        #
        # Optional arguments
        #   $zoneSpecifiedFlag
        #               - Set to TRUE if the function that called $self->createGridWin specified a
        #                   zone to use, otherwise set to FALSE. Set to 'undef' when called by
        #                   any other function
        #   $widthPixels, $heightPixels
        #               - The size of the window specified by the function that called
        #                   $self->createGridWin. Both set to 'undef' if no size was specified
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the list ($widthPixels, $heightPixels)

        my (
            $self, $winType, $workspaceGridObj, $zoneObj, $zoneSpecifiedFlag, $widthPixels,
            $heightPixels, $check,
        ) = @_;

        # Local variables
        my (
            $blockSize,
            @emptyList,
        );

        # Check for improper arguments
        if (
            ! defined $winType || ! defined $workspaceGridObj || ! defined $zoneObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->chooseWinSize', @_);
            return @emptyList;
        }

        # Import the standard gridblock size (in pixels) for convenience
        $blockSize = $axmud::CLIENT->gridBlockSize;

        # On the original call to $self->createGridWin, if a zone number wasn't specified and one
        #   (but not both) of $widthPixels / $heightPixels weren't specified, use default values for
        #   the width and height
        # Exception: if this window is a 'main' window and it's the first window ever created,
        #   assume that the Axmud is still setting up. If there is more than one zone, set the
        #   'main' window to fill the zone. If there is only one zone, use the default 'main' window
        #   size
        if (
            ! $zoneSpecifiedFlag
            && (
                (defined $widthPixels && ! defined $heightPixels)
                || (defined $heightPixels && ! defined $widthPixels)
            )
        ) {
            if ($winType eq 'main' && ! $axmud::CLIENT->desktopObj->gridWinHash) {

                # It's the 'main' window, which is almost always in zone 1
                if ($workspaceGridObj->zoneCount == 1) {

                    $widthPixels = $axmud::CLIENT->customMainWinWidth;
                    $heightPixels = $axmud::CLIENT->customMainWinHeight;

                } else {

                    $widthPixels = ($zoneObj->widthBlocks * $blockSize);
                    $heightPixels = ($zoneObj->heightBlocks * $blockSize);
                }

            } else {

                if (! defined $widthPixels) {

                    $widthPixels = $axmud::CLIENT->customGridWinWidth;

                } elsif (! defined $heightPixels) {

                    $heightPixels = $axmud::CLIENT->customGridWinHeight;
                }
            }

        # In a positioning free-for-all (zonemap 'single'), let a 'main' window use its own default
        #   size
        } elsif ($winType eq 'main' && $workspaceGridObj->zonemap eq 'single') {

            $widthPixels = $axmud::CLIENT->customMainWinWidth;
            $heightPixels = $axmud::CLIENT->customMainWinHeight;

        # Most of the time, use the zone's default width and height if those defaults are specified.
        #   Take into account any adjustment to the zone's default width and height that
        #   $zoneObj->adjustMultipleWin might have made
        # If the zone's default values aren't specified, use the global default values
        } else {

            if (! defined $widthPixels) {

                if ($zoneObj->defaultAreaWidth) {

                    $widthPixels
                        = ($zoneObj->defaultAreaWidth + $zoneObj->widthAdjustBlocks) * $blockSize;

                } else {

                    $widthPixels = $axmud::CLIENT->customGridWinWidth;
                }
            }

            if (! defined $heightPixels) {

                if ($zoneObj->defaultAreaHeight) {

                    $heightPixels
                        = ($zoneObj->defaultAreaHeight + $zoneObj->heightAdjustBlocks) * $blockSize;

                } else {

                    $heightPixels = $axmud::CLIENT->customGridWinHeight;
                }
            }
        }

        return ($widthPixels, $heightPixels);
    }

    sub chooseWinPosn {

        # Called by $self->createGridWin after the window has been given a zone and a provisional
        #   size
        # Sets the exact position of the window on the workspace, taking into account several
        #   different factors
        #
        # Expected arguments
        #   $complainant    - The object to which error messages should be sent: either the
        #                       controlling GA::Session (if one was specified), or GA::Client
        #                       (if not)
        #   $winType        - The window type; one of the 'grid' window types specified by
        #                       GA::Client->constGridWinTypeHash
        #   $zoneSpecifiedFlag
        #                   - Set to TRUE if the function that called $self->createGridWin specified
        #                       a zone to use, otherwise set to FALSE
        #   $workspaceGridObj
        #                   - The GA::Obj::WorkspaceGrid object which will receive the new window
        #   $widthPixels, $heightPixels
        #                   - The provisional size of the window (which may be changed by this
        #                       function)
        #
        # Optional arguments
        #   $zoneObj        - The GA::Obj::Zone, if already known (otherwise 'undef')
        #   $layer          - The layer in which to place the window specified by the function which
        #                       called $self->createGridWin. If no size was specified, set to
        #                       'undef'
        #   $xPosPixels, $yPosPixels
        #                   - The size of the window specified by the function which called
        #                       $self->createGridWin. If no size was specified, both set to 'undef'
        #
        # Return values
        #   An empty list of improper arguments or if there is no room in this zone for the window
        #   Otherwise, returns the window's size, position and layer in a list:
        #       ($layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $xPosPixels,
        #           $yPosPixels, $widthPixels, $heightPixels)

        my (
            $self, $complainant, $winType, $zoneSpecifiedFlag, $workspaceGridObj, $widthPixels,
            $heightPixels, $zoneObj, $layer, $xPosPixels, $yPosPixels, $check
        ) = @_;

        # Local variables
        my (
            $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $successFlag,
            @emptyList,
        );

        # Check for improper arguments
        if (
            ! defined $complainant || ! defined $winType || ! defined $zoneSpecifiedFlag
            || ! defined $workspaceGridObj || ! defined $widthPixels || ! defined $heightPixels
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->chooseWinPosn', @_);
            return @emptyList;
        }

        # If $zone was specified when this function was called, and either or both or $xPosPixels /
        #   $yPosPixels were specified, this function must ignore them
        if ($zoneSpecifiedFlag) {

            $xPosPixels = undef;
            $yPosPixels = undef;
        }

        # Before we decide where exactly in the zone to put the window, we give it a provisional
        #   position in one of the zone's corners (by default the top-left corner). If that region
        #   of the zone happens to be free, the window will be put there permanently; otherwise it
        #   will be moved to some other free part of the zone later in this function
        # However, if either or both of $xPosPixels / $yPosPixels are still specified, we use one
        #   or both of those values as the provisional position instead
        ($widthBlocks, $heightBlocks, $xPosBlocks, $yPosBlocks)
            = $zoneObj->findProvWinPosn($widthPixels, $heightPixels, $xPosPixels, $yPosPixels);

        # If $layer wasn't specified, use the default layer provisionally
        if (! defined $layer) {

            $layer = $workspaceGridObj->defaultLayer;

        # Otherwise, check that the specified layer is valid (and use the default one if
        #   not)
        } elsif (! $axmud::CLIENT->intCheck($layer, 0, ($workspaceGridObj->maxLayers - 1))) {

            $complainant->writeWarning(
                'The specified layer #' . $layer . ' is not valid, using the default layer #'
                . $workspaceGridObj->defaultLayer,
                $self->_objClass . '->chooseWinPosn',
            );

            $layer = $workspaceGridObj->defaultLayer;
        }

        # Place the window at some position within the zone (hopefully at the provisional one, on
        #   the default layer)
        ($successFlag, $layer, $xPosBlocks, $yPosBlocks)
            = $zoneObj->placeWin($layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks);

        if (! $successFlag) {

            # There is no room for the window in this zone
            $complainant->writeError(
                'Couldn\'t find room for the \'' . $winType . '\' window anywhere in zone #'
                . $zoneObj->number,
                $self->_objClass . '->chooseWinPosn',
            );

            return @emptyList;
        }

        # If the window position on the grid puts it rather close to the edge (or edges) of the
        #   zone, and if the gaps between the window and the zone's edge are empty, adjust the size
        #   of the window to fill the gap (this prevents small areas of the zone from always being
        #   empty: makes the workspace look nice). If the maximum allowable gap size is 0, don't
        #   fill gaps at all
        if ($axmud::CLIENT->gridGapMaxSize) {

            ($xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks)
                = $zoneObj->adjustSingleWin(
                    $layer,
                    $xPosBlocks,
                    $yPosBlocks,
                    $widthBlocks,
                    $heightBlocks,
            );
        }

        # Now that we have the window's final size and position in the zone, reset the variables
        #   that show the window's size and position, in pixels, on the workspace
        ($xPosPixels, $yPosPixels) = $zoneObj->getInternalGridPosn($xPosBlocks, $yPosBlocks);

        $widthPixels = $widthBlocks * $axmud::CLIENT->gridBlockSize;
        $heightPixels = $heightBlocks * $axmud::CLIENT->gridBlockSize;

        # If the desktop theme uses window controls, we have to take them into account, changing the
        #   size of the window accordingly
        ($xPosPixels, $yPosPixels, $widthPixels, $heightPixels)
            = $workspaceGridObj->fineTuneWinSize(
                $winType,
                $xPosPixels,
                $yPosPixels,
                $widthPixels,
                $heightPixels
        );

        return (
            $layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $xPosPixels, $yPosPixels,
            $widthPixels, $heightPixels,
        );
    }

    sub getWinmap {

        # Called by $self->createGridWin or $self->createSimpleGridWin
        # If a winmap name was specified as an argument to those functions, selects the
        #   corresponding winmap object (if it exists)
        # Otherwise selects a default winmap object, or 'undef' for 'map', 'fixed' and 'external'
        #   windows (which don't use winmaps)
        # 'main' windows must contain at least one winzone which creates a pane object
        #   (GA::Table::Pane). For 'main' windows, if the selected winmap doesn't contain a pane
        #   object, a standard winmap is used instead
        #
        # Expected arguments
        #   $winType        - The window type; one of the 'grid' window types specified by
        #                       GA::Client->constGridWinTypeHash
        #
        # Optional arguments
        #   $winmapName     - The winmap name specified as an argument in the calls to
        #                       $self->createGridWin or $self->createSimpleGridWin (may be 'undef')
        #   $zoneObj        - When called by $self->createGridWin, the GA::Obj::Zone into which the
        #                       window will be moved. When called by $self->createSimpleGridWin,
        #                       'undef'
        #
        # Return values
        #   'undef' on improper arguments or if no winmap object is created
        #   Otherwise, returns a winmap object (GA::Obj::Winmap)

        my ($self, $winType, $winmapName, $zoneObj, $check) = @_;

        # Local variables
        my ($winmapObj, $flag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getWinmap', @_);
        }

        # Convert a winmap name to a winmap object. If no winmap was specified, use a default one
        if (! defined $winType || defined $winmapName) {

            $winmapObj = $axmud::CLIENT->ivShow('winmapHash', $winmapName);
        }

        if (! $winmapObj) {

            # No winmap name specified, or winmap doesn't exist, so use a default winmap
            if ($winType eq 'main') {

                if ($self->gridEnableFlag && $axmud::CLIENT->activateGridFlag) {

                    if ($zoneObj && defined $zoneObj->defaultEnabledWinmap) {

                        $winmapObj
                            = $axmud::CLIENT->ivShow('winmapHash', $zoneObj->defaultEnabledWinmap);
                    }

                    if (! $winmapObj) {

                        $winmapObj = $axmud::CLIENT->ivShow(
                            'winmapHash',
                            $axmud::CLIENT->defaultEnabledWinmap,
                        );
                    }

                } else {

                    if ($zoneObj && defined $zoneObj->defaultDisabledWinmap) {

                        $winmapObj
                            = $axmud::CLIENT->ivShow('winmapHash', $zoneObj->defaultDisabledWinmap);
                    }

                    if (! $winmapObj) {

                        $winmapObj = $axmud::CLIENT->ivShow(
                            'winmapHash',
                            $axmud::CLIENT->defaultDisabledWinmap,
                        );
                    }
                }

            } elsif ($winType eq 'protocol' || $winType eq 'custom') {

                if ($zoneObj && defined $zoneObj->defaultInternalWinmap) {

                    $winmapObj
                        = $axmud::CLIENT->ivShow('winmapHash', $zoneObj->defaultInternalWinmap);
                }

                if (! $winmapObj) {

                    $winmapObj = $axmud::CLIENT->ivShow(
                        'winmapHash',
                        $axmud::CLIENT->defaultInternalWinmap,
                    );
                }
            }
        }

        # For 'main' windows, check we're going to get at least one pane object
        # (Exception: 'main_wait' deliberately contains no pane objects)
        if (
            $winType eq 'main'
            && (! $winmapName || $winmapName ne 'main_wait')
        ) {
            OUTER: foreach my $winzoneObj ($winmapObj->ivValues('zoneHash')) {

                if ($winzoneObj->packageName eq 'Games::Axmud::Table::Pane') {

                    $flag = TRUE;
                    last OUTER;
                }
            }

            if (! $flag) {

                # Use a standard winmap instead
                if ($self->gridEnableFlag && $axmud::CLIENT->activateGridFlag) {

                    $winmapObj = $axmud::CLIENT->ivShow(
                        'winmapHash',
                        $axmud::CLIENT->constDefaultEnabledWinmap,
                    );

                } else {

                    $winmapObj = $axmud::CLIENT->ivShow(
                        'winmapHash',
                        $axmud::CLIENT->constDefaultDisabledWinmap,
                    );
                }
            }
        }

        # Operation complete
        return $winmapObj;
    }

    ##################
    # Accessors - set

    sub set_defaultZonemap {

        # Called by GA::Cmd::ResetGrid->do, GA::Obj::File->extractData and
        #   GA::WizWin::Setup->saveChanges

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_defaultZonemap', @_);
        }

        # Temporary zonemaps (created by MXP) can't be used as a workspace's default zonemap
        if ($obj->tempFlag) {

            return undef;

        } else {

            $self->ivPoke('defaultZonemap', $obj->name);
        }

        return 1;
    }

    sub reset_defaultZonemap {

        # Called by GA::WizWin::Setup->saveChanges

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_defaultZonemap', @_);
        }

        $self->ivPoke('defaultZonemap', undef);

        return 1;
    }

    ##################
    # Accessors - get

    sub number
        { $_[0]->{number} }
    sub systemNum
        { $_[0]->{systemNum} }

    sub currentWidth
        { $_[0]->{currentWidth} }
    sub currentHeight
        { $_[0]->{currentHeight} }
    sub panelLeftSize
        { $_[0]->{panelLeftSize} }
    sub panelRightSize
        { $_[0]->{panelRightSize} }
    sub panelTopSize
        { $_[0]->{panelTopSize} }
    sub panelBottomSize
        { $_[0]->{panelBottomSize} }
    sub controlsLeftSize
        { $_[0]->{controlsLeftSize} }
    sub controlsRightSize
        { $_[0]->{controlsRightSize} }
    sub controlsTopSize
        { $_[0]->{controlsTopSize} }
    sub controlsBottomSize
        { $_[0]->{controlsBottomSize} }

    sub gridHash
        { my $self = shift; return %{$self->{gridHash}}; }
    sub gridEnableFlag
        { $_[0]->{gridEnableFlag} }
    sub defaultZonemap
        { $_[0]->{defaultZonemap} }
}

# Package must return a true value
1
