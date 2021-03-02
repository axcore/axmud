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
# Games::Axmud::Obj::Regionmap
# Handles a single region with the world model

{ package Games::Axmud::Obj::Regionmap;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by Games::Axmud::Obj::WorldModel->addRegion
        #
        # Create a new instance of the regionmap object, which contains the layout of a single
        #   region in the world. Each regionmap object corresponds to a GA::ModelObj::Region stored
        #   in the world model
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the regionmap (matches GA::ModelObj::Region->name)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'worldmodel',
            _parentWorld                => $session->currentWorld->name,
            # All IVs are private, but should usually be set with calls to the GA::Obj::WorldModel
            #   object
            _privFlag                   => TRUE,        # All IVs are private

            # Object IVs
            # ----------

            # The region's name (max 32 chars)
            name                        => $name,
            # The model number of the corresponding GA::ModelObj::Region (set later by
            #   GA::Obj::WorldModel->addRegion)
            number                      => undef,

            # Current magnification - 1 is the standard size
            magnification               => 1,
            # Position of the scrollbars (values between 0 and 1), the last time this region was
            #   removed from display - stored here so that, the next time it is displayed, the
            #   scrollbars can be moved to the same position
            scrollXPos                  => 0.5,         # Middle of the map
            scrollYPos                  => 0.5,
            # They are also stored when the user zooms out fully, so that there are no scrollbars
            #   visible - so that, the next time the user zooms in, the map is in the same position.
            #   (Gtk3::Canvas conveniently forgets, so we have to remember ourselves.)
            # When that happens, this flag is set to TRUE. Whenever the user zooms in or out,
            #   ->zoomCallback checks this flag. If it has been set to TRUE, ->zoomCallback knows
            #   that the previous zoom was maximum, and that therefore the scrollbars are in the
            #   wrong place. They are moved, and the flag is reset back to FALSE.
            # One of the horizontal and vertical scrollbars may be fully zoomed out before the
            #   other, so we have two flags, one for each scrollbar
            maxZoomOutXFlag             => FALSE,
            maxZoomOutYFlag             => FALSE,

            # Current block/room sizes (which depend on the magnification)
            gridWidthBlocks             => undef,       # Set below
            gridHeightBlocks            => undef,
            blockWidthPixels            => undef,
            blockHeightPixels           => undef,
            roomWidthPixels             => undef,
            roomHeightPixels            => undef,
            # Current map (canvas) sizes (which depend on the magnification)
            mapWidthPixels              => undef,       # Set below
            mapHeightPixels             => undef,

            # Name of the region scheme (GA::Obj::RegionScheme) that specifies colours for this
            #   region. If 'undef', or if the named scheme doesn't exist, colours specified by the
            #   'default' region scheme are used
            regionScheme                => undef,

            # How exits are drawn for this region; the range of values matches those used in
            #   GA::Obj::WorldModel->drawExitMode. If that IV is set to 'ask_regionmap', this IV is
            #   consulted
            # The acceptable values are:
            #   'no_exit' - Draw no exits (only the rooms themselves are drawn)
            #   'simple_exit' - Draw simple exits (all exists are simple lines, with arrows for
            #       one-way exits)
            #   'complex_exit' - Draw complex exits (there are four kinds of exits drawn -
            #       incomplete, uncertain, one-way and two-way)
            drawExitMode                => 'simple_exit',
            # Flag set to TRUE if the automapper should obscure (i.e. filter out) some exits in this
            #   region, drawing only those exits for rooms near the current room, or for selected
            #   rooms (and selected exits), and for rooms whose rooms flags match those in
            #   GA::Client->constRoomNoObscuredHash (e.g. 'main_route')
            obscuredExitFlag            => FALSE,
            # Flag set to TRUE if the automapper should re-obscure exits as the character moves
            #   around (so that only exits around the character's location are visible), and
            #   when other conditions change
            obscuredExitRedrawFlag      => FALSE,
            # Radius (in gridblocks) of a square area, with the current room in the middle. When
            #   obscuring exits is enabled for this region, exits are drawn for all rooms in this
            #   area (including the current room), but not necessarily for any rooms outside the
            #   area
            # Use 1 to draw only the current room, 2 to draw exits for rooms in a 3x3 area, 3 for a
            #   5x5 area, and so on
            # The maximum value is that specified by GA::Obj::WorldModel->maxObscuredExitRadius
            obscuredExitRadius          => 3,
            # When this flag is set to TRUE, exit ornaments are drawn in this region. If set to
            #   FALSE, ornaments aren't drawn
            drawOrnamentsFlag           => TRUE,

            # The current level (i.e., the z-coordinate currently displayed). The initial level is
            #   0, the level in the middle
            currentLevel                => 0,
            # The highest level occupied by a room or label (set to 'undef' when the regionmap has
            #   no rooms or labels)
            highestLevel                => undef,
            # The lowest level occupied by a room (set to 'undef' when the regionmap has no rooms or
            #   labels)
            lowestLevel                 => undef,

            # The region's layout is stored in the following IVs as a collection of
            #   GA::ModelObj::Room, GA::Obj::Exit and GA::Obj::MapLabel objects
            # Only one room is allowed per gridblock, but exits and labels can be drawn freely
            # Hash of rooms in this regionmap, in the form
            #   $gridRoomHash{'x_y_z'} = model_number_of_room_at_these_coordinates
            # ...where 'x_y_z' are the room's coordinates in the regionmap
            gridRoomHash                => {},
            # Hash of rooms with room tags in this regionmap, in the form
            #   $gridRoomTagHash{'x_y_z'} = model_number_of_room_at_these_coordinates
            gridRoomTagHash             => {},
            # Hash of rooms with room guilds in this regionmap, in the form
            #   $gridRoomGuildHash{'x_y_z'} = model_number_of_room_at_these_coordinates
            gridRoomGuildHash           => {},
            # Hash of exits that have been drawn in this regionmap (not necessarily all the exits in
            #   all the rooms - the Automapper window often needs to know which exits have been
            #   drawn, and which therefore need to be re-drawn, and for that it uses this hash)
            # Hash in the form
            #   $gridExitHash{exit_model_number} = undef
            gridExitHash                => {},
            # Hash of (all) exits with exit tags in this regionmap, in the form
            #   $gridExitTagHash{exit_model_number} = undef
            gridExitTagHash             => {},
            # Hash of (all) labels that exist in this regionmap, in the form
            #   $gridLabelHash{label_number} = blessed_reference_to_map_label_object
            gridLabelHash               => {},

            # As GA::Obj::MapLabel objects are added to this regionmap they are given a unique
            #   ->labelNumber. This IV records the ->labelNumber given to the last created label.
            #   The first label gets the number #1
            # (The number is set by $self->storeLabel)
            labelCount                  => 0,

            # Gridblocks in the map's background can be coloured in (useful for representing map
            #   features that aren't actually accessible to the player, such as rivers and mountain
            #   ranges)
            # The user can colour in a single gridblock, or a group of gridblocks in a rectangle
            #   shape
            # The rules for drawing are these:
            # 1. Coloured rectangles can overlap each other. The coloured rectangle that was added
            #   first is drawn first (so will be obscured by later rectangles)
            # 2. Coloured rectangles cannot overlap a single coloured block. Adding a coloured
            #   rectangle destroys any single coloured block in the same space
            # 3. Single coloured blocks cannot overlap other coloured blacks or other coloured
            #   rectangles. Adding a single coloured block destroys any existing single coloured
            #   block or coloured rectangle occupying the same gridblock
            #
            # Single gridblock colours are stored in this hash, a hash in the form
            #   $gridColourBlockHash{'x_y_z'} = rgb_colour_tag
            #   $gridColourBlockHash{'x_y'} = rgb_colour_tag
            # ...where 'x_y_z' are the block's coordinates in the regionmap (for coloured blocks
            #       displayed on only one level), 'x_y' are the block's coordinates (for coloured
            #       blocks that are displayed on every level), and 'rgb_colour_tag' is in the form
            #       #ABCDEF (case-insensitive)
            gridColourBlockHash         => {},
            # Multiple gridblock colours are stored as GA::Obj::GridColour objects. Hash in the form
            #   $gridColourObjHash{unique_number} = blessed_reference_to_grid_colour_object
            gridColourObjHash           => {},
            # Number of grid colour objects ever created in this regionmap (used to give each
            #   object a unique number)
            colourObjCount              => 0,

            # Hash of exits that lead to another region, in the form
            #   $regionExitHash{exit_number} = model_number_of_other_region
            regionExitHash              => {},
            # Hash of paths between all the exits in ->regionExitHash, in the form
            #   $regionPathHash{exit_string} = blessed_ref_of_region_path_object
            # ...where 'exit_string' is in the form 'a_b', where 'a' is the exit model number of the
            #   region exit at the start of the path, and 'b' is the exit model number of the exit
            #   at the end of the path
            regionPathHash              => {},
            # Hash of paths between all the exits in ->regionExitHash, but avoiding rooms with
            #   hazardous room flags. The actual paths are not necessarily the same as those in
            #   ->regionPathHash. When there is no safe path between two boundary exits, there will
            #   be an entry in ->regionPathHash but not a corresponding one in ->safeRegionPathHash
            safeRegionPathHash          => {},

            # When the Locator task has a current room, it copies the room's contents into
            #   GA::ModelObj::Room->tempObjList
            # Now, when GA::Win::Map->countRoomContents is called, the automapper makes a note of
            #   how many living and non-living things there are in the Locator's current room, and
            #   stores them in the equivalent room object
            # Hence, each room object has a record of the number of living and non-living things in
            #   it, the last time the room was visited
            # We can use this record to display the counts (when the appropriate flag is set) and,
            #   more importantly, it's quick and easy to empty the record when the user wants a
            #   reset
            # These two hashes are in the form
            #   $hash{room_object_model_number} = number_of_things
            # If there is no entry for a room in this region, then the number of things in it (on
            #   the last visit) is 0
            livingCountHash             => {},
            nonLivingCountHash          => {},
        };

        # Bless the object into existence
        bless $self, $class;

        # Set the initial values of the size IVs
        $self->{gridWidthBlocks}        = $session->worldModelObj->defaultGridWidthBlocks;
        $self->{gridHeightBlocks}       = $session->worldModelObj->defaultGridHeightBlocks;
        # NB ->blockWidthPixels, ->blockHeightPixels, ->roomWidthPixels and
        #   ->roomHeightPixels are set again every time the map is redrawn
        $self->{blockWidthPixels}       = $session->worldModelObj->defaultBlockWidthPixels;
        $self->{blockHeightPixels}      = $session->worldModelObj->defaultBlockHeightPixels;
        $self->{roomWidthPixels}        = $session->worldModelObj->defaultRoomWidthPixels;
        $self->{roomHeightPixels}       = $session->worldModelObj->defaultRoomHeightPixels;
        # NB ->mapWidthPixels and ->mapHeightPixels are set again every time the map
        #   is redrawn
        $self->{mapWidthPixels}         = $self->gridWidthBlocks * $self->blockWidthPixels;
        $self->{mapHeightPixels}        = $self->gridHeightBlocks * $self->blockHeightPixels;

        return $self;
    }

    ##################
    # Methods

    sub emptyGrid {

        # Called by GA::Obj::WorldModel->emptyRegion
        # Resets this object's IVs after a region is emptied
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->emptyGrid', @_);
        }

        # Reset the highest/lowest occupied levels
        $self->ivUndef('highestLevel');
        $self->ivUndef('lowestLevel');

        # Empty the hashes of drawn objects
        $self->ivEmpty('gridRoomHash');
        $self->ivEmpty('gridRoomTagHash');
        $self->ivEmpty('gridRoomGuildHash');
        $self->ivEmpty('gridExitHash');
        $self->ivEmpty('gridLabelHash');
        $self->ivPoke('labelCount', 0);

        # Empty the hashes of grid colours
        $self->ivEmpty('gridColourBlockHash');
        $self->ivEmpty('gridColourObjHash');
        $self->ivPoke('colourObjCount', 0);

        # Empty the hashes of region paths
        $self->ivEmpty('regionExitHash');
        $self->ivEmpty('regionPathHash');
        $self->ivEmpty('safeRegionPathHash');

        # Reset the living/non-living object counts
        $self->ivEmpty('livingCountHash');
        $self->ivEmpty('nonLivingCountHash');

        return 1;
    }

    # Functions for $self->gridRoomHash, ->gridRoomTagHash, ->gridRoomGuildHash, ->gridExitHash,
    #   ->gridLabelHash

    sub checkGridBlock {

        # Can be called by anything
        # Checks that a gridblock actually exists - for example, before creating a new room, check
        #   that its proposed location actually fits on the map
        #
        # Expected arguments
        #   $xPosBlocks, $yPosBlocks, $zPosBlocks
        #       - Coordinates of the gridblock in this regionmap to check
        #
        # Return values
        #   'undef' on improper arguments or if the gridblock doesn't actually exist
        #   1 if the gridblock exists (regardless of whether it contains a room, or not)

        my ($self, $xPosBlocks, $yPosBlocks, $zPosBlocks, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $xPosBlocks || ! defined $yPosBlocks || ! defined $zPosBlocks
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkGridBlock', @_);
        }

        if (
            ! $axmud::CLIENT->intCheck($xPosBlocks, 0)
            || ! $axmud::CLIENT->intCheck($yPosBlocks, 0)
            || ! $axmud::CLIENT->intCheck($zPosBlocks)          # Can be negative
            || $xPosBlocks >= $self->gridWidthBlocks
            || $yPosBlocks >= $self->gridHeightBlocks
        ) {
            # Specified gridblock doesn't exist
            return undef;

        } else {

            # Specified gridblock exists
            return 1;
        }
    }

    sub fetchRoom {

        # Can be called by anything
        # Finds the GA::ModelObj::Room in the gridblock at the specified coordinates in the grid
        #
        # Expected arguments
        #   $xPosBlocks, $yPosBlocks, $zPosBlocks
        #       - The grid coordinates of the room object to get
        #
        # Return values
        #   'undef' on improper arguments, or if the specified gridblock doesn't exits or doesn't
        #       contain a room
        #   Otherwise, returns the model number of the GA::ModelObj::Room occupying the gridblock

        my ($self, $xPosBlocks, $yPosBlocks, $zPosBlocks, $check) = @_;

        # Local variables
        my ($posn, $number);

        # Check for improper arguments
        if (
            ! defined $xPosBlocks || ! defined $yPosBlocks || ! defined $zPosBlocks
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->fetchRoom', @_);
        }

        # Need to check that $xPosBlocks, $yPosBlocks and $zPosBlocks are valid grid coordinates
        if (! $self->checkGridBlock($xPosBlocks, $yPosBlocks, $zPosBlocks)) {

            # The specified gridblock doesn't exist
            return undef;
        }

        # Keys in $self->gridRoomHash are strings in the form 'x_y_z'
        $posn = $xPosBlocks . '_' . $yPosBlocks . '_' . $zPosBlocks;

        # Fetch the room, returning either the model number (if there is a room in this gridblock),
        #   or 'undef' (if there isn't)
        return $self->ivShow('gridRoomHash', $posn);
    }

    sub storeRoom {

        # Called by GA::Obj::WorldModel->addRoom and ->moveRoomsLabels when the world model adds a
        #   room object to this region
        # Update this object's IVs
        #
        # Expected arguments
        #   $roomObj        - The GA::ModelObj::Room to store
        #
        # Return values
        #   'undef' on improper arguments or if the room's proposed location on the grid is invalid
        #   1 otherwise

        my ($self, $roomObj, $check) = @_;

        # Local variables
        my ($posn, $roomNum);

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeRoom', @_);
        }

        # Need to check that room's proposed location are at valid grid coordinates and that there
        #   isn't already a room at the location
        if (
            ! $self->checkGridBlock(
                $roomObj->xPosBlocks,
                $roomObj->yPosBlocks,
                $roomObj->zPosBlocks,
            )
        ) {
            # The specified gridblock doesn't exist
            return undef;
        }

        # Keys in $self->gridRoomHash are strings in the form 'x_y_z'
        $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;

        # If there is already a room at this position, return an error
        #   (also update ->gridRoomTagHash and ->gridRoomGuildHash)
        if ($self->ivExists('gridRoomHash', $posn)) {

            return undef;
        }

        # Store the room by updating ->gridRoomHash
        $self->ivAdd('gridRoomHash', $posn, $roomObj->number);
        # Also update ->gridRoomTagHash and ->gridRoomGuildHash
        if ($roomObj->roomTag) {

            $self->storeRoomTag($roomObj, $posn);
        }

        if ($roomObj->roomGuild) {

            $self->storeRoomGuild($roomObj, $posn);
        }

        return 1;
    }

    sub removeRoom {

        # Called by GA::Obj::WorldModel->deleteRooms and ->moveRoomsLabels when the world model
        #   removes a room object from this region
        # Update this object's IVs
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room to remove
        #
        # Return values
        #   'undef' on improper arguments or if the room object isn't stored in this regionmap
        #   1 otherwise

        my ($self, $roomObj, $check) = @_;

        # Local variables
        my $posn;

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeRoom', @_);
        }

        # Keys in $self->gridRoomHash are strings in the form 'x_y_z'
        $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;

        # Check the room exists in this region
        if (! $self->ivExists('gridRoomHash', $posn)) {

            return undef;

        } else {

            # Remove the room
            $self->ivDelete('gridRoomHash', $posn);

            # If the room has a room tag or room guild, update those IVs, too
            if ($roomObj->roomTag) {

                $self->removeRoomTag($roomObj, $posn);
            }

            if ($roomObj->roomGuild) {

                $self->removeRoomGuild($roomObj, $posn);
            }

            return 1;
        }
    }

    sub storeRoomTag {

        # Called by GA::Obj::WorldModel->setRoomTag and $self->storeRoom when the world model adds
        #   a room tag to this region
        # Update this object's IVs
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room (which has a room tag) to store
        #
        # Optional arguments
        #   $posn       - The room's position in the grid, in the form 'x_y_z' (used as a key in
        #                   $self->gridRoomTagHash). If 'undef', this function works out the
        #                   position
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $posn, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeRoomTag', @_);
        }

        if (! $posn) {

            # Keys in $self->gridRoomTagHash are strings in the form 'x_y_z'
            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
        }

        # Store the room tag, replacing any existing entry
        $self->ivAdd('gridRoomTagHash', $posn, $roomObj->number);

        return 1;
    }

    sub removeRoomTag {

        # Called by GA::Obj::WorldModel->resetRoomTag and $self->removeRoom when the world model
        #   removes a room tag from this region
        # Update this object's IVs
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room (which has a room tag) to remove
        #
        # Optional arguments
        #   $posn       - The room's position in the grid, in the form 'x_y_z' (used as a key in
        #                   $self->gridRoomTagHash). If 'undef', this function works out the
        #                   position
        #
        # Return values
        #   'undef' on improper arguments or if the tagged room isn't stored in this regionmap
        #   1 otherwise

        my ($self, $roomObj, $posn, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeRoomTag', @_);
        }

        if (! $posn) {

            # Keys in $self->gridRoomHash are strings in the form 'x_y_z'
            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
        }

        # Check the tagged room exists in this region
        if (! $self->ivExists('gridRoomTagHash', $posn)) {

            return undef;

        } else {

            # Remove the tagged room
            $self->ivDelete('gridRoomTagHash', $posn);

            return 1;
        }
    }

    sub storeRoomGuild {

        # Called by GA::Obj::WorldModel->setRoomGuild and $self->storeRoom when the world model
        #   adds a room guild to this region
        # Update this object's IVs
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room (which has a room guild) to store
        #
        # Optional arguments
        #   $posn       - The room's position in the grid, in the form 'x_y_z' (used as a key in
        #                   $self->gridRoomGuildHash). If 'undef', this function works out the
        #                   position
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $posn, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeRoomGuild', @_);
        }

        if (! $posn) {

            # Keys in $self->gridRoomGuildHash are strings in the form 'x_y_z'
            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
        }

        # Store the room guild, replacing any existing entry
        $self->ivAdd('gridRoomGuildHash', $posn, $roomObj->number);

        return 1;
    }

    sub removeRoomGuild {

        # Called by GA::Obj::WorldModel->setRoomGuild and $self->removeRoom when the world model
        #   removes a room guild from this region
        # Update this object's IVs
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room (which has a room guild) to remove
        #
        # Optional arguments
        #   $posn       - The room's position in the grid, in the form 'x_y_z' (used as a key in
        #                   $self->gridRoomGuildHash). If 'undef', this function works out the
        #                   position
        #
        # Return values
        #   'undef' on improper arguments or if the room with a guild isn't stored in this regionmap
        #   1 otherwise

        my ($self, $roomObj, $posn, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeRoomGuild', @_);
        }

        if (! $posn) {

            # Keys in $self->gridRoomGuildHash are strings in the form 'x_y_z'
            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
        }

        # Check the room with a guild exists in this region
        if (! $self->ivExists('gridRoomGuildHash', $posn)) {

            return undef;

        } else {

            # Remove the room with a gu ild
            $self->ivDelete('gridRoomGuildHash', $posn);

            return 1;
        }
    }

    sub storeExit {

        # Called by GA::Win::Map->drawExit to store any exit that has been drawn (not necesssarily
        #   every exit belonging to every room in this regionmap). Gets called every time the
        #   exit is drawn. Also called by GA::Obj::WorldModel->moveRoomsLabels
        # Updates this object's IVs
        #
        # Expected arguments
        #   $exitObj        - The GA::Obj::Exit that has been drawn on the map
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeExit', @_);
        }

        # Store the drawn exit
        $self->ivAdd('gridExitHash', $exitObj->number, undef);

        return 1;
    }

    sub removeExit {

        # Called by GA::Obj::WorldModel->deleteExits when the world model removes an exit object
        #   from this region
        # Update this object's IVs
        #
        # Expected arguments
        #   $exitObj     - The GA::Obj::Exit to remove
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeExit', @_);
        }

        # Remove the exit (if the exit hasn't been drawn, there won't be an entry in
        #   ->gridExitHash)
        $self->ivDelete('gridExitHash', $exitObj->number);

        # If the exit has an exit tag, update that IV, too
        if ($exitObj->exitTag) {

            $self->removeExitTag($exitObj);
        }

        # If it's a region exit, remove its entry from ->regionExitHash
        if ($self->ivExists('regionExitHash', $exitObj->number)) {

            $self->ivDelete('regionExitHash', $exitObj->number);
        }

        return 1;
    }

    sub resetExit {

        # Called by GA::Obj::WorldModel->deleteExits when the world model removes an exit object
        #   whose twin exit is in this region
        # If the twin is to be deleted, it hasn't been deleted yet. The calling function makes the
        #   twin an incomplete exit; this function updates this object's IVs to reflect the fact
        #   that the still-existing twin is no longer a region exit
        #
        # Expected arguments
        #   $exitObj     - The still-existing twin GA::Obj::Exit
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetExit', @_);
        }

        # If the exit has an exit tag, update that IV, too
        if ($exitObj->exitTag) {

            $self->removeExitTag($exitObj);
        }

        # If it's a region exit, remove its entry from ->regionExitHash
        if ($self->ivExists('regionExitHash', $exitObj->number)) {

            $self->ivDelete('regionExitHash', $exitObj->number);
        }

        return 1;
    }

    sub storeExitTag {

        # Called by GA::Obj::WorldModel->moveRoomsLabels and ->applyExitTag when the world model
        #   adds an exit tag to this region
        # Updates this object's IVs
        #
        # Expected arguments
        #   $exitObj    - The GA::Obj::Exit (which has an exit tag) to store
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeExitTag', @_);
        }

        # Store the exit tag
        $self->ivAdd('gridExitTagHash', $exitObj->number, undef);

        return 1;
    }

    sub removeExitTag {

        # Called by $self->removeExit and GA::Obj::WorldModel->cancelExitTag when the world model
        #   removes an exit tag from this region
        # Update this object's IVs
        #
        # Expected arguments
        #   $exitObj    - The GA::Obj::Exit (which has an exit tag) to remove
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeExit', @_);
        }

        # Remove the exit tag
        $self->ivDelete('gridExitTagHash', $exitObj->number);

        return 1;
    }

    sub storeLabel {

        # Called by GA::Obj::WorldModel->addLabel and ->moveRoomsLabels when the world model adds a
        #   label to this region
        # Assigns the new label a unique number within this regionmap, and adds the label to
        #   $self->gridLabelHash
        #
        # Expected arguments
        #   $labelObj     - The GA::Obj::MapLabel to store
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $labelObj, $check) = @_;

        # Check for improper arguments
        if (! defined $labelObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeLabel', @_);
        }

        # Allocate the label a unique number
        $self->ivIncrement('labelCount');
        $labelObj->ivPoke('number', $self->labelCount);
        # (->id is in the form 'region-name_label_number', e.g. 'town_42')
        $labelObj->ivPoke('id', $labelObj->region . '_' . $self->labelCount);

        # Store the drawn exit
        $self->ivAdd('gridLabelHash', $labelObj->number, $labelObj);

        return 1;
    }

    sub removeLabel {

        # Called by GA::Obj::WorldModel->deleteLabels and ->moveRoomsLabels when the world model
        #   removes a label from this region
        # Update this object's IVs
        #
        # Expected arguments
        #   $labelObj     - The GA::Obj::MapLabel to remove
        #
        # Return values
        #   'undef' on improper arguments or if the label object isn't stored in this regionmap
        #   1 otherwise

        my ($self, $labelObj, $check) = @_;

        # Check for improper arguments
        if (! defined $labelObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeLabel', @_);
        }

        # Check the label exists in this region
        if (! $self->ivExists('gridLabelHash', $labelObj->number)) {

            return undef;

        } else {

            # Remove the label
            $self->ivDelete('gridLabelHash', $labelObj->number);

            return 1;
        }
    }

    # Functions for $self->gridColourBlockHash, ->gridColourObjHash

    sub fetchSquareInSquare {

        # Called by GA::Win::Map->setColouredSquare
        # Given a single gridblock, return a list of coloured squares that occupy the block
        #   (possible on differently levels)
        #
        # Expected arguments
        #   $xBlocks, $yBlocks
        #               - Grid coordinates of the block to check
        #
        # Optional arguments
        #   $level      - The z-coordinate, matching $self->currentLevel. If not defined, coloured
        #                   blocks/rectangles on all levels are counted
        #
        # Return values
        #   An empty list on improper arguments or if the specified block's position on the grid is
        #       invalid
        #   Otherwise returns a list of keys from $self->gridColourBlockHash, one for each matching
        #       square (the keys are strings in the form 'x_y_z' or 'x_y')

        my ($self, $xBlocks, $yBlocks, $level, $check) = @_;

        # Local variables
        my (@emptyList, @returnList);

        # Check for improper arguments
        if (! defined $xBlocks || ! defined $yBlocks || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->fetchSquareInSquare', @_);
            return @emptyList;
        }

        # Check that the coordinates are valid grid coordinates
        if (! $self->checkGridBlock($xBlocks, $yBlocks, $self->currentLevel)) {

            # The specified gridblock doesn't exist
            return undef;
        }

        # Count coloured blocks on the specified gridblock, across all levels
        foreach my $coord ($self->ivKeys('gridColourBlockHash')) {

            # $coord is in the form 'x_y_z' or 'x_y', for coloured blocks shown on every level
            my ($thisX, $thisY, $thisZ) = split(/_/, $coord);

            if (
                $thisX == $xBlocks
                && $thisY == $yBlocks
                && (
                    ! defined $thisZ
                    || ! defined $level
                    || $thisZ == $level
                )
            ) {
                push (@returnList, $coord);
            }
        }

        return @returnList;
    }

    sub fetchSquareInArea {

        # Called by GA::Win::Map->setColouredRect
        # Given a rectangular area of the grid (which can be as small as a single gridblock),
        #   return a list of coloured squares that occupy a block within the area
        #
        # Expected arguments
        #   $x1, $y1, $x2, $y2
        #               - Grid coordinates of opposite corners (top-left, then bottom-right) of the
        #                   rectangular area. $x1 and $x2 can be the same, and $y1 and $y2 can
        #                   be the same. If both pairs are the same, it's a single gridblock (this
        #                   should never happen, but is not forbidden)
        #
        # Optional arguments
        #   $level      - The z-coordinate, matching $self->currentLevel. If not defined, coloured
        #                   blocks/rectangles on all levels are counted
        #
        # Return values
        #   An empty list on improper arguments or if the rectangular area's position on the grid is
        #       invalid
        #   Otherwise returns a list of keys from $self->gridColourBlockHash, one for each matching
        #       square (the keys are strings in the form 'x_y_z' or 'x_y')

        my ($self, $x1, $y1, $x2, $y2, $level, $check) = @_;

        # Local variables
        my (@emptyList, @returnList);

        # Check for improper arguments
        if (! defined $x1 || ! defined $y1 || ! defined $x2 || ! defined $y2 || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->fetchSquareInArea', @_);
            return @emptyList;
        }

        # Check that both corners of the rectangle are valid grid coordinates
        if (
            ! $self->checkGridBlock($x1, $y1, $self->currentLevel)
            || ! $self->checkGridBlock($x2, $y2, $self->currentLevel)
        ) {
            # The specified gridblock(s) don't exist
            return @emptyList;
        }

        # If the two corners are the wrong way around, swap them
        if ($x1 > $x2) {

            ($x1, $x2) = ($x2, $x1);
        }

        if ($y1 > $y2) {

            ($y1, $y2) = ($y2, $y1);
        }

        # Count coloured blocks in the rectangular area
        foreach my $coord ($self->ivKeys('gridColourBlockHash')) {

            # $coord is in the form 'x_y_z' or 'x_y', for coloured blocks shown on every level
            my ($thisX, $thisY, $thisZ) = split(/_/, $coord);

            if (
                $thisX >= $x1
                && $thisX <= $x2
                && $thisY >= $y1
                && $thisY <= $y2
                && (
                    ! defined $thisZ
                    || ! defined $level
                    || $thisZ == $level
                )
            ) {
                push (@returnList, $coord);
            }
        }

        return @returnList;
    }

    sub storeSquare {

        # Called by GA::Win::Map->setColouredSquare
        # Update this object's IVs
        #
        # Expected arguments
        #   $colour     - The block's colour
        #   $xBlocks, $yBlocks
        #               - The block's grid coordinates
        #
        # Optional arguments
        #   $level      - The z-coordinate, matching $self->currentLevel. If not defined, the
        #                   coloured block is visible on every level
        #
        # Return values
        #   'undef' on improper arguments or if the block's proposed location on the grid is invalid
        #   1 otherwise

        my ($self, $colour, $xBlocks, $yBlocks, $level, $check) = @_;

        # Local variables
        my $coord;

        # Check for improper arguments
        if (! defined $colour || ! defined $xBlocks || ! defined $yBlocks || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeSquare', @_);
        }

        # Check that the coordinates are valid grid coordinates
        if (! $self->checkGridBlock($xBlocks, $yBlocks, $self->currentLevel)) {

            # The specified gridblock doesn't exist
            return undef;
        }

        # Store the block by updating the IV
        $coord = $xBlocks . '_' . $yBlocks;
        if (defined $level) {

            $coord .= '_' . $level;
        }

        $self->ivAdd('gridColourBlockHash', $coord, $colour);

        return 1;
    }

    sub removeSquare {

        # Called by GA::Win::Map->setColouredSquare and ->setColouredRect
        # Updates this object's IVs
        #
        # Expected arguments
        #   $coord  - A string representing the coloured block's coordinates, matching a key in
        #               $self->gridColourBlockHash
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $coord, $check) = @_;

        # Check for improper arguments
        if (! defined $coord || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeSquare', @_);
        }

        $self->ivDelete('gridColourBlockHash', $coord);

        return 1;
    }

    sub fetchRectInSquare {

        # Called by GA::Win::Map->setColouredSquare
        # Given a single gridblock, return a list of coloured rectangles that occupy the block
        #   (possible on differently levels)
        #
        # Expected arguments
        #   $xBlocks, $yBlocks
        #               - Grid coordinates of the block to check
        #
        # Optional arguments
        #   $level      - The z-coordinate, matching $self->currentLevel. If not defined, coloured
        #                   blocks/rectangles on all levels are counted
        #
        # Return values
        #   An empty list on improper arguments or if the specified block's position on the grid is
        #       invalid
        #   Otherwise returns a list of GA::Obj::GridColour objects, one for each rectangle
        #       occupying the specified block (may be an empty list)

        my ($self, $xBlocks, $yBlocks, $level, $check) = @_;

        # Local variables
        my (@emptyList, @returnList);

        # Check for improper arguments
        if (! defined $xBlocks || ! defined $yBlocks || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->fetchRectInSquare', @_);
            return @emptyList;
        }

        # Check that the coordinates are valid grid coordinates
        if (! $self->checkGridBlock($xBlocks, $yBlocks, $self->currentLevel)) {

            # The specified gridblock doesn't exist
            return undef;
        }

        # Count coloured rectangles in the rectangular area
        foreach my $obj ($self->ivValues('gridColourObjHash')) {

            if (
                $xBlocks >= $obj->x1
                && $xBlocks <= $obj->x2
                && $yBlocks >= $obj->y1
                && $yBlocks <= $obj->y2
                && (
                    ! defined $level
                    || ! defined $obj->level
                    || $level == $obj->level
                )
            ) {
                push (@returnList, $obj);
            }
        }

        return @returnList;
    }

    sub fetchRectInArea {

        # Called by GA::Win::Map->setColouredRect
        # Given a rectangular area of the grid (which can be as small as a single gridblock),
        #   return a list of coloured rectangles that occupy the same area, wholly or partially
        #
        # Expected arguments
        #   $x1, $y1, $x2, $y2
        #               - Grid coordinates of opposite corners (top-left, then bottom-right) of the
        #                   rectangular area. $x1 and $x2 can be the same, and $y1 and $y2 can
        #                   be the same. If both pairs are the same, it's a single gridblock (this
        #                   should never happen, but is not forbidden)
        #
        # Optional arguments
        #   $level      - The z-coordinate, matching $self->currentLevel. If not defined, coloured
        #                   blocks/rectangles on all levels are counted
        #
        # Return values
        #   An empty list on improper arguments or if the rectangular area's position on the grid is
        #       invalid
        #   Otherwise returns a list of GA::Obj::GridColour objects, one for each rectangle
        #       occupying part of the rectangular area (may be an empty list)

        my ($self, $x1, $y1, $x2, $y2, $level, $check) = @_;

        # Local variables
        my (@emptyList, @returnList);

        # Check for improper arguments
        if (! defined $x1 || ! defined $y1 || ! defined $x2 || ! defined $y2 || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->fetchRect', @_);
            return @emptyList;
        }

        # Check that both corners of the rectangle are valid grid coordinates
        if (
            ! $self->checkGridBlock($x1, $y1, $self->currentLevel)
            || ! $self->checkGridBlock($x2, $y2, $self->currentLevel)
        ) {
            # The specified gridblock(s) don't exist
            return @emptyList;
        }

        # If the two corners are the wrong way around, swap them
        if ($x1 > $x2) {

            ($x1, $x2) = ($x2, $x1);
        }

        if ($y1 > $y2) {

            ($y1, $y2) = ($y2, $y1);
        }

        # Count coloured rectangles in the rectangular area
        foreach my $obj ($self->ivValues('gridColourObjHash')) {

            if (
                (
                    # Occupy the same 2-dimensional space
                    ($x1 >= $obj->x1 && $x1 <= $obj->x2)
                    || ($x2 >= $obj->x1 && $x2 <= $obj->x2)
                ) && (
                    ($y1 >= $obj->y1 && $y1 <= $obj->y2)
                    || ($y2 >= $obj->y1 && $y2 <= $obj->y2)
                ) && (
                    # Occupy the same level
                    ! defined $level
                    || ! defined $obj->level
                    || $level == $obj->level
                )
            ) {
                push (@returnList, $obj);
            }
        }

        return @returnList;
    }

    sub storeRect {

        # Called by GA::Win::Map->setColouredRect
        # Update this object's IVs
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $colour     - The rectangle's colour
        #   $x1, $y1, $x2, $y2
        #               - Grid coordinates of opposite corners (top-left, then bottom-right) of the
        #                   coloured rectangle. $x1 and $x2 can be the same, and $y1 and $y2 can
        #                   be the same. If both pairs are the same, it's a single gridblock (this
        #                   should never happen, but is not forbidden)
        #
        # Optional arguments
        #   $level      - The z-coordinate, matching $self->currentLevel. If not defined, the
        #                   coloured rectangle is visible on every level
        #
        # Return values
        #   'undef' on improper arguments or if the rectangles's proposed location on the grid is
        #       invalid
        #   Otherwise returns the GA::Obj::GridColour object created

        my ($self, $session, $colour, $x1, $y1, $x2, $y2, $level, $check) = @_;

        # Local variables
        my $colourObj;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $colour || ! defined $x1 || ! defined $y1
            || ! defined $x2 || ! defined $y2 || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeRect', @_);
        }

        # Check that both corners of the rectangle are valid grid coordinates
        if (
            ! $self->checkGridBlock($x1, $y1, $self->currentLevel)
            || ! $self->checkGridBlock($x2, $y2, $self->currentLevel)
        ) {
            # The specified gridblock(s) don't exist
            return undef;
        }

        # If the two corners are the wrong way around, swap them
        if ($x1 > $x2) {

            ($x1, $x2) = ($x2, $x1);
        }

        if ($y1 > $y2) {

            ($y1, $y2) = ($y2, $y1);
        }

        # Coloured rectangles can be drawn on top of each other, but coloured blocks cannot
        # Import the IV (for speed) and check every coloured square
        foreach my $coord ($self->ivKeys('gridColourBlockHash')) {

            # $coord is in the form 'x_y_z' or 'x_y', for coloured blocks shown on every level
            my ($thisX, $thisY, $thisZ) = split(/_/, $coord);

            if (
                $thisX >= $x1
                && $thisX <= $x2
                && $thisY >= $y1
                && $thisY <= $y2
                && (
                    ! defined $thisZ
                    || ! defined $level
                    || $thisZ == $level
                )
            ) {
                # This coloured block occupies part of the space that the rectangle wants, so don't
                #   draw the rectangle
                return undef;
            }
        }

        # Create a new grid colour object
        $colourObj = Games::Axmud::Obj::GridColour->new(
            $session,
            $self->ivIncrement('colourObjCount'),
            $colour,
            $x1, $y1,
            $x2, $y2,
            $level,
        );

        if (! $colourObj) {

            return undef;
        }

        # Store the rectangle by updating the IV
        $self->ivAdd('gridColourObjHash', $colourObj->number, $colourObj);

        return $colourObj;
    }

    sub removeRect {

        # Called by GA::Win::Map->setColouredSquare and ->setColouredRect
        # Updates this object's IVs
        #
        # Expected arguments
        #   $obj    - The GA::Obj::GridColour to remove
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeRect', @_);
        }

        $self->ivDelete('gridColourObjHash', $obj->number);

        return 1;
    }

    # Functions for $self->regionExitHash, ->regionPathHash, ->safeRegionPathHash

    sub storeRegionExit {

        # Called by GA::Obj::WorldModel->updateRegionPaths to store a region exit
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $exitObj    - The GA::Obj::Exit to store (a region exit)
        #
        # Return values
        #   'undef' on improper arguments or if $exitObj is not a region exit with a destination
        #       room set
        #   1 otherwise

        my ($self, $session, $exitObj, $check) = @_;

        # Local variables
        my $destRoomObj;

        # Check for improper arguments
        if (! defined $session || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeRegionExit', @_);
        }

        # Check that it's really a region exit with a destination room set
        if (! $exitObj->regionFlag || ! $exitObj->destRoom || $exitObj->randomType ne 'none') {

            return undef;
        }

        # Get the exit's destination region
        $destRoomObj = $session->worldModelObj->ivShow('modelHash', $exitObj->destRoom);

        # Store the drawn exit
        $self->ivAdd('regionExitHash', $exitObj->number, $destRoomObj->parent);

        return 1;
    }

    sub removeRegionExit {

        # Called by GA::Obj::WorldModel->updateRegionPaths to remove a stored region exit
        #
        # Expected arguments
        #   $exitObj     - The GA::Obj::Exit to remove
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeRegionExit', @_);
        }

        # Remove the exit, if it is stored
        $self->ivDelete('regionExitHash', $exitObj->number);

        return 1;
    }

    sub storePath {

        # Called by GA::Obj::WorldModel->connectRegionExits and ->replaceRegionPath to add a region
        #   path to one (but not both) of the IVs ->regionPathHash and ->safeRegionPathHash
        #
        # Expected arguments
        #   $iv                     - Which hash IV should be used to store the region path:
        #                               'regionPathHash' or 'safeRegionPathHash'
        #   $exitObj, $exitObj2     - The exit objects at each end of the path
        #   $pathObj                - The GA::Obj::RegionPath object which connects the two exits
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $exitObj, $exitObj2, $pathObj, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $iv || ! defined $exitObj || ! defined $exitObj2 || ! defined $pathObj
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->storePath', @_);
        }

        # Store the path objects
        $self->ivAdd(
            $iv,
            $exitObj->number . '_' . $exitObj2->number,
            $pathObj,
        );

        return 1;
    }

    sub removePaths {

        # Called by GA::Obj::WorldModel->updateRegionPaths and ->replaceRegionPath to remove a
        #   region path from one or both of the IVs ->regionPathHash and ->safeRegionPathHash
        #
        # Expected arguments
        #   $exitString     - A string describing the region path to remove (a key in one of the
        #                       hash IVs ->regionPathHash and ->safeRegionPathHash)
        #
        # Optional arguments
        #   $iv             - If specified, set to 'regionPathHash' or 'safeRegionPathHash'. If
        #                       not specified, the region path is removed from both hash IVs
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitString, $iv, $check) = @_;

        # Check for improper arguments
        if (! defined $exitString || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removePaths', @_);
        }

        # Remove the region path from one or both hash IVs
        if (! $iv || $iv eq 'regionPathHash') {

            $self->ivDelete('regionPathHash', $exitString);
        }

        if (! $iv || $iv eq 'safeRegionPathHash') {

            $self->ivDelete('safeRegionPathHash', $exitString);
        }

        return 1;
    }

    sub resetPaths {

        # Called by GA::Obj::WorldModel->recalculateRegionPaths
        # Empties the regionmap's list of region paths, so that new ones can be calculated
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetPaths', @_);
        }

        # Empty the region path hash IVs
        $self->ivEmpty('regionPathHash');
        $self->ivEmpty('safeRegionPathHash');

        return 1;
    }

    # Functions for $self->livingCountHash, ->nonLivingCountHash

    sub resetCounts {

        # Called by GA::Obj::WorldModel->resetRegionCounts
        # Empties the ->livingCountHash and ->nonLivingCountHash IVs (for compatibility with
        #   other functions modifying these IVs, we'll provide a separate function for doing it)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetCounts', @_);
        }

        # Update the IVs
        $self->ivEmpty('livingCountHash');
        $self->ivEmpty('nonLivingCountHash');

        return 1;
    }

    sub storeLivingCount {

        # Called by GA::Obj::WorldModel->moveRoomsLabels and ->countRoomContents and to update this
        #   region's count of living beings
        #
        # Expected arguments
        #   $roomNum    - The number of the model room whose count of living beings is being updated
        #
        # Optional arguments
        #   $count      - The number of living beings in this room. If zero or 'undef', no entry is
        #                   added (we don't need to track rooms with no living beings)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomNum, $count, $check) = @_;

        # Check for improper arguments
        if (! defined $roomNum || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeLivingCount', @_);
        }

        # Update the IV
        if ($count) {

            $self->ivAdd('livingCountHash', $roomNum, $count);
        }

        return 1;
    }

    sub removeLivingCount {

        # Called by GA::Obj::WorldModel->deleteRooms, moveRoomsLabels and ->countRoomContents to
        #   update this region's count of living beings
        #
        # Expected arguments
        #   $roomNum    - The number of the model room whose count of living beings is being updated
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the current number of living beings stored for this room (may be
        #       zero)

        my ($self, $roomNum, $check) = @_;

        # Local variables
        my $count;

        # Check for improper arguments
        if (! defined $roomNum || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeLivingCount', @_);
        }

        # Get the current number of living beings stored
        if ($self->ivExists('livingCountHash', $roomNum)) {

            $count = $self->ivShow('livingCountHash', $roomNum);

            # If there are no living beings in the room, there will be no entry in ->livingCountHash
            #   but we still need to return an explicit zero
            if (! $count) {

                $count = 0;
            }
        }

        # Update the IV
        if ($count) {

            $self->ivDelete('livingCountHash', $roomNum);
        }

        return $count;
    }

    sub storeNonLivingCount {

        # Called by GA::Obj::WorldModel->moveRoomsLabels and ->countRoomContents to update this
        #   region's count of non-living beings
        #
        # Expected arguments
        #   $roomNum    - The number of the model room whose count of non-living beings is being
        #                   updated
        #
        # Optional arguments
        #   $count      - The number of non-living beings in this room. If zero or 'undef', no entry
        #                   is added (we don't need to track rooms with no non-living beings)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomNum, $count, $check) = @_;

        # Check for improper arguments
        if (! defined $roomNum || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeNonLivingCount', @_);
        }

        # Update the IV
        if ($count) {

            $self->ivAdd('nonLivingCountHash', $roomNum, $count);
        }

        return 1;
    }

    sub removeNonLivingCount {

        # Called by GA::Obj::WorldModel->deleteRooms, ->moveRoomsLabels and ->countRoomContents to
        #   update this region's count of non-living beings
        #
        # Expected arguments
        #   $roomNum    - The number of the model room whose count of non-living beings is being
        #                   updated
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the current number of non-living beings stored for this room (may be
        #       zero)

        my ($self, $roomNum, $check) = @_;

        # Local variables
        my $count;

        # Check for improper arguments
        if (! defined $roomNum || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeNonLivingCount', @_);
        }

        # Get the current number of non-living beings stored
        if ($self->ivExists('nonLivingCountHash', $roomNum)) {

            $count = $self->ivShow('nonLivingCountHash', $roomNum);

            # If there are no non-living beings in the room, there will be no entry in
            #   ->livingCountHash, but we still need to return an explicit zero
            if (! $count) {

                $count = 0;
            }
        }

        # Update the IV
        if ($count) {

            $self->ivDelete('nonLivingCountHash', $roomNum);
        }

        return $count;
    }

    # Other functions

    sub getGridCentre {

        # Can be called by anything
        # Finds the grid coordinates of the centre of the regionmap's grid
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   The list (0, 0, 0) on improper arguments
        #   Otherwise, returns a list containing the coordinates of the centre of the grid, in the
        #       form (x, y, z)

        my ($self, $check) = @_;

        # Local variables
        my ($xPosBlocks, $yPosBlocks, $zPosBlocks);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getGridCentre', @_);
            return (0, 0, 0);
        }

        $xPosBlocks = int (($self->gridWidthBlocks) / 2);
        $yPosBlocks = int (($self->gridHeightBlocks) / 2);
        $zPosBlocks = 0;    # 'Ground' level

        return ($xPosBlocks, $yPosBlocks, $zPosBlocks);
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub number
        { $_[0]->{number} }

    sub magnification
        { $_[0]->{magnification} }
    sub scrollXPos
        { $_[0]->{scrollXPos} }
    sub scrollYPos
        { $_[0]->{scrollYPos} }
    sub maxZoomOutXFlag
        { $_[0]->{maxZoomOutXFlag} }
    sub maxZoomOutYFlag
        { $_[0]->{maxZoomOutYFlag} }

    sub gridWidthBlocks
        { $_[0]->{gridWidthBlocks} }
    sub gridHeightBlocks
        { $_[0]->{gridHeightBlocks} }
    sub blockWidthPixels
        { $_[0]->{blockWidthPixels} }
    sub blockHeightPixels
        { $_[0]->{blockHeightPixels} }
    sub roomWidthPixels
        { $_[0]->{roomWidthPixels} }
    sub roomHeightPixels
        { $_[0]->{roomHeightPixels} }
    sub mapWidthPixels
        { $_[0]->{mapWidthPixels} }
    sub mapHeightPixels
        { $_[0]->{mapHeightPixels} }

    sub regionScheme
        { $_[0]->{regionScheme} }

    sub drawExitMode
        { $_[0]->{drawExitMode} }
    sub obscuredExitFlag
        { $_[0]->{obscuredExitFlag} }
    sub obscuredExitRedrawFlag
        { $_[0]->{obscuredExitRedrawFlag} }
    sub obscuredExitRadius
        { $_[0]->{obscuredExitRadius} }
    sub drawOrnamentsFlag
        { $_[0]->{drawOrnamentsFlag} }

    sub currentLevel
        { $_[0]->{currentLevel} }
    sub highestLevel
        { $_[0]->{highestLevel} }
    sub lowestLevel
        { $_[0]->{lowestLevel} }

    sub gridRoomHash
        { my $self = shift; return %{$self->{gridRoomHash}}; }
    sub gridRoomTagHash
        { my $self = shift; return %{$self->{gridRoomTagHash}}; }
    sub gridRoomGuildHash
        { my $self = shift; return %{$self->{gridRoomGuildHash}}; }
    sub gridExitHash
        { my $self = shift; return %{$self->{gridExitHash}}; }
    sub gridExitTagHash
        { my $self = shift; return %{$self->{gridExitTagHash}}; }
    sub gridLabelHash
        { my $self = shift; return %{$self->{gridLabelHash}}; }

    sub labelCount
        { $_[0]->{labelCount} }

    sub gridColourBlockHash
        { my $self = shift; return %{$self->{gridColourBlockHash}}; }
    sub gridColourObjHash
        { my $self = shift; return %{$self->{gridColourObjHash}}; }
    sub colourObjCount
        { $_[0]->{colourObjCount} }

    sub regionExitHash
        { my $self = shift; return %{$self->{regionExitHash}}; }
    sub regionPathHash
        { my $self = shift; return %{$self->{regionPathHash}}; }
    sub safeRegionPathHash
        { my $self = shift; return %{$self->{safeRegionPathHash}}; }

    sub livingCountHash
        { my $self = shift; return %{$self->{livingCountHash}}; }
    sub nonLivingCountHash
        { my $self = shift; return %{$self->{nonLivingCountHash}}; }
}

# Package must return a true value
1
