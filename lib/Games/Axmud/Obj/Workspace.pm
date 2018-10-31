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
# Games::Axmud::Obj::Workspace
# The workspace object. Arranges windows on a workspace grid on a single workspace

{ package Games::Axmud::Obj::Workspace;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Desktop->add_workspace()
        #
        # Expected arguments
        #   $number     - Unique number for this workspace object
        #
        # Optional arguments
        #   $workspace  - The corresponding Gnome2::Wnck::Workspace, if already known ('undef'
        #                   otherwise)
        #   $screen     - The workspace's Gnome2::Wnck::Screen, if already known ('undef' otherwise.
        #                   Gnome2::Wnck doesn't exist on windows, in which case $workspace and
        #                   $screen will be undefined)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $workspace, $screen, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Get the Gnome2::Wnck::Screen, if not specified
        # Gnome2::Wnck doesn't exist on MS Windows, so we need to check for that
        if ($^O ne 'MSWin32' && ! $screen) {

            $screen = $workspace->get_screen();
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
            # The corresponding Gnome2::Wnck::Workspace ('undef' if unknown)
            wnckWorkspace               => $workspace,
            # The workspace's Gnome2::Wnck::Screen ('undef' if unknown)
            wnckScreen                  => $screen,

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
        # NB On MS Windows, Gnome2::Wnck does not exist, so some of the test can't be performed
        #
        # Expected arguments
        #   $zonemap    - The default zonemap to use for this workspace
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $zonemap, $check) = @_;

        # Local variables
        my $msg;

        # Check for improper arguments
        if (! defined $zonemap || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->start', @_);
        }

        # Perform certain tests on this workspace
        if (! $axmud::CLIENT->desktopObj->gridPermitFlag) {

            # Workspace grids are disabled in general
            $self->ivPoke('gridEnableFlag', FALSE);

        } elsif ($self->wnckWorkspace) {

            # Test whether the workspace is too small
            $self->ivPoke('currentWidth', $self->wnckWorkspace->get_width());
            $self->ivPoke('currentHeight', $self->wnckWorkspace->get_height());

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
            # GA::Client->stop must not call Gtk2->main_quit(), as it normally does, as this will
            #   produce a Gtk-CRITICAL error. Instead, tell it to exit
            $axmud::CLIENT->set_forceExitFlag();
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
        # NB On MS Windows, Gnome2::Wnck does not exist, so the test can't be performed
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $timeout    - A timeout for the test, in seconds. If not defined, the default timeout is
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

        # Can't do anything without Gnome2::Wnck
        if ($^O eq 'MSWin32') {

            return @emptyList;
        }

        # Try to detect panel sizes
        ($xPos, $yPos, $width, $height) = $self->testPanelSize($timeout);
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
        #   $timeout    - A timeout, in seconds. If not defined, the default timeout is used
        #
        # Return values
        #   An empty list on improper arguments or if the test fails
        #   Otherwise returns the detected sizes of panels/taskbars detected, a list in the form
        #       (left, right, top, bottom)

        my ($self, $timeout, $check) = @_;

        # Local variables
        my (
            $initSize, $startTime, $checkTime, $xPos, $yPos, $width, $height, $left, $right, $top,
            $bottom,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->testPanelSize', @_);
            return @emptyList;
        }

        # The test window's size can be measured once it is no longer its original size
        $initSize = 100;
        # If no timeout was specified, use the default one
        if (! defined $timeout) {

            $timeout = 1;
        }

        # Create a test window with maximum opacity, so the user doesn't see it
        my $testWin = Gtk2::Window->new('toplevel');
        $testWin->set_title($axmud::SCRIPT . ' panel test');
        $testWin->set_border_width(0);
        $testWin->set_size_request($initSize, $initSize);
        $testWin->set_decorated(FALSE);
        $testWin->set_opacity(0);
        $testWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);
        $testWin->set_skip_taskbar_hint(TRUE);
        $testWin->set_skip_pager_hint(TRUE);
        $testWin->show_all();

        # If we can find the Gnome2::Wnck::Window, we can move it this workspace
        my $wnckWin = $self->findWnckWin($testWin);
        if (! $wnckWin) {

            return undef;
        }

        $wnckWin->move_to_workspace($self->wnckWorkspace);
        $testWin->maximize();
        $testWin->show_all();

        # Initialise the timeout (a time in seconds)
        $startTime = $axmud::CLIENT->getTime();

        # The window will not become maximised immediately, so we keep looking on a loop until it
        #   does on until the timeout expires
        do {

            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->testWinControls');
            ($xPos, $yPos, $width, $height) = $self->getWinGeometry($wnckWin);

            $checkTime = $axmud::CLIENT->getTime();

        } until (
            ($width != $initSize && $height != $initSize)
            || $checkTime > ($startTime + $timeout)
        );

        $testWin->destroy();

        if ($width == $initSize || $height == $initSize) {

            # Test failed
            return @emptyList;

        } else {

            # Test successful
            return ($xPos, $yPos, $width, $height);
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
        # NB On MS Windows, Gnome2::Wnck does not exist, so the test can't be performed
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

        # Can't do anything without Gnome2::Wnck
        if ($^O eq 'MSWin32') {

            return @emptyList;
        }

        # Try to detect window controls sizes. Create first test window near the top-left corner of
        #   this workspace
        ($left, $top) = $self->testWinControls(FALSE);
        # Create second test window near the bottom-right corner
        ($right, $bottom) = $self->testWinControls(TRUE);

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
            $testWinName, $testWinSize, $testWinDistance, $wnckWin, $xPos, $yPos,
            @emptyList, @nameList,
        );

        # Check for improper arguments
        if (! defined $gravityFlag || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->testWinControls', @_);
            return @emptyList;
        }

        # This test requires that window panels have been set in an earlier call to
        #   $self->findPanelSize; in case they haven't the test fails
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
        my $testWin = Gtk2::Window->new('toplevel');
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
                ($self->panelTopSize + $testWinDistance)
            );

        } else {

            # Position the test window near the bottom-right corner
            $testWin->move(
                (
                    $self->wnckScreen->get_width() - $self->panelRightSize
                    - $testWinDistance - $testWinSize
                ),
                (
                    $self->wnckScreen->get_height() - $self->panelBottomSize
                    - $testWinDistance - $testWinSize
                ),
            );
        }

        # Set the window's gravity
        if (! $gravityFlag) {
            $testWin->set_gravity('GDK_GRAVITY_NORTH_WEST');
        } else {
            $testWin->set_gravity('GDK_GRAVITY_SOUTH_EAST');
        }

        # Use standard 'dialogue' window icons
        $testWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        # Make the window visible, briefly, otherwise we won't be able to find the
        #   Gnome2::Wnck::Window (and the sizes themselves will sometimes be wrong, as well)
        $testWin->show_all();
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->testWinControls');

        # Find the test window's corresponding Gnome2::Wnck::Window
        $wnckWin = $self->findWnckWin($testWin);
        if (! $wnckWin) {

            # The test window wasn't found. Destroy the test window
            $testWin->destroy();

            return @emptyList;
        }

        # Move the test window to the correct workspace
        $wnckWin->move_to_workspace($self->wnckWorkspace);

        # Use the corresponding Gnome2::Wnck::Window to get information about the window's actual
        #   position on the desktop
        ($xPos, $yPos) = $self->getWinGeometry($wnckWin);

        # Destroy the test window, now that we have all the data we want
        $testWin->destroy();

        if (! defined $xPos || ! defined $yPos) {

            # No window matching the title $testWinName was found
            $axmud::CLIENT->writeError(
                'Undefined window position values',
                $self->_objClass . '->testWinControls',
            );

            return @emptyList;
        }

        # Return the window controls sizes as a list
        if (! $gravityFlag) {

            # Return size of the left and top window controls
            return (
                ($xPos - ($self->panelLeftSize + $testWinDistance)),
                ($yPos - ($self->panelTopSize + $testWinDistance)),
            )

        } else {

            # Return size of the right and bottom window controls
            return (
                (
                    (
                        $self->wnckScreen->get_width() - $self->panelRightSize
                        - $testWinDistance - $testWinSize
                    ) - $xPos
                ), (
                    (
                        $self->wnckScreen->get_height() - $self->panelBottomSize
                        - $testWinDistance - $testWinSize
                    ) - $yPos
                ),
            )
        }
    }

    sub getWinGeometry {

        # Can be called by any function, e.g. by $self->testWinControls
        # Gets the actual size and position of a Gnome2::Wnck::Window
        #
        # NB On MS Windows, Gnome2::Wnck does not exist, so the test can't be performed
        #
        # Expected arguments
        #   $wnckWin    - The Gnome2::Wnck::Window to use
        #
        # Return values
        #   An empty list on improper arguments or if the test fails
        #   Otherwise a list in the form
        #       ($xPosPixels, $yPosPixels, $widthPixels, $heightPixels)

        my ($self, $wnckWin, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (! defined $wnckWin || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getWinGeometry', @_);
            return @emptyList;
        }

        # Can't do anything without Gnome2::Wnck
        if ($^O eq 'MSWin32') {

            return @emptyList;

        } else {

            # Update Wnck
            $self->wnckScreen->force_update();
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->getWinGeometry');

            # Return the window's size and position
            return $wnckWin->get_client_window_geometry();
        }
    }

    sub findGtkWin {

        # Called by $self->createGridWin
        # Given a Gnome2::Wnck::Window, finds the corresponding Gtk2::Window by comparing xids
        # NB Unlike $self->findWnckWin, this function doesn't use a timeout, and will only return
        #   a matching Gtk2::Window if one actually exists
        # NB Unlike $self->findWnckWin, this function checks all top-level windows, not just those
        #   on this workspace
        #
        # NB On MS Windows, Gnome2::Wnck does not exist, so the test can't be performed
        #
        # Expected arguments
        #   $wnckWin - The Gnome2::Wnck::Window
        #
        # Return values
        #   'undef' on improper arguments, if the Gnome2::Wnck::Window's xid can't be found or if
        #       the corresponding Gtk2::Window can't be found
        #   Otherwise, returns the corresponding Gtk2::Window

        my ($self, $wnckWin, $check) = @_;

        # Local variables
        my $wnckWinXid;

        # Check for improper arguments
        if (! defined $wnckWin || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findGtkWin', @_);
        }

        # Can't do anything without Gnome2::Wnck
        if ($^O eq 'MSWin32') {

            return undef;
        }

        # Otherwise, find the Gnome2::Wnck::Window's xid
        $wnckWinXid = $wnckWin->get_xid();
        if (! $wnckWinXid) {

            return undef;
        }

        # Find matching windows
        foreach my $item (Gtk2::Window->list_toplevels()) {

            my ($window, $winXid);

            # Ignore any which aren't Gtk2::Windows
            if (ref($item) eq 'Gtk2::Window') {

                $window = $item->get_window();
                if ($window) {

                    $winXid = $window->get_xid();
                    if ($winXid && $winXid eq $wnckWinXid) {

                        # We have found the corresponding Gtk2::Window!
                        return $item;
                    }
                }
            }
        }

        # No corresponding Gtk2::Window has been found
        return undef;
    }

    sub findWnckWin {

        # Called by $self->testWinControls, ->createGridWin and ->createSimpleGridWin
        # Given a Gtk2::Window, finds the corresponding Gnome2::Wnck::Window by comparing xids
        # The Gtk2::Window may not appear immediately in the Wnck module's list of windows, so we
        #   keep looking on a continuous loop, until a timeout expires (the default value is 1
        #   second)
        #
        # NB On MS Windows, Gnome2::Wnck does not exist, so the test can't be performed
        #
        # Expected arguments
        #   $window     - The Gtk2::Window
        #
        # Optional arguments
        #   $timeout    - A timeout, in seconds. If not defined, the default timeout is used
        #
        # Return values
        #   'undef' in improper arguments, if the Gtk2::Window's xid can't be determined or if the
        #       corresponding Gnome2::Wnck::Window can't be found before the timeout expires
        #   Otherwise, returns the corresponding Gnome2::Wnck::Window

        my ($self, $window, $timeout, $check) = @_;

        # Local variables
        my ($gdkWin, $winXid, $startTime, $checkTime);

        # Check for improper arguments
        if (! defined $window || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findWnckWin', @_);
        }

        # Can't do anything without Gnome2::Wnck
        if ($^O eq 'MSWin32') {

            return undef;
        }

        # Find the Gtk2::Window's xid
        $gdkWin = $window->get_window();
        if (! $gdkWin) {

            return undef;
        }

        $winXid = $gdkWin->get_xid();
        if (! $winXid) {

            return undef;
        }

        # If no timeout was specified, use the default one
        if (! $timeout) {

            $timeout = 1;
        }

        # Initialise the timeout (a time in seconds)
        $startTime = $axmud::CLIENT->getTime();

        # The Gtk2::Window may not appear immediately in the Wnck module's list of windows, so we
        #   keep looking on a loop until we find a match or the timeout expires
        do {

            # Update Wnck
            $self->wnckScreen->force_update();
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->findWnckWin');

            # Find matching windows
            OUTER: foreach my $wnckWin ($self->wnckScreen->get_windows()) {

                my $wnckWinXid = $wnckWin->get_xid();

                if ($wnckWinXid && $wnckWinXid eq $winXid) {

                    # We have found the corresponding Gnome2::Wnck::Window!
                    return $wnckWin;
                }
            }

            # No corresponding Gnome2::Wnck::Window has yet been found. Update the timer.
            $checkTime = $axmud::CLIENT->getTime();

        } until ($checkTime > ($startTime + $timeout));

        # The timeout has expired and no correspnding Gnome2::Wnck::Window has been found
        return undef;
    }

    sub matchWinList {

        # Called GA::GrabWindowCmd->do or any other code
        # Compares a list of strings - e.g. ('Notepad', 'Firefox') - against a list of
        #   Gnome2::Wnck::Windows on this workspace
        # Returns a list containing every Gnome2::Wnck::Window which matches one or more of the
        #   supplied names
        #
        # N.B. The names can be a regex (so 'Notepad' and '^Note' are both acceptable)
        #
        # NB On MS Windows, Gnome2::Wnck does not exist, so the test can't be performed
        #
        # Expected arguments
        #   $number         - The number of windows to match. 1 - return only the first matching
        #                       window; 7 - return only the first 7 matching windows, 0 - return all
        #                       matching windows
        #   $nameListRef    - Reference to a list of names to check
        #
        # Optional arguments
        #   $timeout        - A timeout, in seconds. If defined, we continue looking for matching
        #                       windows until at least one is found, or until the timeout expires
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of Gnome2::Wnck::Windows (which may be empty)

        my ($self, $number, $nameListRef, $timeout, $check) = @_;

        # Local variables
        my (
            $startTime, $checkTime,
            @emptyList, @nameList, @matchList,
        );

        # Can't do anything without Gnome2::Wnck
        if ($^O eq 'MSWin32') {

            return @emptyList;
        }

        # Check for improper arguments; adding a check that $number is an integer (which would
        #   indicate that $number has been missed out in the argument list)
        if (
            ! $axmud::CLIENT->intCheck($number)
            || ! defined $nameListRef
            || (defined $timeout && ! $axmud::CLIENT->intCheck($timeout))
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->matchWinList', @_);
            return @emptyList;
        }

        # Dereference the list of names
        @nameList = @$nameListRef;

        # Initialise the timeout, if one was specified
        if ($timeout) {

            $startTime = $axmud::CLIENT->getTime();
        }

        # Keep looking for windows until we reach the number of matching windows specified by
        #   $number, or until the timer expires
        do {

            # Update Wnck
            $self->wnckScreen->force_update();
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->matchWinList');

            # Find matching windows
            OUTER: foreach my $wnckWin ($self->wnckScreen->get_windows()) {

                my $name = $wnckWin->get_name();

                INNER: foreach my $matchName (@nameList) {

                    if ($name && $matchName && ($name =~ m/$matchName/i)) {

                        # A matching window was found
                        push (@matchList, $wnckWin);

                        # Do we have enough matching windows now?
                        if ($number > 0 && scalar @matchList >= $number) {

                            # We have enough matching windows
                            return @matchList;

                        } else {

                            # Look for the next matching window
                            next OUTER;
                        }
                    }
                }
            }

            # Update the timer
            $checkTime = $axmud::CLIENT->getTime();

        } until (
            ($number == 0 && @matchList)
            || (defined $timeout && $timeout > ($startTime + $timeout))
        );

        # Return the matching list of Gnome2::Wnck::Windows (may be empty)
        return @matchList;
    }

    sub getWnckWinList {

        # Can be called by any function, e.g. by $self->findPanelSize
        # Returns a list of (all) Gnome2::Wnck::Windows
        #
        # NB On MS Windows, Gnome2::Wnck does not exist, so the test can't be performed
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns the list of Gnome2::Wnck::Windows

        my ($self, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getWnckWinList', @_);
            return @emptyList;
        }

        # Can't do anything without Gnome2::Wnck
        if ($^O eq 'MSWin32') {

            return @emptyList;

        } else {

            # Update Wnck
            $self->wnckScreen->force_update();
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->getWnckWinList');

            # Get the list of windows
            return $self->wnckScreen->get_windows();
        }
    }

    sub moveResizeWin {

        # Can be called by any function (but not used by $self->testWinControls, which calls
        #   Gtk2::Window->move and ->resize directly)
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
        #   'undef' on improper arguments or if the window can't be moved (because the window object
        #       has neither its ->winWidget or ->wnckWin set)
        #   1 otherwise

        my ($self, $winObj, $xPosPixels, $yPosPixels, $widthPixels, $heightPixels, $check) = @_;

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

        # Move the window to the correct workspace, if possible (if known, and if it's not already
        #   there)
        if ($winObj->wnckWin) {

            $winObj->wnckWin->move_to_workspace($self->wnckWorkspace);
        }

        # If the window's ->winWidget is set (i.e. we know the Gtk2::Window), move it that way
        if ($winObj->winWidget) {

            # Resize the window, if that was specified
            if (defined $widthPixels) {

                $winObj->winWidget->resize($widthPixels, $heightPixels);
            }

            # This line prevents the system's window manager from placing the 'main' window at the
            #   wrong location on smaller desktops
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->moveResizeWin');

            # Move the window, if that was specified
            # v1.1.264 - for unknown reasons, $winObj->winWidget is occasionally set to 'undef'
            #   just before this line. Temporary fix until we find the cause
#            if (defined $xPosPixels) {
            if ($winObj->winWidget && defined $xPosPixels) {

                $winObj->winWidget->move($xPosPixels, $yPosPixels);
            }

        # Otherwise if the window's ->wnckWin (i.e. we know the equivalent Gnome2::Wnck::Window),
        #   move that, instead
        } elsif ($winObj->wnckWin) {

            # Move and resize the window, if both were specified
            if (defined $widthPixels && $xPosPixels) {

                $winObj->wnckWin->set_geometry(
                    'WNCK_WINDOW_GRAVITY_CURRENT',
                    [
                        'WNCK_WINDOW_CHANGE_X',         # Gnome2::Wnck::WindowMoveResizeMask
                        'WNCK_WINDOW_CHANGE_Y',
                        'WNCK_WINDOW_CHANGE_WIDTH',
                        'WNCK_WINDOW_CHANGE_HEIGHT',
                    ],
                    $xPosPixels,
                    $yPosPixels,
                    $widthPixels,
                    $heightPixels
                );
            }
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
        #   in the specified layer, on the workspace $self->wnckWorkspace
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
        #                       Gtk2::Window's layout when it is first created. If 'undef', a
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
        #   $winWidget      - The Gtk2::Window, if it already exists and it is known (otherwise
        #                       set to 'undef')
        #   $wnckWin        - The Gnome2::Wnck::Window, if it already exists and it is known
        #                       (otherwise set to 'undef'. If both $winWidget and $wnckWin are
        #                       'undef', a new window object is created)
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
        #                       in the first list are called just after the Gtk2::Window is created.
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
            $self, $winType, $winName, $winTitle, $winmapName, $packageName, $winWidget, $wnckWin,
            $owner, $session, $workspaceGrid, $zone, $layer, $xPosPixels, $yPosPixels, $widthPixels,
            $heightPixels, $beforeListRef, $afterListRef, $check,
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
                $winType, $winName, $winTitle, $winmapName, $packageName, $winWidget, $wnckWin,
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
                    $wnckWin,
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

            # Create a new Gtk2::Window widget at the specified size and position (but don't make
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

            # Find the Gtk2::Window or the Gnome2::Wnck::Window, if we don't already know them
            if (! $wnckWin) {

                $wnckWin = $self->findWnckWin($winObj->winWidget);
                if ($wnckWin) {

                    $winObj->set_wnckWin($wnckWin);
                }
            }

            # Move the window to its correct workspace, size and position
            $self->moveResizeWin(
                $winObj,
                $xPosPixels,
                $yPosPixels,
                $widthPixels,
                $heightPixels,
            );

            # For 'grid' windows, $winObj->winEnable created the window in a minimised state, so its
            #   Gnome2::Wnck::Window can be found, and so the window can be moved to its correct
            #   workspace, before actually becoming visible on the desktop
            # Unminimise it now
            $winObj->winWidget->deiconify();

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
            if (! $winObj->winSetup($wnckWin)) {

                # Something or other failed. Update the zone
                $zoneObj->removeArea($areaObj);

                return undef;
            }

            # We already have ->wnckWin, but not ->winWidget
            $winWidget = $self->findGtkWin($winObj->wnckWin);
            if ($winWidget) {

                $winObj->set_winWidget($winWidget);
                $winObj->set_winBox($winWidget);
                # When the user closes this 'external' window manually, it needs to be removed
                #   from the workspace grid. Set up a ->signal_connect
                $winObj->setDeleteEvent($winWidget);

            } else {

                # If we don't have a corresponding Gtk2::Window, create a Gnome2::Wnck::Screen
                #   ->signal_connect to deal with removing the 'external' window from the workspace
                #   grid, when the time comes
                $winObj->setWindowClosedEvent();
            }

            # Store the 'external' window's original position and size, so that they can be restored
            #   if the window is banished from the workspace grid
            @geometryList = $self->getWinGeometry($winObj->wnckWin);
            if (@geometryList) {

                $winObj->set_oldPosn(@geometryList);
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
            if ($winObj->wnckWin->is_minimized) {

                $winObj->wnckWin->unminimize(time());
            }
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
        #                       Gtk2::Window's layout when it is first created. If 'undef', a
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
        #   $winWidget      - The Gtk2::Window, if it already exists and it is known (otherwise
        #                       set to 'undef')
        #   $wnckWin        - The Gnome2::Wnck::Window, if it already exists and it is known
        #                       (otherwise set to 'undef'. If both $winWidget and $wnckWin are
        #                       'undef', a new window object is created)
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
        #                       in the first list are called just after the Gtk2::Window is created.
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
            $self, $winType, $winName, $winTitle, $winmapName, $packageName, $winWidget, $wnckWin,
            $owner, $session, $xPosPixels, $yPosPixels, $widthPixels, $heightPixels, $beforeListRef,
            $afterListRef, $check,
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

            # Create a new Gtk2::Window widget (but don't make it visible yet)
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

            # Find the Gtk2::Window or the Gnome2::Wnck::Window, if we don't already know them
            if (! $wnckWin) {

                $wnckWin = $self->findWnckWin($winObj->winWidget);
                if ($wnckWin) {

                    $winObj->set_wnckWin($wnckWin);
                }
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

            # For 'external' windows, we already have ->wnckWin, but not ->winWidget
            $winWidget = $self->findGtkWin($winObj->wnckWin);
            if ($winWidget) {

                $winObj->set_winWidget($winWidget);
                $winObj->set_winBox($winWidget);
                # When the user closes this 'external' window manually, it needs to be removed
                #   from the workspace grid. Set up a ->signal_connect
                $winObj->setDeleteEvent($winWidget);

            } else {

                # If we don't have a corresponding Gtk2::Window, create a Gnome2::Wnck::Screen
                #   ->signal_connect to deal with removing the 'external' window from the workspace
                #   grid, when the time comes
                $winObj->setWindowClosedEvent($wnckWin);
            }

            # Store the 'external' window's original position and size, so that they can be restored
            #   if the window is banished from the workspace grid
            @geometryList = $self->getWinGeometry($winObj->wnckWin);
            if (@geometryList) {

                $winObj->set_oldPosn(@geometryList);
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
            if ($winObj->wnckWin->is_minimized) {

                $winObj->wnckWin->unminimize(time());
            }
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
        #   $winWidget      - The Gtk2::Window, if it already exists and it is known (otherwise set
        #                       to 'undef')
        #   $wnckWin        - The Gnome2::Wnck::Window, if it already exists and it is known
        #                       (otherwise set to 'undef')
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
            $self, $workspaceGridObj, $winType, $winName, $winWidget, $wnckWin, $owner, $session,
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
    sub wnckWorkspace
        { $_[0]->{wnckWorkspace} }
    sub wnckScreen
        { $_[0]->{wnckScreen} }

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
