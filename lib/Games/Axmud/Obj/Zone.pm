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
# Games::Axmud::Obj::Zone
# Handles a single zone within a zonemap

{ package Games::Axmud::Obj::Zone;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::WorkspaceGrid->resetZones
        # Create a new instance of the zone object, which regulates a single area of the workspace
        #   grid in which windows are arranged
        # (Having created the object and set its size and position instance variables, don't forget
        #   to call $self->resetInternalGrid to set up the zone's internal grid)
        #
        # Expected arguments
        #   $number             - A unique number for the zone within the parent workspace grid
        #                           object
        #   $workspaceGridObj   - The parent GA::Obj::WorkspaceGrid object
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $workspaceGridObj, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $workspaceGridObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'zone',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # The zone's number on the workspace grid (matches GA::Obj::WorkspaceGrid->zoneCount)
            #   - set later on
            number                      => $number,
            # The parent GA::Obj::WorkspaceGrid object
            workspaceGridObj            => $workspaceGridObj,

            # The zone's coordinates on the workspace grid
            xPosBlocks                  => undef,
            yPosBlocks                  => undef,
            # The zone's width and height
            widthBlocks                 => undef,
            heightBlocks                => undef,

            # If this flag is TRUE, the zone is reserved for certain window types
            reservedFlag                => FALSE,
            # For reserved zones, a hash of window types allowed to use it. Hash in the form
            #   $reservedHash{window_name} = window_type
            # ...where 'window_type' is one of the window types specified by
            #   GA::Client->constGridWinTypeHash, and 'window_name' is either the same as the
            #   window type, or something different that further limits the type of window allowed
            #   to use it:
            #       window_type     window_name
            #       -----------     -----------
            #       main            main
            #       map             map
            #       protocol        Any string chosen by the protocol code (default value is
            #                           'protocol')
            #       fixed           Any string chosen by the controlling code (default value is
            #                           'fixed')
            #       custom          Any string chosen by the controlling code. For task windows,
            #                           the name of the task (e.g. 'status_task', for other windows,
            #                           default value is 'custom'
            #       external        The 'external' window's name (e.g. 'Notepad')
            reservedHash                => {},
            # For reserved zones, it's often preferable to use only a single layer. When this flag
            #   is set to TRUE, only a single layer is used by the zone (the default one specified
            #   by GA::Obj::WorkspaceGrid->defaultLayer)
            multipleLayerFlag           => TRUE,

            # When GA::Client->shareMainWinFlag = FALSE, meaning every session has its own 'main'
            #   window, we probably want to prevent multiple sessions from sharing the same zone
            # If this IV is defined, this zone is reserved for a single session. The IV's value can
            #   be any non-empty string. All zones with the same ->ownerString are reserved for a
            #   particular session
            # The first session to place one of its windows into any 'owned' zone claims all of
            #   those zones for itself. If this IV is 'undef', the zone is available for any session
            #   to use (subject to the restrictions above)
            # NB Even if ->ownerString is set, it is ignored when GA::Client->shareMainWinFlag
            #   = TRUE (meaning all sessions share a single 'main' window). This default behaviour
            #   guards against the user selecting a zonemap such as 'horizontal', which is designed
            #   for GA::Client->shareMainWinFlag = FALSE
            ownerString                 => undef,
            # Once this zone has been 'claimed', the GA::Session that claimed it
            owner                       => undef,

            # The zone's internal grid in 3 dimensions. The internal grid is a sub-section of the
            #   parent workspace grid, using the same grid blocks, but the internal grid has its own
            #   coordinate system
            # Layers are numbered from 0 to (GA::Obj::WorkspaceGrid->maxLayers - 1)
            # The x axis is numbered from 0 to ($self->widthBlocks - 1)
            # The y axis is numbered from 0 to ($self->heightBlocks - 1)
            # Rather than using a 3D array, we use calls to $self->checkPosnInLayer to check that a
            #   region of the zone is not occupied by an area object (GA::Obj::Area), with each
            #   area object handling a single window in the zone. Each area object stores details
            #   about the portion of the internal grid used by its window
            # Hash in the form
            #   $areaHash{number} = blessed_reference_to_area_object
            areaHash                    => {},
            # Number of area objects created for this internal grid since the last reset (used to
            #   give every area object a number unique to the internal grid)
            areaCount                   => 0,
            # Sometimes it's useful to set the total maximum number of areas allowed in the zone
            #   (especially for zones reserved for certain types of windows). If set to 0, there is
            #   no maximum
            areaMax                     => 0,
            # It's very often useful to set the maximum number of areas allowed in one layer of
            #   the zone, because this helps to fill a zone with windows easily. Unlike ->areaMax
            #   which is an absolute maximum, if any layer is full then new windows are just moved
            #   to another layer
            visibleAreaMax              => 0,

            # In which corner the zone should start placing windows ('top_left', 'top_right',
            #   'bottom_left', 'bottom_right');
            startCorner                 => 'top_left',
            # In which direction the zone should place windows first ('horizontal' move horizontally
            #   after the first window, if possible, 'vertical' move vertically after the first
            #   window, if possible)
            orientation                 => 'vertical',
            # The default winmap names to use in this zone with 'main' windows and other 'internal'
            #   windows. If not specified, use corresponding IVs in GA::Client
            defaultEnabledWinmap        => undef,
            defaultDisabledWinmap       => undef,
            defaultInternalWinmap       => undef,

            # The sizes of windows within a zone normally depend on $self->areaMax; i.e. if
            #   ->areaMax is set to 2, each area takes up half the zone.
            # If ->areaMax is set to 0 (meaning unlimited areas), the default area size is set
            #   by the following two IVs. They show the default size of an area in terms of the
            #   zone's internal grid
            # If either or both of these IVs are set to 0, then the one or both of the default
            #   area sizes GA::Client->customGridWinWidth and ->customGridWinWidth (both
            #   measured in pixels) is used to set them, instead
            defaultAreaWidth            => 0,
            defaultAreaHeight           => 0,
            # ->adjustMultipleWin can adjust the size of all the areas in a zone, in order to make
            #   a bigger gap (large enough to fit another area) or to close a smaller gap (too
            #   small to fit another area). If such an adjustment has been done, this flag is set
            #   to TRUE; it is set back to FALSE if areas are deleted, and there's enough space
            #   for an area of the default size (defined by $self->widthAdjustBlocks and
            #   ->heightAdjustBlocks)
            areaAdjustFlag              => FALSE,
            # The size of the adjustment is set by these variables. A positive number means the
            #   default size has increased (e.g. +1 means 1 gridblock), a negative number means the
            #   default size has decreased. If both are set to 0, $self->areaAdjustFlag is also set
            #   back to FALSE
            widthAdjustBlocks           => 0,
            heightAdjustBlocks          => 0,
        };

        # Bless the zone layout into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    sub resetInternalGrid {

        # Resets the zone
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetInternalGrid', @_);
        }

        # Reset IVs
        $self->ivEmpty('areaHash');
        $self->ivPoke('areaCount', 0);

        return 1;
    }

    sub getInternalGridPosn {

        # Called by GA::Client->createGridWin, $self->findProvWinPosn or by any other function
        # Finds the coordinates on the workspace, in pixels, of a position of a gridblock in this
        #   zone's internal grid
        #
        # Expected arguments
        #   $xPosBlocks, $yPosBlocks
        #       - The coordinates of one gridblock in the zone's internal grid
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns the coordinates in a list in the form
        #       ($xPosPixels, $yPosPixels)

        my ($self, $xPosBlocks, $yPosBlocks, $check) = @_;

        # Local variables
        my (
            $xPosPixels, $yPosPixels,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $xPosBlocks || ! defined $yPosBlocks || defined $check) {

            $axmud::CLIENT->writeImproper(
                $self->_objClass . '->getInternalGridPosn',
                @_,
            );

            return @emptyList;
        }

        # Find the coordinates of the specified gridblock
        $xPosPixels = $self->workspaceGridObj->xPosPixels
                        + (($self->xPosBlocks + $xPosBlocks) * $axmud::CLIENT->gridBlockSize);
        $yPosPixels = $self->workspaceGridObj->yPosPixels
                        + (($self->yPosBlocks + $yPosBlocks) * $axmud::CLIENT->gridBlockSize);

        return ($xPosPixels, $yPosPixels);
    }

    sub checkWinAllowed {

        # Called by GA::Obj::Desktop->swapGridWin, GA::Obj::Workspace->createGridWin and
        #   ->chooseZone, GA::Obj::WorkspaceGrid->changeWinZone
        # Checks whether a window of a certain type is allowed in this zone. (Some zones allow
        #   any kind of window; others are reserved for certain window types)
        #
        # Expected arguments
        #   $winType, $winName
        #               - The window type and name to check, matching the keys and corresponding
        #                   values in $self->reservedHash:
        #
        #       $winType        $winName
        #       --------        --------
        #       main            main
        #       map             map
        #       protocol        Any string chosen by the protocol code, e.g. for MXP (default value
        #                           is 'protocol')
        #       fixed           Any string chosen by the controlling code (default value is
        #                           'fixed')
        #       custom          Any string chosen by the controlling code. For task windows,
        #                           the name of the task (e.g. 'status_task', for other windows,
        #                           default value is 'custom'
        #       external        The external window's name (e.g. 'Notepad')
        #
        # Optional arguments
        #   $session    - The GA::Session which controls this window, if any
        #
        # Return values
        #   'undef' on improper arguments or if the window isn't allowed in this zone
        #   1 if it is allowed

        my ($self, $winType, $winName, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $winType || ! defined $winName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkWinAllowed', @_);
        }

        # Check invalid window type ('grid' windows allowed, but 'free' windows are not)
        if (! $axmud::CLIENT->ivExists('constGridWinTypeHash', $winType)) {

            # Not allowed
            return undef;
        }

        # Check the zone owner, if it's set
        if (
            # (Zone owners ignored in GA::Client->shareMainWinFlag = TRUE)
            ! $axmud::CLIENT->shareMainWinFlag
            && $self->owner
            && (! $session || $self->owner ne $session)
        ) {
            # This zone is claimed by a different session
            return undef;
        }

        # If this zone is reserved for certain windows...
        if ($self->reservedFlag) {

            # Check reserved zones
            if (
                ! $self->ivExists('reservedHash', $winName)
                || $self->ivShow('reservedHash', $winName) ne $winType
            ) {
                # Not allowed
                return undef;
            }
        }

        # Window is allowed in this zone
        return 1;
    }

    sub findProvWinPosn {

        # Called by GA::Obj::Workspace->chooseWinPosn and GA::Obj::WorkspaceGrid->changeWinzone
        # Before we decide where exactly in the zone to put a window, we give it a provisional
        #   position in one of the zone's corners (by default the top-left corner). If that area of
        #   the zone happens to be free, the window can be put there; otherwise
        #   GA::Obj::Workspace->createGridWin can move it to some other part of the zone
        # However, if both $xPosPixels and $yPosPixels have been set, we use these values as the
        #   provisional position instead
        # If the specified window width and height, $widthPixels and $yPixels, doesn't fit exactly
        #   into a gridblock, the whole of the gridblock is used (so the window's specified size
        #   will increase slightly)
        #
        # Expected arguments
        #   $widthPixels, $heightPixels
        #       - The size of the window in pixels (must not be undef)
        #
        # Optional arguments
        #   $xPosPixels, $yPosPixels
        #       - The windows coordinates on the workspace, if they have already been specified (one
        #           or both of these values can be 'undef')
        #
        # Return values
        #   An empty list on improper arguments, or if the specified coordinates are not in this
        #       zone
        #   Otherwise, returns a list in the format
        #       ($widthBlocks, $heightBlocks, $xPosBlocks, $yPosBlocks)
        #   ...showing the provisional position of the window new position of the window on the
        #       zone's internal grid

        my ($self, $widthPixels, $heightPixels, $xPosPixels, $yPosPixels, $check) = @_;

        # Local variables
        my (
            $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $internalGridXPosPixels,
            $internalGridYPosPixels, $blockSize,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $widthPixels || ! defined $heightPixels || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findProvWinPosn', @_);
            return @emptyList;
        }

        # Get the position of the internal grid on the workspace (actually, the position of the
        #   top-left gridblock)
        ($internalGridXPosPixels, $internalGridYPosPixels) = $self->getInternalGridPosn(0, 0);

        # Set the window's size, in gridblocks; round up decimal values so that the whole of a
        #   partially-filled gridblock is used
        $blockSize = $axmud::CLIENT->gridBlockSize;
        $widthBlocks = sprintf ("%.0f", ($widthPixels / $blockSize));
        $heightBlocks = sprintf ("%.0f", ($heightPixels / $blockSize));
        # In case there were partially filled gridblocks, re-set the window's size in pixels
        $widthPixels = $widthBlocks * $blockSize;
        $heightPixels = $heightBlocks * $blockSize;
        # If the window is too big for the zone, reduce its size; also ignore the specified
        #   coordinates so that the window is provisionally placed in the default corner
        if ($widthBlocks > $self->widthBlocks) {

            $widthBlocks = $self->widthBlocks;
            $xPosPixels = undef;
            $yPosPixels = undef;
        }

        if ($heightBlocks > $self->heightBlocks) {

            $heightBlocks = $self->heightBlocks;
            $xPosPixels = undef;
            $yPosPixels = undef;
        }

        # If the window's position hasn't been specified (or is no longer specified), set values for
        #   the coordinates of the window, on the zone's internal grid, at its provisional position
        if (! defined $xPosPixels || ! defined $yPosPixels) {

            if ($self->startCorner eq 'top_left') {

                $xPosBlocks = 0;
                $yPosBlocks = 0;

            } elsif ($self->startCorner eq 'top_right') {

                $xPosBlocks = ($self->widthBlocks - $widthBlocks);
                $yPosBlocks = 0;

            } elsif ($self->startCorner eq 'bottom_left') {

                $xPosBlocks = 0;
                $yPosBlocks = ($self->heightBlocks - $heightBlocks);

            } elsif ($self->startCorner eq 'bottom_right') {

                $xPosBlocks = ($self->widthBlocks - $widthBlocks);
                $yPosBlocks = ($self->heightBlocks - $heightBlocks);
            }

        # If the window's position was specified, set values for the coordinates of the window on
        #   the zone's internal grid, as close as possible to the specified position (i.e. move it
        #   slightly up or slightly left if necessary so there are no partially-filled gridblocks)
        } else {

            $xPosBlocks = int(
                ($xPosPixels - $internalGridXPosPixels) / $blockSize
            );
            $yPosBlocks = int(
                ($yPosPixels - $internalGridYPosPixels) / $blockSize
            );
        }

        return ($widthBlocks, $heightBlocks, $xPosBlocks, $yPosBlocks);
    }

    sub placeWin {

        # Called by GA::Obj::Workspace->chooseWinPosn, GA::Obj::WorkspaceGrid->changeWinzone and
        #   $self->replaceAreaSpace
        # Places a window inside this zone at a position unoccupied by other windows
        # A provisional position inside the zone (often at one of the corners), as well as the
        #   window's size, are passed to this function as arguments
        # If that position is already occupied by another window, this function tries to find room
        #   for it somewhere else in the zone (maybe in a different layer)
        #
        # Expected arguments
        #   $layer
        #       - Which layer within the zone to check first (matches a number between 0 and
        #           (GA::Obj::WorkspaceGrid->maxLayers - 1) )
        #   $xPosBlocks, $yPosBlocks
        #       - The window's proposed x/y coordinates on the zone's internal grid (in gridblocks)
        #   $widthBlocks, $heightBlocks
        #       - The window's proposed width and height (in gridblocks)
        #
        # Optional arguments
        #   $winObj
        #       - Specified by GA::Obj::WorkspaceGrid->changeWinzone, when it wants to place a
        #           window in the same zone it currently occupies. $winObj is something that
        #           inherits from GA::Generic::Win. If defined, regard any space currently occupied
        #           by this window as available
        #
        # Return values
        #   An empty list on improper arguments, or if the window won't fit anywhere inside the zone
        #   Otherwise returns a list in the form
        #       (1, $layer, $xPosBlocks, $yPosBlocks)
        #   ...The '1' represents success; the next three variables are the layer and position in
        #       the zone's internal grid at which the window will fit without overlapping other
        #       windows

        my (
            $self, $layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $winObj, $check,
        ) = @_;

        # Local variables
        my (
            $successFlag,
            @layerList, @emptyList,
        );

        # Check for improper arguments
        if (
            ! defined $layer || ! defined $xPosBlocks || ! defined $yPosBlocks
            || ! defined $widthBlocks || ! defined $heightBlocks || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->placeWin', @_);
            return @emptyList,
        }

        # Get a list of layers, starting with the specified one, then all layers below it, then all
        #   layers above it
        @layerList = $self->workspaceGridObj->buildLayerList($layer);

        # Now consider moving the window within the zone's grid. First see if the window will fit
        #   inside this zone's internal grid at the specified position and layer, without
        #   overlapping other windows on the same layer
        $successFlag = $self->checkPosnInLayer(
            $layer,
            $xPosBlocks,
            $yPosBlocks,
            $widthBlocks,
            $heightBlocks,
            $winObj,
        );

        # If the window overlaps an existing window, see if it will fit in another position inside
        #   the grid, at any layer (check the specified layer first, then every layer in @layerList
        #   in turn)
        if (! $successFlag) {

            OUTER: foreach my $successiveLayer (@layerList) {

                ($successFlag, $xPosBlocks, $yPosBlocks) = $self->findSpaceInLayer(
                    $successiveLayer,
                    $widthBlocks,
                    $heightBlocks,
                    $winObj,
                );

                if ($successFlag) {

                    # Use this layer, and don't do any more searching
                    $layer = $successiveLayer;
                    last OUTER;
                }
            }
        }

        # If there's no room anywhere in the zone, on any layer, display a warning message and let
        #   the user decide what to do
        if (! $successFlag) {

            return @emptyList;

        # Otherwise return the layer and position within the zone's internal grid at which the
        #   window will fit, without overlapping other windows
        } else {

            return (1, $layer, $xPosBlocks, $yPosBlocks);
        }
    }

    sub checkPosnInLayer {

        # Called by $self->placeWin and $self->findSpaceInLayer to see if a window will fit in this
        #   zone, at the specified layer and position, without overlapping other windows in the same
        #   layer
        # (Also called by $self->adjustSingleWin to check whether a small area near the edge of a
        #   zone - for the purposes of this function, the area is a proposed window - to see whether
        #   it's unoccupied)
        #
        # Expected arguments
        #   $layer
        #       - Which layer within the zone to check first (matches a number between 0 and
        #           (GA::Obj::WorkspaceGrid->maxLayers - 1) )
        #   $xPosBlocks, $yPosBlocks
        #       - The window's proposed x/y coordinates on the zone's internal grid (in gridblocks)
        #   $widthBlocks, $heightBlocks
        #       - The window's proposed width and height (in gridblocks)
        #
        # Optional arguments
        #   $winObj
        #       - Specified by GA::Obj::WorkspaceGrid->changeWinzone, when it wants to place a
        #           window in the same zone it currently occupies. $winObj is something that
        #           inherits from GA::Generic::Win. If defined, regard any space currently occupied
        #           by this window as available
        #
        # Return values
        #   'undef' if the window doesn't fit at the specified position in the grid without
        #       overlapping other windows on the same layer
        #   1 if it does

        my (
            $self, $layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $winObj, $check,
        ) = @_;

        # Local variables
        my ($x1, $x2, $y1, $y2);

        # Check for improper arguments
        if (
            ! defined $layer || ! defined $xPosBlocks || ! defined $yPosBlocks
            || ! defined $widthBlocks || ! defined $heightBlocks || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkPosnInLayer', @_);
        }

        $x1 = $xPosBlocks,
        $x2 = $x1 + $widthBlocks - 1;
        $y1 = $yPosBlocks,
        $y2 = $y1 + $heightBlocks - 1;

        foreach my $areaObj ($self->ivValues('areaHash')) {

            if (
                (! $winObj || $winObj ne $areaObj->winObj)
                && $areaObj->layer == $layer
                && (
                    (
                        ($x1 >= $areaObj->leftBlocks && $x1 <= $areaObj->rightBlocks)
                        || ($x2 >= $areaObj->leftBlocks && $x2 <= $areaObj->rightBlocks)
                    ) && (
                        ($y1 >= $areaObj->topBlocks && $y1 <= $areaObj->bottomBlocks)
                        || ($y2 >= $areaObj->topBlocks && $y2 <= $areaObj->bottomBlocks)
                    )
                )
            ) {
                return undef;
            }
        }

        # The window fits at the specified layer and position
        return 1;
    }

    sub findSpaceInLayer {

        # Called by $self->placeWin
        # Check to see if a window will fit in this zone, at the specified layer and in any
        #   position, without overlapping other windows in the same layer
        # When the first suitable position is found, return the window's coordinates in the zone's
        #   internal grid
        #
        # Expected arguments
        #   $layer
        #       - Which layer within the zone to check first (matches a number between 0 and
        #           (GA::Obj::WorkspaceGrid->maxLayers - 1) )
        #   $widthBlocks, $heightBlocks
        #       - The window's proposed width and height (in gridblocks)
        #
        # Optional arguments
        #   $winObj
        #       - Specified by GA::Obj::WorkspaceGrid->changeWinzone, when it wants to place a
        #           window in the same zone it currently occupies. $winObj is something that
        #           inherits from GA::Generic::Win. If defined, regard any space currently occupied
        #           by this window as available
        #
        # Return values
        #   An empty list on improper arguments or if the window doesn't fit at any position in the
        #       grid without overlapping other windows on the same layer
        #   Otherwise returns a list in the form
        #       (1, $posX, $posY)
        #   ...The '1' represents success; the next two variables are the window's coordinates at a
        #       position in the zone's internal grid at the specified layer, at which the window
        #       will fit without overlapping other windows

        my ($self, $layer, $widthBlocks, $heightBlocks, $winObj, $check) = @_;

        # Local variables
        my (
            $startX, $startY, $step, $numX, $numY,
            @emptyList,
        );

        # Check for improper arguments
        if (
            ! defined $layer || ! defined $widthBlocks || ! defined $heightBlocks || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->findSpaceInLayer', @_);
            return @emptyList;
        }

        # Set the search parameters. The coordinates of the top-left gridblock are (0,0)
        # $step represents the direction of the search; 1 for left-to-right or top-to-bottom; -1 for
        #   right-to-left or bottom-to-top. The direction depends on $self->orientation which can be
        #   'horizontal' (move left or right, before moving up and down) or 'vertical' (move up and
        #   down, before moving left and right)
        if ($self->startCorner eq 'top_left') {

            # Gridblock at which the top-left corner of a window will be, when it is in the top-left
            #   corner of the search area
            $startX = 0;
            $startY = 0;
            $step = 1;

        } elsif ($self->startCorner eq 'top_right') {

            # Gridblock at which the top-left corner of a window will be, when it is in the
            #   top-right corner of the search area
            $startX = $self->widthBlocks - $widthBlocks;
            $startY = 0;

            if ($self->orientation eq 'horizontal') {
                $step = -1;
            } else {
                $step = 1;
            }

        } elsif ($self->startCorner eq 'bottom_left') {

            # Gridblock at which the top-left corner of a window will be, when it is in the
            #   bottom-left corner of the search area
            $startX = 0;
            $startY = $self->heightBlocks - $heightBlocks;
            if ($self->orientation eq 'horizontal') {
                $step = 1;
            } else {
                $step = -1;
            }

        } elsif ($self->startCorner eq 'bottom_right') {

            # Gridblock at which the top-left corner of the first window is, when it is in the
            #   bottom-right corner of the search area
            $startX = $self->widthBlocks - $widthBlocks;
            $startY = $self->heightBlocks - $heightBlocks;
            $step = -1;
        }

        # Set more search parameters - the number of possible positions of a window, of size
        #   $widthBlocks and $heightBlocks, in this zone's internal grid
        $numX = ($self->widthBlocks - $widthBlocks + 1);
        $numY = ($self->heightBlocks - $heightBlocks + 1);

        # Conduct the search
        for (my $posX = $startX; $posX < ($startX + $numX); $posX  += $step) {

            for (my $posY = $startY; $posY < ($startY + $numY); $posY += $step) {

                # Check that every gridblock in the area starting at grid coordinates $posX/$posY
                #   region is free
                if (
                    $self->checkPosnInLayer(
                        $layer,
                        $posX,
                        $posY,
                        $widthBlocks,
                        $heightBlocks,
                        $winObj,
                    )
                ) {
                    # The entire area is free, so a window can be placed at this position, at the
                    #   specified layer, without overlapping other windows
                    return (1, $posX, $posY);
                }
            }
        }

        # There isn't space for this window anywhere in this zone at the specified layer
        return @emptyList;
    }

    sub adjustSingleWin {

        # Called by GA::Obj::Workspace->chooseWinPosn
        # If the window's proposed position on a zone's internal grid puts it rather close to the
        #   edge (or edges) of the zone, and if the gaps between the proposed window and the zone's
        #   edge(s) are unoccupied, adjust the size of the window to fill the gap (this prevents
        #   small regions of the zone from always being empty and makes the desktop look nice)
        #
        # Expected arguments
        #   $layer  - Which layer within the zone to check first (matches a number between 0 and
        #               (GA::Obj::WorkspaceGrid->maxLayers - 1) )
        #   $winXPosBlocks, $winYPosBlocks
        #           - The window's proposed x/y coordinates on the zone's internal grid (in
        #               gridblocks)
        #   $winWidthBlocks, $winHeightBlocks
        #           - The window's proposed width and height (in gridblocks)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns the list
        #       ($winXPosBlocks, $winYPosBlocks, $winWidthBlocks, $winHeightBlocks)
        #   ...some of which may have been adjusted by this function

        my (
            $self, $layer, $winXPosBlocks, $winYPosBlocks, $winWidthBlocks, $winHeightBlocks,
            $check,
        ) = @_;

        # Local variables
        my (
            $gapSize, $maxGapSize, $regionXPosBlocks, $regionYPosBlocks, $regionWidthBlocks,
            $regionHeightBlocks,
            @emptyList,
        );

        # Check for improper arguments
        if (
            ! defined $layer || ! defined $winXPosBlocks || ! defined $winYPosBlocks
            || ! defined $winWidthBlocks || ! defined $winHeightBlocks || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->adjustSingleWin', @_);
            return @emptyList;
        }

        # If this zone has a maximum number of visible windows, the biggest gap this function will
        #   close is that number minus 1 (bigger gaps shouldn't occur in zones with a maximum number
        #   of visible windows)
        # Otherwise, the biggest gap is the one defined by the global variable
        if ($self->visibleAreaMax) {

            $maxGapSize = ($self->visibleAreaMax - 1);
            # If this value is 0 (because only one window is allowed), don't need to check for gaps.
            #   Return the unadjusted size of the window
            if (! $maxGapSize) {

                return (
                    $winXPosBlocks, $winYPosBlocks, $winWidthBlocks, $winHeightBlocks,
                );
            }

        } else {

            # Use the default value
            $maxGapSize = $axmud::CLIENT->gridGapMaxSize;
        }

        # Search the region to the left of the window
        $gapSize = $winXPosBlocks;
        if ( $gapSize && $gapSize <= $maxGapSize) {

            # Set the search region, immediately to the left of the window
            $regionXPosBlocks = 0;
            $regionYPosBlocks = $winYPosBlocks;
            $regionWidthBlocks = $gapSize;
            $regionHeightBlocks = $winHeightBlocks;

            if (
                $self->checkPosnInLayer(
                    $layer,
                    $regionXPosBlocks,
                    $regionYPosBlocks,
                    $regionWidthBlocks,
                    $regionHeightBlocks,
                )
            ) {
                # The gap is unoccupied; increase the width of the window
                $winWidthBlocks += $gapSize;
                $winXPosBlocks -= $gapSize;
            }
        }

        # Search the region to the right of the window
        $gapSize = $self->widthBlocks - ($winXPosBlocks + $winWidthBlocks);
        if ( $gapSize && $gapSize <= $maxGapSize) {

            # Set the search region, immediately to the right of the window
            $regionXPosBlocks = $winXPosBlocks + $winWidthBlocks;
            $regionYPosBlocks = $winYPosBlocks;
            $regionWidthBlocks = $gapSize;
            $regionHeightBlocks = $winHeightBlocks;

            if (
                $self->checkPosnInLayer(
                    $layer,
                    $regionXPosBlocks,
                    $regionYPosBlocks,
                    $regionWidthBlocks,
                    $regionHeightBlocks,
                )
            ) {
                # The gap is unoccupied; increase the width of the window (don't need to change the
                #   coordinates of the top-left corner)
                $winWidthBlocks += $gapSize;
            }
        }

        # Search the region immediately above the window
        $gapSize = $winYPosBlocks;
        if ( $gapSize && $gapSize <= $maxGapSize) {

            # Set the search region, immediately above the window
            $regionXPosBlocks = $winXPosBlocks;
            $regionYPosBlocks = 0;
            $regionWidthBlocks = $winWidthBlocks;
            $regionHeightBlocks = $gapSize;

            if (
                $self->checkPosnInLayer(
                    $layer,
                    $regionXPosBlocks,
                    $regionYPosBlocks,
                    $regionWidthBlocks,
                    $regionHeightBlocks,
                )
            ) {
                # The gap is unoccupied; increase the height of the window
                $winHeightBlocks += $gapSize;
                $winYPosBlocks -= $gapSize;
            }
        }

        # Search the region immediately below the window
        $gapSize = $self->heightBlocks - ($winYPosBlocks + $winHeightBlocks);
        if ( $gapSize && $gapSize <= $maxGapSize) {

            # Set the search region, immediately below the window
            $regionXPosBlocks = $winXPosBlocks;
            $regionYPosBlocks =  $winYPosBlocks + $winHeightBlocks;
            $regionWidthBlocks = $winWidthBlocks;
            $regionHeightBlocks = $gapSize;

            if (
                $self->checkPosnInLayer(
                    $layer,
                    $regionXPosBlocks,
                    $regionYPosBlocks,
                    $regionWidthBlocks,
                    $regionHeightBlocks,
                )
            ) {
                # The gap is unoccupied; increase the height of the window (don't need to change the
                #   coordinates of the top-left corner)
                $winHeightBlocks += $gapSize;
            }
        }

        # Return the window position and size (some of the values may have been adjusted, or they
        #   may be the same)
        return ($winXPosBlocks, $winYPosBlocks, $winWidthBlocks, $winHeightBlocks);
    }

    sub adjustMultipleWin {

        # Called by GA::Client->createGridWin and GA::Obj::WorkspaceGrid->changeWinzone
        # After a new window is created in this zone, if the zone is wide enough (and its
        #   orientation is 'horizontal') or high enough (and its orientation is 'vertical') for only
        #   one window of the zone's default size, then consider expanding all of the windows in the
        #   zone to fill gaps that are bigger than a gridblock or two, but still not big enough to
        #   hold another window
        # If it would be better to reduce all the window sizes in order to make room for another
        #   window, some time in the future, do that instead. Leave enough room for a window of the
        #   default size
        # If an adjustment is made, record the size of the adjustment in
        #   $self->widthAdjustBlocks and $self->heightAdjustBlocks, and set the flag
        #   $self->areaAdjustFlag to TRUE
        # If the adjustment causes windows to return the zone's default size, these three variables
        #   are all reset
        # This function takes account of the direction in which the workspace is being filled (left
        #   to right, right to left, top to bottom, bottom to top)
        #
        # Expected arguments
        #   $layer  - Which layer within the zone to check first (matches a number between 0 and
        #               (GA::Obj::WorkspaceGrid->maxLayers - 1) )
        #
        # Return values
        #   'undef' on improper arguments, or if no adjustment is made
        #   1 if an adjustment is made

        my ($self, $layer, $check) = @_;

        # Local variables
        my (
            $gapSize, $width, $height, $gapCount, $adjustmentCount,
            $largestAdjustment, $startBlock, $dir, $blockSize,
            @areaList,
            %adjustHash,
        );

        # Check for improper arguments
        if (! defined $layer || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->adjustMultipleWin', @_);
        }

        # Compile a list of areas in this zone, sorted in order of their proximity to the starting
        #   corner
        @areaList = $self->getSortedAreaList($layer);
        if (! @areaList) {

            # No adjustments to make
            return undef;
        }

        # Work out the total width or height (in gridblocks) of all these areas if they were to be
        #   put together in a line (which they probably already are)
        $width = 0;
        $height = 0;
        if ($self->orientation eq 'horizontal') {

            foreach my $areaObj (@areaList) {

                $width += $areaObj->widthBlocks;
            }

        } elsif ($self->orientation eq 'vertical') {

            foreach my $areaObj (@areaList) {

                $height += $areaObj->heightBlocks;
            }
        }

        # Now work out the size of the gap between the end of the line and the total length of the
        #   zone
        if ($self->orientation eq 'horizontal') {
            $gapSize = ($self->widthBlocks - $width);
        } elsif ($self->orientation eq 'vertical') {
            $gapSize = ($self->heightBlocks - $height);
        }

        # If there's no gap, then make no adjustments
        if (! $gapSize) {

            return undef;

        # If the gap is big enough for a standard-sized window, make no adjustments - the gap
        #   doesn't need to be filled
        } elsif (
            ($width && $gapSize >= $self->defaultAreaWidth)
            || ($height && $gapSize >= $self->defaultAreaHeight)
        ) {
            return undef;
        }

        # Otherwise, divide up the gap as equally as possible between the windows

        # Copy @areaList into a hash to remember its adjusted width or height (e.g. a value of +1
        #   means the width or height has increased by 1 gridblock, a value of -1 means the width
        #   or height has decreased, and a value of 0 means the width or height is the same)
        #   $adjustHash{area_number} = change_in_size
        foreach my $areaObj (@areaList) {

            $adjustHash{$areaObj->number} = 0;
        }

        # If the gap is less than half a size of a default-sized window, try to fill the gap by
        #   making the other area bigger
        if (
            ($width && $gapSize < (($self->defaultAreaWidth) / 2))
            || ($height && $gapSize < (($self->defaultAreaHeight) / 2))
        ) {
            # Start with the area furthest from the start corner...
            @areaList = reverse @areaList;
            # ...and increase its height (or width) by one gridblock. When each area has been
            #   reduced, repeat the cycle until the gap has closed
            $gapCount = 0;
            $largestAdjustment = 0;

            OUTER: while (1) {

                INNER: foreach my $areaObj (@areaList) {

                    $gapCount++;
                    $adjustHash{$areaObj->number}++;

                    if ($largestAdjustment < $adjustHash{$areaObj->number}) {

                        $largestAdjustment = $adjustHash{$areaObj->number};
                    }

                    if ($gapCount == $gapSize) {

                        last OUTER;
                    }
                }
            }

            # Un-reverse the list of areas, so that they're moved in an aesthetically pleasing
            #   order
            @areaList = reverse @areaList;

        # If the gap is more than half a size of a default-sized window, try to increase the gap by
        #   making the other areas smaller
        } else {

            # Start with the area furthest from the start corner...
            @areaList = reverse @areaList;
            # ...and decrease its height (or width) by one gridblock. When each area has been
            #   reduced, repeat the cycle until the gap has expanded far enough to accommodate an
            #   area
            $adjustmentCount = 0;
            $largestAdjustment = 0;

            OUTER: while (1) {

                $adjustmentCount++;
                INNER: foreach my $areaObj (@areaList) {

                    $gapSize++;
                    $adjustHash{$areaObj->number}--;

                    if ($largestAdjustment > $adjustHash{$areaObj->number}) {

                        $largestAdjustment = $adjustHash{$areaObj->number};
                    }

                    # When all the areas are almost the same size as the expanded gap (e.g. area
                    #   widths 26, 26, 25; gap width 25), stop adjusting
                    if (
                        (
                            $self->orientation eq 'horizontal'
                            && $gapSize >= ($self->defaultAreaWidth + $largestAdjustment)
                        ) || (
                            $self->orientation eq 'vertical'
                            && $gapSize >= ($self->defaultAreaHeight + $largestAdjustment)
                        )
                    ) {
                        last OUTER;
                    }
                }
            }

            # Un-reverse the list of areas, so that they're moved in an aesthetically pleasing
            #   order
            @areaList = reverse @areaList;
        }

        # Reset the zone's internal grid
        $self->resetInternalGrid();

        # Save the size of the adjustment - if there's a gap big enough for another area,
        #   GA::Obj::Workspace->createGridWin can use the adjustment in creating an area small
        #   enough to fit
        $self->ivPoke('areaAdjustFlag', TRUE);
        if ($self->orientation eq 'horizontal') {
            $self->ivPlus('widthAdjustBlocks', $largestAdjustment);
        } else {
            $self->ivPlus('heightAdjustBlocks', $largestAdjustment);
        }

        # Now, move all the areas (and the windows contained in them) into their new positions,
        #   starting with window closest to the start corner
        if ($self->orientation eq 'horizontal') {

            if ($self->startCorner eq 'top_left' || $self->startCorner eq 'bottom_left') {

                $startBlock = 0;
                $dir = 1;     # Move right

            } else {

                $startBlock = $self->widthBlocks - 1;
                $dir = -1;    # Move left
            }

        } elsif ($self->orientation eq 'vertical') {

            if ($self->startCorner eq 'top_left' || $self->startCorner eq 'top_right') {

                $startBlock = 0;
                $dir = 1;     # Move down

            } else {

                $startBlock = $self->heightBlocks - 1;
                $dir = -1;    # Move up
            }
        }

        foreach my $areaObj (@areaList) {

            my (
                $widthBlocks, $heightBlocks, $xPosBlocks, $yPosBlocks, $widthPixels, $heightPixels,
                $xPosPixels, $yPosPixels,
            );

            if ($self->orientation eq 'horizontal') {

                # Set the new size of the area, in blocks on the zone's internal grid
                $widthBlocks = $areaObj->zoneWidth + $adjustHash{$areaObj->number};
                $heightBlocks = $areaObj->zoneHeight;
                # Set the new position of the area, in blocks on the zone's internal grid
                $yPosBlocks = $areaObj->zoneTop;
                if ($dir == 1) {
                    $xPosBlocks = $startBlock;
                } else {
                    $xPosBlocks = ($startBlock - $widthBlocks + 1);
                }

                # Set $startBlock as the position of the next area
                $startBlock = $startBlock + ($widthBlocks * $dir);

            } else {

                # Set the new size of the area, in blocks on the zone's internal grid
                $widthBlocks = $areaObj->zoneWidth;
                $heightBlocks = $areaObj->zoneHeight + $adjustHash{$areaObj->number};
                # Set the new position of the area, in blocks on the zone's internal grid
                $xPosBlocks = $areaObj->zoneLeft;
                if ($dir == 1) {
                    $yPosBlocks = $startBlock;
                } else {
                    $yPosBlocks = ($startBlock - $heightBlocks + 1);
                }

                # Set $startBlock as the position of the next window
                $startBlock = $startBlock + ($heightBlocks * $dir);
            }

            # Convert these values into pixels on the workspace
            $blockSize = $axmud::CLIENT->gridBlockSize;

            $widthPixels = $widthBlocks * $blockSize;
            $heightPixels = $heightBlocks * $blockSize;
            $xPosPixels = $self->workspaceGridObj->xPosPixels
                + (($self->xPosBlocks + $xPosBlocks) * $blockSize);
            $yPosPixels = $self->workspaceGridObj->yPosPixels +
                (($self->yPosBlocks + $yPosBlocks) * $blockSize);

            # Correct for windows controls, etc
            ($xPosPixels, $yPosPixels, $widthPixels, $heightPixels)
                = $self->workspaceGridObj->fineTuneWinSize(
                    $areaObj->winObj->winType,
                    $xPosPixels,
                    $yPosPixels,
                    $widthPixels,
                    $heightPixels,
                );

            # Resize the window and move it to the correct location
            $self->workspaceGridObj->workspaceObj->moveResizeWin(
                $areaObj->winObj,
                $xPosPixels,
                $yPosPixels,
                $widthPixels,
                $heightPixels,
            );

            # Update the area object with the window's new location
            $areaObj->set_zone(
                $layer,
                $xPosBlocks,
                $yPosBlocks,
                $widthBlocks,
                $heightBlocks,
            );

            $areaObj->set_posn(
                $xPosPixels,
                $yPosPixels,
                $widthPixels,
                $heightPixels,
            );

            # Restack the windows in this zone - windows in a higher layer are placed above those in
            #   a lower layer; but windows which are higher than the workspace grid's ->currentLayer
            #   are minimised
            $self->restackWin();
        }

        # Adjustment complete
        return 1;
    }

    sub getSortedAreaList {

        # Called by $self->adjustMultipleWin and $self->replaceAreaSpace
        # Returns a list of all areas in the zone, on a specified layer, sorted in the order of
        #   closeness to the starting corner. (Each area is a space on the grid occupied by a
        #   single window)
        #
        # Expected arguments
        #   $layer      - Which layer to check
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, the sorted list. If there are no areas on this layer, returns an empty list

        my ($self, $layer, $check) = @_;

        # Local variables
        my (@emptyList, @areaList);

        # Check for improper arguments
        if (! defined $layer || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getSortedAreaList', @_);
            return @emptyList;
        }

        # Compile a list of all windows in this zone, at the specified layer
        foreach my $areaObj ($self->ivValues('areaHash')) {

            if ($areaObj->layer == $layer) {

                push (@areaList, $areaObj);
            }
        }

        # Sort the list, with the area closest to the starting corner at the beginning of the list
        if ($self->orientation eq 'horizontal') {

            if ($self->startCorner eq 'top_left' || $self->startCorner eq 'bottom_left') {

                @areaList = sort {$a->leftBlocks <=> $b->leftBlocks} (@areaList);

            } else {

                @areaList = sort {$b->rightBlocks <=> $a->rightBlocks} (@areaList);
            }

        } elsif ($self->orientation eq 'vertical') {

            if ($self->startCorner eq 'top_left' || $self->startCorner eq 'top_right') {

                @areaList = sort {$a->topBlocks <=> $b->topBlocks} (@areaList);

            } else {

                @areaList = sort {$b->bottomBlocks <=> $a->bottomBlocks} (@areaList);
            }
        }

        # Return the sorted list
        return @areaList;
    }

    sub addArea {

        # Called by GA::Obj::Workspace->createGridWin
        # Marks a part of the zone's internal grid as occupied by this window (by creating a new
        #   GA::Obj::Area object), and updates other IVs
        #
        # Expected arguments
        #   $layer          - The window's layer on the zone's internal grid
        #   $xPosBlocks, $yPosBlocks
        #                   - The window's x/y coordinates on the zone's internal grid (in
        #                       gridblocks)
        #   $widthBlocks, $heightBlocks
        #                   - The window's width and height (in gridblocks)
        #   $xPosPixels, $yPosPixels
        #                   - The window's x/y coordinates on the workspace (in pixels)
        #   $widthPixels, $heightPixels
        #                   - The window's width and height (in pixels)
        #
        # Optional arguments
        #   $session
        #       - The GA::Session controlling this window ('undef' if no owner)
        #   $changeWinObj
        #       - Specified by GA::Obj::WorkspaceGrid->changeWinzone, when it wants to place a
        #           window in the same zone it currently occupied. If defined, regard any space
        #           occupied by this window as available
        #       - NB If $changeWinObj is specified, it's the same as $winObj
        #
        # Return values
        #   'undef' on improper arguments, or if any part of the zone's internal grid to be occupied
        #       by the window is already occupied (won't happen if this function is called by
        #       GA::Client->createGridWin)
        #   Otherwise returns the GA::Obj::Area object created

        my (
            $self, $layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $xPosPixels,
            $yPosPixels, $widthPixels, $heightPixels, $session, $changeWinObj, $check,
        ) = @_;

        # Local variables
        my $areaObj;

        # Check for improper arguments
        if (
            ! defined $layer || ! defined $xPosBlocks  || ! defined $yPosBlocks
            || ! defined $widthBlocks || ! defined $heightBlocks || ! defined $xPosPixels
            || ! defined $yPosPixels || ! defined $widthPixels || ! defined $heightPixels
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addArea', @_);
        }

        # Check that the area is unoccupied by other windows (it shouldn't be)
        if (
            ! $self->checkPosnInLayer(
                $layer,
                $xPosBlocks,
                $yPosBlocks,
                $widthBlocks,
                $heightBlocks,
                $changeWinObj,
            )
        ) {
            return $axmud::CLIENT->writeError(
                'Window cannot be placed at the specified position, because the area is already'
                . ' occupied',
                $self->_objClass . '->addArea',
            );
        }

        # Create a new area object to store details about the window's size and position
        $areaObj = Games::Axmud::Obj::Area->new($self->areaCount, $self);
        $self->ivAdd('areaHash', $areaObj->number, $areaObj);
        $self->ivIncrement('areaCount');

        # If $self->ownerString is defined, this zone is reserved for a single session. The IV's
        #   value can be any non-empty string. All zones with the same ->ownerString are reserved
        #   for a particular session
        # The first session to place one of its windows into any 'owned' zone claims all of
        #   those zones for itself. If $self->ownerString IV is 'undef', the zone is available for
        #   any session to use (subject to restriction described in the comments in $self->new)
        # ->ownerString is ignored in GA::Client->shareMainWinFlag = TRUE
        if (
            ! $axmud::CLIENT->shareMainWinFlag
            && defined $session
            && defined $self->ownerString
            && $self->ownerString ne ''
            && ! defined $self->owner
        ) {
            # Claim this zone, and all other zones (across all workspaces) with the same
            #   ->ownerString for this session
            $axmud::CLIENT->desktopObj->claimZones($session, $self->ownerString);
        }

        # Set its IVs (->set_win is called by GA::Obj::Workspace->createGridWin, once the window
        #   object has been created)
        $areaObj->set_zone($layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks);
        $areaObj->set_posn($xPosPixels, $yPosPixels, $widthPixels, $heightPixels);

        return $areaObj;
    }

    sub removeArea {

        # Called by GA::Obj::Workspace->createGridWin, GA::Obj::WorkspaceGrid->changeWinzone and
        #   ->del_gridWin
        # Removes the GA::Obj::Area object (which is occupied by a single window) from this zone's
        #   internal grid
        # Optionally reshuffles remaining windows
        #
        # Expected arguments
        #   $areaObj        - The GA::Obj::Area which should be removed
        #
        # Optional arguments
        #   $noShuffleFlag  - Set to TRUE when called GA::Obj::WorkspaceGrid->changeWinzone, in
        #                       which case this function doesn't call $self->replaceAreaSpace to
        #                       reshuffle the positions of windows in this zone
        #
        # Return values
        #   'undef' on improper arguments, or if the area doesn't seem to exist in this zone, or
        #       if an operation to re-shuffle window positions fails
        #   1 otherwise

        my ($self, $areaObj, $noShuffleFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $areaObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeArea', @_);
        }

        # Update IVs
        $self->ivDelete('areaHash', $areaObj->number);

        # If there are no areas left in this zone, and the zone's ->owner is set, tell the
        #   GA::Obj::Desktop to check all zones across all workspaces. If the session has no windows
        #   in any of the zones it controls, free up those zones so they're available to another
        #   session
        if ($self->owner && ! $self->areaHash) {

            $axmud::CLIENT->desktopObj->relinquishZones($self->ownerString);
        }

        # If the global flag is set, reshuffle the position of all windows in this zone, removing
        #   any gaps that might have appeared in the middle of the zone, if the removed window
        #   occupied that space
        if (! $noShuffleFlag && $axmud::CLIENT->gridReshuffleFlag) {

            return $self->replaceAreaSpace($areaObj->layer);

        } else {

            return 1;
        }
    }

    sub replaceAreaSpace {

        # Called by $self->removeArea
        # After a window has been removed, it's often desirable to move all the windows in the zone
        #   (on the same layer) to fill the gap - so, instead of having a gap in the middle, we have
        #   a gap at the end (the opposite end to the starting corner).
        # This function performs that operation
        #
        # Expected arguments
        #   $layer      - Which layer to reshuffle
        #
        # Return values
        #   'undef' on improper arguments, or if (for some very unlikely reason) one of the windows
        #       won't fit in the zone
        #   1 otherwise

        my ($self, $layer, $check) = @_;

        # Local variables
        my (
            $blockSize,
            @areaList,
        );

        # Check for improper arguments
        if (! defined $layer || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->replaceAreaSpace', @_);
        }

        # Compile a list of GA::Obj::Area objects (one area for each window), sorted in order of
        #   their proximity to the starting corner
        @areaList = $self->getSortedAreaList($layer);

        # Move the windows into position. Start with the closest windows, so that all windows are in
        #   turn moved closer to the starting corner
        $blockSize = $axmud::CLIENT->gridBlockSize;
        foreach my $areaObj (@areaList) {

            my (
                $widthBlocks, $heightBlocks, $widthPixels, $heightPixels, $xPosBlocks, $yPosBlocks,
                $xPosPixels, $yPosPixels, $successFlag,
            );

            # Get the area's size on the zone's internal grid. Remove the influence of any past
            #   fine-tuning by GA::Obj::WorkspaceGrid->fineTuneWinSize and window size adjustments
            #   made by $self->adjustMultipleWin
            $widthBlocks = $areaObj->widthBlocks - $self->widthAdjustBlocks;
            $heightBlocks = $areaObj->heightBlocks - $self->heightAdjustBlocks;
            # Convert into pixels
            $widthPixels = $widthBlocks * $blockSize;
            $heightPixels = $heightBlocks * $blockSize;

            # Provisionally place the area's window at the starting corner of the zone's internal
            #   grid
            ($widthBlocks, $heightBlocks, $xPosBlocks, $yPosBlocks)
                = $self->findProvWinPosn($widthPixels, $heightPixels);

            # Move the window into the first unoccupied position in the zone's internal grid
            ($successFlag, $layer, $xPosBlocks, $yPosBlocks)
                = $self->placeWin(
                    $layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $areaObj->winObj,
                  );

            # There should be no possible reason why there isn't enough room - but just in case...
            if (! $successFlag) {

                return $self->writeError(
                    'Failed to replaced a formerly occupied part of zone #' . $self->number,
                    $self->_objClass . '->replaceAreaSpace',
                );
            }

            # Adjust windows at the edge of the zone, if necessary
            if ($axmud::CLIENT->gridGapMaxSize) {

                ($xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks) = $self->adjustSingleWin(
                    $layer,
                    $xPosBlocks,
                    $yPosBlocks,
                    $widthBlocks,
                    $heightBlocks,
                );
            }

            # Get the window's new size and position in pixels (converting from blocks)
            ($xPosPixels, $yPosPixels) = $self->getInternalGridPosn($xPosBlocks, $yPosBlocks);
            $widthPixels = $widthBlocks * $blockSize;
            $heightPixels = $heightBlocks * $blockSize;

            # Fine tune the window size, taking into account window controls and arkward available
            #   workspace sizes
            ($xPosPixels, $yPosPixels, $widthPixels, $heightPixels)
                = $self->workspaceGridObj->fineTuneWinSize(
                    $areaObj->winObj->winType,
                    $xPosPixels,
                    $yPosPixels,
                    $widthPixels,
                    $heightPixels,
                );

            # Resize the window and move it to the correct location
            $self->workspaceGridObj->workspaceObj->moveResizeWin(
                $areaObj->winObj,
                $xPosPixels,
                $yPosPixels,
                $widthPixels,
                $heightPixels,
            );

            # Update the area object with the window's new location
            $areaObj->set_zone(
                $layer,
                $xPosBlocks,
                $yPosBlocks,
                $widthBlocks,
                $heightBlocks,
            );

            $areaObj->set_posn(
                $xPosPixels,
                $yPosPixels,
                $widthPixels,
                $heightPixels,
            );
        }

        # Cancel any window adjustments - they are no longer valid
        $self->ivPoke('areaAdjustFlag', FALSE);
        $self->ivPoke('widthAdjustBlocks', 0);
        $self->ivPoke('heightAdjustBlocks', 0);

        # Operation complete
        return 1;
    }

    sub restackWin {

        # Called by GA::Obj::Workspace->createGridWin, ->moveResizeWin and
        #   $self->adjustMultipleWin
        # Restack the windows in this zone - windows in a higher layer are placed above those in a
        #   lower layer; but windows which are higher than the workspace grid's ->currentLayer are
        #   minimised
        # NB The window manager is under no obligation to obey a request to restack one window above
        #   another, so this operation is not foolproof
        # NB This function does nothing if GA::Obj::Workspace->gridEnableFlag = FALSE or if no
        #   windows have been created yet (unlikely)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the windows are not restacked
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $screen, $swapFlag,
            @areaList, @winObjList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restackWin', @_);
        }

        # Don't do any restacking in if workspace grids are disabled or if no grid windows have been
        #   created in this workspace grid yet
        foreach my $zoneObj ($self->workspaceGridObj->ivValues('zoneHash')) {

            push (@areaList, $zoneObj->ivValues('areaHash'));
        }

        if (! @areaList || ! $self->workspaceGridObj->workspaceObj->gridEnableFlag) {

            return undef;
        }

        # Find the first window object whose Gtk2::Window is known, and from that, get the
        #   Gtk2::Gdk::Screen
        OUTER: foreach my $areaObj (@areaList) {

            if (defined $areaObj->winObj->winWidget) {

                $screen = $areaObj->winObj->winWidget->get_screen();
                if (defined $screen) {

                    last OUTER;
                }
            }
        }

        if (! defined $screen) {

            # Can't continue without a Gtk2::Gdk::Screen (unlikely)
            return undef;
        }

        # From the list of all windows on this screen, extract a list of windows on the workspace
        #   grid (in the order that they're stacked)
        OUTER: foreach my $win ($screen->get_window_stack()) {

            # Find the equivalent window object, if there is one
            INNER: foreach my $areaObj ($self->ivValues('areaHash')) {

                my ($winObj, $gdkWin);

                $winObj = $areaObj->winObj;

                # Find the Gtk2::Window's equivalent Gtk2::Gdk::Window
                if ($winObj->winWidget) {

                    $gdkWin = $winObj->winWidget->get_window();

                    # Is this window on the workspace grid?
                    if ($gdkWin && $gdkWin eq $win) {

                        # If the window is in a layer higher than the current one, just minimise it
                        #   (unless it's already minimised)
                        if ($areaObj->layer > $self->workspaceGridObj->currentLayer) {

                            if ($winObj->wnckWin && ! $winObj->wnckWin->is_minimized()) {

                                $winObj->wnckWin->minimize();
                            }

                        } else {

                            # This window is at the current layer, or below it
                            push (@winObjList, $winObj);

                            # If the window is minimised, un-minimise it
                            if ($winObj->wnckWin && $winObj->wnckWin->is_minimized()) {

                                $winObj->wnckWin->unminimize(time());
                            }

                            next OUTER;
                        }
                    }
                }
            }
        }

        # Gtk2::Gdk::Window allows us to restack window above another, but not to swap the position
        #   of two windows in the stack, so we're forced to do an evil bubble sort
        do {

            $swapFlag = FALSE;

            for (my $i = 1; $i < scalar @winObjList; $i++) {

                my ($gdkWin, $gdkWin2);

                # If an adjacent pair of windows is in the wrong order in @winObjList (i.e. if the
                #   first window has a higher layer than the second one)...
                if ($winObjList[$i - 1]->areaObj->layer > $winObjList[$i]->areaObj->layer) {

                    # Restack the higher-layer window beneath the lower-layer one (this is the only
                    #   method that seems to work)
                    $gdkWin = $winObjList[$i - 1]->winWidget->get_window();
                    $gdkWin2 = $winObjList[$i]->winWidget->get_window();
                    $gdkWin2->restack($gdkWin, 0);

                    # Update the bubble sort list
                    ($winObjList[$i - 1], $winObjList[$i]) = ($winObjList[$i], $winObjList[$i - 1]);
                    $swapFlag = TRUE;
                }
            }

        } until (! $swapFlag);

        return 1;
    }

    ##################
    # Accessors - set

    sub set_areaHeight {

        # Called by GA::Obj::WorkspaceGrid->resetZones

        my ($self, $height, $check) = @_;

        # Check for improper arguments
        if (! defined $height || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_areaHeight', @_);
        }

        $self->ivPoke('defaultAreaHeight', $height);

        return 1;
    }

    sub set_areaVars {

        # Called by GA::Obj::WorkspaceGrid->resetZones

        my ($self, $areaMax, $visibleAreaMax, $areaCount, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $areaMax || ! defined $visibleAreaMax || ! defined $areaCount
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_areaVars', @_);
        }

        $self->ivPoke('areaMax', $areaMax);
        $self->ivPoke('visibleAreaMax', $visibleAreaMax);
        $self->ivPoke('areaCount', $areaCount);

        return 1;
    }

    sub set_areaWidth {

        # Called by GA::Obj::WorkspaceGrid->resetZones

        my ($self, $width, $check) = @_;

        # Check for improper arguments
        if (! defined $width || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_areaWidth', @_);
        }

        $self->ivPoke('defaultAreaWidth', $width);

        return 1;
    }

    sub set_orientation {

        # Called by GA::Obj::WorkspaceGrid->resetZones

        my ($self, $startCorner, $orientation, $check) = @_;

        # Check for improper arguments
        if (! defined $startCorner || ! defined $orientation || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_orientation', @_);
        }

        $self->ivPoke('startCorner', $startCorner);
        $self->ivPoke('orientation', $orientation);

        return 1;
    }

    sub set_owner {

        # Called by GA::Obj::Desktop->claimZones

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_owner', @_);
        }

        $self->ivPoke('owner', $session);

        return 1;
    }

    sub reset_owner {

        # Called by GA::Obj::Desktop->relinquishZones

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_owner', @_);
        }

        $self->ivPoke('owner', undef);

        return 1;
    }

    sub set_ownerString {

        # Called by GA::Obj::WorkspaceGrid->resetZones

        my ($self, $string, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_ownerString', @_);
        }

        $self->ivPoke('ownerString', $string);

        return 1;
    }

    sub set_posn {

        # Called by GA::Obj::WorkspaceGrid->resetZones

        my ($self, $x, $y, $check) = @_;

        # Check for improper arguments
        if (! defined $x || ! defined $y || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_posn', @_);
        }

        $self->ivPoke('xPosBlocks', $x);
        $self->ivPoke('yPosBlocks', $y);

        return 1;
    }

    sub set_reserved {

        # Called by GA::Obj::WorkspaceGrid->resetZones

        my ($self, $multipleLayerFlag, $reservedFlag, %reservedHash) = @_;

        # Check for improper arguments
        if (! defined $multipleLayerFlag || ! defined $reservedFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_reserved', @_);
        }

        $self->ivPoke('multipleLayerFlag', $multipleLayerFlag);
        $self->ivPoke('reservedFlag', $reservedFlag);
        $self->ivPoke('reservedHash', %reservedHash);

        return 1;
    }

    sub set_size {

        # Called by GA::Obj::WorkspaceGrid->resetZones

        my ($self, $width, $height, $check) = @_;

        # Check for improper arguments
        if (! defined $width || ! defined $height || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_size', @_);
        }

        $self->ivPoke('widthBlocks', $width);
        $self->ivPoke('heightBlocks', $height);

        return 1;
    }

    sub set_winmap {

        # Called by GA::Obj::WorkspaceGrid->resetZones

        my ($self, $enabledWinmap, $disabledWinmap, $internalWinmap, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_winmap', @_);
        }

        $self->ivPoke('defaultEnabledWinmap', $enabledWinmap);
        $self->ivPoke('defaultDisabledWinmap', $disabledWinmap);
        $self->ivPoke('defaultInternalWinmap', $internalWinmap);

        return 1;
    }

    ##################
    # Accessors - get

    sub number
        { $_[0]->{number} }
    sub workspaceGridObj
        { $_[0]->{workspaceGridObj} }

    sub xPosBlocks
        { $_[0]->{xPosBlocks} }
    sub yPosBlocks
        { $_[0]->{yPosBlocks} }
    sub widthBlocks
        { $_[0]->{widthBlocks} }
    sub heightBlocks
        { $_[0]->{heightBlocks} }

    sub reservedFlag
        { $_[0]->{reservedFlag} }
    sub reservedHash
        { my $self = shift; return %{$self->{reservedHash}}; }
    sub multipleLayerFlag
        { $_[0]->{multipleLayerFlag} }

    sub ownerString
        { $_[0]->{ownerString} }
    sub owner
        { $_[0]->{owner} }

    sub areaHash
        { my $self = shift; return %{$self->{areaHash}}; }
    sub areaCount
        { $_[0]->{areaCount} }
    sub areaMax
        { $_[0]->{areaMax} }
    sub visibleAreaMax
        { $_[0]->{visibleAreaMax} }

    sub startCorner
        { $_[0]->{startCorner} }
    sub orientation
        { $_[0]->{orientation} }
    sub defaultEnabledWinmap
        { $_[0]->{defaultEnabledWinmap} }
    sub defaultDisabledWinmap
        { $_[0]->{defaultDisabledWinmap} }
    sub defaultInternalWinmap
        { $_[0]->{defaultInternalWinmap} }

    sub defaultAreaWidth
        { $_[0]->{defaultAreaWidth} }
    sub defaultAreaHeight
        { $_[0]->{defaultAreaHeight} }
    sub areaAdjustFlag
        { $_[0]->{areaAdjustFlag} }
    sub widthAdjustBlocks
        { $_[0]->{widthAdjustBlocks} }
    sub heightAdjustBlocks
        { $_[0]->{heightAdjustBlocks} }
}

# Package must return true
1
