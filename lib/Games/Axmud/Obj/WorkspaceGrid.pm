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
# Games::Axmud::Obj::WorkspaceGrid
# The workspace grid object, on which windows on a single workspace are arranged

{ package Games::Axmud::Obj::WorkspaceGrid;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Desktop->add_grid() if the parent workspace object's ->gridEnableFlag
        #   is TRUE ('grid' windows are not arranged on a workspace grid if FALSE)
        #
        # Expected arguments
        #   $number         - Number for this workspace grid object, unique to its workspace
        #   $workspaceObj   - The GA::Obj::Workspace object for the workspace on which this
        #                       workspace grid is displayed
        #
        # Optional arguments
        #   $owner          - (GA::Client->shareMainWinFlag = TRUE) The GA::Session object which
        #                       controls this workspace grid
        #                   - (GA::Client->shareMainWinFlag = FALSE) 'undef' (the grid is shared
        #                       between all sessions)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $workspaceObj, $owner, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'workspace_grid_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # Number for this workspace grid object, unique to its workspace
            number                      => $number,
            # The GA::Obj::Workspace object for the workspace on which this workspace grid is
            #   displayed
            workspaceObj                => $workspaceObj,
            # (GA::Client->shareMainWinFlag = TRUE) The GA::Session object which controls this
            #   workspace grid
            # (GA::Client->shareMainWinFlag = FALSE) 'undef' (the grid is shared between all
            #   sessions)
            owner                       => $owner,

            # The name of the zonemap used by this workspace grid to create zones
            zonemap                     => undef,

            # Maximum number of layers in this workspace grid
            maxLayers                   => 16,
            # The default layer in this workspace grid for new windows (a number from 0 to
            #   ($self->maxLayers - 1) )
            defaultLayer                => 0,       # The bottom layer
            # The currently visible layer ('undef' if not set yet)
            currentLayer                => undef,

            # The size of this grid, in gridblocks, once it's been set up (the size of the whole
            #   workspace, minus any areas used by panels/taskbars)
            widthBlocks                 => undef,
            heightBlocks                => undef,
            # The coordinates of the top-left pixel of the workspace grid on the workspace - must be
            #   added to a window's actual coordinates on the workspace whenever the window is
            #   created, resized or moved (if there are no panels to the top and to the left, both
            #   set to 0)
            xPosPixels                  => undef,
            yPosPixels                  => undef,

            # The workspace grid itself covers the whole available workspace (minus any panels,
            #   etc).
            # It consists of a hash of zone objects (GA::Obj::Zone), each of which defines a zone
            #   of the grid into which one or more windows can be inserted. The 'plan' by which the
            #   workspace grid is divided into zones is the zonemap object (GA::Obj::Zonemap).
            #   Each zone object stores details about its size and position on this workspace grid,
            #   and the windows it contains
            # The top-left gridblock always has the coordinates 0,0 - so if this workspace grid is
            #   sized 100x100 gridblocks, the bottom-right gridblock has the coordinates 99,99
            # Rather than using a 2D array, we use calls to $self->checkPosn to check that a zone of
            #   the grid is/is not occupied by a zone object (GA::Obj::Zone)
            # Hash in the form
            #   $zoneHash{number} = blessed_reference_to_zone_object
            zoneHash                    => {},
            # Number of zone objects ever created for this workspace grid (used to give every zone
            #   object a number unique to the workspace grid)
            # Is reset to 0 when $self->resetGrid is called (because this operation removes all
            #   zones)
            zoneCount                   => 0,
            # Zonemaps have a fixed size (60x60), but workspace grids have an arbitrary size (which
            #   may or may not be the same)
            # In order to make sure zones are spaced equally, and that there are no gaps between
            #   them because of rounding errors, as soon as this workspace grid is created (or
            #   reset), decide which part of the grid corresponds to which part of the zonemap's
            #   60x60 grid
            # e.g If the whole workspace is free, and is sized 1200x800,
            #   $zonemapXCoordHash{0} = 0   First part of 60x60 grid is in top-left corner of the
            #                               workspace grid
            #   $zonemapXCoordHash{1} = 20  Second part of 60x60 grid starts at the workspace grid,
            #                               x = 20
            #   $zonemapXCoordHash{2} = 40  Second part of 60x60 grid starts at the workspace grid,
            #                               x = 40
            zonemapXCoordHash           => {},
            zonemapYCoordHash           => {},

            # Registry hash of grid windows that have been placed onto this workspace grid (a subset
            #   of GA::Obj::Desktop->gridWinHash). Hash in the form
            #   $gridWinHash{unique_number} = blessed_reference_to_grid_window_object
            gridWinHash                 => {},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    sub start {

        # Called by GA::Obj::Workspace->addWorkspaceGrid
        # Sets up this workspace grid using a specified zonemap
        #
        # Expected arguments
        #   $zonemap    - The GA::Obj::Zonemap which specifies how zones should be arranged on the
        #                   workspace grid
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $zonemap, $check) = @_;

        # Check for improper arguments
        if (! defined $zonemap || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->start', @_);
        }

        # The new current zonemap is the default one
        $self->ivPoke('zonemap', $zonemap);

        # Set up the workspace grid
        $self->resetGrid();
        # Set up zones on the newly-created grid
        $self->resetZones();

        return 1;
    }

    sub stop {

        # Called by GA::Obj::Desktop->del_grid
        # Closes any 'grid' windows on this workspace grid
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $session    - When a GA::Session is closing, that session. When specified, the
        #                   session's 'main' window is disengaged (removed from its workspace grid),
        #                   not closed, in the expectation that GA::Session->close might want to
        #                   preserve it
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my ($count, $msg);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->stop', @_);
        }

        # Tell any remaining 'grid' window objects to close their windows. If $session is
        #   defined, 'main' windows merely remove themselves from the workspace grid, but the
        #   window itself is not closed (exception: when Axmud is shutting down, all windows are
        #   closed)
        # Do this in the reverse order they were created, in the expectation that 'main' windows
        #   will be closed last
        foreach my $winObj (sort {$b->number <=> $a->number} ($self->ivValues('gridWinHash'))) {

            if (! $axmud::CLIENT->shutdownFlag && $session && $session->mainWin eq $winObj) {

                # (The ->winDisengage function calls $self->del_gridWin in turn)
                $winObj->winDisengage($session);

            } else {

                # (The ->winDestroy function calls $self->del_gridWin in turn)
                $winObj->winDestroy();
            }
        }

        # Check there are no 'grid' windows left (for error-detection purposes)
        $count = $self->ivPairs('gridWinHash');
        if ($count) {

            if ($count == 1) {
                $msg = 'There was 1';
            } else {
                $msg = 'There were ' . $count;
            }

            $msg .= ' un-closed \'grid\' window when the parent workspace grid closed';

            $axmud::CLIENT->writeWarning($msg, $self->_objClass . '->stop');
        }

        return 1;
    }

    sub fineTuneWinSize {

        # Called by GA::Obj::Workspace->chooseWinPosn, $self->changeWinzone,
        #   GA::Obj::Zone->adjustMultipleWin and ->replaceAreaSpace
        # Makes small adjustments to a window's size and position to close any gaps on the right and
        #   bottom edges of the workspace grid (because of an arkwardly-sized available workspace)
        # Makes more small adjustments to correct for window controls, usually before a call to
        #   GA::Obj::Workspace->moveResizeWin. (If the desktop theme uses window controls, we have
        #   to take them into account, changing the size of the window accordingly; $widthPixels and
        #   $heightPixels must now refer to the client area, not the whole window including the
        #   window controls)
        #
        # Expected arguments
        #   $winType    - The window type; one of the 'grid' window types specified by
        #                   GA::Client->constGridWinTypeHash
        #   $xPosPixels, $yPosPixels
        #               - The position of the window to be fine-tuned
        #   $widthPixels, $heightPixels
        #               - The size of the window to be fine-tuned
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns the adjusted list, in the form
        #       ($xPosPixels, $yPosPixels, $widthPixels, $heightPixels)

        my ($self, $winType, $xPosPixels, $yPosPixels, $widthPixels, $heightPixels, $check) = @_;

        # Local variables
        my (
            $gridRightEdge, $winRightEdge, $gridBottomEdge, $winBottomEdge, $rightGap, $bottomGap,
            @emptyList,
        );

        # Check for improper arguments
        if (
            ! defined $winType || ! defined $xPosPixels || ! defined $yPosPixels
            || ! defined $widthPixels || ! defined $heightPixels || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->fineTuneWinSize', @_);
            return @emptyList;
        }

        # Close the gap between the workspace grid and the right and bottom edges of the available
        #   workspace, if there is one, and if the global flag is set
        if ($axmud::CLIENT->gridEdgeCorrectionFlag) {

            # Get the position of the right boundary of the workspace grid, and the right edge of
            #   the window, in pixels
            $gridRightEdge
                = $self->xPosPixels + ($self->widthBlocks * $axmud::CLIENT->gridBlockSize) - 1;
            $winRightEdge = $xPosPixels + $widthPixels - 1;

            $gridBottomEdge
                = $self->yPosPixels + ($self->heightBlocks * $axmud::CLIENT->gridBlockSize) -1;
            $winBottomEdge = $yPosPixels + $heightPixels - 1;

            # For windows on the right edge of the workspace grid, look for a gap between that edge
            #   and the edge of the available workspace that's smaller than a gridblock
            if ($gridRightEdge == $winRightEdge) {

                $rightGap = $self->workspaceObj->currentWidth
                                - $self->workspaceObj->panelRightSize - 1 - $gridRightEdge;

                if ($rightGap > 0 && $rightGap < $axmud::CLIENT->gridBlockSize) {

                    # Increase the width of the window, therefore closing the gap
                    $widthPixels += $rightGap;
                }
            }

            # For windows on the bottom edge of the workspace grid, look for a gap between that edge
            #   and the edge of the available workspace that's smaller than a gridblock
            if ($gridBottomEdge == $winBottomEdge) {

                $bottomGap = $self->workspaceObj->currentHeight
                                - $self->workspaceObj->panelBottomSize - 1 - $gridBottomEdge;

                if ($bottomGap > 0 && $bottomGap < $axmud::CLIENT->gridBlockSize) {

                    # Increase the height of the window by the amount, therefore closing the gap
                    $heightPixels += $bottomGap;
                }
            }
        }

        # Adjust the size of the window to account for window controls for this workspace
        # NB 'external' windows aren't fine-tuned in this way - instead,
        #   GA::Obj::Workspace->createGridWin takes window controls into account in its call to
        #   ->moveResizeWin
        if ($winType ne 'external') {

            $widthPixels -= ($self->workspaceObj->controlsLeftSize
                                + $self->workspaceObj->controlsRightSize);
            $heightPixels -= ($self->workspaceObj->controlsTopSize
                                + $self->workspaceObj->controlsBottomSize);
        }

        return ($xPosPixels, $yPosPixels, $widthPixels, $heightPixels);
    }

    sub applyZonemap {

        # Called by GA::Cmd::ResetGrid->do and GA::Obj::File->extractData
        # Resets this workspace grid and all windows on it, using a new zonemap if specified, or
        #   re-using the existing one if not
        # If a temporary zonemap is specified, calls $self->applyTempZonemap to do the job
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $zonemapObj      - The zonemap object (GA::Obj::Zonemap) to use ('undef' to re-use the
        #                       existing zonemap)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $zonemapObj, $check) = @_;

        # Local variables
        my $errorFlag;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->applyZonemap', @_);
        }

        # If using a temporary zonemap (created by MXP), check that the zonemap 'belongs' to
        #   the same session that controls this workspace grid (not a concern if all sessions share
        #   workspace grids)
        # $self->applyTempZonemap is then called to preserve the size and position of existing
        #   windows (as far as possible)
        if ($zonemapObj && $zonemapObj->tempFlag) {

            if ($self->owner && $zonemapObj->tempSession ne $self->owner) {
                return undef;
            } else {
                return $self->applyTempZonemap($zonemapObj);
            }
        }

        # Update IVs
        if ($zonemapObj) {

            $self->ivPoke('zonemap', $zonemapObj->name);
        }

        # Reset the grid itself, emptying it of zones
        $self->resetGrid();
        # Reset zones on the newly-emptied grid, using zone models from the zonemap
        $self->resetZones();

        # For each 'grid' window object on this workspace grid, find a new position on the grid and
        #   give it a new area object (GA::Obj::Area) storing details of that position
        OUTER: foreach my $winObj (
            sort {$a->number <=> $b->number} ($self->ivValues('gridWinHash'))
        ) {
            if (! $self->repositionGridWin($winObj)) {

                $errorFlag = TRUE;
                last OUTER;
            }
        }

        if ($errorFlag) {

            # In the unlikely event of an error, disable grids in this workspace - destroying/
            #   disengaging windows adds too many complications
            $self->workspaceObj->disableWorkspaceGrids();

            return undef;

        } else {

            return 1;
        }
    }

    sub applyTempZonemap {

        # Called by $self->applyZonemap, whenever a temporary zonemap is specified (which has
        #   passed some basic checks)
        # Resets this workspace grid using the temporary zonemap (which should have a single zone
        #   model, encompassing the whole of the zonemap's internal grid)
        # Tries to place existing 'grid' windows on the reset grid at their former size and
        #   position
        # If successful, the user won't realise (immediately) that a new zonemap has been applied
        #
        # Expected arguments
        #   $zonemapObj      - The temporary zonemap object (GA::Obj::Zonemap) to use. This
        #                       function assumes it was created by GA::Client->createTempZonemap,
        #                       and that it has a single zone model (and is not editable)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $zonemapObj, $check) = @_;

        # Local variables
        my (
            $errorFlag,
            @failList,
            %gridWinHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->applyTempZonemap', @_);
        }

        # Remember the current size/position of 'grid' windows
        %gridWinHash = $self->gridWinHash;

        # Update IVs
        $self->ivPoke('zonemap', $zonemapObj->name);
        # Reset the grid itself, emptying it of zones
        $self->resetGrid();
        # Reset zones on the newly-emptied grid, using zone models from the zonemap
        $self->resetZones();

        # For each 'grid' window object on this workspace grid, try to place the window on the grid
        #   at its former size and position, giving it a new area object
        foreach my $winObj (sort {$a->number <=> $b->number} (values %gridWinHash)) {

            if (! $self->restoreGridWin($winObj)) {

                push (@failList, $winObj);
            }
        }

        # Any windows that couldn't be restored to their former size and position can be placed
        #   onto the grid as normal
        OUTER: foreach my $winObj (@failList) {

            if (! $self->repositionGridWin($winObj)) {

                $errorFlag = TRUE;
                last OUTER;
            }
        }

        if ($errorFlag) {

            # In the unlikely event of an error, disable grids in this workspace - destroying/
            #   disengaging windows adds too many complications
            $self->workspaceObj->disableWorkspaceGrids();

            return undef;

        } else {

            return 1;
        }
    }

    sub resetGrid {

        # Called by $self->start or $self->applyZonemap
        # Resets the workspace grid, deleting any existing zones. The new size of the grid is the
        #   whole workspace, minus any areas reserved for panels (taskbars)
        # Given the size of the available workspace, also works out which parts of the workspace
        #   grid correspond to each gridblock on the zonemap's 60x60 grid
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional argument
        #   $zonemap    - The name of the new zonemap to use; if specified, stored in
        #                   $self->zonemap; if 'undef', the zonemap stored in $self->zonemap is not
        #                   modified
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $zonemap, $check) = @_;

        # Local variables
        my (
            $availableWidth, $availableHeight,
            %xCoordHash, %yCoordHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetGrid', @_);
        }

        # Set the new zonemap, if one was specified (and it exists)
        if ($zonemap && $axmud::CLIENT->ivExists('zonemapHash', $zonemap)) {

            $self->ivPoke('zonemap', $zonemap);
        }

        # The size of the available workspace is the current width and height, minus any space
        #   reserved for panels
        $availableWidth = $self->workspaceObj->currentWidth - $self->workspaceObj->panelLeftSize
                            - $self->workspaceObj->panelRightSize;
        $availableHeight = $self->workspaceObj->currentHeight - $self->workspaceObj->panelTopSize
                            - $self->workspaceObj->panelBottomSize;

        # Now work out the size of the grid, rounding down if necessary (this may create small areas
        #   near the right and bottom edges of the workspace, if it's an arkward size like 1047x731)
        $self->ivPoke('widthBlocks', int($availableWidth / $axmud::CLIENT->gridBlockSize));
        $self->ivPoke('heightBlocks', int($availableHeight / $axmud::CLIENT->gridBlockSize));


        # Set the x/y coordinates, in pixels, of the top-left corner of the grid on the wprkspace
        $self->ivPoke('xPosPixels', $self->workspaceObj->panelLeftSize);
        $self->ivPoke('yPosPixels', $self->workspaceObj->panelTopSize);

        # Empty the workspace grid, which deletes any existing zones
        $self->ivEmpty('zoneHash');
        $self->ivPoke('zoneCount', 0);

        # Work out which parts of the workspace grid correspond to each block on the zonemap's 60x60
        #   grid
        for (my $count = 0; $count < 60; $count++) {

            $xCoordHash{$count} = int (($count * $self->widthBlocks) / 60);
        }

        for (my $count = 0; $count < 60; $count++) {

            $yCoordHash{$count} = int (($count * $self->heightBlocks) / 60);
        }

        # Store the hashes
        $self->ivPoke('zonemapXCoordHash', %xCoordHash);
        $self->ivPoke('zonemapYCoordHash', %yCoordHash);

        # Set the currently visible layer to the default one
        $self->ivPoke('currentLayer', $self->defaultLayer);

        # Grid reset complete
        return 1;
    }

    sub resetZones {

        # Called by $self->start or ->applyZonemap
        # Sets up all zones on the workspace grid, according to the instructions provided by the
        #   current zonemap
        # This function assumes that the workspace grid is currently empty
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the current GA::Obj::Zonemap can't be found or if a
        #       GA::Obj::Zone can't be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $zonemapObj, $count,
            %modelHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetZones', @_);
        }

        # Import IVs
        $zonemapObj = $axmud::CLIENT->ivShow('zonemapHash', $self->zonemap);
        if (! $zonemapObj) {

            # The current zonemap seems to be missing
            return $self->writeError(
                'Missing zonemap \'' . $self->zonemap . '\'',
                $self->_objClass . '->resetZones',
            );

        } else {

            # Import the zonemap's GA::Obj::ZoneModel objects
            %modelHash = $zonemapObj->modelHash;
        }

        # Create new zones for each zone model in the list in ascending order
        $count = 0;
        foreach my $modelObj (
            sort {$a->number <=> $b->number} ($zonemapObj->ivValues('modelHash'))
        ) {
            my ($zoneObj, $leftBlocks, $rightBlocks, $topBlocks, $bottomBlocks);

            # Create a new zone object
            $zoneObj = Games::Axmud::Obj::Zone->new($count, $self);
            if (! $zoneObj) {

                # This is a fatal error
                return undef;

            } else {

                $count++;
            }

            # Set the zone's variables using the zone model's variables

            # Translate the zone model's coordinates on the the zonemap's 60x60 grid into the
            #   coordinates of a zone on the workspace grid
            # For the top left corner, use the actual values specified by the zone model. For
            #   the bottom right corner, use one block to the left/above the value of the NEXT
            #   block to the right/below (unless we're on the right or bottom edge of the
            #   available workspace; in that case, use the gridblock touching the edge)

            # Top-left corner
            $leftBlocks = $self->ivShow('zonemapXCoordHash', $modelObj->left);
            $topBlocks = $self->ivShow('zonemapYCoordHash', $modelObj->top);

            # Bottom-right corner
            if ($modelObj->right == ($zonemapObj->gridSize - 1)) {

                # Furthest right gridblock has x co-ord (width - 1)
                $rightBlocks = ($self->widthBlocks - 1);

            } else {

                $rightBlocks
                    = $self->ivShow('zonemapXCoordHash', ($modelObj->right + 1)) - 1;
            }

            if ($modelObj->bottom == ($zonemapObj->gridSize - 1)) {

                # Furthest down gridblock has y co-ord (height - 1)
                $bottomBlocks = ($self->heightBlocks - 1);

            } else {

                $bottomBlocks
                    = $self->ivShow('zonemapYCoordHash',($modelObj->bottom + 1)) - 1;
            }

            # Check that the workspace grid is free at those locations
            $self->checkPosn($leftBlocks, $rightBlocks, $topBlocks, $bottomBlocks);

            # Now mark the workspace as occupied at these points
            $self->ivAdd('zoneHash', $zoneObj->number, $zoneObj);
            $self->ivPoke('zoneCount', $count);

            # Set the zone's coordinates and size
            $zoneObj->set_posn($leftBlocks, $topBlocks);
            $zoneObj->set_size(
                ($rightBlocks - $leftBlocks + 1),
                ($bottomBlocks - $topBlocks + 1),
            );

            # Set the reserved window variables
            $zoneObj->set_reserved(
                $modelObj->multipleLayerFlag,
                $modelObj->reservedFlag,
                $modelObj->reservedHash,
            );

            # Setup the zone's internal grid
            $zoneObj->resetInternalGrid();

            # Set the orientation variables
            $zoneObj->set_orientation($modelObj->startCorner, $modelObj->orientation);

            # Set the winmap variables
            $zoneObj->set_winmap(
                $modelObj->defaultEnabledWinmap,
                $modelObj->defaultDisabledWinmap,
                $modelObj->defaultInternalWinmap,
            );

            # Set the area variables (each GA::Obj::Area object handles a single window and
            #   reserves an area of the zone for that window)
            $zoneObj->set_areaVars($modelObj->areaMax, $modelObj->visibleAreaMax, 0);

            # Set the string specifying an owner
            $zoneObj->set_ownerString($modelObj->ownerString);

            # Set the default area sizes
            if ($zoneObj->visibleAreaMax) {

                # If there's a maximum number of visible areas, set the default area sizes
                #   around that
                if ($zoneObj->orientation eq 'horizontal') {

                    $zoneObj->set_areaWidth(int($zoneObj->widthBlocks / $zoneObj->visibleAreaMax));
                    $zoneObj->set_areaHeight($zoneObj->heightBlocks);

                } elsif ($zoneObj->orientation eq 'vertical') {

                    $zoneObj->set_areaWidth($zoneObj->widthBlocks);
                    $zoneObj->set_areaHeight(
                        int($zoneObj->heightBlocks / $zoneObj->visibleAreaMax),
                    );
                }

            } else {

                # If the zone model specifies a default area size, use that. Otherwise set the
                #   default area sizes using global defaults
                if ($modelObj->defaultAreaWidth) {

                    $zoneObj->set_areaWidth(
                        # (Convert a 60x60 grid to workspace gridblocks)
                        int($zoneObj->widthBlocks * ($modelObj->defaultAreaWidth / 60)),
                    );

                } else {

                    $zoneObj->set_areaHeight(
                        int($axmud::CLIENT->customGridWinWidth / $axmud::CLIENT->gridBlockSize),
                    );
                }

                if ($modelObj->defaultAreaHeight) {

                    $zoneObj->set_areaWidth(
                        # (Convert a 60x60 grid to workspace gridblocks)
                        int($zoneObj->heightBlocks * ($modelObj->defaultAreaHeight / 60)),
                    );

                } else {

                    $zoneObj->set_areaHeight(
                        int($axmud::CLIENT->customGridWinHeight / $axmud::CLIENT->gridBlockSize),
                    );
                }
            }
        }

        return 1;
    }

    sub repositionGridWin{

        # Called by $self->applyZonemap and GA::Obj::Desktop->convertSpareMainWin
        # New 'grid' windows are placed onto a workspace grid via a call to
        #   GA::Obj::Workspace->createGridWin
        # Existing 'grid' windows are given a new position on the same grid by calling this
        #   function, which creates a new area object (GA::Obj::Area) storing details of the new
        #   position
        #
        # Expected arguments
        #   $winObj     - The existing window object (inheriting from GA::Generic::Win)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be repositioned
        #   1 on success

        my ($self, $winObj, $check) = @_;

        # Local variables
        my (
            $zoneObj, $widthPixels, $heightPixels, $layer, $xPosBlocks, $yPosBlocks,
            $widthBlocks, $heightBlocks, $xPosPixels, $yPosPixels, $areaObj,
        );

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->repositionGridWin', @_);
        }

        # Choose the new zone
        $zoneObj = $self->workspaceObj->chooseZone(
            $self,
            $winObj->winType,
            $winObj->winName,
            $winObj->winWidget,
            undef,
            $winObj->owner,
            $winObj->session,
        );

        if (! $zoneObj) {

            # No available zones
            return undef;
        }

        # Choose the window size within the zone
        ($widthPixels, $heightPixels) = $self->workspaceObj->chooseWinSize(
            $winObj->winType,
            $self,
            $zoneObj,
        );

        # Choose the exact size and position of the window inside its zone, taking into account such
        #   factors as other windows in the zone
        (
            $layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $xPosPixels,
            $yPosPixels, $widthPixels, $heightPixels,
        ) = $self->workspaceObj->chooseWinPosn(
            $winObj->session,       # Write error messages here
            $winObj->winType,
            TRUE,                   # Use the zone allocated above
            $self,
            $widthPixels,
            $heightPixels,
            $zoneObj,
        );

        if (! defined $layer) {

            # Zone is full
            return undef;
        }

        # Create a GA::Obj::Area within the zone (which handles the existing window, and is the
        #   same size as it)
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
            $winObj->session,
        );

        if (! $areaObj) {

            # Checks failed
            return undef;

        } else {

            $winObj->set_areaObj($areaObj);
            $areaObj->set_win($winObj);
        }

        # Move the window to its correct size and position
        $self->workspaceObj->moveResizeWin(
            $winObj,
            $xPosPixels,
            $yPosPixels,
            $widthPixels,
            $heightPixels,
        );

        # This object's new current layer is the layer in which this window will be placed (so that
        #   it's visible to the user immediately)
        $self->ivPoke('currentLayer', $layer);

        # Make the usual sensible adjustments to window sizes (see the comments in
        #   GA::Obj::Workspace->createGridWin)
        if (
            $axmud::CLIENT->gridAdjustmentFlag
            && $zoneObj->areaHash
            && $zoneObj->areaMax != 1
            && (
                # Windows are stacked horizontally, and there's only room for one (default-size)
                #   window in each row
                (
                    $zoneObj->orientation eq 'horizontal'
                    && $zoneObj->heightBlocks >= $zoneObj->defaultAreaHeight
                    && $zoneObj->heightBlocks < ($zoneObj->defaultAreaHeight * 2)
                # Windows are stacked vertically, and there's only room for one (default-size)
                #   window in each column
                ) || (
                    $zoneObj->orientation eq 'vertical'
                    && $zoneObj->widthBlocks >= $zoneObj->defaultAreaWidth
                    && $zoneObj->widthBlocks < ($zoneObj->defaultAreaWidth * 2)
                )
            )
        ) {
            $zoneObj->adjustMultipleWin($areaObj->layer);
        }

        # Operation complete
        return 1;
    }

    sub restoreGridWin{

        # Called by $self->applyTempZonemap; counterpart to $self->repositionGridWin (which is
        #   called by $self->applyZonemap)
        # After the grid has been reset, tries to place a 'grid' window onto the grid at its former
        #   size and position, creating a new area object (GA::Obj::Area)
        # This function assumes the new zonemap is a temporary zonemap with a single zone model,
        #   encompassing the whole of the zonemap's internal grid)
        #
        # Expected arguments
        #   $winObj     - The existing window object (inheriting from GA::Generic::Win)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be restored
        #   1 on success

        my ($self, $winObj, $check) = @_;

        # Local variables
        my ($zoneObj, $oldAreaObj, $newAreaObj);

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restoreGridWin', @_);
        }

        # Get the (single) zone
        $zoneObj = $self->ivShow('zoneHash', 0);
        if (! $zoneObj) {

            return undef;
        }

        # Create a GA::Obj::Area within the zone (which handles the existing window, and is the
        #   same size as it)
        $oldAreaObj = $winObj->areaObj;
        $newAreaObj = $zoneObj->addArea(
            $oldAreaObj->layer,
            $oldAreaObj->zoneObj->xPosBlocks + $oldAreaObj->leftBlocks,
            $oldAreaObj->zoneObj->yPosBlocks + $oldAreaObj->topBlocks,
            $oldAreaObj->widthBlocks,
            $oldAreaObj->heightBlocks,
            $oldAreaObj->xPosPixels,
            $oldAreaObj->yPosPixels,
            $oldAreaObj->widthPixels,
            $oldAreaObj->heightPixels,
            $winObj->session,
        );

        if (! $newAreaObj) {

            # Checks failed
            return undef;

        } else {

            $winObj->set_areaObj($newAreaObj);
            $newAreaObj->set_win($winObj);

            return 1;
        }
    }

    sub checkPosn {

        # Called by $self->resetZones
        # Check to see if a proposed zone would fit onto a region of the workspace grid, at a
        #   specified position, without overlapping existing zones
        #
        # Expected arguments
        #   $leftBlocks, $rightBlocks, $topBlocks, $bottomBlocks
        #           - The boundaries of the region to check
        #
        # Return values
        #   'undef' on improper arguments or if the zone overlaps another zone
        #   1 otherwise

        my ($self, $leftBlocks, $rightBlocks, $topBlocks, $bottomBlocks, $check) = @_;

        # Check for improper arguments

        if (
            ! defined $leftBlocks || ! defined $rightBlocks || ! defined $topBlocks
            || ! defined $bottomBlocks || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkPosn', @_);
        }

        # Check each existing zone in turn
        foreach my $zoneObj ($self->ivValues('zoneHash')) {

            my ($x1, $x2, $y1, $y2);

            $x1 = $zoneObj->xPosBlocks;
            $x2 = $x1 + $zoneObj->widthBlocks - 1;
            $y1 = $zoneObj->yPosBlocks;
            $y2 = $y1 + $zoneObj->heightBlocks - 1;

            if (
                (
                    ($x1 >= $leftBlocks && $x1 <= $rightBlocks)
                    || ($x2 >= $leftBlocks && $x2 <= $rightBlocks)
                ) && (
                    ($y1 >= $topBlocks && $y1 <= $bottomBlocks)
                    || ($y2 >= $topBlocks && $y2 <= $bottomBlocks)
                )
            ) {
                return undef;
            }
        }

        # The proposed zone fits at the specified position without overlapping existing zones
        return 1;
    }

    sub findZone {

        # Called by GA::Obj::Workspace->createGridWin and GA::Cmd::FixWindow->do to find out
        #   which zone occupies a specified position (in pixels) on the workspace
        #
        # Expected arguments
        #   $xPosPixels, $yPosPixels
        #       - The coordinates of a pixel on the workspace (the top-left pixel has co-ords 0, 0)
        #
        # Return values
        #   'undef' on improper arguments or if no zone occupies the specified pixel
        #   Otherwise returns the GA::Obj::Zone that occupies the specified pixel

        my ($self, $xPosPixels, $yPosPixels, $check) = @_;

        # Local variables
        my ($xPosBlocks, $yPosBlocks);

        # Check for improper arguments
        if (! defined $xPosPixels || ! defined $yPosPixels || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findZone', @_);
        }

        # Work out which gridblock occupies this position
        $xPosBlocks = ($xPosPixels - $self->xPosPixels) / $axmud::CLIENT->gridBlockSize;
        $yPosBlocks = ($yPosPixels - $self->yPosPixels) / $axmud::CLIENT->gridBlockSize;

        # Return the zone at this gridblock
        foreach my $zoneObj ($self->ivValues('zoneHash')) {

            if (
                $xPosBlocks >= $zoneObj->xPosBlocks
                && $xPosBlocks <= ($zoneObj->xPosBlocks + $zoneObj->widthBlocks - 1)
                && $yPosBlocks >= $zoneObj->yPosBlocks
                && $yPosBlocks <= ($zoneObj->yPosBlocks + $zoneObj->heightBlocks - 1)
            ) {
                return $zoneObj;
            }
        }

        # This part of the workspace grid is unoccupied
        return undef;
    }

    sub buildLayerList {

        # Called by GA::Obj::Zone->placeWin() when deciding where in a zone to place a window
        # Compiles a list of layers in the workspace grid, starting with the specified one, then all
        #   layers above it, then all layers below
        # If no layer is specified, the list starts with the default layer
        # e.g. if $self->maxLayers = 16 and $self->defaultLayer = 0 (the default values),
        #   @layerList = (0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)
        # e.g. if $self->maxLayers = 9 and $self->defaultLayer = 4,
        #   @layerList = (4 5 6 7 8 3 2 1 0)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $layer      - Which layer should start the list. If 'undef', $self->defaultLayer is used
        #
        # Return values
        #   Returns an empty list on improper arguments
        #   Otherwise returns the ordered list of layers

        my ($self, $layer, $check) = @_;

        # Local variables
        my (@emptyList, @layerList);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->buildLayerList', @_);
            return @emptyList;
        }

        if (! defined $layer) {

            $layer = $self->defaultLayer;
        }

        # Build the layer list
        if ($layer == 0) {

            # e.g. @layerList = (0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)
            for (my $num = 0; $num < $self->maxLayers; $num++) {

                push (@layerList, $num);
            }

        } elsif ($layer == ($self->maxLayers - 1) ) {

            # e.g. @layerList = (15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0)
            for (my $num = ($self->maxLayers - 1); $num >= 0; $num--) {

                push (@layerList, $num);
            }

        } else {

            # e.g. $layer = 8, @layerList = (8 9 10 11 12 13 14 15 7 6 5 4 3 2 1 0)
            for (my $num = $layer; $num < $self->maxLayers; $num++) {

                push (@layerList, $num);
            }

            for (my $num = ($layer - 1); $num >= 0; $num--) {

                push (@layerList, $num);
            }
        }

        return @layerList;
    }

    sub changeWinzone {

        # Called by GA::Session->setMainWin, and also by GA::Cmd::MoveWindow->do, FixWindow->do
        # Moves a window from one zone into any available space in another zone, the latter being
        #   a zone in this workspace grid
        # If the new zone is the same as the old one, moves the window to the space it would have
        #   occupied, if it were being moved into this zone from a different one
        #
        # Expected arguments
        #   $winObj             - Blessed reference to the window object to be moved (inheriting
        #                           from GA::Generic::GridWin)
        #   $zoneObj            - Blessed reference to the zone object (GA::Obj::Zone) into which
        #                           the window should be moved
        #
        # Optional arguments
        #   $defaultSizeFlag    - If TRUE, the window is resized to fit the zone's default size. If
        #                           FALSE or 'undef', the window keeps its current size (subject to
        #                           small adjustments to fill small gaps)
        #   $fixWidthPixels, $fixHeightPixels
        #                       - Only specified when called by GA::Cmd::FixWindow->do. If the
        #                           user has changed the window's size, these variables specify that
        #                           size. Both must be specified or both must be set to 'undef'
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 otherwise

        my (
            $self, $winObj, $zoneObj, $defaultSizeFlag, $fixWidthPixels, $fixHeightPixels, $check,
        ) = @_;

        # Local variables
        my (
            $blockSize, $widthPixels, $heightPixels, $widthBlocks, $heightBlocks, $xPosBlocks,
            $yPosBlocks, $successFlag, $layer, $oldZoneObj, $xPosPixels, $yPosPixels, $areaObj,
        );

        # Check for improper arguments
        if (
            ! defined $winObj || ! defined $zoneObj || defined $check
            || (defined $fixWidthPixels && ! defined $fixHeightPixels)
            || (! defined $fixWidthPixels && defined $fixHeightPixels)
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->changeWinzone', @_);
        }

        # Check that the window is a 'grid' window
        if (
            $winObj->winCategory ne 'grid'
            || ! $axmud::CLIENT->desktopObj->ivExists('gridWinHash', $winObj->number)
            || ! $winObj->areaObj
            || ! $winObj->areaObj->zoneObj
        ) {
            return $axmud::CLIENT->writeError(
                'Can\'t move the window - window is not a grid window',
                $self->_objClass . '->changeWinzone',
            );
        }

        # Check that the window is allowed in the new zone
        if (
            ! $zoneObj->checkWinAllowed(
                $winObj->winType,
                $winObj->winName,
                $winObj->session,
            )
        ) {
            return $axmud::CLIENT->writeError(
                'Can\'t move the window - window is not allowed in zone #' . $zoneObj->number,
                $self->_objClass . '->changeWinzone',
            );
        }

        # Set the provisional size of the window in its new zone
        # If called by GA::Cmd::FixWindow->do after the user manually changed the window's size,
        #   use that size
        # If the default flag has been set, use the new zone's default size, otherwise use the
        #   window's current size
        $blockSize = $axmud::CLIENT->gridBlockSize;

        if ($fixWidthPixels) {

            $widthPixels = $fixWidthPixels;
            $heightPixels = $fixHeightPixels;

            # When the window object was first created, the call to $self->fineTuneWinSize modified
            #   the size of the window due to window controls. We must reverse those changes (if
            #   they were applied), so that our call to $zoneObj->placeWin() will have the same
            #   initial window size as it would have had, if GA::Obj::Workspace->chooseWinPosn had
            #   been calling it
            if ($winObj->winType ne 'external') {

                $widthPixels += (
                    $winObj->workspaceObj->controlsLeftSize
                    + $winObj->workspaceObj->controlsRightSize
                );

                $heightPixels += (
                    $winObj->workspaceObj->controlsTopSize
                    + $winObj->workspaceObj->controlsBottomSize
                );
            }

        } elsif ($defaultSizeFlag) {

            $widthPixels = $zoneObj->defaultAreaWidth * $blockSize;
            $heightPixels = $zoneObj->defaultAreaHeight * $blockSize;

        } else {

            $widthPixels = $winObj->areaObj->widthBlocks * $blockSize;
            $heightPixels = $winObj->areaObj->heightBlocks * $blockSize;
        }

        # Try to find room for the window in the new zone
        # First define a provisional position for the window at the zone's start corner
        ($widthBlocks, $heightBlocks, $xPosBlocks, $yPosBlocks)
            = $zoneObj->findProvWinPosn($widthPixels, $heightPixels);

        # Try to find room for the window in the new zone. Start at the default layer, then check
        #   other layers
        ($successFlag, $layer, $xPosBlocks, $yPosBlocks) = $zoneObj->placeWin(
            $self->defaultLayer,
            $xPosBlocks,
            $yPosBlocks,
            $widthBlocks,
            $heightBlocks,
            # In case the window already exists in the zone, any space it currently occupies is
            #   available
            $winObj,
        );

        if (!$successFlag) {

            # There is no room for the window in this zone
            return $axmud::CLIENT->writeError(
                'Can\'t move the window - ouldn\'t find room for the \'' . $winObj->winType
                . '\' window anywhere in zone #' . $zoneObj->number,
                $self->_objClass . '->changeWinzone',
            );
        }

        # If the window position on the grid puts it rather close to the edge (or edges) of the
        #   zone, and if the gaps between the window and the zone's edge are empty, adjust the size
        #   of the window to fill the gap (this prevents small areas of the zone from always being
        #   empty: makes the desktop look nice). If the maximum allowable gap size is 0, don't fill
        #   gaps at all
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

        # There is room for the window in the specified zone, at layer $layer and grid coordinates
        #   $xPosBlocks, $yPosBlocks
        $oldZoneObj = $winObj->areaObj->zoneObj;
        if ($oldZoneObj) {

            if ($oldZoneObj ne $zoneObj) {

                $successFlag = $oldZoneObj->removeArea($winObj->areaObj);

            } else {

                # The original and destination zones are the same, but the window's old and new size
                #   and position on the workspace won't necessarily be the same. Don't call
                #   $oldZoneObj->replaceAreaSpace to reshuffle window positions yet, because that
                #   will mess up everything
                $successFlag = $oldZoneObj->removeArea(
                    $winObj->areaObj,
                    TRUE,
                );
            }

            if (! $successFlag) {

                return $axmud::CLIENT->writeError(
                    'Can\'t move the window - attempt to move it from its current zone failed',
                    $self->_objClass . '->changeWinzone',
                );
            }
        }

        # Work out the window object's size and position on the desktop in pixels
        $xPosPixels = $self->xPosPixels + (($zoneObj->xPosBlocks + $xPosBlocks) * $blockSize);
        $yPosPixels = $self->yPosPixels + (($zoneObj->yPosBlocks + $yPosBlocks) * $blockSize);
        $widthPixels = ($widthBlocks * $blockSize);
        $heightPixels = ($heightBlocks * $blockSize);

        # Correct for small gaps in the grid and for window controls
        ($xPosPixels, $yPosPixels, $widthPixels, $heightPixels) = $self->fineTuneWinSize(
            $winObj->winType,
            $xPosPixels,
            $yPosPixels,
            $widthPixels,
            $heightPixels,
        );

        # Mark the window as added to the new zone
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
            $winObj->session,
        );

        if (! $areaObj) {

            return $axmud::CLIENT->writeError(
                'Can\'t move the window - attempt to move it to its new zone failed',
                $self->_objClass . '->changeWinzone',
            );
        }

        # Update the window object's own IVs
        $winObj->set_workspaceGridObj($self);
        $winObj->set_workspaceObj($self->workspaceObj);
        $winObj->set_areaObj($areaObj);

        # If the new zone is different from the old one, update the workspace grid object's IVs too
        if ($oldZoneObj && $oldZoneObj->workspaceGridObj ne $zoneObj->workspaceGridObj) {

            $oldZoneObj->workspaceGridObj->ivDelete('gridWinHash', $winObj->number);
            $zoneObj->workspaceGridObj->add_gridWin($winObj);
        }

        # Resize the window and move it to the correct location
        $self->workspaceObj->moveResizeWin(
            $winObj,
            $xPosPixels,
            $yPosPixels,
            $widthPixels,
            $heightPixels,
        );

        # Reshuffle the positions of all windows in the zone, if necessary, in order to fill smaller
        #   gaps to fill up the zone, or expand larger ones to make room for another window
        # If the global flag isn't set allowing these adjustments, or if the zone has a maximum of
        #   1 window, don't make any adjustments
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

        # Let the calling function display a success message
        return 1;
    }

    ##################
    # Accessors - set

    sub set_currentLayer {

        my ($self, $layer, $check) = @_;

        # Check for improper arguments
        if (! defined $layer || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_currentLayer', @_);
        }

        $self->ivPoke('currentLayer', $layer);

        return 1;
    }

    sub inc_currentLayer {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->inc_currentLayer', @_);
        }

        # Update IVs
        $self->ivIncrement('currentLayer');

        return 1;
    }

    sub dec_currentLayer {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->dec_currentLayer', @_);
        }

        # Update IVs
        $self->ivDecrement('currentLayer');

        return 1;
    }

    sub add_gridWin {

        # Called by GA::Obj::Workspace->createGridWin, ->createSimpleGridWin and
        #   ->enableWorkspaceGrids, as well as $self->changeWinzone

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_gridWin', @_);
        }

        $self->ivAdd('gridWinHash', $winObj->number, $winObj);

        return 1;
    }

    sub del_gridWin {

        # Called by GA::Win::Internal->winDestroy, etc

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_gridWin', @_);
        }

        if (! $self->ivExists('gridWinHash', $obj->number)) {

            return undef;

        } else {

            $self->ivDelete('gridWinHash', $obj->number);
            # Also remove the area object from its zone
            if ($obj->areaObj && $obj->areaObj->zoneObj) {

                $obj->areaObj->zoneObj->removeArea($obj->areaObj);
            }

            return 1;
        }
    }

    sub reset_gridWinHash {

        # Called by GA::Obj::Workspace->disableWorkspaceGrids

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_gridWinHash', @_);
        }

        $self->ivEmpty('gridWinHash');

        return undef;
    }

    ##################
    # Accessors - get

    sub number
        { $_[0]->{number} }
    sub workspaceObj
        { $_[0]->{workspaceObj} }
    sub owner
        { $_[0]->{owner} }

    sub zonemap
        { $_[0]->{zonemap} }

    sub maxLayers
        { $_[0]->{maxLayers} }
    sub defaultLayer
        { $_[0]->{defaultLayer} }
    sub currentLayer
        { $_[0]->{currentLayer} }

    sub widthBlocks
        { $_[0]->{widthBlocks} }
    sub heightBlocks
        { $_[0]->{heightBlocks} }
    sub xPosPixels
        { $_[0]->{xPosPixels} }
    sub yPosPixels
        { $_[0]->{yPosPixels} }

    sub zoneHash
        { my $self = shift; return %{$self->{zoneHash}}; }
    sub zoneCount
        { $_[0]->{zoneCount} }
    sub zonemapXCoordHash
        { my $self = shift; return %{$self->{zonemapXCoordHash}}; }
    sub zonemapYCoordHash
        { my $self = shift; return %{$self->{zonemapYCoordHash}}; }

    sub gridWinHash
        { my $self = shift; return %{$self->{gridWinHash}}; }
}

# Package must return a true value
1
