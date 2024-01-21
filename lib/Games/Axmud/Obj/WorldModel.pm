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
# Games::Axmud::Obj::WorldModel
# Handles the world model

{ package Games::Axmud::Obj::WorldModel;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->setupProfiles
        # Create a new instance of the (main) world model object
        #
        # Expected arguments
        #   $session    - The calling GA::Session (not stored as an IV)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'world_model',
            _objClass                   => $class,
            _parentFile                 => 'worldmodel',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => TRUE,        # All IVs are private

            # Main IVs
            # --------

            # Four IVs to allow an author to claim ownership of their maps
            author                      => undef,       # Max 128 chars
            date                        => undef,       # Max 64 chars
            version                     => undef,       # Max 64 chars
            descripList                 => [],          # Lines Displayed in a TextView

            # Four additional IVs not set by the user
            # The actual date on which this world model was created. This IV was added in v1.0.223,
            #   so for models created before that, the date of the original Axmud release (Thu 31
            #   July 2014) is used
            modelCreationDate           => $axmud::CLIENT->localDate(),
            # The Axmud version when this world model was created. This IV was added in v1.0.223, so
            #   for models created before that, the value is set to 1.0.0 by
            #   GA::Obj::File->updateExtractedData
            modelCreationVersion        => $axmud::VERSION,
            # Flag set to TRUE if the world model has been converted from another client, set to
            #   FALSE otherwise. (This IV is not currently used, but might be, in the future, so
            #   that early attemps to convert files can be corrected by later versions)
            modelConvertedFlag          => FALSE,
            # The other client's version, set if known ('undef' otherwise)
            modelConvertedVersion       => undef,
            # Large world models can cause 'out of memory' errors on low-spec machines. The
            #   problem is not that the world model takes up too much memory, but that the Perl
            #   Storable module struggles to load very large files into memory
            # Since v1.1.529, the world model is saved either as a monolithic file (as previously),
            #   or as multiple files, all of which are handled by a single file object
            # The number of files used to store this world model, the last time it was saved. If 0,
            #   a single monolithic file was used
            modelSaveFileCount          => 0,

            # IVs for the world model
            # -----------------------

            # Axmud creates a 'model' of the world. Each object in the model has a unique number.
            #   The first object created is #1. When objects are deleted from the model, the number
            #   is available for re-use
            # Types of model objects are: 'region' (an area of a world), 'room' (a location in the
            #   world), 'weapon' (all weapon objects), 'armour' (all protective objects), 'garments'
            #   (all wearable non-protective objects), 'char' (for player characters), 'minion' (for
            #   non-player characters/NPCs controlled by the user), 'sentient' (for NPCs capable of
            #   speech, at least in theory), 'creature' (for NPCS not capable of speech, at least in
            #   theory) 'portable' (for all non-living things that can, in theory, be picked up),
            #   'decoration' (for all non-living things that can not, in theory, be picked up),
            #   'custom' (any other kind of object)
            #
            # Model objects have a core set of properties set by GA::Generic::ModelObj
            # Some groups of objects have their own set of shared properties also set by
            #   GA::Generic::ModelObj
            # Alongside the world model is an exit model, which contains all exits used by rooms in
            #   the model. Every exit has a unique number in the exit model. The first exit created
            #   is #1
            # World model commands use the following switches:
            #   -n region, -r room, -w weapon, -a armour, -g garment, -c char, -m minion,
            #   -s sentient, -k creature, -p portable, -d decoration, -u custom, -x exit
            #
            # Model objects are all given a ->name (max length 32 chars). For room model objects,
            #   the name is the brief description (if available), or a shortened version of the
            #   verbose description (if not). Names do not have to be unique (except for regions and
            #   characters; e.g. there can only be one GA::ModelObj::Char whose ->name is 'Gandalf')
            #
            # Model objects can have a parent model object and any number of child model objects.
            #   In general, parent objects are used to 'contain' child objects. The rules for
            #   parents/children are:
            #   1. Regions can have no parent, or their parent can be another region
            #   2. Regions can have no children, or can have any model object(s) as children
            #       (including other regions)
            #   3. Rooms must have a region parent; there are no orphan rooms
            #   4. Rooms can have no children, or can have any model object(s) as children (except
            #       regions and rooms, which cannot be children of a room)
            #   5. Other model objects can have no parent or children, or can have any model
            #       object(s) as parents or children
            #   6. No model object can have itself as a parent or child
            # Exit objects in the exit model have different rules:
            #   1. Exit model objects always have a parent room, and never have children
            #   2. The parent room doesn't count its exits as being one of its children
            #
            # The world model itself. A hash in the form
            #   $modelHash{number} = blessed_reference_to_model_object
            modelHash                   => {},
            # For convenience, registry hashes of all categories of model object. If these hashes
            #   were combined, the combined hash would be exactly the same as $self->modelHash
            regionModelHash             => {},
            roomModelHash               => {},
            weaponModelHash             => {},
            armourModelHash             => {},
            garmentModelHash            => {},
            charModelHash               => {},
            minionModelHash             => {},
            sentientModelHash           => {},
            creatureModelHash           => {},
            portableModelHash           => {},
            decorationModelHash         => {},
            customModelHash             => {},
            #
            # The number of objects in $self->modelHash (included deleted objects whose ->number has
            #   not been re-used)
            modelObjCount               => 0,
            # The number of objects in $self->modelHash (doesn't include deleted objects, so this
            #   value is the actual number of objects it contains)
            modelActualCount            => 0,
            # Deleted objects can have their numbers re-used. This list contains the numbers of all
            #   deleted objects which haven't yet been reused; when a new model object is created,
            #   it gets a number from the first element in this list. If the list is empty, the
            #   number used is $self->modelObjCount + 1
            modelDeletedList            => [],
            # To avoid having an object being deleted and having its number almost immediately
            #   re-used - which could cause an unintentional error, if an old object is confused for
            #   a new one - $self->deleteObj stores the numbers of deleted objects here,
            #   temporarily
            # GA::Session->spinMaintainLoop calls $self->updateModelBuffers, which copies them
            #   into $self->modelDeletedList on every spin of the loop. In this way, numbers don't
            #   become available for re-use until after an operation is complete
            modelBufferList             => [],
            # Number of the most recently-created model object (may since have been deleted from the
            #   model; 'undef' if no object ever deleted)
            mostRecentNum               => undef,

            # The exit model
            # Model objects have a ->name, but exit model objects use ->dir as an equivalent. The
            #   maximum length is 32 chars. Hash in the form
            #   $exitModelHash{number} = blessed_reference_to_exit_object
            exitModelHash               => {},
            # The number of exit objects in $self->exitModelHash (includes deleted exit objects
            #   whose ->number has not been re-used)
            exitObjCount                => 0,
            # The number of exit objects in $self->exitModelHash (doesn't include deleted exit
            #   objects, so this value is the actual number of exit objects it contains)
            exitActualCount             => 0,
            # Deleted exit objects can have their numbers re-used. This list contains the numbers of
            #   all deleted exit objects which haven't yet been reused; when a new model object is
            #   created, it gets a number from the first element in this list. If the list is empty,
            #   the number used is $self->exitObjCount + 1
            exitDeletedList             => [],
            # To avoid having an exit being deleted and having its number almost immediately
            #   re-used - which could cause an unintentional error, if an old exit is confused for
            #   a new one - $self->deleteExits stores the numbers of deleted exits here,
            #   temporarily
            # GA::Session->spinMaintainLoop calls $self->updateModelBuffers, which copies them
            #   into $self->exitDeletedList on every spin of the loop. In this way, numbers don't
            #   become available for re-use until after an operation is complete
            exitBufferList              => [],
            # Number of the most recently-created exit object (may since have been deleted from the
            #   model; 'undef' if no exit object ever deleted)
            mostRecentExitNum           => undef,

            # Hash of GA::Obj::Regionmap objects, in the form
            #   $regionmapHash{'region_name'} = blessed_reference_to_regionmap_object
            regionmapHash               => {},
            # Flag set to TRUE, if the list of regions in the treeview should be displayed in
            #   reverse alphabetical order (set to FALSE to display them in the normal order)
            reverseRegionListFlag       => FALSE,
            # The name of the region which should be displayed at the top of the list (even if the
            #   list is reversed). If set to 'undef', no region is automatically shown at the top of
            #   the list
            firstRegion                 => undef,

            # IVs which set how the automapper window handles pre-drawing of regions
            # Flag set to TRUE if pre-drawing should occur at all, FALSE if no pre-drawing should
            #   occur
            preDrawAllowFlag            => TRUE,
            # When the automapper opens, check all regions; any that have this many rooms in them
            #   are added to the queue to be drawn by background processes (i.e. regular calls to
            #   GA::Win::Map->winUpdate)
            # Must be an integer, 0 or above. If 0, all regions are added to the queue
            # If $self->firstRegion is set and it contains the minimum number of rooms, it's added
            #   to the queue first
            preDrawMinRooms             => 500,
            # When a new current region is set, the old current region's canvas widget and canvas
            #   objects are retained in memory, so they don't have to be redrawn again, if they
            #   contain at least this many rooms
            # Must be an integer, 0 or above. If 0, all regions are retained in memory
            # Otherwise, the canvas objects are destroyed and the canvas widgets are recycled for
            #   the next region which doesn't have at least this many rooms
            preDrawRetainRooms          => 500,
            # What percentage of the available processor time should be allocated to pre-drawing
            #   operations
            # The value is in the range 1-100. For efficiency, the value is approximate, so
            #   changing 50 to 51 will have absolutely no effect, but changing 50 to 70 will. If
            #   someone were to change the value to 0 (for some reason), some amount of pre-drawing
            #   would still occur
            preDrawAllocation           => 50,

            # An additional hash for character model objects. Contains exactly the same number
            #   of entries as $self->charModelHash, but this hash is in the form
            #   $knownCharHash{name} = blessed_reference_to_character_model_object
            # Used to make sure that character model objects don't have duplicate names (i.e. you
            #   can't have two character objects whose ->name is 'Gandalf')
            knownCharHash               => {},
            # A collection of 'minion strings', where several minion strings (e.g. 'hairy orc',
            #   'hairy orcs', 'Glob the orc') may represent the same minion model object
            # Unlike $self->minionModelHash, this hash can only contain one key-value pair for each
            #   possible minion string. Also, the value may be a model object or a non-model object;
            #   in either case, it's possible to compare the object against other model/non-model
            #   objects, to see if they match
            # Minion strings are case-insensitive
            # Hash in the form
            #   $minionStringHash{minion_string} = blessed_reference_to_minion_model_object
            minionStringHash            => {},

            # Light statuses
            # Some worlds use different verbose descriptions depending on the the time of day, or
            #   how much light there is - for example, one description during the day, and another
            #   at night
            # A light status describes how much light there is currently. There are three standard
            #   values: 'day' (the default value - corresponding to the description seen during the
            #   day), 'night' (the description seen at night, when the light is dimmer or
            #   non-existent), 'dark' (the description seen when there is no light at all, for
            #   example when underground - if it's different from that used at night)
            # Each light status has a maximum length of 16 chars
            # Room model objects in the world model store 1 or more descriptions. When new room
            #   model objects are created, the first description added is marked as belonging to the
            #   light status defined by this IV
            lightStatus                 => 'day',
            # List of standard light statuses (never altered)
            constLightStatusList        => [
                'day', 'night', 'dark',
            ],
            # Customised list of light statuses (can be modified)
            lightStatusList             => [],          # Set below

            # Room tags
            # Rooms can be given a short name, usually displayed next to the room on the map. These
            #   are called room tags. The maximum size is 16 characters
            # Room tags are unique - a room tag called 'tower' can either belong to no room at all,
            #   or a single room. However, room tags are case-insensitive - you can refer to a
            #   room's tag as 'tower', 'TOWER' or 'tOwEr', if you like. (Room tags are stored in
            #   lower-case letters, i.e. 'tower')
            # Each room object also has its own ->roomTag IV, set to 'undef' if the room doesn't
            #   have a room tag
            # This hash stores all room tags currently in use, in the form
            #   $roomTagHash{room_tag} = model_number_of_room
            # NB GA::Obj::Route objects also use room tags. It's up to the user to ensure that world
            #   model room tags are equivalent to the tags used in their route objects; by the same
            #   token, adding or deleting a route does not change the contents of $self->roomTagHash
            #   (in fact, the world model isn't informed at all)
            roomTagHash                 => {},

            # Teleport hash
            # Using this hash, the client command ';teleport <destination>' is converted into a
            #   world command in order to teleport to a certain destination (assuming that the
            #   teleport ability might be available at many departure locations)
            # In this hash, the keys are <destination>, and the corresponding values are the
            #   command to get there
            #   e.g. $teleportHash{tower} = 'goto /domains/town/room/start'
            #   e.g. $teleportHash{2} = 'goto /domains/town/room/start'
            #
            # If the destination ('tower' in the example above) exists as a room tag in the world
            #   model, or if it is the number of a world model room ('2' in the example above), the
            #   automapper/Locator task assume that this is the target destination. Otherwise, the
            #   target destination is unknown, and the automapper will get lost
            # If the user types ';teleport tower', and the key 'tower' is not found in this hash,
            #   the highest-priority command cage's standard command 'teleport' is used instead.
            #   Assuming that the standard command is in the form 'teleport room', the word 'room'
            #   is replaced with the destination specified by the user. If it's a recognised room
            #   tag, the automapper/Locator task assume that this room is the target destination
            #   (world model room numbers can't be used in this case). Otherwise, the target
            #   destination is unknown, and the automapper will get lost
            teleportHash                => {},

            # IVs used to draw maps
            # ---------------------

            # Should the Automapper window open automatically when Axmud starts? (TRUE for yes,
            #   FALSE for no)
            autoOpenWinFlag             => FALSE,
            # Should the Automapper window open inside the session's 'main' window, if possible, and
            #   open as a normal 'grid' window, if not possible? (TRUE for yes, FALSE for no)
            pseudoWinFlag               => TRUE,
            # When the Automapper window opens, which parts of it should be visible? (TRUE for
            #   visible, FALSE for not visible)
            showMenuBarFlag             => TRUE,
            showToolbarFlag             => TRUE,
            showTreeViewFlag            => TRUE,
            showCanvasFlag              => TRUE,
            # The automapper window can show one or more toolbars, each with a set of buttons
            # A list specifying how many toolbars should be shown, besides the (compulsory) first
            #   one. The list comprises the names of the button sets to use in each additional
            #   toolbar. (This list is updated whenever the user adds/removes button sets, so it's
            #   remembered between sessions)
            # The list can contain 0, 1 or more of the button set names specified by
            #   GA::Win::Map->constButtonSetList, except for 'default'
            # When the list is empty, only one toolbar is shown. If the list contains one item, two
            #   are shown (and so on)
            buttonSetList               => [],
            # The automapper window's 'painting' toolbar can show buttons, each corresponding to a
            #   room flag, that are applied to the window's painter when turned on
            # A list of room flags that should be shown (can be an empty list, but should not
            #   contain duplicates)
            preferRoomFlagList          => [],
            # The automapper window's 'background' toolbar can show buttons, each corresponding to
            #   an RGB colour, that is used to colour in the map's background
            # A list of RGB colours that should be shown, in addition to a button for the default
            #   colour, which is always shown (can be an empty list, but should not contain
            #   duplicates)
            preferBGColourList          => [],

            # Default and maximum sizes/colours.

            # Default sizes. Each gridblock contain max 1 room. All these sizes should be odd
            #   numbers
            defaultGridWidthBlocks      => 201,         # Room's x co-ordinates
            defaultGridHeightBlocks     => 201,         # Room's y co-ordinates
            defaultBlockWidthPixels     => 51,          # At magnification 1
            defaultBlockHeightPixels    => 51,
            defaultRoomWidthPixels      => 31,          # Room in centre of block
            defaultRoomHeightPixels     => 31,

            # Maximum sizes. We use a maximum size to stop the user creating a map bigger than the
            #   known universe in the world model's 'pref' window; we use the default size IVs above
            #   to enable smaller maps by default for testing purposes
            # $self->defaultGridWidthBlocks (etc) is not checked against these maximum sizes. It's
            #   up to you, as the person editing these literal values, to make the maximum sizes the
            #   same as, or bigger, than the default sizes
            maxGridWidthBlocks          => 1001,
            maxGridHeightBlocks         => 1001,
            maxBlockWidthPixels         => 101,
            maxBlockHeightPixels        => 101,
            maxRoomWidthPixels          => 51,
            maxRoomHeightPixels         => 51,

            # Default map sizes
            defaultMapWidthPixels       => undef,       # Set below
            defaultMapHeightPixels      => undef,

            # Hash of region scheme objects, specifying a set of colours to use in the automapper.
            #   The object named 'default' always exists and cannot be deleted. Other objects can
            #   have any name (i.e. they don't need to match a region name)
            # Hash in the form
            #   $regionSchemeHash{style_name} = blessed_reference_to_scheme_object
            regionSchemeHash            => {},
            # Shortcut to the default region scheme object
            defaultSchemeObj            => undef,       # Set below

            # Default colours - used to reset region scheme colours to default values
            # N.b. Region schemes have corresponding IVs for all of these values except for
            #   ->defaultNoBackgroundColour
            defaultBackgroundColour     => '#FFFF99',   # Cream - map displayed
            defaultNoBackgroundColour   => '#FFFFFF',   # White - no map
            defaultRoomColour           => '#FFFFFF',   # White - room
            defaultRoomTextColour       => '#000000',   # Black - text inside room
            defaultSelectBoxColour      => '#0088FF',   # Blue - selection box
            defaultBorderColour         => '#000000',   # Black - room border
            defaultCurrentBorderColour  => '#FF0000',   # Red - current location
                                                        #   (update mode)
            defaultCurrentFollowBorderColour
                                        => '#DD7422',   # Orange - current location
                                                        #   (follow mode)
            defaultCurrentWaitBorderColour
                                        => '#FF8CB3',   # Pink - current location
                                                        #   (wait mode)
            defaultCurrentSelectBorderColour
                                        => '#FF40E0',   # Purple - current and
                                                        #   selected room
            defaultLostBorderColour     => '#21D221',   # Green - automapper is lost
            defaultLostSelectBorderColour               # Dark green - automapper is lost at room
                                        => '#268626',   #   which is also a selected room
            defaultGhostBorderColour    => '#933A20',   # Brown - ghost (presumed) room
            defaultGhostSelectBorderColour              # Pale brown - ghost (presumed) which is
                                        => '#BB6E57',   #   also a selected room
            defaultSelectBorderColour   => '#0088FF',   # Blue - selected location
            defaultRoomAboveColour      => '#FABA7E',   # Less pale orange - room echo from above
            defaultRoomBelowColour      => '#FFCA99',   # More pale orange - room echo from below
            defaultRoomTagColour        => '#C90640',   # Dark red - room tag
            defaultSelectRoomTagColour  => '#0088FF',   # Blue - selected room tag
            defaultRoomGuildColour      => '#1430D7',   # Dark blue - room guild
            defaultSelectRoomGuildColour
                                        => '#0088FF',   # Blue - selected room guild
            defaultExitColour           => '#000000',   # Black - exit
            defaultSelectExitColour     => '#0088FF',   # Blue - selected exit
            defaultSelectExitTwinColour => '#3AE1EC',   # Cyan - twin room/exit of
                                                        #   selected region/broken
                                                        #   exit
            defaultSelectExitShadowColour
                                        => '#DD7422',   # Orange - selected exit's shadow exit
            defaultRandomExitColour     => '#FF0000',   # Red - random exit (type 3 only)
            defaultImpassableExitColour => '#FF00FF',   # Magenta - impassable exit
            defaultMysteryExitColour    => '#900700',   # Dark red - mystery exit
            defaultCheckedDirColour     => '#FF96AA',   # Pink - checked direction
            defaultDragExitColour       => '#FF0000',   # Red - draggable exit
            defaultExitTagColour        => '#000000',   # Black - exit tag
            defaultSelectExitTagColour  => '#0088FF',   # Blue - selected exit tag
            defaultMapLabelColour       => '#C90640',   # Dark red - map label
            defaultSelectMapLabelColour => '#0088FF',   # Blue - selected label

            # Hash of map label style objects. Each object defines attributes like text colour,
            #   italics, and so on, that can be applied to multiple map labels
            # Hash in the form
            #   $mapLabelStyleHash{style_name} = blessed_reference_to_style_object
            mapLabelStyleHash           => {},          # Set below
            # The name of the map label style that should be used for new labels, set whenever a
            #   label is added to the automapper window
            mapLabelStyle               => undef,       # Set below
            # Flag set to TRUE if all labels should be aligned horizontally (in the middle of a
            #   grid block or at its edge), FALSE if labels can be placed with any horizontal
            #   alignment
            mapLabelAlignXFlag          => FALSE,
            # Flag set to TRUE if all labels should be aligned vertically (in the middle of a
            #   grid block or at its edge), FALSE if labels can be placed with any vertical
            #   alignment
            mapLabelAlignYFlag          => FALSE,
            # Flag set to FALSE if the map label dialogue window (created by
            #   GA::Win::Map->promptConfigLabel) should use a single-line entry box, TRUE if it
            #   should use a multi-line textview
            mapLabelTextViewFlag        => FALSE,

            # Room flags - a collection of flags used by room model objects, organised into groups
            #   called room filters and used mainly by the automapper window to set the colour of
            #   the room, with one colour for each room flag
            # (NB There is no rule which says an RGB colour must be unique to a room flag, but
            #   obviously using the same colour with multiple room flags is a bad idea)
            # The room model object (GA::ModelObj::Room) stores a hash of room flags. In each room,
            #   every room flag is either 'on' or 'off'. A room can have zero, one or multiple
            #   room flags
            #
            # Hash of room filters, showing which are currently applied (TRUE) and which are not
            #   applied. Room filters can't be added or removed by the user, so they keys in this
            #   hash are those specified by GA::Client->constRoomFilterList
            roomFilterApplyHash         => {},          # Set by $self->setupRoomFlags
            # A hash of room flag objects (GA::Obj::RoomFlag), one for each room flag specified by
            #   GA::Client->constRoomFlagList. Hash in the form
            #   $roomFlagHash{room_flag_name} = blessed_reference_to_room_flag_object
            roomFlagHash                => {},          # Set by $self->setupRoomFlags
            # A list of room flag names, sorted by its priority (highest-priority room flag object
            #   has its ->priority set to 1, the lowest-priority has its ->priority set to a value
            #   in the 100s. Used for quick lookup, so this list must be updated whenever
            #   $self->roomFlagHash or an individual room flag object is updated
            # e.g. ( 'stash_room', 'hide_room', 'interesting', ... )
            roomFlagOrderedList         => [],          # Set by $self->setupRoomFlags
            # A single flag which, when set to TRUE, releases all filters, overriding the contents
            #   of ->roomFilterApplyHash (set to FALSE otherwise)
            allRoomFiltersFlag          => TRUE,
            # How lists of room flags should be displayed in the automapper window (and in various
            #   'edit' windows)
            #   'default'   - List all room flags
            #   'essential' - Show only essential standard flags (those specified by
            #                   GA::Client->constRoomHazardHash) and any custom room flags
            #   'custom'    - Show only custom room flags
            roomFlagShowMode            => 'default',
            # MSDP can supply a 'TERRAIN' variable for each room. If so, those variables are
            #   collected initially in this hash, in the form
            #       $roomTerrainInitHash{terrain_type} = undef
            roomTerrainInitHash         => {},
            # The user can then allocate a terrain to one of Axmud's room flags (in which case new
            #   rooms have their room flags set automatically, as if the painter was on), or choose
            #   to ignore the terrain type
            # NB Room flags in this hash are exclusive. If a room's room flag is set using one of
            #   the room flags in ->roomTerrainHash, all other room flags which are also found in
            #   ->roomTerrainHash are unset in the room, regardless of whether the user set them
            #   manually or not
            # Hash of allocated terrain types, in the form
            #       $roomTerrainHash{terrain_type} = room_flag
            #       $roomTerrainHash{terrain_type} = undef (to ignore the terrain type)
            roomTerrainHash             => {},

            # The following IVs work in a similar way. When the painter is on, rooms are allocated
            #   a room flag if text in the room title/description/exit/content list matches one of
            #   the patterns in the following hashes
            # Hashes in the form
            #   $hash{pattern} = room_flag
            #
            # Patterns that match text in the room's title (tested against every room title in the
            #   room's ->titleList IV)
            # NB A restriction applies to ->paintFromTitleHash, but not the other ->paintFrom...
            #   IVs
            # When painting because of titles matching a pattern in ->paintFromTitleHash, room flags
            #   in the room are set for every matching pattern
            # When that operation is complete, any room flags which are found in
            #   ->paintFromTitleHash, but which were not set during that operation, are then unset
            # This restriction prevents problems at worlds like EmpireMUD 2.0, whose room titles
            #   change as you chop down trees and dig up crops
            paintFromTitleHash          => {},
            # Patterns that match text in the room's description (tested against every description
            #   in the room's ->descripHash IV)
            paintFromDescripHash        => {},
            # Patterns that match one of the room's exits (tested against every exit stored as a key
            #   in the room's ->exitNumHash)
            paintFromExitHash           => {},
            # Patterns that match one of the objects in the room's temporary contents list, set for
            #   the non-model room object used by the Locator task. The objects are stored in the
            #   room's ->tempObjList. Patterns are tested against each of those objects'
            #   ->baseString IV, if it is set, or its ->noun IV otherwise
            paintFromObjHash            => {},
            # Patterns that match one of the room's room commands (tested against every string in
            #   the room's ->roomCmdList)
            paintFromRoomCmdHash        => {},

            # How rooms are drawn
            # Current room mode
            #   'single' - The current/last known/ghost rooms are drawn with a coloured border, 1
            #       pixel wide
            #   'double' - The current/last known/ghost rooms are drawn with a coloured border, 2
            #       pixels wide
            #   'interior' - The current/last known/ghost rooms are drawn with a normal border, but
            #       the interior colour is changed (to match the border colour in modes 0/1),
            #       overriding any room flags that are set
            currentRoomMode             => 'single',
            # Room interior mode - sets what characters/numbers are drawn in room interiors, towards
            #   the top
            # Doesn't affect drawing U and D for up and down, towards the bottom. Also doesn't
            #   affect setting the room interior's colour
            #   'none' - Draw nothing
            #   'shadow_count' - Draw shadow/unallocated exit counts
            #   'region_count' - Draw region/super-region exit counts
            #   'checked_count' - Draw checked/checkable direction counts
            #   'room_content' - Draw room contents
            #   'hidden_count' - Draw hidden objects counts
            #   'temp_count' - Draw temporary contents counts
            #   'word_count' - Draw recognised word counts
            #   'room_tag' - Draw the room tag (instead of drawing it externally)
            #   'room_flag' - Draw room flag text (which matches the room's highest priority room
            #       flag)
            #   'visit_count' - Draw # of character visits
            #   'compare_count' - Draw # of matching rooms (but only in the current room)
            #   'profile_count' - Draw room's exclusive profiles
            #   'title_descrip' - Draw room titles/verbose descriptions
            #   'exit_pattern' - Draw assisted moves/exit patterns
            #   'source_code' - Draw source code path
            #   'vnum' - Draw world's room vnum
            #   'grid_posn' - Draw room's grid coordinates
            roomInteriorMode            => 'none',
            # When ->roomInteriorMode is set to 'grid_posn', offsets to use, so that the visible
            #   grid coordinates match the game's grid coordinates
            roomInteriorXOffset         => 0,
            roomInteriorYOffset         => 0,

            # How exits are drawn
            #   'ask_regionmap' - Let each individual regionmap decide (between no exits, simple
            #       exits and complex exits)
            #   'no_exit' - Draw no exits (only the rooms themselves are drawn)
            #   'simple_exit' - Draw simple exits (all exists are simple lines, with arrows for
            #       one-way exits)
            #   'complex_exit' - Draw complex exits (there are four kinds of exits drawn -
            #       incomplete, uncertain, one-way and two-way)
            drawExitMode                => 'ask_regionmap',
            # Flag set to TRUE if the automapper should obscure (i.e. filter out) some exits,
            #   drawing only those exits for rooms near the current room, or for selected rooms (and
            #   selected exits), and for rooms whose rooms flags match those in
            #   GA::Client->constRoomNoObscuredHash (e.g. 'main_route')
            obscuredExitFlag            => FALSE,
            # Flag set to TRUE if the automapper should re-obscure exits as the character moves
            #   around (so that only exits around the character's location are visible), and
            #   when other conditions change
            obscuredExitRedrawFlag      => FALSE,
            # Radius (in gridblocks) of a square area, with the current room in the middle. When
            #   obscuring exits is enabled, exits are drawn for all rooms in this area (including
            #   the current room), but not necessarily for any rooms outside the area
            # Use 1 to draw only the current room, 2 to draw exits for rooms in a 3x3 area, 3 for a
            #   5x5 area, and so on
            obscuredExitRadius          => 2,
            # Max radius (the minimum is always 1). This maximum also applies to
            #   GA::Obj::Regionmap->obscuredExitRadius
            maxObscuredExitRadius       => 9,
            # When this flag is set to TRUE, exit ornaments are drawn. If set to FALSE, ornaments
            #   aren't drawn
            drawOrnamentsFlag           => TRUE,
            # Exit length - how long normal exits should be. When set to '1', adjacent rooms occupy
            #   adjacent gridblocks. When set to '2', adjacent rooms are 1 gridblock apart (and so
            #   on). This affects newly-created exits only; existing exits retain their length even
            #   when the value is changed
            # The exit length for cardinal directions (i.e. between rooms on the same level)
            horizontalExitLengthBlocks  => 1,
            # The exit length for up/down directions (i.e. between rooms not on the same level)
            verticalExitLengthBlocks    => 1,
            # Max exit length (the minimum is always 1)
            maxExitLengthBlocks         => 16,
            # Whether new broken exits should be drawn as 'bent' broken exits (a zig-zagging line
            #   from the parent room to a destination room; flag set to TRUE) or as normal broken
            #   exits (squares attached to the parent room, not touching the destination room; flag
            #   set to FALSE)
            drawBentExitsFlag           => TRUE,

            # The way in which the automapper decides whether the Locator's current room is the same
            #   one as the one displayed on the map
            # Match the room title, if set to TRUE (set to FALSE otherwise)
            matchTitleFlag              => FALSE,
            # Match the first part of the (verbose) description, if set to TRUE (set to FALSE
            #   otherwise)
            matchDescripFlag            => FALSE,
            # How many characters to match, when matching the verbose description (0 - match the
            #   entire verbose description)
            matchDescripCharCount       => 100,
            # Match exits, if set to TRUE (set to FALSE otherwise). Ignored if the current world
            #   profile's ->basicMappingFlag is not FALSE (meaning, don't use basic mapping)
            matchExitFlag               => TRUE,
            # If this flag is set to TRUE, whenever $self->updateRoom is called to update the
            #   properties of a room model object, the room's verbose description is compared with
            #   the current dictionary's list of recognised words; every recognised noun and
            #   adjective is stored in the the room's >nounList and/or ->adjList (set to FALSE
            #   otherwise)
            analyseDescripFlag          => FALSE,
            # Match the room's source code path, if set to TRUE (set to FALSE otherwise)
            matchSourceFlag             => FALSE,
            # Match the room's remote vnum, if set to TRUE (set to FALSE otherwise)
            matchVNumFlag               => TRUE,

            # When the Automapper window is open and in 'update' mode, which of the room model
            #   object's properties are updated to match those gathered by the Locator task's
            #   current room (during the call to $self->updateRoom). Set to TRUE if a property
            #   should be updated, FALSE if not
            updateTitleFlag             => TRUE,
            updateDescripFlag           => TRUE,
            updateExitFlag              => TRUE,
            updateSourceFlag            => FALSE,
            # If TRUE, this flag updates not just the room's remote vnum, but any other room data
            #   supplied by MSDP and MXP (i.e., transfers the contents of the room's
            #   ->protocolRoomHash and ->protocolExitHash IVs)
            updateVNumFlag              => TRUE,
            # Flag set to TRUE if $self->updateRoom should set replace the room's roomm commands,
            #   FALSE if not
            updateRoomCmdFlag           => FALSE,
            # Flag set to TRUE if $self->updateExit should set an exit's ornaments using its exit
            #   state (when the exit state is set); FALSE if not
            updateOrnamentFlag          => FALSE,

            # Flag set to TRUE if moves between rooms should be translated by the automapper (for
            #   example, if the user types 'south' and there's an exit with its ->dir set to 'enter
            #   cave', and with its ->mapDir set to 'south', the command sent to the world should be
            #   'enter cave'). Set to FALSE otherwise
            assistedMovesFlag           => TRUE,
            # Flags set to TRUE if the automapper should try to open, close, unlock, lock or pick
            #   exits during an assisted move (set to FALSE otherwise)
            assistedBreakFlag           => FALSE,
            assistedPickFlag            => FALSE,
            assistedUnlockFlag          => TRUE,
            assistedOpenFlag            => TRUE,
            assistedCloseFlag           => FALSE,
            assistedLockFlag            => FALSE,
            # Flag set to TRUE if protected moves mode is turned on (for example, if the user types
            #   'south' and assisted moves are on, but the world model has no exit with its ->mapDir
            #   drawn south, the world command is not sent, and the user sees a warning message
            #   instead; set to FALSE otherwise)
            # Ignored when $self->assistedMovesFlag is FALSE
            protectedMovesFlag          => FALSE,
            # Flag set to TRUE if super protected moves turned on; after the first warning message,
            #   all unprocessed commands are removed, so (for example) in 'north;get torch', if
            #   the 'north' command fails, 'get torch' is never processed. Ignored if
            #   ->proctedMovesFlag is FALSE
            superProtectedMovesFlag     => FALSE,
            # Flag to deal with worlds like Discworld, which have some kind of pseudo-wilderness
            #   areas - neighbouring rooms have no exits leading into them, but nevertheless those
            #   exits exist and can be used
            # Flag set to TRUE if crafty moves mode is turned on - for example, when the automapper
            #   window is open and in 'update' mode, if the user tries to leave the current room in
            #   a direction for which there isn't an exit, draws a (hidden) exit in that direction
            #   if a new room statement (rather than a fail exit message) is received
            # If set to FALSE, no new exit (hidden or otherwise) is drawn in that situation, and the
            #   character becomes lost
            # Ignored when if ->protectedMovesFlag is TRUE (the value of ->assistedMovesFlag
            #   doesn't matter)
            craftyMovesFlag             => FALSE,

            # Flag set to TRUE when, if setting an exit ornament (from Exits > Set ornaments...),
            #   the exit's twin exit should have the same ornament set (set to FALSE otherwise)
            setTwinOrnamentFlag         => TRUE,

            # Axbasic scripts. Only non-task based scripts are suitable for these lists. Ignored if
            #   $self->allowModelScriptFlag is FALSE.
            # List of Axbasic scripts to run, when the character arrives in a newly-created room. If
            #   ->arriveScriptList is also set, they are ignored.
            newRoomScriptList           => [],
            # List of Axbasic scripts to run, when the character arrives in an existing room. If
            #   the room's own ->arriveScriptList is set, those scripts are run before these
            #   scripts are run.
            arriveScriptList            => [],

            # Flag set to TRUE if the automapper should count the number of character visits (set to
            #   FALSE otherwise)
            countVisitsFlag             => TRUE,
            # Flag set to TRUE if the world model's list of Axbasic scripts should be run when we
            #   create/enter rooms (set to FALSE if not). The scripts are stored in
            #   $self->newRoomScriptList and -> arriveScriptList
            # Does not apply to scripts belonging to individual rooms, i.e.
            #   GA::ModelObj::Room->arriveScriptList
            allowModelScriptFlag        => TRUE,
            # Flag set to TRUE if the room model object's own list of Axbasic scripts should be run
            #   when when we enter this room (set to FALSE if not). The scripts are stored in
            #   GA::ModelObj::Room->arriveScriptList
            # Does not apply to to scripts belonging to the model itself, i.e
            #   $self->newRoomScriptList and ->arriveScriptList
            allowRoomScriptFlag         => TRUE,
            # Flag set for the special case of Room A with an uncertain exit that leads north to
            #   Room B. If it's also a broken or region exit, when the user moves south from Room B,
            #   should the automapper attempt to convert the exit into an uncertain exit (flag set
            #   to TRUE), or should a new room be drawn, south of Room B (flag set to FALSE)
            intelligentExitsFlag        => TRUE,
            # Flag set to TRUE if the automapper should create a new exit object when the character
            #   moves, and the move is detected by the Locator task using a 'follow anchor' pattern.
            #   If FALSE, the automapper becomes lost, instead
            followAnchorFlag            => FALSE,
            # Flag set to TRUE if room tags should be displayed in capitals (set to FALSE otherwise)
            capitalisedRoomTagFlag      => TRUE,
            # Flag set to TRUE if tooltips should be visible (set to FALSE otherwise)
            showTooltipsFlag            => TRUE,
            # Flag set to TRUE if room notes should be visible in tooltips (set to FALSE otherwise,
            #   and ignored if ->showTooltipsFlag is FALSE)
            showNotesFlag               => TRUE,
            # Flag set to TRUE when a message should be displayed, whenever the call to
            #   $self->compareRooms from GA::Obj::Map->useExistingRoom returns a false value,
            #   meaning that the automapper is now lost (set to FALSE otherwise)
            explainGetLostFlag          => TRUE,
            # Flag set to TRUE if update mode should be disabled (so that only wait/follow modes are
            #   available); set to FALSE otherwise
            disableUpdateModeFlag       => FALSE,
            # Flag set to TRUE if, when an exit becomes a region exit, its ->exitTag should be
            #   automatically set
            updateExitTagFlag           => TRUE,
            # Flag set to TRUE if room echos should be drawn (rooms just above or below the
            #   current regionmap's current level)
            drawRoomEchoFlag            => TRUE,
            # Flag set to TRUE if the Automapper window should activate the automapper object's
            #   ->trackAloneFlag (where possible), when the window closes (set to FALSE otherwise)
            allowTrackAloneFlag         => TRUE,
            # Flag set to TRUE if all primary directions (inc. northnortheast, etc) should be shown
            #   in 'dialogue' windows; set to FALSE if only the usual eight compass directions (inc.
            #   north and northeast) plus up/down should be shown in 'dialogue' windows
            showAllPrimaryFlag          => FALSE,
            # Flag set to TRUE if CTRL+C should initiate a 'move rooms to click' operation, FALSE if
            #   CTRL+C should be ignored
            allowCtrlCopyFlag           => TRUE,

            # Auto-compare mode: when the automapper window is open and in 'update' mode, Axmud
            #   can automatically compare the current room against other rooms. If one or more
            #   matches are found, IVs in GA::Obj::Map are set to enable merge operations between
            #   the current room and the matching room(s)
            # The current setting for auto-compare mode:
            #   'default'   - Don't auto-compare the current room
            #   'new'       - Auto-compare the current room when it's a new room
            #   'current'   - Auto-compare the current room whenever the current room is set
            autoCompareMode             => 'default',
            # Flag set to TRUE if Axmud should auto-compare all rooms in the world model; FALSE if
            #   it should only auto-compare rooms in the same region (ignored if
            #   $self->autoCompareMode is 'default')
            autoCompareAllFlag          => FALSE,
            # The maximum number of room comparisons to perform in auto-compare mode. If 0, there is
            #   no maximum
            autoCompareMax              => 0,
            # Auto-slide mode: what to do when, in the automapper window's 'update' mode, the
            #   character moves from an original room to a destination room, but the destination
            #   room doesn't match the Locator task's room
            #   - 'default'     - Mark the character as lost
            #   - 'orig_pull'   - Move the original room backwards (i.e. in the opposite direction)
            #                       into the first available gridblock in which there's room for
            #                       both the original room and a new destination room
            #   - 'orig_push'   - Move the original room forwards (i.e. in the direction of
            #                       movement) into the first available gridblock, so there's room
            #                       to create a new destination room
            #   - 'other_pull'  - Move the non-matching destination room backwards (i.e. in the
            #                       opposite direction) into the first available gridblock, so
            #                       there's room to create a new destination room
            #   - 'other_push'  - Move the non-matching destination room forwards (i.e. in the
            #                       direction of movement) into the first available gridblock, so
            #                       there's room to create a new destination room
            #   - 'dest_pull'   - Place the new destination room in the first available gridblock in
            #                       the backwards direction
            #   - 'dest_push'   - Place the new destination room in the first available gridblock in
            #                       the forwards direction
            autoSlideMode               => 'default',
            # When performing an auto-slide, the maximum distance to travel, looking for empty
            #   gridblocks, before giving up. Must be a positive integer
            autoSlideMax                => 10,
            # Auto-rescue mode: when GA::Obj::Map->setCurrentRoom is called to make the character as
            #   lost, it can instead activate auto-rescue mode, which creates a temporary region
            #   where new rooms can be drawn. The current location is compared against rooms in the
            #   previous region, so that all rooms in the temporary region can be merged back into
            #   the previous region, when required
            # Note that auto-rescue mode can't be activated all all in certain situations (for
            #   example, in wilderness rooms, after certain Axmud internal errors, in 'Connect
            #   offline' mode, when the Locator task is reset manually)
            # Flag set to TRUE if, instead of marking the character as lost, auto-rescue mode should
            #   be activated instead (when it's possible to do so); FALSE otherwise
            autoRescueFlag              => FALSE,
            # Flag set to TRUE if Axmud should automatically merge rooms in the temporary region
            #   back into the previous region, as soon as a new room is drawn matching a single
            #   room in the previous region (the first room drawn in the temporary region doesn't
            #   count; ignored if ->autoRescueFlag is FALSE and if the Locator task is expecting
            #   more room statements)
            autoRescueFirstFlag         => FALSE,
            # Flag set to TRUE if Axmud should prompt the user, before automatically merging rooms
            #   back into the previous region (ignored if ->autoRescueFlag or ->autoRescueFirstFlag
            #   are FALSE)
            autoRescuePromptFlag        => FALSE,
            # Flag set to TRUE if matching rooms should be merged, but non-matching moves should not
            #   be moved (FALSE if non-matching rooms should be moved)
            autoRescueNoMoveFlag        => FALSE,
            # Flag set to TRUE if only character visits should be updated when merging rooms (FALSE
            #   if all of the rooms' IVs should be updated when merging a pair of rooms)
            autoRescueVisitsFlag        => FALSE,
            # Flag set to TRUE if the automapper window's mode should be temporarily switched to
            #   'update' mode if it's in 'follow' mode, and then restored to 'follow' mode when the
            #   merge operation is performed (FALSE if auto-rescue mode is only available when the
            #   automapper window is in 'update' mode)
            autoRescueForceFlag         => FALSE,

            # The last filepath entered - so that, for source code files stored in the same
            #   directory, the user doesn't have to type the entire path again ('undef' if none
            #   ever entered)
            lastFilePath                => undef,
            # The last virtual area path entered ('undef' if none ever entered)
            lastVirtualAreaPath         => undef,
            # Flag set to TRUE if the automapper should track the current room and auto-scroll the
            #   map's scrollbars, so that it is always visible after a move (set to FALSE otherwise)
            trackPosnFlag               => TRUE,
            # How close the current room has to be to the edge of the visible map, in order to get
            #   the scrollbars moved
            # A value from 0-1. 0 means 'always centre the map on the current room', 1 means 'centre
            #   the map only when the current room is outside the visible window'.
            # 0.5 means that the room must be halfway between the centre of the visible map, before
            #   the map is centred. 0.66 means the room must be two-thirds of the distance away from
            #   the centre, and 0.9 means that the room must be 90% of the distance away from the
            #   centre
            # The automapper menu currently sets it to one of four values
            #   (0, 0.33, 0.66, 1)
            trackingSensitivity         => 0.66,
            # Flag set to TRUE if pathfinding functions (and any similar code) should avoid using
            #   rooms that are hazardous, by default - specifically, any rooms which have any of the
            #   room flags specified by GA::Client->constRoomHazardHash (currently 'blocked_room',
            #   'avoid_room', 'danger' or 'mortal_danger') (set to FALSE otherwise)
            avoidHazardsFlag            => TRUE,
            # Flag set to TRUE if, after finding a shortest route using the pathfinding algorithms,
            #   post-processing should be applied to smooth jagged paths (set to FALSE otherwise)
            postProcessingFlag          => TRUE,
            # Flag set to TRUE if double-clicking over a room should be the equivalent of 'Go to
            #   room' (set to FALSE otherwise)
            quickPathFindFlag           => TRUE,
            # Flag set to TRUE if uncertain exits should automatically be converted into 2-way exits
            #   (set to FALSE if not)
            # NB If basic mapping mode (GA::Profile::World->basicMappingFlag) is on, travelling from
            #   one room to a new room normally creates a one-way exit. When the user prefers to
            #   create two-way exits instead, they can set this flag to TRUE
            # NB When moving between normal and wilderness border rooms, a one-way exit is normally
            #   created. When they user prefers to create two-way exits instead, they can set this
            #   flag to TRUE
            autocompleteExitsFlag       => FALSE,
            # When the character attempts to move in a direction but we get a failed exit message
            #   in response, and if there is no exit in the direction, we can store that direciton
            #   as a checked direction (an entry in the room object's ->checkedDirHash)
            # Flag set to TRUE if checked directions should be collected, FALSE if not
            # If TRUE, checked directions are collected even if the automapper window (when open) is
            #   in 'follow' mode
            collectCheckedDirsFlag      => FALSE,
            # Flag set to TRUE if checked directions should be drawn in the automapper window, FALSE
            #   if not
            drawCheckedDirsFlag         => TRUE,
            # Checkable direction mode - when the room's interior text is showing the number of
            #   checked directions (and checkable primary directions), this mode determines how many
            #   directions are counted when working out the checkable directions
            # (A checkable direction is a primary direction for which there is is no exit object
            #   and no checked direction)
            #       'simple'    - north, south, west, east
            #       'diku'      - the above, plus up/down
            #       'lp'        - the above, plus northwest/northeast/southwest/southeast
            #       'complex'   - all primary directions (including eastnortheast, etc)
            checkableDirMode            => 'diku',

            # There are three pathfinding algorithms, enacted by calls to $self->findPath (to find
            #   a path using rooms in a single region), $self->findUniversalPath (to find a path
            #   using rooms in any region) and $self->findRoutePath (which doesn't consult the
            #   world model at all, using route objects, GA::Obj::Route, instead)
            # ->findUniversalPath uses pre-calculated routes across a region, but only uses region
            #   exits that have been marked as super-region exits (so that we don't have to
            #   calculate thousands of paths across each region)
            # An alternative is to set these IVs, so that ->findPath can use rooms in adjacent
            #   regions, as if they were in the same region
            # Adjacent region mode - 'default' if $self->findPath should can only use rooms in a
            #   single region, 'near' if $self->findPath can use rooms in regions adjacent to
            #   the start room, and 'all' if $self->findPath ignores regions altogether, treating
            #   all rooms as if they were in the same region
            adjacentMode                => 'near',
            # When $self->adjacentMode is 'adjacent', the number of adjacent regions to use (e.g.
            #   1 means 'use rooms in any adjacent region', 2 means 'use rooms in any adjacent
            #   region, and any of their adjacent regions', 0 means 'don't use adjacent regions'
            # Must be an integer, 0 or above. Ignored if $self->adjacentRegionModeis is not
            #   'adjacent'
            adjacentCount               => 1,
            # Boundary updates. When an existing region exit is modified in any way, or deleted, or
            #   an exit becomes a region exit, it is added to this hash, so that the parent
            #   regionmap's list of super-region exits can be updated. Hash in the form
            #       $updateBoundaryHash{exit_num} = parent_region_name
            updateBoundaryHash          => {},
            # Parallel hash, containing only region exits which have been deleted
            deleteBoundaryHash          => {},
            # Region path updates. When an existing exit is modified in any way, or deleted, it is
            #   added to this hash, so that the parent regionmap's region paths can be checked; if
            #   any of them contain this exit, they can then be recalculated. Hash in the form
            #       $updatePathHash{exit_num} = region_name
            updatePathHash              => {},
            # $self->connectRegionBrokenExit opens a 'dialogue' window; while we wait for a user
            #   response, the timer loop will spin. While we're waiting, this IV is set to TRUE,
            #   and $self->updateRegionPaths won't do anything; once the 'dialogue' window has been
            #   closed, this IV is set back to FALSE
            updateDelayFlag             => FALSE,
            # IVs checked when $self->updateRegionLevels is called, once per timer loop
            # When room model objects and/or map labels are added to or deleted from a regionmap, we
            #   need to re-calculate the regionmap's highest and lowest occupied levels. This hash
            #   contains all the regionmaps that need to be checked. Hash in the form
            #   $checkLevelsHash{regionmap_name} = undef
            checkLevelsHash             => {},

            # Other IVs
            # ---------

            # If the world's source code is available on the user's computer, the directory in which
            #   it can be found. (Individual model objects store the path to the matching world
            #   file, relative to this directory)
            # Normally set to the mudlib directory, e.g. /home/myname/ds/lib/
            mudlibPath                  => undef,
            # The normal file extension used for mudlib objects. If defined, the value of this IV
            #   is added to the value of a model object's ->sourceCodePath (e.g. '.c' for LPMuds).
            #   No need to define it, if the ->sourceCodePath already contains the file extension
            mudlibExtension             => '.c',

            # The painter is a non-model GA::ModelObj::Room object whose IVs are used to 'paint'
            #   new rooms as they are created (or update existing rooms as the character moves
            #   through them). Details about the painter are stored here, but each Automapper window
            #   has its own ->painterFlag which can be set to TRUE or FALSE
            # The non-model GA::ModelObj::Room object which is the painter object
            painterObj                  => undef,           # Set below
            # A list of IVs in the painter object that are actually used to paint rooms (the others
            #   are ignored).
            # Scalar and list IVs in the current room are replaced by their equivalents in the
            #   painter - but hash IVs are merged. (If the same key exists in both objects, the
            #   painter's key-value pair is used)
            constPainterIVList          => [
                'wildMode',
                'titleList',
                'descripHash',
                'exclusiveFlag',
                'exclusiveHash',
                'roomFlagHash',
                'roomGuild',
                'searchHash',
            ],
            # Flag set to TRUE, when only new rooms should be painted. Otherwise, set to FALSE, so
            #   that in 'update' mode, every time the current room changes, it is painted
            paintAllRoomsFlag           => FALSE,
            # Flag relating to the automapper window's quick painting toolbar. Set to FALSE if
            #   quick painting should apply to one room (before resetting itself), TRUE if it should
            #   apply to multiple rooms (the user must manually reset it)
            quickPaintMultiFlag         => FALSE,

            # Limits to world model searches (used by GA::PrefWin::Search). If either value is 0,
            #   then searches use $self->modelObjCount as a limit
            # Maximum number of matches during a search
            searchMaxMatches            => 1000,
            # Maximum number of objects searched
            searchMaxObjects            => 10000,
            # A flag which, when set to TRUE, causes any matching rooms to be selected in the map
            #   window (set to FALSE otherwise)
            searchSelectRoomsFlag       => TRUE,
            # Limits to locate room operations. If the value is 0, then the whole model is searched
            #   when trying to locate a room
            locateMaxObjects            => 5000,
            # What to do, when the character uses an exit whose ->randomType is 'same_region'
            #   (locate room in the current region). Set to TRUE if Axmud should try to locate the
            #   new location (but only if there are less than ->locateMaxObjects to search), or
            #   FALSE if the character should just be marked as 'lost'
            locateRandomInRegionFlag    => FALSE,
            # What to do, when the character uses an exit whose ->randomType is 'any_region' (locate
            #   room anywhere in the map). Set to TRUE if Axmud should try to locate the new
            #   location (but only if there are less than ->locateMaxObjects to search), or FALSE if
            #   the character should just be marked as 'lost'
            locateRandomAnywhereFlag    => FALSE,

            # When the user double-clicks on a room to go there (using the shortest path), give them
            #   an opportunity to change their minds for very long paths. IV set to the number of
            #   steps (separate world commands) used to move from the current room to the specified
            #   one; if the actual number of steps exceeds this value,
            #   GA::Win::Map->processPathCallback shows a yes-no 'dialogue' window, first. If the
            #   IV is set to 0, there is no limit
            pathFindStepLimit           => 200,

            # When GA::Win::Map->doDraw is called, the drawing process can take a long time, if
            #   there are thousands of objects to draw. The value of this IV is the number of
            #   objects (not including exits) above which ->doDraw will create a popup window, so
            #   that the user knows why Axmud has frozen (minimum value 100)
            drawPauseNum                => 500,
            # When GA::Win::Map->recalculatePathsCallback is called, the recalculation process
            #   can tak a long time, if there are hundreds of region paths to recalculate. The
            #   value of this IV is the number of paths above which ->recalculatePathsCallback
            #   will create a popup window, so that the user knows why Axmud has frozen (minimum
            #   value 10)
            recalculatePauseNum         => 50,

            # The font and font size to use for text drawn in the Automapper window (expressed as a
            #   ratio, with 1 being the font size used for room tags at the map's current
            #   magnification)
            mapFont                     => 'Sans',
            roomTagRatio                => 1,
            roomGuildRatio              => 0.7,
            exitTagRatio                => 0.7,
            labelRatio                  => 0.8,
            roomTextRatio               => 0.7,

            # $self->deleteRegions, ->deleteRooms, ->deleteExits and ->deleteLabels all make a call
            #   to GA::Win::Map->setSelectedObj to make sure there are no selected objects in the
            #   automapper window(s)
            # A single call to ->deleteRegions could cause thousands of calls to ->deleteExits,
            #   each of them calling GA::Win::Map->setSelectedObj in turn
            # In that case, we only need a single call to GA::Win::Map->setSelectedObj. This flag is
            #   set to TRUE when ->deleteRegions is called, and reset back to FALSE when that
            #   function is finished. When the flag is TRUE, no time-wasting calls to
            #   GA::Win::Map->setSelectedObj are made
            blockUnselectFlag           => FALSE,
        };

        # Bless the object into existence
        bless $self, $class;

        # Set the light status list
        $self->{lightStatusList}        = $self->{constLightStatusList};

        # Set map size (based on the values immediately above)
        $self->{defaultMapWidthPixels}
            = $self->{defaultGridWidthBlocks} * $self->{defaultBlockWidthPixels};
        $self->{defaultMapHeightPixels}
            = $self->{defaultGridHeightBlocks} * $self->{defaultBlockHeightPixels};

        # Create a default region scheme object
        $self->ivPoke(
            'defaultSchemeObj',
            Games::Axmud::Obj::RegionScheme->new($session, $self, 'default'),
        );
        $self->ivAdd('regionSchemeHash', 'default', $self->defaultSchemeObj);

        # Create some map label styles
        $self->addLabelStyle($session, 'Style 1', $self->{defaultMapLabelColour});
        $self->addLabelStyle($session, 'Style 2', '#FF40E0');
        $self->addLabelStyle($session, 'Style 3', '#000000', undef, 2);
        $self->addLabelStyle($session, 'Style 4', '#000000', undef, 4);
        $self->{mapLabelStyle}          = 'Style 1';

        # Set room filters and room flags
        $self->setupRoomFlags($session);

        # Create a painter object - a non-model GA::ModelObj::Room used to 'paint' other rooms
        #   by copying its IVs into theirs
        $self->resetPainter($session);

        return $self;
    }

    ##################
    # Methods

    # Methods called by GA::Session->spinMaintainLoop, etc

    sub updateRegionPaths {

        # Called by GA::Session->spinMaintainLoop, $self->findUniversalPath and
        #   GA::EditWin::Regionmap->boundaries1Tab_addButtons
        # Uses the exit numbers stored in $self->updateBoundaryHash, ->updatePathHash and
        #   ->deleteBoundaryHash (if any) to create, modify or delete region paths for the exits'
        #   parent regions
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            @exitList, @newModList,
            %boundaryHash, %deleteHash, %regionmapHash, %regionNameHash, %otherHash,
            %otherRegionmapHash,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRegionPaths', @_);
        }

        # $self->connectRegionBrokenExit can open 'dialogue' windows; while the window is open, the
        #   GA::Session's timer loop can still call this function. Ignore any such calls until the
        #   dialogue connect operation has completed
        if ($self->updateDelayFlag) {

            return undef;
        }

        # Import the hashes (for quick lookup)
        %boundaryHash = $self->updateBoundaryHash;
        %otherHash = $self->updatePathHash;
        %deleteHash = $self->deleteBoundaryHash;

        # First deal with all region exits which have been created, modified or deleted since the
        #   last spin of the timer loop (if any)
        if (%boundaryHash) {

            # Get a sorted list of exit numbers, because when two region exits in the same region
            #   lead to the same other region, the one with the lowest exit model number (usually
            #   the first one created) is used as the super-region exit, by default
            @exitList = sort {$a <=> $b} (keys %boundaryHash);

            OUTER: foreach my $exitNum (@exitList) {

                my ($regionName, $regionmapObj, $exitObj, $roomObj, $newRegionObj);

                $regionName = $boundaryHash{$exitNum};
                $regionmapObj = $self->ivShow('regionmapHash', $regionName);
                if (! $regionmapObj) {

                    # If the region is being deleted, don't need to bother with its super-region
                    #   exits
                    next OUTER;
                }

                # (As we go, create a hash of affected regionmaps, so that later on we can
                #   check super-region exits)
                $regionmapHash{$regionmapObj->number} = $regionmapObj;

                # We deal with deleted region exits in a moment
                if (! exists $deleteHash{$exitNum}) {

                    $exitObj = $self->ivShow('exitModelHash', $exitNum);

                    # Check whether the exit has moved to a new region, or not
                    $roomObj = $self->ivShow('modelHash', $exitObj->parent);
                    if ($roomObj->parent != $regionmapObj->number) {

                        $newRegionObj = $self->ivShow('modelHash', $roomObj->parent);
                    }

                    # Check that the existing exit is still a region exit in its original region
                    if (! $exitObj->regionFlag || $newRegionObj) {

                        # An existing exit is no longer a region exit in its original region. Update
                        #   the regionmap's list of region objects
                        $regionmapObj->removeRegionExit($exitObj);

                        # Remove any region paths (stored in ->regionPathHash and
                        #   ->safeRegionPathHash) which were using this exit
                        INNER: foreach my $exitString ($regionmapObj->ivKeys('regionPathHash')) {

                            my $pathObj = $regionmapObj->ivShow('regionPathHash', $exitString);

                            if ($pathObj->startExit == $exitNum || $pathObj->stopExit == $exitNum) {

                                # (Update both ->regionPathHash and ->safeRegionPathHash)
                                $regionmapObj->removePaths($exitString);
                            }
                        }

                    } else {

                        # Deal with new/modified region exits in a moment
                        push (@newModList, $exitObj, $roomObj, $regionmapObj, $newRegionObj);
                    }
                }
            }

            # Deal with deleted region exits. Compile a hash of affected region names
            OUTER: foreach my $exitNum (keys %deleteHash) {

                my $regionName = $deleteHash{$exitNum};

                $regionNameHash{$regionName} = undef;
            }

            OUTER: foreach my $regionName (keys %regionNameHash) {

                my $regionmapObj = $self->ivShow('regionmapHash', $regionName);
                if ($regionmapObj) {

                    INNER: foreach my $exitString ($regionmapObj->ivKeys('regionPathHash')) {

                        my $pathObj = $regionmapObj->ivShow('regionPathHash', $exitString);

                        if (
                            exists $deleteHash{$pathObj->startExit}
                            || exists $deleteHash{$pathObj->stopExit}
                        ) {
                            # (Update both ->regionPathHash and ->safeRegionPathHash)
                            $regionmapObj->removePaths($exitString);
                        }
                    }
                }
            }

            # Deal with new/modified region exits
            if (@newModList) {

                do {

                    my (
                        $exitObj, $roomObj, $regionmapObj, $newRegionObj, $destRoomObj, $matchFlag,
                        $twinExitObj, $twinRoomObj, $twinRegionObj, $twinRegionmapObj,
                    );

                    $exitObj = shift @newModList;
                    $roomObj = shift @newModList;
                    $regionmapObj = shift @newModList;
                    $newRegionObj = shift @newModList;

                    $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
                    # For an exit which has moved to a new region, use the regionmap of the new
                    #   region
                    if ($newRegionObj) {

                        $regionmapObj = $self->ivShow('regionmapHash', $newRegionObj->name);
                    }

                    # Check if the regionmap already knows about this exit
                    if (! $regionmapObj->ivExists('regionExitHash', $exitObj->number)) {

                        # It's a new region exit, or a region exit which has moved to a new region.
                        #   If there are no super-region exits between this exit's region and the
                        #   destination region, then this exit should be marked as a super-region
                        #   exit (but not if the user has specifically marked it as a normal region
                        #   exit, in which case $exitObj->notSuperFlag will be set)
                        INNER: foreach my $otherExitNum ($regionmapObj->ivKeys('regionExitHash')) {

                            my ($otherExitObj, $otherDestRoomObj);

                            $otherExitObj = $self->ivShow('exitModelHash', $otherExitNum);
                            $otherDestRoomObj = $self->ivShow('modelHash', $otherExitObj->destRoom);

                            if (
                                $otherExitObj->superFlag
                                && $destRoomObj->parent == $otherDestRoomObj->parent
                            ) {
                                $matchFlag = TRUE;
                                last INNER;
                            }
                        }

                        if (! $matchFlag && ! $exitObj->notSuperFlag) {

                            # This exit is a super-region exit
                            $exitObj->ivPoke('superFlag', TRUE);

                            # Create region paths between this super-region exit and every other
                            #   super-region exit in the region
                            $self->connectRegionExits(
                                $session,
                                $regionmapObj,
                                $roomObj,
                                $exitObj,
                            );

                            # If the exit has a twin, that exit should also be a super-region exit
                            #   (unless the user has marked the twin as definitely NOT being a
                            #   super-region exit)
                            if ($exitObj->twinExit) {

                                $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
                                if (
                                    $twinExitObj->regionFlag
                                    && ! $twinExitObj->superFlag
                                    && ! $twinExitObj->notSuperFlag
                                ) {
                                    $twinExitObj->ivPoke('superFlag', TRUE);
                                    $twinRoomObj = $self->ivShow('modelHash', $twinExitObj->parent);
                                    $twinRegionObj
                                        = $self->ivShow('modelHash', $twinRoomObj->parent);
                                    $twinRegionmapObj
                                        = $self->ivShow('regionmapHash', $twinRegionObj->name);

                                    # Create region paths from the twin exit, too
                                    $self->connectRegionExits(
                                        $session,
                                        $twinRegionmapObj,
                                        $twinRoomObj,
                                        $twinExitObj,
                                    );
                                }
                            }
                        }

                        # Update the regionmap's list of region objects
                        $regionmapObj->storeRegionExit($session, $exitObj);
                        if ($twinRegionmapObj) {

                            $twinRegionmapObj->storeRegionExit($session, $twinExitObj);
                        }

                    } else {

                        # It's an existing region exit that has been modified (but not changed
                        #   region). Check all region paths starting or ending at this exit, to make
                        #   sure they're still valid and, if not, mark them for removal
                        INNER: foreach my $exitString ($regionmapObj->ivKeys('regionPathHash')) {

                            my $pathObj = $regionmapObj->ivShow('regionPathHash', $exitString);

                            if (
                                (
                                    $pathObj->startExit == $exitObj->number
                                    || $pathObj->stopExit == $exitObj->number
                                ) && ! $self->checkRegionPath($pathObj, $regionmapObj, FALSE)
                            ) {
                                $regionmapObj->removePaths($exitString, 'regionPathHash');
                            }
                        }

                        INNER: foreach my $exitString (
                            $regionmapObj->ivKeys('safeRegionPathHash')
                        ) {
                            my $pathObj = $regionmapObj->ivShow('safeRegionPathHash', $exitString);

                            if (
                                (
                                    $pathObj->startExit == $exitObj->number
                                    || $pathObj->stopExit == $exitObj->number
                                ) && ! $self->checkRegionPath($pathObj, $regionmapObj, TRUE)
                            ) {
                                $regionmapObj->removePaths($exitString, 'safeRegionPathHash');
                            }
                        }
                    }

                } until (! @newModList);
            }
        }

        # Next, deal with all non-region exits which have been created, modified or deleted since
        #   the last spin of the timer loop (if any)
        if (%otherHash) {

            # Remove any region exits (which have already been processed)
            foreach my $otherExitNum (keys %otherHash) {

                my $regionmapObj;

                if (exists $boundaryHash{$otherExitNum}) {

                    delete $otherHash{$otherExitNum};

                } else {

                    # (As we go, create a hash of affected regionmaps, so that later on we can
                    #   check super-region exits)
                    $regionmapObj = $self->ivShow('regionmapHash', $otherHash{$otherExitNum});
                    if ($regionmapObj) {

                        # (If a whole region is being deleted, $regionmapObj will be 'undef')
                        $otherRegionmapHash{$regionmapObj->number} = $regionmapObj;
                    }
                }
            }

            # Now, for each regionmap in %otherRegionmapHash, check each region path in turn. If any
            #   of them use any of the exits still in %otherHash, the path must be recalculated
            OUTER: foreach my $regionmapObj (values %otherRegionmapHash) {

                # (Add to our hash of affected regionmaps)
                $regionmapHash{$regionmapObj->number} = $regionmapObj;

                CENTRE: foreach my $pathObj ($regionmapObj->ivValues('regionPathHash')) {

                    INNER: foreach my $exitNum (
                        $pathObj->startExit,
                        $pathObj->exitList,
                        $pathObj->stopExit,
                    ) {
                        if (exists $otherHash{$exitNum}) {

                            # Replace the path
                            $self->replaceRegionPath($session, $pathObj, $regionmapObj, FALSE);

                            last INNER;
                        }
                    }
                }

                CENTRE: foreach my $pathObj ($regionmapObj->ivValues('safeRegionPathHash')) {

                    INNER: foreach my $exitNum (
                        $pathObj->startExit,
                        $pathObj->exitList,
                        $pathObj->stopExit,
                    ) {
                        if (exists $otherHash{$exitNum}) {

                            # Replace the path
                            $self->replaceRegionPath($session, $pathObj, $regionmapObj, TRUE);

                            last INNER;
                        }
                    }
                }
            }
        }

        # Each affected region has been stored in %regionmapHash. Now check each of those
        #   regionmaps in turn and add new super-region exits and paths, as necessary
        foreach my $regionmapObj (values %regionmapHash) {

            my (%mainHash, %superHash);

            # Check each region exit. If there are one or more region exits leading to the same
            #   destination region, and none of them are super-region exits, mark one as a
            #   super-region exit

            # Compile a hash in the form
            #   $mainHash{destination_region_number} = [reference_to_list_of_region_exit_numbers]
            # For each super-region exit found, compile a parallel hash in the form
            #   $superHash{destination_region_number} = undef

            foreach my $exitNum ($regionmapObj->ivKeys('regionExitHash')) {

                my ($exitObj, $destRegionNum, $listRef);

                $destRegionNum = $regionmapObj->ivShow('regionExitHash', $exitNum);
                $exitObj = $self->ivShow('exitModelHash', $exitNum);

                if (! exists $mainHash{$destRegionNum}) {

                    $mainHash{$destRegionNum} = [$exitNum];

                } else {

                    $listRef = $mainHash{$destRegionNum};
                    push (@$listRef, $exitNum);
                }

                if ($exitObj->superFlag) {

                    $superHash{$destRegionNum} = undef;
                }
            }

            # Check each destination region in turn. If none of the region exits leading to it are
            #   super-region exits, mark one as a super-region exit, and then create region paths
            #   between it and every other super-region exit in $regionmapObj
            OUTER: foreach my $destRegionNum (keys %mainHash) {

                my (
                    $listRef, $superExitObj, $superRoomObj,
                    @thisList,
                );

                $listRef = $mainHash{$destRegionNum};

                if (! exists $superHash{$destRegionNum}) {

                    # By default, the preferred super-region exit is the one with the lowest exit
                    #   number (which was probably created first). We can't use exits which have
                    #   been marked by the user as normal super-region exits
                    @thisList = sort {$a <=> $b} (@$listRef);
                    INNER: foreach my $otherExitNum (@thisList) {

                        my $otherExitObj = $self->ivShow('exitModelHash', $otherExitNum);
                        if (! $otherExitObj->notSuperFlag) {

                            # We can use this exit
                            $superExitObj = $otherExitObj;
                            last INNER;
                        }
                    }

                    if ($superExitObj) {

                        $superRoomObj = $self->ivShow('modelHash', $superExitObj->parent);
                        $superExitObj->ivPoke('superFlag', TRUE);

                        # Create region paths between this super-region exit and every other
                        #   super-region exit in the region
                        $self->connectRegionExits(
                            $session,
                            $regionmapObj,
                            $superRoomObj,
                            $superExitObj,
                        );
                    }
                }
            }
        }

        # Reset IVs
        $self->ivEmpty('updateBoundaryHash');
        $self->ivEmpty('updatePathHash');
        $self->ivEmpty('deleteBoundaryHash');

        return 1;
    }

    sub connectRegionExits {

        # Called by $self->updateRegionPaths, ->recalculateRegionPaths, ->recalculateSpecificPaths
        #   and ->setSuperRegionExit
        # Given a region exit (which will normally be a super-region exit, but doesn't have to be),
        #   create paths between the region exit and all other super-region exits in the same
        #   region
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $regionmapObj   - The GA::Obj::Regionmap which contains the room
        #   $roomObj        - A GA::ModelObj::Room contained in the region
        #   $exitObj        - One of the room's GA::Obj::Exit objects (a region exit)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $regionmapObj, $roomObj, $exitObj, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $regionmapObj || ! defined $roomObj
            || ! defined $exitObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->connectRegionExits', @_);
        }

        OUTER: foreach my $otherExitNum ($regionmapObj->ivKeys('regionExitHash')) {

            my (
                $otherExitObj, $otherRoomObj, $pathRoomListRef, $pathExitListRef, $pathObj,
                $reverseRoomListRef, $reverseExitListRef, $safePathRoomListRef,
                $safePathExitListRef, $safeReverseRoomListRef, $safeReverseExitListRef,
            );

            # Get the other boundary exit and its parent room
            $otherExitObj = $self->ivShow('exitModelHash', $otherExitNum);
            $otherRoomObj = $self->ivShow('modelHash', $otherExitObj->parent);

            # Don't try to draw a path between $exitObj and itself, and don't use non-super region
            #   exits
            if ($otherExitNum == $exitObj->number || ! $otherExitObj->superFlag) {

                next OUTER;
            }

            # Find the shortest path between the two boundary rooms
            ($pathRoomListRef, $pathExitListRef) = $self->findPath(
                $roomObj,
                $otherRoomObj,
                FALSE,              # Don't avoid hazards
                undef,
                TRUE,               # Don't use adjacent regions
            );

            # If there is actually a path between the two rooms...
            if (@$pathRoomListRef) {

                # Save it
                $pathObj = Games::Axmud::Obj::RegionPath->new(
                    $session,
                    $exitObj->number,
                    $otherExitObj->number,
                    $pathRoomListRef,
                    $pathExitListRef,
                );

                if ($pathObj) {

                    # Store the path, replacing any previously-existing path between the same two
                    #   exits
                    $regionmapObj->storePath('regionPathHash', $exitObj, $otherExitObj, $pathObj);
                }
            }

            # Also find the reverse path
            ($reverseRoomListRef, $reverseExitListRef) = $self->findPath(
                $otherRoomObj,
                $roomObj,
                FALSE,              # Don't avoid hazards
                undef,
                TRUE,               # Don't use adjacent regions
            );

            # Save it, if found
            if (@$reverseRoomListRef) {

                # Save it
                $pathObj = Games::Axmud::Obj::RegionPath->new(
                    $session,
                    $otherExitObj->number,
                    $exitObj->number,
                    $reverseRoomListRef,
                    $reverseExitListRef,
                );

                if ($pathObj) {

                    # Store the path, replacing any previously-existing path between the same two
                    #   exits
                    $regionmapObj->storePath('regionPathHash', $otherExitObj, $exitObj, $pathObj);
                }
            }

            # Now we repeat this process using only paths that avoid rooms with hazardous room
            #   flags

            # Find the shortest path between the new boundary room, $roomObj, and the parent
            #   room of the other exit
            ($safePathRoomListRef, $safePathExitListRef) = $self->findPath(
                $roomObj,
                $otherRoomObj,
                TRUE,               # Avoid hazards
                undef,
                TRUE,               # Don't use adjacent regions
            );

            # If there is actually a safe path between the two rooms...
            if (@$safePathRoomListRef) {

                # Save it
                $pathObj = Games::Axmud::Obj::RegionPath->new(
                    $session,
                    $exitObj->number,
                    $otherExitObj->number,
                    $safePathRoomListRef,
                    $safePathExitListRef,
                );

                if ($pathObj) {

                    # Store the path, replacing any previously-existing path between the same two
                    #   exits
                    $regionmapObj->storePath(
                        'safeRegionPathHash',
                        $exitObj,
                        $otherExitObj,
                        $pathObj,
                    );
                }
            }

            # Also find the reverse path
            ($safeReverseRoomListRef, $safeReverseExitListRef) = $self->findPath(
                $otherRoomObj,
                $roomObj,
                TRUE,           # Avoid hazards
                undef,
                TRUE,               # Don't use adjacent regions
            );

            # If there is actually a safe path between the two rooms...
            if (@$safeReverseRoomListRef) {

                # Save it
                $pathObj = Games::Axmud::Obj::RegionPath->new(
                    $session,
                    $otherExitObj->number,
                    $exitObj->number,
                    $safeReverseRoomListRef,
                    $safeReverseExitListRef,
                );

                if ($pathObj) {

                    # Store the path, replacing any previously-existing path between the same two
                    #   exits
                    $regionmapObj->storePath(
                        'safeRegionPathHash',
                        $otherExitObj,
                        $exitObj,
                        $pathObj,
                    );
                }
            }
        }

        # Operation complete
        return 1;
    }

    sub checkRegionPath {

        # Called by $self->updateRegionPaths
        # Checks the path stored in a GA::Obj::RegionPath object, to make sure it is still usable
        #
        # Expected arguments
        #   $pathObj        - The region path object to check
        #   $regionmapObj   - The GA::Obj::Regionmap corresponding to the region path
        #   $safeFlag       - Set to TRUE if the path should avoid rooms with hazardous room flags,
        #                       FALSE if the path can use rooms with hazardous room flags
        #
        # Return values
        #   'undef' on improper arguments or if the path is no longer usable
        #   1 if the path is still usable

        my ($self, $pathObj, $regionmapObj, $safeFlag, $check) = @_;

        # Local variables
        my (
            @roomList, @exitList,
            %hazardHash,
        );

        # Check for improper arguments
        if (
            ! defined $pathObj || ! defined $regionmapObj || ! defined $safeFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkRegionPath', @_);
        }

        # Import the path object's list of rooms and exits
        @roomList = $pathObj->roomList;
        @exitList = $pathObj->exitList;
        # For speed, import the hash of hazardous room flags
        %hazardHash = $axmud::CLIENT->constRoomHazardHash;

        # If the room list is empty then, of course, the path is not usable
        if (! @roomList) {

            return undef;
        }

        do {

            my ($roomNum, $roomObj, $exitNum, $exitObj, $nextRoomObj);

            $roomNum = shift @roomList;
            $exitNum = shift @exitList;

            # Check that the room still exists
            $roomObj = $self->ivShow('modelHash', $roomNum);
            if (! $roomObj) {

                return undef;
            }

            # Check that the room is still in the right region
            if ($roomObj->parent ne $regionmapObj->number) {

                return undef;
            }

            # Check that the room does not contain hazardous room flags (if $safeFlag is set)
            if ($safeFlag && $roomObj->roomFlagHash) {

                foreach my $roomFlag ($roomObj->ivKeys('roomFlagHash')) {

                    if (exists $hazardHash{$roomFlag}) {

                        return undef;
                    }
                }
            }

            if (! defined $exitNum) {

                # We've reached the end of the path, which is therefore usable
                return 1;
            }

            # Check that the exit still exists
            $exitObj = $self->ivShow('exitModelHash', $exitNum);
            if (! $exitObj) {

                return undef;
            }

            # Check that the exit leads to the correct destination room (i.e., the next room in
            #   @roomList)
            $nextRoomObj = $self->ivShow('modelHash', $roomList[0]);
            if (! $exitObj->destRoom || $exitObj->destRoom ne $nextRoomObj->number) {

                return undef;
            }

            # Check that the exit is passable
            if ($exitObj->exitOrnament eq 'impass' || $exitObj->exitOrnament eq 'mystery') {

                return undef;
            }

        } until (! @roomList);

        # Emergency default - the path is not usable
        return undef;
    }

    sub replaceRegionPath {

        # Called by $self->updateRegionPaths
        # Replaces a region path with a new GA::Obj::RegionPath object
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $pathObj        - The region path object to check
        #   $regionmapObj   - The GA::Obj::Regionmap corresponding to the region path
        #   $safeFlag       - Set to TRUE if the path should avoid rooms with hazardous room flags,
        #                       FALSE if the path can use rooms with hazardous room flags
        #
        # Return values
        #   'undef' on improper arguments or if the path is no longer usable
        #   1 if the path is still usable

        my ($self, $session, $pathObj, $regionmapObj, $safeFlag, $check) = @_;

        # Local variables
        my (
            $startExitObj, $stopExitObj, $startRoomObj, $stopRoomObj, $pathRoomListRef,
            $pathExitListRef, $newPathObj, $exitString,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $pathObj || ! defined $regionmapObj
            || ! defined $safeFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->replaceRegionPath', @_);
        }

        # Get the boundary exits from the existing region path
        $startExitObj = $self->ivShow('exitModelHash', $pathObj->startExit);
        $stopExitObj = $self->ivShow('exitModelHash', $pathObj->stopExit);
        # Get their parent rooms
        $startRoomObj = $self->ivShow('modelHash', $startExitObj->parent);
        $stopRoomObj = $self->ivShow('modelHash', $stopExitObj->parent);

        # Find the shortest path between the two boundary rooms
        ($pathRoomListRef, $pathExitListRef) = $self->findPath(
            $startRoomObj,
            $stopRoomObj,
            $safeFlag,          # Avoid hazards, or not
            undef,
            TRUE,               # Don't use adjacent regions
        );

        # If there is actually a path between the two rooms...
        if (@$pathRoomListRef) {

            # Save it
            $newPathObj = Games::Axmud::Obj::RegionPath->new(
                $session,
                $startExitObj->number,
                $stopExitObj->number,
                $pathRoomListRef,
                $pathExitListRef,
            );

            if ($newPathObj) {

                # Store the path, replacing any previously-existing path between the same two
                #   exits
                if (! $safeFlag) {

                    $regionmapObj->storePath(
                        'regionPathHash',
                        $startExitObj,
                        $stopExitObj,
                        $newPathObj,
                    );

                } else {

                    $regionmapObj->storePath(
                        'safeRegionPathHash',
                        $startExitObj,
                        $stopExitObj,
                        $newPathObj,
                    );
                }
            }

        } else {

            # Even though a new path could not be found, the existing path is invalid, and must be
            #   removed
            $exitString = $pathObj->startExit . '_' . $pathObj->stopExit;

            if (! $safeFlag) {
                $regionmapObj->removePaths($exitString, 'regionPathHash');
            } else {
                $regionmapObj->removePaths($exitString, 'safeRegionPathHash');
            }
        }

        return 1;
    }

    sub updateModelBuffers {

        # Called by GA::Session->spinMaintainLoop
        # When a model object or exit object is deleted, the number is temporarily stored in
        #   $self->modelBufferList or $self->exitBufferList
        # If either IV contains any numbers, copy them into ->modelDeletedList or ->exitDeletedList
        #   so that they're available for re-use
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateModelBuffers', @_);
        }

        if ($self->modelBufferList) {

            $self->ivPush('modelDeletedList', sort {$a <=> $b} ($self->modelBufferList));
            $self->ivEmpty('modelBufferList');
        }

        if ($self->exitBufferList) {

            $self->ivPush('exitDeletedList', sort {$a <=> $b} ($self->exitBufferList));
            $self->ivEmpty('exitBufferList');
        }

        return 1
    }

    sub updateRegionLevels {

        # Called by GA::Session->spinMaintainLoop
        # When a room model object or map label is added, moved or deleted, the parent regionmap's
        #   name is temporarily stored in $self->checkLevelsHash
        # Ask each regionmap to re-calculate its highest and lowest occupied levels
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @mapWinList;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRegionLevels', @_);
        }

        # Collect a list of automapper windows used by this world model now (so we only have to do
        #   it once)
        @mapWinList = $self->collectMapWins();

        OUTER: foreach my $regionName ($self->ivKeys('checkLevelsHash')) {

            my ($regionmapObj, $high, $low);

            $regionmapObj = $self->ivShow('regionmapHash', $regionName);
            if (! $regionmapObj) {

                # Region has just been deleted, so move on to the next one
                next OUTER;
            }

            # Check every room in the map, finding the highest and lowest occupied level
            foreach my $roomNum ($regionmapObj->ivValues('gridRoomHash')) {

                my $roomObj = $self->ivShow('modelHash', $roomNum);
                if ($roomObj) {

                    if (! defined $high || $high < $roomObj->zPosBlocks) {

                        $high = $roomObj->zPosBlocks;
                    }

                    if (! $low || $low > $roomObj->zPosBlocks) {

                        $low = $roomObj->zPosBlocks;
                    }
                }
            }

            # Likewise check every label
            foreach my $labelObj ($regionmapObj->ivValues('gridLabelHash')) {

                if (! defined $high || $high < $labelObj->level) {

                    $high = $labelObj->level;
                }

                if (! $low || $low > $labelObj->level) {

                    $low = $labelObj->level;
                }
            }

            # If there are no rooms/labels in the regionmap, $high and $low will be 'undef' which
            #   is, in that situation, also the correct value for the IVs
            $regionmapObj->ivPoke('highestLevel', $high);
            $regionmapObj->ivPoke('lowestLevel', $low);

            # All parchment objects can now be updated to remove canvas widgets for the unoccupied
            #   levels (in this case, treat the window's visible level as the highest or lowest
            #   level)
            foreach my $mapWin (@mapWinList) {

                my ($thisHigh, $thisLow, $parchmentObj);

                if (! defined $regionmapObj->highestLevel) {

                    $thisHigh = 0;
                    $thisLow = 0;

                } else {

                    $thisHigh = $regionmapObj->highestLevel;
                    $thisLow = $regionmapObj->lowestLevel;
                }

                if ($mapWin->currentRegionmap) {

                    if ($mapWin->currentRegionmap->currentLevel > $thisHigh) {
                        $thisHigh = $mapWin->currentRegionmap->currentLevel;
                    } elsif ($mapWin->currentRegionmap->currentLevel < $thisLow) {
                        $thisLow = $mapWin->currentRegionmap->currentLevel;
                    }
                }

                # Furthermore, increase the highest/lowest occupied level by 1 so that room
                #   echos can be drawn
                $thisHigh++;
                $thisLow--;

                # Remove any redundant canvas widgets
                $parchmentObj = $mapWin->ivShow('parchmentHash', $regionmapObj->name);
                if ($parchmentObj) {

                    foreach my $level ($parchmentObj->ivKeys('canvasWidgetHash')) {

                        if ($level > $thisHigh || $level < $thisLow) {

                            $parchmentObj->ivDelete('canvasWidgetHash', $level);
                            $parchmentObj->ivDelete('bgCanvasObjHash', $level);
                            $parchmentObj->ivDelete('levelHash', $level);
                        }
                    }
                }
            }
        }

        # Update any GA::Win::Map objects using this world model
        foreach my $mapWin (@mapWinList) {

            # If the automapper is showing the same region...
            if (
                $mapWin->currentRegionmap
                && $self->ivExists('checkLevelsHash', $mapWin->currentRegionmap->name)
            ) {
                # ...redraw its title bar to show up/down arrows
                $mapWin->setWinTitle();
                # Sensitise/desensitise menu bar/toolbar items, depending on current conditions (as
                #   a response to this calculation)
                $mapWin->restrictWidgets();
            }
        }

        # Reset the IV
        $self->ivEmpty('checkLevelsHash');

        return 1
    }

    # Model test methods

    sub testModel {

        # Called by GA::Cmd::TestModel->do, GA::Cmd::MergeModel->do (or by any other function)
        # Tests the integrity of the world model and (optionally) fixes as many errors as possible
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #
        # Optional values
        #   $fixFlag        - If TRUE, fixes any errors that can be fixed. If FALSE or 'undef', does
        #                       not attempt to fix any errors
        #   $diagnoseFlag   - If TRUE, returns a list of values. If FALSE or 'undef', returns a
        #                       simple pass or fail value
        #
        # Return values
        #   If $diagnoseFlag is TRUE:
        #       Returns an empty list on improper arguments
        #       Otherwise, returns a list in the form
        #           (error_count, fix_count, message, message, message...)
        #       ...where 'message' are any number (including zero) of error messages
        #   If $diagnoseFlag is FALSE or 'undef':
        #       Returns 'undef' on improper arguments or if there are any errors
        #       Returns 1 if there are no errors

        my ($self, $session, $fixFlag, $diagnoseFlag, $check) = @_;

        # Local variables
        my (
            $errorCount, $fixCount, $count,
            @emptyList, @outputList, @categoryList,
            %modelHash, %exitModelHash, %regionModelHash, %regionmapHash, %charModelHash,
            %knownCharHash, %roomModelHash, %roomTagHash, %abandonExitHash,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->testModel', @_);

            if ($diagnoseFlag) {
                return @emptyList;
            } else {
                return undef;
            }
        }

        # So that the calls to $self->testModelRoom and $self->testModelExit can do better improper
        #   arguments checks, give the optional flags defined values
        if (! $fixFlag) {
            $fixFlag = FALSE;
        } else {
            $fixFlag = TRUE;
        }

        if (! $diagnoseFlag) {
            $diagnoseFlag = FALSE;
        } else {
            $diagnoseFlag = TRUE;
        }

        # Initialise counts
        $errorCount = 0;
        $fixCount = 0;

        # Check that ->modelActualCount and ->exitActualCount are correct
        %modelHash = $self->modelHash;
        $count = scalar (keys %modelHash);
        if ($count != $self->modelActualCount) {

            push (@outputList,
                '   ->modelActualCount should be ' . $self->modelActualCount . ', but is '
                . $count,
            );

            $errorCount++;
            if ($fixFlag) {

                # When -f is used, fix errors
                $self->ivPoke('modelActualCount', scalar (keys %modelHash));
                $fixCount++;
            }
        }

        %exitModelHash = $self->exitModelHash;
        $count = scalar (keys %exitModelHash);
        if ($count != $self->exitActualCount) {

            push (@outputList,
                '   ->exitActualCount should be ' . $self->exitActualCount . ', but is '
                . $count,
            );

            $errorCount++;
            if ($fixFlag) {

                $self->ivPoke('exitActualCount', scalar (keys %exitModelHash));
                $fixCount++;
            }
        }

        # Check that ->modelDeletedList and ->exitDeletedList are not still in the model
        %modelHash = $self->modelHash;
        foreach my $num ($self->modelDeletedList) {

            if (exists $modelHash{$num}) {

                push (@outputList,
                    '   Deleted model object #' . $num . ' still exists in the model',
                );

                $errorCount++;
                if ($fixFlag) {

                    $self->ivDelete('modelHash', $num);
                    $fixCount++;
                }
            }
        }

        %exitModelHash = $self->exitModelHash;
        foreach my $num ($self->exitDeletedList) {

            if (exists $exitModelHash{$num}) {

                push (@outputList,
                    '   Deleted exit model object #' . $num . ' still exists in the exit model',
                );

                $errorCount++;
                if ($fixFlag) {

                    $self->ivDelete('exitModelHash', $num);
                    $fixCount++;
                }
            }
        }

        # Check that ->modelBufferList and ->exitBufferList are not still in the model
        %modelHash = $self->modelHash;
        foreach my $num ($self->modelBufferList) {

            if (exists $modelHash{$num}) {

                push (@outputList,
                    '   Buffered model object #' . $num . ' still exists in the model',
                );

                $errorCount++;
                if ($fixFlag) {

                    $self->ivDelete('modelHash', $num);
                    $fixCount++;
                }
            }
        }

        %exitModelHash = $self->exitModelHash;
        foreach my $num ($self->exitBufferList) {

            if (exists $exitModelHash{$num}) {

                push (@outputList,
                    '   Buffered exit model object #' . $num . ' still exists in the exit model',
                );

                $errorCount++;
                if ($fixFlag) {

                    $self->ivDelete('exitModelHash', $num);
                    $fixCount++;
                }
            }
        }

        # Check that everything in ->regionModelHash, etc, is the right category, exists in
        #   ->modelHash and points to the same object
        @categoryList = (
            'region', 'room', 'weapon', 'armour', 'garment', 'char', 'minion', 'sentient',
            'creature', 'portable', 'decoration', 'custom',
        );

        %modelHash = $self->modelHash;
        OUTER: foreach my $category (@categoryList) {

            my (
                $iv,
                %thisHash,
            );

            $iv = $category . 'ModelHash';      # e.g. ->regionModelHash
            %thisHash = $self->$iv;

            INNER: foreach my $num (keys %thisHash) {

                my ($obj, $realObj);

                $obj = $thisHash{$num};

                if (! exists $modelHash{$num}) {

                    push (@outputList,
                        '   \'' . $category . '\' object exists in ->' . $iv . ', but not in'
                        . '->modelHash',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        $self->ivDelete($iv, $num);
                        $fixCount++;
                    }

                    next INNER;
                }

                if ($obj->category ne $category) {

                    push (@outputList,
                        '   \'' . $category . '\' object exists in ->' . $iv . ', but is not a \''
                        . $category . '\' object',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        $self->ivDelete($iv, $num);
                        $fixCount++;
                    }

                    next INNER;
                }

                $realObj = $modelHash{$num};
                if ($realObj ne $obj) {

                    push (@outputList,
                        '   \'' . $category . '\' object exists in ->' . $iv . ', but is not the'
                        . ' same object that exists in ->modelHash',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        $self->ivDelete($iv, $num);
                        $fixCount++;
                    }

                    next INNER;
                }
            }
        }

        # Check that every exit has a parent room
        %modelHash = $self->modelHash;
        %exitModelHash = $self->exitModelHash;
        OUTER: foreach my $exitObj (values %exitModelHash) {

            my $roomObj = $modelHash{$exitObj->parent};
            if (! $roomObj) {

                push (@outputList,
                    '   Exit #'  . $exitObj->number . ' does not have a parent room',
                );

                $errorCount++;
                if ($fixFlag) {

                    # Cannot call GA::Obj::WorldModel->deleteExit, as that function assumes the exit
                    #   has a parent room and that the room has a parent region; instead, use a
                    #   function written especially for ;testmodel
                    $self->emergencyDeleteExit($exitObj);
                    $fixCount++;
                }

            } elsif ($roomObj->category ne 'room') {

                push (@outputList,
                    '   Exit #'  . $exitObj->number . ' has a parent room #' . $roomObj->number
                    . ' which is actually a \'' . $roomObj->category . '\' object',
                );

                $errorCount++;
                if ($fixFlag) {

                    $self->emergencyDeleteExit($exitObj);
                    $fixCount++;
                }
            }
        }

        # Check that every exit has a defined ->mapDir (except for unallocatable exits, whose
        #   ->drawMode is 'temp_unalloc'; in that case, ->mapDir must be 'undef')
        %exitModelHash = $self->exitModelHash;
        OUTER: foreach my $exitObj (values %exitModelHash) {

            if ($exitObj->drawMode eq 'temp_unalloc' && defined $exitObj->mapDir) {

                push (@outputList,
                    '   Unallocatable exit #'  . $exitObj->number . ' has a defined map'
                    . ' direction \'' . $exitObj->mapDir,
                );

                $errorCount++;
                if ($fixFlag) {

                    $self->emergencyDeleteExit($exitObj);
                    $fixCount++;
                }

            } elsif ($exitObj->drawMode ne 'temp_unalloc' && ! defined $exitObj->mapDir) {

                push (@outputList,
                    '   Exit #'  . $exitObj->number . ' has an undefined map direction (and is not'
                    . ' unallocatable)',
                );

                $errorCount++;
                if ($fixFlag) {

                    $self->emergencyDeleteExit($exitObj);
                    $fixCount++;
                }
            }
        }

        # Check that the regionmap list matches the region list
        %regionModelHash = $self->regionModelHash;
        %regionmapHash = $self->regionmapHash;
        OUTER: foreach my $regionName (keys %regionmapHash) {

            my $regionmapObj = $regionmapHash{$regionName};

            if (! exists $regionModelHash{$regionmapObj->number}) {

                push (@outputList,
                    '   Regionmap \'' . $regionName . '\' does not have a corresponding region'
                    . ' object in ->regionModelHash (not auto-fixable)',
                );

                $errorCount++;

                next OUTER;

            } else {

                delete $regionModelHash{$regionmapObj->number};
            }
        }

        if (%regionModelHash) {

            foreach my $regionObj (values %regionModelHash) {

                push (@outputList,
                    '   Region \'' . $regionObj->name . '\' does not have a corresponding'
                    . ' regionmap in ->regionmapHash (not auto-fixable)',
                );

                $errorCount++;
            }
        }

        # Check that the known character hash matches ->charModelHash
        %charModelHash = $self->charModelHash;
        %knownCharHash = $self->knownCharHash;
        OUTER: foreach my $charName (keys %knownCharHash) {

            my $charObj = $knownCharHash{$charName};

            if (! exists $charModelHash{$charObj->number}) {

                push (@outputList,
                    '   ->knownCharHash \'' . $charName . '\' does not have a corresponding model'
                    . ' object in ->charModelHash (not auto-fixable)',
                );

                $errorCount++;

                next OUTER;

            } else {

                delete $charModelHash{$charObj->number};
            }
        }

        if (%charModelHash) {

            foreach my $charObj (values %charModelHash) {

                push (@outputList,
                    '   Character \'' . $charObj->name . '\' does not have a corresponding'
                    . ' entry in ->knownCharHash (not auto-fixable)',
                );

                $errorCount++;
            }
        }

        # Check that ->roomTagHash is right
        %roomModelHash = $self->roomModelHash;
        %roomTagHash = $self->roomTagHash;
        OUTER: foreach my $tag (keys %roomTagHash) {

            my ($roomNum, $roomObj);

            $roomNum = $roomTagHash{$tag};

            if (! exists $roomModelHash{$roomNum}) {

                push (@outputList,
                    '   ->roomTagHash tag \'' . $tag . '\' points to room #' . $roomNum
                    . ' which is not in ->roomModelHash (not auto-fixable)',
                );

                $errorCount++;

                next OUTER;
            }

            $roomObj = $roomModelHash{$roomNum};
            if (! $roomObj->roomTag) {

                push (@outputList,
                    '   ->roomTagHash tag \'' . $tag . '\' points to room #' . $roomNum
                    . ' which does not have a room tag (not auto-fixable)',
                    );

                $errorCount++;

                next OUTER;

            } elsif ($roomObj->roomTag ne $tag) {

                push (@outputList,
                    '   ->roomTagHash tag \'' . $tag . '\' points to room #' . $roomNum
                    . ' which has a different room tag, \'' . $roomObj->roomTag . '\' (not'
                    . ' auto-fixable)',
                );

                $errorCount++;

                next OUTER;

            } else {

                delete $roomModelHash{$roomNum};
            }
        }

        foreach my $roomObj (values %roomModelHash) {

            if ($roomObj->roomTag) {

                push (@outputList,
                    '   ->roomModelHash room \'' . $roomObj->number . '\' has a room tag \''
                    . $roomObj->roomTag . '\' which has no corresponding entry in ->roomTagHash'
                    . ' (not auto-fixable)',
                );

                $errorCount++;

                next OUTER;
            }
        }

        # Check that every room's exits exist in the exit model
        %roomModelHash = $self->roomModelHash;
        %exitModelHash = $self->exitModelHash;
        OUTER: foreach my $roomObj (values %roomModelHash) {

            my (
                @sortedExitList,
                %exitNumHash,
            );

            @sortedExitList = $roomObj->sortedExitList;
            %exitNumHash = $roomObj->exitNumHash;

            INNER: foreach my $exitDir (keys %exitNumHash) {

                my $exitNum = $exitNumHash{$exitDir};

                if (! exists $exitModelHash{$exitNum}) {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' exit #' . $exitNum . ' does not exist in'
                        . ' ->exitModelHash',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        my @newList;

                        $roomObj->ivDelete('exitNumHash', $exitDir);
                        # Remove the corresponding entry in ->sortedExitList
                        foreach my $item (@sortedExitList) {

                            if ($item ne $exitDir) {

                                push (@newList, $item);
                            }
                        }

                        $roomObj->ivPoke('sortedExitList', @newList);
                        $fixCount++;
                    }
                }

                next INNER;
            }
        }

        # Check that every room's exit has corresponding entries in ->sortedExitList and
        #   ->exitNumHash
        %roomModelHash = $self->roomModelHash;
        OUTER: foreach my $roomObj (values %roomModelHash) {

            my (
                @sortedExitList,
                %exitNumHash,
            );

            @sortedExitList = $roomObj->sortedExitList;
            %exitNumHash = $roomObj->exitNumHash;

            foreach my $dir (@sortedExitList) {

                if (! exists $exitNumHash{$dir}) {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' exit in direction \'' . $dir . '\' does'
                        . ' not have a corresponding entry in ->exitNumHash (not auto-fixable)',
                    );

                    $errorCount++;

                } else {

                    delete $exitNumHash{$dir};
                }
            }

            if (%exitNumHash) {

                foreach my $dir (keys %exitNumHash) {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' exit #' . $dir . '\' does not have a'
                        . ' corresponding entry in ->sortedExitList (not auto-fixable)',
                    );

                    $errorCount++;
                }
            }
        }

        # Check that every twinned exit's twin still exists, and knows about its twin
        %exitModelHash = $self->exitModelHash;
        OUTER: foreach my $exitObj (values %exitModelHash) {

            my $twinExitObj;

            if ($exitObj->twinExit) {

                if (! exists $exitModelHash{$exitObj->twinExit}) {

                    push (@outputList,
                        '   Exit #' . $exitObj->number . ' has a twin exit #' . $exitObj->twinExit
                         . ' which no longer exists',
                    );

                    $errorCount++;
                    # We'll get all the mismatched twin exits to abandon each other all in one go,
                    #   in a moment
                    $abandonExitHash{$exitObj->number} = $exitObj;

                } else {

                    $twinExitObj = $exitModelHash{$exitObj->twinExit};
                    if (! $twinExitObj->twinExit) {

                        push (@outputList,
                            '   Exit #' . $exitObj->number . ' has a twin exit #'
                            . $exitObj->twinExit . ' which is not itself twinned to anything',
                        );

                        $errorCount++;
                        $abandonExitHash{$exitObj->number} = $exitObj;

                    } elsif ($twinExitObj->twinExit != $exitObj->number) {

                        push (@outputList,
                            '   Exit #' . $exitObj->number . ' has a twin exit #'
                            . $exitObj->twinExit . ' which is twinned to some other exit (#'
                            . $twinExitObj->twinExit . ')',
                        );

                        $errorCount++;
                        $abandonExitHash{$exitObj->number} = $exitObj;
                    }
                }
            }
        }

        if ($fixFlag) {

            # Abandon any rogue twin exits in %abandonExitHash
            foreach my $exitObj (values %abandonExitHash) {

                $self->abandonTwinExit(
                    FALSE,          # Don't update Automapper windows yet
                    $exitObj,
                );

                $fixCount++;
            }
        }

        # Check that every incoming uncertain, one way and random exit still exists, and actually
        #   points to its room
        %exitModelHash = $self->exitModelHash;
        %roomModelHash = $self->roomModelHash;
        OUTER: foreach my $roomObj (values %roomModelHash) {

            my (%uncertainExitHash, %oneWayExitHash, %randomExitHash);

            %uncertainExitHash = $roomObj->uncertainExitHash;
            %oneWayExitHash = $roomObj->oneWayExitHash;
            %randomExitHash = $roomObj->randomExitHash;

            INNER: foreach my $exitNum (keys %uncertainExitHash) {

                my $exitObj;

                if (! exists $exitModelHash{$exitNum}) {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' incoming uncertain exit #' . $exitNum
                        . ' does not exist in ->exitModelHash (not auto-fixable)',
                    );

                    $errorCount++;
                    next INNER;
                }

                $exitObj = $exitModelHash{$exitNum};
                if (! $exitObj->destRoom || $exitObj->destRoom != $roomObj->number) {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' incoming uncertain exit #' . $exitNum
                        . ' does not lead to the room (not auto-fixable)',
                    );

                    $errorCount++;
                    next INNER;
                }
            }

            INNER: foreach my $exitNum (keys %oneWayExitHash) {

                my $exitObj;

                if (! exists $exitModelHash{$exitNum}) {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' incoming one-way exit #' . $exitNum
                        . ' does not exist in ->exitModelHash (not auto-fixable)',
                    );

                    $errorCount++;
                    next INNER;
                }

                $exitObj = $exitModelHash{$exitNum};
                if (! $exitObj->destRoom || $exitObj->destRoom != $roomObj->number) {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' incoming one-way exit #' . $exitNum
                        . ' does not lead to the room (not auto-fixable)',
                    );

                    $errorCount++;
                    next INNER;
                }
            }

            INNER: foreach my $exitNum (keys %randomExitHash) {

                my ($exitObj, $matchFlag);

                if (! exists $exitModelHash{$exitNum}) {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' incoming random exit #' . $exitNum
                        . ' does not exist in ->exitModelHash (not auto-fixable)',
                    );

                    $errorCount++;
                    next INNER;
                }

                $exitObj = $exitModelHash{$exitNum};
                if ($exitObj->randomType eq 'none') {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' incoming random exit #' . $exitNum
                        . ' is not marked as a random exit (not auto-fixable)',
                    );

                    $errorCount++;
                    next INNER;

                } elsif ($exitObj->randomType ne 'room_list') {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' incoming random exit #' . $exitNum
                        . ' is marked as a random exit of the wrong type (not auto-fixable)',
                    );

                    $errorCount++;
                    next INNER;
                }

                DEEPER: foreach my $destRoomNum ($exitObj->randomDestList) {

                    if ($destRoomNum == $roomObj->number) {

                        $matchFlag = TRUE;
                        last DEEPER;
                    }
                }

                if (! $matchFlag) {

                    push (@outputList,
                        '   Room #' . $roomObj->number . ' incoming random exit #' . $exitNum
                        . ' does not know that it leads to the room (not auto-fixable)',
                    );

                    $errorCount++;
                }
            }
        }

        # Check that only one-way exits have their ->oneWayDir set
        %exitModelHash = $self->exitModelHash;
        OUTER: foreach my $exitObj (values %exitModelHash) {

            if (! $exitObj->oneWayFlag && defined $exitObj->oneWayDir) {

                push (@outputList,
                    '   Exit #' . $exitObj->number . ' is not a one-way exit, but has a one-way'
                    . ' direction set',
                );

                $errorCount++;
                if ($fixFlag) {

                    $exitObj->ivUndef('oneWayDir');
                    $fixCount++;
                }
            }
        }

        # Check every random exit
        %exitModelHash = $self->exitModelHash;
        %roomModelHash = $self->roomModelHash;
        OUTER: foreach my $exitObj (values %exitModelHash) {

            if ($exitObj->randomType ne 'room_list' && $exitObj->randomDestList) {

                push (@outputList,
                    '   Random exit #' . $exitObj->number . ' has a list of destination rooms,'
                    . ' but its ->randomType is not set to \'room_list\' (not auto-fixable)',
                );

                $errorCount++;
                next OUTER;

            } elsif ($exitObj->randomType eq 'room_list') {

                INNER: foreach my $roomNum ($exitObj->randomDestList) {

                    my $roomObj;

                    if (! exists $roomModelHash{$roomNum}) {

                        push (@outputList,
                            '   Random exit #' . $exitObj->number . ' destination room #' . $roomNum
                            . ' does not exist (not auto-fixable)',
                        );

                        $errorCount++;

                    } else {

                        $roomObj = $roomModelHash{$roomNum};
                        if (! $roomObj->ivExists('randomExitHash', $exitObj->number)) {

                            push (@outputList,
                                '   Random exit #' . $exitObj->number . ' destination room #'
                                . $roomNum . ' does not know about the incoming random exit (not'
                                . ' auto-fixable)',
                            );

                            $errorCount++;
                        }
                    }
                }
            }
        }

        # Check every region exit
        %modelHash = $self->modelHash;
        %exitModelHash = $self->exitModelHash;
        OUTER: foreach my $exitObj (values %exitModelHash) {

            my ($roomObj, $destRoomObj, $regionObj);

            if ($exitObj->destRoom) {

                $roomObj = $modelHash{$exitObj->parent};
                $destRoomObj = $modelHash{$exitObj->destRoom};
                if (! $roomObj->parent || ! $destRoomObj->parent) {

                    # This kind of error will have been detected (or created by) the code above
                    next OUTER;

                } elsif ($exitObj->regionFlag && $roomObj->parent == $destRoomObj->parent) {

                    push (@outputList,
                        '   Region exit #' . $exitObj->number . ' destination room #'
                        . $roomObj->parent . ' is actually in the same region',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        # Delete the original exit, and replace it with an incomplete exit in the
                        #   same direction
                        $self->deleteExits(
                            $session,
                            FALSE,      # Don't update Automapper window
                            $exitObj,
                        );

                        $self->addExit(
                            $session,
                            FALSE,      # Don't update Automapper window
                            $roomObj,
                            $exitObj->dir,
                            $exitObj->mapDir,
                        );

                        $fixCount++;
                    }

                } elsif (! $exitObj->regionFlag && $roomObj->parent != $destRoomObj->parent) {

                    push (@outputList,
                        '   Non-region exit #' . $exitObj->number . ' destination room #'
                        . $roomObj->parent . ' is not in the same region',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        # Delete the original exit, and replace it with an incomplete exit in the
                        #   same direction
                        $self->deleteExits(
                            $session,
                            FALSE,      # Don't update Automapper window
                            $exitObj,
                        );

                        $self->addExit(
                            $session,
                            FALSE,      # Don't update Automapper window
                            $roomObj,
                            $exitObj->dir,
                            $exitObj->mapDir,
                        );

                        $fixCount++;
                    }

                } elsif (
                    ! $exitObj->regionFlag
                    && ($exitObj->superFlag || $exitObj->notSuperFlag)
                ) {
                    push (@outputList,
                        '   Non-region exit #' . $exitObj->number . ' is marked as a super-region'
                        . ' exit (or as definitely not a super-region exit',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        # Just update the IVs
                        $exitObj->ivPoke('superFlag', FALSE);
                        $exitObj->ivPoke('notSuperFlag', FALSE);

                        $regionObj = $self->ivShow('modelHash', $roomObj->parent);

                        # Any region paths using the exits will have to be updated
                        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
                        $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);

                        $fixCount++;
                    }
                }
            }
        }

        # Check the integrity of every regionmap
        %modelHash = $self->modelHash;
        %exitModelHash = $self->exitModelHash;
        %regionmapHash = $self->regionmapHash;
        OUTER: foreach my $regionmapObj (values %regionmapHash) {

            my (
                %gridRoomHash, %gridRoomTagHash, %gridRoomGuildHash, %gridExitHash,
                %gridExitTagHash, %regionExitHash, %regionPathHash,
            );

            # Check ->gridRoomHash
            %gridRoomHash = $regionmapObj->gridRoomHash;
            INNER: foreach my $posn (keys %gridRoomHash) {

                my (
                    $roomNum, $roomObj, $eCount, $fCount,
                    @opList,
                );

                $roomNum = $gridRoomHash{$posn};
                $roomObj = $modelHash{$roomNum};
                # Check the room actually exists, and so on
                ($eCount, $fCount, @opList) = $self->testModelRoom(
                    $session,
                    $fixFlag,
                    $regionmapObj,
                    $posn,
                    $roomNum,
                    $roomObj,
                    'gridRoomHash',
                    \%modelHash,
                );

                $errorCount += $eCount;
                $fixCount += $fCount;
                push (@outputList, @opList);
            }

            # Check ->gridRoomTagHash
            %gridRoomTagHash = $regionmapObj->gridRoomTagHash;
            INNER: foreach my $posn (keys %gridRoomTagHash) {

                my (
                    $roomNum, $roomObj, $eCount, $fCount,
                    @opList,
                );

                $roomNum = $gridRoomTagHash{$posn};
                $roomObj = $modelHash{$roomNum};
                # Check the room actually exists, and so on
                ($eCount, $fCount, @opList) = $self->testModelRoom(
                    $session,
                    $fixFlag,
                    $regionmapObj,
                    $posn,
                    $roomNum,
                    $roomObj,
                    'gridRoomTagHash',
                    \%modelHash,
                );

                $errorCount += $eCount;
                $fixCount += $fCount;
                push (@outputList, @opList);

                if (! $eCount && ! $fCount && ! $roomObj->roomTag) {

                    push (@outputList,
                        '   Regionmap \'' . $regionmapObj->name . '\' references the room #'
                        . $roomNum . ' in ->gridRoomTagHash which doesn\'t have a room tag',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        $regionmapObj->ivDelete('gridRoomTagHash', $posn);
                        $fixCount++;
                    }
                }
            }

            # Check ->gridRoomGuildHash
            %gridRoomGuildHash = $regionmapObj->gridRoomGuildHash;
            INNER: foreach my $posn (keys %gridRoomGuildHash) {

                my (
                    $roomNum, $roomObj, $eCount, $fCount,
                    @opList,
                );

                $roomNum = $gridRoomGuildHash{$posn};
                $roomObj = $modelHash{$roomNum};
                # Check the room actually exists, and so on
                ($eCount, $fCount, @opList) = $self->testModelRoom(
                    $session,
                    $fixFlag,
                    $regionmapObj,
                    $posn,
                    $roomNum,
                    $roomObj,
                    'gridRoomGuildHash',
                    \%modelHash,
                );

                $errorCount += $eCount;
                $fixCount += $fCount;
                push (@outputList, @opList);

                if (! $eCount && ! $fCount && ! $roomObj->roomGuild) {

                    push (@outputList,
                        '   Regionmap \'' . $regionmapObj->name . '\' references a room #'
                        . $roomNum . ' in ->gridRoomGuildHash which doesn\'t have a room guild',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        $regionmapObj->ivDelete('gridRoomGuildHash', $posn);
                        $fixCount++;
                    }
                }
            }

            # Check ->gridExitHash
            %gridExitHash = $regionmapObj->gridExitHash;
            INNER: foreach my $exitNum (keys %gridExitHash) {

                my (
                    $exitObj, $roomObj, $eCount, $fCount,
                    @opList,
                );

                $exitObj = $exitModelHash{$exitNum};
                # Check the exit actually exists, and so on
                ($eCount, $fCount, @opList) = $self->testModelExit(
                    $session,
                    $fixFlag,
                    $regionmapObj,
                    $exitNum,
                    $exitObj,
                    'gridExitHash',
                    \%modelHash,
                    \%exitModelHash,
                );

                $errorCount += $eCount;
                $fixCount += $fCount;
                push (@outputList, @opList);
            }

            # Check ->gridExitTagHash
            %gridExitTagHash = $regionmapObj->gridExitTagHash;
            INNER: foreach my $exitNum (keys %gridExitTagHash) {

                my (
                    $exitObj, $roomObj, $eCount, $fCount,
                    @opList,
                );

                $exitObj = $exitModelHash{$exitNum};
                # Check the exit actually exists, and so on
                ($eCount, $fCount, @opList) = $self->testModelExit(
                    $session,
                    $fixFlag,
                    $regionmapObj,
                    $exitNum,
                    $exitObj,
                    'gridExitTagHash',
                    \%modelHash,
                    \%exitModelHash,
                );

                $errorCount += $eCount;
                $fixCount += $fCount;
                push (@outputList, @opList);

                if (! $eCount && ! $fCount && ! $exitObj->exitTag) {

                    push (@outputList,
                        '   Regionmap \'' . $regionmapObj->name . '\' references an exit #'
                        . $exitNum . ' in ->gridExitTagHash which doesn\'t have an exit tag',
                    );

                    $errorCount++;
                    if ($fixFlag) {

                        $regionmapObj->ivDelete('gridExitTagHash', $exitNum);
                        $fixCount++;
                    }
                }
            }

            # Check ->regionExitHash
            %regionExitHash = $regionmapObj->regionExitHash;
            INNER: foreach my $exitNum (keys %regionExitHash) {

                my (
                    $exitObj, $roomObj, $eCount, $fCount,
                    @opList,
                );

                $exitObj = $exitModelHash{$exitNum};
                # Check the exit actually exists, and so on
                ($eCount, $fCount, @opList) = $self->testModelExit(
                    $session,
                    $fixFlag,
                    $regionmapObj,
                    $exitNum,
                    $exitObj,
                    'regionExitHash',
                    \%modelHash,
                    \%exitModelHash,
                );

                $errorCount += $eCount;
                $fixCount += $fCount;
                push (@outputList, @opList);

                if (! $eCount && ! $fCount) {

                    if (! $exitObj->regionFlag) {

                        push (@outputList,
                            '   Regionmap \'' . $regionmapObj->name . '\' references an exit #'
                            . $exitNum . ' in ->regionExitHash which isn\'t a region exit',
                        );

                        $errorCount++;
                        if ($fixFlag) {

                            $regionmapObj->ivDelete('regionExitHash', $exitNum);
                            $fixCount++;
                        }

                    } elsif (! $self->ivExists('regionModelHash', $regionExitHash{$exitNum})) {

                        push (@outputList,
                            '   Regionmap \'' . $regionmapObj->name . '\' references an exit #'
                            . $exitNum . ' in ->regionExitHash which leads to a model object #'
                            . $regionExitHash{$exitNum} . ' which isn\'t a region',
                        );

                        $errorCount++;
                        if ($fixFlag) {

                            $regionmapObj->ivDelete('regionExitHash', $exitNum);
                            $fixCount++;
                        }
                    }
                }
            }

            # Check ->regionPathHash
            %regionPathHash = $regionmapObj->regionPathHash;
            INNER: foreach my $posn (keys %regionPathHash) {

                my @posnList = split('_', $posn);
                if (
                    scalar @posnList != 2
                    || ! exists $exitModelHash{$posnList[0]}
                    || ! exists $exitModelHash{$posnList[1]}
                ) {
                    push (@outputList,
                        '   Regionmap \'' . $regionmapObj->name . '\' references a region path at'
                        . ' an invalid position \'' . $posn . '\' (not auto-fixable)',
                    );
                }
            }
        }

        # Operation complete. Return value(s)
        if ($diagnoseFlag) {
            return ($errorCount, $fixCount, @outputList);
        } elsif ($errorCount) {
            return undef;
        } else {
            return 1;
        }
    }

    sub testModelRoom {

        # Called by $self->testModel to check one of the hashes in a regionmap object
        #   (GA::Obj::Regionmap)
        # Checks that each room in the hash actually exists, and so on
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $fixFlag        - If TRUE, fixes any errors that can be fixed. If FALSE, does not
        #                       attempt to fix any errors
        #   $regionmapObj   - The regionmap object to check
        #   $posn           - A key in one of the regionmap's hashes
        #   $roomNum        - $posn's corresponding value
        #   $roomObj        - $roomNum's corresponding room object
        #   $iv             - The hash being checked, e.g. 'gridRoomHash'
        #   $modelHashRef   - Reference to a hash containing the contents of ->modelHash
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list in the form
        #       (error_count, fix_count, message, message, message...)
        #   ...where 'message' are any number (including zero) of error messages

        my (
            $self, $session, $fixFlag, $regionmapObj, $posn, $roomNum, $roomObj, $iv, $modelHashRef,
            $check,
        ) = @_;

        # Local variables
        my (
            $errorCount, $fixCount,
            @emptyList, @outputList, @posnList,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $fixFlag || ! defined $regionmapObj || ! defined $posn
            || ! defined $roomNum || ! defined $roomObj || ! defined $iv || ! defined $modelHashRef
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->testModelRoom', @_);
            return @emptyList;
        }

        $errorCount = 0;
        $fixCount = 0;

        if (! exists $$modelHashRef{$roomNum}) {

            push (@outputList,
                '   Regionmap \'' . $regionmapObj->name . '\' references a room #'
                . $roomNum . ' in ->' . $iv . ' which is not in ->modelHash',
            );

            $errorCount++;
            if ($fixFlag) {

                $regionmapObj->ivDelete($iv, $posn);
                $fixCount++;
            }
        }

        if (! $errorCount) {

            if ($roomObj->category ne 'room') {

                push (@outputList,
                    '   Regionmap \'' . $regionmapObj->name . '\' references a room #'
                    . $roomNum . ' in ->' . $iv . ' which is not actually a room object',
                );

                $errorCount++;
                if ($fixFlag) {

                    $regionmapObj->ivDelete($iv, $posn);
                    $fixCount++;
                }
            }
        }

        if (! $errorCount) {

            if ($roomObj->parent ne $regionmapObj->number) {

                push (@outputList,
                    '   Regionmap \'' . $regionmapObj->name . '\' references a room #'
                    . $roomNum . ' in ->' . $iv . ' which is actually in a different region',
                );

                $errorCount++;
                if ($fixFlag) {

                    $regionmapObj->ivDelete($iv, $posn);
                    $fixCount++;
                }
            }
        }

        if (! $errorCount) {

            @posnList = split('_', $posn);
            if (
                scalar @posnList != 3
                || $posnList[0] != $roomObj->xPosBlocks
                || $posnList[1] != $roomObj->yPosBlocks
                || $posnList[2] != $roomObj->zPosBlocks
            ) {
                push (@outputList,
                    '   Regionmap \'' . $regionmapObj->name . '\' references a room #'
                    . $roomNum . ' in ->' . $iv . ' whose position \'' . $posn . '\' is incorrect'
                    . ' (not auto-fixable)',
                );

                $errorCount++;
            }
        }

        return ($errorCount, $fixCount, @outputList);
    }

    sub testModelExit {

        # Called by $self->testModel to check one of the hashes in a regionmap object
        #   (GA::Obj::Regionmap)
        # Checks that each exit in the hash actually exists, and so on
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $fixFlag        - If TRUE, fixes any errors that can be fixed. If FALSE, does not
        #                       attempt to fix any errors
        #   $regionmapObj   - The regionmap object to check
        #   $exitNum        - A key in one of the regionmap's hashes
        #   $exitObj        - $exitNum's corresponding room object ('undef' value allowed)
        #   $iv             - The hash being checked, e.g. 'gridRoomHash'
        #   $modelHashRef   - Reference to a hash containing the contents of ->modelHash
        #   $exitModelHashRef
        #                   - Reference to a hash containing the contents of ->exitModelHash
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list in the form
        #       (error_count, fix_count, message, message, message...)
        #   ...where 'message' are any number (including zero) of error messages

        my (
            $self, $session, $fixFlag, $regionmapObj, $exitNum, $exitObj, $iv, $modelHashRef,
            $exitModelHashRef, $check,
        ) = @_;

        # Local variables
        my (
            $errorCount, $fixCount, $roomObj,
            @emptyList, @outputList,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $fixFlag || ! defined $regionmapObj
            || ! defined $exitNum || ! defined $iv || ! defined $modelHashRef
            || ! defined $exitModelHashRef || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->testModelExit', @_);
            return @emptyList;
        }

        $errorCount = 0;
        $fixCount = 0;

        if (! exists $$exitModelHashRef{$exitNum}) {

            push (@outputList,
                '   Regionmap \'' . $regionmapObj->name . '\' references an exit #'
                . $exitNum . ' in ->' . $iv . ' which is not in ->exitModelHash',
            );

            $errorCount++;
            if ($fixFlag) {

                $regionmapObj->ivDelete($iv, $exitNum);
                $fixCount++;
            }
        }

        if (! $errorCount) {

            $roomObj = $$modelHashRef{$exitObj->parent};
            if (
                # (Must check $roomObj exists and has a parent region, because some earlier checks
                #   produce errors that might not be fixed)
                $roomObj
                && $roomObj->parent
                && $roomObj->parent != $regionmapObj->number
            ) {
                push (@outputList,
                    '   Regionmap \'' . $regionmapObj->name . '\' references an exit #'
                    . $exitNum . ' in ->' . $iv . ' which is actually in a different region',
                );

                $errorCount++;
                if ($fixFlag) {

                    $regionmapObj->ivDelete($iv, $exitNum);
                    $fixCount++;
                }
            }
        }

        return ($errorCount, $fixCount, @outputList);
    }

    sub mergeModel {

        # Called by GA::Cmd::MergeModel->do (only)
        # Merges two world models into one. The calling function has imported a world model file
        #   (created by ;exportfiles -m <world_name>). This function merges data from that model
        #   into this one
        # Not everything is merged; for example, regions, rooms and exits are merged, but the
        #   value of ->currentRoomMode is not modified at all
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $mergeModelObj  - The imported world model (a GA::Obj::WorldModel object, just like this
        #                       one)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $mergeModelObj, $check) = @_;

        # Local variables
        my (
            @deleteList,
            %convertObjHash, %convertExitHash, %convertRegionHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $mergeModelObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mergeModel', @_);
        }

        # Compile a hash converting numbers of imported model objects (regions, rooms, sentients
        #   etc) etc to unused numbers in this model
        # ->modelObjCount specifies how many numbers have actually been used (i.e. if 1000 objects
        #   ever created, but 50 of them have since been deleted and not reallocated to a new
        #   object, ->modelObjCount is still 1000)
        for (my $count = 1; $count <= $mergeModelObj->modelObjCount; $count++) {

            my ($importObj, $newNum);

            $importObj = $mergeModelObj->ivShow('modelHash', $count);

            # If this object hasn't been deleted...
            if (defined $importObj) {

                # ...find a new number for it
                $newNum = $self->allocateModelNumber();
                $convertObjHash{$importObj->number} = $newNum;
            }
        }

        # Do the same for exits
        for (my $count = 1; $count <= $mergeModelObj->exitObjCount; $count++) {

            my ($importObj, $newNum);

            $importObj = $mergeModelObj->ivShow('exitModelHash', $count);

            # If this object hasn't been deleted...
            if (defined $importObj) {

                # ...find a new number for it
                $newNum = $self->allocateExitModelNumber();
                $convertExitHash{$importObj->number} = $newNum;
            }
        }

        # Region names. Any imported regions whose names clash with existing regions must be
        #   renamed
        foreach my $importObj ($mergeModelObj->ivValues('regionmapHash')) {

            my ($count, $newName, $exitFlag);

            if ($self->ivExists('regionmapHash', $importObj->name)) {

                # Set the new name for the imported region
                $count = 1;
                do {

                    $count++;
                    $newName = $importObj->name . '_' . $count;
                    if (! $self->ivExists('regionmapHash', $newName)) {

                        $exitFlag = TRUE;
                    }

                } until ($exitFlag);

                $convertRegionHash{$importObj->name} = $newName;
            }
        }

        # Start actually importing things

        # Import model objects
        foreach my $importObj ($mergeModelObj->ivValues('modelHash')) {

            my (
                $oldName,
                %childHash,
            );

            # Update the object's IVs

            # Group 1 IVs
            if ($importObj->category eq 'region') {

                $oldName = $importObj->name;

                if (exists $convertRegionHash{$importObj->name}) {

                    $importObj->ivPoke('name', $convertRegionHash{$importObj->name});
                    $importObj->{_objName} = $importObj->name;
                }
            }

            $importObj->ivPoke('number', $convertObjHash{$importObj->number});

            if (defined $importObj->parent) {

                $importObj->ivPoke('parent', $convertObjHash{$importObj->parent});
            }

            foreach my $key ($importObj->ivKeys('childHash')) {

                $childHash{$convertObjHash{$key}} = undef;
            }

            $importObj->ivPoke('childHash', %childHash);

            # ->privateHash must be emptied, because it might contain arbitrary model object numbers
            $importObj->ivEmpty('privateHash');

            # Group 2 IVs
            if (defined $importObj->container) {

                $importObj->ivPoke('container', $convertObjHash{$importObj->container});
            }

            # Group 3 IVs
            if (defined $importObj->targetRoomNum) {

                $importObj->ivPoke('targetRoomNum', $convertObjHash{$importObj->targetRoomNum});
            }

            # (No group 4 IVs to update)

            # Group 5 IVs
            if ($importObj->category eq 'region') {

                $importObj->ivPoke(
                    'regionmapObj',
                    $mergeModelObj->ivShow('regionmapHash', $oldName),
                );

            } elsif ($importObj->category eq 'room') {

                my (
                    %uncertainExitHash, %oneWayExitHash, %randomExitHash, %exitNumHash,
                    %hiddenObjHash,
                );

                foreach my $key ($importObj->ivKeys('uncertainExitHash')) {

                    my $value = $importObj->ivShow('uncertainExitHash', $key);

                    $uncertainExitHash{$convertExitHash{$key}} = $convertExitHash{$value};
                }

                $importObj->ivPoke('uncertainExitHash', %uncertainExitHash);

                foreach my $key ($importObj->ivKeys('oneWayExitHash')) {

                    $oneWayExitHash{$convertExitHash{$key}} = undef
                }

                $importObj->ivPoke('oneWayExitHash', %oneWayExitHash);

                foreach my $key ($importObj->ivKeys('randomExitHash')) {

                    $randomExitHash{$convertExitHash{$key}} = undef
                }

                $importObj->ivPoke('randomExitHash', %randomExitHash);

                foreach my $key ($importObj->ivKeys('exitNumHash')) {

                    my $value = $importObj->ivShow('exitNumHash', $key);

                    $exitNumHash{$key} = $convertExitHash{$value};
                }

                $importObj->ivPoke('exitNumHash', %exitNumHash);

                foreach my $key ($importObj->ivKeys('hiddenObjHash')) {

                    my $value = $importObj->ivShow('hiddenObjHash', $key);

                    $hiddenObjHash{$convertObjHash{$key}} = $value;
                }

                $importObj->ivPoke('hiddenObjHash', %hiddenObjHash);
            }

            # Add the imported object to this world model
            $self->ivAdd('modelHash', $importObj->number, $importObj);
            $self->ivAdd($importObj->category . 'ModelHash', $importObj->number, $importObj);
            $self->ivIncrement('modelActualCount');
            $self->ivPoke('mostRecentNum', $importObj->number);
        }

        # Import exits
        foreach my $importObj ($mergeModelObj->ivValues('exitModelHash')) {

            my @randomDestList;

            # Update the object's IVs

            $importObj->ivPoke('number', $convertExitHash{$importObj->number});
            $importObj->ivPoke('parent', $convertObjHash{$importObj->parent});

            # ->privateHash must be emptied, because it might contain arbitrary model object numbers
            $importObj->ivEmpty('privateHash');

            foreach my $num ($importObj->randomDestList) {

                push (@randomDestList, $convertObjHash{$num});
            }

            $importObj->ivPoke('randomDestList', @randomDestList);

            if (defined $importObj->destRoom) {

                $importObj->ivPoke('destRoom', $convertObjHash{$importObj->destRoom});
            }

            if (defined $importObj->twinExit) {

                $importObj->ivPoke('twinExit', $convertExitHash{$importObj->twinExit});
            }

            if (defined $importObj->shadowExit) {

                $importObj->ivPoke('shadowExit', $convertExitHash{$importObj->shadowExit});
            }

            # Add the imported object to this world model
            $self->ivAdd('exitModelHash', $importObj->number, $importObj);
            $self->ivIncrement('exitActualCount');
            $self->ivPoke('mostRecentExitNum', $importObj->number);
        }

        # Import regionmaps
        foreach my $importObj ($mergeModelObj->ivValues('regionmapHash')) {

            my (
                %gridRoomHash, %gridRoomTagHash, %gridRoomGuildHash, %gridExitHash,
                %gridExitTagHash, %regionExitHash, %regionPathHash, %safeRegionPathHash,
            );

            if (exists $convertRegionHash{$importObj->name}) {

                $importObj->ivPoke('name', $convertRegionHash{$importObj->name});
                $importObj->{_objName} = $importObj->name;
            }

            $importObj->ivPoke('number', $convertObjHash{$importObj->number});

            foreach my $key ($importObj->ivKeys('gridRoomHash')) {

                my $value = $importObj->ivShow('gridRoomHash', $key);

                $gridRoomHash{$key} = $convertObjHash{$value};
            }

            $importObj->ivPoke('gridRoomHash', %gridRoomHash);

            foreach my $key ($importObj->ivKeys('gridRoomTagHash')) {

                my $value = $importObj->ivShow('gridRoomTagHash', $key);

                $gridRoomTagHash{$key} = $convertObjHash{$value};
            }

            $importObj->ivPoke('gridRoomTagHash', %gridRoomTagHash);

            foreach my $key ($importObj->ivKeys('gridRoomGuildHash')) {

                my $value = $importObj->ivShow('gridRoomGuildHash', $key);

                $gridRoomGuildHash{$key} = $convertObjHash{$value};
            }

            $importObj->ivPoke('gridRoomGuildHash', %gridRoomGuildHash);

            foreach my $key ($importObj->ivKeys('gridExitHash')) {

                $gridExitHash{$convertExitHash{$key}} = undef;
            }

            $importObj->ivPoke('gridExitHash', %gridExitHash);

            foreach my $key ($importObj->ivKeys('gridExitTagHash')) {

                $gridExitTagHash{$convertExitHash{$key}} = undef;
            }

            $importObj->ivPoke('gridExitTagHash', %gridExitTagHash);

            foreach my $key ($importObj->ivKeys('regionExitHash')) {

                my $value = $importObj->ivShow('regionExitHash', $key);

                $regionExitHash{$convertExitHash{$key}} = $convertObjHash{$value};
            }

            $importObj->ivPoke('regionExitHash', %regionExitHash);

            foreach my $labelObj ($importObj->ivValues('gridLabelHash')) {

                if (exists $convertRegionHash{$importObj->name}) {

                    $labelObj->ivPoke('region', $convertRegionHash{$labelObj->region});
                }
            }

            foreach my $key ($importObj->ivKeys('regionPathHash')) {

                my (
                    $regionPathObj, $newKey,
                    @list, @roomList, @exitList,
                );

                $regionPathObj = $importObj->ivShow('regionPathHash', $key);

                # $key is in the form 'a_b', where are both are exit model numbers
                @list = split(/\_/, $key);
                $newKey = $convertExitHash{$list[0]} . '_' . $convertExitHash{$list[1]};

                # Update the region path object (GA::Obj::RegionPath) itself
                $regionPathObj->ivPoke('startExit', $convertExitHash{$regionPathObj->startExit});
                $regionPathObj->ivPoke('stopExit', $convertExitHash{$regionPathObj->stopExit});

                foreach my $item ($regionPathObj->roomList) {

                    push (@roomList, $convertObjHash{$item});
                }

                $regionPathObj->ivPoke('roomList', @roomList);

                foreach my $item ($regionPathObj->exitList) {

                    push (@exitList, $convertExitHash{$item});
                }

                $regionPathObj->ivPoke('exitList', @exitList);

                # Mark the region path object to be put back into the regionmap
                $regionPathHash{$newKey} = $regionPathObj;
                if ($importObj->ivExists('safeRegionPathHash', $key)) {

                    $safeRegionPathHash{$newKey} = $regionPathObj;
                }
            }

            $importObj->ivPoke('regionPathHash', %regionPathHash);
            $importObj->ivPoke('safeRegionPathHash', %safeRegionPathHash);

            # Add the imported object to this world model
            $self->ivAdd('regionmapHash', $importObj->name, $importObj);
        }

        # Update $self->knownCharHash and ->minionStringHash. Duplicate character names and
        #   duplicate minion strings are not allowed, so if there's a clash, remove the imported
        #   model object
        foreach my $name ($mergeModelObj->ivKeys('knownCharHash')) {

            my $importObj = $mergeModelObj->ivShow('knownCharHash', $name);

            if ($self->ivExists('knownCharHash', $name)) {

                push (@deleteList, $importObj);

            } else {

                $self->ivAdd('knownCharHash', $name, $importObj);
            }
        }

        foreach my $string ($mergeModelObj->ivKeys('minionStringHash')) {

            my $importObj = $mergeModelObj->ivShow('minionStringHash', $string);

            if ($self->ivExists('minionStringHash', $string)) {

                # $importObj can be a model or a non-model object. If the former, it must be
                #   deleted via a call to $self->deleteObj; if the latter, we can just ignore it
                if ($importObj->number) {

                    push (@deleteList, $importObj);
                }

            } else {

                $self->ivAdd('minionStringHash', $string, $importObj);
            }
        }

        foreach my $importObj (@deleteList) {

            $self->deleteObj(
                $session,
                FALSE,          # Don't update automapper windows now
                $importObj,
            );
        }

        # Merge any new light status values into our list of light status values (but don't create
        #   duplicates)
        foreach my $string ($mergeModelObj->lightStatusList) {

            if (! defined $self->ivFind('lightStatusList', $string)) {

                $self->ivPush('lightStatusList', $string);
            }
        }

        # Update this model's hash of room tags. If an imported room has a tag that's already in
        #   use, remove it
        foreach my $importObj ($mergeModelObj->ivValues('roomModelHash')) {

            my ($roomTag, $regionmapObj);

            $roomTag = $importObj->roomTag;

            if ($roomTag) {

                if ($self->ivExists('roomTagHash', $roomTag)) {

                    $importObj->ivUndef('roomTag');
                    # (Need to remove it from ->teleportHash, too)
                    $mergeModelObj->ivDelete('teleportHash', $roomTag);

                    # (And remove the entry in the regionmap)
                    $regionmapObj = $self->findRegionmap($importObj->parent);
                    $regionmapObj->removeRoomTag($importObj);

                } else {

                    $self->ivAdd('roomTagHash', $roomTag, $importObj->number);
                }
            }
        }

        # Update this model's hash of teleport rooms
        foreach my $key ($mergeModelObj->ivKeys('teleportHash')) {

            my $value = $mergeModelObj->ivShow('teleportHash', $key);

            if (exists $convertObjHash{$key}) {

                # The key is a room number
                $self->ivAdd('teleportHash', $convertObjHash{$key}, $value);

            } else {

                # The key is a room tag. Any duplicate room tags have already been removed from
                #   ->teleportHash
                $self->ivAdd('teleportHash', $key, $value);
            }
        }

        # Import any map label styles, but don't import any styles that have the same name as an
        #   existing style
        foreach my $importObj ($mergeModelObj->ivValues('mapLabelStyleHash')) {

            if (! $self->ivExists('mapLabelStyleHash', $importObj->name)) {

                $self->ivAdd('mapLabelStyleHash', $importObj->name, $importObj);
            }
        }

        # Import any custom room flags, but don't import any room flags that have the same name as
        #   an existing room flag
        foreach my $importObj ($mergeModelObj->ivValues('roomFlagHash')) {

            if ($importObj->customFlag && ! $self->ivExists('roomFlagHash', $importObj->name)) {

                # Don't import the room flag object (GA::Obj::RoomFlag); just create a new one with
                #   the same attributes
                $self->addRoomFlag(
                    $session,
                    $importObj->name,
                    $importObj->shortName,
                    $importObj->descrip,
                    $importObj->colour,
                );
            }
        }

        # Operation complete. Any automapper windows using this world model should be updated
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->redrawWidgets('menu_bar', 'toolbar', 'treeview');
            $mapWin->drawRegion();
        }

        return 1;
    }

    # Region path methods

    sub recalculateRegionPaths {

        # Called by GA::Win::Map->recalculatePathsCallback
        # Recalculates the region paths for a specified regionmap, replacing all previously
        #   calculated region paths
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $regionmapObj   - The GA::Obj::RegionPath whose region paths should be recalculated
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the number of region paths created (may be 0)

        my ($self, $session, $regionmapObj, $check) = @_;

        # Local variables
        my (
            $count,
            @exitNumList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $regionmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->recalculateRegionPaths', @_);
        }

        # Empty the existing hashes of region paths in this region
        $regionmapObj->resetPaths();

        # Recalculate paths from each super-region exit in turn
        foreach my $exitNum ($regionmapObj->ivKeys('regionExitHash')) {

            my ($roomObj, $exitObj);

            $exitObj = $self->ivShow('exitModelHash', $exitNum);

            if ($exitObj->superFlag) {

                $roomObj = $self->ivShow('modelHash', $exitObj->parent);

                # Recalculate the region paths between this super-region exit and all other
                #   super-region exits in the same region
                $self->connectRegionExits($session, $regionmapObj, $roomObj, $exitObj);
            }
        }

        # Work out how many region paths have been created
        $count = $regionmapObj->ivPairs('regionPathHash');

        # Operation complete
        return $count;
    }

    sub recalculateSafePaths {

        # Called by $self->toggleRoomFlags
        # When the user adds or removes a room flag from a room, and when that flag is one of the
        #   hazardous rooms flags, the parent region's safe region paths (which connect all the
        #   super-region exits in the region, using the shortest path that avoids rooms with
        #   hazardous flags) must be updated
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $regionmapObj   - The GA::Obj::Regionmap for which to recalculate safe region paths
        #   @roomList       - A list of GA::ModelObj::Room objects in this region, each of which
        #                       has had a hazardous room flag added or removed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $regionmapObj, @roomList) = @_;

        # Local variables
        my %roomHash;

        # Check for improper arguments
        if (! defined $session || ! defined $regionmapObj || ! @roomList) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->recalculateSafePaths', @_);
        }

        # Convert @roomList into a hash for easy lookup
        foreach my $roomObj (@roomList) {

            $roomHash{$roomObj->number} = $roomObj;
        }

        # Check every safe region path in the regionmap. Any of them which uses one of the rooms
        #   in %roomHash must be replaced
        OUTER: foreach my $exitString ($regionmapObj->ivKeys('safeRegionPathHash')) {

            my $pathObj = $regionmapObj->ivShow('regionPathHash', $exitString);

            INNER: foreach my $roomNum ($pathObj->roomList) {

                if (exists $roomHash{$roomNum}) {

                    # Replace the path
                    $self->replaceRegionPath($session, $pathObj, $regionmapObj, TRUE);

                    next OUTER;
                }
            }
        }

        # Operation complete
        return 1;
    }

    sub recalculateSpecificPaths {

        # Called by GA::Win::Map->recalculatePathsCallback
        # Recalculates the region paths to and from a specified super-region exit, replacing any
        #   existing region paths to/from that exit
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $regionmapObj   - The GA::Obj::Regionmap for which to recalculate region paths
        #   $exitObj        - A super-region exit somewhere in the region
        #
        # Return values
        #   'undef' on improper arguments, if the specified exit isn't a super-region exit or if
        #       it's not in the specified region
        #   Otherwise returns the number of new region paths to/from the specified exit (may be 0)

        my ($self, $session, $regionmapObj, $exitObj, $check) = @_;

        # Local variables
        my ($roomObj, $count);

        # Check for improper arguments
        if (! defined $session || ! defined $regionmapObj || ! defined $exitObj || defined $count) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->recalculateSpecificPaths',
                @_,
            );
        }

        # Get the exit's parent room
        $roomObj = $self->ivShow('modelHash', $exitObj->parent);

        # Check that $exitObj is a super-region exit in the right region
        if (! $exitObj->superFlag || $roomObj->parent != $regionmapObj->number) {

            return undef;
        }

        # Check every region path in the regionmap, and remove any that start or stop at the
        #   specified exit
        foreach my $exitString ($regionmapObj->ivKeys('regionPathHash')) {

            my $pathObj = $regionmapObj->ivShow('regionPathHash', $exitString);

            if ($pathObj->startExit == $exitObj->number || $pathObj->stopExit == $exitObj->number) {

                # Remove the path
                $regionmapObj->removePaths($exitString);
            }
        }

        # Now calculate new region paths to/from the specified exit
        $self->connectRegionExits(
            $session,
            $regionmapObj,
            $roomObj,
            $exitObj,
        );

        # Finally, count the number of region paths now leading to/from this exit
        $count = 0;

        foreach my $exitString ($regionmapObj->ivKeys('regionPathHash')) {

            my $pathObj = $regionmapObj->ivShow('regionPathHash', $exitString);

            if ($pathObj->startExit == $exitObj->number || $pathObj->stopExit == $exitObj->number) {

                $count++;
            }
        }

        return $count;
    }

    # Add non-model objects

    sub addRegionScheme {

        # Called by $self->new and GA::Cmd::AddRegionScheme->do
        # Adds a new region scheme object (GA::Obj::RegionScheme)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $name           - A name for the region scheme (any characters, max length 16)
        #
        # Return values
        #   'undef' on improper arguments or if the region scheme object can't be created
        #   Otherwise returns the region scheme object created

        my ($self, $session, $name, $check) = @_;

        # Local variables
        my $schemeObj;

        # Check for improper arguments
        if (! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRegionScheme', @_);
        }

        # Check specified values are valid
        if (length ($name) > 16) {

            return undef;
        }

        # Create the region scheme object
        $schemeObj = Games::Axmud::Obj::RegionScheme->new($session, $self, $name);
        if (! $schemeObj) {

            return undef;

        } else {

            $self->ivAdd('regionSchemeHash', $name, $schemeObj);

            return $schemeObj;
        }
    }

    sub deleteRegionScheme {

        # Called by anything
        # Deletes the specified region scheme
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $name           - The name of the region scheme to delete
        #
        # Return values
        #   'undef' on improper arguments, if the region scheme doesn't exist or if the default
        #       region scheme (which can't be deleted) is specified
        #   1 otherwise

        my ($self, $updateFlag, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteRegionScheme', @_);
        }

        if (! $self->ivExists('regionSchemeHash', $name) || $name eq 'default') {

            return undef;
        }

        $self->ivDelete('regionSchemeHash', $name);

        # Any regionmap using that region scheme should be redrawn (if the flag is specified)
        foreach my $regionmapObj ($self->ivValues('regionmapHash')) {

            if (defined $regionmapObj->regionScheme && $regionmapObj->regionScheme eq $name) {

                $regionmapObj->ivUndef('regionScheme');
                if ($updateFlag) {

                    # Redraw the region in any automapper window in which it's already drawn
                    $self->updateRegion($regionmapObj->name);
                }
            }
        }

        return 1;
    }

    sub renameRegionScheme {

        # Called by GA::Win::Map->doRegionSchemeCallback and GA::Cmd::RenameRegionScheme->do
        # Renames the specified region scheme
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $oldName        - The name of an existing region scheme
        #   $newName        - The new name for that region scheme
        #
        # Return values
        #   'undef' on improper arguments, or if $oldName or $newName are invalid, or if the default
        #       region scheme (which can't be renamed) is specified
        #   1 otherwise

        my ($self, $session, $oldName, $newName, $check) = @_;

        # Local variables
        my $schemeObj;

        # Check for improper arguments
        if (! defined $session || ! defined $oldName || ! defined $newName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->renameRegionScheme', @_);
        }

        # Check specified values are valid
        if (
            length ($newName) > 16
            || ! $self->ivExists('regionSchemeHash', $oldName)
            || $self->ivExists('regionSchemeHash', $newName)
            || $oldName eq 'default'
        ) {
            return undef;
        }

        # Get the region scheme object, and rename it
        $schemeObj = $self->ivShow('regionSchemeHash', $oldName);
        $schemeObj->ivPoke('name', $newName);

        # Update our IVs
        $self->ivDelete('regionSchemeHash', $oldName);
        $self->ivAdd('regionSchemeHash', $newName, $schemeObj);

        return 1;
    }

    sub attachRegionScheme {

        # Called by anything
        # Attaches a region scheme to a regionmap
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $schemeName     - The name of the region scheme to apply
        #   $regionName     - The name of the regionmap to which the scheme should be applied
        #
        # Return values
        #   'undef' on improper arguments, if the scheme/region names are invalid, if the region
        #       scheme object can't be applied or if it has already been applied
        #   1 otherwise

        my ($self, $updateFlag, $schemeName, $regionName, $check) = @_;

        # Local variables
        my ($schemeObj, $regionmapObj);

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $schemeName || ! defined $regionName
            || defined $check
        ) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->attachRegionScheme', @_);
        }

        # Retrieve the specified objects
        $schemeObj = $self->ivShow('regionSchemeHash', $schemeName);
        $regionmapObj = $self->ivShow('regionmapHash', $regionName);
        if (! $schemeObj || ! $regionmapObj) {

            return undef;
        }

        # If the scheme has already been applied to this regionmap, do nothing (i.e. don't redraw
        #   the regionmap)
        if (
            (
                ! defined $regionmapObj->regionScheme
                && $schemeObj eq $self->defaultSchemeObj
            ) || (
                defined $regionmapObj->regionScheme
                && $regionmapObj->regionScheme eq $schemeObj->name
            )
        ) {
            return undef;
        }

        # Apply the region scheme. Apply the default region scheme by setting the value to 'undef'
        if ($schemeObj eq $self->defaultSchemeObj) {
            $regionmapObj->ivUndef('regionScheme');
        } else {
            $regionmapObj->ivPoke('regionScheme', $schemeObj->name);
        }

        if ($updateFlag) {

            # Redraw the region in any automapper window in which it's already drawn
            $self->updateRegion($regionName);
        }

        return 1;
    }

    sub detachRegionScheme {

        # Called by anything
        # Detaches the region scheme from a regionmap (the 'default' region scheme then applies to
        #   it)
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $regionName     - The name of the regionmap to which the scheme should be applied
        #
        # Return values
        #   'undef' on improper arguments, if the region name is invalid or if the region has no
        #       region scheme attached to it
        #   1 otherwise

        my ($self, $updateFlag, $regionName, $check) = @_;

        # Local variables
        my $regionmapObj;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $regionName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRegionScheme', @_);
        }

        # Retrieve the specified regionmap
        $regionmapObj = $self->ivShow('regionmapHash', $regionName);
        if (! $regionmapObj || ! defined $regionmapObj->regionScheme) {

            return undef;

        } else {

            $regionmapObj->ivUndef('regionScheme');
            if ($updateFlag) {

                # Redraw the region in any automapper window in which it's already drawn
                $self->updateRegion($regionName);
            }
        }

        return 1;
    }

    sub addLabelStyle {

        # Called by $self->new and GA::Cmd::AddLabelStyle->do
        # Adds a new map label style object (GA::Obj::MapLabelStyle)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $name           - A name for the label style (any characters, max length 16)
        #
        # Optional arguments
        #   $text           - The text colour, an RGB colour tag (case-insensitive). If 'undef', no
        #                       text colour is set by this function
        #   $underlay       - The underlay colour, a normal RGB colour tag like '#ABCDEF', not an
        #                       Axmud underlay RGB tag like 'u#ABCDEF. If 'undef', no underlay
        #                       colour is set by this function
        #   $relSize        - The relative size. If specified, a value in the range 0.5-10
        #
        # Return values
        #   'undef' on improper arguments, if an invalid value for $text, $underlay and/or $relSize
        #       is specified, or if the map label style object can't be created
        #   Otherwise returns the map label style object created

        my ($self, $session, $name, $text, $underlay, $relSize, $check) = @_;

        # Local variables
        my ($type, $underlayFlag, $styleObj);

        # Check for improper arguments
        if (! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addLabelStyle', @_);
        }

        # Check specified values are valid
        if (length ($name) > 16) {

            return undef;
        }

        if (defined $text) {

            ($type, $underlayFlag) = $axmud::CLIENT->checkColourTags($text);
            if (! defined $type || $type ne 'rgb' || $underlayFlag) {

                return undef;
            }
        }

        if (defined $underlay) {

            ($type, $underlayFlag) = $axmud::CLIENT->checkColourTags($underlay);
            if (! defined $type || $type ne 'rgb' || $underlayFlag) {

                return undef;
            }
        }

        if (defined $relSize && ! $axmud::CLIENT->floatCheck($relSize, 0.5, 10)) {

            return undef;
        }

        # Create the map label style object
        $styleObj = Games::Axmud::Obj::MapLabelStyle->new(
            $session,
            $name,
            $text,
            $underlay,
            $relSize,
        );

        if (! $styleObj) {

            return undef;

        } else {

            $self->ivAdd('mapLabelStyleHash', $name, $styleObj);

            return $styleObj;
        }
    }

    sub deleteLabelStyle {

        # Called by anything
        # Deletes the specified map label style
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $name           - The name of the map label style to delete
        #
        # Return values
        #   'undef' on improper arguments or if the map label style doesn't exist
        #   1 otherwise

        my ($self, $updateFlag, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteLabelStyle', @_);
        }

        if (! $self->ivExists('mapLabelStyleHash', $name)) {

            return undef;
        }

        $self->ivDelete('mapLabelStyleHash', $name);

        # Any label using that style should be set to use custom IVs
        foreach my $regionmapObj ($self->ivValues('regionmapHash')) {

            foreach my $labelObj ($regionmapObj->ivValues('gridLabelHash')) {

                if (defined $labelObj->style && $labelObj->style eq $name) {

                    $labelObj->reset_style();
                }
            }
        }

        # Update automapper windows, if required
        if ($updateFlag) {

            $self->updateMapLabels();
        }

        return 1;
    }

    sub renameLabelStyle {

        # Called by GA::Win::Map->renameStyleCallback and GA::Cmd::RenameLabelStyle->do
        # Renames the specified label style (in case the user wants to swap the default name for
        #   a different one, without modifying a large number of labels)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $oldName        - The name of an existing map label style
        #   $newName        - The new name for that style
        #
        # Return values
        #   'undef' on improper arguments, or if $oldName or $newName are invalid
        #   1 otherwise

        my ($self, $session, $oldName, $newName, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (! defined $session || ! defined $oldName || ! defined $newName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->renameLabelStyle', @_);
        }

        # Check specified values are valid
        if (
            length ($newName) > 16
            || ! $self->ivExists('mapLabelStyleHash', $oldName)
            || $self->ivExists('mapLabelStyleHash', $newName)
        ) {
            return undef;
        }

        # Get the style object, and rename it
        $obj = $self->ivShow('mapLabelStyleHash', $oldName);
        $obj->ivPoke('name', $newName);

        # Update our IVs
        $self->ivDelete('mapLabelStyleHash', $oldName);
        $self->ivAdd('mapLabelStyleHash', $newName, $obj);
        if (defined $self->mapLabelStyle && $self->mapLabelStyle eq $oldName) {

            $self->ivPoke('mapLabelStyle', $newName);
        }

        # Any label that uses this style must be updated
        foreach my $regionmapObj ($self->ivValues('regionmapHash')) {

            foreach my $labelObj ($regionmapObj->ivValues('gridLabelHash')) {

                if (defined $labelObj->style && $labelObj->style eq $oldName) {

                    $labelObj->set_style($session, $newName);
                }
            }
        }

        return 1;
    }

    sub toggleLabelAlignment {

        # Called by GA::Win::Map->toggleLabelAlignment or any other function
        # Toggles alignment of map labels in horizontal or vertical directions (using the edge of
        #   a gridblock and the middle of it)
        # When turning on alignment, the position of all existing labels is changed to either the
        #   middle of the gridblock or the edge of it; new labels are placed in the same way
        # When turning off alignment, all existing labels remain in their current positions, but
        #   new labels are placed in the exact position on the map that the user clicks
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready). Ignored when turning off
        #                   alignment as no label positions change
        #   $type       - Which type of alignment to toggle - 'horizontal' or 'vertical'
        #
        # Return values
        #   'undef' on improper arguments, if a region with the specified name already exists, if
        #       an invalid parent region is specified or if either the region object or the
        #       regionmap object can't be created
        #   Otherwise returns the region object created

        my ($self, $session, $updateFlag, $type, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $session
            || ! defined $updateFlag
            || ! defined $type
            || ($type ne 'horizontal' && $type ne 'vertical')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleLabelAlignment', @_);
        }

        if ($type eq 'horizontal') {

            if ($self->mapLabelAlignXFlag) {

                # Turn off horizontal alignment
                $self->ivPoke('mapLabelAlignXFlag', FALSE);

            } else {

                # Turn on horizontal alignment
                $self->ivPoke('mapLabelAlignXFlag', TRUE);

                # Update the position of every label
                foreach my $regionmapObj ($self->ivValues('regionmapHash')) {

                    # Half a block width is usually fractional, e.g. width 51, half is 25.5
                    my $halfWidth = $regionmapObj->blockWidthPixels / 2;

                    foreach my $labelObj ($regionmapObj->ivValues('gridLabelHash')) {

                        # Round the label's position to the nearest half gridblock
#                        my $xPos = $halfWidth * sprintf(
#                            '%.0f',
#                            ($labelObj->xPosPixels / $halfWidth),
#                        );
                        my $xPos = $halfWidth * Math::Round::nearest(
                            1,
                            ($labelObj->xPosPixels / $halfWidth),
                        );

                        $labelObj->ivPoke('xPosPixels', int($xPos));
                    }
                }
            }

        } else {

            if ($self->mapLabelAlignYFlag) {

                # Turn off vertical alignment
                $self->ivPoke('mapLabelAlignYFlag', FALSE);

            } else {

                # Turn on vertical alignment
                $self->ivPoke('mapLabelAlignYFlag', TRUE);

                # Update the position of every label
                foreach my $regionmapObj ($self->ivValues('regionmapHash')) {

                    # Half a block height is usually fractional, e.g. height 51, half is 25.5
                    my $halfHeight = $regionmapObj->blockHeightPixels / 2;

                    foreach my $labelObj ($regionmapObj->ivValues('gridLabelHash')) {

                        # Round the label's position to the nearest half gridblock
#                        my $yPos = $halfHeight * sprintf(
#                            '%.0f',
#                            ($labelObj->yPosPixels / $halfHeight),
#                        );
                        my $yPos = $halfHeight * Math::Round::nearest(
                            1,
                            ($labelObj->yPosPixels / $halfHeight),
                        );

                        $labelObj->ivPoke('yPosPixels', int($yPos));
                    }
                }
            }
        }

        # Update automapper windows, if required
        if ($updateFlag) {

            $self->updateMapLabels();
        }

        return 1;
    }

    # Add model objects

    sub addRegion {

        # Called by GA::Win::Map->newRegionCallback or by any other function
        # Creates a new GA::ModelObj::Region object and adds it to the world model. Also creates a
        #   corresponding GA::Obj::Regionmap, adds it to the world model, and updates any
        #   Automapper windows using this model
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #
        # Optional arguments
        #   $name           - A name for the new region. If more than 32 characters, it is
        #                       shortened. If not specified, a name is generated for it (in the
        #                       form 'unnamed_x' or 'temporary_x')
        #   $parentNum      - The model number of the parent region object ('undef' if no parent
        #                       region)
        #   $tempFlag       - If set to TRUE, the new region is a temporary region (that should be
        #                       deleted, the next time the world model is loaded from file). If set
        #                       to FALSE (or 'undef'), the new region is not temporary
        #
        # Return values
        #   'undef' on improper arguments, if a region with the specified name already exists, if
        #       an invalid parent region is specified or if either the region object or the
        #       regionmap object can't be created
        #   Otherwise returns the region object created

        my ($self, $session, $updateFlag, $name, $parentNum, $tempFlag, $check) = @_;

        # Local variables
        my ($count, $partName, $regionObj, $regionmapObj);

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRegion', @_);
        }

        # If $name is not specified, generate a name
        if (! defined $name || $name eq '') {

            # Generate a name in the form 'unnamed_x', or 'temporary_x' for temporary regions
            if ($tempFlag) {
                $partName = 'temporary_';
            } else {
                $partName = 'unnamed_';
            }

            $count = 0;
            do {

                $count++;
                $name = $partName . $count;

            } until (
                ! $self->ivExists('regionmapHash', $name)
                || $count > 9999
            );

            if ($count > 9999) {

                # To avoid infinite loops, give up at this point
                return undef;
            }
        }

        # Check the region doesn't already exist
        foreach my $regionObj ($self->ivValues('regionModelHash')) {

            if ($regionObj->name eq $name) {

                # Region called $name already exists
                return undef;
            }
        }

        # If parent was specified, check it's a valid region object
        if (defined $parentNum && ! $self->ivExists('regionModelHash', $parentNum)) {

            return undef;
        }

        # Create the new region object
        $regionObj = Games::Axmud::ModelObj::Region->new($session, $name, TRUE, $parentNum);
        if ($regionObj) {

            # Also create a new regionmap object
            $regionmapObj = Games::Axmud::Obj::Regionmap->new($session, $name);
        }

        if (! $regionObj || ! $regionmapObj) {

            # Error creating one or both objects; we can't continue
            return undef;
        }

        # Add the region object to the model
        if (! $self->addToModel($regionObj)) {

            # Object could not be added
            return undef;
        }

        # Also add the corresponding regionmap
        $self->ivAdd('regionmapHash', $name, $regionmapObj);
        $regionmapObj->ivPoke('number', $regionObj->number);

        # If it's a temporary region, mark it as so
        if ($tempFlag) {

            $regionObj->ivPoke('tempRegionFlag', TRUE);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                $mapWin->resetTreeView();
            }
        }

        # Operation complete
        return $regionObj;
    }

    sub addRoom {

        # Called by GA::Obj::Map->createNewRoom or by any other function
        # Creates a new GA::ModelObj::Room object, adds it to the world model, and updates any
        #   Automapper windows using this model
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $region         - The name of the room's parent region
        #   $xPosBlocks, $yPosBlocks, $zPosBlocks
        #                   - The coordinates of the new room on the regionmap's grid
        #
        # Optional arguments
        #   $name           - The value stored as the object's ->name: the room's title, if that's
        #                       available; if not, a shortened version of the verbose description.
        #                       If 'undef', a name is assigned to the room
        #
        # Return values
        #   'undef' on improper arguments or if the room can't be added
        #   Otherwise returns the new GA::Model::Room object

        my (
            $self, $session, $updateFlag, $region, $xPosBlocks, $yPosBlocks, $zPosBlocks, $name,
            $check,
        ) = @_;

        # Local variables
        my ($regionmapObj, $roomObj);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $region
            || ! defined $xPosBlocks || ! defined $yPosBlocks || ! defined $zPosBlocks
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRoom', @_);
        }

        # Find the regionmap
        $regionmapObj = $self->ivShow('regionmapHash', $region);
        if (! $regionmapObj) {

            return undef;
        }

        # Check that the grid coordinates are valid and not already occupied by another room
        if ($regionmapObj->fetchRoom($xPosBlocks, $yPosBlocks, $zPosBlocks)) {

            return undef;
        }

        # If $name wasn't specified, use a temporary name
        if (! $name) {

            $name = '<unnamed room>';
        }

        # Create the new room object
        $roomObj = Games::Axmud::ModelObj::Room->new(
            $session,
            $name,
            'model',
            $regionmapObj->number,
        );

        if (! $roomObj) {

            return undef;
        }

        # Add the room object to the model
        if (! $self->addToModel($roomObj)) {

            # Object could not be added
            return undef;
        }

        # Set the room's position
        $roomObj->ivPoke('xPosBlocks', $xPosBlocks);
        $roomObj->ivPoke('yPosBlocks', $yPosBlocks);
        $roomObj->ivPoke('zPosBlocks', $zPosBlocks);

        # Add the room to its regionmap
        $regionmapObj->storeRoom($roomObj);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();

                # The regionmap's highest/lowest occupied levels need to be recalculated
                $self->ivAdd('checkLevelsHash', $regionmapObj->name, undef);
                # Sensitise/desensitise menu bar/toolbar items, depending on current conditions (as
                #   a response to this calculation)
                $mapWin->restrictWidgets();
            }
        }

        # Operation complete
        return $roomObj;
    }

    sub updateRoom {

        # Called by GA::Obj::Map->updateRoom, when the Automapper window is in 'update' mode, to
        #   adjust the properties of a room object in the world model to match those of
        #   the Locator task's non-model current room
        # The properties adjusted depend on various flags
        #
        # Expected arguments
        #   $session
        #       - The calling function's GA::Session
        #   $updateFlag
        #       - Flag set to TRUE if all Automapper windows using this world model should be
        #           updated now, FALSE if not (in which case, they can be updated later by the
        #           calling function, when it is ready)
        #   $modelRoomObj
        #       - A GA::ModelObj::Room in the world model
        #
        # Optional arguments
        #   $connectRoomObj, $connectExitObj, $standardDir
        #       - When the calling function was in turn called by GA::Obj::Map->createNewRoom, the
        #           room from which the character arrived and the exit obj/standard direction used
        #           (if known). Used when temporarily allocating primary directions to unallocated
        #           exits
        #
        # Return values
        #   'undef' on improper arguments, if the Locator task doesn't exist, if it doesn't know the
        #       current location or if we're not in 'update' mode
        #   1 otherwise

        my (
            $self, $session, $updateFlag, $modelRoomObj, $connectRoomObj, $connectExitObj,
            $standardDir, $check,
        ) = @_;

        # Local variables
        my (
            $taskObj, $taskRoomObj, $name, $terrain, $roomFlag,
            @titleList, @drawList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $modelRoomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRoom', @_);
        }

        # Import the Locator task and its current room
        $taskObj = $session->locatorTask;
        if ($taskObj) {

            $taskRoomObj = $taskObj->roomObj;
        }

        # If the Locator task doesn't exist, or if it doesn't know the current location, we can't
        #   use the location's properties
        if (! $taskRoomObj) {

            return undef;
        }

        # Update the room title(s) (if the Locator task knows any, and if we're allowed)
        if ($self->updateTitleFlag && $taskRoomObj->titleList) {

            # Each description in the Locator room's title list should be added to the model room's
            #   title list, but don't add duplicates
            @titleList = $modelRoomObj->titleList;
            if (! @titleList) {

                # The model room's title list is empty, so simply copy the Locator room's title list
                #   across (even if it, too, is empty)
                $modelRoomObj->ivPoke('titleList', $taskRoomObj->titleList);

            } else {

                OUTER: foreach my $taskTitle ($taskRoomObj->titleList) {

                    foreach my $modelTitle (@titleList) {

                        if ($taskTitle eq $modelTitle) {

                            # The model room already has this room title
                            next OUTER;
                        }
                    }

                    # The model room doesn't already have this room title
                    push (@titleList, $taskTitle);
                }

                # Store the combined list of brief descriptions
                $modelRoomObj->ivPoke('titleList', @titleList);
            }
        }

        # Update the (verbose) description(s), if the Locator task knows any, and if we're allowed
        if ($self->updateDescripFlag && $taskRoomObj->descripHash) {

            # A room's verbose description hash is in the form
            #   ->descripHash{light_status} = description_string
            #       e.g. $hash{'day'} = daytime_description_string
            #       e.g. $hash{'dark'} = darkness_description_string
            # Any key-value pairs in the Locator room's hash are copied to the map's hash,
            #   replacing any key-value pairs that are already there
            foreach my $key ($taskRoomObj->ivKeys('descripHash')) {

                my $value = $taskRoomObj->ivShow('descripHash', $key);

                $modelRoomObj->ivAdd('descripHash', $key, $value);
            }
        }

        # Update the room's ->name. If there's a room title, use it; if there's a verbose
        #   description, use it; otherwise use a generic name
        if ($taskRoomObj->titleList) {

            # Use the first 32 characters of the first room title found
            $name = substr($taskRoomObj->ivFirst('titleList'), 0, 32);

        } elsif ($taskRoomObj->ivExists('descripHash', $self->lightStatus)) {

            # Use the first 32 characters of the verbose description matching the current light
            #   status
            $name = substr($taskRoomObj->ivShow('descripHash', $self->lightStatus), 0, 32);

        } else {

            # Use a generic name
            $name = 'room_' . $modelRoomObj->number;
        }

        # Update the ->name IV
        $modelRoomObj->ivPoke('name', $name);

        # Analyse the verbose description to find recognised words, if we're allowed (and if the
        #   room's verbose description is known)
        if ($self->analyseDescripFlag && $modelRoomObj->descripHash) {

            $self->analyseVerboseDescrip($session, $modelRoomObj);
        }

        # Update exits (if we're allowed)
        # For wilderness rooms, we don't check any exits that have been added to the map (since we
        #   assume the world has sent a room statement with no exit list)
        if ($self->updateExitFlag && $modelRoomObj->wildMode eq 'normal') {

            # An exit's nominal direction is the one we'd expect to find in a room statement
            #   (e.g. 'Obvious exits are: east, south, north') and are stored in the exit object's
            #   ->dir
            # Room objects save their exits in two IVs: a hash in the form...
            #   ->exitNumHash{nominal_direction} = number_in_exit_model
            # ...and a list, with the nominal directions sorted in a standard order
            # Any nominal directions in the Locator room's hash which don't exist in the map's
            #   hash are added to the world model as new exits. Any that already exist are updated
            # Ignore transient exits (those which appear from time to time in various locations, for
            #   example the entrance to a moving wagon)
            OUTER: foreach my $exitObj ($taskRoomObj->ivValues('exitNumHash')) {

                my (
                    $slot, $convertDir,
                    @patternList,
                );

                # Deal with transient exits
                @patternList = $session->currentWorld->transientExitPatternList;
                if (@patternList) {

                    do {

                        my $pattern = shift @patternList;
                        my $destRoom = shift @patternList;

                        if ($exitObj->dir =~ m/$pattern/) {

                            # A transient exit; don't add it to the model room
                            next OUTER;
                        }

                    } until (! @patternList);
                }

                # Deal with relative directions
                $slot = $session->currentDict->convertRelativeDir($exitObj->dir);
                if (defined $slot) {

                    # $slot is in the range 0-7. Convert it into a standard primary direction like
                    #   'north', depending on which way the character is currently facing
                    $convertDir = $session->currentDict->rotateRelativeDir(
                        $slot,
                        $session->mapObj->facingDir,
                    );
                }

                $self->updateExit(
                    $session,
                    FALSE,       # Don't update Automapper windows now
                    $modelRoomObj,
                    $taskRoomObj,
                    $exitObj,
                    $convertDir,
                );
            }

            # Now, check the model room's list of exit objects, looking for those which don't yet
            #   have a map direction (->mapDir) set (which will be the case for any new exits we've
            #   just created in non-primary directions)
            # Allocate them one of the sixteen cardinal directions that are not already in use. If
            #   all sixteen cardinal directions are in use, the exit object's ->mapDir remains set
            #   to 'undef' (and isn't explicity drawn in the map)
            # (When this function is called by GA::Obj::Map->updateRoom which was, in turn, called
            #   by GA::Obj::Map->createNewRoom when moving from an existing departure room to a new
            #   arrival room, we pass information about the departure room to the function so that,
            #   if we moved using an allocated exit, any unallocated exits in the arrival room can
            #   be drawn in the opposite direction)
            foreach my $number ($modelRoomObj->ivValues('exitNumHash')) {

                my $exitObj = $self->ivShow('exitModelHash', $number);
                if ($exitObj && ! $exitObj->mapDir) {

                    $self->allocateCardinalDir(
                        $session,
                        $modelRoomObj,
                        $exitObj,
                        $connectRoomObj,
                        $connectExitObj,
                        $standardDir,
                    );
                }
            }
        }

        # Update the room source code path (if the Locator task knows it, and if we're allowed)
        if ($self->updateSourceFlag && $taskRoomObj->sourceCodePath) {

            $modelRoomObj->ivPoke('sourceCodePath', $taskRoomObj->sourceCodePath);
        }

        # Update the world's room vnum, etc (if the world has specified it, and if we're allowed)
        if ($self->updateVNumFlag && $taskRoomObj->ivExists('protocolRoomHash', 'vnum')) {

            foreach my $key ($taskRoomObj->ivKeys('protocolRoomHash')) {

                $modelRoomObj->ivAdd(
                    'protocolRoomHash',
                    $key,
                    $taskRoomObj->ivShow('protocolRoomHash', $key),
                );
            }

            foreach my $key ($taskRoomObj->ivKeys('protocolExitHash')) {

                $modelRoomObj->ivAdd(
                    'protocolExitHash',
                    $key,
                    $taskRoomObj->ivShow('protocolExitHash', $key),
                );
            }

            # Deal with MSDP terrain types
            $terrain = $taskRoomObj->ivShow('protocolRoomHash', 'terrain');
            if (defined $terrain) {

                if (! $self->ivExists('roomTerrainHash', $terrain)) {

                    # This terrain type not allocated to a room flag yet
                    $self->ivAdd('roomTerrainInitHash', $terrain, undef);

                } else {

                    # If the terrain type should be ignored, $roomFlag will be set to 'undef'
                    $roomFlag = $self->ivShow('roomTerrainHash', $terrain);
                    if ($roomFlag) {

                        # Add the corresponding room flag to the room, and remove any room flags
                        #   which belong to a differen terrain
                        $modelRoomObj->ivAdd('roomFlagHash', $roomFlag, undef);

                        foreach my $otherTerrain ($self->ivKeys('roomTerrainHash')) {

                            my $otherFlag = $self->ivShow('roomTerrainHash', $otherTerrain);

                            if ($otherFlag ne $roomFlag) {

                                $modelRoomObj->ivDelete('roomFlagHash', $otherFlag);
                            }
                        }
                    }
                }
            }
        }

        # Update room commands
        if ($self->updateRoomCmdFlag) {

            $modelRoomObj->ivPoke('roomCmdList', $taskRoomObj->roomCmdList);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Compile a list of rooms to be marked for drawing
            @drawList = ('room', $modelRoomObj);
            if ($connectRoomObj) {

                push (@drawList, 'room', $connectRoomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@drawList);
                $mapWin->doDraw();
            }
        }

        # Adjustment complete
        return 1;
    }

    sub addRoomChildren {

        # Called by GA::Win::Map->addContentsCallback
        # Adds one or more non-model objects to the world model as children of an existing model
        #   room
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $hiddenFlag - Flag set to TRUE if the child objects should be marked as hidden, set to
        #                   FALSE otherwise
        #   $roomObj    - The world model room object to which children should be added
        #
        # Optional arguments
        #   $obtainCmd  - For hidden objects, the command used to obtain it. Set to 'undef' when
        #                   $hiddenFlag is FALSE
        #   @objList    - A list of non-model objects. If empty, the world model isn't modified
        #
        # Return values
        #   'undef' on improper arguments or if @objList is empty
        #   1 otherwise

        my ($self, $updateFlag, $hiddenFlag, $roomObj, $obtainCmd, @objList) = @_;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $hiddenFlag || ! defined $roomObj) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRoomChildren', @_);
        }

        # Do nothing if the object list is empty
        if (! @objList) {

            return undef;
        }

        # Add each object in turn
        foreach my $obj (@objList) {

            # First set the parent ($self->addToModel will inform the parent it has acquired a
            #   child)
            $obj->ivPoke('parent', $roomObj->number);

            # Add the object to the model
            $self->addToModel($obj);

            if ($hiddenFlag) {

                # Add the object to the hidden objects list
                $roomObj->ivAdd('hiddenObjHash', $obj->number, $obtainCmd);
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub addExit {

        # Called by $self->updateExit and GA::Win::Map->addExitCallback
        # Adds a new exit object to the exit model
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $roomObj    - The world model room object to which an exit should be added
        #   $dir        - The exit's nominal direction (stored in GA::Obj::Exit->dir)
        #
        # Optional arguments
        #   $mapDir     - The primary direction in which the exit is drawn (stored in
        #                   GA::Obj::Exit->mapDir). Set when called by ->addExitCallback; set to
        #                   'undef' when called by ->updateExit (which decides for itself, which
        #                   primary direction to use) or when the exit is unallocatable (in which
        #                   case, GA::Obj::Exit->mapDir is 'undef')
        #
        # Return values
        #   'undef' on improper arguments or if the exit can't be added
        #   Otherwise returns the new GA::Obj::Exit object

        my ($self, $session, $updateFlag, $roomObj, $dir, $mapDir, $check) = @_;

        # Local variables
        my (
            $dictObj, $exitObj, $oldExitObj, $standardDir, $reallocateExitObj, $regionFlag,
            $regionObj,
            @dirList, @sortedList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $roomObj || ! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addExit', @_);
        }

        # Import the current dictionary
        $dictObj = $session->currentDict;

        # Create the new exit object
        $exitObj = Games::Axmud::Obj::Exit->new(
            $session,
            $dir,
            'model',
        );

        if (! $exitObj) {

            return undef;
        }

        # Add the exit object to the exit model
        if (! $self->addToExitModel($exitObj)) {

            # Object could not be added
            return undef;
        }

        # If this room already has an exit using the same direction, that exit must be deleted from
        #   the exit model
        if ($roomObj->ivExists('exitNumHash', $dir)) {

            $oldExitObj = $self->ivShow('exitModelHash', $roomObj->ivShow('exitNumHash', $dir));
            if ($oldExitObj) {

                $self->deleteExits(
                    $session,
                    TRUE,           # Update Automapper windows now
                    $oldExitObj,
                );
            }

        } else {

            # If this room already has an exit using the same map direction (the standard primary
            #   direction used to draw the exit on the map), and if the new exit's nominal direction
            #   $dir is a primary direction, then the new exit supplants the old one
            if ($mapDir) {

                # Use the specified map direction
                $exitObj->ivPoke('mapDir', $mapDir);
                $standardDir = $mapDir;

            } else {

                # Check whether the new exit's nominal direction is a (custom) primary direction by
                #   getting the corresponding standard primary direction
                $standardDir = $dictObj->convertStandardDir($dir);
            }

            if ($standardDir) {

                # Check whether any of the room's existing exits are using the same custom primary
                #   direction
                OUTER: foreach my $number ($roomObj->ivValues('exitNumHash')) {

                    my $otherExitObj = $self->ivShow('exitModelHash', $number);

                    if (
                        $otherExitObj
                        && $otherExitObj->mapDir
                        && $otherExitObj->mapDir eq $standardDir
                    ) {
                        # The room's existing exit is using the map direction we need
                        $reallocateExitObj = $otherExitObj;
                        last OUTER;
                    }
                }
            }
        }

        # Add the new exit object to the room
        $roomObj->ivAdd('exitNumHash', $dir, $exitObj->number);
        $exitObj->ivPoke('parent', $roomObj->number);

        @dirList = $roomObj->ivKeys('exitNumHash');
        @sortedList = $dictObj->sortExits(@dirList);
        $roomObj->ivPoke('sortedExitList', @sortedList);

        # If an existing exit has been supplanted, allocate it a different map direction
        if ($reallocateExitObj) {

            $regionFlag = $reallocateExitObj->regionFlag;
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);

            $reallocateExitObj->ivUndef('mapDir');
            $reallocateExitObj->ivPoke('drawMode', 'primary');

            $self->allocateCardinalDir($session, $roomObj, $reallocateExitObj);

            # Any region paths using the reallocated exit will have to be updated
            $self->ivAdd('updatePathHash', $reallocateExitObj->number, $regionObj->name);
            if ($regionFlag || $reallocateExitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $reallocateExitObj->number, $regionObj->name);
            }
        }

        # If a checked direction in this (primary or secondary) direction existed, remove its entry
        $roomObj->ivDelete('checkedDirHash', $exitObj->dir);

        # Set the exit type (e.g. 'primaryDir', 'primaryAbbrev', etc)
        $exitObj->ivPoke(
            'exitType',
            $session->currentDict->ivShow('combDirHash', $exitObj->dir),
        );

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the exit
                $mapWin->markObjs('exit', $exitObj);
                $mapWin->doDraw();
            }
        }

        return $exitObj;
    }

    sub updateExit {

        # Called by GA::Win::Map->updateRoom
        # The current Locator task has a non-model room with non-model exits. Given one of those
        #   exits, create a new exit object and add it to the world model via a call to
        #   $self->addExit
        # However, if the world model room object already has an exit in the same direction, don't
        #   replace it - just update its IVs
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $modelRoomObj   - The room object in the world model to which the new exit will belong
        #   $taskRoomObj    - The current Locator task's non-model room object
        #   $taskExitObj    - The non-model exit object belonging to $taskRoomObj which we need to
        #                       copy
        #
        # Optional arguments
        #   $convertDir     - If $taskExitObj's nominal direction is a relative direction, the
        #                       calling function has converted it into a standard primary direction
        #                       like 'north', depending on which direction the character is facing.
        #                       'undef' for non-relative directions
        #
        # Return values
        #   'undef' on improper arguments or if the function tries and fails to create a new exit
        #   Otherwise, returns the model number of the newly-added exit object

        my (
            $self, $session, $updateFlag, $modelRoomObj, $taskRoomObj, $taskExitObj, $convertDir,
            $check,
        ) = @_;

        # Local variables
        my ($useDir, $modelExitNum, $modelExitObj, $standardDir, $regionObj);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $modelRoomObj
            || ! defined $taskRoomObj || ! defined $taskExitObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateExit', @_);
        }

        # Any relative direction has been converted into a standard primary direction like 'north'
        # During this function, if $convertDir was specified, use the corresponding custom
        #   direction, otherwise use the exit's true nominal direction
        if (defined $convertDir) {
            $useDir = $session->currentDict->ivShow('primaryDirHash', $convertDir);
        } else {
            $useDir = $taskExitObj->dir;
        }

        # Does the world model room object already have an exit in this direction?
        if (! $modelRoomObj->ivExists('exitNumHash', $useDir)) {

            # It doesn't, so add a new one
            $modelExitObj = $self->addExit(
                $session,
                FALSE,              # Don't update Automapper windows now
                $modelRoomObj,
                $useDir,
            );

            if (! $modelExitObj) {

                # Nothing more we can do
                return undef;
            }

            # Decide how to draw the exit on the map. Is its direction a recognised custom primary
            #   direction?
            if (defined $convertDir) {
                $standardDir = $convertDir;
            } else {
                $standardDir = $session->currentDict->convertStandardDir($modelExitObj->dir);
            }

            if ($standardDir) {

                # The exit's nominal direction is a custom primary direction; store the
                #   corresponding standard primary direction in ->mapDir (this is the direction in
                #   which the exit is drawn on the map)
                # Otherwise, the calling function allocates a temporary value for ->mapDir, once it
                #   has finished calling this function (so it knows which directions are available)
                $modelExitObj->ivPoke('mapDir', $standardDir);
            }

        } else {

            # Update the existing exit
            $modelExitNum = $modelRoomObj->ivShow('exitNumHash', $useDir);
            $modelExitObj = $self->ivShow('exitModelHash', $modelExitNum);

            # Any region paths using the existing exit will have to be updated
            $regionObj = $self->ivShow('modelHash', $modelRoomObj->parent);
            $self->ivAdd('updatePathHash', $modelExitObj->number, $regionObj->name);
            if ($modelExitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $modelExitObj->number, $regionObj->name);
            }
        }

        # Update the model exit's ornament, but don't remove an ornament from $modelExitObj if
        #   there is no ornament on $taskExitObj
        if ($taskExitObj->exitOrnament ne 'none') {

            $modelExitObj->ivPoke('exitOrnament', $taskExitObj->exitOrnament);
        }

        # If the non-model exit has its ->exitState set, we can also use that to update the model
        #   exit's ornament (if this behaviour is allowed by the setting of
        #   $self->updateOrnamentFlag, but don't overrule the existing ornament, if set)
        if (
            ! $modelExitObj->exitOrnament ne 'none'
            && $self->updateOrnamentFlag
            && $taskExitObj->exitState
        ) {
            if ($taskExitObj->exitState eq 'impass') {

                $modelExitObj->ivPoke('exitOrnament', 'impass');

            } elsif (
                $taskExitObj->exitState eq 'locked'
                || $taskExitObj->exitState eq 'secret_locked'
            ) {
                $modelExitObj->ivPoke('exitOrnament', 'lock');

            } elsif (
                $taskExitObj->exitState eq 'open'
                || $taskExitObj->exitState eq 'closed'
                || $taskExitObj->exitState eq 'secret_open'
                || $taskExitObj->exitState eq 'secret_closed'
            ) {
                $modelExitObj->ivPoke('exitOrnament', 'open');
            }
        }

        # GA::Profile::World->exitStateTagHash can specify custom strings instead of exit states,
        #   which are added to the non-model object as assisted moves, so use them
        foreach my $key ($taskExitObj->assistedHash) {

            my $value = $taskExitObj->ivShow('assistedHash', $key);

            $modelExitObj->ivAdd('assistedHash', $key, $value);
        }

        # Also set the exit info, if it was collected
        if ($taskExitObj->exitInfo) {

            $modelExitObj->ivPoke('exitInfo', $taskExitObj->exitInfo);
        }

        # If the Locator task found a duplicate exit, it may have converted it using the pattern
        #   specified by GA::Profile::World->duplicateReplaceString (e.g. it might have converted a
        #   duplicate 'east' exit into a 'swim east' exit)
        # Any such duplicate exits are marked hidden. If the non-model exit object is marked hidden
        #  then so must the model exit object
        if ($taskExitObj->hiddenFlag) {

            $modelExitObj->ivPoke('hiddenFlag', TRUE);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the exit
                $mapWin->markObjs('exit', $modelExitObj);
                $mapWin->doDraw();
            }
        }

        # Update complete
        return 1;
    }

    sub addLabel {

        # Called by GA::Win::Map->canvasEventHandler, ->addLabelAtBlockCallback or by any other
        #   function
        # Creates a new GA::Obj::MapLabel object, adds it to the specified regionmap object and
        #   updates any Automapper windows using this model
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $regionmapObj   - The GA::Obj::Regionmap to which the label should be added
        #   $xPosPixels, $yPosPixels
        #                   - The map coordinates of the top-left pixel of the label
        #   $level          - The regionmap level on which the label is drawn
        #   $labelText      - The label text
        #
        # Optional arguments
        #   $style      - The name of the map label style to use (a GA::Obj::MapLabelStyle). If
        #                   defined, that style is applied to the label's text. If not defined,
        #                   the style depends on IVs in this object
        #
        # Return values
        #   'undef' on improper arguments, if the map coordinates are invalid or if the label can't
        #       be created
        #   Otherwise returns the new GA::Obj::MapLabel created

        my (
            $self, $session, $updateFlag, $regionmapObj, $xPosPixels, $yPosPixels, $level,
            $labelText, $style, $check,
        ) = @_;

        # Local variables
        my ($halfWidth, $halfHeight, $labelObj);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $regionmapObj
            || ! defined $xPosPixels || ! defined $yPosPixels || ! defined $level
            || ! defined $labelText || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addLabel', @_);
        }

        # Check that the map coordinates are valid
        if (
            $xPosPixels < 0
            || $yPosPixels < 0
            || $xPosPixels > $regionmapObj->mapWidthPixels
            || $yPosPixels > $regionmapObj->mapHeightPixels
        ) {
            return undef;
        }

        # If label alignment is turned on, adjust the label's horizontal and or vertical position
        if ($self->mapLabelAlignXFlag) {

            # Half a block width is usually fractional, e.g. width 51, half is 25.5
            $halfWidth = $regionmapObj->blockWidthPixels / 2;
            # Round the label's position to the nearest half gridblock
#            $xPosPixels = $halfWidth * sprintf('%.0f', ($xPosPixels / $halfWidth));
            $xPosPixels = $halfWidth * Math::Round::nearest(1, ($xPosPixels / $halfWidth));
        }

        if ($self->mapLabelAlignYFlag) {

            # Half a block height is usually fractional, e.g. height 51, half is 25.5
            $halfHeight = $regionmapObj->blockHeightPixels / 2;
            # Round the label's position to the nearest half gridblock
#            $yPosPixels = $halfHeight * sprintf('%.0f', ($yPosPixels / $halfHeight));
            $yPosPixels = $halfHeight * Math::Round::nearest(1, ($yPosPixels / $halfHeight));
        }

        # Create the new map label object
        $labelObj = Games::Axmud::Obj::MapLabel->new(
            $session,
            $labelText,
            $regionmapObj->name,
            $xPosPixels,
            $yPosPixels,
            $level,
            $style,
        );

        if (! $labelObj) {

            return undef;
        }

        # Add the label to the regionmap
        $regionmapObj->storeLabel($labelObj);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the label
                $mapWin->markObjs('label', $labelObj);
                $mapWin->doDraw();

                # The regionmap's highest/lowest occupied levels need to be recalculated
                $self->ivAdd('checkLevelsHash', $regionmapObj->name, undef);
                # Sensitise/desensitise menu bar/toolbar items, depending on current conditions (as
                #   a response to this calculation)
                $mapWin->restrictWidgets();
            }
        }

        # Operation complete
        return $labelObj;
    }

    sub addChar {

        # Called by GA::Cmd::AddModelObject->do or by any other function
        # Adds a character model object to the world model. Characters are the only kind of model
        #   object that must have a unique name (not already used by other character objects)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $name           - A name for the new character model object
        #
        # Optional arguments
        #   $parentNum      - If specified, the world model number of the parent object. Otherwise
        #                       set to 'undef'
        #
        # Return values
        #   'undef' on improper arguments or if the character can't be added
        #   Otherwise returns the new model object

        my ($self, $session, $updateFlag, $name, $parentNum, $check) = @_;

        # Local variables
        my ($obj, $parentObj, $profObj);

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addChar', @_);
        }

        # If the parent is specified, check it exists
        if ($parentNum) {

            if (! $self->ivExists('modelHash', $parentNum)) {

                return undef;

            } else {

                $parentObj = $self->ivShow('modelHash', $parentNum);
            }
        }

        # Check that there isn't already a known character with this name
        if ($self->ivExists('knownCharHash', $name)) {

            return undef;
        }

        # Create the new character model object
        $obj = Games::Axmud::ModelObj::Char->new($session, $name, TRUE, $parentNum);
        if (! $obj) {

            return undef;
        }

        # Add the new object to the model
        if (! $self->addToModel($obj)) {

            # Object could not be added
            return undef;
        }

        # Update the character model object IVs
        $self->ivAdd('knownCharHash', $name, $obj);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag && $parentObj && $parentObj->category eq 'room') {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the (parent) room
                $mapWin->markObjs('room', $parentObj);
                $mapWin->doDraw();
            }
        }

        # Operation complete
        return $obj;
    }

    sub addOther {

        # Called by GA::Cmd::AddModelObject->do or by any other function
        # Adds a model object which is not a region, room, character (or exit) to the world model
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $category       - The category of model object - one of 'weapon', 'armour', 'garment',
        #                       'char', 'minion', 'sentient', 'creature', 'portable', 'decoration'
        #                       or 'custom'
        #   $name           - A name for the new model object
        #
        # Optional arguments
        #   $parentNum      - If specified, the world model number of the parent object. Otherwise
        #                       set to 'undef'
        #
        # Return values
        #   'undef' on improper arguments or model object can't be added
        #   Otherwise returns the new model object

        my ($self, $session, $updateFlag, $category, $name, $parentNum, $check) = @_;

        # Local variables
        my ($obj, $parentObj, $package);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $category || ! defined $name
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addOther', @_);
        }

        # Check that the $category is one that can be handled by this function
        if (
            $category ne 'weapon' && $category ne 'armour' && $category ne 'garment'
            && $category ne 'minion' && $category ne 'sentient' && $category ne 'creature'
            && $category ne 'portable' && $category ne 'decoration' && $category ne 'custom'
        ) {
            return undef;
        }

        # If the parent is specified, check it exists
        if ($parentNum) {

            if (! $self->ivExists('modelHash', $parentNum)) {

                return undef;

            } else {

                $parentObj = $self->ivShow('modelHash', $parentNum);
            }
        }

        # Create the new model object
        $package = 'Games::Axmud::ModelObj::' . ucfirst($category);
        $obj = $package->new($session, $name, TRUE, $parentNum);
        if (! $obj) {

            return undef;
        }

        # Add the new object to the model
        if (! $self->addToModel($obj)) {

            # Object could not be added
            return undef;
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag && $parentObj && $parentObj->category eq 'room') {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the (parent) room
                $mapWin->markObjs('room', $parentObj);
                $mapWin->doDraw();
            }
        }

        # Operation complete
        return $obj;
    }

    sub importOther {

        # Called by GA::Cmd::AddMinionString->do or by any other function
        # Imports an existing non-model object which is not a region, room, character (or exit) to
        #   into world model
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $obj            - The non-model object to import
        #
        # Optional arguments
        #   $parentNum      - If specified, the world model number of the parent object. Otherwise
        #                       set to 'undef'
        #
        # Return values
        #   'undef' on improper arguments or if the model object can't be imported
        #   Otherwise returns the new model object

        my ($self, $session, $updateFlag, $obj, $parentNum, $check) = @_;

        # Local variables
        my $parentObj;

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->importOther', @_);
        }

        # Check that the $category is one that can be handled by this function
        if (
            $obj->category ne 'weapon' && $obj->category ne 'armour' && $obj->category ne 'garment'
            && $obj->category ne 'minion' && $obj->category ne 'sentient'
            && $obj->category ne 'creature' && $obj->category ne 'portable'
            && $obj->category ne 'decoration' && $obj->category ne 'custom'
        ) {
            return undef;
        }

        # If the parent is specified, check it exists
        if ($parentNum) {

            if (! $self->ivExists('modelHash', $parentNum)) {

                return undef;

            } else {

                $parentObj = $self->ivShow('modelHash', $parentNum);
            }
        }

        # Add the existing object to the model
        if (! $self->addToModel($obj)) {

            # Object could not be added
            return undef;
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag && $parentObj && $parentObj->category eq 'room') {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the (parent) room
                $mapWin->markObjs('room', $parentObj);
                $mapWin->doDraw();
            }
        }

        # Operation complete
        return $obj;
    }

    # Add to model/delete from model support funcs

    sub addToModel {

        # Called by $self->addRegion, ->addRoom, ->addRoomChildren, ->addChar, ->addOther,
        #   ->importOther and ->convertCategory (should not be called from outside this
        #   GA::Obj::WorldModel object - call ->addRoom, ->addOther, etc, instead)
        # Adds a new model object or an existing non-model object - such as the Locator task's
        #   current room and its contents - to the world model
        #
        # Expected arguments
        #   $obj    - The object to add (any object which inherits from GA::Generic::ModelObj)
        #
        # Return values
        #   'undef' on improper arguments or if the object can't be added to the model
        #   Otherwise, returns the model number of the newly-added object

        my ($self, $obj, $check) = @_;

        # Local variables
        my ($number, $parentObj);

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addToModel', @_);
        }

        # Allocate the object a world model number
        $number = $self->allocateModelNumber();
        if (! defined $number) {

            return undef;
        }

        # Update the object's IVs
        $obj->ivPoke('number', $number);
        $obj->ivPoke('modelFlag', TRUE);

        # Add the object to the model
        $self->ivAdd('modelHash', $obj->number, $obj);
        # (e.g. add to $self->regionModelHash)
        $self->ivAdd($obj->category . 'ModelHash', $obj->number, $obj);

        # Update model IVs. NB $self->modelObjCount is incremented by the call to
        #   $self->allocateModelNumber
        $self->ivIncrement('modelActualCount');
        $self->ivPoke('mostRecentNum', $obj->number);

        # If there's a parent, inform it that it's acquired a child
        if ($obj->parent) {

            $parentObj = $self->ivShow('modelHash', $obj->parent);
            if ($parentObj) {

                $parentObj->ivAdd('childHash', $obj->number, undef);
            }
        }

        return $number;
    }

    sub allocateModelNumber {

        # Called by $self->addToModel to allocate a number to a new model object (should not be
        #   called from outside this GA::Obj::WorldModel object)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the model number allocated to the new model object

        my ($self, $check) = @_;

        # Local variables
        my (
            $match,
            @newList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->allocateModelNumber', @_);
        }

        # Allocate a number
        if ($self->modelDeletedList) {

            # Re-use the smallest previously-allocated number. Checking every value in
            #   ->modelDeletedList now is probably more efficient than sorting ->modelDeletedList
            #   every time a new value is added to it (especially for very big world models)
            foreach my $num ($self->modelDeletedList) {

                if (! defined $match) {

                    $match = $num;

                } elsif ($match > $num) {

                    push (@newList, $match);
                    $match = $num;

                } else {

                    push (@newList, $num);
                }
            }

            # Update the IV
            $self->ivPoke('modelDeletedList', @newList);

            return $match;

        } else {

            # The count of model object numbers ever allocated increases by 1, but only when
            #   we're not re-using a number of a deleted model object
            return $self->ivIncrement('modelObjCount');
        }
    }

    sub addToExitModel {

        # Called by $self->addExit (should not be called from outside this GA::Obj::WorldModel
        #   object)
        # Adds a new exit object to the exit model
        #
        # Expected arguments
        #   $obj    - The GA::Obj::Exit to add
        #
        # Return values
        #   'undef' on improper arguments or if the exit object can't be added to the exit model
        #   Otherwise, returns the exit model number of the newly-added object

        my ($self, $exitObj, $check) = @_;

        # Local variables
        my ($number, $parentObj);

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addToExitModel', @_);
        }

        # Allocate the object a world model number
        $number = $self->allocateExitModelNumber();
        if (! defined $number) {

            return undef;
        }

        # Update the object's IVs
        $exitObj->ivPoke('number', $number);
        $exitObj->ivPoke('modelFlag', TRUE);

        # Add the object to the exit model
        $self->ivAdd('exitModelHash', $exitObj->number, $exitObj);

        # Update exit model IVs. NB $self->exitObjCount is incremented by the call to
        #   $self->allocateExitModelNumber
        $self->ivIncrement('exitActualCount');
        $self->ivPoke('mostRecentExitNum', $exitObj->number);

        return $number;
    }

    sub allocateExitModelNumber {

        # Called by $self->addToExitModel (should not be called from outside this
        #   GA::Obj::WorldModel object)
        # Allocates a number to a new exit model object
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the exit model number allocated to the new exit model object

        my ($self, $check) = @_;

        # Local variables
        my (
            $match,
            @newList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->allocateExitModelNumber',
                @_,
            );
        }

        # Allocate a number
        if ($self->exitDeletedList) {

            # Re-use the smallest previously-allocated number. Checking every value in
            #   ->exitDeletedList now is probably more efficient than sorting ->exitDeletedList
            #   every time a new value is added to it (especially for very big world models)
            foreach my $num ($self->exitDeletedList) {

                if (! defined $match) {

                    $match = $num;

                } elsif ($match > $num) {

                    push (@newList, $match);
                    $match = $num;

                } else {

                    push (@newList, $num);
                }
            }

            # Update the IV
            $self->ivPoke('exitDeletedList', @newList);

            return $match;

        } else {

            # The count of exit model object numbers ever allocated increases by 1, but only when
            #   we're not re-using a number of a deleted exit model object
            return $self->ivIncrement('exitObjCount');
        }
    }

    sub collectMapWins {

        # Checks every session, and compiles a list of GA::Win::Map objects which are using this
        #   world model
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the list of matching GA::Win::Map objects (may be an empty list)

        my ($self, $check) = @_;

        # Local variables
        my (@emptyList, @returnArray);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->collectMapWins', @_);
            return @emptyList;
        }

        foreach my $session ($axmud::CLIENT->listSessions()) {

            if (
                $session->currentWorld->name eq $self->_parentWorld
                && $session->mapWin
            ) {
                push (@returnArray, $session->mapWin);
            }
        }

        return @returnArray;
    }

    # Delete model objects

    sub deleteObj {

        # Deletes an object (and its child objects, including exits if the object is a room) from
        #   the world model
        # For regions, called by $self->deleteRegions. For rooms, called by $self->deleteRooms. For
        #   other kinds of world model object, can be called by anything (including by this function
        #   recursively)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $obj            - The model object to delete
        #
        # Optional arguments
        #   $recursionFlag  - Set to TRUE if this function has been called by itself (recursively)
        #                       (set to 'undef' otherwise)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $updateFlag, $obj, $recursionFlag, $check) = @_;

        # Local variables
        my (
            $parentObj, $count,
            @childList, @exitNumList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteObj', @_);
        }

        # For room objects, delete its exits
        if ($obj->category eq 'room') {

            # If there are any uncertain exits which lead to this soon-to-be-deleted room, convert
            #   them to incomplete exits (and redraw them, if allowed)
            foreach my $uncertainExitNum ($obj->ivKeys('uncertainExitHash')) {

                my $uncertainExitObj = $self->ivShow('exitModelHash', $uncertainExitNum);

                if (
                    $uncertainExitObj
                    && $uncertainExitObj->destRoom
                    && $uncertainExitObj->destRoom == $obj->number
                ) {
                    # (The call to $self->abandonUncertainExit updates $self->updateBoundaryHash and
                    #   ->updatePathHash)
                    $self->abandonUncertainExit(
                        $updateFlag,
                        $uncertainExitObj,
                    );
                }
            }

            # Do the same for one-way exits which lead to this soon-to-be-deleted room
            foreach my $oneWayExitNum ($obj->ivKeys('oneWayExitHash')) {

                my $oneWayExitObj = $self->ivShow('exitModelHash', $oneWayExitNum);

                if (
                    $oneWayExitObj
                    && $oneWayExitObj->destRoom
                    && $oneWayExitObj->destRoom == $obj->number
                ) {
                    # (The call to $self->abandonOneWayExit updates $self->updateBoundaryHash and
                    #   ->updatePathHash)
                    $self->abandonOneWayExit(
                        $updateFlag,
                        $oneWayExitObj,
                    );
                }
            }

            # Do the same for involuntary/repulse exit patterns whose corresponding destination room
            #   is this room
            foreach my $value (
                $obj->ivValues('involuntaryExitPatternHash'),
                $obj->ivValues('repulseExitPatternHash'),
            ) {
                # The values in both hashes can be 'undef' if the destination room is unknown
                if (defined $value) {

                    # Otherwise, $value is probably a room model number or a direction
                    my $destRoomObj = $self->ivShow('modelHash', $value);
                    if ($destRoomObj) {

                        $self->updateInvoluntaryExit(
                            $destRoomObj,
                            $obj,
                        );
                    }
                }
            }

            # Do the same for random exits which lead to this soon-to-be-deleted room
            foreach my $randomExitNum ($obj->ivKeys('randomExitHash')) {

                my $randomExitObj = $self->ivShow('exitModelHash', $randomExitNum);

                if (
                    $randomExitObj
                    && $randomExitObj->destRoom
                    && $randomExitObj->destRoom == $obj->number
                ) {
                    # (No need to update $self->updateBoundaryHash and ->updatePathHash, since a
                    #   random exit is allowed to have an empty ->randomDestList)
                    $self->updateRandomExit(
                        $randomExitObj,
                        $obj,
                    );
                }
            }

            # These hashes would be consulted in the call to ->deleteExits, so we have to empty
            #   them now
            $obj->ivEmpty('uncertainExitHash');
            $obj->ivEmpty('oneWayExitHash');
            $obj->ivEmpty('randomExitHash');

            # Delete the room's exit objects
            @exitNumList = $obj->ivValues('exitNumHash');
            foreach my $exitNum (@exitNumList) {

                $self->deleteExits(
                    $session,
                    $updateFlag,
                    $self->ivShow('exitModelHash', $exitNum),
                );
            }

            # If the character previously moved through a 'temp_region' random exit into a temporary
            #   region, and either the original or destination room is being deleted, we can simply
            #   tell the automapper object to forget about returning to the original room
            foreach my $thisSession ($axmud::CLIENT->ivValues('sessionHash')) {

                if (
                    $thisSession->worldModelObj eq $self
                    && defined $thisSession->mapObj->tempRandomOriginRoom
                    && (
                        $thisSession->mapObj->tempRandomOriginRoom eq $obj
                        || $thisSession->mapObj->tempRandomDestRoom eq $obj
                    )
                ) {
                    $thisSession->mapObj->reset_tempRandom();
                }
            }

            # If the room has a room tag, update the hash of room tags
            if ($obj->roomTag) {

                $self->ivDelete('roomTagHash', $obj->roomTag);
            }

        # Player character objects have additional IVs that must be updated
        } elsif ($obj->category eq 'char') {

            if ($self->ivExists('knownCharHash', $obj->name)) {

                $self->ivDelete('knownCharHash', $obj->name);
            }
        }

        # If this object is at the top of the deletion tree, and it has a parent, we need to inform
        #   the parent that it has lost one of its children
        if (! $recursionFlag && $obj->parent) {

            $parentObj = $self->ivShow('modelHash', $obj->parent);
            if ($parentObj && $parentObj->ivExists('childHash', $obj->number)) {

                $parentObj->ivDelete('childHash', $obj->number);
            }
        }

        # Delete this object's children, if any
        $count = 0;
        if ($obj->childHash) {

            @childList = $obj->ivKeys('childHash');
            foreach my $childNum (@childList) {

                my $childObj = $self->ivShow('modelHash', $childNum);

                # Delete the child object (recursively)
                if ($self->deleteObj($session, $updateFlag, $childObj, TRUE)) {

                    $count++;
                }
            }
        }

        # Delete the object from the model
        $self->ivDelete('modelHash', $obj->number);
        $self->ivDelete($obj->category . 'ModelHash', $obj->number);
        # Mark the number of this object as having been deleted, so it can be reused
        $self->ivPush('modelBufferList', $obj->number);
        # Adjust the model object count
        $self->ivDecrement('modelActualCount');

        # Return the total number of objects deleted (add one for this object)
        return ($count + 1);
    }

    sub deleteRegions {

        # Called by GA::Win::Map->deleteRegionCallback and $self->deleteTempRegions
        # Deletes one of more GA::ModelObj::Region objects, together with any child objects
        #   (mostly the rooms it contains).
        # Also deletes the corresponding regionmap (GA::Obj::Regionmap) and parchment objects
        #   (GA::Obj::Parchment)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #
        # Optional arguments
        #   @regionList     - A list of GA::ModelObj::Region objects to delete. If the list is
        #                       empty, no regions are deleted
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $updateFlag, @regionList) = @_;

        # Local variables
        my @graffitiList;

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteRegions', @_);
        }

        # If @regionList is empty, do nothing
        if (! @regionList) {

            return undef;
        }

        # Before any deletion operation, all selected canvas objects must be un-selected
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->setSelectedObj();
        }

        # This functions causes calls to self->deleteRooms and ->deleteExits. Everything in the
        #   automapper window is already unselected, so those functions don't need to make further
        #   calls to GA::Win::Map->setSelectedObj
        $self->ivPoke('blockUnselectFlag', TRUE);

        foreach my $regionObj (@regionList) {

            my @childList;

            # Check the region's children; any of them which are themselves regions should not be
            #   deleted
            @childList = $regionObj->ivKeys('childHash');
            foreach my $childNum (@childList) {

                my $childObj = $self->ivShow('modelHash', $childNum);

                # Prevent deletion of the child region by resetting its parent
                if ($childObj->category eq 'region') {

                    $self->setParent(
                        FALSE,    # Don't update Automapper windows yet
                        $childNum,
                    );

                # Make sure the automapper's current room is reset, if it's to be deleted
                } elsif (
                    $childObj->category eq 'room'
                    && $session->mapObj->currentRoom
                    && $session->mapObj->currentRoom eq $childObj
                ) {
                    $session->mapObj->setCurrentRoom();
                    push (@graffitiList, $childObj);
                }
            }

            # Delete the region object and its child objects (if any)
            $self->deleteObj(
                $session,
                FALSE,       # Don't update Automapper windows yet
                $regionObj,
            );

            # Delete the corresponding regionmap
            $self->ivDelete('regionmapHash', $regionObj->name);

            # If the character was moved to a temporary region rather than being marked lost (in
            #   auto-rescue mode), and either the temporary or the previous region is being
            #   deleted, we can simply forget about merging/moving rooms from one region to another
            foreach my $thisSession ($axmud::CLIENT->ivValues('sessionHash')) {

                if (
                    $thisSession->worldModelObj eq $self
                    && defined $thisSession->mapObj->rescueLostRegionObj
                    && (
                        $thisSession->mapObj->rescueLostRegionObj eq $regionObj
                        || $thisSession->mapObj->rescueTempRegionObj eq $regionObj
                    )
                ) {
                    $thisSession->mapObj->reset_rescueRegion();
                }
            }
        }

        # Regardless of whether $updateFlag is set, or not, the automapper windows' list of
        #   recent regions must be updated, and the deleted rooms should no longer be graffitied
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->reset_recentRegion(@regionList);
            $mapWin->del_graffiti(@graffitiList);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                foreach my $regionObj (@regionList) {

                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $regionObj->number
                    ) {
                        # Show the empty map
                        $mapWin->setCurrentRegion();
                    }

                    $mapWin->del_parchment($regionObj->name);
                }

                # Update the window's treeview (containing the list of regions)
                $mapWin->resetTreeView();
            }
        }

        # (Allow future calls to $self->deleteRooms and ->deleteExits to check that everything in
        #   the automapper window is unselected)
        $self->ivPoke('blockUnselectFlag', FALSE);

        return 1;
    }

    sub deleteTempRegions {

        # Called by GA::Win::Map->deleteTempRegionsCallback, GA::Cmd::DeleteTemporaryRegion->do
        #   or by any other function
        # Deletes every temporary region in the world model (every GA::ModelObj::Region whose
        #   ->tempRegionFlag is set). Also deletes the corresponding GA::Obj::Regionmaps
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #
        # Return values
        #   'undef' on improper arguments or if there are no temporary regions to delete
        #   1 otherwise

        my ($self, $session, $updateFlag, $check) = @_;

        # Local variables
        my @regionList;

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteTempRegions', @_);
        }

        # Get a list of temporary regions
        foreach my $regionObj ($self->ivValues('regionModelHash')) {

            if ($regionObj->tempRegionFlag) {

                push (@regionList, $regionObj);
            }
        }

        if (! @regionList) {

            # No temporary regions to delete
            return undef;
        }

        # Delete each temporary region in turn
        $self->deleteRegions(
            $session,
            FALSE,      # Don't update Automapper windows yet
            @regionList,
        );

        # Regardless of whether $updateFlag is set, or not, the automapper windows' list of
        #   recent regions must be updated
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->reset_recentRegion(@regionList);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                foreach my $regionObj (@regionList) {

                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $regionObj->number
                    ) {
                        # Show no current region, which deletes all canvas objects
                        $mapWin->setCurrentRegion();
                    }

                    $mapWin->del_parchment($regionObj->name);
                }

                # After any deletion operation, all selected canvas objects must be un-selected
                $mapWin->setSelectedObj();

                # Update the window's treeview (containing the list of regions)
                $mapWin->resetTreeView();
            }
        }

        return 1;
    }

    sub deleteRooms {

        # Called by GA::Win::Map->enableRoomsColumn, GA::Cmd::DeleteRoom->do and
        #   $self->emptyRegion
        # Deletes one of more GA::ModelObj::Room objects, together with any child objects and exit
        #   objects belonging to the room
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #
        # Optional arguments
        #   @roomList      - A list of GA::ModelObj::Room objects to delete. If the list is empty,
        #                       no rooms are deleted
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $updateFlag, @roomList) = @_;

        # Local variables
        my (
            @mapWinList,
            %regionHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteRooms', @_);
        }

        # If @roomList is empty, do nothing
        if (! @roomList) {

            return undef;
        }

        # Before any deletion operation, all selected canvas objects must be un-selected (but don't
        #   need to to do that if there has been an earlier call to $self->deleteRegions)
        if (! $self->blockUnselectFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                $mapWin->setSelectedObj();
            }
        }

        foreach my $roomObj (@roomList) {

            my $regionmapObj;

            # If this room is the automapper's current room, any Automapper windows which are not
            #   in 'wait' mode should switch to 'wait' mode at the end of this function (do it even
            #   if $updateFlag is not set)
            if ($session->mapObj->currentRoom && $session->mapObj->currentRoom eq $roomObj) {

                $session->mapObj->setCurrentRoom();

                foreach my $mapWin ($self->collectMapWins()) {

                    if ($mapWin->mode ne 'wait') {

                        push (@mapWinList, $mapWin);
                    }
                }
            }

            # Update the regionmap's hashes of rooms, room tags and room guilds
            $regionmapObj = $self->findRegionmap($roomObj->parent);
            $regionmapObj->removeRoom($roomObj);
            # (We can save a bit of time in the code below by storing each room's regionmap
            #   temporarily)
            $regionHash{$roomObj} = $regionmapObj;

            # Delete the room object and its child objects and exit objects (if any)
            $self->deleteObj(
                $session,
#                TRUE,       # Update Automapper windows now - is applied to the room's exits
                $updateFlag,
                $roomObj,
            );

            # The regionmap's highest/lowest occupied levels need to be recalculated
            $self->ivAdd('checkLevelsHash', $regionmapObj->name, undef);

            # The regionmap's hashes of living/non-living objects must be updated
            $regionmapObj->removeLivingCount($roomObj->number),
            $regionmapObj->removeNonLivingCount($roomObj->number),
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Any deleted rooms should no longer be graffitied
                $mapWin->del_graffiti(@roomList);

                foreach my $roomObj (@roomList) {

                    my ($regionmapObj, $parchmentObj);

                    $regionmapObj = $regionHash{$roomObj};
                    $parchmentObj = $mapWin->ivShow('parchmentHash', $regionmapObj->name);

                    # Delete the room's canvas objects (if they exist; its exits will have been
                    #   deleted in the call to ->deleteObj just above)
                    $mapWin->deleteCanvasObj('room', $roomObj, $regionmapObj, $parchmentObj, TRUE);
                    if ($roomObj->roomTag) {

                        $mapWin->deleteCanvasObj(
                            'room_tag',
                            $roomObj,
                            $regionmapObj,
                            $parchmentObj,
                            TRUE,
                        );
                    }

                    if ($roomObj->roomGuild) {

                        $mapWin->deleteCanvasObj(
                            'room_guild',
                            $roomObj,
                            $regionmapObj,
                            $parchmentObj,
                            TRUE,
                        );
                    }

                    # Some other function may have placed the room on the automapper's list of
                    #   objects to draw; if so, remove it
                    if ($parchmentObj) {

                        $parchmentObj->ivDelete('markedRoomHash', $roomObj->number);
                        $parchmentObj->ivDelete('markedRoomTagHash', $roomObj->number);
                        $parchmentObj->ivDelete('markedRoomGuildHash', $roomObj->number);

                        $parchmentObj->ivDelete('queueRoomEchoHash', $roomObj->number);
                        $parchmentObj->ivDelete('queueRoomBoxHash', $roomObj->number);
                        $parchmentObj->ivDelete('queueRoomTextHash', $roomObj->number);
                        $parchmentObj->ivDelete('queueRoomExitHash', $roomObj->number);
                        $parchmentObj->ivDelete('queueRoomInfoHash', $roomObj->number);
                    }
                }
            }
        }

        foreach my $mapWin (@mapWinList) {

            # This Automapper window's current room was deleted, so we need to switch to 'wait' mode
            $mapWin->setMode('wait');
        }

        # Check every Locator task; if its current room is one of those just be deleted, it needs to
        #   be informed
        OUTER: foreach my $mapWin ($self->collectMapWins()) {

            my $taskObj = $mapWin->session->locatorTask;

            if ($taskObj && $taskObj->modelNumber) {

                INNER: foreach my $roomObj (@roomList) {

                    if ($taskObj->modelNumber eq $roomObj->number) {

                        $taskObj->resetModelRoom();
                        next OUTER;
                    }
                }
            }
        }

        return 1;
    }

    sub deleteExits {

        # Called by GA::Win::Map->deleteExitCallback, GA::Cmd::DeleteExit->do and $self->deleteObj
        # Deletes one or more GA::Obj::Exit objects
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #
        # Optional arguments
        #   @exitList       - A list of GA::Obj::Exit objects to delete. If the list is empty, no
        #                       exits are deleted
        #
        # Return values
        #   'undef' on improper arguments or if @exitList is empty
        #   1 otherwise

        my ($self, $session, $updateFlag, @exitList) = @_;

        # Local variables
        my (
            @redrawList, @mapWinList,
            %roomHash, %regionHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteExits', @_);
        }

        # If @exitList is empty, do nothing
        if (! @exitList) {

            return undef;
        }

        # Before any deletion operation, all selected canvas objects must be un-selected (but don't
        #   need to to do that if there has been an earlier call to $self->deleteRegions)
        if (! $self->blockUnselectFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                $mapWin->setSelectedObj();
            }
        }

        foreach my $exitObj (@exitList) {

            my (
                $roomObj, $regionObj, $twinExitObj, $twinRoomObj, $destRoomObj, $regionmapObj,
                $twinRegionObj, $twinRegionmapObj,
                @dirList, @sortedDirList,
            );

            # Get the exit's parent room and region
            $roomObj = $self->ivShow('modelHash', $exitObj->parent);
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);

            # Any region paths using the soon-to-be-deleted exit will have to be updated
            $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
            if ($exitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
                # $self->deleteBoundaryHash contains all the exits in ->updateBoundaryHash that
                #   have been deleted
                $self->ivAdd('deleteBoundaryHash', $exitObj->number, $regionObj->name);
            }

            if ($updateFlag) {

                # We need to keep track of the parent rooms, which must also be redrawn (in case
                #   the exit is a shadow exit, in which case the newly-unallocated exit won't be
                #   drawn unless we redraw the room)
                $roomHash{$roomObj->number} = $roomObj;

                # When $exitObj is an incomplete exit and the possible twin of an incoming uncertain
                #   exit, we need to redraw any rooms which have uncertain exits leading to
                #   $exitObj's parent room - otherwise, those uncertain exits won't get redrawn as
                #   one-way exits. The same applies to incoming one-way exits
                if (! $exitObj->destRoom && $exitObj->randomType eq 'none') {

                    # This is an incomplete exit. Redraw the parent rooms of incoming uncertain
                    #   exits...
                    foreach my $uncertainNum ($roomObj->ivKeys('uncertainExitHash')) {

                        my $uncertainExitObj = $self->ivShow('exitModelHash', $uncertainNum);

                        $roomHash{$uncertainExitObj->parent}
                            = $self->ivShow('modelHash', $uncertainExitObj->parent);
                    }

                    # ...and incoming one-way exits
                    foreach my $oneWayNum ($roomObj->ivKeys('oneWayExitHash')) {

                        my $oneWayExitObj = $self->ivShow('exitModelHash', $oneWayNum);

                        $roomHash{$oneWayExitObj->parent}
                            = $self->ivShow('modelHash', $oneWayExitObj->parent);
                    }
                }
            }

            # If this exit has a twin exit, inform the twin exit that it is being abandoned
            if ($exitObj->twinExit) {

                $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
                $twinRoomObj = $self->ivShow('modelHash', $twinExitObj->parent);
                if ($updateFlag) {

                    $roomHash{$twinExitObj->parent} = $twinRoomObj;
                }

                # (The call to ->abandonTwinExit sets $self->updateBoundaryHash, ->updatePathHash)
                $self->abandonTwinExit(
                    FALSE,          # Don't update Automapper window yet
                    $exitObj,
                    $twinExitObj,
                );

            } elsif ($exitObj->destRoom) {

                $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);

                # If this exit is an uncertain exit (has a destination room, but no twin exit and
                #   it's not a marked one way exit) then the destination room's hash of incoming
                #   uncertain exits needs to be updated
                if (! $exitObj->oneWayFlag) {

                    if ($destRoomObj->ivExists('uncertainExitHash', $exitObj->number)) {

                        # Remove this exit from that hash
                        $destRoomObj->ivDelete('uncertainExitHash', $exitObj->number);
                    }

                # If this exit is a one-way exit (has a destination room and it's a marked one way
                #   exit) then the destination room's hash of incoming one-way exits needs to be
                #   updated
                } else {

                    # If the hash contains this exit object as an incoming one-way exit...
                    if ($destRoomObj->ivExists('oneWayExitHash', $exitObj->number)) {

                        # ...remove this ExitObj from that hash
                        $destRoomObj->ivDelete('oneWayExitHash', $exitObj->number);
                    }
                }
            }

            # Mark the number of this object as having been deleted, so it can be reused
            $self->ivPush('exitBufferList', $exitObj->number);
            # Remove the exit from the model
            $self->ivDelete('exitModelHash', $exitObj->number);
            $self->ivDecrement('exitActualCount');

            if ($roomObj) {

                # If this exit is a shadow exit for one of the other exits in the room, the other
                #   exit must be reset
                foreach my $otherExitNum ($roomObj->ivValues('exitNumHash')) {

                    my $otherExitObj = $self->ivShow('exitModelHash', $otherExitNum);

                    if (
                        $otherExitObj      # (May have been deleted from the model by this function)
                        && $otherExitObj->shadowExit
                        && $otherExitObj->shadowExit eq $exitObj->number
                    ) {
                        # The other exit retains its map direction, ->mapDir, which matches the
                        #   ->mapDir of $exitObj
                        $otherExitObj->ivUndef('shadowExit');
                        # The other exit is once again marked as 'unallocated'. The map direction is
                        #   definitely available, so ->drawMode is set to 'temp_alloc', not
                        #   'temp_unalloc'
                        $otherExitObj->ivPoke('drawMode', 'temp_alloc');

                        # Any region paths using the other exit will have to be updated
                        $self->ivAdd('updatePathHash', $otherExitObj->number, $regionObj->name);
                        if ($otherExitObj->regionFlag) {

                            $self->ivAdd(
                                'updateBoundaryHash',
                                $otherExitObj->number,
                                $regionObj->name,
                            );
                        }
                    }
                }

                # Check this room's hash of incoming uncertain objects
                foreach my $uncertainNum ($roomObj->ivKeys('uncertainExitHash')) {

                    my ($twinNumber, $uncertainExitObj);

                    $twinNumber = $roomObj->ivShow('uncertainExitHash', $uncertainNum);
                    if ($twinNumber && $twinNumber == $exitObj->number) {

                        # Convert the uncertain exit to a one-way exit
                        $uncertainExitObj = $self->ivShow('exitModelHash', $uncertainNum);
                        $self->convertUncertainExit(
                            FALSE,      # Don't update Automapper windows yet
                            $uncertainExitObj,
                            $self->ivShow('modelHash', $uncertainExitObj->parent),
                        );
                    }
                }

                # Remove the exit from the room's list of exit names (each corresponding to a
                #   direction)
                foreach my $dir ($roomObj->sortedExitList) {

                    if ($dir ne $exitObj->dir) {

                        push (@dirList, $dir);
                    }
                }

                $roomObj->ivPoke('sortedExitList', @dirList);

                # Remove the exit from the room's hash of numbered exits
                $roomObj->ivDelete('exitNumHash', $exitObj->dir);

                # Update the parent room's regionmap
                $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);
                $regionmapObj->removeExit($exitObj);
                # (We can save a bit of time in the code below by storing each exit's regionmap
                #   temporarily)
                $regionHash{$exitObj} = $regionmapObj;

                # Also update the twin exit's regionmap (if there is one)
                if ($twinRoomObj && $twinExitObj) {

                    $twinRegionObj = $self->ivShow('modelHash', $twinRoomObj->parent);
                    $twinRegionmapObj = $self->ivShow('regionmapHash', $twinRegionObj->name);
                    $twinRegionmapObj->resetExit($twinExitObj);

                    $regionHash{$twinExitObj} = $twinRegionmapObj;
                }
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $thisRoomObj (values %roomHash) {

                push (@redrawList, 'room', $thisRoomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                foreach my $exitObj (@exitList) {

                    my ($regionmapObj, $parchmentObj);

                    $regionmapObj = $regionHash{$exitObj};
                    $parchmentObj = $mapWin->ivShow('parchmentHash', $regionmapObj->name);

                    # Delete the exit's canvas object (if it exists)
                    $mapWin->deleteCanvasObj('exit', $exitObj, $regionmapObj, $parchmentObj, TRUE);
                    # Delete the exit tag's canvas object (which might exist, even if the exit's
                    #   canvas object does not)
                    $mapWin->deleteCanvasObj(
                        'exit_tag',
                        $exitObj,
                        $regionmapObj,
                        $parchmentObj,
                        TRUE,
                    );

                    # Some other function may have placed the exit and the exit tag (if any) on the
                    #   automapper's list of objects to draw; if so, remove them
                    if ($parchmentObj) {

                        $parchmentObj->ivDelete('markedExitHash', $exitObj->number);
                        $parchmentObj->ivDelete('markedExitTagHash', $exitObj->number);
                    }
                }

                # Redraw all those rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub emergencyDeleteExit {

        # Must only be called by GA::Cmd::TestModel->do for orphan exits
        # Deletes the exit (which should be some kind of orphan exit) from the exit model, but does
        #   not try to update anything else
        #
        # Expected arguments
        #   $exitObj        - The exit to forcably delete
        #
        # Return values
        #   'undef' on improper arguments or if $exitObj isn't an orphan exit
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Local variables
        my ($roomObj, $twinExitObj);

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->emergencyDeleteExit', @_);
        }

        # Get the exit's parent room (it shouldn't have one, or the parent should be set to some
        #   kind of model object other than a room)
        $roomObj = $self->ivShow('modelHash', $exitObj->parent);
        if ($roomObj && $roomObj->category eq 'room') {

            return undef;
        }

        # If this exit has a twin (that really exists), abandon it (using code adapted from
        #   $self->abandonTwinExit)
        if ($exitObj->twinExit) {

            $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
            if ($twinExitObj) {

                # Modify $twinExitObj
                $twinExitObj->ivUndef('destRoom');
                $twinExitObj->ivUndef('twinExit');
                # If this exit is marked as a broken or region exit, convert it into an incomplete
                #   exit
                $twinExitObj->ivPoke('brokenFlag', FALSE);
                $twinExitObj->ivPoke('regionFlag', FALSE);
                $twinExitObj->ivPoke('superFlag', FALSE);
                $twinExitObj->ivPoke('notSuperFlag', FALSE);

                # Set ->randomType too, just to be safe
                $twinExitObj->ivPoke('randomType', 'none');
            }
        }

        # Mark the number of this object as having been deleted, so it can be reused
        $self->ivPush('exitBufferList', $exitObj->number);
        # Remove the exit from the model
        $self->ivDelete('exitModelHash', $exitObj->number);
        $self->ivDecrement('exitActualCount');

        # Make sure the deleted exit is not marked to be re-drawn
        foreach my $mapWin ($self->collectMapWins()) {

            # Unfortunately this means checking every parchment. We don't know the parent region of
            #   an orphaned exit
            foreach my $parchmentObj ($mapWin->ivValues('parchmentHash')) {

                $parchmentObj->ivDelete('markedExitHash', $exitObj->number);
                $parchmentObj->ivDelete('markedExitTagHash', $exitObj->number);
            }
        }

        return 1;
    }

    sub deleteLabels {

        # Called by GA::Win::Map->deleteLabelCallback
        # Deletes one of more GA::Obj::MapLabel objects
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #
        # Optional arguments
        #   @labelList      - A list of GA::Obj::MapLabel objects to delete. If the list is empty,
        #                       no labels are deleted
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, @labelList) = @_;

        # Check for improper arguments
        if (! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteLabels', @_);
        }

        # If @labelList is empty, do nothing
        if (! @labelList) {

            return undef;
        }

        # Before any deletion operation, all selected canvas objects must be un-selected (but don't
        #   need to to do that if there has been an earlier call to $self->deleteRegions)
        if (! $self->blockUnselectFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                $mapWin->setSelectedObj();
            }
        }

        foreach my $labelObj (@labelList) {

            # Get the label's parent regionmap
            my $regionmapObj = $self->ivShow('regionmapHash', $labelObj->region);

            # Remove the label from the regionmap
            $regionmapObj->removeLabel($labelObj);

            # The regionmap's highest/lowest occupied levels need to be recalculated
            $self->ivAdd('checkLevelsHash', $regionmapObj->name, undef);

            # Update any GA::Win::Map objects using this world model (if allowed)
            if ($updateFlag) {

                foreach my $mapWin ($self->collectMapWins()) {

                    my $parchmentObj = $mapWin->ivShow('parchmentHash', $regionmapObj->name);

                    # Delete the label's canvas object (if it exists)
                    $mapWin->deleteCanvasObj(
                        'label',
                        $labelObj,
                        $regionmapObj,
                        $parchmentObj,
                        TRUE,
                    );

                    # Some other function may have placed the label on the automapper's list of
                    #   objects to draw; if so, remove them
                    if ($parchmentObj) {

                        $parchmentObj->ivDelete('markedLabelHash', $labelObj->number);
                        $parchmentObj->ivDelete('queueLabelHash', $labelObj->number);
                    }
                }
            }
        }

        return 1;
    }

    # Move model objects

    sub moveRoomsLabels {

        # Called by GA::Win::Map->moveSelectedObjs
        # Moves one or more selected rooms and labels to a new position, possibly in a new region
        # NB It's up to the calling function to check that rooms are not being moved into
        #   occupied gridblocks
        #
        # Expected arguments
        #   $session            - The calling function's GA::Session
        #   $updateFlag         - Flag set to TRUE if all Automapper windows using this world model
        #                           should be updated now, FALSE if not (in which case, they can be
        #                           updated later by the calling function, when it is ready)
        #   $oldRegionmapObj    - The GA::Obj::Regionmap from which the rooms are being moved (NB
        #                           all the rooms/labels are in the same region)
        #   $newRegionmapObj    - The GA::Obj::Regionmap to which the rooms are being moved (may
        #                           be the same as $oldRegionmapObj)
        #   $adjustXPos, $adjustYPos, $adjustZPos
        #                       - Describes a vector between the coordinates of the rooms/labels in
        #                           their old position, and and their coordinates in the new
        #                           position
        #   $roomHashRef        - Reference to a hash of GA::ModelObj::Room objects to move. Hash
        #                           in the form
        #                               $roomHash{model_number} = blessed_reference_to_room_object
        #   $labelHashRef       - Reference to a hash of GA::Obj::MapLabel objects to move. Hash in
        #                           either of the following forms
        #                               $labelHash{label_id) = blessed_reference_to_map_label_object
        #                               $labelHash{label_number) = blessed_ref_to_map_label_object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $session, $updateFlag, $oldRegionmapObj, $newRegionmapObj, $adjustXPos,
            $adjustYPos, $adjustZPos, $roomHashRef, $labelHashRef, $check,
        ) = @_;

        # Local variables
        my (
            $oldRegionObj, $newRegionObj,
            @mapWinList, @drawList,
            %roomHash, %labelHash, %checkExitHash, %drawHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $oldRegionmapObj
            || ! defined $newRegionmapObj || ! defined $adjustXPos || ! defined $adjustYPos
            || ! defined $adjustZPos || ! defined $roomHashRef || ! defined $labelHashRef
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->moveRoomsLabels', @_);
        }

        # De-reference the hashes
        # A hash of rooms, in the form
        #   $roomHash{model_number} = blessed_reference_to_room_object
        %roomHash = %$roomHashRef;
        # A hash of labels, in the form
        #   $labelHash{label_number) = blessed_reference_to_map_label_object
        %labelHash = %$labelHashRef;

        # Get the corresponding GA::ModelObj::Region objects
        $oldRegionObj = $self->ivShow('modelHash', $oldRegionmapObj->number);
        $newRegionObj = $self->ivShow('modelHash', $newRegionmapObj->number);

        # The automapper stores canvas objects for each drawn room in a hash, using a key in the
        #   form (x_y_z). However, after the rooms are moved to their new position, the Axmud code
        #   will have no way of knowing what the old position was, and thus they won't be able to
        #   find the right key
        # Therefore, when moving rooms around in the same region, we have to delete canvas objects
        #   in each automapper window now, even if $updateFlag is FALSE
        # (Don't need to delete anything if the whole region is going to be redrawn anyway)

        # Compile a list of automapper windows using this world model now (so we only have to do it
        #   once)
        @mapWinList = $self->collectMapWins();
        # Any moved room, plus any room connected to it, must be redrawn. (Redrawing connected
        #   rooms guarantees that exits are redrawn correctly)
        # Compile a hash of rooms to be redrawn to eliminate duplicates
        foreach my $roomObj (values %roomHash) {

            $drawHash{$roomObj->number} = $roomObj;

            foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

                my ($exitObj, $otherRoomObj);

                $exitObj = $self->ivShow('exitModelHash', $exitNum);

                if ($exitObj->destRoom) {

                    $otherRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
                    $drawHash{$otherRoomObj->number} = $otherRoomObj;
                }
            }

            foreach my $exitNum (
                $roomObj->ivKeys('uncertainExitHash'),
                $roomObj->ivKeys('oneWayExitHash'),
            ) {
                my ($exitObj, $otherRoomObj);

                $exitObj = $self->ivShow('exitModelHash', $exitNum);
                $otherRoomObj = $self->ivShow('modelHash', $exitObj->parent);
                $drawHash{$otherRoomObj->number} = $otherRoomObj;
            }
        }

        foreach my $mapWin (@mapWinList) {

            my $parchmentObj = $mapWin->ivShow('parchmentHash', $oldRegionmapObj->name);

            foreach my $roomObj (values %drawHash) {

                $mapWin->deleteCanvasObj('room', $roomObj, $oldRegionmapObj, $parchmentObj);
                # Also destroy the canvas objects for any checked directions
                $mapWin->deleteCanvasObj('checked_dir', $roomObj, $oldRegionmapObj, $parchmentObj);
                # Also destroy canvas objects for their exits
                foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

                    $mapWin->deleteCanvasObj(
                        'exit',
                        $self->ivShow('exitModelHash', $exitNum),
                        $oldRegionmapObj,
                        $parchmentObj,
                    );
                }
            }
        }

        # Regardless of whether $updateFlag is set, if the whole region isn't going to be redrawn,
        #   canvas objects for each room must be deleted
        # Remove each room in turn from its old position in $oldRegionmapObj's grid
        foreach my $roomObj (values %roomHash) {

            # Remove the entries in the old regionmap's ->gridRoomHash, ->gridRoomTagHash and
            #   ->gridRoomGuildHash
            $oldRegionmapObj->removeRoom($roomObj);

            # If the room is moving from one region to another...
            if ($oldRegionObj ne $newRegionObj) {

                # Tell the old region that it has lost a child, and tell the new region that it has
                #   acquired one
                $oldRegionObj->ivDelete('childHash', $roomObj->number);
                $newRegionObj->ivAdd('childHash', $roomObj->number, undef);
                $roomObj->ivPoke('parent', $newRegionObj->number);

                # Remove the entries for each of the room's exits in the old regionmap's
                #   ->gridExitHash (the entries wouldn't need to be replaced if the room were
                #   staying in the same region)
                foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

                    my $exitObj = $self->ivShow('exitModelHash', $exitNum);

                    # Remove the entries in the old regionmap's ->gridExitHash and ->gridExitTagHash
                    $oldRegionmapObj->removeExit($exitObj);

                    # Any exits which are currently region exits must be checked, once they have
                    #   been moved, to see if they are now broken exits (all exits are first checked
                    #   to see if they are region exits)
                    if ($exitObj->regionFlag) {

                        $checkExitHash{$exitNum} = $exitObj;
                    }
                }
            }

            # The regionmaps' highest/lowest occupied levels need to be recalculated
            $self->ivAdd('checkLevelsHash', $oldRegionmapObj->name, undef);
        }

        # Move each room in turn to its new position in $newRegionmapObj's grid
        foreach my $roomObj (values %roomHash) {

            # Set the room's new coordinates
            $roomObj->ivPoke('xPosBlocks', ($roomObj->xPosBlocks + $adjustXPos));
            $roomObj->ivPoke('yPosBlocks', ($roomObj->yPosBlocks + $adjustYPos));
            $roomObj->ivPoke('zPosBlocks', ($roomObj->zPosBlocks + $adjustZPos));

            # Make new entries in the regionmap's ->gridRoomHash, ->gridRoomTagHash and
            #   ->gridRoomGuildHash
            $newRegionmapObj->storeRoom($roomObj);

            # If the room is moving from one region to another...
            if ($oldRegionObj ne $newRegionObj) {

                # Make entries in new regionmap's ->gridExitHash
                foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

                    my $exitObj = $self->ivShow('exitModelHash', $exitNum);

                    $newRegionmapObj->storeExit($exitObj);
                    if ($exitObj->exitTag) {

                        $newRegionmapObj->storeExitTag($exitObj);
                    }
                }

                # Update ->livingCountHash and ->nonLivingCountHash in both regionmaps
                $newRegionmapObj->storeLivingCount(
                    $roomObj->number,
                    $oldRegionmapObj->removeLivingCount($roomObj->number),
                );

                $newRegionmapObj->storeNonLivingCount(
                    $roomObj->number,
                    $oldRegionmapObj->removeNonLivingCount($roomObj->number),
                );

                # The regionmaps' highest/lowest occupied levels need to be recalculated
                $self->ivAdd('checkLevelsHash', $newRegionmapObj->name, undef);
            }
        }

        # If the rooms have been moved to a new region, we must check each of their exits to see
        #   whether they are now region exits
        if ($oldRegionObj ne $newRegionObj) {

            foreach my $roomObj (values %roomHash) {

                foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

                    my ($exitObj, $twinExitObj, $destRoomObj);

                    $exitObj = $self->ivShow('exitModelHash', $exitNum);
                    if ($exitObj->twinExit) {

                        $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
                    }

                    # If the exit leads to a room in a different region to the new region, it must
                    #   be added to the regionmap's ->regionExitHash
                    if ($exitObj->destRoom) {

                        $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
                        if ($destRoomObj->parent != $newRegionObj->number) {

                            # This is a region exit
                            $self->setRegionExit(
                                FALSE,          # Don't update Automapper windows
                                $exitObj,
                                $newRegionObj->number,
                            );

                            # The twin exit, if there is one, must also be marked as a region exit
                            if ($twinExitObj) {

                                $self->setRegionExit(
                                    FALSE,          # Don't update Automapper windows
                                    $twinExitObj,
                                    $destRoomObj->parent,
                                );
                            }

                        } else {

                            # Definitely not a region exit - and neither is its twin (if there is
                            #   one)...
                            if ($exitObj->regionFlag) {

                                $self->unsetRegionExit(
                                    FALSE,          # Don't update Automapper windows
                                    $exitObj,
                                    $newRegionmapObj->number,
                                );
                            }

                            if ($twinExitObj && $twinExitObj->regionFlag) {

                                $self->unsetRegionExit(
                                    FALSE,          # Don't update Automapper windows
                                    $twinExitObj,
                                    $destRoomObj->parent,
                                );
                            }

                            # For any exits which were formerly region exits, they are probably
                            #   now broken exits
                            if (exists $checkExitHash{$exitObj->number}) {

                                # If (by chance) the two rooms are aligned in the direction of
                                #   their exit, it's not a broken exit
                                if (! $self->checkRoomAlignment($session, $exitObj)) {

                                    # The two rooms aren't aligned so $exitObj is a broken exit and
                                    #   so is its twin (if there is one)
                                    # (Don't convert the exits to broken exits if they were already
                                    #   broken exits - the call to ->setBrokenExit would reset
                                    #   various IVs such as ->bentFlag)
                                    if (! $exitObj->brokenFlag) {

                                        $self->setBrokenExit(
                                            FALSE,          # Don't update Automapper windows
                                            $exitObj,
                                            $newRegionmapObj->number,
                                        );
                                    }

                                    if ($twinExitObj && ! $twinExitObj->brokenFlag) {

                                        $self->setBrokenExit(
                                            FALSE,          # Don't update Automapper windows
                                            $twinExitObj,
                                            $destRoomObj->parent,
                                        );
                                    }

                                } else {

                                    # It's not a broken exit, and neither is its twin (if there is
                                    #   one)
                                    $self->unsetBrokenExit(
                                        FALSE,              # Don't update Automapper windows
                                        $exitObj,
                                        $newRegionmapObj->number,
                                    );

                                    if ($twinExitObj) {

                                        $self->unsetBrokenExit(
                                            FALSE,          # Don't update Automapper windows
                                            $twinExitObj,
                                            $destRoomObj->parent,
                                        );
                                    }
                                }
                            }
                        }
                    }
                }
            }

        # If the rooms have been moved to a new position in the same region, we have to check each
        #   exit to see whether it's a broken exit
        } else {

            foreach my $roomObj (values %roomHash) {

                foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

                    my ($exitObj, $twinExitObj);

                    $exitObj = $self->ivShow('exitModelHash', $exitNum);
                    if ($exitObj->twinExit) {

                        $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
                    }

                    # If the exit doesn't lead to one of the rooms that we've just moved - i.e. if
                    #   the destination room isn't in %roomHash - then we need to check whether it's
                    #   a broken exit or not. (Dont' bother if it's already marked as a region exit)
                    if (
                        ! $exitObj->regionFlag
                        && $exitObj->destRoom
                        && ! exists $roomHash{$exitObj->destRoom}
                    ) {
                        # This might be a broken exit
                        if (! $self->checkRoomAlignment($session, $exitObj)) {

                            # The two rooms aren't aligned so $exitObj is a broken exit and so is
                            #   its twin (if there is one)
                            # (Don't convert the exits to broken exits if they were already broken
                            #   exits - the call to ->setBrokenExit would reset various IVs such as
                            #   ->bentFlag)
                            if (! $exitObj->brokenFlag) {

                                $self->setBrokenExit(
                                    FALSE,          # Don't update Automapper windows
                                    $exitObj,
                                    $newRegionmapObj->number,
                                );
                            }

                            if ($exitObj->bendOffsetList) {

                                # The position of any bends, relative to the dragged room, must be
                                #   reset
                                $self->updateExitBends(
                                    $adjustXPos,
                                    $adjustYPos,
                                    $adjustZPos,
                                    $newRegionmapObj,
                                    $exitObj,
                                    $twinExitObj,
                                );
                            }

                            if ($twinExitObj && ! $twinExitObj->brokenFlag) {

                                $self->setBrokenExit(
                                    FALSE,          # Don't update Automapper windows
                                    $twinExitObj,
                                    undef,          # Let ->setBrokenExit work out exit's region
                                );
                            }

                        } elsif ($exitObj->brokenFlag) {

                            # The exit is marked as a broken exit, but the two rooms are aligned,
                            #   so it's no longer a broken exit
                            $self->unsetBrokenExit(
                                FALSE,              # Don't update Automapper windows
                                $exitObj,
                                $newRegionmapObj->number,
                            );

                            if ($twinExitObj) {

                                $self->unsetBrokenExit(
                                    FALSE,          # Don't update Automapper windows
                                    $twinExitObj,
                                    undef,          # Let ->setBrokenExit work out exit's region
                                );
                            }
                        }
                    }
                }
            }
        }

        # Move each label in turn
        foreach my $labelObj (values %labelHash) {

            # If the label is moving from one region to another...
            if ($oldRegionObj ne $newRegionObj) {

                # Remove the label's entry in the old regionmap's ->gridRoomHash
                $oldRegionmapObj->removeLabel($labelObj);

                # Add it to the new region
                $newRegionmapObj->storeLabel($labelObj);

                # The label object's ->number has already been modified, so that it's a unique
                #   number for the region - but we still need to update the name of the region
                #   in which the label is stored
                $labelObj->ivPoke('region', $newRegionmapObj->name);
            }

            # Set the label's new position on the new regionmap
            $labelObj->ivPoke(
                'xPosPixels',
                ($labelObj->xPosPixels + ($adjustXPos * $newRegionmapObj->blockWidthPixels)),
            );

            $labelObj->ivPoke(
                'yPosPixels',
                ($labelObj->yPosPixels + ($adjustYPos * $newRegionmapObj->blockHeightPixels)),
            );

            $labelObj->ivPoke('level', ($labelObj->level + $adjustZPos));
        }

        # Now, if the room(s) were moved to a different region, update their incoming one-way /
        #   uncertain exits
        if ($oldRegionmapObj ne $newRegionmapObj) {

            my (@regionExitList);

            # We must check each of the moved rooms. If any of them have one-way or uncertain exits
            #   leading towards them, those exits must be marked as region exits
            # Two-way exits will already have been marked as region exits, so we don't need to worry
            #   about them
            foreach my $roomObj (values %roomHash) {

                my @exitNumList = (
                    $roomObj->ivKeys('uncertainExitHash'),
                    $roomObj->ivKeys('oneWayExitHash'),
                );

                foreach my $exitNum (@exitNumList) {

                    my ($exitObj, $departRoomObj);

                    $exitObj = $self->ivShow('exitModelHash', $exitNum);
                    $departRoomObj = $self->ivShow('modelHash', $exitObj->parent);

                    if ($departRoomObj->parent eq $oldRegionObj->number) {

                        # Mark the uncertain exit as a region exit (and definitely not a broken
                        #   exit). The called function must work out the parent region of the
                        #   destination room.
                        $self->setRegionExit(
                            FALSE,                  # Don't update Automapper windows
                            $exitObj,
                            $departRoomObj->parent,
                        );
                    }
                }
            }

        # Otherwise, if rooms were moved in the same region, check their incoming one-way /
        #   / uncertain exits
        } else {

            # We must check each of the moved rooms. If any of them have one-way or uncertain exits,
            #   we have to check whether they're broken exits or not
            # Two-way exits will already have been marked as broken exits, so we don't need to worry
            #   about them
            foreach my $roomObj (values %roomHash) {

                my @exitNumList = (
                    $roomObj->ivKeys('uncertainExitHash'),
                    $roomObj->ivKeys('oneWayExitHash'),
                );

                foreach my $exitNum (@exitNumList) {

                    my ($exitObj, $departRoomObj);

                    $exitObj = $self->ivShow('exitModelHash', $exitNum);
                    $departRoomObj = $self->ivShow('modelHash', $exitObj->parent);

                    # This might be a broken exit
                    if (! $self->checkRoomAlignment($session, $exitObj)) {

                        # The two rooms aren't aligned, so it's a broken exit
                        $self->setBrokenExit(
                            FALSE,              # Don't update Automapper windows
                            $exitObj,
                            $departRoomObj->parent,
                        );

                    } else {

                        # It's not a broken exit
                        $self->unsetBrokenExit(
                            FALSE,              # Don't update Automapper windows
                            $exitObj,
                            $departRoomObj->parent,
                        );
                    }
                }
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Compile a list of rooms, including all the rooms in %drawHash, and any rooms that are
            #   connected to those rooms
            push (@drawList, $self->compileRedrawRooms(values %drawHash));
            # Add any labels to that list
            foreach my $labelObj (values %labelHash) {

                push (@drawList, 'label', $labelObj);
            }

            # Redraw all of the affected rooms/labels
            foreach my $mapWin (@mapWinList) {

                $mapWin->markObjs(@drawList);
                $mapWin->doDraw();
            }
        }

        # Operation complete
        return 1;
    }

    sub moveOtherObjs {

        # Called by GA::Win::Map->stopDrag at the end of a drag operation for a room tag, room
        #   guild, exit tags or label (if the drag involves any rooms, $self->moveSelectedObjs is
        #   called instead, and exits can't be dragged)
        # Updates the dragged object and redraws it (if allowed)
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $type           - The type of dragged canvas object - 'room_tag', 'room_guild',
        #                       'exit_tag' or 'label'
        #   $dragObj        - The GA::ModelObj::Room, GA::Obj::Exit or GA::Obj::MapLabel which
        #                       corresponds to the dragged canvas object
        #   $xPos, $yPos    - The object's new position on the map (in pixels)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $type, $dragObj, $xPos, $yPos, $check) = @_;

        # Local variables
        my @redrawList;

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $type || ! defined $dragObj || ! defined $xPos
            || ! defined $yPos || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->moveOtherObjs', @_);
        }

        # Update the corresponding room tag, room guild or label
        if ($type eq 'room_tag') {

            # Set the room tag's new position
            $dragObj->ivPoke('roomTagXOffset', $dragObj->roomTagXOffset + $xPos);
            $dragObj->ivPoke('roomTagYOffset', $dragObj->roomTagYOffset + $yPos);

            # Mark the room to be redrawn, which draws the room tag in its new position
            @redrawList = ('room', $dragObj);

        } elsif ($type eq 'room_guild') {

            # Set the room guild's new position
            $dragObj->ivPoke('roomGuildXOffset', $dragObj->roomGuildXOffset + $xPos);
            $dragObj->ivPoke('roomGuildYOffset', $dragObj->roomGuildYOffset + $yPos);

            # Mark the room to be redrawn, which draws the room guild in its new position
            @redrawList = ('room', $dragObj);

        } elsif ($type eq 'exit_tag') {

            # Set the room guild's new position
            $dragObj->ivPoke('exitTagXOffset', $dragObj->exitTagXOffset + $xPos);
            $dragObj->ivPoke('exitTagYOffset', $dragObj->exitTagYOffset + $yPos);

            # Mark the exit to be redrawn, which draws the exit tag in its new position
            @redrawList = ('exit', $dragObj);

        } elsif ($type eq 'label') {

            # Set the map label's new position
            $dragObj->ivPoke('xPosPixels', $dragObj->xPosPixels + $xPos);
            $dragObj->ivPoke('yPosPixels', $dragObj->yPosPixels + $yPos);

            # Mark the label to be redrawn
            @redrawList = ('label', $dragObj);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the dragged object
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub mergeMap {

        # Called by GA::Win::Map->doMerge (or by any other automapper code)
        # Merges a room (or a group of rooms) into a different room (or group of rooms)
        # This is useful if the user is lost (or has been transported to some random location). This
        #   function merges rooms in a region (or an area of a region) that the user wants to
        #   discard into a region (or an area of a region) that user wants to keep. The room's IVs
        #   are preserved, as far as possible (for example, the character visit counts in pairs of
        #   merged rooms are combined)
        # The merge operation is fairly intelligent. The code compares rooms to work out which
        #   pairs of rooms should be merged. This partly depends on how rooms are connected to each
        #   other, but can also depend on the rooms' positions on the maps
        #
        # The function takes at least two arguments. $targetRoomObj and $twinRoomObj are
        #   assumed to represent the same room in the game world; those two rooms are definitely
        #   merged together. $targetRoomObj survives and $twinRoomObject is destroyed
        # @otherRoomList is optional. If specified, it should be one or more rooms which are near
        #   $twinRoomObj, representing a region (or an area of the region) that the user wants to
        #   discard
        # The function checks rooms that are connected to $targetRoomObj (the one that's going to
        #   survive) to see if the rooms connected to it can be merged with any rooms in
        #   @otherRoomList which are connected to @otherRoomList. If so, those pairs of rooms are
        #   merged, too
        # Any rooms in @otherRoomList which can't be merged are simply moved, with their position
        #   relative to $twinRoomObj being replaced with a new position relative to $targetRoomObj.
        #   If it's not possible to move a room in @otherRoomList, because the relative position is
        #   already occupied, then that room is not moved (or merged). It's up to the calling
        #   function to decide what to do with it
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $targetRoomObj  - A GA::ModelObj::Room object which will survive the merge operation
        #   $twinRoomObj    - A GA::ModelObj::Room object which is assumed to represent the same
        #                       room in the game world
        #
        # Optional arguments
        #   $otherRoomListRef
        #                   - Reference to a secondary list of rooms which are either connected to
        #                       $twinRoomObj or are (at the very least) in the same region as it,
        #                       and which should be merged or moved as well, if possible (otherwise
        #                       'undef' or a reference to an empty list)
        #   $labelListRef   - Reference to a list of labels in the same region as $twinRoomObj which
        #                       should also be moved (otherwise 'undef' or a reference to an empty
        #                       list)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success (meaning that $targetRoomObj and $twinRoomObj were merged, and that an
        #       unspecified number of rooms in @otherRoomList might have been merged or moved, too)

        my (
            $self, $session, $targetRoomObj, $twinRoomObj, $otherRoomListRef, $labelListRef,
            $check,
        ) = @_;

        # Local variables
        my (
            $regionmapObj, $twinRegionmapObj, $result,
            @otherRoomList, @labelList, @checkRoomList, @deleteList, @selectList,
            %labelHash, %mergeHash, %noMergeHash, %moveHash, %reconnectHash, %reverseHash,
            %disconnectHash,
        );

        # Check for improper arguments
        if (! defined $targetRoomObj || ! defined $twinRoomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mergeMap', @_);
        }

        # De-reference the list arguments, if specified
        if (defined $otherRoomListRef) {

            @otherRoomList = @$otherRoomListRef;
        }

        if (defined $labelListRef) {

            # Convert to a hash, ready for the call to $self->moveRoomsLabels
            foreach my $labelObj (@$labelListRef) {

                $labelHash{$labelObj->id} = $labelObj;
            }
        }

        # Basic checks. We'll assume that the calling function is satisfied that the target and twin
        #   rooms are actually represent the same room in the world

        # The target and twin rooms must not be the same room model object
        if ($targetRoomObj eq $twinRoomObj) {

            return undef;
        }

        # Neither may appear in @otherRoomList. Any rooms in @otherRoomList must be in the same
        #   region as $twinRoomObj
        foreach my $otherRoomObj (@otherRoomList) {

            if (
                $otherRoomObj eq $targetRoomObj
                || $otherRoomObj eq $twinRoomObj
                || $otherRoomObj->parent != $twinRoomObj->parent
            ) {
                return undef;
            }
        }

        # Get the target room's regionmap
        $regionmapObj = $self->findRegionmap($targetRoomObj->parent);
        $twinRegionmapObj = $self->findRegionmap($twinRoomObj->parent);
        if (! $regionmapObj) {

            return undef;
        }

        # Once a merge operation has started, the automapper object doesn't need to check that
        #   the (newly-set) current room is in the temporary region any more
        $session->mapObj->reset_rescueCheckFlag();

        # Compile a list of pairs of rooms that will be merged with each other, starting with...
        $mergeHash{$twinRoomObj->number} = $targetRoomObj->number;

        # Now go through the rooms in @otherRoomList. Our goal is to check which of those rooms are
        #   connected to $twinRoomObj via exits, and then to see if there are any matching rooms
        #   connected to %targetRoomObj via equivalent exits; any room pairs we find can be marked
        #   as mergeable
        if (@otherRoomList) {

            # (Keep track of which rooms haven't yet been marked as mergeable)
            foreach my $otherRoomObj (@otherRoomList) {

                $noMergeHash{$otherRoomObj->number} = $otherRoomObj;
            }

            # Start by checking the exits in $twinRoomObj itself
            push (@checkRoomList, $twinRoomObj);

            do {

                my ($checkRoomObj, $mergeRoomObj);

                # $checkRoomObj is either $twinRoomObj itself, or one of the rooms directly
                #   connected to it
                $checkRoomObj = shift @checkRoomList;
                # Get the room with which $checkRoomObj will be merged
                $mergeRoomObj = $self->ivShow('modelHash', $mergeHash{$checkRoomObj->number});

                # Check all of $checkRoomObj's outgoing exits, one by one
                OUTER: foreach my $exitNum ($checkRoomObj->ivValues('exitNumHash')) {

                    my ($exitObj, $destRoomObj, $exitNum2, $exitObj2, $destRoomObj2);

                   $exitObj = $self->ivShow('exitModelHash', $exitNum);

                    # If this exit's destination room is one of those which might be merged, get the
                    #   destination room object
                    if ($exitObj->destRoom && exists $noMergeHash{$exitObj->destRoom}) {

                        $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);

                        # If the equivalent room has an exit in the same direction, get that exit's
                        #   destination room
                        $exitNum2 = $mergeRoomObj->ivShow('exitNumHash', $exitObj->dir);
                        if (defined $exitNum2) {

                            $exitObj2 = $self->ivShow('exitModelHash', $exitNum2);
                        }

                        if ($exitObj2 && $exitObj2->destRoom) {

                            $destRoomObj2 = $self->ivShow('modelHash', $exitObj2->destRoom);
                        }
                    }

                    # Compare the two destination rooms to see if they are also matches
                    if ($destRoomObj2) {

                        ($result) = $self->compareRooms($session, $destRoomObj, $destRoomObj2);
                        if ($result) {

                            # Success! Mark these rooms as mergeable
                            $mergeHash{$destRoomObj->number} = $destRoomObj2->number;
                            delete $noMergeHash{$destRoomObj->number};

                            # $destRoomObj is connected to $twinRoomObj; in a future iteration of
                            #   this loop, check $destRoomObj's exits too
                            push (@checkRoomList, $destRoomObj);
                        }
                    }
                }

                # Check all of $checkRoomObj's incoming uncertain exits, one by one
                OUTER: foreach my $key ($checkRoomObj->ivKeys('uncertainExitHash')) {

                    my (
                        $exitObj, $incomingExitObj, $parentRoomObj, $exitNum2, $exitObj2,
                        $parentRoomObj2,
                    );

                    # $exitObj is the exit belonging to $checkRoomObj, and $incomingExitObj is an
                    #   an uncertain exit which might be its twin exit)
                    $exitObj = $self->ivShow(
                        'exitModelHash',
                        $checkRoomObj->ivShow('uncertainExitHash', $key),
                    );

                   $incomingExitObj = $self->ivShow('exitModelHash', $key);

                    # If this incoming exit's parent room is one of those which might be merged, get
                    #   the parent room object
                    if (exists $noMergeHash{$incomingExitObj->parent}) {

                       $parentRoomObj = $self->ivShow('modelHash', $incomingExitObj->parent);

                        # If the equivalent room has an outgoing exit in the same direction as
                        #   $exitObj, or an incoming exit in the same direction as $incomingExitObj,
                        #   get the corresponding destination/parent room
                        $exitNum2 = $mergeRoomObj->ivShow('exitNumHash', $exitObj->dir);
                        if (defined $exitNum2) {

                            $exitObj2 = $self->ivShow('exitModelHash', $exitNum2);
                            if ($exitObj2->destRoom) {

                                $parentRoomObj2 = $self->ivShow('modelHash', $exitObj2->destRoom);
                            }

                        } else {

                            INNER: foreach my $key ($mergeRoomObj->ivKeys('uncertainExitHash')) {

                                my $incomingExitObj2 = $self->ivShow('exitModelHash', $key);

                                if ($incomingExitObj2->dir eq $incomingExitObj->dir) {

                                    $parentRoomObj2
                                        = $self->ivShow('modelHash', $incomingExitObj2->parent);

                                    last INNER;
                                }
                            }
                        }
                    }

                    # Compare the two parent rooms to see if they are also matches
                    if ($parentRoomObj2) {

                        ($result) = $self->compareRooms($session, $parentRoomObj, $parentRoomObj2);
                        if ($result) {

                            # Success! Mark these rooms as mergeable
                            $mergeHash{$parentRoomObj->number} = $parentRoomObj2->number;
                            delete $noMergeHash{$parentRoomObj->number};

                            # $parentRoomObj is connected to $twinRoomObj; in a future iteration of
                            #   this loop, check $parentRoomObj's exits too
                            push (@checkRoomList, $parentRoomObj);
                        }
                    }
                }

                # Check all of $checkRoomObj's incoming one-way exits, one by one
                OUTER: foreach my $key ($checkRoomObj->ivKeys('oneWayExitHash')) {

                    my ($exitObj, $parentRoomObj, $parentRoomObj2);

                    $exitObj = $self->ivShow('exitModelHash', $key);

                    # If this one-way exit's parent room is one of those which might be merged, get
                    #   the parent room object
                    if (exists $noMergeHash{$exitObj->parent}) {

                        $parentRoomObj = $self->ivShow('modelHash', $exitObj->parent);

                        # If the equivalent room has an incoming one-way exit in the same direction
                        #   as $oneWayExitObj get the corresponding parent room
                        INNER: foreach my $key ($mergeRoomObj->ivKeys('oneWayExitHash')) {

                            my $exitObj2 = $self->ivShow('exitModelHash', $key);

                            if ($exitObj2->dir eq $exitObj->dir) {

                                $parentRoomObj2 = $self->ivShow('modelHash', $exitObj2->parent);
                                last INNER;
                            }
                        }
                    }

                    # Compare the two parent rooms to see if they are also matches
                    if ($parentRoomObj2) {

                        ($result) = $self->compareRooms($session, $parentRoomObj, $parentRoomObj2);
                        if ($result) {

                            # Success! Mark these rooms as mergeable
                            $mergeHash{$parentRoomObj->number} = $parentRoomObj2->number;
                            delete $noMergeHash{$parentRoomObj->number};

                            # $parentRoomObj is connected to $twinRoomObj; in a future iteration of
                            #   this loop, check $parentRoomObj's exits too
                            push (@checkRoomList, $parentRoomObj);
                        }
                    }
                }

            } until (! @checkRoomList);
        }

        # Any members of @otherRoomList which still survive in %noMergeHash are not merged with any
        #   existing room, but are simply moved to a new position
        foreach my $otherRoomObj (values %noMergeHash) {

            my ($xAdjust, $yAdjust, $zAdjust, $existRoomNum);

            # Find this room's position relative to $twinRoomObj
            $xAdjust = $otherRoomObj->xPosBlocks - $twinRoomObj->xPosBlocks;
            $yAdjust = $otherRoomObj->yPosBlocks - $twinRoomObj->yPosBlocks;
            $zAdjust = $otherRoomObj->zPosBlocks - $twinRoomObj->zPosBlocks;

            # At the same position, relative to $targetRoomObj, does a room already exist?
            $existRoomNum = $regionmapObj->fetchRoom(
                $targetRoomObj->xPosBlocks + $xAdjust,
                $targetRoomObj->yPosBlocks + $yAdjust,
                $targetRoomObj->zPosBlocks + $zAdjust,
            );

            if ($existRoomNum) {

                # Compare this room with $otherRoomObj. If they match, those two rooms can also be
                #   merged. If they don't match, $otherRoomObj is not moved or merged
                ($result) = $self->compareRooms($session, $targetRoomObj, $otherRoomObj);
                if (! $result) {

                    # Any rooms to be moved (not merged) which have exits leading to or from this
                    #   room must be disconnected from them, before redrawing the map
                    $disconnectHash{$otherRoomObj->number} = $otherRoomObj;

                } else {

                    $mergeHash{$otherRoomObj->number} = $existRoomNum;
                }

            } else {

                # The gridblock is empty, so $otherRoomObj can be moved there without being merged
                #   with other rooms
                $moveHash{$otherRoomObj->number} = $otherRoomObj;
            }
        }

        # For rooms in %moveHash, any exits which lead to a room in %mergeHash will be disconnected
        #   when the pair of rooms are merged, after which one of the pair is destroyed
        # Compile a hash of such exits and their new destination rooms so they can be reconnected
        #   after the merge operation
        foreach my $otherRoomObj (values %moveHash) {

            foreach my $exitNum ($otherRoomObj->ivValues('exitNumHash')) {

                my $exitObj = $self->ivShow('exitModelHash', $exitNum);

                if ($exitObj->destRoom && exists $mergeHash{$exitObj->destRoom}) {

                    # the exit number        = the replacement (surviving) destination room
                    $reconnectHash{$exitNum} = $mergeHash{$exitObj->destRoom};
                }
            }
        }

        # Now the same thing in reverse. For pairs of rooms in %mergeHash, if the room to be
        #   destroyed has any exits leading to a room in %moveHash, that exit will be disconnected
        # Update %reconnectHash with the equivalent exit in the surviving room and the same
        #   destination
        foreach my $key (keys %mergeHash) {

            my ($thisTwinObj, $thisTargetObj);

            $thisTwinObj = $self->ivShow('modelHash', $key);
            $thisTargetObj = $self->ivShow('modelHash', $mergeHash{$key});

            foreach my $exitNum ($thisTwinObj->ivValues('exitNumHash')) {

                my ($exitObj, $exitObj2);

                # $exitObj will be destroyed, along with its parent; $exitObj2 will survive
                $exitObj = $self->ivShow('exitModelHash', $exitNum);
                if ($thisTargetObj->ivExists('exitNumHash', $exitObj->dir)) {

                    $exitObj2 = $self->ivShow(
                        'exitModelHash',
                        $thisTargetObj->ivShow('exitNumHash', $exitObj->dir),
                    );

                    if (
                        $exitObj->destRoom
                        && exists $moveHash{$exitObj->destRoom}
                        && $exitObj2
                        && ! $exitObj2->destRoom
                    ) {
                        # the exit number                 = the moved destination room
                        $reconnectHash{$exitObj2->number} = $exitObj->destRoom;
                    }
                }
            }
        }

        if (%mergeHash) {

            # If the automapper's current room is any of the rooms that are about to be merged,
            #   change it
            if (
                $session->mapObj->currentRoom
                && exists ($mergeHash{$session->mapObj->currentRoom->number})
            ) {
                $session->mapObj->setCurrentRoom(
                    $self->ivShow('modelHash', $mergeHash{$session->mapObj->currentRoom->number}),
                );
            }

            # Merge the pairs of rooms in %mergeHash
            %reverseHash = reverse %mergeHash;
            foreach my $key (keys %mergeHash) {

                my ($thisTwinObj, $thisTargetObj);

                $thisTwinObj = $self->ivShow('modelHash', $key);
                $thisTargetObj = $self->ivShow('modelHash', $mergeHash{$key});

                # Merge the two rooms. $thisTargetObj is the one that survives
                $self->mergeRoom($thisTwinObj, $thisTargetObj);
                push (@deleteList, $self->ivShow('modelHash', $key));

                # Check $thisTargetObj's incoming uncertain exits. If the equivalent exit in
                #   $thisTwinObj is a two-way exit, we can make the former a two-way exit too
                foreach my $uncertainExitNum ($thisTargetObj->ivKeys('uncertainExitHash')) {

                    my (
                        $incompleteExitNum, $uncertainExitObj, $incompleteExitObj,
                        $uncertainRoomObj, $equivRoomObj, $equivExitNum, $equivExitObj,
                    );

                    # Every uncertain exit has a corresponding incomplete exit, which might be
                    #   connected to it (but we're not certain yet)
                    $incompleteExitNum
                        = $thisTargetObj->ivShow('uncertainExitHash', $uncertainExitNum);

                    $uncertainExitObj = $self->ivShow('exitModelHash', $uncertainExitNum);
                    $incompleteExitObj = $self->ivShow('exitModelHash', $incompleteExitNum);

                    $uncertainRoomObj = $self->ivShow('modelHash', $uncertainExitObj->parent);

                    # Does $uncertainRoomObj also exist in %mergeHash (i.e. are both that room and
                    #   $thisTwinObj being merged into other rooms?)
                    if (exists $reverseHash{$uncertainRoomObj->number}) {

                        # Get the room that will be merged into $uncertainRoomObj
                        $equivRoomObj
                            = $self->ivShow('modelHash', $reverseHash{$uncertainRoomObj->number});

                        # Is there an exit in $thisTwinObj in the same direction as
                        #   $incompleteExitObj, which is a two-way exit and whose destination room
                        #   is $equivRoomObj?
                        $equivExitNum = $thisTwinObj->ivShow(
                            'exitNumHash',
                            $incompleteExitObj->dir,
                        );

                        if (defined $equivExitNum) {

                            $equivExitObj = $self->ivShow('exitModelHash', $equivExitNum);
                            if (
                                $equivExitObj->twinExit
                                && $equivExitObj->destRoom
                                && $equivExitObj->destRoom == $equivRoomObj->number
                            ) {
                                # Convert $uncertainExitObj and $incompleteExitObj into two-way twin
                                #   exits
                                $self->connectRooms(
                                    $session,
                                    FALSE,                          # Don't update windows now
                                    $thisTargetObj,                 # Departure room
                                    $uncertainRoomObj,              # Arrival room
                                    $incompleteExitObj->dir,
                                    $incompleteExitObj->mapDir,
                                    $incompleteExitObj,
                                    $uncertainExitObj,              # The opposite exit
                                );
                            }
                        }
                    }
                }
            }

            # After merging the pairs of rooms, delete the one we don't need any more
            $self->deleteRooms(
                $session,
                FALSE,          # Don't update automapper windows yet
                @deleteList,
            );
        }

        if (%moveHash && ! $self->autoRescueNoMoveFlag) {

            # Move all rooms that haven't been merged (and for which there is space at the new
            #   location)
            $self->moveRoomsLabels(
                $session,
                FALSE,                                                  # Don't update windows now
                $twinRegionmapObj,                                      # Move from this region...
                $regionmapObj,                                          # ...to this one...
                $targetRoomObj->xPosBlocks - $twinRoomObj->xPosBlocks,  # ...using this vector
                $targetRoomObj->yPosBlocks - $twinRoomObj->yPosBlocks,
                $targetRoomObj->zPosBlocks - $twinRoomObj->zPosBlocks,
                \%moveHash,
                \%labelHash,
            );

            # Reconnect exits between surviving rooms in %mergeHash and the moved rooms in
            #   %moveHash
            foreach my $exitNum (keys %reconnectHash) {

                my ($exitObj, $destRoomObj);

                $exitObj = $self->ivShow('exitModelHash', $exitNum);
                $destRoomObj = $self->ivShow('modelHash',  $reconnectHash{$exitNum});

                $self->connectRooms(
                    $session,
                    FALSE,                                          # Don't update windows now
                    $self->ivShow('modelHash', $exitObj->parent),   # Departure room
                    $destRoomObj,                                   # Arrival room
                    $exitObj->dir,
                    $exitObj->mapDir,
                    $exitObj,
                );
            }
        }

        # Any rooms that are left behind - not merged and not moved - must be disconnected from any
        #   rooms that were moved (not merged)
        if (%disconnectHash) {

            foreach my $otherRoomObj (values %disconnectHash) {

                foreach my $exitNum ($otherRoomObj->ivValues('exitNumHash')) {

                    my $exitObj = $self->ivShow('exitModelHash', $exitNum);

                    if ($exitObj->destRoom && exists $moveHash{$exitObj->destRoom}) {

                        $self->disconnectExit(
                            FALSE,              # Don't update automapper windows yet
                            $exitObj,
                        );
                    }
                }
            }

            foreach my $moveRoomObj (values %moveHash) {

                foreach my $exitNum ($moveRoomObj->ivValues('exitNumHash')) {

                    my $exitObj = $self->ivShow('exitModelHash', $exitNum);

                    if ($exitObj->destRoom && exists $disconnectHash{$exitObj->destRoom}) {

                        $self->disconnectExit(
                            FALSE,              # Don't update automapper windows yet
                            $exitObj,
                        );
                    }
                }
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        foreach my $mapWin ($self->collectMapWins()) {

            # Mark the two affected regions to be redrawn. The TRUE argument means that only the
            #   specified region needs to be redrawn
            $mapWin->redrawRegions($regionmapObj, TRUE);
            if ($twinRegionmapObj ne $regionmapObj) {

                $mapWin->redrawRegions($twinRegionmapObj, TRUE);
            }

            # For visual clarity, select any rooms that were moved or merged
            foreach my $roomNum (values %mergeHash, keys %moveHash) {

                push (@selectList, $self->ivShow('modelHash', $roomNum), 'room');
            }

            $mapWin->setSelectedObj(
                \@selectList,
                TRUE,               # Select multiple objects
            );
        }

        return 1;
    }

    sub mergeRoom {

        # Called by $self->mergeMap (only; to merge a single pair of rooms, call ->mergeMap, not
        #   this function)
        # Merges IVs from a pair of rooms, $targetRoomObj (which will survive the operation) and
        #   $twinRoomObj (which will be destroyed)
        #
        # Expected arguments
        #   $twinRoomObj, $targetRoomObj
        #       - The GA::ModelObj::Room objects to merge
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $twinRoomObj, $targetRoomObj, $check) = @_;

        # Check for improper arguments
        if (! defined $twinRoomObj || ! defined $targetRoomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mergeRoom', @_);
        }

        # If the flag is set, only character visits are merged
        if (! $self->autoRescueVisitsFlag) {

            # Transfer the twin room's child objects to the target
            foreach my $childNum ($twinRoomObj->ivKeys('childHash')) {

                $self->setParent(
                    FALSE,              # Don't update automapper windows yet
                    $childNum,
                    $targetRoomObj->number,
                );
            }

            # (Don't transfer ->privateHash - we have no idea what sort of data it contains, nor of
            #   what conflicts that transferring it to a different room might cause)

            # Add any notes in the twin room to any existing notes in target room
            if ($twinRoomObj->notesList) {

                $targetRoomObj->ivPush('notesList', $twinRoomObj->notesList);
            }

            # If the twin has a room tag and the target room doesn't, apply the tag to the target
            #   room
            if (defined $twinRoomObj->roomTag && ! defined $targetRoomObj->roomTag) {

                $self->setRoomTag(
                    FALSE,              # Don't update automapper windows yet
                    $targetRoomObj,
                    $twinRoomObj->roomTag,
                );
            }

            # Same for room guilds
            if (defined $twinRoomObj->roomGuild && ! defined $targetRoomObj->roomGuild) {

                $self->setRoomGuild(
                    FALSE,              # Don't update automapper windows yet
                    $twinRoomObj->roomGuild,
                    $targetRoomObj,
                );
            }

            # Combine lists of room titles, but don't create duplicates
            foreach my $string ($twinRoomObj->titleList) {

                if (! $targetRoomObj->ivFind('titleList', $string)) {

                    $targetRoomObj->ivPush('titleList', $string);
                }
            }

            # Combine hashes of verbose descriptions, but don't replace any verbose description that
            #   already exists in $targetRoomObj
            foreach my $key ($twinRoomObj->ivKeys('descripHash')) {

                my $value = $twinRoomObj->ivShow('descripHash', $key);

                if (! $targetRoomObj->ivExists('descripHash', $key)) {

                    $targetRoomObj->ivAdd('descripHash', $key, $value);
                }
            }

            # Combine various pattern lists, but don't create duplicates
            foreach my $iv (
                qw(unspecifiedPatternList failExitPatternList specialDepartPatternList)
            ) {
                foreach my $string ($twinRoomObj->$iv) {

                    if (! $targetRoomObj->ivFind($iv, $string)) {

                        $targetRoomObj->ivPush($iv, $string);
                    }
                }
            }

            foreach my $key ($twinRoomObj->ivKeys('involuntaryExitPatternHash')) {

                my $value = $twinRoomObj->ivShow('involuntaryExitPatternHash', $key);

                $self->addInvoluntaryExit($targetRoomObj, $key, $value);
            }

            foreach my $key ($twinRoomObj->ivKeys('repulseExitPatternHash')) {

                my $value = $twinRoomObj->ivShow('repulseExitPatternHash', $key);

                $self->addRepulseExit($targetRoomObj, $key, $value);
            }
        }

        # Combine visits, adding the sum of visits in the target and twin rooms
        foreach my $key ($twinRoomObj->ivKeys('visitHash')) {

            my $value = $twinRoomObj->ivShow('visitHash', $key);

            if (! $targetRoomObj->ivExists('visitHash', $key)) {

                $targetRoomObj->ivAdd('visitHash', $key, $value);

            } else {

                $targetRoomObj->ivAdd(
                    'visitHash',
                    $key,
                    $targetRoomObj->ivShow('visitHash', $key) + $value,
                );
            }
        }

        # If the flag is set, only character visits are merged
        if (! $self->autoRescueVisitsFlag) {

            # Combine exclusivity IVs
            if ($twinRoomObj->exclusiveFlag) {

                $targetRoomObj->ivPoke('exclusiveFlag', TRUE);

                foreach my $key ($twinRoomObj->ivKeys('exclusiveHash')) {

                    $targetRoomObj->ivAdd('exclusiveHash', $key, undef);
                }
            }

            # Combine room flag hashes
            foreach my $key ($twinRoomObj->ivKeys('roomFlagHash')) {

                $targetRoomObj->ivAdd('roomFlagHash', $key, undef);
            }

            # If the twin has a source code/virtual area path and the target room doesn't, copy them
            #   across
            if (! $targetRoomObj->sourceCodePath && $twinRoomObj->sourceCodePath) {

                 $targetRoomObj->ivPoke('sourceCodePath', $twinRoomObj->sourceCodePath);
            }

            if (! $targetRoomObj->virtualAreaPath && $twinRoomObj->virtualAreaPath) {

                 $targetRoomObj->ivPoke('virtualAreaPath', $twinRoomObj->virtualAreaPath);
            }

            # (Don't modify MSDP and MXP data supplied to $targetRoomObj)

            # The keys in ->hiddenObjHash are a subset of the keys in ->childHash, so they must be
            #   transferred, too
            foreach my $key ($twinRoomObj->hiddenObjHash) {

                $targetRoomObj->ivAdd(
                    'hiddenObjHash',
                    $key,
                    $twinRoomObj->ivShow('hiddenObjHash', $key),
                );
            }

            # Transfer search results, but don't replace any existing search results
            foreach my $key ($twinRoomObj->searchHash) {

                if (! $targetRoomObj->ivExists('searchHash', $key)) {

                    $targetRoomObj->ivAdd(
                        'searchHash',
                        $key,
                        $twinRoomObj->ivShow('searchHash', $key),
                    );
                }
            }

            # Combine noun/adjective/script lists, but don't create duplicates
            foreach my $iv (qw(nounList adjList arriveScriptList)) {

                foreach my $string ($twinRoomObj->$iv) {

                    if (! $targetRoomObj->ivFind($iv, $string)) {

                        $targetRoomObj->ivPush($iv, $string);
                    }
                }
            }

            # Combine checked directions, adding the sum of failed attempts in the target and twin
            #   rooms
            foreach my $key ($twinRoomObj->ivKeys('checkedDirHash')) {

                my $value = $twinRoomObj->ivShow('checkedDirHash', $key);

                if (! $targetRoomObj->ivExists('checkedDirHash', $key)) {

                    $targetRoomObj->ivAdd('checkedDirHash', $key, $value);

                } else {

                    $targetRoomObj->ivAdd(
                        'checkedDirHash',
                        $key,
                        $targetRoomObj->ivShow('checkedDirHash', $key) + $value,
                    );
                }
            }
        }

        # Operation complete
        return 1;
    }

    # Modify model objects - all objects

    sub setParent {

        # Can be called by anything
        # Sets the parent model object of a child object. Should not be used to add rooms to a
        #   region (call $self->addRoom for that), or to add non-model objects to a room (call
        #   $self->addRoomChildren for that), or to add an exit (call->addExit for that)
        # Checks the rules for setting parents/children, and performs the operation
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $objNum         - The world model number of the object to modify
        #
        # Optional arguments
        #   $parentNum      - The world model number of the new parent. If set to 'undef', the
        #                       object should have no parent
        #
        # Return values
        #   'undef' on improper arguments, if either object does not exist or if the operation fails
        #   1 otherwise

        my ($self, $updateFlag, $objNum, $parentNum, $check) = @_;

        # Local variables
        my ($obj, $parentObj, $oldParentObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $objNum || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setParent', @_);
        }

        # Find the corresponding model objects
        $obj = $self->ivShow('modelHash', $objNum);
        if (! $obj) {

            return undef;
        }

        if ($parentNum) {

            $parentObj = $self->ivShow('modelHash', $parentNum);
            if (! $parentObj) {

                return undef;
            }
        }

        # Check the rules for setting parents (see the comments in $self->new)
        if (
            # General rules
            ($obj->category eq 'region' && $parentObj && $parentObj->category ne 'region')
            # Rules for this function only
            || $obj->category eq 'room'
            # Object cannot be its own parent
            || $parentObj && $obj eq $parentObj
        ) {
            return undef;
        }

        if (! $parentObj) {

            # Object should have no parent
            if (! $obj->parent) {

                # The object already has no parent; nothing to do
                return 1;
            }

            # Remove the object from the parent's child list
            $oldParentObj = $self->ivShow('modelHash', $obj->parent);
            if ($oldParentObj->ivExists('childHash', $objNum)) {

                $oldParentObj->ivDelete('childHash', $objNum);
            }

            # Set the object to have no parent
            $obj->ivUndef('parent');

        } else {

            # Remove the object's current parent, if there is one
            if ($obj->parent) {

                $oldParentObj = $self->ivShow('modelHash', $obj->parent);
                if ($oldParentObj->ivExists('childHash', $objNum)) {

                    $oldParentObj->ivDelete('childHash', $objNum);
                }
            }

            # Set the new parent
            $obj->ivPoke('parent', $parentNum);
            # Inform the parent it has acquired a child
            $parentObj->ivAdd('childHash', $objNum, undef);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                if ($obj->category eq 'room') {

                    # Redraw the room
                    $mapWin->markObjs('room', $obj);
                    $mapWin->doDraw();
                }
            }
        }

        return 1;
    }

    sub addChild {

        # Can be called by anything
        # Adds a child object to a parent model object. Should not be used to add rooms to a region
        #   (call $self->addRoom for that), or to add non-model objects to a room (call
        #   $self->addRoomChildren for that), or to add an exit (call->addExit for that)
        # Checks the rules for setting parents/children, and performs the operation
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $objNum         - The world model number of the object to modify
        #   $childNum       - The child object to add to the parent
        #
        # Return values
        #   'undef' on improper arguments, if either object does not exist or if the operation fails
        #   1 otherwise

        my ($self, $updateFlag, $objNum, $childNum, $check) = @_;

        # Local variables
        my ($obj, $childObj, $oldParentObj);

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $objNum || ! defined $childNum || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addChild', @_);
        }

        # Find the corresponding model objects
        $obj = $self->ivShow('modelHash', $objNum);
        if (! $obj) {

            return undef;
        }

        $childObj = $self->ivShow('modelHash', $childNum);
        if (! $childObj) {

            return undef;
        }

        # Check the rules for adding children (see the comments in $self->new)
        if (
            # General rules
            (
                $obj->category eq 'room'
                && ($childObj->category eq 'region' || $childObj->category eq 'room')
            )
            # Rules for this function
            || ($obj->category eq 'region' && $childObj->category eq 'room')
            # Object cannot be its own child
            || ($obj eq $childObj)
        ) {
            return undef;
        }

        # If the child object already has a parent, remove the parent
        if ($childObj->parent) {

            $oldParentObj = $self->ivShow('modelHash', $childObj->parent);
            if ($oldParentObj->ivExists('childHash', $childNum)) {

                $oldParentObj->ivDelete('childHash', $childNum);
            }
        }

        # Add the child object to the new parent
        $childObj->ivPoke('parent', $objNum);
        $obj->ivAdd('childHash', $childNum, undef);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                if ($obj->category eq 'room') {

                    # Redraw the room
                    $mapWin->markObjs('room', $obj);
                    $mapWin->doDraw();
                }
            }
        }

        return 1;
    }

    sub removeChild {

        # Can be called by anything
        # Removes a child object from a parent model object. Should not be used to remove rooms from
        #   a region (call $self->deleteRooms for that) or to remove exits (call $self->deleteExits
        #   for that)
        # Checks the rules for setting parents/children, and performs the operation
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $objNum         - The world model number of the object to modify
        #
        # Optional arguments
        #   $childNum       - The child object to remove from the parent. If 'undef', all children
        #                       are removed
        #
        # Return values
        #   'undef' on improper arguments or if child object can't be removed
        #   1 otherwise

        my ($self, $updateFlag, $objNum, $childNum, $check) = @_;

        # Local variables
        my (
            $obj, $childObj,
            @childList,
        );

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $objNum || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeChild', @_);
        }

        # Find the corresponding model objects
        $obj = $self->ivShow('modelHash', $objNum);
        if (! $obj) {

            return undef;
        }

        if ($childNum) {

            # Remove a single child
            $childObj = $self->ivShow('modelHash', $childNum);
            if (! $childObj) {

                return undef;

            } else {

                push (@childList, $childObj);
            }

        } else {

            # Remove all children
            foreach my $number ($obj->ivKeys('childHash')) {

                $childObj = $self->ivShow('modelHash', $number);

                if ($obj->category eq 'region' && $childObj->category eq 'room') {

                    # This function can't be used to remove rooms from a region
                    return undef;

                } else {

                    push (@childList, $childObj);
                }
            }
        }

        # Remove each child in turn
        foreach $childObj (@childList) {

            # Remove the child object from the parent
            $childObj->ivUndef('parent');
            $obj->ivDelete('childHash', $childNum);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # We only need to redraw rooms on the currently visible regionmap and level
            foreach my $mapWin ($self->collectMapWins()) {

                if ($obj->category eq 'room') {

                    # Redraw the room
                    $mapWin->markObjs('room', $obj);
                    $mapWin->doDraw();
                }
            }
        }

        return 1;
    }

    sub convertCategory {

        # Called by GA::Cmd::AddMinionString->do or by any other function
        # Converts the category of a model object (or a non-model object); actually, it creates a
        #   new model object (or non-model object) of the desired category, and preserves the values
        #   stored in IVs (as far as possible)
        # Regions, rooms and exits can't be converted to another category (and objects can't be
        #   converted to regions, rooms or exits)
        # Group 5 IVs are not converted; the new object will have default group 5 IVs
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $oldObj            - The existing model (or non-model) object
        #   $newCategory    - The category of the new object
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, the blessed reference of the replacement object

        my ($self, $session, $updateFlag, $oldObj, $newCategory, $check) = @_;

        # Local variables
        my (
            $modelFlag, $package, $newObj, $parentObj,
            %childHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $oldObj
            || ! defined $newCategory || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertCategory', @_);
        }

        # Check that this category of object can be converted
        if ($oldObj->category eq 'region' || $newCategory eq 'region') {

            return $session->writeError(
                'Cannot convert to/from world model region objects',
                $self->_objClass . '->convertCategory',
            );

        } elsif ($oldObj->category eq 'room' || $newCategory eq 'room') {

            return $session->writeError(
                'Cannot convert to/from world model room objects',
                $self->_objClass . '->convertCategory',
            );

        } elsif ($oldObj->category eq 'exit' || $newCategory eq 'exit') {

            return $session->writeError(
                'Cannot convert to/from exit model objects',
                $self->_objClass . '->convertCategory',
            );
        }

        # Check that $newCategory is valid
        if (
            $newCategory ne 'weapon' && $newCategory ne 'armour' && $newCategory ne 'garment'
            && $newCategory ne 'char' && $newCategory ne 'minion' && $newCategory ne 'sentient'
            && $newCategory ne 'creature' && $newCategory ne 'portable'
            && $newCategory ne 'decoration' && $newCategory ne 'custom'
        ) {
            return $session->writeError(
                'Unrecognised world object category \'' . $newCategory . '\'',
                $self->_objClass . '->convertCategory',
            );
        }

        # To keep the code simple, mark whether the existing object is already in the world model,
        #   or not
        if ($oldObj->number) {
            $modelFlag = TRUE;
        } else {
            $modelFlag = FALSE;
        }

        # Create the new model object
        $package = 'Games::Axmud::ModelObj::' . ucfirst($newCategory);
        $newObj = $package->new($session, $oldObj->name, $modelFlag, $oldObj->parent);
        if (! $newObj) {

            return undef;
        }

        # If the old object was in the model, remove it, and add the new object to the model (the
        #   new object will almost certainly have a different model number)
        if ($modelFlag) {

            # Store the old object's children (if any), so they can be re-assigned to the new object
            %childHash = $oldObj->childHash;

            # Add the new object to the model
            if (! $self->addToModel($newObj)) {

                # Object could not be added
                return undef;

            } else {

                # Delete the old one
                $self->deleteObj(
                    $session,
                    FALSE,      # Don't update Automapper windows yet
                    $oldObj,
                );
            }

            # Reassign any children to the new object
            foreach my $childNum (keys %childHash) {

                $self->setParent(
                    FALSE,
                    $childNum,
                    $newObj->number,
                );
            }
        }

        # For IVs that exist both in the original and new objects, transfer them

        # Group 1 IVs (only a few are object-specific)
        $newObj->ivPoke('privateHash', $oldObj->privateHash);
        $newObj->ivPoke('sourceCodePath', $oldObj->sourceCodePath);
        $newObj->ivPoke('notesList', $oldObj->notesList);

        # Group 2 IVs (exist in all objects convertable by this function)
        $newObj->ivPoke('noun', $oldObj->noun);
        $newObj->ivPoke('nounTag', $oldObj->nounTag);
        $newObj->ivPoke('otherNounList', $oldObj->otherNounList);
        $newObj->ivPoke('adjList', $oldObj->adjList);
        $newObj->ivPoke('pseudoAdjList', $oldObj->pseudoAdjList);
        $newObj->ivPoke('rootAdjList', $oldObj->rootAdjList);
        $newObj->ivPoke('unknownWordList', $oldObj->unknownWordList);
        $newObj->ivPoke('multiple', $oldObj->multiple);
        $newObj->ivPoke('baseString', $oldObj->baseString);
        $newObj->ivPoke('descrip', $oldObj->descrip);

        $newObj->ivPoke('container', $oldObj->container);
        $newObj->ivPoke('inventoryType', $oldObj->inventoryType);

        # Group 3 IVs
        if (
            (
                $oldObj->category eq 'char' || $oldObj->category eq 'minion'
                || $oldObj->category eq 'sentient' || $oldObj->category eq 'creature'
            ) && (
                $newCategory eq 'char' || $newCategory eq 'sentient' || $newCategory eq 'creature'
            )
        ) {
            $newObj->ivPoke('targetStatus', $oldObj->targetStatus);
            $newObj->ivPoke('targetType', $oldObj->targetType);
            $newObj->ivPoke('targetPath', $oldObj->targetPath);
            $newObj->ivPoke('explicitFlag', $oldObj->explicitFlag);
            $newObj->ivPoke('alreadyAttackedFlag', $oldObj->alreadyAttackedFlag);
        }

        # Group 4 IVs
        if (
            (
                $oldObj->category eq 'weapon' || $oldObj->category eq 'armour'
                || $oldObj->category eq 'garment' || $oldObj->category eq 'portable'
                || $oldObj->category eq 'decoration' || $oldObj->category eq 'custom'
            ) && (
                $newCategory eq 'weapon' || $newCategory eq 'armour' || $newCategory eq 'garment'
                || $newCategory eq 'portable' || $newCategory eq 'decoration'
                || $newCategory eq 'custom'
            )
        ) {
            $newObj->ivPoke('explicitFlag', $oldObj->explicitFlag);
            $newObj->ivPoke('weight', $oldObj->weight);
            $newObj->ivPoke('bonusHash', $oldObj->bonusHash);
            $newObj->ivPoke('condition', $oldObj->condition);
            $newObj->ivPoke('conditionChangeFlag', $oldObj->conditionChangeFlag);
            $newObj->ivPoke('fixableFlag', $oldObj->fixableFlag);
            $newObj->ivPoke('sellableFlag', $oldObj->sellableFlag);
            $newObj->ivPoke('buyValue', $oldObj->buyValue);
            $newObj->ivPoke('sellValue', $oldObj->sellValue);
            $newObj->ivPoke('exclusiveFlag', $oldObj->exclusiveFlag);
            $newObj->ivPoke('exclusiveHash', $oldObj->exclusiveHash);
        }

        # (Group 5 IVs are not converted)

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($newObj->parent) {

            $parentObj = $self->ivShow('modelHash', $newObj->parent);
        }

        if ($updateFlag && $parentObj && $parentObj->category eq 'room') {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the (parent) room
                $mapWin->markObjs('room', $parentObj);
                $mapWin->doDraw();
            }
        }

        # Operation complete
        return $newObj;
    }

    # Modify model objects - regions

    sub renameRegion {

        # Called by GA::Win::Map->renameRegionCallback
        # Renames an existing region
        #
        # Expected arguments
        #   $regionmapObj   - The GA::Obj::Regionmap corresponding to the region that must be
        #                       renamed
        #   $newName        - The new name for the region
        #
        # Return values
        #   'undef' on improper arguments or if a region named $newName already exists
        #   1 otherwise

        my ($self, $regionmapObj, $newName, $check) = @_;

        # Local variables
        my (
            $oldName, $regionObj,
            %redrawHash,
        );

        # Check for improper arguments
        if (! defined $regionmapObj || ! defined $newName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->renameRegion', @_);
        }

        # Check that a region with this name doesn't already exist
        if ($self->ivExists('regionmapHash', $newName)) {

            return undef;
        }

        # Give the regionmap object its new name (briefly storing the old one)
        $oldName = $regionmapObj->name;
        $regionmapObj->{_objName} = $newName;
        $regionmapObj->ivPoke('name', $newName);

        # Find the equivalent GA::ModelObj::Region, and give it the same new name
        $regionObj = $self->ivShow('modelHash', $regionmapObj->number);
        if ($regionObj) {

            $regionObj->{_objName} = $newName;
            $regionObj->ivPoke('name', $newName);
        }

        # Check all of this region's incoming region exits, updating their exit tags so that they
        #   display the new region (but if the tags have been modified by the user, leave them
        #   alone)
        foreach my $thisRegionmapObj ($self->ivValues('regionmapHash')) {

            # (Region exits can't lead to a destination room in their own region)
            if ($thisRegionmapObj ne $regionmapObj) {

                foreach my $exitNum ($thisRegionmapObj->ivKeys('regionExitHash')) {

                    my ($exitObj, $destRegionNum, $destRegionObj, $defaultText, $roomObj);

                    $destRegionNum = $thisRegionmapObj->ivShow('regionExitHash', $exitNum);

                    # If the region exit leads to our newly-renamed region...
                    if ($destRegionNum == $regionmapObj->number) {

                        $exitObj = $self->ivShow('exitModelHash', $exitNum);
                        $destRegionObj = $self->ivShow('modelHash', $destRegionNum);

                        # Get the default text that would have been given to the exit's tag, before
                        #   its parent region was renamed
                        $defaultText = $self->getExitTagText($exitObj, undef, $oldName);
                        if ($exitObj->exitTag && $exitObj->exitTag eq $defaultText) {

                            # The user has not modified the tag's default text, so modify it to show
                            #   the region's new name
                            $self->applyExitTag(
                                FALSE,              # Don't update Automapper windows yet
                                $exitObj,
                                $thisRegionmapObj,
                                undef,
                                TRUE,               # Override $self->updateExitTagFlag
                            );

                            # Mark the parent room to be redrawn (which redraws the exit). Use a
                            #   hash so that the same room isn't drawn twice
                            $roomObj = $self->ivShow('modelHash', $exitObj->parent);
                            $redrawHash{$roomObj->number} = $roomObj;
                        }
                    }
                }
            }
        }

        # Delete the old entry in the hash of regionmaps, and replace it with a new one
        $self->ivDelete('regionmapHash', $oldName);
        $self->ivAdd('regionmapHash', $newName, $regionmapObj);

        # All of this regionmap's labels must be updated
        foreach my $labelObj ($regionmapObj->ivValues('gridLabelHash')) {

            $labelObj->ivPoke('region', $regionmapObj->name);
        }

        # Update each Automapper window
        foreach my $mapWin ($self->collectMapWins()) {

            my (
                $parchmentObj,
                @redrawList,
            );

            # Update the parchment object for this region, if it exists
            $parchmentObj = $mapWin->ivShow('parchmentHash', $oldName);
            if ($parchmentObj) {

                $mapWin->del_parchment($oldName);
                $parchmentObj->ivPoke('name', $newName);
                $mapWin->add_parchment($parchmentObj);
            }

            # Redraw the list of regions in the treeview
            $mapWin->resetTreeView();

            # Reset the Automapper window's title bar
            $mapWin->setWinTitle();

            # If there are any region exits whose exit tags have been modified, redraw them
            if (%redrawHash) {

                foreach my $thisRoomObj (values %redrawHash) {

                    push (@redrawList, 'room', $thisRoomObj);
                }

                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }

            # The automapper windows' list of recent regions must be updated
            $mapWin->set_recentRegion($oldName, $newName);
        }

        return 1;
    }

    sub resetRegionCounts {

        # Called by GA::Win::Map->enableRegionsColumn
        # Resets the living/non-living objects counts for an existing region and redraws the region
        #
        # Expected arguments
        #   $regionmapObj   - The GA::Obj::Regionmap whose counts should be reset
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $regionmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $regionmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetRegionCounts', @_);
        }

        # Reset the regionmap's IVs
        $regionmapObj->resetCounts();

        # Update each Automapper window
        foreach my $mapWin ($self->collectMapWins()) {

            if ($mapWin->currentRegionmap eq $regionmapObj) {

                # Redraw (all) regions to remove the displayed counts
                $mapWin->redrawRegions();
            }
        }

        return 1;
    }

    sub emptyRegion {

        # Called by GA::Win::Map->emptyRegionCallback
        # Empties an existing region of all its child model objects. Also empties the corresponding
        #   regionmap
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $regionObj      - The region object to empty
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $updateFlag, $regionObj, $check) = @_;

        # Local variables
        my (
            $regionmapObj,
            @roomList, @otherList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag || ! defined $regionObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->emptyRegion', @_);
        }

        # So that we only have to call a function once, split the region's children into one list of
        #   rooms and another list of everything else. However, child regions should not be deleted
        foreach my $childNum ($regionObj->ivKeys('childHash')) {

            my $childObj = $self->ivShow('modelHash', $childNum);

            if ($childObj->category eq 'room') {
                push (@roomList, $childObj);
            } elsif ($childObj->category ne 'region') {
                push (@otherList, $childObj);
            }
        }

        # Delete all rooms (which deletes all the rooms' child objects and exits)
        $self->deleteRooms(
            $session,
            FALSE,          # Don't update Automapper windows yet
            @roomList,
        );

        # Delete everything else (all non-room objects which are children of the region itself)
        foreach my $otherObj (@otherList) {

            $self->deleteObj(
                $session,
                FALSE,
                $otherObj,  # Don't update Automapper windows yet
            );
        }

        # Get the corresponding regionmap and empty it
        $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);
        $regionmapObj->emptyGrid();

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap eq $regionmapObj
                ) {
                    # Redraw (all) regions. This region will be empty, and any connecting regions
                    #   will have their region exits drawn correctly
                    $mapWin->redrawRegions();
                }
            }
        }

        return 1
    }

    sub connectRegionBrokenExit {

        # Called by GA::Win::Map->connectExitToRoom (but is available to other code, if necessary)
        # After the user chooses the 'connect to click' menu item and clicks on a room, connects the
        #   selected exit to the clicked room, marking it as a broken or region exit if necessary
        # Also prompts the user to ask if they'd like to create an exit in the reverse direction
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $roomObj    - The clicked GA::ModelObj::Room object
        #   $exitObj    - The GA::Exit::Obj object to connect to the room
        #   $type       - What type of exit to create - set to 'broken' or 'region'. If set to
        #                   'broken', the function checks that it really is a broken exit
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $updateFlag, $roomObj, $exitObj, $type, $check) = @_;

        # Local variables
        my (
            $twinExitObj, $parentRoomObj, $parentRegionObj, $twinDir, $twinMapDir, $oppExitNum,
            $oppExitObj, $useExitObj, $choice, $forceOneWayFlag, $pairedTwinExit, $pairedTwinRoom,
            $pairedTwinRegion, $regionFlag, $specialBrokenFlag,
            @redrawList, @exitList, @comboList,
            %comboHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $roomObj || ! defined $exitObj
            || ! defined $type || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->connectRegionBrokenExit',
                @_,
            );
        }

        # This function uses 'dialogue' windows. While the 'dialogue' window is open, we don't want
        #   the GA::Session->spinMaintainLoop to call $self->updateRegionPaths, so we set this
        #   flag to TRUE. At the end of the function, we set it back to FALSE, so that
        #   ->updateRegionPaths can be called as normal
        $self->ivPoke('updateDelayFlag', TRUE);

        # Before doing anything, make sure the exit doesn't have a twin and/or shadow exit (both of
        #   which will be obsolete after the connection operation)
        if ($exitObj->twinExit) {

            # (The call to ->abandonTwinExit sets $self->updateBoundaryHash, ->updatePathHash)
            $self->abandonTwinExit(
                FALSE,      # Don't update Automapper windows yet
                $exitObj,
            );
        }

        if ($exitObj->shadowExit) {

            # (The call to ->abandonShadowExit sets $self->updateBoundaryHash, ->updatePathHash)
            $self->abandonShadowExit($exitObj);
        }

        # If the exit currently has a destination room, that room should be redrawn
        if ($exitObj->destRoom) {

            push (@redrawList, 'room', $self->ivShow('modelHash', $exitObj->destRoom));
        }

        # Connect the exit to the specified room
        $self->connectRooms(
            $session,
            FALSE,              # Don't update Automapper windows yet
            $self->ivShow('modelHash', $exitObj->parent),
            $roomObj,
            $exitObj->dir,
            $exitObj->mapDir,   # May be 'undef'
            $exitObj,
        );

        # The call to ->connectRooms may have allocated a twin; if so, get the blessed reference
        if ($exitObj->twinExit) {

            $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
        }

        # While we're at it, get the exit's parent room
        $parentRoomObj = $self->ivShow('modelHash', $exitObj->parent);
        $parentRegionObj = $self->ivShow('modelHash', $parentRoomObj->parent);

        # Mark the exit as a broken or a region exit
        if ($type eq 'broken') {

            # The rooms might - by coincidence - be aligned, so that we don't have to mark it as a
            #   broken exit. Mark it as broken for now, and check towards the end of the function
            $exitObj->ivPoke('brokenFlag', TRUE);
            $self->checkBentExit($exitObj, $parentRoomObj);

            $exitObj->ivPoke('regionFlag', FALSE);
            $self->cancelExitTag(
                FALSE,                  # Don't update Automapper windows yet
                $exitObj,
                $self->ivShow('regionmapHash', $parentRegionObj->name),
            );

            if ($twinExitObj) {

                $twinExitObj->ivPoke('brokenFlag', TRUE);
                $self->checkBentExit($twinExitObj);

                $twinExitObj->ivPoke('regionFlag', FALSE);
                $self->cancelExitTag(
                    FALSE,              # Don't update Automapper windows yet
                    $twinExitObj,
                );
            }

        } else {

            # Likewise, mark the exit (and its twin, if there is one) as a region exit for now
            $exitObj->ivPoke('regionFlag', TRUE);
            $self->applyExitTag(
                FALSE,                  # Don't update Automapper windows yet
                $exitObj,
                $self->ivShow('regionmapHash', $parentRegionObj->name),
            );

            $exitObj->ivPoke('brokenFlag', FALSE);
            $exitObj->ivPoke('bentFlag', FALSE);
            $exitObj->ivEmpty('bendOffsetList');

            if ($twinExitObj) {

                $twinExitObj->ivPoke('regionFlag', TRUE);
                $self->applyExitTag(
                    FALSE,              # Don't update Automapper windows yet
                    $twinExitObj,
                    undef,              # Called function finds the parent regionmap
                    undef,              # No custom text
                    # Force ->applyExitTag to replace the existing text, in case a 1-way exit has
                    #   just become a 2-way exit (etc)
                    TRUE,
                );

                $twinExitObj->ivPoke('brokenFlag', FALSE);
                $twinExitObj->ivPoke('bentFlag', FALSE);
                $twinExitObj->ivEmpty('bendOffsetList');
            }
        }

        # See if the exit's nominal direction can be converted into an opposite direction. Use mode
        #   0 (do not abbreviate / if there is more than one opposite direction, use the first one)
        ($twinDir) = $self->reversePath(
            $session,
            'no_abbrev',
            $exitObj->dir,
        );

        # Also get the opposite of the exit's map direction (a primary direction), but not for
        #   unallocated exits
        if (
            $exitObj->mapDir
            && ($exitObj->drawMode eq 'primary' || $exitObj->drawMode eq 'perm_alloc')
        ) {
            $twinMapDir = $axmud::CLIENT->ivShow('constOppDirHash', $exitObj->mapDir);
        }

        # If the exit isn't already a twin (the call to ->connectRooms earlier in this function
        #   might have allocated a twin) and if the destination room has an exit which might be a
        #   twin exit, ask the user whether they should be paired
        if (
            ! $twinExitObj
            && (
                ($twinDir && $twinDir ne $exitObj->dir)
                || $twinMapDir
            )
        ) {
            # Does the clicked room already have an exit in the opposite direction, that is probably
            #   the specified exit's twin exit? If so, is it an 'incomplete' exit that's ready to be
            #   connected to something?
            if ($twinDir && $roomObj->ivExists('exitNumHash', $twinDir)) {

                $oppExitNum = $roomObj->ivShow('exitNumHash', $twinDir);
                $oppExitObj = $self->ivShow('exitModelHash', $oppExitNum);

            } elsif ($twinMapDir) {

                # Check map directions
                @exitList = $roomObj->ivValues('exitNumHash');
                OUTER: foreach my $exitNum (@exitList) {

                    my ($thisExitObj, $dir, $string);

                    $thisExitObj = $self->ivShow('exitModelHash', $exitNum);
                    if ($thisExitObj->mapDir && $thisExitObj->mapDir eq $twinMapDir) {

                        $oppExitNum = $exitNum;
                        $oppExitObj = $thisExitObj;
                        last OUTER;
                    }
                }
            }

            if ($oppExitObj) {

                if (
                    $oppExitObj->exitOrnament eq 'impass'
                    || $oppExitObj->exitOrnament eq 'mystery'
                    || $oppExitObj->randomType ne 'none'
                ) {
                    # The opposite exit is impassable, so it can't be made a twin (or it is a random
                    #   exit, and it should remain a random exit)
                    # Therefore, $exitObj must be made one-way
                    $forceOneWayFlag = TRUE;
                }

                if (
                    $session->mapWin
                    && ! $oppExitObj->destRoom
                    && $oppExitObj->randomType eq 'none'
                    && ! $forceOneWayFlag
                ) {
                    # Prompt the user to modify it (but only if the calling session actually has an
                    #   automapper window open)
                    $choice = $session->mapWin->showMsgDialogue(
                        'Set up twin exit',
                        'question',
                        'Would you like to modify the clicked room\'s existing \'' . $exitObj->dir
                        . '\' exit to lead back to the original room?',
                        'yes-no',
                        'yes',
                    );

                    if ($choice eq 'yes') {

                        # Mark this exit to be used as a twin exit (rest of the code is below)
                        $useExitObj = $oppExitObj;
                    }
                }

            # Does the clicked room have any exits at all?
            } elsif ($roomObj->exitNumHash) {

                @exitList = $roomObj->ivValues('exitNumHash');
                foreach my $exitNum (@exitList) {

                    my ($thisExitObj, $dir, $string);

                    $thisExitObj = $self->ivShow('exitModelHash', $exitNum);

                    # Only add incomplete exits that don't have shadow exits
                    if (
                        ! $thisExitObj->destRoom
                        && $thisExitObj->randomType eq 'none'
                        && ! $thisExitObj->shadowExit
                    ) {
                        $dir = $thisExitObj->dir;
                        $string = $dir . ' #' . $roomObj->ivShow('exitNumHash', $dir);
                        push (@comboList, $string);
                        $comboHash{$string} = $roomObj->ivShow('exitNumHash', $dir);
                    }
                }

                if ($session->mapWin && @comboList) {

                    # Prompt the user for an exit
                    $choice = $session->mapWin->showComboDialogue(
                        'Set up twin exit',
                        'Choose one of the clicked room\'s existing exits to lead back to the'
                        . ' original room (or click the \'Cancel\' button to mark this exit as'
                        . ' one-way)',
                        \@comboList,
                    );

                    if ($choice) {

                        # Modify the existing exit (rest of the code is below)
                        $useExitObj = $self->ivShow('exitModelHash', $comboHash{$choice});

                    } else {

                        # We need to mark the exit as one-way shortly
                        $forceOneWayFlag = TRUE;
                    }
                }
            }
        }

        if ($useExitObj) {

            # (A two-way exit)
            $twinExitObj = $useExitObj;
            $regionFlag = $twinExitObj->regionFlag;

            # Set the twin exit's IVs
            $twinExitObj->ivPoke('destRoom', $exitObj->parent);
            $twinExitObj->ivPoke('twinExit', $exitObj->number);
            # Make it the selected exit's twin
            $exitObj->ivPoke('twinExit', $twinExitObj->number);
            # Make sure neither room has either of these exits still marked as uncertain
            if ($roomObj->ivExists('uncertainExitHash', $exitObj->number)) {

                $roomObj->ivDelete('uncertainExitHash', $exitObj->number);
            }

            if ($parentRoomObj->ivExists('uncertainExitHash', $twinExitObj->number)) {

                $parentRoomObj->ivDelete('uncertainExitHash', $twinExitObj->number);
            }

            # The call to ->connectRooms may have marked one of the rooms as one-way; if so, the
            #   exit now loses its one-way status
            $exitObj->ivPoke('oneWayFlag', FALSE);
            $exitObj->ivPoke('oneWayDir', undef);
            $twinExitObj->ivPoke('oneWayFlag', FALSE);
            $twinExitObj->ivPoke('oneWayDir', undef);

            # Deal with broken/region exits
            if ($type eq 'broken') {

                $twinExitObj->ivPoke('brokenFlag', TRUE);

                # Special case: if an exit whose ->mapDir is up or down is twinned with an exit
                #   whose ->mapDir is not up or down, then these are definitely unbendable broken
                #   exits (trying to draw them as normal exits or bent broken exits causes all sorts
                #   of problems)
                if (
                    $exitObj->mapDir
                    && $twinExitObj->mapDir
                    && (
                        (
                            ($exitObj->mapDir eq 'up' || $exitObj->mapDir eq 'down')
                            && $twinExitObj->mapDir ne 'up'
                            && $twinExitObj->mapDir ne 'down'
                        ) || (
                            ($twinExitObj->mapDir eq 'up' || $twinExitObj->mapDir eq 'down')
                            && $exitObj->mapDir ne 'up'
                            && $exitObj->mapDir ne 'down'
                        )
                    )
                ) {
                    $specialBrokenFlag = TRUE;
                    $exitObj->ivPoke('bentFlag', FALSE);
                    $exitObj->ivEmpty('bendOffsetList');
                    $twinExitObj->ivPoke('bentFlag', FALSE);
                    $twinExitObj->ivEmpty('bendOffsetList');

                } else {

                    $self->checkBentExit($twinExitObj);
                }

                $twinExitObj->ivPoke('regionFlag', FALSE);
                $self->cancelExitTag(
                    FALSE,              # Don't update Automapper windows yet
                    $twinExitObj,
                );

            } else {

                $twinExitObj->ivPoke('brokenFlag', FALSE);
                $twinExitObj->ivPoke('bentFlag', FALSE);
                $twinExitObj->ivEmpty('bendOffsetList');

                $twinExitObj->ivPoke('regionFlag', TRUE);
                $self->applyExitTag(
                    FALSE,              # Don't update Automapper windows yet
                    $twinExitObj,
                    undef,              # Called function finds the parent regionmap
                    undef,              # No custom text
                    # Force ->applyExitTag to replace the existing text, in case a 1-way exit has
                    #   just become a 2-way exit (etc)
                    TRUE,
                );
            }

            # Mark the twin exit (and its parent room) to be drawn a different colour (ignored for
            #   bent broken exits)
            $pairedTwinExit = $twinExitObj;
            $pairedTwinRoom = $self->ivShow('modelHash', $twinExitObj->parent);
            $pairedTwinRegion = $self->ivShow('modelHash', $pairedTwinRoom->parent);

            # Any region paths using the exits will have to be updated
            $self->ivAdd('updatePathHash', $exitObj->number, $parentRegionObj->name);
            if ($regionFlag || $exitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $exitObj->number, $parentRegionObj->name);
            }

            $self->ivAdd('updatePathHash', $twinExitObj->number, $pairedTwinRegion->name);
            if ($regionFlag || $twinExitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $twinExitObj->number, $pairedTwinRegion->name);
            }

        } else {

            # (A one-way or uncertain exit)
            if ($forceOneWayFlag) {

                # The user declined to connect this exit to an available opposite exit. This exit
                #   would ordinarily be marked as 'uncertain', but now it should be marked as
                #   one-way
                $exitObj->ivPoke('oneWayFlag', TRUE);
                # The default incoming direction (where the exit touches its destination room) is
                #   the opposite of ->mapDir
                # NB If the exit is unallocatable, ->mapDir won't be set, so we'll use 'north' as
                #   an emergency default value for ->mapDir
                if ($exitObj->mapDir) {

                    $exitObj->ivPoke(
                        'oneWayDir',
                        $axmud::CLIENT->ivShow('constOppDirHash', $exitObj->mapDir),
                    );

                } else {

                    # Emergency default
                    $exitObj->ivPoke('oneWayDir', 'north');
                }

                if ($roomObj->ivExists('uncertainExitHash', $exitObj->number)) {

                    $roomObj->ivDelete('uncertainExitHash', $exitObj->number);
                }

                $roomObj->ivAdd('oneWayExitHash', $exitObj->number, undef);
            }

            # Any region paths using the exit will have to be updated
            $self->ivAdd('updatePathHash', $exitObj->number, $parentRegionObj->name);
            if ($regionFlag || $exitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $exitObj->number, $parentRegionObj->name);
            }
        }

        # If the exit has been marked as a broken exit, check whether the exit is in fact aligned
        #   with its destination room and, if so, remove its broken exit status
        if (
            $type eq 'broken'
            && ! $specialBrokenFlag
            && $self->checkRoomAlignment($session, $exitObj)
        ) {
            $self->unsetBrokenExit(
                FALSE,          # Don't update Automapper windows
                $exitObj,
                undef,          # $exitObj's parent region not immediately available
            );

            if ($twinExitObj) {

                $self->unsetBrokenExit(
                    FALSE,      # Don't update Automapper windows
                    $twinExitObj,
                    undef,
                );
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            push (@redrawList,
                'room', $roomObj,
                'room', $parentRoomObj,
            );

            # Only draw a paired twin room (and its exit) a special colour, if the exit is a normal
            #   (unbent) broken exit or a region exit - the special colour is only for exits not
            #   drawn with a line
            if (
                $pairedTwinRoom
                && (
                    (! $pairedTwinExit->brokenFlag && ! $pairedTwinExit->regionFlag)
                    || ($pairedTwinExit->brokenFlag && $pairedTwinExit->bentFlag)
                )
            ) {
                $pairedTwinRoom = undef;
            }

            # If the paired twin room is still to be drawn a different colour, mark it to be
            #   redrawn
            if ($pairedTwinRoom) {

                push (@redrawList, 'room', $pairedTwinRoom);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Mark the paired room/exit (if set) to be drawn a different colour
                if ($pairedTwinRoom) {

                    $mapWin->set_pairedTwinRoom($pairedTwinRoom);
                    $mapWin->set_pairedTwinExit($pairedTwinExit);
                }

                # Redraw affected rooms immediately
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        # Allow $self->updateRegionPaths to be called again
        $self->ivPoke('updateDelayFlag', FALSE);

        return 1;
    }

    # Modify model objects - rooms

    sub updateRegion {

        # Can be called by anything to force any Automapper windows to redraw regions (though at the
        #   moment, only code in 'edit' windows calls this function)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $region     - The name of a regionmap. If specified, only this region is redrawn in
        #                   every Automapper window (but if it's not already drawn, even partially,
        #                   it's not redrawn). If not specified, all drawn regions in each
        #                   Automapper window are redrawn
        #
        # Return values
        #   'undef' on improper arguments or if the specified region doesn't exist
        #   1 otherwise

        my ($self, $region, $check) = @_;

        # Local variables
        my $regionmapObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRegion', @_);
        }

        if ($region) {

            # Find the equivalent regionmap
            $regionmapObj = $self->ivShow('regionmapHash', $region);
            if (! $regionmapObj) {

                # Nothing more we can do
                return undef;
            }
        }

        # Update each Automapper window in turn
        foreach my $mapWin ($self->collectMapWins()) {

            if (! $regionmapObj) {

                # Redraw all drawn regions
                $mapWin->redrawRegions();

            } elsif ($mapWin->ivExists('parchmentHash', $regionmapObj->name)) {

                # Redraw the specified region (if it's drawn in this automapper window). The TRUE
                #   argument means 'don't redraw other regions'
                $mapWin->redrawRegions($regionmapObj, TRUE);
            }
        }

        return 1;
    }

    sub updateMaps {

        # Can be called by anything in the automapper object (GA::Obj::Map) and the Automapper
        #   window (GA::Win::Map) to update every Automapper window using this world model
        # Usually called after other calls to this world model object, in which the $updateFlag
        #   argument was set to FALSE - the calling function is now ready for the Automapper windows
        #   to be updated
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @list       - A list to send to each Automapper window's ->markObjs, in the form
        #                   (type, object, type, object...)
        #               - If it's an empty list, nothing is marked to be drawn; GA::Win::Map->doDraw
        #                   is still called in each automapper window, in the expectation that
        #                   something has already been marked to be drawn
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, @list) = @_;

        # (No improper arguments to check)

        foreach my $mapWin ($self->collectMapWins()) {

            if (@list) {

                $mapWin->markObjs(@list);
            }

            $mapWin->doDraw();
        }

        return 1;
    }

    sub updateMapMenuToolbars {

        # Can be called by anything in the automapper object (GA::Obj::Map) and the Automapper
        #   window (GA::Win::Map) to update every Automapper window using this world model
        # Also called by the painter's edit window, when ->saveChanges is applied
        # Redraws the menu bars and/or toolbars in all automapper windows using this world model
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateMapMenuToolbars', @_);
        }

        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->redrawWidgets('menu_bar', 'toolbar');
        }

        return 1;
    }

    sub updateMapExit {

        # Called by several of this object's functions to update a single exit (and its twin) in
        #   every Automapper window using this world model
        #
        # Expected arguments
        #   $exitObj        - The exit object to update
        #
        # Optional arguments
        #   $twinExitObj    - The exit's twin object, if known (if 'undef', this function looks up
        #                       for twin exit object)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $twinExitObj, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateMapExit', @_);
        }

        # If the exit has a twin, that must be redrawn, too
        @list = ('exit', $exitObj);

        if (! $twinExitObj && $exitObj->twinExit) {

            $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
        }

        if ($twinExitObj) {

            push (@list, 'exit', $twinExitObj);
        }

        foreach my $mapWin ($self->collectMapWins()) {

            # Redraw the objects
            $mapWin->markObjs(@list);
            $mapWin->doDraw();
        }

        return 1;
    }

    sub updateMapLabels {

        # Called by GA::EditWin::MapLabelStyle->saveChanges and $self->deleteLabelStyle to redraw
        #   all labels in every Automapper using this world model (assuming that the map label style
        #   has been modified)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateMapLabels', @_);
        }

        foreach my $mapWin ($self->collectMapWins()) {

            if ($mapWin->currentRegionmap) {

                foreach my $labelObj ($mapWin->currentRegionmap->ivValues('gridLabelHash')) {

                    push (@list, 'label', $labelObj);
                }

                # Redraw the objects
                $mapWin->markObjs(@list);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub connectRooms {

        # Called by GA::Obj::Map->autoProcessNewRoom, ->useExistingRoom,
        #   GA::Obj::Map->createNewRoom, $self->connectRegions or any other function
        # Given two room objects in the world model, and the command we use to move from one to the
        #   other, connect the rooms by modifying their exit object's IVs
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $departRoomObj  - The GA::ModelObj::Room from which the character left
        #   $arriveRoomObj  - The GA::ModelObj::Room to which the character arrived
        #   $dir            - The command used to move (e.g. 'north', 'cross bridge')
        #
        # Optional arguments
        #   $mapDir         - How the exit is drawn on the map - matches a standard primary
        #                       direction (e.g. 'north', 'south', 'up'). If not specified, the exit
        #                       can't be drawn on the map
        #   $exitObj        - An existing GA::Obj::Exit to use, if known; the parent room is
        #                       $departRoomObj. If no exit is specified, the destination room's
        #                       ->exitNumHash is consulted to provide it
        #   $oppExitObj     - An existing GA::Obj::Exit belonging to $arriveRoomObj. If set, those
        #                       two exits are linked; otherwise, the user is prompted for an
        #                       opposite exit, if there isn't already an obvious candidate. Ignored
        #                       if $exitObj is not also set
        #   $forceFlag      - If TRUE, the value of $self->autocompleteExitsFlag is ignored, and
        #                       this function behaves as if that IV was set to TRUE
        #
        # Return values
        #   'undef' on improper arguments or if the rooms can't be connected
        #   1 otherwise

        my (
            $self, $session, $updateFlag, $departRoomObj, $arriveRoomObj, $dir, $mapDir, $exitObj,
            $oppExitObj, $forceFlag,
            $check,
        ) = @_;

        # Local variables
        my (
            $number, $departExitObj, $standardDir, $departRegionFlag, $arriveExitObj,
            $arriveRegionFlag, $departRegionObj, $arriveRegionObj, $twinExitObj,
            @redrawList,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $departRoomObj
            || ! defined $arriveRoomObj || ! defined $dir || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->connectRooms', @_);
        }

        # Connect the exit from the departure to the arrival room

        # If $exitObj and/or $oppExitObj were specified, check that they belong to the specified
        #   parent rooms
        if (
            ($exitObj && $exitObj->parent ne $departRoomObj->number)
            || ($oppExitObj && $oppExitObj->parent ne $arriveRoomObj->number)
        ) {
            return undef;
        }

        # Get the departure room's exit object (unless already specified)
        if (! $exitObj) {

            $number = $departRoomObj->ivShow('exitNumHash', $dir);
            if (defined $number) {

                $departExitObj = $self->ivShow('exitModelHash', $number);
            }

        } else {

            $departExitObj = $exitObj;
        }

        if (! $departExitObj) {

            # The departure exit isn't known (probably because the room from which the character is
            #   leaving hasn't yet been updated with a call to GA::Obj::Map->updateRoom and,
            #   therefore, doesn't have any exits at all)
            # This can also happen when the character leaves the room via a hidden exit that the
            #   Locator task doesn't know about, or when the departure room is dark and its exits
            #   aren't known

            # We can't connect the rooms properly until the Locator task has seen the departure
            #   room's statement, and knows which exits it has. As a compromise, create an
            #   incomplete exit - that has no destination room - in the direction just moved; it's
            #   up to the user to connect it to a room. (The exit will be connected to its arrival
            #   room, in the normal way, once the Locator has seen the departure room's statement)
            # If we're not allowed to add exits - or if it's a retracing exit - then do nothing
            if ($self->updateExitFlag && $departRoomObj ne $arriveRoomObj) {

                # If it's not a primary direction, then the new exit is drawn as 'unallocated' (and
                #   this function call returns 'undef')
                $standardDir = $session->currentDict->convertStandardDir($dir);

                # Add a new incomplete exit, using what information we have
                $exitObj = $self->addExit(
                    $session,
                    TRUE,           # Update Automapper windows now
                    $departRoomObj,
                    $dir,
                    $standardDir,   # May be 'undef'
                );

                # If the room isn't dark, make it a hidden exit (but don't bother, if
                #   unallocated)
                if ($exitObj && $standardDir) {

                    $self->setHiddenExit(
                        FALSE,      # Don't update Automapper windows now
                        $exitObj,
                        TRUE,       # Exit is hidden
                    );
                }
            }

            # There's nothing more we can do
            return undef;

        } else {

            $departRegionFlag = $departExitObj->regionFlag;
        }

        # Set the IVs for $departExitObj, which connects the departure and arrival rooms
        #   ($departExitObj->dir is already set to $dir)
        if ($mapDir) {

            # Don't overwrite an allocated ->mapDir with 'undef'
            $departExitObj->ivPoke('mapDir', $mapDir);
        }

        $departExitObj->ivPoke('destRoom', $arriveRoomObj->number);

        # If the departure and arrival rooms are the same, it's a retracing exit
        if ($departRoomObj eq $arriveRoomObj) {

            # The parent room of the twin exit, if any, must be added to the redraw list now
            if ($departExitObj->twinExit) {

                $twinExitObj = $self->ivShow('exitModelHash', $departExitObj->twinExit);
                if ($twinExitObj && $twinExitObj->parent) {

                    push (@redrawList, 'room', $self->ivShow('modelHash', $twinExitObj->parent));
                }
            }

            # Now we can convert the exit (and its twin, if any)
            $self->setRetracingExit(
                FALSE,          # Don't update Automapper windows now
                $departExitObj,
            );

        # If we're not using an existing exit object which already has an opposite exit
        #   (stored in ->twinExit)...
        } elsif (! $departExitObj->twinExit) {

            # Check whether an exit in the opposite primary direction exists (unless one was
            #   specified by the calling function, in which case, use that)
            # (NB $oppExitObj, if specified, must be ignored unles $exitObj was also specified)
            if ($exitObj && $oppExitObj) {
                $arriveExitObj = $oppExitObj;
            } else {
                $arriveExitObj = $self->checkOppPrimary($departExitObj);
            }

            # Obviously, we don't use an unallocated exit
            if (
                $arriveExitObj
                && (
                    $arriveExitObj->drawMode eq 'primary'
                    || $arriveExitObj->drawMode eq 'perm_alloc'
                )
            ) {
                # An opposite exit exists
                $arriveRegionFlag = $arriveExitObj->regionFlag;
                if (
                    (
                        ($self->autocompleteExitsFlag || $forceFlag)
                        # (Don't connect $departExitObj to an opposite unallocated exit)
                        && $arriveExitObj->drawMode ne 'temp_alloc'
                        && $arriveExitObj->drawMode ne 'temp_unalloc'
                        && (
                            (! $arriveExitObj->destRoom && $arriveExitObj->randomType eq 'none')
                            || (
                                $arriveExitObj->destRoom
                                && $arriveExitObj->destRoom == $departRoomObj->number
                            )
                        )
                    ) || (
                        $arriveExitObj->destRoom
                        && $arriveExitObj->destRoom == $departRoomObj->number
                    )
                ) {
                    # Either this is a genuine two-way exit, or the flag insists that we treat it as
                    #   a two-way exit (although it might be an uncertain or a two-way exit)
                    # Link the two exit objects together.
                    $departExitObj->ivPoke('twinExit', $arriveExitObj->number);
                    $arriveExitObj->ivPoke('twinExit', $departExitObj->number);

                    # When ->autocompleteExitsFlag is set, the arrival room's exit won't have its
                    #   destination room set. Set it now
                    if ($self->autocompleteExitsFlag || $forceFlag) {

                        $arriveExitObj->ivPoke('destRoom', $departRoomObj->number);
                    }

                    # If either exit is marked as a broken exit, so must the other be so marked
                    # (This can happen when we have three rooms in a row, A-B-C, and are travelling
                    #   two gridblocks at a time from A to C. C's exit towards A will already be
                    #   marked as 'broken', so A's exit towards C must also be broken)
                    if ($arriveExitObj->brokenFlag) {

                        $self->setBrokenExit(
                            FALSE,       # Don't update Automapper windows now
                            $departExitObj,
                            $departRoomObj->parent,
                        );
                    }

                    if ($departExitObj->brokenFlag) {

                        $self->setBrokenExit(
                            FALSE,       # Don't update Automapper windows now
                            $arriveExitObj,
                            $arriveRoomObj->parent,
                        );
                    }

                    # If either room used to have an uncertain exit pointing at the other, tell the
                    #   other room that it no longer needs to keep track
                    $arriveRoomObj->ivDelete('uncertainExitHash', $departExitObj->number);
                    $departRoomObj->ivDelete('uncertainExitHash', $arriveExitObj->number);

                    # Likewise update the rooms for 1-way exits
                    $arriveRoomObj->ivDelete('oneWayExitHash', $departExitObj->number);
                    $departRoomObj->ivDelete('oneWayExitHash', $arriveExitObj->number);

                    # Each exit should lose its 1-way flag, if it has one
                    $arriveExitObj->ivPoke('oneWayFlag', FALSE);
                    $arriveExitObj->ivPoke('oneWayDir', undef);
                    $departExitObj->ivPoke('oneWayFlag', FALSE);
                    $departExitObj->ivPoke('oneWayDir', undef);

                } elsif (
                    (
                        $arriveExitObj->destRoom
                        && $arriveExitObj->destRoom != $departRoomObj->number
                    )
                    || $arriveExitObj->randomType ne 'none'
                ) {
                    # The opposite exit is already connected to some other room (or it's a random
                    #   exit), so this is a one-way exit
                    $departExitObj->ivPoke('oneWayFlag', TRUE);
                    # NB If the exit is unallocatable, ->mapDir won't be set, so we'll use 'north'
                    #   as an emergency default value for ->mapDir
                    if ($departExitObj->mapDir) {

                        $departExitObj->ivPoke(
                            'oneWayDir',
                            $axmud::CLIENT->ivShow('constOppDirHash', $departExitObj->mapDir),
                        );

                    } else {

                        # Emergency default
                        $departExitObj->ivPoke('oneWayDir', 'north');
                    }

                    $arriveRoomObj->ivAdd('oneWayExitHash', $departExitObj->number, undef);

                    # If $departExitObj used to be an uncertain exit, tell the arrival room that it
                    #   no longer needs to keep track of it
                    $arriveRoomObj->ivDelete('uncertainExitHash', $departExitObj->number);

                } else {

                    # This is an uncertain exit. Update the arrival room
                    $arriveRoomObj->ivAdd(
                        'uncertainExitHash',
                        $departExitObj->number,
                        $arriveExitObj->number,
                    );
                }

            } else {

                # This is a one-way exit
                $departExitObj->ivPoke('oneWayFlag', TRUE);
                # NB If the exit is unallocatable, ->mapDir won't be set, so we'll use 'north' as
                #   an emergency default value for ->mapDir
                if ($departExitObj->mapDir) {

                    $departExitObj->ivPoke(
                        'oneWayDir',
                        $axmud::CLIENT->ivShow('constOppDirHash', $departExitObj->mapDir),
                    );

                } else {

                    # Emergency default
                    $departExitObj->ivPoke('oneWayDir', 'north');
                }

                $arriveRoomObj->ivAdd('oneWayExitHash', $departExitObj->number, undef);

                # If $departExitObj used to be an uncertain exit, tell the arrival room that it no
                #   longer needs to keep track of it
                $arriveRoomObj->ivDelete('uncertainExitHash', $departExitObj->number);

                # If $arriveExitObj, an exit was found in the opposite direction to $departExitObj,
                #   but it's unallocated. Reallocate its temporary map direction so that
                #   $departExitObj isn't drawn over the top of $arriveExitObj
                # NB $arriveExitObj->drawMode could also be 'temp_unalloc', in which case it's not
                #   drawn in a way that could be underneath $departExitObj
                if ($arriveExitObj && $arriveExitObj->drawMode eq 'temp_alloc') {

                    $self->allocateCardinalDir($session, $arriveRoomObj, $arriveExitObj);
                }
            }
        }

        # Any region paths using the exits will have to be updated
        $departRegionObj = $self->ivShow('modelHash', $departRoomObj->parent);
        $self->ivAdd('updatePathHash', $departExitObj->number, $departRegionObj->name);
        if ($departRegionFlag || $departExitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $departExitObj->number, $departRegionObj->name);
        }

        if ($arriveExitObj) {

            $arriveRegionObj = $self->ivShow('modelHash', $arriveRoomObj->parent);
            $self->ivAdd('updatePathHash', $arriveExitObj->number, $arriveRegionObj->name);
            if ($arriveRegionFlag || $arriveExitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $arriveExitObj->number, $arriveRegionObj->name);
            }
        }

        # When an exit is connected to a room, it loses its impassable status (if set). Don't
        #   specify the flag for the twin exit, because if the twin exit has a different kind of
        #   exit ornament, we don't want to lose it
        if ($departExitObj->exitOrnament eq 'impass' || $departExitObj->exitOrnament eq 'mystery') {

            $self->setExitOrnament(
                FALSE,              # Don't update Automapper windows yet
                $departExitObj,
            );
        }

        # The twin exit object (if any) also loses its impassable status
        if (
            $arriveExitObj
            && (
                $arriveExitObj->exitOrnament eq 'impass'
                || $arriveExitObj->exitOrnament eq 'mystery'
            )
        ) {
            $self->setExitOrnament(
                FALSE,              # Don't update Automapper windows yet
                $arriveExitObj,
            );
        }

        # When a retracing exit is connected to a room, it loses its retracing status (unless it is
        #   being connected to its own parent room - in which case it is, by profile, a retracing
        #   exit)
        if (
            $departExitObj->retraceFlag
            && $departExitObj->destRoom != $departExitObj->parent
        ) {
            # (We don't call $self->restoreRetracingExit, because that would destroy the exit's
            #   ->destRoom setting)
            $departExitObj->ivPoke('retraceFlag', FALSE);
        }

        # When a random exit is connected to a room, it loses its random status (and any destination
        #   rooms stored in ->randomDestList)
        if ($departExitObj->randomType ne 'none') {

            $self->restoreRandomExit(
                FALSE,              # Don't update Automapper windows yet
                $departExitObj,
            );
        }

        # When an exit is connected to a room, it loses any existing bends
        $departExitObj->ivEmpty('bendOffsetList');
        if ($arriveExitObj) {

            $arriveExitObj->ivEmpty('bendOffsetList');
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Compile a list of rooms to be marked for drawing (if $departRoomObj is not on the
            #   visible region level, it won't get drawn, so there's no danger in marking it to be
            #   drawn here)
            push (@redrawList, 'room', $arriveRoomObj);
            if ($departRoomObj && $departRoomObj ne $arriveRoomObj) {

                push (@redrawList, 'room', $departRoomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub slideRoom {

        # Called by GA::Obj::Map->useExistingRoom after a character move when there's no room for a
        #   new arrival room
        # Depending on the value of $self->autoSlideMode, either the original departure room is
        #   moved (slided) to a new position (in the same region, on the same level), or the room
        #   that's occupying the gridblock where we'd like to draw a new room is moved, or this
        #   function finds an empty gridblock where a new room can be drawn
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $departRoomObj  - The GA::ModelObj::Room from which the character left
        #   $arriveRoomObj  - The GA::ModelObj::Room occupying the gridblock where a new room
        #                       would be placed, if a slide operation were not necessary
        #   $mapDir         - The standard primary direction of movement
        #
        # Return values
        #   An empty list on improper arguments or if it's possible to slide a room
        #   Otherwise, returns a list in the form
        #       (new_x_pos, new_y_pos, z_posn, slid_room_obj)
        #   ...where 'new_x_pos' and 'new_y_pos' are the moved room's new coordinates in the region,
        #       'z_posn' is the room's (unmodified) level in the region, and 'room_obj' is the
        #       room object that was moved, or 'undef' if the coordinates represent an empty
        #       gridblock in which a new room can be created

        my ($self, $session, $updateFlag, $departRoomObj, $arriveRoomObj, $mapDir, $check) = @_;

        # Local variables
        my (
            $mode, $regionmapObj, $slideRoomObj, $xPos, $yPos, $zPos, $useXPos, $useYPos,
            @emptyList,
            %convertHash, %roomHash, %emptyHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $departRoomObj
            || ! defined $arriveRoomObj || ! defined $mapDir || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->slideRoom', @_);
            return @emptyList;
        }

        # Import IVs (for convenience)
        $mode = $self->autoSlideMode;
        $regionmapObj = $self->findRegionmap($departRoomObj->parent);

        if (
            $mode eq 'default'
            || $mapDir eq 'up'
            || $mapDir eq 'down'
            || $departRoomObj->parent != $arriveRoomObj->parent
        ) {
            # Cannot slide either room
            return @emptyList;

        } elsif ($mode eq 'orig_pull' || $mode eq 'orig_push') {

            $slideRoomObj = $departRoomObj;
            $xPos = $slideRoomObj->xPosBlocks;
            $yPos = $slideRoomObj->yPosBlocks;
            $zPos = $slideRoomObj->zPosBlocks;

        } elsif ($mode eq 'other_pull' || $mode eq 'other_push') {

            $slideRoomObj = $arriveRoomObj;
            $xPos = $slideRoomObj->xPosBlocks;
            $yPos = $slideRoomObj->yPosBlocks;
            $zPos = $slideRoomObj->zPosBlocks;

        } elsif ($mode eq 'dest_pull' || $mode eq 'dest_push') {

            # ($slideRoomObj remains 'undef', as the new room hasn't been created yet)
            $xPos = $arriveRoomObj->xPosBlocks;
            $yPos = $arriveRoomObj->yPosBlocks;
            $zPos = $arriveRoomObj->zPosBlocks;

        } else {

            # Invalid $mode
            return @emptyList;
        }

        # For 'push', use the direction of movement, $mapDir. For 'pull', use the opposite direction
        if ($mode =~ m/pull/) {

            $mapDir = $axmud::CLIENT->ivShow('constOppDirHash', $mapDir);
        }

        # Greatly simplify the code by sliding in only eight directions
        %convertHash = (
            northnortheast          => 'north',
            eastnortheast           => 'east',
            eastsoutheast           => 'east',
            southsoutheast          => 'south',
            southsouthwest          => 'south',
            westsouthwest           => 'west',
            westnorthwest           => 'west',
            northnorthwest          => 'north',
        );

        if (exists $convertHash{$mapDir}) {

            $mapDir = $convertHash{$mapDir};
        }

        # Find the nearest unoccupied gridblock. One algorithm for sliding n/s/w/e, another for
        #   sliding nw/ne/sw/se
        if ($mapDir eq 'north' || $mapDir eq 'south' || $mapDir eq 'west' || $mapDir eq 'east') {

            # Search for gridblocks in this general order, where R is the position currently
            #   expressed by $xPos and $yPos
            #
            #   45678           4       4
            #    123            51     15
            #     R       R     62R   R26
            #            123    73     37
            #           45678   8       8

            # 'dest_push' operations look a lot nicer if we modify the starting position by one
            #   block
            if ($mode eq 'dest_push') {

                if ($mapDir eq 'north') {
                    $yPos++;
                } elsif ($mapDir eq 'south') {
                    $yPos--;
                } elsif ($mapDir eq 'west') {
                    $xPos++;
                } elsif ($mapDir eq 'east') {
                    $xPos--;
                }
            }

            # Maximum size of the cone is 8 gridblocks
            OUTER: for ($a = 1; $a <= $self->autoSlideMax; $a++) {

                my ($thisXPos, $thisYPos);

                if ($mapDir eq 'north') {

                    $yPos--;
                    $thisXPos = $xPos - $a;
                    $thisYPos = $yPos;

                } elsif ($mapDir eq 'south') {

                    $yPos++;
                    $thisXPos = $xPos - $a;
                    $thisYPos = $yPos;

                } elsif ($mapDir eq 'west') {

                    $xPos--;
                    $thisXPos = $xPos;
                    $thisYPos = $yPos - $a;

                } else {

                    $xPos++;
                    $thisXPos = $xPos;
                    $thisYPos = $yPos - $a;
                }

                INNER: for ($b = 0; $b < (($a * 2) + 1); $b++) {

                    if ($thisXPos) {
                        $thisXPos += $b;
                    } else {
                        $thisYPos += $b;
                    }

                    if (
                        # Gridblock actually exists
                        $regionmapObj->checkGridBlock($thisXPos, $thisYPos, $zPos)
                        # ...and is not occupied
                        && ! $regionmapObj->fetchRoom($thisXPos, $thisYPos, $zPos)
                    ) {
                        # Success!
                        $useXPos = $thisXPos;
                        $useYPos = $thisYPos;
                        last OUTER;
                    }
                }
            }

        } else {

            # Search for gridblocks in this general order, where R is the position expressed by
            #   $xPos and $yPos
            #
            #     5         5
            #    24         42
            #   R13   R13   31R   31R
            #          24         42
            #           5         5

            # Maximum size of the cone is 8 gridblocks
            OUTER: for ($a = 1; $a <= 8; $a++) {

                my ($thisXPos, $thisYPos);

                if ($mapDir eq 'northeast' || $mapDir eq 'southeast') {
                    $xPos++;
                } else {
                    $xPos--;
                }

                $thisXPos = $xPos;
                $thisYPos = $yPos;

                INNER: for ($b = 0; $b < ($a + 1); $b++) {

                    if ($mapDir eq 'northeast' || $mapDir eq 'northwest') {
                        $thisYPos += ($b * -1);
                    } else {
                        $thisYPos += $b;
                    }

                    if (
                        # Gridblock actually exists
                        $regionmapObj->checkGridBlock($thisXPos, $thisYPos, $zPos)
                        # ...and is not occupied
                        && ! $regionmapObj->fetchRoom($thisXPos, $thisYPos, $zPos)
                    ) {
                        # Success!
                        $useXPos = $thisXPos;
                        $useYPos = $thisYPos;
                        last OUTER;
                    }
                }
            }
        }

        if (! defined $useXPos) {

            # No empty gridblock found
            return @emptyList;
        }

        # Empty gridblock found at $useXPos, $useYPos, $zPos
        #.
        if (! $slideRoomObj) {

            # For some auto-slide modes, return the location of the empty gridblock, so a new room
            #   can be created there
            return ($useXPos, $useYPos, $zPos);

        } else {

            # For others, move an existing room to the empty gridblock

            # $self->moveRoomsLabels expects a room list, stored as a hash
            $roomHash{$slideRoomObj->number} = $slideRoomObj;

            if (
                ! $self->moveRoomsLabels(
                    $session,
                    $updateFlag,
                    $regionmapObj,
                    $regionmapObj,
                    ($useXPos - $slideRoomObj->xPosBlocks),
                    ($useYPos - $slideRoomObj->yPosBlocks),
                    0,
                    \%roomHash,
                    \%emptyHash,            # No labels to move
                )
            ) {
                return @emptyList;
            } else {
                return ($useXPos, $useYPos, $zPos, $slideRoomObj);
            }
        }

        return 1;
    }

    sub updateVisitCount {

        # Called by several functions in the automapper object (GA::Obj::Map) and the Automapper
        #   window (GA::Win::Map)
        # Increments the number of character visits to a room, if allowed
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $number     - The model number of the room object to update
        #
        # Return values
        #   'undef' on improper arguments, if the model object doesn't exist, if it isn't a room, if
        #       $self->countVisitsFlag is set to TRUE (meaning we don't count character visits) or
        #       if the current session doesn't have a current character profile
        #   1 otherwise

        my ($self, $session, $updateFlag, $number, $check) = @_;

        # Local variables
        my ($roomObj, $charName);

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag || ! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateVisitCount', @_);
        }

        # Check that we're allowed to count character visits and that the current session has a
        #   current character profile
        if (! $self->countVisitsFlag || ! $session->currentChar) {

            return undef;
        }

        # Get the model object
        $roomObj = $self->ivShow('modelHash', $number);
        if (! $roomObj || $roomObj->category ne 'room') {

            return undef;
        }

        # Update the room
        $charName = $session->currentChar->name;

        if (! $roomObj->ivExists('visitHash', $charName)) {

            # First visit to this room
            $roomObj->ivAdd('visitHash', $charName, 1);

        } else {

            # A return visit to this room
            $roomObj->ivIncHash('visitHash', $charName);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub resetVisitCount {

        # Called by GA::Win::Map->resetVisitsCallback
        # Removes the record of the number of visits in a specified room for a specified character
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                       be updated now, FALSE if not (in which case, they can be updated
        #                       later by the calling function, when it is ready)
        #   $roomObj    - The GA::ModelObj::Room to update
        #
        # Optional arguments
        #   $char       - The name of the character whose record should be erased. If set to
        #                   'undef', all characters' records are erased
        #
        # Return values
        #   'undef' on improper arguments or if no record(s) are deleted
        #   1 otherwise

        my ($self, $updateFlag, $roomObj, $char, $check) = @_;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $roomObj || ! defined $char || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetVisitCount', @_);
        }

        if ($char) {

            if (! $roomObj->ivExists('visitHash', $char)) {

                # Record doesn't exist
                return undef;

            } else {

                $roomObj->ivDelete('visitHash', $char);
            }

        } else {

            if (! $roomObj->visitHash) {

                # No records for this room
                return undef;

            } else {

                $roomObj->ivEmpty('visitHash');
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub resetRoomData {

        # Called by GA::Win::Map->resetRoomDataCallback
        # Resets data stored in one or more room model objects
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $type       - The type of data to reset - 'title', 'descrip', 'room_tag', 'room_guild',
        #                   'room_flag', 'room_cmd', 'unspecified', 'exit_depart', 'checked_dir',
        #                   'script', 'noun_adj', 'search', 'char_visit', 'exclusive', 'remote',
        #                   'path' or 'all_data' for all of the above
        #
        # Optional arguments
        #   @roomList   - The list of room model objects to reset (can be an empty list)
        #
        # Return values
        #   'undef' on improper argumentsm or if no data is deleted
        #   1 otherwise

        my ($self, $updateFlag, $type, @roomList) = @_;

        # Local variables
        my @markList;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $type) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetRoomData', @_);
        }

        foreach my $roomObj (@roomList) {

            if ($type eq 'title' || $type eq 'all_data') {

                $roomObj->ivEmpty('titleList');
            }

            if ($type eq 'descrip' || $type eq 'all_data') {

                $roomObj->ivEmpty('descripHash');
            }

            if ($type eq 'room_tag' || $type eq 'all_data') {

                $roomObj->ivUndef('roomTag');
                $roomObj->ivPoke('roomTagXOffset', 0);
                $roomObj->ivPoke('roomTagYOffset', 0);
            }

            if ($type eq 'room_guild' || $type eq 'all_data') {

                $roomObj->ivUndef('roomGuild');
                $roomObj->ivPoke('roomGuildXOffset', 0);
                $roomObj->ivPoke('roomGuildYOffset', 0);
            }

            if ($type eq 'room_flag' || $type eq 'all_data') {

                $roomObj->ivEmpty('roomFlagHash');
                $roomObj->ivUndef('lastRoomFlag');
            }

            if ($type eq 'room_cmd' || $type eq 'all_data') {

                $roomObj->ivEmpty('roomCmdList');
                $roomObj->ivEmpty('tempRoomCmdList');
            }

            if ($type eq 'unspecified' || $type eq 'all_data') {

                $roomObj->ivEmpty('unspecifiedPatternList');
            }

            if ($type eq 'exit_depart' || $type eq 'all_data') {

                $roomObj->ivEmpty('failExitPatternList');
                $roomObj->ivEmpty('specialDepartPatternList');
                $roomObj->ivEmpty('involuntaryExitPatternHash');
                $roomObj->ivEmpty('repulseExitPatternHash');
            }

            if ($type eq 'checked_dir' || $type eq 'all_data') {

                $roomObj->ivEmpty('checkedDirHash');
            }

            if ($type eq 'noun_adj' || $type eq 'all_data') {

                $roomObj->ivEmpty('nounList');
                $roomObj->ivEmpty('adjList');
            }

            if ($type eq 'search' || $type eq 'all_data') {

                $roomObj->ivEmpty('searchHash');
            }

            if ($type eq 'char_visit' || $type eq 'all_data') {

                $roomObj->ivEmpty('visitHash');
            }

            if ($type eq 'exlusive' || $type eq 'all_data') {

                $roomObj->ivPoke('exclusiveFlag', FALSE);
                $roomObj->ivEmpty('exclusiveHash');
            }

            if ($type eq 'remote' || $type eq 'all_data') {

                $roomObj->ivEmpty('protocolRoomHash');
                $roomObj->ivEmpty('protocolExitHash');
            }

            if ($type eq 'script' || $type eq 'all_data') {

                $roomObj->ivEmpty('arriveScriptList');
            }

            if ($type eq 'path' || $type eq 'all_data') {

                $roomObj->ivUndef('sourceCodePath');
                $roomObj->ivUndef('virtualAreaPath');
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag && @roomList) {

            foreach my $roomObj (@roomList) {

                push (@markList, 'room', $roomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@markList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub addExitPattern {

        # Can be called by anything
        # Adds a pattern to a specified room
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room to update
        #   $type       - The type of pattern to add - 'fail', 'special' or 'unspecified' (if not
        #                   one of these strings, no pattern is added)
        #   $pattern    - The pattern to add
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $type, $pattern, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $type || ! defined $pattern || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addExitPattern', @_);
        }

        if ($type eq 'fail') {
            $roomObj->ivPush('addFailExitPattern', $pattern);
        } elsif ($type eq 'special') {
            $roomObj->ivPush('specialDepartPatternList', $pattern);
        } elsif ($type eq 'unspecified') {
            $roomObj->ivPush('unspecifiedPatternList', $pattern);
        }

        return 1;
    }

    sub setRoomSource {

        # Called by GA::Win::Map->setFilePathCallback
        # Sets a world model room's source code file and (optionally) its virtual area file, when
        #   it is known
        #
        # Expected arguments
        #   $roomObj        - The GA::ModelObj::Room to modify
        #
        # Optional arguments
        #   $filePath       - The path to the room's source code file, relative to
        #                       $self->mudlibPath. If 'undef' or an empty string, the room's
        #                       ->sourceCodePath is set to 'undef'
        #   $virtualPath    - The virtual area path, e.g. '/filepath/forest/24,3', relative to
        #                       $self->mudlibPath. If 'undef' or an empty string, the room's
        #                       ->sourceCodePath is set to 'undef'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $filePath, $virtualPath, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setRoomSource', @_);
        }

        if (! $filePath) {

            $roomObj->ivUndef('sourceCodePath');

        } else {

            $roomObj->ivPoke('sourceCodePath', $filePath);
            # Save this filepath for the next new room, so that if the directories are the same, the
            #   user doesn't have to type the whole thing again
            $self->ivPoke('lastFilePath', $filePath);
        }

        if (! $virtualPath) {

            $roomObj->ivUndef('virtualAreaPath');

        } else {

            $roomObj->ivPoke('virtualAreaPath', $virtualPath);
            # Likewise, save the virtual area
            $self->ivPoke('lastVirtualAreaPath', $filePath);
        }

        foreach my $mapWin ($self->collectMapWins()) {

            # If the room is on the automapper's region and level...
            if (
                $mapWin->currentRegionmap
                && $mapWin->currentRegionmap->number eq $roomObj->parent
                && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
            ) {
                # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
                $mapWin->restrictWidgets();
            }
        }

        return 1;
    }

    sub addSearchTerm {

        # Called by GA::Win::Map->addSearchResultCallback
        # Adds a search term (and its result) to a specified room object
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room to modify
        #   $term       - The search term, e.g. 'fireplace'
        #   $result     - The result, e.g. 'It's an old fireplace'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $term, $result, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $term || ! defined $result || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addSearchTerm', @_);
        }

        $roomObj->ivAdd('searchHash', $term, $result);

        return 1;
    }

    sub setRoomTag {

        # Called by GA::Win::Map->setRoomTagCallback
        # Sets the specified room's room tag, updating all IVs and redrawing the room (if allowed)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $roomObj    - The room object to use
        #   $tag        - The room's new tag
        #
        # Return values
        #   'undef' on improper arguments, if the $tag contains the string '@@@' (which is needed
        #       for route objects) or if the $tag is longer than the maximum 16 characters
        #   1 otherwise

        my ($self, $updateFlag, $roomObj, $tag, $check) = @_;

        # Local variables
        my (
            $oldRoomNum, $oldRoomObj, $regionmapObj,
            @redrawList,
        );

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $roomObj || ! defined $tag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setRoomTag', @_);
        }

        # Check that the $tag is valid
        if (length($tag) > 16 || $tag =~ m/@@@/) {

            # Invalid tag
            return undef;

        } else {

            # Room tags are stored in lower-case letters
            $tag = lc($tag);
        }

        # If the room already has a tag, remove it
        if ($roomObj->roomTag) {

            $self->resetRoomTag(
                FALSE,      # Don't update the Automapper windows yet
                $roomObj,
            );
        }

        # See if the specified tag already exists
        $oldRoomNum = $self->checkRoomTag($tag);
        if ($oldRoomNum) {

            # Remove the other room's tag
            $oldRoomObj = $self->ivShow('modelHash', $oldRoomNum);
            $self->resetRoomTag(
                FALSE,      # Don't update the Automapper windows yet
                $oldRoomObj,
            );

            # Mark the other room to be redrawn
            push (@redrawList, 'room', $oldRoomObj);
        }

        # Assign the tag to $roomObj
        $self->ivAdd('roomTagHash', $tag, $roomObj->number);
        $roomObj->ivPoke('roomTag', $tag);

        # Find the room's regionmap and update it
        $regionmapObj = $self->findRegionmap($roomObj->parent);
        $regionmapObj->storeRoomTag($roomObj);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # $roomObj must be redrawn
            push (@redrawList, 'room', $roomObj);

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub resetRoomTag {

        # Called by GA::Win::Map->setRoomTagCallback
        # Removes the specified room's room tag (if any), updating all IVs and redrawing the room
        #   (if allowed)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $roomObj    - The room object to update
        #
        # Return values
        #   'undef' on improper arguments or if the specified room doesn't have a room tag
        #   1 otherwise

        my ($self, $updateFlag, $roomObj, $check) = @_;

        # Local variables
        my ($regionObj, $regionmapObj, $key);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetRoomTag', @_);
        }

        # Check the room actually has a room tag
        if (! $roomObj->roomTag) {

            # Nothing to do here
            return undef;
        }

        # Delete the entry in the world model's list of room tags
        $self->ivDelete('roomTagHash', $roomObj->roomTag);

        # Find the room's regionmap and update it
        $regionmapObj = $self->findRegionmap($roomObj->parent);
        $regionmapObj->removeRoomTag($roomObj);

        # Reset the room object's own IV
        $roomObj->ivUndef('roomTag');

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub checkRoomTag {

        # Called by GA::Win::Map->setRoomGuildCallback, GA::Cmd::SetRoom->do and
        #   $self->setRoomTag
        # Checks whether a room tag is already in use, or not. Since room tags are supposed to be
        #   checked in a case-insensitive way, we need to check every existing room tag
        # If an existing model room is using the room tag, returns the room's model number;
        #   otherwise returns 'undef'
        #
        # Expected arguments
        #   $tag    - A room tag to check. If it is set to 'tower', this function checks whether
        #               any room is using the tag 'tower', 'TOWER', 'tOwEr', etc
        #
        # Return values
        #   'undef' on improper arguments or if the room tag is available for use
        #   Otherwise, returns the model number of the room using this tag (with or without the
        #       same capital letters)

        my ($self, $tag, $check) = @_;

        # Check for improper arguments
        if (! defined $tag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkRoomTag', @_);
        }

        foreach my $otherTag ($self->ivKeys('roomTagHash')) {

            if (lc($tag) eq lc($otherTag)) {

                # The tag is already in use. Return the room's model number
                return $self->ivShow('roomTagHash', $otherTag);
            }
        }

        # The tag is available
        return undef;
    }

    sub setRoomGuild {

        # Called by GA::Win::Map->setRoomGuildCallback
        # Sets the specified room's guild, updating all IVs and redrawing the room (if allowed)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #
        # Optional argument
        #   $guildName  - The name of the guild profile for this room. If set to 'undef', the room's
        #                   guild is reset
        #   @roomList   - A list of room GA::ModelObj::Room objects. If the list is empty, no rooms
        #                   are updated
        #
        # Return values
        #   'undef' on improper arguments or if @roomList is empty
        #   1 otherwise

        my ($self, $updateFlag, $guildName, @roomList) = @_;

        # Local variables
        my @redrawList;

        # Check for improper arguments
        if (! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setRoomGuild', @_);
        }

        # Do nothing if @roomList is empty
        if (! @roomList) {

            return undef;
        }

        # Update each room in turn
        foreach my $roomObj (@roomList) {

            my $regionmapObj;

            # Set the room's guild. $guildName might be 'undef'
            $roomObj->ivPoke('roomGuild', $guildName);

            # Update the regionmap
            $regionmapObj = $self->findRegionmap($roomObj->parent);

            if ($guildName) {
                $regionmapObj->storeRoomGuild($roomObj);
            } else {
                $regionmapObj->removeRoomGuild($roomObj);
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $roomObj (@roomList) {

                push (@redrawList, 'room', $roomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub resetRoomOffsets {

        # Called by GA::Win::Map->resetRoomOffsetsCallback
        # Resets the room's room tag and room guild offsets - the distance from the default position
        #   at which the text is drawn (allows the user to drag the text around the map)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $mode       - Set to 0 to reset room tags and room guilds, 1 to reset room tags only or
        #                   2 to reset room guilds only
        #
        # Optional argument
        #   @roomList   - A list of room GA::ModelObj::Room objects. If the list is empty, no
        #                   rooms are updated
        #
        # Return values
        #   'undef' on improper arguments or if @roomList is empty
        #   1 otherwise

        my ($self, $updateFlag, $mode, @roomList) = @_;

        # Local variables
        my @redrawList;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $mode) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetRoomOffsets', @_);
        }

        # Do nothing if @roomList is empty
        if (! @roomList) {

            return undef;
        }

        # Update each room in turn
        foreach my $roomObj (@roomList) {

            if ($roomObj->roomTag && $mode != 2) {

                $roomObj->ivPoke('roomTagXOffset', 0);
                $roomObj->ivPoke('roomTagYOffset', 0);
            }

            if ($roomObj->roomGuild && $mode != 1) {

                $roomObj->ivPoke('roomGuildXOffset', 0);
                $roomObj->ivPoke('roomGuildYOffset', 0);
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $roomObj (@roomList) {

                push (@redrawList, 'room', $roomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub toggleRoomExclusivity {

        # Called by GA::Win::Map->enableRoomsColumn
        # Toggles the ->exclusiveFlag for one or more room objects
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #
        # Optional argument
        #   @roomList   - A list of room GA::ModelObj::Room objects. If the list is empty, no rooms
        #                   are updated
        #
        # Return values
        #   'undef' on improper arguments or if @roomList is empty
        #   1 otherwise

        my ($self, $updateFlag, @roomList) = @_;

        # Local variables
        my @redrawList;

        # Check for improper arguments
        if (! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleRoomExclusivity', @_);
        }

        # Do nothing if @roomList is empty
        if (! @roomList) {

            return undef;
        }

        # Update each room in turn
        foreach my $roomObj (@roomList) {

            if ($roomObj->exclusiveFlag) {
                $roomObj->ivPoke('exclusiveFlag', FALSE);
            } else {
                $roomObj->ivPoke('exclusiveFlag', TRUE);
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $roomObj (@roomList) {

                push (@redrawList, 'room', $roomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub setRoomExclusiveProfile {

        # Called by GA::Win::Map->enableRoomsColumn
        # Toggles the ->exclusiveFlag for one or more room objects
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $roomObj    - The GA::ModelObj::Room to update
        #   $profName   - The profile to be set as an exclusive profile for this room
        #
        # Return values
        #   'undef' on improper arguments or if @roomList is empty
        #   1 otherwise

        my ($self, $updateFlag, $roomObj, $profName, $check) = @_;

        # Check for improper arguments
        if (! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->setRoomExclusiveProfile',
                @_,
            );
        }

        # Add the profile to this room's exclusive profile hash
        $roomObj->ivAdd('exclusiveHash', $profName, undef);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub resetExclusiveProfiles {

        # Called by GA::Win::Map->enableRoomsColumn
        # Resets the list of exclusive profile for one or more room objects
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #
        # Optional argument
        #   @roomList   - A list of room GA::ModelObj::Room objects. If the list is empty, no rooms
        #                   are updated
        #
        # Return values
        #   'undef' on improper arguments or if @roomList is empty
        #   1 otherwise

        my ($self, $updateFlag, @roomList) = @_;

        # Local variables
        my @redrawList;

        # Check for improper arguments
        if (! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetExclusiveProfiles', @_);
        }

        # Do nothing if @roomList is empty
        if (! @roomList) {

            return undef;
        }

        # Update each room in turn
        foreach my $roomObj (@roomList) {

            $roomObj->ivEmpty('exclusiveHash');
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $roomObj (@roomList) {

                push (@redrawList, 'room', $roomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub updateInvRepExit {

        # Called by $self->deleteObj
        # Each room model object keeps track of which rooms use it as the destination room for an
        #   involuntary exit pattern/repulse exit pattern
        # When a room is deleted, this function is called to remove an entry in the destination
        #   room's hash
        #
        # Expected arguments
        #   $destRoomObj    - The room to update
        #   $deleteRoomObj  - The room to be deleted
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $destRoomObj, $deleteRoomObj, $check) = @_;

        # Check for improper arguments
        if (! defined $destRoomObj || ! defined $deleteRoomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateInvRepExit', @_);
        }

        # Update IVs
        $destRoomObj->ivDelete('invRepExitHash', $deleteRoomObj->number);

        return 1;
    }

    sub addInvoluntaryExit {

        # Called by GA::EditWin::ModelObj::Room->saveChanges,
        #   GA::Win::Map->addInvoluntaryExitCallback or any other function
        # Adds an involuntary exit pattern and, optionally, a direction (or a room model number)
        #   which identifies the destination room
        #
        # Expected arguments
        #   $roomObj        - The room model object (GA::ModelObj::Room) to update
        #   $pattern        - The involuntary exit pattern to add
        #
        # Optional arguments
        #   $value          - The direction of movement, or the number of the destination room, or
        #                       'undef'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $pattern, $value, $check) = @_;

        # Local variables
        my $destRoomObj;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $pattern  || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addInvoluntaryExit', @_);
        }

        # Update IVs
        $roomObj->ivAdd('involuntaryExitPatternHash', $pattern, $value);
        # If $value is a destination room, update that room, too
        if (defined $value) {

            $destRoomObj = $self->ivShow('modelHash', $value);
            if ($destRoomObj) {

                $destRoomObj->ivAdd('invRepExitHash', $roomObj->number);
            }
        }

        return 1;
    }

    sub removeInvoluntaryExit {

        # Called by GA::EditWin::ModelObj::Room->saveChanges or any other function
        # Removes an involuntary exit pattern. If the pattern has a corresponding destination room,
        #   updates the destination room's IVs too
        #
        # Expected arguments
        #   $roomObj        - The room model object (GA::ModelObj::Room) to update
        #   $pattern        - The involuntary exit pattern to remove
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $pattern, $check) = @_;

        # Local variables
        my ($value, $destRoomObj, $matchFlag);

        # Check for improper arguments
        if (! defined $roomObj || ! defined $pattern  || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeInvoluntaryExit', @_);
        }

        # Update IVs
        $value = $roomObj->ivShow('involuntaryExitPatternHash', $pattern);
        $roomObj->ivDelete('involuntaryExitPatternHash', $pattern);

        if (defined $value) {

            # $value can be 'undef', a direction or a destination room model object
            $destRoomObj = $self->ivShow('modelHash', $value);
            if (defined $destRoomObj) {

                # If $roomObj has no further involuntary or repulse exit patterns whose
                #   corresponding destination room number is $value, we can delete the entry
                OUTER: foreach my $otherVal (
                    $roomObj->ivValues('involuntaryExitPatternHash'),
                    $roomObj->ivValues('repulseExitPatternHash'),
                ) {
                    if (defined $otherVal && $otherVal eq $value) {

                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }

                if (! $matchFlag) {

                    $destRoomObj->ivDelete('invRepExitHash', $roomObj->number);
                }
            }
        }

        return 1;
    }

    sub addRepulseExit {

        # Called by GA::EditWin::ModelObj::Room->saveChanges,
        #   GA::Win::Map->addRepulseExitCallback or any other function
        # Adds a repulse exit pattern and, optionally, a direction (or a room model number) which
        #   identifies the destination room
        #
        # Expected arguments
        #   $roomObj        - The room model object (GA::ModelObj::Room) to update
        #   $pattern        - The repulse exit pattern to add
        #
        # Optional arguments
        #   $value          - The direction of movement, or the number of the destination room, or
        #                       'undef'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $pattern, $value, $check) = @_;

        # Local variables
        my $destRoomObj;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $pattern  || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRepulseExit', @_);
        }

        # Update IVs
        $roomObj->ivAdd('repulseExitPatternHash', $pattern, $value);
        # If $value is a destination room, update that room, too
        if (defined $value) {

            $destRoomObj = $self->ivShow('modelHash', $value);
            if ($destRoomObj) {

                $destRoomObj->ivAdd('invRepExitHash', $roomObj->number);
            }
        }

        return 1;
    }

    sub removeRepulseExit {

        # Called by GA::EditWin::ModelObj::Room->saveChanges or any other function
        # Removes a repulse exit pattern. If the pattern has a corresponding destination room,
        #   updates the destination room's IVs too
        #
        # Expected arguments
        #   $roomObj        - The room model object (GA::ModelObj::Room) to update
        #   $pattern        - The repulse exit pattern to remove
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $pattern, $check) = @_;

        # Local variables
        my ($value, $destRoomObj, $matchFlag);

        # Check for improper arguments
        if (! defined $roomObj || ! defined $pattern  || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeRepulseExit', @_);
        }

        # Update IVs
        $value = $roomObj->ivShow('repulseExitPatternHash', $pattern);
        $roomObj->ivDelete('repulseExitPatternHash', $pattern);

        if (defined $value) {

            # $value can be 'undef', a direction or a destination room model object
            $destRoomObj = $self->ivShow('modelHash', $value);
            if (defined $destRoomObj) {

                # If $roomObj has no further involuntary or repulse exit patterns whose
                #   corresponding destination room number is $value, we can delete the entry
                OUTER: foreach my $otherVal (
                    $roomObj->ivValues('involuntaryExitPatternHash'),
                    $roomObj->ivValues('repulseExitPatternHash'),
                ) {
                    if (defined $otherVal && $otherVal eq $value) {

                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }

                if (! $matchFlag) {

                    $destRoomObj->ivDelete('invRepExitHash', $roomObj->number);
                }
            }
        }

        return 1;
    }

    sub addRandomDestination {

        # Called by GA::EditWin::Exit->saveChanges
        # Each room model object keeps track of the exits which use the room as a random destination
        #   (but only when GA::Obj::Exit->randomType is 'room_list')
        # This function is called to add an exit to the room's hash
        #
        # Expected arguments
        #   $roomObj    - The room to update
        #   $exitObj    - The exit (belonging to another room) which now uses $roomObj as one of its
        #                   random destinations
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRandomDestination', @_);
        }

        $roomObj->ivAdd('randomExitHash', $exitObj->number, undef);

        return 1;
    }

    sub removeRandomDestination {

        # Called by GA::EditWin::Exit->saveChanges
        # Each room model object keeps track of the exits which use the room as a random destination
        #   (but only when GA::Obj::Exit->randomType is 'room_list')
        # This function is called to remove an exit from the room's hash
        #
        # Expected arguments
        #   $roomObj    - The room to update
        #   $exitObj    - The exit (belonging to another room) which no longer uses $roomObj as one
        #                   of its random destinations
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->removeRandomDestination',
                @_,
            );
        }

        $roomObj->ivDelete('randomExitHash', $exitObj->number, undef);

        return 1;
    }

    sub updateRandomExit {

        # Called by $self->deleteObj when a room is deleted, which has an incoming random exit. This
        #   function removes the room from the exit's list of random destination rooms
        #
        # Expected arguments
        #   $exitObj    - The exit object to update
        #   $roomObj    - The room which is being deleted
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $roomObj, $check) = @_;

        # Local variables
        my (@roomList, @modList);

        # Check for improper arguments
        if (! defined $exitObj || ! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRandomExit', @_);
        }

        # Import the IV
        @roomList = $exitObj->randomDestList;

        # Remove $roomObj from the exit's list of random destinations
        foreach my $roomNum (@roomList) {

            if ($roomNum ne $roomObj->number) {

                push (@modList, $roomNum);
            }
        }

        # Update the IV
        $exitObj->ivPoke('randomDestList', @modList);

        return 1;
    }

    sub setWildernessRoom {

        # Can be called by anything
        # Sets a room's ->wildMode, removing any existing exit objects and redrawing as required
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $mode       - The new wilderness mode, one of the strings 'normal', 'border' or 'wild'
        #                   (it doesn't matter if any specified room already has that mode)
        #
        # Optional arguments
        #   @roomList   - A list of GA::ModelObj::Room objects to update (can be an empty list)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $updateFlag, $mode, @roomList) = @_;

        # Local variables
        my (
            @drawList,
            %checkHash,
        );

        # Check for improper arguments
        if (
            ! defined $session
            || ! defined $updateFlag
            || ! defined $mode
            || ($mode ne 'normal' && $mode ne 'border' && $mode ne 'wild')
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setWildernessRoom', @_);
        }

        foreach my $roomObj (@roomList) {

            my @exitList;

            # For 'wilderness' rooms, remove all existing exits
            if ($mode eq 'wild') {

                foreach my $number ($roomObj->exitNumHash) {

                    my ($exitObj, $destRoomObj);

                    $exitObj = $self->ivShow('exitModelHash', $number);
                    if ($exitObj) {

                        push (@exitList, $exitObj);

                        if (defined $exitObj->destRoom) {

                            $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
                        }
                    }

                    # Don't mark the same room to be redrawn twice
                    if ($destRoomObj && ! exists $checkHash{$destRoomObj->number}) {

                        push (@drawList, 'room', $destRoomObj);
                        $checkHash{$destRoomObj->number} = undef;
                    }
                }

            # For 'wilderness border' rooms, remove all existing exits unless they're connected to a
            #   normal room
            } elsif ($mode eq 'border') {

                foreach my $number ($roomObj->exitNumHash) {

                    my ($exitObj, $destRoomObj);

                    $exitObj = $self->ivShow('exitModelHash', $number);
                    if ($exitObj) {

                        if (defined $exitObj->destRoom) {

                            $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
                        }

                        if (! $destRoomObj || $destRoomObj->wildMode ne 'normal') {

                            push (@exitList, $exitObj);
                        }
                    }


                    # Don't mark the same room to be redrawn twice
                    if ($destRoomObj && ! exists $checkHash{$destRoomObj->number}) {

                        push (@drawList, 'room', $destRoomObj);
                        $checkHash{$destRoomObj->number} = undef;
                    }
                }
            }

            # Delete any exits from rooms that are now 'wilderness' or 'wilderness border' rooms
            $self->deleteExits(
                $session,
                # Deleted exits must be redrawn immediately, regardless of $updateFlag setting
                TRUE,
                @exitList,
            );

            # Now we can actually set the IV
            $roomObj->ivPoke('wildMode', $mode);

            # Mark this room to be redrawn (unless it's already been marked to be redrawn)
            if (! exists $checkHash{$roomObj->number}) {

                push (@drawList, 'room', $roomObj);
                $checkHash{$roomObj->number} = undef;
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                $mapWin->markObjs(@drawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    # Modify model objects - exits

    sub disconnectExit {

        # Can be called by anything
        # Disconnects the specified exit object from its destination room. If the exit has a twin
        #   exit, that exit is disconnected, too
        # This function is a quick way to call the right code (e.g. $self->abandonTwinExit,
        #   ->abandonUncertainExit etc)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to disconnect
        #
        # Return values
        #   'undef' on improper arguments or if the exit isn't connected to a room
        #   Otherwise returns the result of the call to $self->abandonTwinExit, etc)

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->disconnectExit', @_);
        }

        if ($exitObj->destRoom) {

            if ($exitObj->twinExit) {

                # Two-way exit
                return $self->abandonTwinExit($updateFlag, $exitObj);

            } elsif ($exitObj->retraceFlag) {

                # Retracing exit
                return $self->restoreRetracingExit($updateFlag, $exitObj);

            } elsif ($exitObj->oneWayFlag) {

                # One-way exit
                return $self->abandonOneWayExit($updateFlag, $exitObj);

            } elsif ($exitObj->randomType ne 'none') {

                # Random exit
                return $self->restoreRandomExit($updateFlag, $exitObj);

            } else {

                # Uncertain exit
                return $self->abandonUncertainExit($updateFlag, $exitObj);
            }

        } elsif ($exitObj->randomType ne 'none') {

            # Random exit
            return $self->restoreRandomExit($updateFlag, $exitObj);

        } else {

            # Exit not connected
            return undef;
        }

        return 1;
    }

    sub setRegionExit {

        # Can be called by anything
        # Converts an exit into a region exit (cancelling its status as a broken exit, if need be)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #
        # Optional arguments
        #   $regionNum  - The model number of the exit's parent region (set to 'undef' if not
        #                   immediately available)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $regionNum, $check) = @_;

        # Local variables
        my ($roomObj, $regionObj, $destRoomObj, $destRegionObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setRegionExit', @_);
        }

        # Mark the exit as a region exit
        $exitObj->ivPoke('regionFlag', TRUE);
        $exitObj->ivPoke('brokenFlag', FALSE);
        $exitObj->ivPoke('bentFlag', FALSE);
        $exitObj->ivEmpty('bendOffsetList');

        # Find the parent region
        if (! $regionNum) {

            $roomObj = $self->ivShow('modelHash', $exitObj->parent);
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);

        } else {

            $regionObj = $self->ivShow('modelHash', $regionNum);
        }

        # Automatically set the exit tag, if allowed
        $self->applyExitTag(
            FALSE,              # Don't update Automapper windows yet
            $exitObj,
            $self->ivShow('regionmapHash', $regionObj->name),
        );

        # Any region paths using the exit will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);

        if ($updateFlag) {

            # Mark this exit (and its twin, if there is one) to be redrawn in every Automapper
            #   window using this world model
            $self->updateMapExit($exitObj);
        }

        return 1;
    }

    sub unsetRegionExit {

        # Can be called by anything
        # Converts a region exit into a non-region exit (it's up to the calling function to check
        #   whether it is now a broken exit, or not)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #
        # Optional arguments
        #   $regionNum  - The model number of the exit's parent region (set to 'undef' if not
        #                   immediately available)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $regionNum, $check) = @_;

        # Local variables
        my ($roomObj, $regionObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->unsetRegionExit', @_);
        }

        # If it's not a region exit, do nothing
        if ($exitObj->regionFlag) {

            # Find the parent region
            if (! $regionNum) {

                $roomObj = $self->ivShow('modelHash', $exitObj->parent);
                $regionObj = $self->ivShow('modelHash', $roomObj->parent);

            } else {

                $regionObj = $self->ivShow('modelHash', $regionNum);
            }

            # Update IVs
            $exitObj->ivPoke('regionFlag', FALSE);
            $exitObj->ivPoke('superFlag', FALSE);
            $exitObj->ivPoke('notSuperFlag', FALSE);
            $self->cancelExitTag(
                FALSE,              # Don't update Automapper windows yet
                $exitObj,
                $self->ivShow('regionmapHash', $regionObj->name),
            );

            # Any region paths using the exit will have to be updated
            $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);

            if ($updateFlag) {

                # Mark this exit (and its twin, if there is one) to be redrawn in every Automapper
                #   window using this world model
                $self->updateMapExit($exitObj);
            }
        }

        return 1;
    }

    sub setBrokenExit {

        # Can be called by anything
        # Converts an exit into a broken exit. Region exits can't be converted into broken exits, so
        #   the operation will fail if a calling function tries that
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #
        # Optional arguments
        #   $regionNum  - The model number of the exit's parent region (set to 'undef' if not
        #                   immediately available)
        #
        # Return values
        #   'undef' on improper arguments or if $exitObj is a region exit
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $regionNum, $check) = @_;

        # Local variables
        my ($roomObj, $regionObj, $destRoomObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setBrokenExit', @_);
        }

        # Region exits can't be converted into broken exits
        if ($exitObj->regionFlag) {

            return undef;
        }

        # Find the parent region and destination room (if any)
        if (! $regionNum) {

            $roomObj = $self->ivShow('modelHash', $exitObj->parent);
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);

        } else {

            $regionObj = $self->ivShow('modelHash', $regionNum);
        }

        if ($exitObj->destRoom) {

            $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
        }

        # Any region paths using the exit will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);

        # Mark the exit as broken
        $exitObj->ivPoke('brokenFlag', TRUE);
        $self->checkBentExit($exitObj, $roomObj, $destRoomObj);

        if ($updateFlag) {

            # Mark this exit (and its twin, if there is one) to be redrawn in every Automapper
            #   window using this world model
            $self->updateMapExit($exitObj);
        }

        return 1;
    }

    sub unsetBrokenExit {

        # Can be called by anything
        # Converts a broken exit into a non-broken exit (it's up to the calling function to check
        #   whether it is now a region exit, or not)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #
        # Optional arguments
        #   $regionNum  - The model number of the exit's parent region (set to 'undef' if not
        #                   immediately available)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $regionNum, $check) = @_;

        # Local variables
        my ($roomObj, $regionObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->unsetBrokenExit', @_);
        }

        # If it's not a broken exit, do nothing
        if ($exitObj->brokenFlag) {

            # Update IVs
            $exitObj->ivPoke('brokenFlag', FALSE);
            $exitObj->ivPoke('bentFlag', FALSE);
            $exitObj->ivEmpty('bendOffsetList');

            # Find the parent region
            if (! $regionNum) {

                $roomObj = $self->ivShow('modelHash', $exitObj->parent);
                $regionObj = $self->ivShow('modelHash', $roomObj->parent);

            } else {

                $regionObj = $self->ivShow('modelHash', $regionNum);
            }

            # Any region paths using the exit will have to be updated
            $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);

            if ($updateFlag) {

                # Mark this exit (and its twin, if there is one) to be redrawn in every Automapper
                #   window using this world model
                $self->updateMapExit($exitObj);
            }
        }

        return 1;
    }

    sub restoreBrokenExit {

        # Can be called by anything
        # Converts an existing broken exit into a normal (unbroken) exit, if it's possible to do so
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The GA::Obj::Exit to convert
        #
        # Optional arguments
        #   $noCheckFlag    - Flag set to TRUE if the calling function has already checked whether
        #                       it's possible to restore the broken index (in a call to
        #                       $self->checkRoomAlignment). If set to FALSE (or 'undef'), this
        #                       function performs the check
        #
        # Return values
        #   'undef' on improper arguments or if the broken exit can't be restored
        #   1 otherwise

        my ($self, $session, $updateFlag, $exitObj, $noCheckFlag, $check) = @_;

        # Local variables
        my ($roomObj, $regionObj);

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restoreBrokenExit', @_);
        }

        if (
            ! $exitObj->brokenFlag
            || (! $noCheckFlag && ! $self->checkRoomAlignment($session, $exitObj))
        ) {
            # The broken exit can't be restored
            return undef;
        }

        # Mark the exit as not broken
        $exitObj->ivPoke('brokenFlag', FALSE);
        $exitObj->ivPoke('bentFlag', FALSE);
        $exitObj->ivEmpty('bendOffsetList');

        # Find the parent region
        $roomObj = $self->ivShow('modelHash', $exitObj->parent);
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);

        # Any region paths using the restored exit will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);

        if ($updateFlag) {

            # Mark this exit (and its twin, if there is one) to be redrawn in every Automapper
            #   window using this world model
            $self->updateMapExit($exitObj);
        }

        return 1;
    }

    sub setHiddenExit {

        # Can be called by anything
        # Converts an exit into a hidden exit (one which isn't expected to appear in a room
        #   statement's list of exits)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to modify
        #   $hiddenFlag - The new value of the IV - TRUE of FALSE
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $hiddenFlag, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $exitObj || ! defined $hiddenFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setHiddenExit', @_);
        }

        if ($hiddenFlag) {
            $exitObj->ivPoke('hiddenFlag', TRUE);
        } else {
            $exitObj->ivPoke('hiddenFlag', FALSE);
        }

        if ($updateFlag) {

            # Mark this exit (and its twin, if there is one) to be redrawn in every Automapper
            #   window using this world model
            $self->updateMapExit($exitObj);
        }

        return 1;
    }

    sub convertUncertainExit {

        # Can be called by anything
        # Converts an uncertain exit into a one-way exit, updating the (potential) destination
        #   room's IVs as well
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #   $roomObj    - The GA::ModelObj::Room which stores this exit as an uncertain exit
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $roomObj, $check) = @_;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || ! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertUncertainExit', @_);
        }

        # Mark the uncertain exit as a one-way exit
        $exitObj->ivPoke('oneWayFlag', TRUE);
        # The default incoming direction (where the exit touches its destination room) is the
        #   opposite of ->mapDir
        # NB If the exit is unallocatable, ->mapDir won't be set, so we'll use 'north' as an
        #   emergency default value for ->mapDir
        if ($exitObj->mapDir) {

            $exitObj->ivPoke(
                'oneWayDir',
                $axmud::CLIENT->ivShow('constOppDirHash', $exitObj->mapDir),
            );

        } else {

            # Emergency default
            $exitObj->ivPoke('oneWayDir', 'north');
        }

        # Set ->randomType too, just to be safe
        $exitObj->ivPoke('randomType', 'none');
        # Update the (potential) destination room's IVs
        $roomObj->ivDelete('uncertainExitHash', $exitObj->number);
        $roomObj->ivAdd('oneWayExitHash', $exitObj->number, undef);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw both the exit and its destination room
                $mapWin->markObjs(
                    'exit', $exitObj,
                    'room', $roomObj,
                );

                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub convertOneWayExit {

        # Can be called by anything
        # Converts a one-way exit into an uncertain exit, updating the destination room's IVs as
        #   well
        #
        # Expected arguments
        #   $updateFlag         - Flag set to TRUE if all Automapper windows using this world model
        #                           should be updated now, FALSE if not (in which case, they can be
        #                           updated later by the calling function, when it is ready)
        #   $incomingExitObj    - The GA::Obj::Exit to convert
        #   $roomObj            - The GA::ModelObj::Room which stores this exit as a one-way exit
        #   $oppExitObj         - The exit in $roomObj which is the opposite of the incoming exit
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $incomingExitObj, $roomObj, $oppExitObj, $check) = @_;

        # Local variables
        my @redrawList;

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $incomingExitObj || ! defined $roomObj
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertOneWayExit', @_);
        }

        # Mark the one-way exit as an uncertain exit
        $incomingExitObj->ivPoke('oneWayFlag', FALSE);
        $incomingExitObj->ivPoke('oneWayDir', undef);
        # Set ->randomType too, just to be safe
        $incomingExitObj->ivPoke('randomType', 'none');
        # Update the destination room's IVs
        $roomObj->ivDelete('oneWayExitHash', $incomingExitObj->number);
        $roomObj->ivAdd('uncertainExitHash', $incomingExitObj->number, $oppExitObj->number);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Redraw both rooms
            @redrawList = (
                'room', $roomObj,
                'room', $self->ivShow('modelHash', $incomingExitObj->parent),
            );

            foreach my $mapWin ($self->collectMapWins()) {

                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub markOneWayExit {

        # Called by GA::Win::Map->markOneWayExitCallback
        # Converts an existing two-way or uncertain exit into a one-way exit, updating the
        #   destination room's IVs as well
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Local variables
        my (
            $destRoomObj, $twinExitObj, $parentRoomObj, $parentRegionObj,
            @redrawList,
        );

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->markOneWayExit', @_);
        }

        # Mark this exit as a one-way exit
        $exitObj->ivPoke('oneWayFlag', TRUE);
        # The default incoming direction (where the exit touches its destination room) is the
        #   opposite of ->mapDir
        # NB If the exit is unallocatable, ->mapDir won't be set, so we'll use 'north' as an
        #   emergency default value for ->mapDir
        if ($exitObj->mapDir) {

            $exitObj->ivPoke(
                'oneWayDir',
                $axmud::CLIENT->ivShow('constOppDirHash', $exitObj->mapDir),
            );

        } else {

            # Emergency default
            $exitObj->ivPoke('oneWayDir', 'north');
        }

        # Set ->randomType too, just to be safe
        $exitObj->ivPoke('randomType', 'none');
        # (The exit's ->destRoom will be reset in the call to ->abandonTwinExit, so save it so it
        #   can be restored)
        $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);

        # If the exit is a two-way exit (not an uncertain exit)
        if ($exitObj->twinExit) {

            # Mark the twin exit as an incomplete exit (the call to ->abandonTwinExit updates
            #   $self->updatePathHash and ->updateBoundaryHash)
            $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
            $self->abandonTwinExit(
                FALSE,          # Don't update Automapper windows yet
                $exitObj,
                $twinExitObj,
            );

        } else {

            # Remove the selected exit from the destination room's hash of incoming uncertain exits
            $destRoomObj->ivDelete('uncertainExitHash', $exitObj->number);

            # Get the parent room and region
            $parentRoomObj = $self->ivShow('modelHash', $exitObj->parent);
            $parentRegionObj = $self->ivShow('modelHash', $parentRoomObj->parent);

            # Any region paths using the exit will have to be updated
            $self->ivAdd('updatePathHash', $exitObj->number, $parentRegionObj->name);
            if ($exitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $exitObj->number, $parentRegionObj->name);
            }
        }

        # Update the destination room's IVs
        $exitObj->ivPoke('destRoom', $destRoomObj->number);
        $destRoomObj->ivAdd('oneWayExitHash', $exitObj->number, undef);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Redraw both rooms
            @redrawList = (
                'room', $destRoomObj,
                'room', $self->ivShow('modelHash', $exitObj->parent),
            );

            foreach my $mapWin ($self->collectMapWins()) {

                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub abandonTwinExit {

        # Can be called by anything
        # If the specified exit has a twin exit, updates both exits to remove the relationship
        #   between them
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The GA::Obj::Exit to check
        #
        # Optional arguments
        #   $twinExitObj    - $exitObj's twin exit object, if known. If not specified, this function
        #                       finds it
        #
        # Return values
        #   'undef' on improper arguments or if the exit object doesn't have a twin
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $twinExitObj, $check) = @_;

        # Local variables
        my (
            $roomObj, $regionObj, $twinRoomObj, $twinRegionObj,
            @list,
        );

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->abandonTwinExit', @_);
        }

        # If the exit doesn't have a twin, do nothing
        if (! $exitObj->twinExit) {

            return undef;

        # Find the twin exit object, if not specified
        } elsif (! $twinExitObj) {

            $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
        }

        # Find the parent room and region
        $roomObj = $self->ivShow('modelHash', $exitObj->parent);
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);

        # Any region paths using the exits will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        # Modify $exitObj
        $exitObj->ivUndef('destRoom');
        $exitObj->ivUndef('twinExit');
        # If this exit is marked as a broken or region exit, convert it into an incomplete exit
        $exitObj->ivPoke('brokenFlag', FALSE);
        $exitObj->ivPoke('bentFlag', FALSE);
        $exitObj->ivEmpty('bendOffsetList');

        $exitObj->ivPoke('regionFlag', FALSE);
        $exitObj->ivPoke('superFlag', FALSE);
        $exitObj->ivPoke('notSuperFlag', FALSE);
        $self->cancelExitTag(
            FALSE,              # Don't update Automapper windows yet
            $exitObj,
            $self->ivShow('regionmapHash', $regionObj->name),
        );

        # Set ->randomType too, just to be safe
        $exitObj->ivPoke('randomType', 'none');

        # Modify the $twinExitObj, if it still exists
        if ($twinExitObj) {

            # Find the parent room and region
            $twinRoomObj = $self->ivShow('modelHash', $twinExitObj->parent);
            $twinRegionObj = $self->ivShow('modelHash', $twinRoomObj->parent);

            # Any region paths using the exits will have to be updated
            $self->ivAdd('updatePathHash', $twinExitObj->number, $twinRegionObj->name);
            if ($twinExitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $twinExitObj->number, $twinRegionObj->name);
            }

            # Modify $twinExitObj
            $twinExitObj->ivUndef('destRoom');
            $twinExitObj->ivUndef('twinExit');
            # If this exit is marked as a broken or region exit, convert it into an incomplete exit
            $twinExitObj->ivPoke('brokenFlag', FALSE);
            $twinExitObj->ivPoke('bentFlag', FALSE);
            $twinExitObj->ivEmpty('bendOffsetList');
            $twinExitObj->ivPoke('regionFlag', FALSE);
            $twinExitObj->ivPoke('superFlag', FALSE);
            $twinExitObj->ivPoke('notSuperFlag', FALSE);
            $self->cancelExitTag(
                FALSE,              # Don't update Automapper windows yet
                $twinExitObj,
                $self->ivShow('regionmapHash', $twinRegionObj->name),
            );

            # Set ->randomType too, just to be safe
            $twinExitObj->ivPoke('randomType', 'none');
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # If the exit has a twin, that must be redrawn, too
            @list = ('exit', $exitObj);
            if ($twinExitObj) {

                push (@list, 'exit', $twinExitObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the exit(s)
                $mapWin->markObjs(@list);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub abandonShadowExit {

        # Can be called by anything
        # If the specified exit has a shadow exit, resets the stored shadow exit
        #
        # Expected arguments
        #   $exitObj        - The GA::Obj::Exit to check
        #
        # Return values
        #   'undef' on improper arguments or if the exit object doesn't have a shadow exit
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Local variables
        my ($roomObj, $regionObj);

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->abandonShadowExit', @_);
        }

        # If the exit doesn't have a shadow, do nothing
        if (! $exitObj->shadowExit) {

            return undef;
        }

        # Update the exit
        $exitObj->ivUndef('shadowExit');

        # Find the parent region
        $roomObj = $self->ivShow('modelHash', $exitObj->parent);
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        # Any region paths using the exit will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        return 1;
    }

    sub abandonUncertainExit {

        # Called by $self->deleteObj
        # Also called by $self->convertToTwinExits and GA::Win::Map->disconnectExitCallback
        #
        # If the specified uncertain exit has a destination room which is to be deleted, its
        #   destination must be reset. This function also converts an uncertain exit to an
        #   incomplete exit, for any code that needs it
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The GA::Obj::Exit to check
        #
        # Return values
        #   'undef' on improper arguments or if the exit object doesn't have a twin
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Local variables
        my ($roomObj, $regionObj, $destRoomObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->abandonUncertainExit', @_);
        }

        # If the exit isn't an uncertain exit, do nothing
        if (
            ! $exitObj->destRoom
            || $exitObj->randomType ne 'none'
            || $exitObj->oneWayFlag
            || $exitObj->retraceFlag
        ) {
            return undef;
        }

        # Find the parent room and region
        $roomObj = $self->ivShow('modelHash', $exitObj->parent);
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);

        # Modify $exitObj
        $exitObj->ivUndef('destRoom');
        $exitObj->ivUndef('twinExit');
        # Set ->randomType too, just to be safe
        $exitObj->ivPoke('randomType', 'none');
        # If this exit is marked as a broken or region exit, convert it into an incomplete exit
        $exitObj->ivPoke('brokenFlag', FALSE);
        $exitObj->ivPoke('bentFlag', FALSE);
        $exitObj->ivEmpty('bendOffsetList');

        $exitObj->ivPoke('regionFlag', FALSE);
        $self->cancelExitTag(
            FALSE,              # Don't update Automapper windows yet
            $exitObj,
            $self->ivShow('regionmapHash', $regionObj->name),
        );

        # Inform the destination room that it has lost an incoming uncertain exit (if the
        #   destination room still exits)
        if ($destRoomObj) {

            $destRoomObj->ivDelete('uncertainExitHash', $exitObj->number);
        }

        # Any region paths using the exits will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the exit
                $mapWin->markObjs('exit', $exitObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub abandonOneWayExit {

        # Called by $self->deleteObj
        # Also called by $self->convertToTwinExits and GA::Win::Map->disconnectExitCallback
        #
        # If the specified one-way exit has a destination room which is to be deleted, its
        #   destination must be reset. This function also converts a one-way exit to an incomplete
        #   exit, for any code that needs it
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The GA::Obj::Exit to check
        #
        # Return values
        #   'undef' on improper arguments or if the exit object doesn't have a twin
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Local variables
        my ($roomObj, $regionmapObj, $destRoomObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->abandonOneWayExit', @_);
        }

        # If the exit isn't a one-way exit, do nothing
        if (! $exitObj->oneWayFlag) {

            return undef;
        }

        # Find the parent room and region, and the destination room
        $roomObj = $self->ivShow('modelHash', $exitObj->parent);
        $regionmapObj = $self->findRegionmap($roomObj->parent);
        $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);

        # Modify $exitObj
        $exitObj->ivUndef('destRoom');
        $exitObj->ivUndef('twinExit');
        $exitObj->ivPoke('oneWayFlag', FALSE);
        $exitObj->ivPoke('oneWayDir', undef);
        # Set ->randomType too, just to be safe
        $exitObj->ivPoke('randomType', 'none');
        # If this exit is marked as a broken or region exit, convert it into an incomplete exit
        $exitObj->ivPoke('brokenFlag', FALSE);
        $exitObj->ivPoke('bentFlag', FALSE);
        $exitObj->ivEmpty('bendOffsetList');
#        $exitObj->ivPoke('regionFlag', FALSE);

        # Any region paths using the exits will have to be updated, the next time
        #   $self->updateRegionPaths is called
        $self->ivAdd('updatePathHash', $exitObj->number, $regionmapObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionmapObj->name);
            # The regionmap's ->regionExitHash can be updated immediately, though
            $regionmapObj->resetExit($exitObj);

            $exitObj->ivPoke('regionFlag', FALSE);
        }

        $self->cancelExitTag(
            FALSE,              # Don't update Automapper windows yet
            $exitObj,
            $self->ivShow('regionmapHash', $regionmapObj->name),
        );

        # Inform the destination room that it has lost an incoming 1-way exit (if the destination
        #   room still exits)
        if ($destRoomObj) {

            $destRoomObj->ivDelete('oneWayExitHash', $exitObj->number);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the exit
                $mapWin->markObjs('exit', $exitObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub convertToTwinExits {

        # Called by GA::Win::Map->setExitTwinCallback
        # Converts a pair of exits, which are either uncertain or one-way exits (one of each, or
        #   both the same) into twin exits
        # Usually called for two exits which aren't in opposite directions (e.g. north and east),
        #   but which nonetheless lead to each other's parent rooms
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   @exitList   - A list of two The GA::Obj::Exits to convert
        #
        # Return values
        #   'undef' on improper arguments or if the exit object doesn't have a twin
        #   1 otherwise

        my ($self, $updateFlag, @exitList) = @_;

        # Local variables
        my ($exitObj1, $exitObj2, $roomObj1, $roomObj2);

        # Check for improper arguments
        if (! defined $updateFlag || scalar @exitList != 2) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertToTwinExits', @_);
        }

        # Check that the each of the two exits are either one-way or uncertain exits
        foreach my $exitObj (@exitList) {

            if (
                ! (
                    $exitObj->oneWayFlag
                    || (
                        $exitObj->destRoom
                        && ! $exitObj->twinExit
                        && ! $exitObj->retraceFlag
                        && $exitObj->randomType eq 'none'
                    )
                )
            ) {
                return undef;
            }
        }

        # Reset both exits, removing their status as one-way or twin exits. The FALSE arguments mean
        #   'don't update Automapper windows yet'
        foreach my $exitObj (@exitList) {

            if ($exitObj->oneWayFlag) {
                $self->abandonOneWayExit(FALSE, $exitObj);
            } else {
                $self->abandonUncertainExit(FALSE, $exitObj);
            }
        }

        # Now mark each exit as the other's twin
        $exitObj1 = shift @exitList;
        $exitObj2 = shift @exitList;

        $exitObj1->ivPoke('twinExit', $exitObj2->number);
        $exitObj1->ivPoke('destRoom', $exitObj2->parent);

        $exitObj2->ivPoke('twinExit', $exitObj1->number);
        $exitObj2->ivPoke('destRoom', $exitObj1->parent);

        # If the exits' parent rooms are in the same region, mark it as a broken exit; otherwise
        #   mark it as a region exit
        $roomObj1 = $self->ivShow('modelHash', $exitObj1->parent);
        $roomObj2 = $self->ivShow('modelHash', $exitObj2->parent);

        if ($roomObj1->parent == $roomObj2->parent) {

            $self->setBrokenExit(
                FALSE,          # Don't update Automapper windows yet
                $exitObj1,
                $roomObj1->parent,
            );

            $self->setBrokenExit(
                FALSE,          # Don't update Automapper windows yet
                $exitObj2,
                $roomObj2->parent,
            );

        } else {

            $self->setRegionExit(
                FALSE,          # Don't update Automapper windows yet
                $exitObj1,
                $roomObj1->parent,
            );

            $self->setRegionExit(
                FALSE,          # Don't update Automapper windows yet
                $exitObj2,
                $roomObj2->parent,
            );
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(
                    'room', $roomObj1,
                    'room', $roomObj2,
                );

                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub setRetracingExit {

        # Called by $self->connectRooms
        # Converts an exit into a retracing exit (resetting other IVs as necessary)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Local variables
        my ($regionFlag, $destRoomNum, $twinExitNum, $roomObj, $regionObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setRetracingExit', @_);
        }

        $regionFlag = $exitObj->regionFlag;

        # The call to ->abandonTwinExit resets $exitObj->destRoom, so store it so that we can
        #   restore the original value
        if ($exitObj->destRoom) {

            $destRoomNum = $exitObj->destRoom;
        }

        # Make sure the exit doesn't have an existing twin and/or shadow exit (both of which are now
        #   obsolete)
        if ($exitObj->twinExit) {

            $twinExitNum = $exitObj->twinExit;

            $self->abandonTwinExit(
                FALSE,       # Don't update Automapper windows now
                $exitObj,
            );
        }

        if ($exitObj->shadowExit) {

            $self->abandonShadowExit($exitObj);
        }

        # Set the exit's IVs
        $exitObj->ivPoke('brokenFlag', FALSE);
        $exitObj->ivPoke('bentFlag', FALSE);
        $exitObj->ivEmpty('bendOffsetList');

        $exitObj->ivPoke('regionFlag', FALSE);
        $self->cancelExitTag(
            FALSE,              # Don't update Automapper windows yet
            $exitObj,
        );

        $exitObj->ivPoke('randomType', 'none');
        $exitObj->ivPoke('oneWayFlag', FALSE);
        $exitObj->ivPoke('oneWayDir', undef);
        $exitObj->ivPoke('retraceFlag', TRUE);

        if (defined $destRoomNum) {

            $exitObj->ivPoke('destRoom', $destRoomNum);
        }

        # If there is a twin exit, the call to ->abandonTwinExit has already updated
        #   $self->updatePathHash/->updateBoundaryHash; otherwise, we need to update them now
        if (! $exitObj->twinExit) {

            # Find the parent region
            $roomObj = $self->ivShow('modelHash', $exitObj->parent);
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);
            # Any region paths using the exit will have to be updated
            $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
            if ($regionFlag) {

                $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                my (
                    $twinExitObj,
                    @list,
                );

                # Mark both the exit and its twin (if any) to be redrawn
                @list = ('exit', $exitObj);
                if ($twinExitNum) {

                    $twinExitObj = $self->ivShow('exitModelHash', $twinExitNum);
                    if ($twinExitObj) {

                        push (@list, 'exit', $twinExitObj);
                    }
                }

                # Redraw the objects
                $mapWin->markObjs(@list);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub restoreRetracingExit {

        # Called by GA::Win::Map->restoreRetracingExitCallback
        # Converts an existing retracing exit into an incomplete exit
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Local variables
        my $roomObj;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restoreRetracingExit', @_);
        }

        # Convert the exit
        $exitObj->ivPoke('retraceFlag', FALSE);
        $exitObj->ivUndef('destRoom');

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            $roomObj = $self->ivShow('modelHash', $exitObj->parent);

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub setRandomExit {

        # Called by GA::Win::Map->markRandomExitCallback
        # Converts an exit into a random exit (resetting other IVs as necessary)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #   $exitType   - Set to 'same_region' if the exit leads to a random location in the current
        #                   region, 'any_region' if the exit leads to a random location in any
        #                   region, 'temp_region' if a destination should be created in a new
        #                   temporary region,  or 'room_list' if the exit leads to a random location
        #                   in the exit's ->randomDestList
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $exitType, $check) = @_;

        # Local variables
        my (
            $regionFlag, $currentType, $roomObj, $regionObj,
            @redrawList,
        );

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $exitObj || ! defined $exitType
            || (
                $exitType ne 'same_region' && $exitType ne 'any_region'
                && $exitType ne 'temp_region' && $exitType ne 'room_list'
            )
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setRandomExit', @_);
        }

        $regionFlag = $exitObj->regionFlag;
        $currentType = $exitObj->randomType;

        # If the exit already has a destination room, mark it for redrawing
        if ($exitObj->destRoom) {

            push (@redrawList, 'room', $self->ivShow('modelHash', $exitObj->destRoom));
        }

        # If the exit has a twin, it must be abandoned
        if ($exitObj->twinExit) {

            $self->abandonTwinExit(
                FALSE,      # Don't update Automapper windows yet
                $exitObj,
            );
        }

        # The same applies if the exit has a shadow exit
        if ($exitObj->shadowExit) {

            $self->abandonShadowExit($exitObj);
        }

        # Update the exit
        $exitObj->ivPoke('brokenFlag', FALSE);
        $exitObj->ivPoke('bentFlag', FALSE);
        $exitObj->ivEmpty('bendOffsetList');

        $exitObj->ivPoke('regionFlag', FALSE);
        $self->cancelExitTag(
            FALSE,              # Don't update Automapper windows yet
            $exitObj,
        );

        $exitObj->ivPoke('randomType', $exitType);
        $exitObj->ivPoke('oneWayFlag', FALSE);
        $exitObj->ivPoke('oneWayDir', undef);
        $exitObj->ivPoke('retraceFlag', FALSE);

        # If there is a twin exit, the call to ->abandonTwinExit has already updated
        #   $self->updatePathHash/->updateBoundaryHash; otherwise, we need to update them now
        if (! $exitObj->twinExit) {

            # Find the parent region
            $roomObj = $self->ivShow('modelHash', $exitObj->parent);
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);
            # Any region paths using the exit will have to be updated
            $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
            if ($regionFlag) {

                $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
            }
        }

        # Mark the exit's parent room to be redawn (if allowed)
        push (@redrawList, 'room', $self->ivShow('modelHash', $exitObj->parent));

        # If the exit's ->randomType was set to 'room_list' (but is not set to 'same_region' or
        #   'any_region'), we need to update the exit's ->randomDestList and each of the former
        #   destination rooms
        if ($currentType eq 'room_list' && $exitType ne 'room_list') {

            foreach my $destRoomNum ($exitObj->randomDestList) {

                my $destRoomObj = $self->ivShow('modelHash', $destRoomNum);
                if ($destRoomObj && $destRoomObj->ivExists('randomExitHash', $exitObj->number)) {

                    $destRoomObj->ivDelete($exitObj->number);
                }
            }

            $exitObj->ivEmpty('randomDestList');
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the objects
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub restoreRandomExit {

        # Called by GA::Win::Map->restoreRandomExitCallback
        # Converts an existing random exit into an incomplete exit
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Local variables
        my $roomObj;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restoreRandomExit', @_);
        }


        # Remove the defined list of destination rooms (for random type 'room_list'), if set
        foreach my $destRoomNum ($exitObj->randomDestList) {

            my $destRoomObj = $self->ivShow('modelHash', $destRoomNum);
            if ($destRoomObj && $destRoomObj->ivExists('randomExitHash', $exitObj->number)) {

                $destRoomObj->ivDelete($exitObj->number);
            }

            $exitObj->ivEmpty('randomDestList');
        }

        # Convert the exit
        $exitObj->ivPoke('randomType', 'none');

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            $roomObj = $self->ivShow('modelHash', $exitObj->parent);

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub setSuperRegionExit {

        # Called by GA::Win::Map->markSuperExitCallback
        # Converts a region exit into a super-region exit (resetting other IVs as necessary)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The GA::Obj::Exit to convert
        #   $exclusiveFlag  - Set to TRUE if this should be the only super-region exit leading from
        #                       its parent region to its destination region. Set to FALSE if other
        #                       super-region exits between the two regions (if any) can be left as
        #                       super-region exits
        #
        # Return values
        #   'undef' on improper arguments, if the specified exit is already a super-region exit or
        #       if it is not a region exit at all
        #   1 otherwise

        my ($self, $session, $updateFlag, $exitObj, $exclusiveFlag, $check) = @_;

        # Local variables
        my (
            $roomObj, $regionmapObj, $destRegionNum,
            @redrawList,
            %regionExitHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $exitObj
            || ! defined $exclusiveFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setSuperRegionExit', @_);
        }

        # Check that the specified exit isn't already a super-region exit, and that it is a region
        #   exit
        if ($exitObj->superFlag || ! $exitObj->regionFlag) {

            return undef;
        }

        # Get the parent regionmap
        $roomObj = $self->ivShow('modelHash', $exitObj->parent);
        $regionmapObj = $self->findRegionmap($roomObj->parent);

        # Import the regionmap's hash of region exits (for quick lookup)
        %regionExitHash = $regionmapObj->regionExitHash;

        # Get $exitObj's destination region (stored in the regionmap)
        $destRegionNum = $regionExitHash{$exitObj->number};

        # If $exclusiveFlag is set, any super-region exits in this regionmap leading to the same
        #   destination region must be converted to non-super region exits
        if ($exclusiveFlag) {

            OUTER: foreach my $otherExitNum (keys %regionExitHash) {

                my ($otherExitObj, $otherDestRegionNum);

                $otherExitObj = $self->ivShow('exitModelHash', $otherExitNum);
                $otherDestRegionNum = $regionExitHash{$otherExitNum};

                # Ignore the entry for $exitObj itself, all normal region exits and any exit which
                #   has a different destination region
                if (
                    $otherExitNum != $exitObj->number
                    && $otherExitObj->superFlag
                    && $destRegionNum == $otherDestRegionNum
                ) {
                    # This super-region exit must be converted to a normal region exit
                    $otherExitObj->ivPoke('superFlag', FALSE);
                    # The user wasn't directly responsible for this change
                    $otherExitObj->ivPoke('notSuperFlag', FALSE);

                    # Remove any region paths (stored in ->regionPathHash and
                    #   ->safeRegionPathHash) which were using this exit
                    INNER: foreach my $exitString ($regionmapObj->ivKeys('regionPathHash')) {

                        my $pathObj = $regionmapObj->ivShow('regionPathHash', $exitString);

                        if (
                            $pathObj->startExit == $exitObj->number
                            || $pathObj->stopExit == $exitObj->number
                        ) {
                            # (Update both ->regionPathHash and ->safeRegionPathHash)
                            $regionmapObj->removePaths($exitString);
                        }
                    }

                    # Any region paths using the exit will have to be updated
                    $self->ivAdd('updatePathHash', $otherExitObj->number, $regionmapObj->name);
                    $self->ivAdd('updateBoundaryHash', $otherExitObj->number, $regionmapObj->name);

                    # Mark the exit's parent room to be re-drawn
                    push (@redrawList, 'room', $self->ivShow('modelHash', $otherExitObj->parent));
                }
            }
        }

        # Now convert $exitObj to a super-region exit
        $exitObj->ivPoke('superFlag', TRUE);
        $exitObj->ivPoke('notSuperFlag', FALSE);

        # Create region paths between this super-region exit and every other
        #   super-region exit in the region
        $self->connectRegionExits(
            $session,
            $regionmapObj,
            $roomObj,
            $exitObj,
        );

        # Mark the exit's parent room to be re-drawn (if allowed)
        push (@redrawList, 'room', $self->ivShow('modelHash', $exitObj->parent));

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the objects
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub restoreSuperRegionExit {

        # Called by GA::Win::Map->restoreSuperExitCallback
        # Converts an existing super-region exit into a normal region exit
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #
        # Return values
        #   'undef' on improper arguments or if the specified exit isn't a super-region exit
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Local variables
        my (
            $roomObj, $regionObj, $regionmapObj,
            @redrawList,
        );

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restoreSuperRegionExit', @_);
        }

        # Check that the specified exit is a super-region exit
        if (! $exitObj->superFlag) {

            return undef;
        }

        # Get the parent regionmap
        $roomObj = $self->ivShow('modelHash', $exitObj->parent);
        $regionmapObj = $self->findRegionmap($roomObj->parent);

        # Convert the exit to a normal region exit
        $exitObj->ivPoke('superFlag', FALSE);
        # The user was directly responsible for this change
        $exitObj->ivPoke('notSuperFlag', TRUE);

        # Remove any region paths (stored in ->regionPathHash and
        #   ->safeRegionPathHash) which were using this exit
        foreach my $exitString ($regionmapObj->ivKeys('regionPathHash')) {

            my $pathObj = $regionmapObj->ivShow('regionPathHash', $exitString);

            if (
                $pathObj->startExit == $exitObj->number
                || $pathObj->stopExit == $exitObj->number
            ) {
                # (Update both ->regionPathHash and ->safeRegionPathHash)
                $regionmapObj->removePaths($exitString);
            }
        }

        # Any region paths using the exit will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionmapObj->name);
        $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionmapObj->name);

        # Mark the exit's parent room to be re-drawn
        push (@redrawList, 'room', $self->ivShow('modelHash', $exitObj->parent));

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the objects
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub setImpassableExit {

        # Called by $self->setExitOrnament (should not be called by anything else)
        # Converts any kind of exit into an (incomplete) impassable or mystery exit
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit to convert
        #   $type       - 'impass' or 'mystery'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $type, $check) = @_;

        # Local variables
        my (
            $destRoomObj, $regionFlag, $roomObj, $regionObj,
            @redrawList,
        );

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setImpassableExit', @_);
        }

        $regionFlag = $exitObj->regionFlag;

        # If the exit already has a destination room, mark it for redrawing
        if ($exitObj->destRoom) {

            $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
            push (@redrawList, 'room', $destRoomObj);
        }

        # If the exit has a twin, it must be abandoned
        if ($exitObj->twinExit) {

            $self->abandonTwinExit(
                FALSE,      # Don't update Automapper windows yet
                $exitObj,
            );
        }

        # The same applies if the exit has a shadow exit
        if ($exitObj->shadowExit) {

            $self->abandonShadowExit($exitObj);
        }

        # Update the destination room (if any)
        if ($destRoomObj) {

            if ($destRoomObj->ivExists('uncertainExitHash', $exitObj->number)) {

                $destRoomObj->ivDelete('uncertainExitHash', $exitObj->number);
            }

            if ($destRoomObj->ivExists('oneWayExitHash', $exitObj->number)) {

                $destRoomObj->ivDelete('oneWayExitHash', $exitObj->number);
            }
        }

        # Update the exit. The ->exitOrnament IV is set by the calling function
        $exitObj->ivPoke('brokenFlag', FALSE);
        $exitObj->ivPoke('bentFlag', FALSE);
        $exitObj->ivEmpty('bendOffsetList');

        $exitObj->ivPoke('regionFlag', FALSE);
        $self->cancelExitTag(
            FALSE,              # Don't update Automapper windows yet
            $exitObj,
        );

        $exitObj->ivPoke('randomType', 'none');
        $exitObj->ivUndef('destRoom');
        $exitObj->ivPoke('oneWayFlag', FALSE);
        $exitObj->ivPoke('oneWayDir', undef);
        $exitObj->ivPoke('retraceFlag', FALSE);
        if ($type eq 'impass') {

            # (There is no exit state corresponding to a mystery exit)
            $exitObj->ivPoke('exitState', 'impass');
        }

        # If there is a twin exit, the call to ->abandonTwinExit has already updated
        #   $self->updatePathHash/->updateBoundaryHash; otherwise, we need to update them now
        if (! $exitObj->twinExit) {

            # Find the parent region
            $roomObj = $self->ivShow('modelHash', $exitObj->parent);
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);
            # Any region paths using the exit will have to be updated
            $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
            if ($regionFlag) {

                $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
            }
        }

        # Mark the exit's parent room to be redawn (if allowed)
        push (@redrawList, 'room', $self->ivShow('modelHash', $exitObj->parent));

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the objects
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub setExitOrnament {

        # Can be called by anything (especially by $self->setMultipleOrnaments)
        # Sets (or resets) the exit's ornament . Optionally sets (or resets) the ornament of the
        #   twin exit (if there is one) to match
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The exit object to modify
        #
        # Optional arguments
        #   $type       - The exit ornament type, one of the permitted values for
        #                   GA::Obj::Exit->exitOrnament ('none', 'break', 'pick', 'lock', 'open',
        #                   'impass', 'mystery'). If 'undef', the value 'none' is set
        #   $twinFlag   - If set to TRUE, the twin exit's ornament (if there is a twin exit) is set
        #                   to match
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $type, $twinFlag, $check) = @_;

        # Local variables
        my (
            $regionFlag, $twinExitObj, $twinRegionFlag, $roomObj, $regionObj, $twinRoomObj,
            $twinRegionObj,
        );

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $exitObj
            || (
                defined $type && $type ne 'none' && $type ne 'break' && $type ne 'pick'
                && $type ne 'lock' && $type ne 'open' && $type ne 'impass' && $type ne 'mystery'
            ) || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setExitOrnament', @_);
        }

        $regionFlag = $exitObj->regionFlag;

        # Set the twin exit object now (if needed), because the call to ->setImpassableExit
        #   abandons the twin
        if ($twinFlag && $exitObj->twinExit) {

            $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
            $twinRegionFlag = $twinExitObj->regionFlag;
        }

        # Set (or reset) the IV
        if (! defined $type) {
            $exitObj->ivPoke('exitOrnament', 'none');
        } else {
            $exitObj->ivPoke('exitOrnament', $type);
        }

        # Update impassable/mystery exit settings
        if ($type && ($type eq 'impass' || $type eq 'mystery')) {

            # Convert this exit into an incomplete impassable exit
            $self->setImpassableExit(
                FALSE,      # Don't update Automapper windows yet
                $exitObj,
                $type,
            );

        } elsif ($exitObj->exitState eq 'impass') {

            # The exit's state is no longer impassable
            $exitObj->ivPoke('exitState', 'normal');       # State not known
        }

        # The call to ->setImpassableExit updates ->updatePathHash and ->updateBoundaryHash. If it
        #   was not called, those IVs must be updated now
        if (! $type || $type ne 'impass') {

            # Find the parent region
            $roomObj = $self->ivShow('modelHash', $exitObj->parent);
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);
            # Update the hashes
            $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
            if ($exitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
            }
        }

        # Reset the IVs on the twin exit, if necessary
        if ($twinExitObj) {

            $twinExitObj->ivPoke('exitOrnament', $exitObj->exitOrnament);

            if ($type && ($type eq 'impass' || $type eq 'mystery')) {

                # Convert this exit into an incomplete impassable exit
                $self->setImpassableExit(
                    FALSE,      # Don't update Automapper windows yet
                    $twinExitObj,
                    $type,
                );

            } elsif ($twinExitObj->exitState eq 'impass') {

                # The exit's state is no longer impassable
                $twinExitObj->ivPoke('exitState', 'normal');       # State not known
            }

            if (! $type || ($type ne 'impass' && $type ne 'mystery')) {

                # The call to ->setImpassableExit updates ->updatePathHash and ->updateBoundaryHash.
                #   If it was not called, those IVs must be updated now
                # Find the parent region
                $twinRoomObj = $self->ivShow('modelHash', $twinExitObj->parent);
                $twinRegionObj = $self->ivShow('modelHash', $twinRoomObj->parent);
                # Update the hashes
                $self->ivAdd('updatePathHash', $twinExitObj->number, $twinRegionObj->name);
                if ($twinExitObj->regionFlag) {

                    $self->ivAdd('updateBoundaryHash', $twinExitObj->number, $twinRegionObj->name);
                }
            }
        }

        if ($updateFlag) {

            # Mark this exit (and its twin, if there is one) to be redrawn in every Automapper
            #   window using this world model
            $self->updateMapExit($exitObj, $twinExitObj);
        }

        return 1;
    }

    sub setMultipleOrnaments {

        # Called by GA::Win::Map->exitOrnamentCallback
        # Sets ornaments for one or more exits
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #
        # Optional arguments
        #   $type           - The exit ornament type, one of the permitted values for
        #                       GA::Obj::Exit->exitOrnament ('none', 'break', 'pick', 'lock',
        #                       'open', 'impass', 'mystery'). If 'undef', the value 'none' is set
        #   @exitList       - A list of exit objects to modify. If the list is empty, no exits are
        #                       modified
        #
        # Return values
        #   'undef' on improper arguments or if @exitList is empty
        #   1 otherwise

        my ($self, $updateFlag, $type, @exitList) = @_;

        # Local variables
        my (
            @redrawList,
            %roomHash,
        );

        # Check for improper arguments
        if (! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setMultipleOrnaments', @_);
        }

        # An exit's twin exit can be reset during the ornament-setting process, so compile a list of
        #   rooms to redraw first
        if ($updateFlag) {

            foreach my $exitObj (@exitList) {

                my $twinExitObj;

                # Mark this room as needing to be redrawn (if allowed), adding it to a hash to
                #   eliminate duplicates
                $roomHash{$exitObj->parent} = $self->ivShow('modelHash', $exitObj->parent);
                # If the exit has a twin exit, its parent must also be marked to be redrawn (e.g.
                #   when we take a two-way exit and modify one of the twins to an impassable exit,
                #   the other one must be redrawn, two)
                if ($exitObj->twinExit) {

                    $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
                    $roomHash{$twinExitObj->parent}
                        = $self->ivShow('modelHash', $twinExitObj->parent);
                }
            }
        }

        foreach my $exitObj (@exitList) {

            # Reset or set the exit's ornament IVs (and reset/set the twin exit's ornament IVs to
            #   match, if the appropriate flag is set)
            $self->setExitOrnament(
                FALSE,                          # Don't update Automapper windows yet
                $exitObj,
                $type,                            # May be 'undef'
                $self->setTwinOrnamentFlag,
            );
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $roomObj (values %roomHash) {

                push (@redrawList, 'room', $roomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub setAssistedMove {

        # Called by GA::Win::Map->addExitCallback and ->setAssistedMoveCallback
        # Adds or removes an assisted move to/from a specified exit object
        #
        # Expected arguments
        #   $exitObj        - The GA::Obj::Exit to be modified
        #   $profile        - The name of a profile. When it's a current profile, this assisted move
        #                       is available to the automapper object code
        #
        # Optional arguments
        #   $cmdSequence    - A sequence of one or more world commands (separated by the usual
        #                       command separator) that comprise the assisted move, e.g.
        #                       'north;open door;east'. If 'undef' or an empty string, the assisted
        #                       move for $profile is removed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $profile, $cmdSequence, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || ! defined $profile || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setAssistedMove', @_);
        }

        # Update the exit object
        if (! defined $cmdSequence || $cmdSequence eq '') {
            $exitObj->ivDelete('assistedHash', $profile);
        } else {
            $exitObj->ivAdd('assistedHash', $profile, $cmdSequence);
        }

        return 1;
    }

    sub modifyIncomingExits {

        # Called by GA::Win::Map->addExitCallback
        # After the new exit is added, checks the parent room's list of incoming exits. Any incoming
        #   exits whose map direction, ->mapDir, is the opposite of the new exit's map direction
        #   must be converted to uncertain exits
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $roomObj        - The new exit's parent room
        #   $exitObj        - The new GA::Obj::Exit object
        #
        # Return values
        #   'undef' on improper arguments or if no incoming exits are converted
        #   1 otherwise

        my ($self, $session, $updateFlag, $roomObj, $exitObj, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $roomObj || ! defined $exitObj
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->modifyIncomingExits', @_);
        }

        # Check each incoming exit in turn
        foreach my $incomingNum ($roomObj->ivKeys('oneWayExitHash')) {

            my ($incomingExitObj, $oppDir, $incomingRoomObj, $incomingRegionObj);

            $incomingExitObj = $self->ivShow('exitModelHash', $incomingNum);

            # Only check allocated exits...
            if (
                $incomingExitObj->drawMode eq 'primary'
                || $incomingExitObj->drawMode eq 'perm_alloc'
            ) {
                # Get the opposite direction of the incoming exit
                $oppDir = $axmud::CLIENT->ivShow('constOppDirHash', $incomingExitObj->dir);
                if ($oppDir && $exitObj->mapDir && $oppDir eq $exitObj->dir) {

                    # Special case: A-O-B, where O is a gap, and B has 1-way exit pointing at A; if
                    #   we put a room at location O, and connect A and O, the exit from B should
                    #   be drawn as a broken exit
                    if (
                        ! $incomingExitObj->regionFlag
                        && ! $self->checkRoomAlignment($session, $incomingExitObj)
                    ) {
                        $self->setBrokenExit($updateFlag, $incomingExitObj);
                    }

                    # Convert the incoming exit into an uncertain exit
                    $incomingExitObj->ivPoke('oneWayFlag', FALSE);
                    $incomingExitObj->ivPoke('oneWayDir', undef);
                    # Remove the entry from one hash, and add it the other
                    $roomObj->ivDelete('oneWayExitHash', $incomingExitObj->number);
                    $roomObj->ivAdd(
                        'uncertainExitHash',
                        $incomingExitObj->number,
                        $exitObj->number,
                    );

                    # If the incoming exit had any bends, remove them
                    $incomingExitObj->ivEmpty('bendOffsetList');

                    # Find the incoming exit's parent region
                    $incomingRoomObj = $self->ivShow('modelHash', $incomingExitObj->parent);
                    $incomingRegionObj = $self->ivShow('modelHash', $incomingRoomObj->parent);
                    # Any region paths using the exit will have to be updated
                    $self->ivAdd(
                        'updatePathHash',
                        $incomingExitObj->number,
                        $incomingRegionObj->name,
                    );

                    if ($incomingExitObj->regionFlag) {

                        $self->ivAdd(
                            'updateBoundaryHash',
                            $incomingExitObj->number,
                            $incomingRegionObj->name,
                        );
                    }

                    if ($updateFlag) {

                        # Mark this incoming exit to be redrawn in every Automapper window using
                        #   this world model
                        $self->updateMapExit($incomingExitObj);
                    }

                    # Return 1 to show that an exit was modified
                    return 1;
                }
            }
        }

        # No exits were modified
        return undef;
    }

    sub changeShadowExitDir {

        # Called by GA::Win::Map->changeDirCallback
        # When the user tries to change the direction of an exit that's been allocated a shadow
        #   exit, the 'change direction' operation merely reassigns it as an unallocated exit
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $roomObj        - The exit's parent room
        #   $exitObj        - The GA::Obj::Exit object to be modified
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $updateFlag, $roomObj, $exitObj, $check) = @_;

        # Local variables
        my $regionObj;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $roomObj || ! defined $exitObj
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->changeShadowExitDir', @_);
        }

        # Update the exit's IVs
        $exitObj->ivPoke('drawMode', 'temp_alloc');
        $exitObj->ivUndef('shadowExit');
        $exitObj->ivUndef('mapDir');

        # Allocate a primary direction (using the sixteen cardinal directions, but not 'up' or
        #   'down')
        $self->allocateCardinalDir($session, $roomObj, $exitObj);

        # Find the parent region
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        # Any region paths using the exit will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        if ($updateFlag) {

            # Mark this incoming exit to be redrawn in every Automapper window using this world
            #   model
            $self->updateMapExit($exitObj);
        }

        return 1;
    }

    sub changeExitDir {

        # Called by GA::Win::Map->changeDirCallback
        # Changes an exit's direction
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $roomObj        - The exit's parent room
        #   $exitObj        - The GA::Obj::Exit object to be modified
        #   $dir            - The exit's new (nominal) direction, stored in ->dir
        #
        # Optional arguments
        #   $mapDir         - The exit's new map direction, stored in ->mapDir. If not specified, a
        #                       map direction is allocated (if possible)
        #
        # Return values
        #   'undef' on improper arguments or if the exit's direction can't be changed
        #   1 otherwise

        my ($self, $session, $updateFlag, $roomObj, $exitObj, $dir, $mapDir, $check) = @_;

        # Local variables
        my (
            $twinExitObj, $regionObj,
            @dirList, @sortedList, @redrawList,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $roomObj || ! defined $exitObj
            || ! defined $dir || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->changeExitDir', @_);
        }

        # If $mapDir was specified and an existing exit already uses that map direction, we can't
        #   modify the specified exit
        if ($mapDir) {

            foreach my $number ($roomObj->ivValues('exitNumHash')) {

                my $otherExitObj = $self->ivShow('exitModelHash', $number);

                if ($otherExitObj && $otherExitObj->mapDir && $otherExitObj->mapDir eq $mapDir) {

                    return undef;
                }
            }
        }

        # Modify the exit object and its parent room object

        # Update the exit's ->dir
        $roomObj->ivDelete('exitNumHash', $exitObj->dir);
        $exitObj->ivPoke('dir', $dir);
        $roomObj->ivAdd('exitNumHash', $dir, $exitObj->number);

        # Delete the equivalent entry in the room's ->sortedExitList
        @dirList = $roomObj->ivKeys('exitNumHash');
        @sortedList = $session->currentDict->sortExits(@dirList);
        $roomObj->ivPoke('sortedExitList', @sortedList);

        # Set the exit's ->mapDir
        if ($mapDir) {

            $exitObj->ivPoke('mapDir', $mapDir);

        } else {

            # Allocate the exit an appropriate map direction
            $self->allocateCardinalDir($session, $roomObj, $exitObj);
        }

        # Set the exit type (e.g. 'primaryDir', 'primaryAbbrev', etc)
        $exitObj->ivPoke(
            'exitType',
            $session->currentDict->ivShow('combDirHash', $exitObj->dir),
        );

        # Find the parent region
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        # Any region paths using the exit will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        # Check the parent room's exits; if any were previously unallocated exits which were
        #   allocated the shadow exit we've just modified, then we must also modify those exits
        OUTER: foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

            my $otherExitObj = $self->ivShow('exitModelHash', $exitNum);

            if (
                $otherExitObj->shadowExit
                && $otherExitObj->shadowExit == $exitObj->number
                && $otherExitObj->mapDir
                && $otherExitObj->mapDir ne $mapDir
            ) {
                # Assign the exit object a new map direction, matching its shadow's new map
                #   direction
                $otherExitObj->ivPoke('mapDir', $mapDir);

                # Find the parent room and region

                # Any region paths using the exit will have to be updated
                $self->ivAdd('updatePathHash', $otherExitObj->number, $regionObj->name);
                if ($otherExitObj->regionFlag) {

                    $self->ivAdd('updateBoundaryHash', $otherExitObj->number, $regionObj->name);
                }
            }
        }

        # Now, we need to check if the room has any more unallocated exits. If they've temporarily
        #   been assigned the primary direction 'undef', we must reallocate them
        OUTER: foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

            my $otherExitObj = $self->ivShow('exitModelHash', $exitNum);

            if (! defined $otherExitObj->mapDir && $otherExitObj->drawMode eq 'primary') {

                # Assign the exit object a new map direction (using the sixteen cardinal directions,
                #   but not 'up' or 'down'), if any are available
                $self->allocateCardinalDir($session, $roomObj, $otherExitObj);

                # Any region paths using the exit will have to be updated
                $self->ivAdd('updatePathHash', $otherExitObj->number, $regionObj->name);
                if ($otherExitObj->regionFlag) {

                    $self->ivAdd('updateBoundaryHash', $otherExitObj->number, $regionObj->name);
                }
            }
        }

        # Mark $roomObj to be redrawn (if allowed)
        push (@redrawList, 'room', $roomObj);

        # Now, if there are any incoming 1-way exits whose ->mapDir is now the opposite of
        #   the exit we've just modified, the incoming exit should be marked as an uncertain exit
        OUTER: foreach my $incomingExitNum ($roomObj->ivKeys('oneWayExitHash')) {

            my ($incomingExitObj, $oppDir);

            $incomingExitObj = $self->ivShow('exitModelHash', $incomingExitNum);

            # Only check allocated exits...
            if (
                $incomingExitObj->drawMode eq 'primary'
                || $incomingExitObj->drawMode eq 'perm_alloc'
            ) {
                # Get the opposite direction of the incoming exit
                $oppDir = $axmud::CLIENT->ivShow('constOppDirHash', $incomingExitObj->mapDir);
                if ($oppDir && $exitObj->mapDir && $oppDir eq $exitObj->mapDir) {

                    # Convert the incoming exit into an uncertain exit
                    $self->convertOneWayExit(
                        FALSE,      # Don't update Automapper windows yet
                        $incomingExitObj,
                        $roomObj,
                        $exitObj,
                    );

                    # Mark the incoming exit's parent room to be redrawn
                    push (
                        @redrawList,
                        'room',
                        $self->ivShow('modelHash', $incomingExitObj->parent),
                    );

                    last OUTER;
                }
            }
        }

        # Both the exit, and its twin exit (if there is one) must be checked for alignment. If
        #   they're no longer aligned, they must be marked as broken exits. If they are now aligned,
        #   their broken exit status must be removed
        # Don't bother checking if the exit is marked as a region exit
        if ($exitObj->destRoom && ! $exitObj->regionFlag) {

            # Get the twin exit object (if any)
            if ($exitObj->twinExit) {

                $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
                # Mark the twin exit's parent room to be redrawn
                push (
                    @redrawList,
                    'room',
                    $self->ivShow('modelHash', $twinExitObj->parent),
                );
            }

            if (! $self->checkRoomAlignment($session, $exitObj)) {

                # Mark this exit and the twin exit, if there is one, as broken exits
                $self->setBrokenExit(
                    FALSE,       # Don't update Automapper windows now
                    $exitObj,
                );

                if ($twinExitObj) {

                    $self->setBrokenExit(
                        FALSE,       # Don't update Automapper windows now
                        $twinExitObj,
                    );
                }

            } elsif ($exitObj->brokenFlag) {

                # The rooms are now aligned, so it's no longer a broken exit (don't need to call a
                #   separate function; there's only one IV to update)
                $exitObj->ivPoke('brokenFlag', FALSE);
                if ($twinExitObj) {

                    $twinExitObj->ivPoke('brokenFlag', FALSE);
                }
            }
        }

        # Redraw the room(s) (and their exits), if allowed
        if ($updateFlag) {

            $self->updateMaps(@redrawList);
        }

        return 1;
    }

    sub setExitIncomingDir {

        # Called by GA::Win::Map->setExitTwinCallback
        # Changes a one-way exit's incoming direction (the direction it is drawn close to its
        #   destination room)
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The GA::Obj::Exit object to be modified
        #   $dir            - The new incoming direction (should be a standard primary direction)
        #
        # Return values
        #   'undef' on improper arguments or if the exit's direction can't be changed
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $dir, $check) = @_;

        # Local variables
        my ($roomObj, $destRoomObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || ! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setExitIncomingDir', @_);
        }

        # Check that $exitObj is really one-way and that $dir is really a standard primary direction
        if (! $exitObj->oneWayFlag || ! $axmud::CLIENT->ivExists('constOppDirHash', $dir)) {

            return undef;

        } else {

            $exitObj->ivPoke('oneWayDir', $dir);

            # Redraw the exit's parent room and its destination room, if allowed
            if ($updateFlag) {

                # Get the exit's parent room and its destination room
                $roomObj = $self->ivShow('modelHash', $exitObj->parent);
                $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);

                $self->updateMaps(
                    'room', $roomObj,
                    'room', $destRoomObj,
                );
            }

            return 1;
        }
    }

    sub setExitMapDir {

        # Called by GA::Win::Map->allocateMapDirCallback
        # Sets an exit's map direction, ->mapDir, using a value specified by the user
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $roomObj        - The exit's parent room
        #   $exitObj        - The GA::Obj::Exit object to be modified
        #   $mapDir         - The exit's new map direction (a standard primary direction)
        #
        # Return values
        #   'undef' on improper arguments or if the exit's direction can't be changed
        #   1 otherwise

        my ($self, $session, $updateFlag, $roomObj, $exitObj, $mapDir, $check) = @_;

        # Local variables
        my (
            $customDir, $regionObj,
            @redrawList,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $roomObj || ! defined $exitObj
            || ! defined $mapDir || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setExitMapDir', @_);
        }

        # Update the selected exit and mark it as 'allocated'
        $exitObj->ivPoke('mapDir', $mapDir);
        # Mark the exit as 'allocated'
        $exitObj->ivPoke('drawMode', 'perm_alloc');
        # Any checked directions in the corresponding custom primary direction are destroyed
        $customDir = $session->currentDict->ivShow('primaryDirHash', $mapDir);
        if (defined $customDir) {

            $roomObj->ivDelete('checkedDirHash', $customDir);
        }

        # Find the parent region
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        # Any region paths using the exit will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        # Check the parent room to see if it has any more unallocated exits. If they've temporarily
        #   been assigned the same map direction as the map direction specified by the user,
        #   $mapDir, we must reallocate them
        OUTER: foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

            my $otherExitObj = $self->ivShow('exitModelHash', $exitNum);

            if (
                $otherExitObj->mapDir
                && $otherExitObj->mapDir eq $mapDir
                && (
                    $otherExitObj->drawMode eq 'temp_alloc'
                    || $otherExitObj->drawMode eq 'temp_unalloc'
                )
            ) {
                # Assign the exit object a new map direction (using the sixteen cardinal directions,
                #   but not 'up' or 'down'), if any are available
                $otherExitObj->ivUndef('mapDir');
                $self->allocateCardinalDir($session, $roomObj, $otherExitObj);

                # Any region paths using the exit will have to be updated
                $self->ivAdd('updatePathHash', $otherExitObj->number, $regionObj->name);
                if ($exitObj->regionFlag) {

                    $self->ivAdd('updateBoundaryHash', $otherExitObj->number, $regionObj->name);
                }

                # (Having found one matching exit, we don't need to check the others)
                last OUTER;
            }
        }

        # Mark $roomObj to be redrawn (if allowed)
        push (@redrawList, 'room', $roomObj);

        # Now, if there are any incoming 1-way exits whose ->mapDir is now the opposite of
        #   the exit we've just allocated, the incoming exit should be marked as an uncertain exit
        OUTER: foreach my $incomingExitNum ($roomObj->ivKeys('oneWayExitHash')) {

            my ($incomingExitObj, $oppDir);

            $incomingExitObj = $self->ivShow('exitModelHash', $incomingExitNum);

            # Only check allocated exits...
            if (
                $incomingExitObj->drawMode eq 'primary'
                || $incomingExitObj->drawMode eq 'perm_alloc'
            ) {
                # Get the opposite direction of the incoming exit
                $oppDir = $axmud::CLIENT->ivShow('constOppDirHash', $incomingExitObj->mapDir);
                if ($oppDir && $exitObj->mapDir && $oppDir eq $exitObj->mapDir) {

                    # Convert the incoming exit into an uncertain exit
                    $self->convertOneWayExit(
                        FALSE,      # Don't update Automapper windows yet
                        $incomingExitObj,
                        $roomObj,
                        $exitObj,
                    );

                    # Mark the incoming exit's parent room to be redrawn
                    push (@redrawList, $self->ivShow('modelHash', $incomingExitObj->parent));

                    last OUTER;
                }
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();

                # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
                $mapWin->restrictWidgets();
            }
        }

        return 1;
    }

    sub setExitShadow {

        # Called by GA::Win::Map->allocateShadowCallback
        # Sets an exit's shadow exit
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $roomObj        - The exit's parent room
        #   $exitObj        - The GA::Obj::Exit object to be modified
        #   $shadowExitObj  - The exit object which is $exitObj's new shadow exit
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $roomObj, $exitObj, $shadowExitObj, $check) = @_;

        # Local variables
        my $regionObj;

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $roomObj || ! defined $exitObj
            || ! defined $shadowExitObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setExitShadow', @_);
        }

        # Update the exit
        $exitObj->ivPoke('shadowExit', $shadowExitObj->number);
        # This exit has the same map direction as the shadow (will be set to 'undef' for
        #   unallocatable exits)
        $exitObj->ivPoke('mapDir', $shadowExitObj->mapDir);
        # Mark the exit as 'allocated'
        $exitObj->ivPoke('drawMode', 'perm_alloc');

        # Find the parent region
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        # Any region paths using the exit will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();

                # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
                $mapWin->restrictWidgets();
            }
        }

        return 1;
    }

    sub completeExits {

        # Called by GA::Win::Map->allocateShadowCallback
        # Given a list of exit objects, looking for uncertain exits which match an opposite
        #   incomplete exit. When a pair is found, converts them into two-way exits
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #
        # Optional arguments
        #   @exitList       - A list of GA::Obj::Exit objects. If an empty list, no exits are
        #                       modified
        #
        # Return values
        #   'undef' on improper arguments or if @exitList is empty
        #   1 otherwise

        my ($self, $session, $updateFlag, @exitList) = @_;

        # Local variables
        my (
            $dictObj, $regionFlag, $twinRegionFlag,
            @redrawList,
            %redrawHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->completeExits', @_);
        }

        # Don't do anything if @exitList is empty
        if (! @exitList) {

            return undef;
        }

        # Import the current dictionary
        $dictObj = $session->currentDict;

        # Check each exit in turn
        OUTER: foreach my $exitObj (@exitList) {

            my (
                $roomObj, $twinRoomObj, $twinExitObj, $oppDir, $regionObj, $twinRegionObj,
                @oppDirList,
            );

            if ($exitObj->destRoom && (! $exitObj->twinExit) && (! $exitObj->oneWayFlag)) {

                # It's an uncertain exit. Is there an incomplete exit in the opposite direction?

                # Get the blessed references of the uncertain exit's room...
                $roomObj = $self->ivShow('modelHash', $exitObj->parent);
                # ...and of the incomplete exit's room
                $twinRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);

                # Get the opposite direction
                $oppDir = $dictObj->ivShow('combOppDirHash', $exitObj->dir);
                # For secondary directions, $oppDir might be several words, separated by spaces
                #   (e.g. the scalar 'entrance in' might be the opposite of 'exit')
                # Split them into a list of words, e.g. ('entrance', 'in')
                @oppDirList = split(/\s/, $oppDir);

                INNER: foreach my $item (@oppDirList) {

                    if ($twinRoomObj->ivExists('exitNumHash', $item)) {

                        # Success! $exitObj is an uncertain exit, so get the twin exit object
                        $twinExitObj = $self->ivShow(
                            'exitModelHash',
                            $twinRoomObj->ivShow('exitNumHash', $item),
                        );

                        last INNER;
                    }
                }

                if ($twinExitObj) {

                    $regionFlag = $exitObj->regionFlag;
                    $regionObj = $self->ivShow('modelHash', $roomObj->parent);
                    $twinRegionFlag = $twinExitObj->regionFlag;
                    $twinRegionObj = $self->ivShow('modelHash', $twinRoomObj->parent);

                    # Connect the two rooms with twin exits
                    $exitObj->ivPoke('twinExit', $twinExitObj->number);
                    $twinExitObj->ivPoke('twinExit', $exitObj->number);
                    $twinExitObj->ivPoke('destRoom', $roomObj->number);

                    # If either room used to be an uncertain exit, tell the opposite room that it no
                    #   longer needs to keep track
                    if ($twinRoomObj->ivExists('uncertainExitHash', $exitObj->number)) {

                        $twinRoomObj->ivDelete('uncertainExitHash', $exitObj->number);
                    }

                    if ($roomObj->ivExists('uncertainExitHash', $twinExitObj->number)) {

                        $roomObj->ivDelete('uncertainExitHash', $twinExitObj->number);
                    }

                    # Any region paths using the exits will have to be updated
                    $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
                    if ($regionFlag || $exitObj->regionFlag) {

                        $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
                    }

                    $self->ivAdd('updatePathHash', $twinExitObj->number, $twinRegionObj->name);
                    if ($twinRegionFlag || $twinExitObj->regionFlag) {

                        $self->ivAdd(
                            'updateBoundaryHash',
                            $twinExitObj->number,
                            $twinRegionObj->name,
                        );
                    }

                    # Mark the parent rooms of both exits to be redrawn
                    $redrawHash{$roomObj->number} = $roomObj;
                    $redrawHash{$twinRoomObj->number} = $twinRoomObj;
                }
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag && %redrawHash) {

            foreach my $obj (values %redrawHash) {

                push (@redrawList, 'room', $obj);
            }

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the rooms
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();

                # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
                $mapWin->restrictWidgets();
            }
        }

        return 1;
    }

    sub checkBentExit {

        # Called by $self->setBrokenExit and ->connectRegionBrokenExit
        # When an exit is marked as a broken exit, this function decides whether its ->bentFlag
        #   should be set to TRUE or FALSE
        #
        # Expected arguments
        #   $exitObj        - The broken exit object to check
        #
        # Optional arguments
        #   $roomObj        - The exit's parent room, if known (if 'undef', this functions finds it)
        #   $destRoomObj    - The exit's destination room, if known (if 'undef', this function
        #                       finds it)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $roomObj, $destRoomObj, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkBentExit', @_);
        }

        # Get the parent and destination rooms, if not specified
        if (! $roomObj) {

            $roomObj = $self->ivShow('modelHash', $exitObj->parent);
        }

        if (! $destRoomObj) {

            $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
        }

        # If $self->drawBentExitsFlag is set - and if the exit's parent and destination rooms are on
        #   the same level - this exit should be drawn as a bent broken exit
        # (If ->bentFlag is already TRUE, because the exit was already a broken exit, dont change
        #   anything)
        if (! $exitObj->bentFlag) {

            if (
                $self->drawBentExitsFlag
                && $destRoomObj
                && $destRoomObj->zPosBlocks == $roomObj->zPosBlocks
            ) {
                $exitObj->ivPoke('bentFlag', TRUE);
            } else {
                $exitObj->ivPoke('bentFlag', FALSE);
                $exitObj->ivEmpty('bendOffsetList');
            }
        }

        return 1;
    }

    sub toggleBentExit {

        # Called by GA::Win::Map->enableExitsColumn
        # Toggles a broken exit between a normal and bent broken exit
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The broken exit object to toggle
        #
        # Return values
        #   'undef' on improper arguments or if $exitObj isn't a broken exit
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Local variables
        my (
            $twinExitObj,
            @redrawList,
        );

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleBentExit', @_);
        }

        if (! $exitObj->brokenFlag) {

            # Not a broken exit - nothing to do
            return undef;
        }

        # Get the twin exit (if there is one)
        if ($exitObj->twinExit) {

            $twinExitObj = $self->ivShow('exitModelHash', $exitObj->twinExit);
        }

        # Toggle the broken exit (and the twin broken exit, if there is one)
        if (! $exitObj->bentFlag) {

            $exitObj->ivPoke('bentFlag', TRUE);
            if ($twinExitObj) {

                $twinExitObj->ivPoke('bentFlag', TRUE);
            }

        } else {

            $exitObj->ivPoke('bentFlag', FALSE);
            $exitObj->ivEmpty('bendOffsetList');

            if ($twinExitObj) {

                $twinExitObj->ivPoke('bentFlag', FALSE);
                $twinExitObj->ivEmpty('bendOffsetList');
            }
        }

        # Both parent rooms must be redrawn
        push (@redrawList, 'room', $self->ivShow('modelHash', $exitObj->parent));
        if ($twinExitObj) {

            push (@redrawList, 'room', $self->ivShow('modelHash', $twinExitObj->parent));
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                # When an unbent broken exit is selected, the destination room is drawn a different
                #   colour. Get around the problems of making sure this colour isn't still used in
                #   any Automapper windows by unselecting any unselected objects
                $mapWin->setSelectedObj();

                # Redraw the rooms, which redraws the broken exits
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();

                # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
                $mapWin->restrictWidgets();
            }
        }

        return 1;
    }

    sub applyExitTag {

        # Called by $self->setRegionExit, $self->renameRegion, $self->connectRegionBrokenExit and
        #   GA::Win::Map->editExitTagCallback
        # For the specified region exit, checks whether we're allowed to add an exit tag and, if so,
        #   applies the exit tag and updates the parent regionmap
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The region exit object to modify
        #
        # Optional arguments
        #   $regionmapObj   - The exit's parent regionmap, if already known (otherwise, this
        #                       function finds it)
        #   $customText     - A string to use as the exit tag's text. If set to 'undef' or an empty
        #                       string, the standard string is useds
        #   $overrideFlag   - Set to TRUE when called by GA::Win::Map->editExitTagCallback and
        #                       $self->renameRegion; this object's ->updateExitTagFlag is not
        #                       consulted (set to FALSE, or 'undef', otherwise)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $regionmapObj, $customText, $overrideFlag, $check) = @_;

        # Local variables
        my ($roomObj, $regionObj, $destRoomObj, $destRegionObj, $newTag);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->applyExitTag', @_);
        }

        # Don't do anything if we're not allowed to automatically add exit tags, and don't reset an
        #   existing room tag (unless we're replacing an exit tag's standard text with some custom
        #   text supplied by the user)
        if (
            ($self->updateExitTagFlag && ! $exitObj->exitTag)
            || $overrideFlag
        ) {
            # Get the parent regionmap, if not specified
            if (! $regionmapObj) {

                $roomObj = $self->ivShow('modelHash', $exitObj->parent);
                $regionmapObj = $self->findRegionmap($roomObj->parent);
            }

            # Get the destination room's parent region
            $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
            $destRegionObj = $self->ivShow('modelHash', $destRoomObj->parent);

            # Apply the tag
            if ($customText) {
                $exitObj->ivPoke('exitTag', $customText);
            } else {
                $exitObj->ivPoke('exitTag', $self->getExitTagText($exitObj, $destRegionObj));
            }

            # Update the regionmap
            $regionmapObj->storeExitTag($exitObj);

            # Update any GA::Win::Map objects using this world model (if allowed)
            if ($updateFlag) {

                foreach my $mapWin ($self->collectMapWins()) {

                    # Redraw the exit
                    $mapWin->markObjs('exit', $exitObj);
                    $mapWin->doDraw();
                }
            }
        }

        return 1;
    }

    sub getExitTagText {

        # Called by $self->applyExitTag to get the text of the exit tag to apply to a particular
        #   exit
        # Also called by $self->renameRegion to compare a particular exit tag's text, which may have
        #   been modified by the user, to the default text that would be applied to the exit tag
        #
        # Expected arguments
        #   $exitObj        - The exit object to check
        #
        # Optional arguments
        #   $destRegionObj  - The GA::ModelObj::Region which is the exit's destination region (set
        #                       to 'undef' when called by ->renameRegion)
        #   $regionName     - A region name; the text returned is that which would be used, if the
        #                       exit were connected to the region (set to 'undef' when called by
        #                       ->applyExitTag)
        #
        # Return values
        #   'undef' on improper arguments
        #   The text of an exit tag otherwise

        my ($self, $exitObj, $destRegionObj, $regionName, $check) = @_;

        # Local variables
        my $text;

        # Check for improper arguments
        if (
            ! defined $exitObj
            || (! defined $destRegionObj && ! defined $regionName)
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->getExitTagText', @_);
        }

        # Set which region name to use. If $destRegionObj is set, we're using a real region name
        if (! $regionName) {

            $regionName = $destRegionObj->name;
        }

        # For exits drawn as 'up' or 'down', use those words in the tag
        if (
            $exitObj->mapDir
            && ($exitObj->mapDir eq 'up' || $exitObj->mapDir eq 'down')
        ) {
            $text = $exitObj->mapDir . ' to ' . $regionName;
        } else {
            $text = 'to ' . $regionName;
        }

        if ($exitObj->oneWayFlag) {

            $text .= ' (>)';
        }

        return $text;
    }

    sub cancelExitTag {

        # Called by several functions
        # For the specified exit, checks whether is has an exit tag and, if so, cancels the tag and
        #   updates the parent regionmap
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The exit object to modify
        #
        # Optional arguments
        #   $regionmapObj   - The exit's parent regionmap, if already known (otherwise, this
        #                       function finds it)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $regionmapObj, $check) = @_;

        # Local variables
        my ($roomObj, $regionObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->cancelExitTag', @_);
        }

        # Don't do anything if $exitObj doesn't have an exit tag
        if ($exitObj->exitTag) {

            # Get the parent regionmap, if not specified
            if (! $regionmapObj) {

                $roomObj = $self->ivShow('modelHash', $exitObj->parent);
                $regionmapObj = $self->findRegionmap($roomObj->parent);
            }

            # Cancel the tag
            $exitObj->ivPoke('exitTag', undef);
            $exitObj->ivPoke('exitTagXOffset', 0);
            $exitObj->ivPoke('exitTagYOffset', 0);

            # Update the regionmap
            $regionmapObj->removeExitTag($exitObj);

            # Update any GA::Win::Map objects using this world model (if allowed)
            if ($updateFlag) {

                foreach my $mapWin ($self->collectMapWins()) {

                    # Redraw the exit
                    $mapWin->markObjs('exit', $exitObj);
                    $mapWin->doDraw();
                }
            }
        }

        return 1;
    }

    sub resetExitTag {

        # Called by GA::Win::Map->resetExitOffsetsCallback
        # Restores an exit tag to its original position on the map
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The GA::Obj::Exit whose tag should be repositioned
        #
        # Return values
        #   'undef' on improper arguments or if @roomList is empty
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $check) = @_;

        # Local variables
        my $roomObj;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetExitTag', @_);
        }

        # Update the exit tag
        if ($exitObj->exitTag) {

            $exitObj->ivPoke('exitTagXOffset', 0);
            $exitObj->ivPoke('exitTagYOffset', 0);

            # Update any GA::Win::Map objects using this world model (if allowed)
            if ($updateFlag) {

                # Get the exit's parent room
                $roomObj = $self->ivShow('modelHash', $exitObj->parent);

                foreach my $mapWin ($self->collectMapWins()) {

                    # Redraw the exit
                    $mapWin->markObjs('exit', $exitObj);
                    $mapWin->doDraw();
                }
            }
        }

        return 1;
    }

    sub addExitBend {

        # Called by GA::Win::Map->addBendCallback
        # Adds a bend at the specified position on an exit (another call to this function is
        #   required to add the corresponding bend to the twin exit, if any)
        #
        # Expected arguments
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The GA::Obj::Exit to modify
        #   $startXPos, $startYPos
        #                   - Absolute coordinates of the start of the exit's bending section
        #   $clickXPos, $clickYPos
        #                   - The position of the mouse click, relative to the start of the bending
        #                       section of the exit
        #   $stopXPos, $stopYPos
        #                   - The end of the bending section of the exit, relative to the start of
        #                       the bending section
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $updateFlag, $exitObj, $startXPos, $startYPos, $clickXPos, $clickYPos,
            $stopXPos, $stopYPos, $check,
        ) = @_;

        # Local variables
        my (
            $shortRatio, $shortRatioPosn, $roomObj,
            @offsetList,
        );

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $exitObj || ! defined $startXPos
            || ! defined $startYPos || ! defined $clickXPos || ! defined $clickYPos
            || ! defined $stopXPos || ! defined $stopYPos || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addExitBend', @_);
        }

        # If the exit isn't already a bent broken exit, convert it to one ($self->setBrokenExit
        #   calls ->checkBentExit to set the exit object's ->bentFlag IV)
        if (! $exitObj->brokenFlag) {

            $self->setBrokenExit(
                FALSE,                   # Don't update Automapper windows yet
                $exitObj,
            );
        }

        # If the exit currently has no bends, then our job is fairly easy
        if (! $exitObj->bendOffsetList) {

            $exitObj->ivPush('bendOffsetList', $clickXPos, $clickYPos);

        } else {

            # GA::Obj::Exit->bendOffsetList is in the form (x, y, x, y...) where each (x, y) pair
            #   are the coordinates of a bend in the exit, relative to the start of the bending
            #   section
            # Start by adding a pair of coordinates at the start of the bending section,
            #   corresponding to the start of the bending section
            @offsetList = $exitObj->bendOffsetList;
            unshift(@offsetList, 0, 0);
            # Add another pair of coordinates, corresponding to the end of the bending section
            #   (relative to the start)
            push (@offsetList, $stopXPos, $stopYPos);

            # Now work out where the new bend should be placed. The position of the mouse click
            #   forms a triangle with the bends (including the start of the bending section) on
            #   either side:
            #                     C
            #                   -- --
            #                 --     --
            #               --         --
            #           A --------D-------- B
            #
            # ...where A and B are existing bends (one of which might be the start/end of the
            #   exit), and C is the position of the mouse click, very close to the line ADB. The
            #   mouse click should create a new bend at D
            # The new bend is created between the bends A and B, for which the line ACB is closest
            #   in length to ADB
            for (my $count = 0; $count < (scalar @offsetList - 2); $count += 2) {

                my ($aXPos, $aYPos, $bXPos, $bYPos, $ratio);

                $aXPos = $offsetList[$count];
                $aYPos = $offsetList[$count + 1];
                $bXPos = $offsetList[$count + 2];
                $bYPos = $offsetList[$count + 3];

                # Get the ratio ACB / ADB
                $ratio = $self->findBendRatio(
                    $aXPos, $aYPos,
                    $bXPos, $bYPos,
                    $clickXPos, $clickYPos,
                );

                if (! defined $shortRatio || $ratio < $shortRatio) {

                    # This is the first pair of bends, or the ratio for this pair of bends is the
                    #   smallest found so far
                    $shortRatio = $ratio;
                    $shortRatioPosn = $count + 2;   # New bend is placed after bend A
                }
            }

            # Add the bend
            $exitObj->ivSplice('bendOffsetList', ($shortRatioPosn - 2), 0, $clickXPos, $clickYPos);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Get the exit's parent room
            $roomObj = $self->ivShow('modelHash', $exitObj->parent);

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub findBendRatio {

        # Called by $self->addExitBend
        # In a triangle ABC, works out the ratio of the length ACB to the length AB (see the
        #   comments in the calling function)
        #
        # Expected arguments
        #   $aXPos, $aYPos          - Relative coordinates of point A
        #   $bXPos, $bYPos          - Relative coordinates of point B
        #   $cXPos, $cYPos          - Relative coordinates of point C
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the ratio ACB / AB

        my ($self, $aXPos, $aYPos, $bXPos, $bYPos, $cXPos, $cYPos, $check) = @_;

        # Local variables
        my ($lengthAB, $lengthAC, $lengthCB);

        # Check for improper arguments
        if (
            ! defined $aXPos || ! defined $aYPos || ! defined $bXPos || ! defined $bYPos
            || ! defined $cXPos || ! defined $cYPos || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->findBendRatio', @_);
        }

        # Find the lengths AB, AC and CB
        $lengthAB = sqrt( (($bXPos - $aXPos) ** 2) + (($bYPos - $aYPos) ** 2));
        $lengthAC = sqrt( (($cXPos - $aXPos) ** 2) + (($cYPos - $aYPos) ** 2));
        $lengthCB = sqrt( (($cXPos - $bXPos) ** 2) + (($cYPos - $bYPos) ** 2));

        # Return the ratio
        return ( abs ( ($lengthAC + $lengthCB) / $lengthAB));
    }

    sub adjustExitBend {

        # Called by GA::Win::Map->continueDrag
        # Called while dragging an exit bend in order to update the exit's IVs
        #
        # Expected arguments
        #   $exitObj        - The GA::Obj::Exit to update
        #   $index          - The index of the bend to adjust (the bend nearest to the start of the
        #                       exit's list of bend coordinates is numbered 0)
        #   $xPos, $yPos    - The bend's new coordinates, relative to the start of the bending
        #                       section of the exit
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $index, $xPos, $yPos, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $exitObj || ! defined $index || ! defined $xPos || ! defined $yPos
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->adjustExitBend', @_);
        }

        # GA::Obj::Exit->bendOffsetList is in the form (x, y, x, y...). Replace a single pair of
        #   (x, y) coordinates; e.g. if $index = 2, replace the 5th and 6th coordinates
        $index *= 2;
        $exitObj->ivSplice('bendOffsetList', $index, 2, $xPos, $yPos);

        return 1;
    }

    sub removeExitBend {

        # Called by GA::Win::Map->removeBendCallback
        # Removes a bend at the specified position on an exit (another call to this function is
        #   required to remove the corresponding bend from the twin exit, if any)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $updateFlag     - Flag set to TRUE if all Automapper windows using this world model
        #                       should be updated now, FALSE if not (in which case, they can be
        #                       updated later by the calling function, when it is ready)
        #   $exitObj        - The GA::Obj::Exit to modify
        #   $index          - The index of the bend to remove (the bend nearest to the start of the
        #                       exit's list of bend coordinates is numbered 0)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $updateFlag, $exitObj, $index, $check) = @_;

        # Local variables
        my $roomObj;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $exitObj || ! defined $index
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeExitBend', @_);
        }

        # GA::Obj::Exit->bendOffsetList is in the form (x, y, x, y...). Remove a single pair of
        #   (x, y) coordinates; e.g. if $index = 2, remove the 5th and 6th coordinates
        $index *= 2;
        $exitObj->ivSplice('bendOffsetList', $index, 2);

        # Check whether the exit's destination and departure rooms are aligned. If so, we can
        #   restore the exit to a non-broken status
        if (! $exitObj->bendOffsetList && $self->checkRoomAlignment($session, $exitObj)) {

            $self->restoreBrokenExit(
                $session,
                FALSE,              # Don't update automapper windows now
                $exitObj,
                TRUE,               # We've already called $self->checkRoomAlignment
            );
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Get the exit's parent room
            $roomObj = $self->ivShow('modelHash', $exitObj->parent);

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the room
                $mapWin->markObjs('room', $roomObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub updateExitBends {

        # Called by $self->moveRoomsLabels
        # When a room is dragged to a new position in the (same) regionmap, we must update the
        #   position of any exit bends
        #
        # Expected arguments
        #   $adjustXPos, $adjustYPos, $adjustZPos
        #                   - The direction of the room's movement, in gridblocks
        #   $regionmapObj   - The regionmap in which the exit's room has been moved
        #   $exitObj        - The GA::Obj::Exit whose bends must be updated
        #
        # Optional arguments
        #   $twinExitObj    - $exitObj's twin, if it has one ('undef' otherwise)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $adjustXPos, $adjustYPos, $adjustZPos, $regionmapObj, $exitObj, $twinExitObj,
            $check,
        ) = @_;

        # Local variables
        my (@offsetList, @newList);

        # Check for improper arguments
        if (
            ! defined $adjustXPos || ! defined $adjustYPos || ! defined $adjustZPos
            || ! defined $exitObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateExitBends', @_);
        }

        # If the room has moved up or down, remove bends altogether
        if ($adjustZPos) {

            $exitObj->ivEmpty('bendOffsetList');
            # (Also for the twin exit, if there is one)
            if ($twinExitObj) {

                $twinExitObj->ivEmpty('bendOffsetList');
            }

        # Otherwise, use the room's new position to update the bend's position
        # (We don't update the twin - if that room has also been dragged, this function will be
        #   called again to update its bends)
        } else {

            $adjustXPos *= $regionmapObj->blockWidthPixels;
            $adjustYPos *= $regionmapObj->blockHeightPixels;

            @offsetList = $exitObj->bendOffsetList;
            do {

                # @offsetList is in the form (x, y, x, y...)
                push (@newList, ((shift @offsetList) - $adjustXPos));
                push (@newList, ((shift @offsetList) - $adjustYPos));

            } until (! @offsetList);

            $exitObj->ivPoke('bendOffsetList', @newList);
        }

        return 1;
    }

    # Modify model objects - labels

    sub updateLabel {

        # Called by GA::Win::Map->setLabelCallback and ->promptConfigLabel
        # Sets the specified label's ->name IV (containing the text displayed) and redraw the label
        #   (if allowed)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $session    - The calling GA::Session
        #   $labelObj   - The GA::Obj::MapLabel to modify
        #   $name       - The new text for the label
        #
        # Optional arguments
        #   $style      - The new map label style (if 'undef', the label starts using its own IVs
        #                   to set a style)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $session, $labelObj, $name, $style, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $session || ! defined $labelObj || ! defined $name
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateLabel', @_);
        }

        # Update IVs
        $labelObj->ivPoke('name', $name);
        if (defined $style) {
            $labelObj->set_style($session, $style);
        } else {
            $labelObj->reset_style();
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw the label
                $mapWin->markObjs('label', $labelObj);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    # Room flag methods

    sub setupRoomFlags {

        # Called by $self->new to initialise the model's room filter and room flag IVs
        # Also called by $self->resetRoomFlags
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $count,
            @initList, @orderedList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupRoomFlags', @_);
        }

        # Set up ->roomFilterApplyHash, with no filters applied by default
        foreach my $filter ($axmud::CLIENT->constRoomFilterList) {

            $self->ivPoke('roomFilterApplyHash', $filter, FALSE);
        }

        # Create room flag objects, one for each room flag
        $count = 0;
        @initList = $axmud::CLIENT->constRoomFlagList;
        do {

            my ($name, $short, $filter, $colour, $descrip, $newObj);

            $count++;

            $name = shift @initList;
            $short = shift @initList;
            $filter = shift @initList;
            $colour = shift @initList;
            $descrip = shift @initList;

            $newObj = Games::Axmud::Obj::RoomFlag->new(
                $session,
                $name,
                FALSE,          # Not a custom room flag
            );

            if ($newObj) {

                $newObj->ivPoke('shortName', $short);
                $newObj->ivPoke('descrip', $descrip);
                $newObj->ivPoke('priority', $count);
                $newObj->ivPoke('filter', $filter);
                $newObj->ivPoke('colour', $colour);

                $self->ivAdd('roomFlagHash', $name, $newObj);
                push (@orderedList, $name);
            }

        } until (! @initList);

        $self->ivPoke('roomFlagOrderedList', @orderedList);

        # Operation complete
        return 1;
    }

    sub resetRoomFlags {

        # Called by GA::EditWin::WorldModel->roomFlags1Tab
        # Resets the world model's room flags to their default state, eliminating any custom room
        #   flags
        # Checks every room in the model, removing any room flags that no longer exist
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetRoomFlags', @_);
        }

        # Reset the IVs
        $self->setupRoomFlags($session);

        # Check every room in the model, eliminating custom room flags that no longer exist
        foreach my $roomObj ($self->ivValues('roomModelHash')) {

            foreach my $roomFlag ($roomObj->ivKeys('roomFlagHash')) {

                if (! $self->ivExists('roomFlagHash', $roomFlag)) {

                    $roomObj->ivDelete('roomFlagHash', $roomFlag);
                }
            }
        }

        return 1;
    }

    sub updateRoomFlags {

        # Called by GA::Obj::File->updateExtractedData in order to update the room flags stored in
        #   this world model to those used in a more recent version of Axmud
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            @initList,
            %newApplyHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRoomFlags', @_);
        }

        # Update $self->roomFilterApplyHash. Add any new filters, and remove any defunct filters
        #   (the latter will probably never happen, but there's no harm in checking)
        foreach my $filter ($axmud::CLIENT->constRoomFilterList) {

            if ($self->ivExists('roomFilterApplyHash', $filter)) {

                # Keep the current setting
                $newApplyHash{$filter} = $self->ivShow('roomFilterApplyHash', $filter);

            } else {

                # New filter
                $newApplyHash{$filter} = FALSE;
            }
        }

        $self->ivPoke('roomFilterApplyHash', %newApplyHash);

        # Update $self->roomFlagHash and ->roomFlagOrderedList. Add any new room flag objects, but
        #   don't remove any defunct room flags (as the rooms in this world model might be using
        #   them)
        @initList = $axmud::CLIENT->constRoomFlagList;
        do {

            my ($name, $short, $filter, $colour, $descrip, $count, $index, $newObj);

            $name = shift @initList;
            $short = shift @initList;
            $filter = shift @initList;
            $colour = shift @initList;
            $descrip = shift @initList;

            if (! $self->ivExists('roomFlagHash', $name)) {

                # Go through the existing ordered list of room flags, and find the position of the
                #   last room flag using the same filter
                $count = 0;
                foreach my $name ($self->roomFlagOrderedList) {

                    my $oldObj;

                    $oldObj = $self->ivShow('roomFlagHash', $name);
                    $count++;

                    if ($oldObj->filter eq $filter) {

                        $index = $count;
                    }
                }

                if (! $index) {

                    # This room flag seems to be using a unique filter (for some reason). Insert
                    #   the new room flag at the end of the list
                    $index = scalar ($self->roomFlagOrderedList);
                }

                # Create a new room flag object
                $newObj = Games::Axmud::Obj::RoomFlag->new(
                    $session,
                    $name,
                    FALSE,          # Not a custom room flag
                );

                # Insert it at the specified position
                if ($newObj) {

                    $newObj->ivPoke('shortName', $short);
                    $newObj->ivPoke('descrip', $descrip);
                    $newObj->ivPoke('priority', $index + 1);
                    $newObj->ivPoke('filter', $filter);
                    $newObj->ivPoke('colour', $colour);

                    $self->ivAdd('roomFlagHash', $name, $newObj);
                    $self->ivSplice('roomFlagOrderedList', $index, 0, $name);

                    # Update every room flag object's ->priority IV
                    $count = 0;
                    foreach my $name ($self->roomFlagOrderedList) {

                        my $thisObj = $self->ivShow('roomFlagHash', $name);

                        $count++;
                        $thisObj->ivPoke('priority', $count);
                    }
                }
            }

        } until (! @initList);

        # Operation complete
        return 1;
    }

    sub addRoomFlag {

        # Called by GA::EditWin::WorldModel->roomFlags1Tab
        # Adds a new custom room flag and updates the priority list for all room flags
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $name       - The room flag name (max 16 characters, must be unique among room flag
        #                   names)
        #   $shortName  - The short name (max 2 characters; should ideally be unique among short
        #                   names, but that's not a hard rule)
        #   $descrip    - The room flag description (any text, but at least 1 character)
        #   $colour     - The colour used to draw the room, when this room flag is the highest-
        #                   priority room flag in the room. An RGB tag, e.g. '#ABCDEF' (case-
        #                   insensitive)
        #
        # Return values
        #   'undef' on improper arguments, if $name, $shortName and/or $descrip are not the right
        #       length, if a room flag called $name already exists or if $colour is not a valid RGB
        #       tag
        #   1 otherwise

        my ($self, $session, $name, $shortName, $descrip, $colour, $check) = @_;

        # Local variables
        my ($type, $lastMarker, $lastCustom, $priority, $newObj, $count);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $name || ! defined $shortName || ! defined $descrip
            || ! defined $colour || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRoomFlag', @_);
        }

        # Check the lengths of the text arguments
        if (
            length($name) < 1 || length($name) > 16
            || length($shortName) != 2
            || length($descrip) < 1
        ) {
            return undef;
        }

        # Check a room flag called $name doesn't already exist
        if ($self->ivExists('roomFlagHash', $name)) {

            return undef;
        }

        # Check $colour is a valid RGB tag
        ($type) = $axmud::CLIENT->checkColourTags($colour, 'rgb');
        if (! $type) {

            return undef;
        }

        # Decide the room flag's position in the priority list
        # Position it after the last 'custom' room flag or, if there are none, after the last
        #   'markers' room tag
        # (In the default list, all 'markers' room flags come first, followed by all 'custom' room
        #   flags)
        foreach my $roomFlagObj ($self->ivValues('roomFlagHash')) {

            if (
                $roomFlagObj->filter eq 'markers'
                && (! defined $lastMarker || $lastMarker < $roomFlagObj->priority)
            ) {
                $lastMarker = $roomFlagObj->priority;

            } elsif (
                $roomFlagObj->filter eq 'custom'
                && (! defined $lastCustom || $lastCustom < $roomFlagObj->priority)
            ) {
                $lastCustom = $roomFlagObj->priority;
            }
        }

        if (defined $lastCustom) {
            $priority = $lastCustom + 1;
        } elsif (defined $lastMarker) {
            $priority = $lastMarker + 1;
        } else {
            $priority = 1;                  # Failsafe - should never be used
        }

        # Create a new room flag object
        $newObj = Games::Axmud::Obj::RoomFlag->new(
            $session,
            $name,
            TRUE,           # Custom room flag
        );

        if ($newObj) {

            $self->ivAdd('roomFlagHash', $name, $newObj);

            # Set the object's IVs
            $newObj->ivPoke('shortName', $shortName);
            $newObj->ivPoke('descrip', $descrip);
            $newObj->ivPoke('priority', $priority);
            $newObj->ivPoke('filter', 'custom');
            $newObj->ivPoke('colour', $colour);

            # Insert it at the right position in the room flag priority list
            $self->ivSplice('roomFlagOrderedList', ($priority - 1), 0, $name);

            # Update every room flag object's ->priority IV
            $count = 0;
            foreach my $name ($self->roomFlagOrderedList) {

                my $thisObj = $self->ivShow('roomFlagHash', $name);

                $count++;
                $thisObj->ivPoke('priority', $count);
            }

            # Must redraw the menu in any automapper windows, so that the new room flag appears in
            #   them
            $self->updateMapMenuToolbars();
        }

        # Operation complete
        return 1;
    }

    sub deleteRoomFlag {

        # Called by GA::EditWin::WorldModel->roomFlags1Tab
        # Deletes custom room flag and updates the priority list for all room flags
        # (Room flags belonging to other filters can't be deleted)
        #
        # Expected arguments
        #   $name       - The room flag name to delete
        #
        # Return values
        #   'undef' on improper arguments, if the room flag doesn't exist or if it isn't a custom
        #       room flag
        #   1 otherwise

        my ($self, $name, $check) = @_;

        # Local variables
        my ($roomFlagObj, $count);

        # Check for improper arguments
        if (! defined $name) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteRoomFlag', @_);
        }

        # Check the flag exists and is a custom room flag
        $roomFlagObj = $self->ivShow('roomFlagHash', $name);
        if (! $roomFlagObj || $roomFlagObj->filter ne 'custom') {

            return undef;

        } else {

            $self->ivDelete('roomFlagHash', $name);

            # Remove it from the room flag priority list
            $self->ivSplice('roomFlagOrderedList', ($roomFlagObj->priority - 1), 1);

            # Update every room flag object's ->priority IV
            $count = 0;
            foreach my $name ($self->roomFlagOrderedList) {

                my $thisObj = $self->ivShow('roomFlagHash', $name);

                $count++;
                $thisObj->ivPoke('priority', $count);
            }

            # Must redraw the menu in any automapper windows, so that the old room flag no longer
            #   appears in them
            $self->updateMapMenuToolbars();
        }

        # Operation complete
        return 1;
    }

    sub toggleRoomFlags {

        # Called by GA::Win::Map->enableRoomsColumn_filterSubMenu
        # Toggles a room flag in one or more rooms. Redraws the rooms (if permitted) and
        #   recalculates the regionmap's paths (if necessary)
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $roomFlag   - The room flag to toggle (matches one of the keys in
        #                   $self->roomFlagHash)
        #
        # Optional arguments
        #   @roomList   - A list of room objects to update. If the list is empty, no flags are
        #                   toggled
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $updateFlag, $roomFlag, @roomList) = @_;

        # Local variables
        my (
            $hazardFlag,
            @redrawList,
            %regionHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag || ! defined $roomFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleRoomFlags', @_);
        }

        # For speed, work out now whether $roomFlag is one of the hazardous room flags, or not
        if ($axmud::CLIENT->ivExists('constRoomHazardHash', $roomFlag)) {

            $hazardFlag = TRUE;
        }

        # Update each room in turn
        foreach my $roomObj (@roomList) {

            my $listRef;

            # (All affected rooms may be redrawn shortly)
            push (@redrawList, 'room', $roomObj);

            if ($roomObj->ivExists('roomFlagHash', $roomFlag)) {

                # Unset the flag by deleting the key
                $roomObj->ivDelete('roomFlagHash', $roomFlag);

            } else {

                # Set the flag by adding the key
                $roomObj->ivAdd('roomFlagHash', $roomFlag);
            }

            if ($updateFlag) {

                # Reset the ->lastRoomFlag IV - it'll be set to the correct value (if any)
                #   when the room is redrawn in a moment
                $roomObj->ivUndef('lastRoomFlag');

            } else {

                # The room isn't going to be redrawn any time soon, so set the correct value of
                #   ->lastRoomFlag now
                $roomObj->ivPoke('lastRoomFlag', $roomFlag);
            }

            # Keep track of all the affected regions. Use a hash in the form
            #   ->regionHash{region_number} = reference_to_list_of_room_objects
            if (exists $regionHash{$roomObj->parent}) {

                $listRef = $regionHash{$roomObj->parent};
                push (@$listRef, $roomObj);

            } else {

                $regionHash{$roomObj->parent} = [$roomObj];
            }
        }

        # If the flag is one of the hazardous room flags, we need to re-calculate each regionmap's
        #   GA::Obj::RegionPath objects (paths between exits at the boundaries of the region)
        if ($hazardFlag) {

            foreach my $regionNum (keys %regionHash) {

                my ($regionmapObj, $listRef);

                $regionmapObj = $self->findRegionmap($regionNum);
                $listRef = $regionHash{$regionNum};

                $self->recalculateSafePaths(
                    $session,
                    $regionmapObj,
                    @$listRef,
                );
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Redraw affected rooms in this region
                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub getDefaultRoomFlag {

        # Can be called by anything
        # Quick and dirty method of accessing a room flag's default settings, as specified by
        #   GA::Client->constRoomFlagList
        # Finds the right settings, then creates a temporary room flag object (GA::Obj::RoomFlag) to
        #   store them, and returns the object
        # Note that custom room flags, added by the user, have no default settings and so this
        #   function returns 'undef'
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $name           - The name of a non-custom room flag
        #
        # Return values
        #   'undef' on improper arguments or if a non-custom or non-existent room flag name is
        #       specified
        #   Otherwise, returns a temporary room flag object whose IVs contain the default settings
        #       for that room flag

        my ($self, $session, $name, $check) = @_;

        # Local variables
        my (
            $count,
            @initList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getDefaultRoomFlag', @_);
        }

        $count = 0;
        @initList = $axmud::CLIENT->constRoomFlagList;
        do {

            my ($thisName, $short, $filter, $colour, $descrip, $tempObj);

            $count++;

            $thisName = shift @initList;
            $short = shift @initList;
            $filter = shift @initList;
            $colour = shift @initList;
            $descrip = shift @initList;

            if ($thisName eq $name) {

                # Create the temporary room flag object
                $tempObj = Games::Axmud::Obj::RoomFlag->new(
                    $session,
                    $name,
                    FALSE,          # Not a custom room flag
                );

                if ($tempObj) {

                    # These are the default settings for the room flag, including its default
                    #   position in the priority list
                    $tempObj->ivPoke('shortName', $short);
                    $tempObj->ivPoke('descrip', $descrip);
                    $tempObj->ivPoke('priority', $count);
                    $tempObj->ivPoke('filter', $filter);
                    $tempObj->ivPoke('colour', $colour);

                    return $tempObj;
                }
            }

        } until (! @initList);

        # No matching room flag found in the default list
        return undef;
    }

    sub getRoomFlagsInFilter {

        # Can be called by anything
        # Returns a list of room flags (names, not objects) belonging to the specified room filter
        # The list is sorted in priority order
        #
        # Expected arguments
        #   $filter     - The room filter name (one of the items in GA::Client->constRoomFilterList
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns the list of room flags, which might be empty (especially if the
        #       specified $filter is 'custom', and the user hasn't added any custom room flags yet)

        my ($self, $filter, $check) = @_;

        # Local variables
        my (@emptyList, @list, @sortedList, @returnList);

        # Check for improper arguments
        if (! defined $filter || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getRoomFlagsInFilter', @_);
            return @emptyList;
        }

        # Weed out all room flags without a matching ->filter
        foreach my $flagObj ($self->ivValues('roomFlagHash')) {

            if ($flagObj->filter eq $filter) {

                push (@list, $flagObj);
            }
        }

        # Sort by priority
        @sortedList = sort {$a->priority <=> $b->priority} (@list);

        # Convert room flag objects to room flag names
        foreach my $flagObj (@sortedList) {

            push (@returnList, $flagObj->name);
        }

        # Operation complete
        return @returnList;
    }

    sub getVisibleRoomFlags {

        # Can be called by anything
        # Returns a hash of room flags which should be visible in various windows, depending on the
        #   current value of $self->roomFlagShowMode
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise returns the hash (which might be empty), in the form
        #       $showHash{room_flag_name} = room_flag_object

        my ($self, $check) = @_;

        # Local variables
        my (%emptyHash, %showHash);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getVisibleRoomFlags', @_);
            return %emptyHash;
        }

        foreach my $roomFlagObj ($self->ivValues('roomFlagHash')) {

            if (
                $self->roomFlagShowMode eq 'default'
                || (
                    $self->roomFlagShowMode eq 'essential'
                    && (
                        $roomFlagObj->customFlag
                        || $axmud::CLIENT->ivExists('constRoomHazardHash', $roomFlagObj->name)
                    )
                ) || (
                    $self->roomFlagShowMode eq 'custom' && $roomFlagObj->customFlag
                )
            ) {
                $showHash{$roomFlagObj->name} = $roomFlagObj;
            }
        }

        # Operation complete
        return %showHash;
    }

    sub moveRoomFlag {

        # Can be called by anything, but mostly called by the world model's edit window
        # Moves the specified room flag to a new position in the priority list, updating IVs for
        #   all other room flags
        #
        # Expected arguments
        #   $name       - The name of the room flag to move
        #   $type       - The type of move: 'above' to move the room flag up one position, 'below'
        #                   to move it down one position, 'top' to move it to the top of the
        #                   priority list, 'bottom' to move it to the bottom of the priority list
        #
        # Return values
        #   'undef' on improper arguments or if the specified room flag object can't be found
        #   1 otherwise

        my ($self, $name, $type, $check) = @_;

        # Local variables
        my (
            $flagObj, $posn, $count,
            @priorityList,
        );

        # Check for improper arguments
        if (
            ! defined $name
            || ! defined $type
            || ($type ne 'above' && $type ne 'below' && $type ne 'top' && $type ne 'bottom')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->moveRoomFlag', @_);
        }

        # Get the corresponding room flag object
        $flagObj = $self->ivShow('roomFlagHash', $name);
        if (! $flagObj) {

            return undef;
        }

        # Import the current priority list
        @priorityList = $self->roomFlagOrderedList;
        # Work out the room flag's new position in that list
        if ($type eq 'above') {

            $posn = $flagObj->priority - 2;
            if ($posn < 0) {

                $posn = 0;
            }

        } elsif ($type eq 'below') {

            $posn = $flagObj->priority;
            if ($posn >= (scalar @priorityList)) {

                $posn = (scalar @priorityList) - 1;
            }

        } elsif ($type eq 'top') {

            $posn = 0;

        } elsif ($type eq 'bottom') {

            $posn = (scalar @priorityList) - 1;
        }

        # Remove the flag from that list...
        splice(@priorityList, ($flagObj->priority - 1), 1);
        # ...and insert it at its new position
        splice(@priorityList, $posn, 0, $flagObj->name);

        # Update IVs
        $self->ivPoke('roomFlagOrderedList', @priorityList);
        # Update every room flag object's ->priority IV
        $count = 0;
        foreach my $name (@priorityList) {

            my $thisObj = $self->ivShow('roomFlagHash', $name);

            $count++;
            $thisObj->ivPoke('priority', $count);
        }

        # Operation complete
        return 1;
    }

    sub removeRoomFlagInRegion {

        # Called by GA::Win::Map->removeRoomFlagsCallback
        # Removes a room flag from every room in an existing region, and redraws the affected rooms
        #
        # Expected arguments
        #   $regionmapObj   - The GA::Obj::Regionmap whose counts should be reset
        #   $roomFlag       - The room flag to remove (matches a key in $self->roomFlagHash)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of modified rooms (may be 0)

        my ($self, $regionmapObj, $roomFlag, $check) = @_;

        # Local variables
        my (
            $count,
            @redrawList,
        );

        # Check for improper arguments
        if (! defined $regionmapObj || ! defined $roomFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeRoomFlagInRegion', @_);
        }

        # Remove the room flag from any room in the specified region which uses it
        foreach my $roomNum ($regionmapObj->ivValues('gridRoomHash')) {

            my $roomObj = $self->ivShow('modelHash', $roomNum);

            if ($roomObj->ivExists('roomFlagHash', $roomFlag)) {

                $roomObj->ivDelete('roomFlagHash', $roomFlag);
                push (@redrawList, 'room', $roomObj);

                $count++;
            }
        }

        if ($count) {

            # Update each Automapper window (if any flags were actually removed)
            foreach my $mapWin ($self->collectMapWins()) {

                $mapWin->markObjs(@redrawList);
                $mapWin->doDraw();
            }
        }

        return $count;
    }

    # Other functions called by GA::Obj::Map and GA::Win::Map

    sub resetPainter {

        # Called by $self->new to create a painter object, or by any other function to reset the
        #   painter object, which is a non-model GA::ModelObj::Room
        # (The object is 'reset' by discarding the old non-model room object and replacing it with a
        #   new one)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the non-model room object created

        my ($self, $session, $check) = @_;

        # Local variables
        my $roomObj;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetPainter', @_);
        }

        # Create a new non-model room
        $roomObj = Games::Axmud::ModelObj::Room->new($session, 'painter', 'non_model');
        if ($roomObj) {

            $self->ivPoke('painterObj', $roomObj);
            return $roomObj;

        } else {

            $self->ivUndef('painterObj');
            return undef;
        }
    }

    sub compareRooms {

        # Called by GA::Obj::Map->useExistingRoom to compare the current location according to
        #   the Locator task (GA::Task::Locator->roomObj, a non-model room object), with the current
        #   location according to the automapper (which is in the world model)
        # Also called by GA::Obj::Map->autoCompareLocatorRoom, ->checkTempRandomReturn,
        #   GA::Cmd::LocateRoom->do for the same purpose
        #
        # Called by $self->mergeMap (or by any other function) to compare two room objects in the
        #   world model (ignoring the Locator task's room)
        #
        # How the rooms are compared depends on the values of various settings
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $modelRoomObj   - A GA::ModelObj::Room object somewhere in the world model
        #
        # Optional arguments
        #   $otherRoomObj   - When comparing two rooms in the world model, the other
        #                       GA::ModelObj::Room object. If 'undef', $modelRoomObj is compared
        #                       against the Locator task's non-model room object
        #   $darkFlag       - Set to TRUE when called by GA::Obj::Map->moveKnownDirSeen and
        #                       GA::Obj::Map->useExistingRoom, in which case the model room matches
        #                       any dark or unspecified rooms
        #   $strictFlag     - Set to TRUE when called by GA::Cmd::LocateRoom->do, in which case this
        #                       function is a little more strict; if $modelRoomObj has a room title
        #                       and/or verbose description but $otherRoomObj doesn't (or
        #                       vice-versa), they cannot be matches; titles and verbose descriptions
        #                       are also checked regardless of the settings of $self->matchTitleFlag
        #                       and ->matchDescripFlag. FALSE (or 'undef') otherwise
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form (result, error_message), where:
        #       - 'result' is set to 1 if the rooms match, or 'undef' if they don't (or if there is
        #           an error)
        #       - 'error_message' is a string to display on failure; otherwise 'error_message' is
        #           'undef'. Most 'error_message' strings refer to the Locator task, since that's
        #           what uses the error message; any other code calling this function (for example
        #           $self->mergeMap) should ignore the error message

        my ($self, $session, $modelRoomObj, $otherRoomObj, $darkFlag, $strictFlag, $check) = @_;

        # Local variables
        my (
            $taskObj, $taskFlag, $matchFlag,
            @emptyList, @patternList,
            %modelExitHash, %otherExitHash, %otherModHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $modelRoomObj || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->compareRooms', @_);
            return @emptyList;
        }

        if (! $otherRoomObj) {

            # Import the Locator task
            $taskObj = $session->locatorTask;
            # If the Locator task isn't running, or if it doesn't know the current location, the
            #   rooms aren't a match
            if (! $taskObj || ! $taskObj->roomObj) {

                return (undef, 'Lost because Locator doesn\'t exist or current location not known');
            }

            $otherRoomObj = $taskObj->roomObj;
            $taskFlag = TRUE;

            # Compare world's room vnums (if allowed)
            if (
                $self->matchVNumFlag
                && defined $modelRoomObj->ivShow('protocolRoomHash', 'vnum')
                && defined $otherRoomObj->ivShow('protocolRoomHash', 'vnum')
                && $modelRoomObj->ivShow('protocolRoomHash', 'vnum')
                        ne $otherRoomObj->ivShow('protocolRoomHash', 'vnum')
            ) {
                # The two rooms' vnums don't match
                return (undef, 'Lost because rooms\' world vnums don\'t match');
            }
        }

        # If $darkFlag is set, dark and unspecified rooms are a match for any room
        if (
            $darkFlag
            && ($otherRoomObj->unspecifiedFlag || $otherRoomObj->currentlyDarkFlag)
        ) {
            return (1, undef);  # No error message
        }

        # Compare the rooms' properties, taking into account the values of various flags

        # Compare room titles (if allowed)
        if (
            ($strictFlag || $self->matchTitleFlag)
            && $modelRoomObj->titleList
            && $otherRoomObj->titleList
        ) {
            $matchFlag = FALSE;

            OUTER: foreach my $modelTitle ($modelRoomObj->titleList) {

                foreach my $otherTitle ($otherRoomObj->titleList) {

                    if ($modelTitle eq $otherTitle) {

                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $matchFlag) {

                # The two rooms's titles don't match
                return (undef, 'Lost because rooms\' titles don\'t match');
            }

        } elsif ($strictFlag && $otherRoomObj->titleList && ! $modelRoomObj->titleList) {

            # The calling ';locateroom' ignores any error message, but we'll provide one anyway
            return (undef, 'Lost because room\'s title is unknown');
        }

        # Compare (verbose) descriptions (if allowed)
        if (
            ($strictFlag || $self->matchDescripFlag)
            && $modelRoomObj->descripHash
            && $otherRoomObj->descripHash
        ) {
            $matchFlag = FALSE;

            OUTER: foreach my $modelDescrip ($modelRoomObj->ivValues('descripHash')) {

                INNER: foreach my $otherDescrip ($otherRoomObj->ivValues('descripHash')) {

                    # Compare the entire verbose descriptions, if allowed
                    if (! $self->matchDescripCharCount) {

                        if ($modelDescrip eq $otherDescrip) {

                            $matchFlag = TRUE;
                            last OUTER;
                        }

                    # Otherwise, compare the first part of the verbose descriptions - namely, the
                    #   first $self->matchDescripCharCount characters
                    } elsif (
                        substr($modelDescrip, 0, $self->matchDescripCharCount)
                        eq substr ($otherDescrip, 0, $self->matchDescripCharCount)
                    ) {
                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $matchFlag) {

                # The two rooms's verbose descriptions don't match (well enough)
                return (
                    undef,
                    'Lost because rooms\' verbose descriptions don\'t match (well enough)',
                );
            }

        } elsif ($strictFlag && $otherRoomObj->descripHash && ! $modelRoomObj->descripHash) {

            # The calling ';locateroom' ignores any error message, but we'll provide one anyway
            return (undef, 'Lost because room\'s verbose description is unknown');
        }

        # Compare exits (if allowed)
        # For wilderness rooms, we don't check any exits that have been added to the map (since we
        #   assume the world has sent a room statement with no exit list)
        if (
            $self->matchExitFlag
            && ! $session->currentWorld->basicMappingFlag
            && $modelRoomObj->wildMode eq 'normal'
        ) {
            $matchFlag = FALSE;

            # Import hashes of exits, in the form
            #   $exitNumHash{direction} = exit_number_in_exit_model (model rooms)
            #   $exitNumHash{direction} = exit_object (non-model rooms)
            %modelExitHash = $modelRoomObj->exitNumHash;
            %otherExitHash = $otherRoomObj->exitNumHash;

            # If the Locator task found a duplicate exit, it may have converted it using the
            #   pattern specified by GA::Profile::World->duplicateReplaceString (e.g. it might have
            #   converted a duplicate 'east' exit into a 'swim east' exit)
            # Any such duplicate exits are marked hidden. Remove them from our considerations
            if ($taskFlag) {

                foreach my $dir (keys %otherExitHash) {

                    my $exitObj = $otherExitHash{$dir};
                    if ($exitObj->hiddenFlag) {

                        delete $otherExitHash{$dir};
                    }
                }
            }

            # From the latter hash, also remove any transient exits (those which appear from time to
            #   time in various locations, for example the entrance to a moving wagon)
            OUTER: foreach my $dir (keys %otherExitHash) {

                @patternList = $session->currentWorld->transientExitPatternList;
                if (@patternList) {

                    do {

                        my $pattern = shift @patternList;
                        my $destRoom = shift @patternList;

                        if ($dir =~ m/$pattern/) {

                            # A transient exit; don't compare it to the model room
                            next OUTER;
                        }

                    } until (! @patternList);
                }

                # Not a transient exit
                $otherModHash{$dir} = $otherExitHash{$dir};
            }

            %otherExitHash = %otherModHash;
            %otherModHash = ();

            # If comparing $modelRoomObj against the Locator task's current room, convert any
            #   relative directions in $otherModHash (e.g. if the character is facing 'west',
            #   convert the direction 'backward' into 'east')
            # Exception: don't convert a relative direction, like 'forward', if an exit in that
            #   direction literally exists in the world model (by default, when an exit in a
            #   relative direction is added to the world model, it's converted to a primary
            #   direction)
            if ($taskFlag) {

                foreach my $dir (keys %otherExitHash) {

                    my ($slot, $convertDir, $customDir);

                    $slot = $session->currentDict->convertRelativeDir($dir);
                    # $slot is in the range 0-7. Convert it into a standard primary direction
                    #   like 'north', depending on which way the character is currently facing
                    if (defined $slot && ! exists $modelExitHash{$dir}) {

                        $convertDir = $session->currentDict->rotateRelativeDir(
                            $slot,
                            $session->mapObj->facingDir,
                        );
                    }

                    if (defined $convertDir) {

                        $customDir = $session->currentDict->ivShow('primaryDirHash', $convertDir);
                        $otherModHash{$customDir} = $otherExitHash{$dir};

                    } else {

                        # Not a relative exit
                        $otherModHash{$dir} = $otherExitHash{$dir};
                    }
                }
            }

            # Compare the keys in both hashes. Delete matching exits from each hash; if there are
            #   any exits left (or missing), the rooms don't match
            OUTER: foreach my $dir (keys %modelExitHash) {

                my ($exitNum, $exitObj);

                $exitNum = $modelExitHash{$dir};
                $exitObj = $self->ivShow('exitModelHash', $exitNum);
                if ($exitObj && $exitObj->hiddenFlag) {

                    # The exit should exist here
                    delete $modelExitHash{$dir};
                    # The exit shouldn't exist here - delete it anyway, just in case
                    delete $otherModHash{$dir};

                    next OUTER;
                }

                if (exists $otherModHash{$dir}) {

                    # Exit exists in both hashes (and isn't hidden)
                    delete $modelExitHash{$dir};
                    delete $otherModHash{$dir};

                    next OUTER;
                }

                if ($exitObj->altDir) {

                    foreach my $otherDir (keys %otherModHash) {

                        if (index ($exitObj->altDir, $otherDir) > -1) {

                            # The exit should exist here
                            delete $modelExitHash{$dir};
                            # The other exit's alternative nominal direction exists here
                            delete $otherModHash{$otherDir};

                            next OUTER;
                        }
                    }
                }

                # Missing exit in $otherRoomObj, so the rooms don't match
                return (
                    undef,
                    'Lost because of missing exit (\'' . $dir . '\') in Locator task\'s'
                    . ' current room (automapper current room is #' . $modelRoomObj->number
                    . ', Locator room exits: ' . join(', ', $otherRoomObj->sortedExitList)
                    . ')',
                );
            }

            if (%otherModHash) {

                # Missing exit in the model's room, so the rooms don't match
                return (
                    undef,
                    'Lost because of missing exit(s) in the automapper\'s current room: '
                    . join(', ', keys %otherModHash) . ' (room #' . $modelRoomObj->number . ')',
                );
            }
        }

        # Compare source code paths (if allowed)
        if (
            $self->matchSourceFlag
            && $modelRoomObj->sourceCodePath
            && $otherRoomObj->sourceCodePath
            && $modelRoomObj->sourceCodePath ne $otherRoomObj->sourceCodePath
        ) {
            # The two rooms' source code paths don't match
           return (undef, 'Lost because rooms\' source code paths don\'t match');
        }

        # The rooms match
        return (1, undef);  # No error message
    }

    sub checkOppPrimary {

        # Called by $self->connectRooms, GA::Win::Map->restoreOneWayExitCallback and
        #   GA::Obj::Map->autoProcessNewRoom
        # Given a GA::Obj::Exit which has a destination room, see if the destination room has an
        #   exit which is drawn on the map in the opposite direction (and return it, if found)
        # If the exit object doesn't have a destination room, see if a proposed destination room
        #   supplied as an optional argument has an exit drawn on the map the opposite direction
        #
        # Expected arguments
        #   $exitObj        - The exit object leading to the destination room
        #
        # Optional arguments
        #   $destRoomObj    - The GA::ModelObj::Room which is the destination room (set to 'undef'
        #                       if the exit already has a destination room set)
        #
        # Return values
        #   'undef' on improper arguments or if an opposite exit can't be found
        #   Otherwise returns the blessed reference of the exit object which leads from the
        #       destination room back to the original room (drawn in an opposite direction to the
        #       one used by $exitObj)

        my ($self, $exitObj, $destRoomObj, $check) = @_;

        # Local variables
        my (
            $oppMapDir,
            @oppList,
            %oppHash,
        );

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkOppPrimary', @_);
        }

        # The exit's primary direction, as used to draw the exit on the map, is stored in ->mapDir.
        #   If this exit object doesn't have a ->mapDir set (because it's unallocatable), there's
        #   nothing we can do
        if (! $exitObj->mapDir) {

            return undef;
        }

        # Set the destination room, if not already set
        if (! $destRoomObj) {

            if (! $exitObj->destRoom) {

                # No destination room specified - so nothing we can do
                return undef;

            } else {

                $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
            }
        }

        # Get the opposite (standard primary) direction (e.g. convert 'north' to 'south')
        $oppMapDir = $axmud::CLIENT->ivShow('constOppDirHash', $exitObj->mapDir);

        # See if the destination room has an exit which leads back to the departure room in the
        #   opposite (primary) direction
        OUTER: foreach my $exitNum ($destRoomObj->ivValues('exitNumHash')) {

            my $oppExitObj = $self->ivShow('exitModelHash', $exitNum);
            if (
                $oppExitObj
                && $oppExitObj->mapDir
                && $oppExitObj->mapDir eq $oppMapDir
                #   Don't use an exit attached to a shadow exit; use the shadow exit instead)
                && (! $oppExitObj->shadowExit)
            ) {
                # We have found an exit in the opposite direction
                return $oppExitObj;
            }
        }

        # No exit in the opposite direction was found
        return undef;
    }

    sub analyseVerboseDescrip {

        # Called by $self->updateRoom
        # Compares a room model object's verbose description(s) against the current dictionary's
        #   lists of recognised words
        # All recognised nouns are stored in the room object's ->nounList, and all recognised
        #   adjectives are stored in ->adjList
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $roomObj    - The room model object to analyse
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $roomObj, $check) = @_;

        # Local variables
        my (
            $dictObj,
            @nounList, @adjList,
            %wordHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->analyseVerboseDescrip', @_);
        }

        # Import the current dictionary
        $dictObj = $session->currentDict;

        foreach my $descrip ($roomObj->ivValues('descripHash')) {

            # Split the description into words, and store them in a hash, so that each word is
            #   checked against the dictionary only once
            my @wordList = split('[\s\W]+', $descrip);
            foreach my $word (@wordList) {

                $wordHash{$word} = undef;
            }
        }

        # Check each unique word and, if it's recognised, add it to a list
        foreach my $word (keys %wordHash) {

            if ($dictObj->ivExists('combNounHash', $word)) {
                push (@nounList, $word);
            } elsif ($dictObj->ivExists('combAdjHash', $word)) {
                push (@adjList, $word);
            }
        }

        # Sort the two lists alphabetically, and store them in the room object's IVs
        $roomObj->ivPoke('nounList', sort {lc($a) cmp lc($b)} (@nounList));
        $roomObj->ivPoke('adjList', sort {lc($a) cmp lc($b)} (@adjList));

        # Analysis complete
        return 1;
    }

    sub allocateCardinalDir {

        # Called by various functions
        # An exit object's ->mapDir is set to one of Axmud's standard primary directions (the words
        #   'north', 'southeast', 'up', 'northnortheast' etc), and tells us how the exit is drawn on
        #   the map
        # The exit's ->dir is its nominal direction - the text that appears in a room statement
        #   (e.g. in 'Obvious exits: north, southeast, up, out')
        # If ->dir is a custom primary direction, the ->mapDir is set to the equivalent standard
        #   primary direction at the time the exit object is created. If ->dir is a recognised
        #   secondary direction which has been given an equivalent standard primary direction, it
        #   will have been used. Otherwise, ->mapDir will still be set to 'undef'
        # This function can be called once all of a new room's exits have been created in order to
        #   allocate standard primary directions to all exits which don't have one yet. However,
        #   this function only allocates the sixteen standard cardinal directions - it's up to the
        #   user to manually allocate 'up' or 'down', if required
        #
        # This function is also called by $self->addExit if an existing exit is supplanted by a
        #   new one, in an effort to allocate a new map direction for it
        # The calling function must update $self->updatePathHash and ->updateBoundaryHash, as
        #   necessary
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $roomObj    - The exit object's parent room
        #   $exitObj    - The exit object whose ->mapDir must be allocated
        #
        # Optional arguments
        #   $departRoomObj, $departExitObj, $standardDir
        #               - When called by $self->updateRoom while temporarily allocating cardinal
        #                   directions to unallocated exits. The room object from which the
        #                   character arrived and the exit object and standard primary or
        #                   secondary direction used (if known). Often, the arrival room ($exitObj's
        #                   parent) will have only one unallocated exit, in which case we allocate
        #                   the opposite standard direction to it
        #
        # Return values
        #   'undef' on improper arguments or if a cardinal direction can't be allocated
        #   Otherwise, the new value of $exitObj->mapDir

        my (
            $self, $session, $roomObj, $exitObj, $departRoomObj, $departExitObj, $standardDir,
            $check,
        ) = @_;

        # Local variables
        my (
            $cardinalDir, $matchFlag, $regex,
            @keyList, @dirList, @sortedList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $roomObj || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->allocateCardinalDir', @_);
        }

        # If the exit's nominal direction ->dir is a secondary direction that should be auto-
        #   allocated a primary direction, allocate that primary direction (unless one of the other
        #   exits in the room is already using it)
        if (
            $session->currentDict->ivExists('secondaryDirHash', $exitObj->dir)
            && defined $session->currentDict->ivShow('secondaryAutoHash', $exitObj->dir)
        ) {
            $cardinalDir = $session->currentDict->ivShow('secondaryAutoHash', $exitObj->dir);
        }

        # Does the exit's nominal direction contain a custom primary direction, e.g. 'swim east'?
        #   If so, we can auto-allocate that primary direction (unless one of the other exits in the
        #   room is already using it)
        # Get a list of custom primary directions, sorted by length (so that we check 'northeast'
        #   before 'north'), but don't use up/down because, if a mistake is made, it's inconvenient
        #   to reallocate an exit which can't be clicked directly
        if (! $cardinalDir) {

            if (! $self->showAllPrimaryFlag) {
                @keyList = $axmud::CLIENT->constShortPrimaryDirList;
            } else {
                @keyList = $axmud::CLIENT->constPrimaryDirList;
            }

            foreach my $key (@keyList) {

                if ($key ne 'up' && $key ne 'down') {

                    push (@dirList, $session->currentDict->ivShow('primaryDirHash', $key));
                }
            }

            @sortedList = sort {length($b) <=> length($a)} (@dirList);

            # Convert the list to a useful regex
            $regex = join('|', @sortedList);
            if ($exitObj->dir =~ m/($regex)/i) {

                $cardinalDir = $session->currentDict->convertStandardDir($1);
            }
        }

        if ($cardinalDir) {

            # Check that no other exits in this room are allocated to the same map direction
            $matchFlag = FALSE;
            OUTER: foreach my $otherExitNum ($roomObj->ivValues('exitNumHash')) {

                my $otherExitObj = $self->ivShow('exitModelHash', $otherExitNum);

                if (
                    $otherExitObj ne $exitObj
                    && $otherExitObj->mapDir
                    && $otherExitObj->mapDir eq $cardinalDir
                ) {
                    $matchFlag = TRUE;
                    last OUTER;
                }
            }

            if (! $matchFlag) {

                # Update the exit and instruct the world model to update its Automapper windows
                $self->setExitMapDir(
                    $session,
                    FALSE,                   # Don't update Automapper windows yet
                    $roomObj,
                    $exitObj,
                    $cardinalDir,
                );

                # Allocating the primary direction destroys the checked direction, if present
                $roomObj->ivDelete(
                    'checkedDirHash',
                    $session->currentDict->ivShow('primaryDirHash', $cardinalDir),
                );

                return $cardinalDir;
            }
        }

        # Otherwise, decide for ourselves which primary direction to allocate
        if (
            defined $departRoomObj
            && defined $departExitObj
            && (defined $standardDir || defined $departExitObj->mapDir)
        ) {
            # The character has arrived in a newly-created room using a known exit. Often it's the
            #   case that the room has only one unallocated exit and we definitely want to allocate
            #   it using the opposite standard primary direction, so that it points back to the
            #   departure room

            # Get the opposite standard primary direction (while checking that $standardDir isn't a
            #   standard secondary direction)
            if ($standardDir && $axmud::CLIENT->ivExists('constOppDirHash', $standardDir)) {
                $cardinalDir = $axmud::CLIENT->ivShow('constOppDirHash', $standardDir);
            } else {
                $cardinalDir = $axmud::CLIENT->ivShow('constOppDirHash', $departExitObj->mapDir);
            }

            # However, we can't allocate an exit temporarily to 'up' or 'down'
            if ($cardinalDir eq 'up' || $cardinalDir eq 'down') {

                $cardinalDir = undef;

            } else {

                # If that standard direction isn't available, don't use it
                OUTER: foreach my $number ($roomObj->ivValues('exitNumHash')) {

                    my $otherExitObj = $self->ivShow('exitModelHash', $number);

                    if (
                        $otherExitObj
                        && $otherExitObj->mapDir
                        && $otherExitObj->mapDir eq $cardinalDir
                    ) {
                        $cardinalDir = undef;
                        last OUTER;
                    }
                }
            }

        } else {

            # Get an unallocated cardinal direction, ignoring any directions which are on the end of
            #   an incoming 1-way exit
            $cardinalDir = $self->chooseCardinalDir($roomObj, $exitObj, TRUE);
        }

        if (! $cardinalDir) {

            # If not successful the first time, repeat the process, this time including any
            #   directions which are on the end of an incoming 1-way exit (the former was
            #   preferable, but we can make do with the latter)
            $cardinalDir = $self->chooseCardinalDir($roomObj, $exitObj, FALSE);
        }

        if ($cardinalDir) {

            # We have found an available standard primary direction. Allocate this direction to the
            #   exit object temporarily (it's up to the user to make it permanent)
            $exitObj->ivPoke('mapDir', $cardinalDir);
            $exitObj->ivPoke('drawMode', 'temp_alloc');

            # Allocating the primary direction destroys the checked direction, if present
            $roomObj->ivDelete(
                'checkedDirHash',
                $session->currentDict->ivShow('primaryDirHash', $cardinalDir),
            );

            return $cardinalDir;

        } else {

            # All sixteen cardinal directions are occupied. Mark the exit as 'unallocatable'
            $exitObj->ivUndef('mapDir');
            $exitObj->ivPoke('drawMode', 'temp_unalloc');

            return undef;
        }
    }

    sub chooseCardinalDir {

        # Called by $self->allocateCardinalDir up to two times - the first time, looking for a
        #   cardinal direction that don't have any incoming one-way exits; the second time (if
        #   necessary), looking for any available cardinal direction
        #
        # Expected arguments
        #   $roomObj    - The GA::Obj::Exit object's parent room
        #   $exitObj    - The exit object which needs to be allocated a cardinal direction
        #   $ignoreFlag - Set to TRUE the first time this function called, in which case we ignore
        #                   directions that have incoming 1-way exits; set to FALSE the second
        #                   time this function called, in which case we include them
        #
        # Return values
        #   'undef' on improper arguments, or if all the available cardinal directions are already
        #       occupied
        #   Otherwise, returns the first available cardinal direction

        my ($self, $roomObj, $exitObj, $ignoreFlag, $check) = @_;

        # Local variables
        my @dirList;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $exitObj || ! defined $ignoreFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chooseCardinalDir', @_);
        }

        # (For convenience, put the longest directions at the end, but don't allocate exits to 'up'
        #    or 'down' since they won't be visible on the map)
        @dirList = qw(
            north northeast east southeast south southwest west northwest
            northnortheast eastnortheast eastsoutheast southsoutheast
            southsouthwest westsouthwest westnorthwest northnorthwest
        );

        OUTER: foreach my $cardinalDir (@dirList) {

            my $matchFlag;

            INNER: foreach my $number ($roomObj->ivValues('exitNumHash')) {

                my $otherExitObj = $self->ivShow('exitModelHash', $number);

                if (
                    $otherExitObj
                    && $otherExitObj->mapDir
                    && $otherExitObj->mapDir eq $cardinalDir
                ) {
                    # This $cardinalDir has already been allocated
                    $matchFlag = TRUE;
                    last INNER;
                }
            }

            if (! $matchFlag) {

                # $cardinalDir is apparently available. Check for incoming one-way exits, if allowed
                if (! $ignoreFlag) {

                    INNER: foreach my $number ($roomObj->ivKeys('oneWayExitHash')) {

                        my ($otherExitObj, $oppDir);

                        $otherExitObj = $self->ivShow('exitModelHash', $number);

                        if ($otherExitObj && $otherExitObj->mapDir) {

                            # Get the opposite of the incoming one-way exit's ->mapDir (the standard
                            #   primary direction used to draw the exit on the map)
                            $oppDir
                                = $axmud::CLIENT->ivShow('constOppDirHash', $otherExitObj->mapDir);

                            if ($oppDir eq $cardinalDir) {

                                # The incoming 1-way exit is using this primary direction, so ignore
                                #   it (for now), and move on to the next one
                                next OUTER;
                            }
                        }
                    }
                }

                # Available cardinal direction found
                return $cardinalDir;
            }
        }

         # All sixteen cardinal directions are unavailable
        return undef;
    }

    sub countRoomContents {

        # Called by GA::Obj::Map->updateRoom
        # Counts the number of living and non-living things in the Locator task's current room, and
        #   stores them in the regionmap in which a specified room model object is stored
        # As a result, it's possible for the Automapper window to display the number of things in a
        #   room the last time it was visited
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $modelRoomObj   - The room model object for which the counts are stored
        #
        # Return values
        #   'undef' on improper arguments, if there is no Locator task, if the Locator task doesn't
        #       know the current location or if $modelRoomObj's regionmap can't be found
        #   1 otherwise

        my ($self, $session, $modelRoomObj, $check) = @_;

        # Local variables
        my ($regionmapObj, $livingCount, $nonLivingCount);

        # Check for improper arguments
        if (! defined $session || ! defined $modelRoomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->countRoomContents', @_);
        }

        # Shouldn't be possible for this function to be called when the Locator task isn't running
        #   or doesn't know the current location - but we'll check anyway
        if (! $session->locatorTask || ! $session->locatorTask->roomObj) {

            return undef;
        }

        # Get the room's regionmap
        $regionmapObj = $self->findRegionmap($modelRoomObj->parent);
        if (! $regionmapObj) {

            # Again, nothing we can do
            return undef;
        }

        # Count the number of living and non-living things in the Locator task's room
        $livingCount = 0;
        $nonLivingCount = 0;

        foreach my $obj ($session->locatorTask->roomObj->tempObjList) {

            if ($obj->aliveFlag) {
                $livingCount++;
            } else {
                $nonLivingCount++;
            }
        }

        # Now, if the count is 0, we remove an entry from the hash IV (if it exists); otherwise we
        #   add an entry (or replace the existing one)
        if ($livingCount) {
            $regionmapObj->storeLivingCount($modelRoomObj->number, $livingCount);
        } else {
            $regionmapObj->removeLivingCount($modelRoomObj->number);
        }

        if ($nonLivingCount) {
            $regionmapObj->storeNonLivingCount($modelRoomObj->number, $nonLivingCount);
        } else {
            $regionmapObj->removeNonLivingCount($modelRoomObj->number);
        }

        return 1;
    }

    sub setInteriorOffsets {

        # Called by GA::Obj::Map->setInteriorOffsetsCallback
        # Sets the offsets used when a room's grid coordinates are displayed as interior text inside
        #   the room box
        #
        # Expected arguments
        #   $xOffset, $yOffset  - The new values to set
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $xOffset, $yOffset, $check) = @_;

        # Check for improper arguments
        if (! defined $xOffset || ! defined $yOffset || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setInteriorOffsets', @_);
        }

        # Update IVs
        $self->ivPoke('roomInteriorXOffset', $xOffset);
        $self->ivPoke('roomInteriorYOffset', $yOffset);

        return 1;
    }

    sub findPathCmds {

        # Called by GA::Win::Map->processPathCallback
        # Given a list of GA::ModelObj::Room objects along a continuous path - such as one
        #   generated by a call to $self->findPath or ->findUniversalPath - compiles a list of
        #   commands to get from the first room on the path to the last one
        # Uses assisted moves, if allowed; otherwise uses only exit nominal directions
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $step       - Set to 1 if we want the commands to get from the beginning of the room
        #                   list to the end; set to -1 if we want the commands to get from the end
        #                   of the room list to the beginning
        #   @roomList   - A list of GA::ModelObj::Room objects along a continuous path
        #
        # Return values
        #   An empty list on improper arguments, if a continuous path between the first and last
        #       rooms on the list can't be found, or if the list contains less than two rooms
        #   Otherwise, returns a list of commands, e.g. ('n', 'nw', 'e', 'u', 'enter cave')

        my ($self, $session, $step, @roomList) = @_;

        # Local variables
        my (@emptyList, @exitList, @cmdList);

        # Check for improper arguments
        if (! defined $session || ! defined $step || scalar @roomList < 2) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findPathCmds', @_);
            return @emptyList;
        }

        # Process the route in the opposite direction, if required
        if ($step == -1) {

            @roomList = reverse @roomList;
        }

        do {

            my ($roomObj, $nextRoomObj, $matchFlag);

            $roomObj = shift @roomList;
            if (@roomList) {

                # Check this room's exits, looking for one which leads to the next room in the list
                $nextRoomObj = $roomList[0];

                INNER: foreach my $exitNum ($roomObj->ivValues('exitNumHash')) {

                    my ($exitObj, $destRoomNum);

                    $exitObj = $self->ivShow('exitModelHash', $exitNum);
                    $destRoomNum = $exitObj->destRoom;

                    if (
                        defined $destRoomNum
                        && $self->ivShow('modelHash', $destRoomNum) eq $nextRoomObj
                    ) {
                        # This is the exit we want
                        push (@exitList, $exitObj);
                        $matchFlag = TRUE;

                        last INNER;
                    }
                }

                # There is no way to get between $roomObj and $nextRoomObj
                if (! $matchFlag) {

                    return @emptyList;
                }
            }

        } until (! @roomList);

        # We have a list of exit objects from the first room on the path to the last one. Now
        #   convert it into a list of commands. If assisted moves are turned on, use them; otherwise
        #   just use each exit's nominal direction
        @cmdList = $self->convertExitList($session, @exitList);

        # Operation complete
        return @cmdList;
    }

    sub convertExitList {

        # Called by GA::Win::Map->processPathCallback and $self->findPathCmds
        # Given a list of GA::Obj::Exit objects (presumed to be along a continuous path),
        #   compiles a list of world commands to move from one end of the path to the other
        # If assisted moves are allowed, uses them; otherwise uses each exit's nominal direction
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Optional arguments
        #   @exitList   - The list of GA::Obj::Exit objects. If the list is empty, an empty list is
        #                   returned
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, @exitList) = @_;

        # Local variables
        my (
            $assistedFlag, $cmdSep,
            @cmdList,
        );

        # Check for improper arguments
        if (! defined $session) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertExitList', @_);
        }

        # Import the world model's ->assistedMovesFlag
        $assistedFlag = $self->assistedMovesFlag;
        # Import the client command separator
        $cmdSep = $axmud::CLIENT->cmdSep;

        OUTER: foreach my $exitObj (@exitList) {

            my $cmdSequence;

            if ($assistedFlag) {

                # Ask the exit to provide a command sequence (e.g. 'knock on door;open door;east')
                #   comprising an assisted move. If no assisted move is found, just use the exit's
                #   nominal direction
                $cmdSequence = $exitObj->getAssisted($session);
                if ($cmdSequence) {
                    push (@cmdList, split(m/$cmdSep/, $cmdSequence));
                } else {
                    push (@cmdList, $exitObj->dir);
                }

            } else {

                # Assisted moves turned off. Just use the exits' nominal directions
                push (@cmdList, $exitObj->dir);
            }
        }

        # Operation complete
        return @cmdList;
    }

    sub getExitLength {

        # Called by GA::Obj::Map->autoProcessNewRoom
        # Given a GA::Obj::Exit, return the exit length that applies to it. If the exit's ->mapDir
        #   (the standard primary direction in which the exit is drawn on the map) is 'up' or
        #   'down', then use the value stored in ->verticalExitLengthBlocks. Otherwise use the
        #   value stored in ->horizontalExitLengthBlocks
        #
        # Expected arguments
        #   $exitObj    - The exit object to check
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getExitLength', @_);
        }

        if (! $exitObj->mapDir) {

            # No standard primary direction set - use a default exit length of 1
            return 1;

        } elsif ($exitObj->mapDir eq 'up' || $exitObj->mapDir eq 'down') {

            return $self->verticalExitLengthBlocks;

        } else {

            return $self->horizontalExitLengthBlocks;
        }
    }

    sub getRegionScheme {

        # Can be called by anything
        # Get the region scheme object (GA::Obj::RegionScheme) that applies to a specified regionmap
        #
        # Expected arguments
        #   $regionmapObj   - The specified GA::Obj::Regionmap
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $regionmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $regionmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getRegionScheme', @_);
        }

        if (
            defined $regionmapObj->regionScheme
            && $self->ivExists('regionSchemeHash', $regionmapObj->regionScheme)
        ) {
            return $self->ivShow('regionSchemeHash', $regionmapObj->regionScheme);

        } else{

            # If the regionmap doesn't name a region scheme, then use the default one
            return $self->defaultSchemeObj;
        }
    }

    # (Called from GA::Win::Map menu, 'View' column)

    sub toggleFlag {

        # Called by anonymous function in GA::Win::Map->enableXXXColumn
        # Toggles a flag IV and updates each Automapper window
        #
        # Expected arguments
        #   $iv         - The flag IV to toggle
        #   $ivFlag     - New value of the IV (TRUE or FALSE)
        #   $drawFlag   - If set to TRUE, this function calls ->drawRegion in every affected
        #                   Automapper window. If FALSE, ->drawRegion is not called
        #
        # Optional arguments
        #   $menuName   - The name of the menu item which must be set to active, or inactive (a key
        #                   in GA::Map::Win->menuToolItemHash
        #   $iconName   - The name of the toolbar icon which must be set to active, or inactive (a
        #                   key in GA::Map::Win->menuToolItemHash. If set to 'undef', there is no
        #                   icon to modify)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $ivFlag, $drawFlag, $menuName, $iconName, $check) = @_;

        # Check for improper arguments
        if (! defined $iv || ! defined $ivFlag || ! defined $drawFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleFlag', @_);
        }

        # Update the IV
        if ($ivFlag) {
            $self->ivPoke($iv, TRUE);
        } else {
            $self->ivPoke($iv, FALSE);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            if ($drawFlag) {

                # Redraw all drawn regions
                $mapWin->redrawRegions();
            }

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($menuName) {

                $mapWin->setActiveItem($menuName, $self->$iv);
            }

            # Set the equivalent toolbar button, if there is one
            if ($iconName) {

                $mapWin->setActiveItem($iconName, $self->$iv);
            }

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);
        }

        return 1;
    }

    sub switchMode {

        # Called by anonymous function in GA::Win::Map->enableXXXColumn
        # Sets the new value of an IV and updates each Automapper window
        #
        # Expected arguments
        #   $iv         - The IV to set
        #   $value      - New value of the IV (can be 'undef')
        #   $drawFlag   - If set to TRUE, this function calls ->drawRegion in every affected
        #                   Automapper window. If FALSE, ->drawRegion is not called
        #
        # Optional arguments
        #   $menuName   - The name of the menu item which must be set to active, or inactive (a key
        #                   in GA::Map::Win->menuToolItemHash
        #   $iconName   - The name of the toolbar icon which must be set to active, or inactive (a
        #                   key in GA::Map::Win->menuToolItemHash. If set to 'undef', there is no
        #                   icon to modify)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $value, $drawFlag, $menuName, $iconName, $check) = @_;

        # Check for improper arguments
        if (! defined $iv || ! defined $drawFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->switchMode', @_);
        }

        # Update the IV
        $self->ivPoke($iv, $value);

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            if ($drawFlag && $mapWin->currentRegionmap) {

                # Redraw all drawn regions
                $mapWin->redrawRegions();

            } elsif ($iv eq 'currentRoomMode') {

                # When setting $self->currentRoomMode, redraw the current/last known/ghost rooms
                if ($mapWin->mapObj->currentRoom) {

                    $mapWin->markObjs('room', $mapWin->mapObj->currentRoom);
                }

                if ($mapWin->mapObj->lastKnownRoom) {

                   $mapWin->markObjs('room', $mapWin->mapObj->lastKnownRoom);
                }

                if ($mapWin->mapObj->ghostRoom) {

                    $mapWin->markObjs('room', $mapWin->mapObj->ghostRoom);
                }

                $mapWin->doDraw();
            }

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($menuName) {

                $mapWin->setActiveItem($menuName, TRUE);
            }

            # Set the equivalent toolbar button, if there is one
            if ($iconName) {

                $mapWin->setActiveItem($iconName, TRUE);
            }

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);

            # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
            $mapWin->restrictWidgets();
        }

        return 1;
    }

    sub toggleWinComponents {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Shows (or hides) each Automapper window's major components (the menu, toolbar, treeview
        #   and canvas)
        #
        # Expected arguments
        #   $iv     - The IV matching the component to show (or hide) - one of 'showMenuBarFlag',
        #               'showToolbarFlag', 'showTreeViewFlag', 'showCanvasFlag'
        #   $flag   - The new value of the IV - TRUE or FALSE
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $iv || ! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleWinComponents', @_);
        }

        # Update the IV
        if ($flag) {
            $self->ivPoke($iv, TRUE);
        } else {
            $self->ivPoke($iv, FALSE);
        }

        # Show (or hide) the component in every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            my $menuItem;

            if ($iv eq 'showMenuBarFlag') {

                $mapWin->redrawWidgets('menu_bar');
                $mapWin->setActiveItem('show_menu_bar', $self->$iv);

            } elsif ($iv eq 'showToolbarFlag') {

                $mapWin->redrawWidgets('toolbar');
                $mapWin->setActiveItem('show_toolbar', $self->$iv);

            } elsif ($iv eq 'showTreeViewFlag') {

                $mapWin->redrawWidgets('treeview');
                $mapWin->setActiveItem('show_treeview', $self->$iv);

            } elsif ($iv eq 'showCanvasFlag') {

                # If there's a current region, we don't need it any more
                if (! $flag && $mapWin->currentRegionmap) {

                    $mapWin->setCurrentRegion();
                }

                $mapWin->redrawWidgets('canvas');
                $mapWin->setActiveItem('show_canvas', $self->$iv);
            }
        }

        return 1;
    }

    sub resetRegionList {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Resets the order of the list of regions displayed in each Automapper window's treeview
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetRegionList', @_);
        }

        # If there's a region moved to the top of the list, put back in its normal position
        $self->ivUndef('firstRegion');
        # Don't show a reversed list
        $self->ivPoke('reverseRegionListFlag', FALSE);

        # Redraw the list of regions in the treeview of every Automapper window using this world
        #   model
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->resetTreeView();
        }

        return 1;
    }

    sub reverseRegionList {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Reverses the order of the list of regions displayed in each Automapper window's treeview
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reverseRegionList', @_);
        }

        if ($self->reverseRegionListFlag) {

            # Show normal list
            $self->ivPoke('reverseRegionListFlag', FALSE);

        } else {

            # Show reversed list
            $self->ivPoke('reverseRegionListFlag', TRUE);
        }

        # Redraw the list of regions in the treeview of every Automapper window using this world
        #   model
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->resetTreeView();
        }

        return 1;
    }

    sub moveRegionToTop {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Moves a specified region to the top of list of regions displayed in each Automapper
        #   window's treeview
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $regionmapObj   - The GA::Obj::Regionmap to move. If undefined, any region already at
        #                       the top of the list is removed (and placed back in its original
        #                       position)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $regionmapObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->moveRegionToTop', @_);
        }

        # Mark the current region as being at the top of the list (or remove an existing region from
        #   the top of the list, if any)
        if ($regionmapObj) {
            $self->ivPoke('firstRegion', $regionmapObj->name);
        } else {
            $self->ivUndef('firstRegion');
        }

        # Redraw the list of regions in the treeview of every Automapper window using this world
        #   model
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->resetTreeView();
        }

        return 1;
    }

    sub toggleFilter {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Releases/applies the specified room filter and updates each Automapper window
        #
        # Expected arguments
        #   $filter     - The filter to apply/release
        #   $flag       - Set to TRUE to release the room filter, FALSE to apply it
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $filter, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $filter || ! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleAllFilters', @_);
        }

        if ($flag) {
            $self->ivAdd('roomFilterApplyHash', $filter, TRUE);
        } else {
            $self->ivAdd('roomFilterApplyHash', $filter, FALSE);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            # Redraw all drawn regions
            $mapWin->redrawRegions();

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            $mapWin->setActiveItem($filter . '_filter', $flag);

            # Set the equivalent toolbar button
            $mapWin->setActiveItem('icon_' . $filter . '_filter', $flag);

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);
        }

        return 1;
    }

    sub switchRoomInteriorMode {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Sets the value of $self->roomInteriorMode and updates each Automapper window
        #
        # Expected arguments
        #   $mode       - The new value of ->roomInteriorMode
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->switchRoomInteriorMode', @_);
        }

        $self->ivPoke('roomInteriorMode', $mode);

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            # Redraw all drawn regions
            $mapWin->redrawRegions();

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            $mapWin->setActiveItem('interior_mode_' . $mode, TRUE);

            # Set the equivalent toolbar button
            $mapWin->setActiveItem('icon_interior_mode_' . $mode, TRUE);

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);
        }

        return 1;
    }

    sub switchRegionDrawExitMode {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Sets the value of GA::Obj::Regionmap->drawExitMode and updates each Automapper window
        #
        # Expected arguments
        #   $regionmapObj   - The regionmap to modify
        #   $mode           - The new value of $regionmapObj->drawExitMode
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $regionmapObj, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $regionmapObj || ! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->switchRegionDrawExitMode',
                @_,
            );
        }

        $regionmapObj->ivPoke('drawExitMode', $mode);

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            my ($menuName, $menuItem);

            # Redraw the specified regionmap (the TRUE argument means don't redraw other regionmaps)
            $mapWin->redrawRegions($regionmapObj, TRUE);

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($mode eq 'no_exit') {
                $menuName = 'region_draw_no_exits';
            } elsif ($mode eq 'simple_exit') {
                $menuName = 'region_draw_simple_exits';
            } elsif ($mode eq 'complex_exit') {
                $menuName = 'region_draw_complex_exits';
            }

            $mapWin->setActiveItem($menuName, FALSE);

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);

            # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
            $mapWin->restrictWidgets();
        }

        return 1;
    }

    sub toggleObscuredExitFlag {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Sets the value of GA::Obj::Regionmap->obscuredExitFlag and updates each Automapper window
        #
        # Expected arguments
        #   $regionmapObj   - The regionmap to modify
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $regionmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $regionmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->toggleObscuredExitFlag',
                @_,
            );
        }

        if (! $regionmapObj->obscuredExitFlag) {
            $regionmapObj->ivPoke('obscuredExitFlag', TRUE);
        } else {
            $regionmapObj->ivPoke('obscuredExitFlag', FALSE);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            my ($menuName, $menuItem);

            # Redraw the specified regionmap (the TRUE argument means don't redraw other regionmaps)
            $mapWin->redrawRegions($regionmapObj, TRUE);

            # Update the menu item
            $mapWin->set_ignoreMenuUpdateFlag(TRUE);
            $mapWin->setActiveItem('obscured_exits_region', $regionmapObj->obscuredExitFlag);
            $mapWin->set_ignoreMenuUpdateFlag(FALSE);

            # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
            $mapWin->restrictWidgets();
        }

        return 1;
    }

    sub toggleObscuredExitRedrawFlag {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Sets the value of GA::Obj::Regionmap->obscuredExitRedrawFlag and updates each Automapper
        #   window
        #
        # Expected arguments
        #   $regionmapObj   - The regionmap to modify
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $regionmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $regionmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->toggleObscuredExitRedrawFlag',
                @_,
            );
        }

        if (! $regionmapObj->obscuredExitRedrawFlag) {
            $regionmapObj->ivPoke('obscuredExitRedrawFlag', TRUE);
        } else {
            $regionmapObj->ivPoke('obscuredExitRedrawFlag', FALSE);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            my ($menuName, $menuItem);

            # Redraw the specified regionmap (the TRUE argument means don't redraw other regionmaps)
            $mapWin->redrawRegions($regionmapObj, TRUE);

            # Update the menu item
            $mapWin->set_ignoreMenuUpdateFlag(TRUE);
            $mapWin->setActiveItem(
                'auto_redraw_obscured_region',
                $regionmapObj->obscuredExitRedrawFlag,
            );
            $mapWin->set_ignoreMenuUpdateFlag(FALSE);

            # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
            $mapWin->restrictWidgets();
        }

        return 1;
    }

    sub toggleDrawOrnamentsFlag {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Sets the value of GA::Obj::Regionmap->drawOrnamentsFlag and updates each Automapper window
        #
        # Expected arguments
        #   $regionmapObj   - The regionmap to modify
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $regionmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $regionmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->toggleDrawOrnamentsFlag',
                @_,
            );
        }

        if (! $regionmapObj->drawOrnamentsFlag) {
            $regionmapObj->ivPoke('drawOrnamentsFlag', TRUE);
        } else {
            $regionmapObj->ivPoke('drawOrnamentsFlag', FALSE);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            my ($menuName, $menuItem);

            # Redraw the specified regionmap (the TRUE argument means don't redraw other regionmaps)
            $mapWin->redrawRegions($regionmapObj, TRUE);

            # Update the menu item
            $mapWin->set_ignoreMenuUpdateFlag(TRUE);
            $mapWin->setActiveItem('draw_ornaments_region', $regionmapObj->drawOrnamentsFlag);
            $mapWin->set_ignoreMenuUpdateFlag(FALSE);

            # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
            $mapWin->restrictWidgets();
        }

        return 1;
    }

    sub setMagnification {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Sets the value of GA::Obj::Regionmap->magnification and updates each Automapper window
        #
        # Expected arguments
        #   $mapWin         - The GA::Win::Map that initiated the zoom
        #   $magnification  - The new value of $regionmapObj->magnification
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $mapWin, $magnification, $check) = @_;

        # Local variables
        my (
            $regionmapObj, $oldOffsetXPos, $oldOffsetYPos, $oldStartXPos, $oldStartYPos,
            $oldWidth, $oldHeight, $offsetXPos, $offsetYPos, $startXPos, $startYPos, $width,
            $height, $adjustXFlag, $adjustYFlag,
        );

        # Check for improper arguments
        if (! defined $mapWin || ! defined $magnification || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setMagnification', @_);
        }

        $regionmapObj = $mapWin->currentRegionmap;
        $regionmapObj->ivPoke('magnification', $magnification);

        # When we fully zoom out, so that there are no scroll bars visible, GooCanvas2::Canvas
        #   helpfully forgets the scrollbar's position. This means that the current room, if we were
        #   centred on it, is no longer centred. Therefore we have to get the scrollbar's position,
        #   change the map's visible size, and then - if the map is fully zoomed out, and the
        #   scrollbars have disappeared - record their position, for the next time the user zooms in

        # Get the visible map's size and position. The six return values are all numbers in the
        #   range 0-1
        ($oldOffsetXPos, $oldOffsetYPos, $oldStartXPos, $oldStartYPos, $oldWidth, $oldHeight)
            = $mapWin->getMapPosn();

        # Update every Automapper window using this world model
        foreach my $otherMapWin ($self->collectMapWins()) {

            if ($otherMapWin->currentRegionmap && $otherMapWin->currentRegionmap eq $regionmapObj) {

                # Zoom in or out on this region
                $otherMapWin->doZoom();
            }
        }

        # Get the visible map's new size and position.
        ($offsetXPos, $offsetYPos, $startXPos, $startYPos, $width, $height)
            = $mapWin->getMapPosn();

        # The horizontal and vertical scrollbars can reach max zoom out at different times, so deal
        #   with them separately
        if (
            ! $regionmapObj->maxZoomOutXFlag
            && (
                ($oldOffsetXPos != 0 && $offsetXPos == 0)
                || ($oldOffsetXPos != 1 && $offsetXPos == 1)
            )
        ) {
            # We have fully zoomed out, and we weren't already fully zoomed out. Inform the
            #   regionmap
            $regionmapObj->ivPoke('maxZoomOutXFlag', TRUE);
            # Remember the position of the scrollbars before the zoom
            $regionmapObj->ivPoke('scrollXPos', $oldStartXPos + ($oldWidth / 2));

        } elsif (
            $regionmapObj->maxZoomOutXFlag
            && (
                ($oldOffsetXPos == 0 && $offsetXPos != 0)
                || ($oldOffsetXPos == 1 && $offsetXPos != 1)
            )
        ) {
            # We have just zoomed in from a maximum zoom out. Reset the flags in the regionmap
            $regionmapObj->ivPoke('maxZoomOutXFlag', FALSE);
            $adjustXFlag = TRUE;
        }

        if (
            ! $regionmapObj->maxZoomOutYFlag
            && (
                ($oldOffsetYPos != 0 && $offsetYPos == 0)
                || ($oldOffsetYPos != 1 && $offsetYPos == 1)
            )
        ) {
            $regionmapObj->ivPoke('maxZoomOutYFlag', TRUE);
            $regionmapObj->ivPoke('scrollYPos', $oldStartYPos + ($oldHeight / 2));

        } elsif (
            $regionmapObj->maxZoomOutYFlag
            && (
                ($oldOffsetYPos == 0 && $offsetYPos != 0)
                || ($oldOffsetYPos == 1 && $offsetYPos != 1)
            )
        ) {
            $regionmapObj->ivPoke('maxZoomOutYFlag', FALSE);
            $adjustYFlag = TRUE;
        }

        # In every affected Automapper window, re-centre the map at the correct position
        foreach my $otherMapWin ($self->collectMapWins()) {

            if (
                $otherMapWin->currentRegionmap
                && $otherMapWin->currentRegionmap eq $regionmapObj
            ) {
                if ($adjustXFlag && $adjustYFlag) {

                    $otherMapWin->setMapPosn($regionmapObj->scrollXPos, $regionmapObj->scrollYPos);

                } elsif ($adjustXFlag) {

                    $otherMapWin->setMapPosn(
                        $regionmapObj->scrollXPos,
                        ($startYPos + ($height / 2)),
                    );

                } elsif ($adjustYFlag) {

                    $otherMapWin->setMapPosn(
                        ($startXPos + ($width / 2)),
                        $regionmapObj->scrollYPos,
                    );
                }
            }
        }

        return 1;
    }

    sub repositionMaps {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Repositions every regionmap in the world model (sets the magnification to 0, and sets the
        #   scroll position to the middle of the map). Updates each Automapper window using this
        #   world model
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->repositionMaps', @_);
        }

        # Update IVs for each regionmap
        foreach my $regionmapObj ($self->ivValues('regionmapHash')) {

            $regionmapObj->ivPoke('magnification', 1);
            $regionmapObj->ivPoke('scrollXPos', 0.5);
            $regionmapObj->ivPoke('scrollYPos', 0.5);
            $regionmapObj->ivPoke('currentLevel', 0);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            if ($mapWin->currentRegionmap) {

                # Reset zoom factor (magnification) to 1
                $mapWin->zoomCallback(1);
                # Reset the scrollbars
                $mapWin->setMapPosn(0.5, 0.5);
                # Redraw the map to make sure the default level is visible
                $mapWin->setCurrentLevel(0);
            }
        }

        return 1;
    }

    sub setTrackingSensitivity {

        # Called by anonymous function in GA::Win::Map->enableViewColumn
        # Sets the value of $self->trackingSensitivity and updates each Automapper window
        #
        # Expected arguments
        #   $sensitivity    - The new tracking sensitivity (one of the value 0, 0.33, 0.66 or 1)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $sensitivity, $check) = @_;

        # Check for improper arguments
        if (! defined $sensitivity || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setTrackingSensitivity', @_);
        }

        if (
            $sensitivity != 0
            && $sensitivity != 0.33
            && $sensitivity != 0.66
            && $sensitivity != 1
        ) {
            # Use a default value for $sensitivity
            $sensitivity = 0;
        }

        $self->ivPoke('trackingSensitivity', $sensitivity);

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            my $menuName;

            if ($sensitivity == 0) {
                $menuName = 'track_always';
            } elsif ($sensitivity == 0.33) {
                $menuName = 'track_near_centre';
            } elsif ($sensitivity == 0.66) {
                $menuName = 'track_near_edge';
            } else {
                $menuName = 'track_not_visible';
            }

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            $mapWin->setActiveItem($menuName, TRUE);

            # Set the equivalent toolbar button
            $mapWin->setActiveItem('icon_' . $menuName, TRUE);

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);
        }

        return 1;
    }

    # (Called from GA::Win::Map menu, 'Mode' column)

    sub setAutoCompareMode {

        # Called by anonymous function in GA::Win::Map->enableModeColumn
        # Updates the world model's ->autoCompareMode and updates each Automapper window using this
        #   world model
        #
        # Expected arguments
        #   $mode   - The new value of the IV - 'default', 'new' or 'current'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setAutoCompareMode', @_);
        }

        # Update the IV
        $self->ivPoke('autoCompareMode', $mode);

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($mode eq 'default') {
                $mapWin->setActiveItem('auto_compare_default', TRUE);
            } elsif ($mode eq 'default') {
                $mapWin->setActiveItem('auto_compare_new', TRUE);
            } elsif ($mode eq 'default') {
                $mapWin->setActiveItem('auto_compare_current', TRUE);
            }

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);

            # If interior counts are currently showing the number of rooms that match the current
            #   room, redraw the current room to show the counts
            if ($self->roomInteriorMode eq 'compare_count' && $mapWin->mapObj->currentRoom) {

                $mapWin->markObjs('room', $mapWin->mapObj->currentRoom);
                $mapWin->doDraw();
            }
        }

        return 1;
    }

    sub toggleAutoCompareAllFlag {

        # Called by anonymous function in GA::Win::Map->enableModeColumn
        # Toggles the world model's ->autoCompareAllFlag and updates each Automapper window using
        #   this world model
        #
        # Expected arguments
        #   $flag   - The new value of the IV - TRUE or FALSE
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->toggleAutoCompareAllFlag',
                @_,
            );
        }

        # Update the IV
        if (! $flag) {
            $self->ivPoke('autoCompareAllFlag', FALSE);
        } else {
            $self->ivPoke('autoCompareAllFlag', TRUE);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if (! $flag) {
                $mapWin->setActiveItem('auto_compare_region', TRUE);
            } else {
                $mapWin->setActiveItem('auto_compare_model', TRUE);
            }

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);
        }

        return 1;
    }

    sub setAutoSlideMode {

        # Called by anonymous function in GA::Win::Map->enableModeColumn
        # Updates the world model's ->autoSlideMode and updates each Automapper window using this
        #   world model
        #
        # Expected arguments
        #   $mode   - The new value of the IV - 'default', 'orig_pull', 'orig_push', 'other_pull',
        #               'other_push', 'dest_pull' or 'dest_push'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setAutoSlideMode', @_);
        }

        # Update the IV
        $self->ivPoke('autoSlideMode', $mode);

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            my $menuItem;

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($mode eq 'default') {
                $mapWin->setActiveItem('slide_default', TRUE);
            } elsif ($mode eq 'orig_pull') {
                $mapWin->setActiveItem('slide_orig_pull', TRUE);
            } elsif ($mode eq 'orig_push') {
                $mapWin->setActiveItem('slide_orig_push', TRUE);
            } elsif ($mode eq 'other_pull') {
                $mapWin->setActiveItem('slide_other_pull', TRUE);
            } elsif ($mode eq 'other_push') {
                $mapWin->setActiveItem('slide_other_push', TRUE);
            } elsif ($mode eq 'dest_pull') {
                $mapWin->setActiveItem('slide_dest_pull', TRUE);
            } elsif ($mode eq 'dest_push') {
                $mapWin->setActiveItem('slide_dest_push', TRUE);
            }

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);
        }

        return 1;
    }

    sub toggleDisableUpdateModeFlag {

        # Called by anonymous function in GA::Win::Map->enableModeColumn
        # Toggles the world model's ->disableUpdateModeFlag and updates each Automapper window using
        #   this world model
        #
        # Expected arguments
        #   $flag   - The new value of the IV - TRUE or FALSE
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->toggleDisableUpdateModeFlag',
                @_,
            );
        }

        # Update the IV
        if ($flag) {
            $self->ivPoke('disableUpdateModeFlag', TRUE);
        } else {
            $self->ivPoke('disableUpdateModeFlag', FALSE);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            $mapWin->setActiveItem('disable_update_mode', $self->disableUpdateModeFlag);

            # The call to ->setMode makes sure the Automapper window's mode is switched from
            #   'update' to 'follow' if 'update' mode has just been disabled, and also makes sure
            #   the menu/toolbar buttons are sensitised or not, as appropriate
            $mapWin->setMode($mapWin->mode);

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);
        }

        return 1;
    }

    sub toggleShowTooltipsFlag {

        # Called by anonymous function in GA::Win::Map->enableModeColumn
        # Toggles the world model's ->showTooltipsFlag and updates each Automapper window using this
        #   world model
        #
        # Expected arguments
        #   $flag   - The new value of the IV - TRUE or FALSE
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleShowTooltipsFlag', @_);
        }

        # Update the IV
        if ($flag) {
            $self->ivPoke('showTooltipsFlag', TRUE);
        } else {
            $self->ivPoke('showTooltipsFlag', FALSE);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            $mapWin->setActiveItem('show_tooltips', $self->showTooltipsFlag);

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);

            if (! $flag) {

                # If the tooltip window is currently visible, hide it
                $mapWin->hideTooltips();
            }
        }

        return 1;
    }

    # (Called from GA::Win::Map menu, 'Exits' column)

    sub setCheckableDirMode {

        # Called by anonymous function in GA::Win::Map->enableModeColumn
        # Updates the world model's ->checkableDirMode and updates each Automapper window using
        #   this world model
        #
        # Expected arguments
        #   $mode   - The new value of the IV - 'simple', 'diku', 'lp' or 'complex'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setCheckableDirMode', @_);
        }

        # Update the IV
        $self->ivPoke('checkableDirMode', $mode);

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($mode eq 'simple') {
                $mapWin->setActiveItem('checkable_dir_simple', TRUE);
            } elsif ($mode eq 'diku') {
                $mapWin->setActiveItem('checkable_dir_diku', TRUE);
            } elsif ($mode eq 'lp') {
                $mapWin->setActiveItem('checkable_dir_lp', TRUE);
            } elsif ($mode eq 'complex') {
                $mapWin->setActiveItem('checkable_dir_complex', TRUE);
            }

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);

            # If interior counts are currently showing checked/checkable directions, redraw all
            #   drawn regions to update those counts
            if ($self->roomInteriorMode eq 'checked_count') {

                $mapWin->redrawRegions();
            }
        }

        return 1;
    }

    sub getCheckableDirs {

        # Called by GA::Win::Map->prepareCheckedCounts, once per drawing cycle. Also called by
        #   GA::Cmd::ModelReport->do
        # $self->roomInteriorMode specifies which primary directions should be checked, when
        #   using checkable directions. This function compiles the list of primary directions, and
        #   converts them from their standard to custom forms, which is how they are stored in
        #   GA::ModelObj::Room->checkedDirHash
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise returns a hash (never empty), in the form
        #       $hash{custom_primary_direction} = undef

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $dictObj,
            @standardList,
            %emptyHash, %returnHash,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getCheckableDirs', @_);
            return %emptyHash;
        }

        # Import the current dictionary (for convenience)
        $dictObj = $session->currentDict;

        if ($self->checkableDirMode eq 'complex') {
            @standardList = $axmud::CLIENT->constPrimaryDirList;
        } elsif ($self->checkableDirMode eq 'lp') {
            @standardList = $axmud::CLIENT->constShortPrimaryDirList;
        } elsif ($self->checkableDirMode eq 'diku') {
            @standardList = qw(north south east west up down);
        } else {
            @standardList = qw(north south east west);      # ->roomInteriorMode is 'simple'
        }

        foreach my $standard (@standardList) {

            my $custom = $dictObj->ivShow('primaryDirHash', $standard);
            $returnHash{$custom} = undef;
        }

        # Operation complete
        return %returnHash;
    }

    # A* algorithm functions (used to find a path between two rooms in the same region)

    sub findPath {

        # Can be called by any function
        #
        # A* algorithm to find a path between two rooms in the same region, based on
        #   AI::Pathfinding::AStar by Aaron Dalton
        #
        # This function should only be called if there's reasonable certainty that a path exists
        #   without going via another region
        # Any code that wants to find the shortest path, including (if necessary) going via another
        #   region), should call $self->findUniversalPath instead (because it calls this function
        #   anyway, if the two rooms are in the same region, and then proceeds with its own
        #   algorithms if necessary)
        #
        # Expected arguments
        #   $initialNode    - The initial node (a GA::ModelObj::Room)
        #   $targetNode     - The target node (a GA::ModelObj::Room in the same region)
        #
        # Optional arguments
        #   $avoidHazardsFlag
        #                   - If set to TRUE, the path won't use any rooms with a room flag on the
        #                       hazardous room flags list (GA::Client->constRoomHazardHash). If set
        #                       to FALSE (or 'undef'), those rooms can be used
        #                   - NB $self->avoidHazardsFlag specifies whether pathfinding functions
        #                       should avoid hazardous rooms by default, or not. It's up to the
        #                       calling function to decide whether to use it, and to set the value
        #                       of this argument accordingly
        #   $otherHazardListRef
        #                   - An optional reference to a list of room flags that should be
        #                       considered hazardous for the purposes of this algorithm (not an
        #                       error if it contains duplicate room flags, or if it contains room
        #                       flags already on the hazardous room flags list). Can be 'undef' or
        #                       a reference to an empty list
        #                   - NB Room flags in this list are considered hazardous, even if
        #                       $avoidHazardsFlag is FALSE
        #   $avoidAdjacentFlag
        #                   - If set to TRUE, the algorithm won't use rooms in adjacent regions,
        #                       regardless of the value of $self->adjacentMode. If set to FALSE (or
        #                       'undef', the value of $self->adjacentMode applies
        #   $adjacentHashRef
        #                   - An optional hash of adjacent regions, set (in some situations) when
        #                       the calling function is $self->findUniversalPath. If defined, the
        #                       keys in the hash are the model numbers of regions that are
        #                       adjacent to $initialNode's parent region (the meaning of 'adjacent'
        #                       depends on $self->adjacentCount). $initialNode's parent region also
        #                       exists in the hash. If 'undef', this function fetches the list of
        #                       adjacent regions itself, if it needs to
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns two list references. The first reference contains a list of
        #       GA::ModelObj::Room objects on the shortest path between the rooms $initialNode and
        #       $targetNode (inclusive). The second reference contains a list of GA::Obj::Exit
        #       objects used to move along the path. The first list contains exactly one more item
        #       than the second (exception: if no path can be found, both lists are empty)

        my (
            $self, $initialNode, $targetNode, $avoidHazardsFlag, $otherHazardListRef,
            $avoidAdjacentFlag, $adjacentHashRef, $check,
        ) = @_;

        # Local variables
        my (
            $currentNode, $path, $openListObj, $nodeHashRef, $pathRoomListRef, $pathExitListRef,
            @emptyList,
            %hazardHash, %adjacentHash,
        );

        # Check for improper arguments
        if (! defined $initialNode || ! defined $targetNode || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findPath', @_);
            return @emptyList;
        }

        # Create a combined hash of hazardous room flags (whose rooms must be avoided by the
        #   algorithm). If the function returns an empty hash, then all rooms can be used
        if (! defined $otherHazardListRef) {
            %hazardHash = $self->compileRoomHazards($avoidHazardsFlag);
        } else {
            %hazardHash = $self->compileRoomHazards($avoidHazardsFlag, @$otherHazardListRef);
        }

        # If $self->adjacentMode is 'near', meaning that we can use adjacent regions, and if the
        #   calling function didn't supply a hash of adjacent regions, compile our own
        if ($avoidAdjacentFlag) {

            # (The call to $self->doAStar needs a hash reference, even an empty one)
            $adjacentHashRef = {};

        } elsif (! defined $adjacentHashRef) {

            if ($self->adjacentMode eq 'near') {

                %adjacentHash = $self->compileAdjacentRegions($initialNode->parent);
            }

            # (The call to $self->doAStar needs a hash reference, even an empty one)
            $adjacentHashRef = \%adjacentHash;
        }

        # Create the open list, using a binomial heap
        $openListObj = Games::Axmud::Obj::Heap->new();
        # Create a reference to a hash of nodes, in the form
        #   $nodeHash{room_object} = node
        # ...where 'room_object' is a GA::ModelObj::Room, and 'node' is a GA::Node::AStar object
        $nodeHashRef = {};

        # Create a node for the initial room
        $currentNode = Games::Axmud::Node::AStar->new(
            $initialNode,   # A GA::ModelObj::Room
            0,              # Initial G score
            0,              # Initial H score
        );

        # Add this node to the open list
        $currentNode->ivPoke('inOpenFlag', TRUE);
        $openListObj->add($currentNode);

        # Perform the A* algorithm, starting at the room $initialNode, and aiming for the room
        #   $targetNode
        $self->doAStar($targetNode, $openListObj, $nodeHashRef, \%hazardHash, $adjacentHashRef);

        # We can now use the nodes stored in $openListObj to find the shortest route, by tracing the
        #   path from the target room, and using the parent of each node in turn (in the standard
        #   way)
        # Get two list references, one containing the rooms in the shortest path between
        #   $initialNode and $targetNode, and the other containing the exits to move along the path
        ($pathRoomListRef, $pathExitListRef) = $self->fillPath_aStar(
            $targetNode,
            $openListObj,
            $nodeHashRef
        );

        return ($pathRoomListRef, $pathExitListRef);
    }

    sub compileRoomHazards {

        # Called by $self->findPath and ->smoothPath
        # Compiles a hash of room flags that should be considered hazardous, for the purposes of the
        #   A-star algorithm
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $avoidHazardsFlag
        #                   - If set to TRUE, the path won't use any rooms with a room flag on the
        #                       hazardous room flags list (GA::Client->constRoomHazardHash). If set
        #                       to FALSE (or 'undef'), those rooms can be used
        #                   - NB $self->avoidHazardsFlag specifies whether pathfinding functions
        #                       should avoid hazardous rooms by default, or not. It's up to the
        #                       calling function to decide whether to use it, and to set the value
        #                       of this argument accordingly
        #   @otherHazardList
        #                   - An optional list of room flags that should be considered hazardous,
        #                       for the purposes of this algorithm (not an error if it contains
        #                       duplicate room flags, or if it contains room flags already on the
        #                       hazardous room flags list)
        #                   - NB Room flags in this list are considered hazardous, even if
        #                       $avoidHazardsFlag is FALSE
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise, returns a hash of hazardous room flags (may be an empty hash), in the form
        #       $hazardHash{room_flag} = undef

        my ($self, $avoidHazardsFlag, @otherHazardList) = @_;

        # Local variables
        my %hazardHash;

        # (No improper arguments to check)

        if ($avoidHazardsFlag) {

            # Avoid rooms with the usual hazardous room flags ('blocked_room', etc)
            %hazardHash = $axmud::CLIENT->constRoomHazardHash;
        }

        foreach my $roomFlag (@otherHazardList) {

            # Also avoid rooms that have the specified room flag
            $hazardHash{$roomFlag} = undef;
        }

        return %hazardHash;
    }

    sub compileAdjacentRegions {

        # Called by $self->findPath and ->findUniversalPath when $self->adjacentMode is set to
        #   'near' (meaning that the path can use rooms in adjacent regions)
        # Compiles a hash of regions that are adjacent to a specified region (the meaning of
        #   'adjacent' depends on $self->adjacentCount; 1 means regions can be connected A-B, 2
        #   means regions can be connected A-B-C, etc. 0 means don't use adjacent regions right now)
        # The hash includes the specified region
        #
        # Expected arguments
        #   $origNum    - The number of a region, representing the parent region of the first room
        #                   in a path yet to be calculated
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise returns a hash containing $origNum and all of its adjacent regions in the form
        #       $adjacentHash{region_number} = undef

        my ($self, $origNum, $check) = @_;

        # Local variables
        my (
            @regionList,
            %emptyHash, %checkHash, %returnHash,
        );

        # Check for improper arguments
        if (! defined $origNum || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->compileAdjacentRegions', @_);
            return %emptyHash;
        }

        if ($self->adjacentCount == 0) {

            # Can't use adjacent regions right now, but the hash must still contain the specified
            #   region
            $returnHash{$origNum} = undef;

            return %returnHash;
        }

        # Compile a hash of all regions. If the value of $self->adjacentCount is high enough that
        #   every region is adjacent to $regionNum, then we can stop searching immediately
        foreach my $regionNum ($self->ivKeys('regionModelHash')) {

            if ($regionNum != $origNum) {

                $checkHash{$regionNum} = undef;
            }
        }

        # Now check each region in turn, starting with $regionNum, then its connection regions,
        #   then all of their connecting regions, and so on
        push (@regionList, $origNum);
        # (%returnHash must contain at least the specified region)
        $returnHash{$origNum} = undef;

        for (my $count = 0; $count < $self->adjacentCount; $count++) {

            my @nextList;

            foreach my $regionNum (@regionList) {

                my $regionmapObj = $self->findRegionmap($regionNum);

                foreach my $otherNum ($regionmapObj->ivValues('regionExitHash') ) {

                    if ($otherNum != $origNum && ! exists $returnHash{$otherNum}) {

                        # This region is adjacent...
                        $returnHash{$otherNum} = undef;
                        # ...so check its region exits on the next iteration of the for... loop
                        push (@nextList, $otherNum);

                        # Have we used up every region?
                        delete $checkHash{$otherNum};
                        if (! %checkHash) {

                            # Yes, we have, so we can stop searching now
                            return %returnHash;
                        }
                    }
                }
            }

            # On the next iteration of the for... loop, check all of the adjacent regions found
            #   during this iteration
            @regionList = @nextList;
        }

        # Operation complete
        return %returnHash;
    }

    sub checkRoomHazards {

        # Called by $self->getSurrounding_aStar
        # Checks whether any of a room's list of room flags is on a list of hazardous room flags,
        #   specified by the initial call to ->findPath (not necessarily the same list stored in
        #   GA::Client->constRoomHazardHash)
        #
        # Expected arguments
        #   $roomObj        - The GA::ModelObj::Room object to check
        #
        # Optional arguments
        #   $hazardHashRef  - Reference to a hash of room flags. The path won't use any rooms with a
        #                       room flag stored as a key in this hash. If an empty hash, all rooms
        #                       are considered
        #
        # Return values
        #   'undef' on improper arguments, if the room has no room flags, or if none of the room's
        #       list of room flags are on the hazardous flags list
        #   1 if any of the room's list of room flags are on the hazardous flags list

        my ($self, $roomObj, $hazardHashRef, $check) = @_;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $hazardHashRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkRoomHazards', @_);
        }

        # Check each flag in turn
        foreach my $flag ($roomObj->ivKeys('roomFlagHash')) {

            if (exists $$hazardHashRef{$flag}) {

                # This room should be avoided by the pathfinding routines
                return 1;
            }
        }

        # The room can be used by the pathfinding routines
        return undef;
    }

    sub smoothPath {

        # Called by $self->processPathCallback
        # After a path has been found (following a call to $self->findPath or
        #   $self->findUniversalPath), this function can optionally be called to remove jagged edges
        #   from the paths typically produced by the A* and Dijkstra algorithms
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $roomListRef    - A reference to a list containing a series of GA::ModelObj::Room
        #                       objects along the path between the initial and target rooms
        #   $exitListRef    - A reference to a list containing the GA::Obj::Exit objects used to
        #                       move along the path (contains one less elements than the list
        #                       referenced by $roomListRef)
        #
        # Optional arguments
        #   $avoidHazardsFlag
        #                   - If set to TRUE, the path won't use any rooms with a room flag on the
        #                       hazardous room flags list (GA::Client->constRoomHazardHash). If set
        #                       to FALSE (or 'undef'), those rooms can be used
        #                   - NB $self->avoidHazardsFlag specifies whether pathfinding functions
        #                       should avoid hazardous rooms by default, or not. It's up to the
        #                       calling function to decide whether to use it, and to set the value
        #                       of this argument accordingly
        #   @otherHazardList
        #                   - An optional list of room flags that should be considered hazardous,
        #                       for the purposes of this algorithm (not an error if it contains
        #                       duplicate room flags, or if it contains room flags already on the
        #                       hazardous room flags list)
        #                   - NB Room flags in this list are considered hazardous, even if
        #                       $avoidHazardsFlag is FALSE
        #
        # Return values
        #   Returns an empty list on improper arguments
        #   Otherwise, returns a list containing the modified $roomListRef and $exitListRef, in the
        #       form (room_list_reference, exit_list_reference)

        my ($self, $session, $roomListRef, $exitListRef, $avoidHazardsFlag, @otherHazardList) = @_;

        # Local variables
        my (
            @emptyList,
            %hazardHash, %vectorHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $roomListRef || ! defined $exitListRef) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->smoothPath', @_);
            return @emptyList;
        }

        # Create a combined hash of hazardous room flags (whose rooms must be avoided by the
        #   algorithm). If the function returns an empty hash, then all rooms can be used
        %hazardHash = $self->compileRoomHazards($avoidHazardsFlag, @otherHazardList);

        # The principle of A*/Dijkstra post-processing is to compare two rooms, numbered n and (n+2)
        # If there is a clear line of sight between them (if we can move using one of ten primary
        #   directions from (n) to (n+2)), and if there is exactly one room between them, in the
        #   line of site, that is not room (n+1), then we can swap room (n+1) to the room directly
        #   between rooms (n) and (n+2)
        # So, this path:    Is smoothed to this one:
        #    X                  X   n
        #     X                 X   n+1
        #    X                  X   n+2 n
        #   X                   X       n+1
        #    X                  X       n+2

        # Firstly, $roomListRef must contain at least three rooms
        if (@$roomListRef < 3) {

            # Return the list references, unmodified
            return ($roomListRef, $exitListRef);
        }

        # GA::Win::Map->constVectorHash contains unit vectors in each of the primary directions
        #   e.g. $hash{'north'} = [0, -1, 0]
        #   e.g. $hash{'south'} = [0, 1, 0]
        # Import the hash
        %vectorHash = $session->mapWin->constVectorHash;

        # Smooth each sub-group of rooms (n, n+1 and n+2)
        OUTER: for (my $index = 0; $index < ((scalar @$roomListRef) - 2); $index++) {

            my (
                $roomN, $roomN1, $roomN2, $exitN, $exitN1, $xGap, $yGap, $zGap, $largestGap,
                $vectorRef, $matchListRef, $flag,
            );

            $roomN = $$roomListRef[$index];         # n
            $roomN1 = $$roomListRef[$index + 1];    # n + 1
            $roomN2 = $$roomListRef[$index + 2];    # n + 2
            $exitN = $$exitListRef[$index];         # n
            $exitN1 = $$exitListRef[$index + 1];    # n + 1

            # All three rooms must be in the same region, and none of the exits between them may be
            #   'broken' exits
            if (
                $roomN->parent != $roomN1->parent
                || $roomN->parent != $roomN2->parent
                || $exitN->brokenFlag
                || $exitN1->brokenFlag
            ) {
                next OUTER;
            }

            # Find the vector between (n) and (n+2), expressed as ($xGap, $yGap, $zGap)
            $xGap = $roomN2->xPosBlocks - $roomN->xPosBlocks;
            $yGap = $roomN2->yPosBlocks - $roomN->yPosBlocks;
            $zGap = $roomN2->zPosBlocks - $roomN->zPosBlocks;

            # Find the largest distance between the rooms along a single axis
            $largestGap = abs($xGap);
            if (abs($yGap) > $largestGap) {

                $largestGap = abs($yGap);
            }
            if (abs($zGap) > $largestGap) {

                $largestGap = abs($zGap);
            }

            # We need a gap of at least two blocks between (n) and (n+2)
            if ($largestGap < 2) {

                next OUTER;
            }

            # Use the hash to find a line of sight between (n) and (n+2) in one of the primary
            #   directions. Don't look further away than $largestGap
            CENTRE: for (my $count = 2; $count <= $largestGap; $count++) {

                foreach my $primaryDir (keys %vectorHash) {

                    # Get a reference to a list in the form [0, -1, 0]
                    my $matchListRef = $vectorHash{$primaryDir};

                    # Does this vector, added to the position of (n), give us the position of (n+2)?
                    if (
                        ($roomN->xPosBlocks + ($$matchListRef[0] * $count))
                            == $roomN2->xPosBlocks
                        && ($roomN->yPosBlocks + ($$matchListRef[1] * $count))
                            == $roomN2->yPosBlocks
                        && ($roomN->zPosBlocks + ($$matchListRef[2] * $count))
                            == $roomN2->zPosBlocks
                    ) {
                        $vectorRef = $matchListRef;
                        last CENTRE;
                    }
                }
            }

            if (! $vectorRef) {

                # No line of sight between (n) and (n+2) found
                next OUTER;
            }

            # There is a line of sight between (n) and (n+2) in one of the primary directions, which
            #   we expressed as a vector $matchListRef in the form [0, -1, 0] (for north) or
            #   [0, 1, 0] (for south), etc
            # Now, does room (n+1) also lie in this line of sight?
            CENTRE: for (my $count = 1; $count < $largestGap; $count++) {

                if (
                    ($roomN->xPosBlocks + ($$vectorRef[0] * $count))
                        == $roomN1->xPosBlocks
                    && ($roomN->yPosBlocks + ($$vectorRef[1] * $count))
                        == $roomN1->yPosBlocks
                    && ($roomN->zPosBlocks + ($$vectorRef[2] * $count))
                        == $roomN1->zPosBlocks
                ) {
                    $flag = TRUE;
                    last CENTRE;
                }
            }

            if ($flag) {

                # All three rooms are in the same line of site, so we don't need to smooth the path
                #   here
                next OUTER;
            }

            # The path is in the form
            #   X   (n)
            #   oX  (n+1)
            #   X   (n+2)
            # Now we look for a room anywhere along the line of sight between (n) and (n+2), looking
            #   for a new room, m, which can be reached via a single exit from room (n), and which
            #   can reach room (n+2) via a single exit - a room like the one marked on the diagram
            #   above as 'o'
            CENTRE: for (my $count = 1; $count < $largestGap; $count++) {

                my ($newRoomNum, $newRoomObj, $firstExitObj, $secondExitObj);

                # See if there's a room at the location marked as 'o', somewhere in the line of site
                #   between (n) and (n+2)
                $newRoomNum = $session->mapWin->currentRegionmap->fetchRoom(
                    $roomN->xPosBlocks + ($$vectorRef[0] * $count),
                    $roomN->yPosBlocks + ($$vectorRef[1] * $count),
                    $roomN->zPosBlocks + ($$vectorRef[2] * $count),
                );

                if ($newRoomNum) {

                    $newRoomObj = $self->ivShow('modelHash', $newRoomNum);

                    # Can this new room be reached from room (n)?
                    INNER: foreach my $thisExitName ($roomN->sortedExitList) {

                        my ($thisExitNum, $thisExitObj);

                        # (Investigate directions in order, so that primary directions are checked
                        #   first)
                        $thisExitNum = $roomN->ivShow('exitNumHash', $thisExitName);
                        $thisExitObj = $self->ivShow('exitModelHash', $thisExitNum);

                        if (
                            $thisExitObj->destRoom
                            && $thisExitObj->destRoom == $newRoomObj->number
                        ) {
                            # Success! $newRoom can be reached from room (n)
                            $firstExitObj = $thisExitObj;
                            last INNER;
                        }
                    }

                    if (! $firstExitObj) {

                        # Can't travel from (n) to the new room - look for a different room
                        next CENTRE;
                    }

                    # Can this new room reach room (n+2) in a single step?
                    INNER: foreach my $thisExitName ($newRoomObj->sortedExitList) {

                        my ($thisExitNum, $thisExitObj);

                        $thisExitNum = $newRoomObj->ivShow('exitNumHash', $thisExitName);
                        $thisExitObj = $self->ivShow('exitModelHash', $thisExitNum);

                        if (
                            $thisExitObj->destRoom
                            && $thisExitObj->destRoom == $roomN2->number
                        ) {
                            # Double success! $newRoom can reach room (n+2)
                            $secondExitObj = $thisExitObj;
                            last INNER;
                        }
                    }

                    if ($secondExitObj) {

                        # Rooms (n), $newRoomObj and (n+2) all lie on the same line of sight, but
                        #   the rooms (n), (n+1) and (n+2) do not

                        # Check that $newRoomObj and the exits between $newRoomObj and the
                        #   surrounding rooms are available for paths (using the same rationale
                        #   as $self->getSurrounding_aStar)
                        if (
                            ! $newRoomObj->exclusiveFlag
                            && ! $self->checkRoomHazards($newRoomObj, \%hazardHash)
                        ) {
                            # $newRoomObj is acceptable, so use it to replace room (n+1)
                            $$roomListRef[$index + 1] = $newRoomObj;
                            # Replace the exits leading from (n) and leading to (n+2)
                            $$exitListRef[$index] = $firstExitObj;
                            $$exitListRef[$index + 1] = $secondExitObj;

                            next OUTER;
                        }
                    }
                }
            }
        }

        # Operation complete
        return ($roomListRef, $exitListRef);
    }

    sub doAStar {

        # Called by $self->findPath
        # Performs the A* algorithm on rooms in the current region, to find the shortest route
        #   between two rooms (as described in the comments for the calling function)
        #
        # Expected arguments
        #   $targetNode     - The target node (a GA::ModelObj::Room)
        #   $openListObj    - The A* open list, stored in a binomial heap object
        #   $nodeHashRef    - Reference to the hash of nodes, in the form $hash{room} = node
        #   $hazardHashRef  - Reference to a hash of room flags. The path won't use any rooms with a
        #                       room flag stored as a key in this hash. If an empty hash, all rooms
        #                       are considered
        #   $adjacentHashRef
        #                   - Reference to a hash of adjacent regions. An empty hash if adjacent
        #                       regions are not to be used
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $targetNode, $openListObj, $nodeHashRef, $hazardHashRef, $adjacentHashRef,
            $check,
        ) = @_;

        # Local variables
        my ($currentNode, $gScore, $nodeListRef);

        # Check for improper arguments
        if (
            ! defined $targetNode || ! defined $openListObj || ! defined $nodeHashRef
            || ! defined $hazardHashRef || ! defined $adjacentHashRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->doAStar', @_);
        }

        # Perform the algorithm until we either find the shortest path to the target room or run out
        #   of rooms
        OUTER: while(
            defined $openListObj->top()
            && ($openListObj->top()->roomObj ne $targetNode)
        ) {
            # Remove the first remaining node in the open list
            $currentNode = $openListObj->extract_top();
            $currentNode->ivPoke('inOpenFlag', FALSE);

            # Get the surrounding nodes. $nodeListRef is a list reference, which in turn contains a
            #   number of list references, each representing a surrounding node (one linked to
            #   $currentNode by a single exit)
            # The contained list references are in the form
            #   [GA::ModelObj::Room, cost, H-Score]
            $nodeListRef = $self->getSurrounding_aStar(
                $currentNode->roomObj,
                $targetNode,
                $hazardHashRef,
                $adjacentHashRef,
            );

            # Process each surrounding node
            INNER: foreach my $nodeRef (@$nodeListRef) {

                my (
                    $surroundRoomObj, $surroundExitObj, $surroundCost, $surroundHScore,
                    $surroundNode, $currentGScore, $possibleGScore,
                );

                ($surroundRoomObj, $surroundExitObj, $surroundCost, $surroundHScore) = @$nodeRef;

                # Skip this node if it's in the closed list
                if (
                    exists $$nodeHashRef{$surroundRoomObj}
                    && ! $$nodeHashRef{$surroundRoomObj}->inOpenFlag
                ) {
                    next INNER;
                }

                # If the node isn't in the open list, add it to the open list
                if (! exists $$nodeHashRef{$surroundRoomObj}) {

                    $surroundNode = Games::Axmud::Node::AStar->new(
                        $surroundRoomObj,                           # GA::ModelObj::Room
                        $currentNode->gScore + $surroundCost,       # G score
                        $surroundHScore,                            # H score
                    );

                    $surroundNode->ivPoke('parent', $currentNode);
                    $surroundNode->ivPoke('arriveExitObj', $surroundExitObj);
                    $surroundNode->ivPoke('cost', $surroundCost);
                    $surroundNode->ivPoke('inOpenFlag', TRUE);
                    $$nodeHashRef{$surroundRoomObj} = $surroundNode;
                    $openListObj->add($surroundNode);

                } else {

                    # Otherwise the node is already in the open list. Check to see if it's cheaper
                    #   to go through the current room, compared to the previous path
                    $surroundNode = $$nodeHashRef{$surroundRoomObj};
                    $currentGScore = $surroundNode->gScore;
                    $possibleGScore = $currentNode->gScore + $surroundCost;

                    if ($possibleGScore < $currentGScore) {

                        # Change the parent...
                        $surroundNode->ivPoke('parent', $currentNode);
                        # ...and the exit used to get there
                        $surroundNode->ivPoke('arriveExitObj', $surroundExitObj);
                        $surroundNode->ivPoke('gScore', $possibleGScore);
                        $openListObj->decrease_key($surroundNode);
                    }
                }
            }
        }

        # A* algorithm complete
        return 1;
    }

    sub fillPath_aStar {

        # Called by $self->findPath, after a call to $self->doAStar
        # The initial room and the target room are now linked, along the shortest path between them,
        #   by a list of rooms, each the parent of the next room along the path
        # Compile two lists: a list of the rooms, from the initial room to the target room
        #   (inclusive), and a corresponding list of exits used to travel between them
        #
        # Expected arguments
        #   $targetNode     - The target node (a GA::ModelObj::Room)
        #   $openListObj    - The A* open list, stored in a binomial heap object
        #   $nodeHashRef    - The hash of nodes, in the form $hash{room} = node
        #
        # Return values
        #   Returns an empty list on improper arguments
        #   Otherwise returns a list containing two list references. The first reference contains a
        #       list of GA::ModelObj::Room objects on the shortest path between the initial and
        #       target rooms (inclusive). The second reference contains a list of GA::Obj::Exit
        #       objects to move between them. The first list contains exactly one more item than the
        #       second (exception: if no path can be found, both lists are empty)

        my ($self, $targetNode, $openListObj, $nodeHashRef, $check) = @_;

        # Local variables
        my (
            $currentNode,
            @emptyList, @roomList, @exitList,
        );

        # Check for improper arguments
        if (
            ! defined $targetNode || ! defined $openListObj || ! defined $nodeHashRef
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->fillPath_aStar', @_);
            return @emptyList;
        }

        if (exists $$nodeHashRef{$targetNode}) {
            $currentNode = $$nodeHashRef{$targetNode};
        } else {
            $currentNode = $openListObj->top();
        }

        while (defined $currentNode) {

            unshift(@roomList, $currentNode->roomObj);

            if (defined $currentNode->arriveExitObj) {

                unshift(@exitList, $currentNode->arriveExitObj);
            }

            $currentNode = $currentNode->parent;
        }

        return (\@roomList, \@exitList);
    }

    sub getSurrounding_aStar {

        # Called by $self->doAStar
        # Get a list of nodes surrounding the current one
        # In this function, the current node is a room. We get a list of all the room's exits, and
        #   then compile a list of those exits' destination rooms
        #
        # Expected arguments
        #   $currentNode    - The current node (a GA::ModelObj::Room)
        #   $targetNode     - The target node (a GA::ModelObj::Room)
        #   $hazardHashRef  - Reference to a hash of room flags. The path won't use any rooms with a
        #                       room flag stored as a key in this hash. If an empty hash, all rooms
        #                       are considered
        #   $adjacentHashRef
        #                   - Reference to a hash of adjacent regions. An empty hash if adjacent
        #                       regions are not to be used
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a list reference, containing a series of list references, one for each
        #       surrounding node. The inner list references are in the form:
        #       [
        #           surround_node_room_object,
        #           surrounding_node_cost,
        #           surrounding_node_g_score,
        #       ]

        my ($self, $currentNode, $targetNode, $hazardHashRef, $adjacentHashRef, $check) = @_;

        # Local variables
        my (
            @returnList,
            %roomHash,
        );

        # Check for improper arguments
        if (
            ! defined $currentNode || ! defined $targetNode || ! defined $hazardHashRef
            || ! defined $adjacentHashRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->getSurrounding_aStar', @_);
        }

        # Get a list of exits from the room $currentNode
        if ($currentNode->exitNumHash) {

            # Get a list of destination rooms. Some rooms have multiple exits leading to the same
            #   destination room, so we use a hash to store the destination rooms
            # The hash is in the form
            #   $hash{destination_room_number} = exit_object_to_get_there
            OUTER: foreach my $exitNum ($currentNode->ivValues('exitNumHash')) {

                my ($exitObj, $destRoomObj);

                $exitObj = $self->ivShow('exitModelHash', $exitNum);
                if ($exitObj->destRoom) {

                    $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);

                    # Depending on the $self->adjacentMode and $adjacentHashRef, we can either use
                    #   region exits, or not
                    if (
                        $exitObj->regionFlag
                        && (
                            $self->adjacentMode ne 'near'
                            || ! exists $$adjacentHashRef{$destRoomObj->parent}
                        )
                    ) {
                        # Can't use this region exit or its destination room
                        next OUTER;
                    }

                    # We don't use a destination room if it has any of the room flags in
                    #   $hazardHashRef
                    # We also don't use exits that have shadow exits (it's normally better to use
                    #   the 'north' shadow exit, rather than the 'open curtains' exit) and exits
                    #   which lead to rooms that can only be visited by certain guilds, races and
                    #   characters (etc); the latter restrictions saves us a whole lot of bother
                    if (
                        ! $destRoomObj->exclusiveFlag
                        && ! $exitObj->shadowExit
                        && ! $self->checkRoomHazards($destRoomObj, $hazardHashRef)
                    ) {
                        $roomHash{$exitObj->destRoom} = $exitObj;
                    }
                }
            }
        }

        # For each destination room, prepare a list reference containing details about that node
        foreach my $destNum (keys %roomHash) {

            my $destRoomObj = $self->ivShow('modelHash', $destNum);

            push (@returnList,
                [
                    $destRoomObj,                                   # GA::ModelObj::Room
                    $roomHash{$destNum},                            # GA::Obj::Exit
                    1,                                              # Cost
                    $self->calcHScore($destRoomObj, $targetNode),   # H score
                ]
            );
        }

        # Return a list reference, containing some list references
        return \@returnList;
    }

    sub calcHScore {

        # Called by $self->getSurrounding_aStar
        # Calculates the H score for a room node, using the Manhattan heuristic
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room for this node
        #   $targetNode - The target node (also a GA::ModelObj::Room)
        #
        # Return values
        #   The H score (an integer)

        my ($self, $roomObj, $targetNode, $check) = @_;

        # Local variables
        my ($xLength, $yLength, $zLength);

        # Check for improper arguments
        if (! defined $roomObj || ! defined $targetNode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->calcHScore', @_);
        }

        # Get absolute distances on the x, y and z axes
        $xLength = abs($roomObj->xPosBlocks - $targetNode->xPosBlocks);
        $yLength = abs($roomObj->yPosBlocks - $targetNode->yPosBlocks);
        $zLength = abs($roomObj->zPosBlocks - $targetNode->zPosBlocks);

        return ($xLength + $yLength + $zLength);
    }

    # Dijkstra algorithm (used to find a path between two rooms in different regions)

    sub findUniversalPath {

        # Can be called by any function
        #
        # Dijkstra algorithm to find a path between two rooms in different regions, based on
        #   AI::Pathfinding::AStar by Aaron Dalton
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $initialRoomObj - The initial room (a GA::ModelObj::Room)
        #   $targetRoomObj  - The target room (a GA::ModelObj::Room), usually in a different region
        #                       (but it doesn't matter if they are in the same region)
        #
        # Optional arguments
        #   $avoidHazardsFlag
        #                   - If set to TRUE, the path won't use any rooms with a room flag on the
        #                       hazardous room flags list (GA::Client->constRoomHazardHash). If set
        #                       to FALSE (or 'undef'), those rooms can be used
        #                   - NB $self->avoidHazardsFlag specifies whether pathfinding functions
        #                       should avoid hazardous rooms by default, or not. It's up to the
        #                       calling function to decide whether to use it, and to set the value
        #                       of this argument accordingly
        #   $otherHazardListRef
        #                   - An optional list of room flags that should be considered hazardous,
        #                       for the purposes of this algorithm (not an error if it contains
        #                       duplicate room flags, or if it contains room flags already on the
        #                       hazardous room flags list)
        #                   - NB This list is IGNORED if the initial and target rooms are not in
        #                       the same region
        #                   - NB Room flags in this list are considered hazardous, even if
        #                       $avoidHazardsFlag is FALSE
        #   $avoidAdjacentFlag
        #                   - If set to TRUE and if the initial and target rooms are in the same
        #                       region, the algorithm won't use rooms in adjacent regions,
        #                       regardless of the value of $self->adjacentMode. If set to FALSE (or
        #                       'undef') and the initial/target rooms are in the same region, the
        #                       value of $self->adjacentMode applies
        #
        # Return values
        #   An empty list on improper arguments or if no path can be found between the initial and
        #       target rooms
        #   Otherwise, returns two list references. The first reference contains a list of
        #       GA::ModelObj::Room objects on the shortest path between the rooms $initialRoomObj
        #       and $targetRoomObj (inclusive). The second reference contains a list of
        #       GA::Obj::Exit objects used to move along the path. The first list contains exactly
        #       one more item than the second

        my (
            $self, $session, $initialRoomObj, $targetRoomObj, $avoidHazardsFlag,
            $otherHazardListRef, $avoidAdjacentFlag, $check,
        ) = @_;

        # Local variables
        my (
            $roomListRef, $exitListRef, $dummyRoomObj, $dummyExitObj, $initialRegionmapObj, $index,
            $dummyRoomObj2, $dummyExitObj2, $targetRegionmapObj, $openListObj, $nodeHashRef,
            $currentNode, $pathRoomListRef, $pathExitListRef,
            @emptyList, @initialExitNumList, @initialRoomList, @targetExitNumList, @targetRoomList,
            @returnRoomList, @returnExitList,
            %adjacentHash, %universalPathHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $initialRoomObj || ! defined $targetRoomObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->findUniversalPath', @_);
            return @emptyList;
        }

        # Depending on the situation, we might be able to use $self->findPath instead
        if (
            $initialRoomObj->parent == $targetRoomObj->parent
            || $self->adjacentMode eq 'all'
        ) {
            ($roomListRef, $exitListRef) = $self->findPath(
                $initialRoomObj,
                $targetRoomObj,
                $avoidHazardsFlag,
                $otherHazardListRef,
                $avoidAdjacentFlag,
            );

            if (defined $roomListRef && @$roomListRef) {

                return ($roomListRef, $exitListRef);
            }

        } elsif ($self->adjacentMode eq 'near') {

            # Get a hash of regions that are adjacent to the start room's region (inclusive)
            if (! $avoidAdjacentFlag) {

                %adjacentHash = $self->compileAdjacentRegions($initialRoomObj->parent);
            }

            ($roomListRef, $exitListRef) = $self->findPath(
                $initialRoomObj,
                $targetRoomObj,
                $avoidHazardsFlag,
                $otherHazardListRef,
                $avoidAdjacentFlag,
                \%adjacentHash,
            );

            if (defined $roomListRef && @$roomListRef) {

                return ($roomListRef, $exitListRef);
            }
        }

        # If a call to $self->findPath failed to find a path between the two rooms, or if
        #   $self->findPath wasn't called at all, we can continue with this function's algorithm

        # If any exits in the exit model have been modified, we may need to check and re-calculate
        #   regions paths, before calculating a path between the two rooms
        if ($self->updatePathHash || $self->updateBoundaryHash) {

            $self->updateRegionPaths();
        }

        # The first step is to compile a hash of region paths that traverse every region in the
        #   world model, leading from one region exit to another region exit in the same region
        # At either end of each path is the node we'll use in our Dijkstra algorithm. The nodes are
        #   exits, each equivalent to a GA::Obj::Exit (which may or may not have a twin exit)
        #
        # Each regionmap stores, in its ->regionPathHash, a list of such paths. Each path is
        #   represented by a GA::Obj::RegionPath
        # There is a parallel ->safeRegionPathHash which contains paths that avoid rooms with
        #   hazardous room flags
        # If $avoidHazardsFlag is set, we use region paths from ->safeRegionPathHash; otherwise, we
        #   use region paths from ->regionPathHash
        #
        # This function's hash of paths is in the form:
        #   $universalPathHash{begin_exit_number} = hash_reference
        # ...where 'begin_exit_number' is the number of the GA::Obj::Exit at the start of the path
        # Each 'hash_reference' is in the form:
        #   $hash_reference{end_exit_number} = GA::Obj::RegionPath

        # Process each regionmap in turn
        foreach my $regionmapObj ($self->ivValues('regionmapHash')) {

            my %regionPathHash;

            # Get the hash of GA::Obj::RegionPath objects from this regionmap
            if ($avoidHazardsFlag) {
                %regionPathHash = $regionmapObj->safeRegionPathHash;
            } else {
                %regionPathHash = $regionmapObj->regionPathHash;
            }

            foreach my $regionPathObj (values %regionPathHash) {

                # Add the path to our universal hash
                $self->addUniversalPath(\%universalPathHash, $regionPathObj);
            }
        }

        # Now, we need to create some new (temporary) paths, and to add them to %universalPathHash

        # The first set of paths connect $initialRoomObj to every region exit in the same region
        # The Dijkstra algorithm we'll employ uses exits as its nodes. The initial room can have
        #   several exits, any of which might be on the shortest path to the target room. So, we'll
        #   create a dummy room object - with a world model number set to -1 - with a dummy one-way
        #   exit which leads to the initial room
        # When the algorithm is finished, we'll discard the room (and its exit)
        ($dummyRoomObj, $dummyExitObj) = $self->createDummyRoom($session, $initialRoomObj, -1);

        # Get the initial room's regionmap
        $initialRegionmapObj = $self->findRegionmap($initialRoomObj->parent);
        # Get a list of region exits in this regionmap
        @initialExitNumList = $initialRegionmapObj->ivKeys('regionExitHash');
        # From this list, get a list of rooms from which the region exits depart
        foreach my $exitNum (@initialExitNumList) {

            my $exitObj = $self->ivShow('exitModelHash', $exitNum);
            push (@initialRoomList, $self->ivShow('modelHash', $exitObj->parent));
        }

        # Find the shortest path between the initial room (not the dummy room), and each of the
        #   boundary rooms. Use the rooms themselves as nodes
        $index = -1;
        foreach my $boundaryRoomObj (@initialRoomList) {

            my ($miniRoomListRef, $miniExitListRef, $pathObj, $thisExitObj);

            $index++;   # Matching indexes in @initialExitList and @initialRoomList

            ($miniRoomListRef, $miniExitListRef) = $self->findPath(
                $initialRoomObj,
                $boundaryRoomObj,
                $avoidHazardsFlag,      # Avoid hazards, or not
                undef,
                TRUE,                   # Don't use adjacent regions
            );

            # If a path was found...
            if (defined $miniRoomListRef && @$miniRoomListRef) {

                # Add the dummy room (and its dummy exit) to the beginning of the path
                unshift(@$miniRoomListRef, $dummyRoomObj);
                unshift(@$miniExitListRef, $dummyExitObj);

                # Create a GA::Obj::RegionPath to stored this path. However, don't add it to the
                #   regionmap's hash of region paths, in the normal way; add it only to our
                #   %universalPathHash
                $thisExitObj = $self->ivShow('exitModelHash', $initialExitNumList[$index]);

                $pathObj = Games::Axmud::Obj::RegionPath->new(
                    $session,
                    $dummyExitObj->number,
                    $thisExitObj->number,
                    $miniRoomListRef,
                    $miniExitListRef,
                );

                if ($pathObj) {

                    $self->addUniversalPath(\%universalPathHash, $pathObj);
                }
            }
        }

        # Do the same for the target region. Find the shortest paths which connect the target room
        #   with every region exit in the same region

        # Once again we need a temporary room, and a temporary exit from the target room which leads
        #   to the temporary room. Both are removed at the end
        ($dummyRoomObj2, $dummyExitObj2) = $self->createDummyRoom($session, $targetRoomObj, -2);

        # Get the target room's regionmap
        $targetRegionmapObj = $self->findRegionmap($targetRoomObj->parent);
        # Get a list of region exits in this regionmap
        @targetExitNumList = $targetRegionmapObj->ivKeys('regionExitHash');
        # From this list, get a list of rooms from which the region exits depart
        foreach my $exitNum (@targetExitNumList) {

            my $exitObj = $self->ivShow('exitModelHash', $exitNum);
            push (@targetRoomList, $self->ivShow('modelHash', $exitObj->parent));
        }

        # Find the shortest path between the target room (not the dummy room), and each of the
        #   boundary rooms. Use the rooms themselves as nodes
        $index = -1;
        foreach my $boundaryRoomObj (@targetRoomList) {

            my ($miniRoomListRef, $miniExitListRef, $pathObj, $thisExitObj);

            $index++;       # Matching indexes in @targetExitList and @targetRoomList

            ($miniRoomListRef, $miniExitListRef) = $self->findPath(
                $boundaryRoomObj,
                $targetRoomObj,
                $avoidHazardsFlag,      # Avoid hazards, or not
                undef,
                TRUE,                   # Don't use adjacent regions
            );

            # If a path was found...
            if (defined $miniRoomListRef && @$miniRoomListRef) {

                # Add the dummy room (and its dummy exit) to the end of the path
                push(@$miniRoomListRef, $dummyRoomObj2);
                push(@$miniExitListRef, $dummyExitObj2);

                # Create a GA::Obj::RegionPath to stored this path. However, don't add it to the
                #   regionmap's hash of region paths, in the normal way; add it only to our
                #   %universalPathHash
                $thisExitObj = $self->ivShow('exitModelHash', $targetExitNumList[$index]);

                $pathObj = Games::Axmud::Obj::RegionPath->new(
                    $session,
                    $thisExitObj->number,
                    $dummyExitObj2->number,
                    $miniRoomListRef,
                    $miniExitListRef,
                );

                if ($pathObj) {

                    $self->addUniversalPath(\%universalPathHash, $pathObj);
                }
            }
        }

        # %universalPathHash now contains a collection of paths that traverse the whole world model,
        #   linking together all connected regions
        # Now we run the Dijkstra algorithm (a modified A* algorithm in which the h-score is
        #   always 0) to get the shortest path between the initial and target rooms

        # Create the open list, using a binomial heap
        $openListObj = Games::Axmud::Obj::Heap->new();
        # Create a reference to a hash of nodes, in the form
        #   $nodeHashRef{exit_object} = node
        # ...where 'exit_object' is a GA::Obj::Exit, and node is a GA::Node::Dijkstra object
        $nodeHashRef = {};

        # Create a node for the initial exit
        $currentNode = Games::Axmud::Node::Dijkstra->new(
            0,                  # Initial G score
            $dummyExitObj,      # Dummy exit object leading to the initial room
        );

        # Add this node to the open list
        $currentNode->ivPoke('inOpenFlag', TRUE);
        $openListObj->add($currentNode);

        # Perform the Dijkstra algorithm, starting at the exit $dummyExitObj, and aiming for the
        #   exit $dummyExitObj2
        $self->doDijkstra($dummyExitObj2, $openListObj, $nodeHashRef, \%universalPathHash);

        # We can now use the nodes stored in $openListObj to find the shortest route, by tracing the
        #   path from the target room, and using the parent of each node in turn (in the standard
        #   way)
        # Get two list references, one containing the rooms in the shortest path between
        #   $dummyRoomObj and $dummyRoomObj2, and the other containing the exits to move along the
        #   path
        ($pathRoomListRef, $pathExitListRef) = $self->fillPath_dijkstra(
            $dummyExitObj2,
            $openListObj,
            $nodeHashRef,
            \%universalPathHash
        );

        # The list references $pathRoomListRef and $pathExitListRef contain a list of room and
        #   exit numbers; convert them to lists of the rooms and exits themselves
        foreach my $number (@$pathRoomListRef) {

            push (@returnRoomList, $self->ivShow('modelHash', $number));
        }

        foreach my $number (@$pathExitListRef) {

            push (@returnExitList, $self->ivShow('exitModelHash', $number));
        }

        # @returnRoomList contains the rooms along the path, plus the two dummy rooms at each end.
        #   Remove the dummy rooms
        if (@returnRoomList) {

            if ($returnRoomList[0] eq $dummyRoomObj) {

                shift @returnRoomList;
            }

            if ($returnRoomList[-1] eq $dummyRoomObj2) {

                pop @returnRoomList;
            }
        }

        # Likewise, @returnExitList contains the exits to move along the path, plus the two dummy
        #   exits at each end. Remove the dummy exits, too
        if (@returnExitList) {

            if ($returnExitList[0] eq $dummyExitObj) {

                shift @returnExitList;
            }

            if ($returnExitList[-1] eq $dummyExitObj2) {

                pop @returnExitList;
            }
        }

        # Delete the dummy rooms/objects
        $self->destroyDummyRoom(-1);
        $self->destroyDummyRoom(-2);

        return (\@returnRoomList, \@returnExitList);
    }

    sub doDijkstra {

        # Called by $self->findUniversalPath
        # Performs the Dijkstra algorithm on two nodes, each corresponding to an exit in two
        #   different regions, in order to find the shortest path between them, and therefore the
        #   shortest path between two rooms (as described in the comments for the calling function)
        #
        # Expected arguments
        #   $targetNode      - The target node (a dummy GA::Obj::Exit that the calling function
        #                       created, which leads away from the target room to a dummy
        #                       GA::ModelObj::Room)
        #   $openListObj    - The Dijkstra open list, stored in a binomial heap object
        #   $nodeHashRef    - The hash of nodes, in the form $hash{exit} = node
        #   $universalPathHashRef
        #                   - A hash of paths between the exits, each of which correspond to a node.
        #                       The hash tells us the cost of moving between two nodes
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $targetNode, $openListObj, $nodeHashRef, $universalPathHashRef, $check) = @_;

        # Local variables
        my (
            $currentNode, $gScore, $nodeListRef,
            %twinNodeHash,
        );

        # Check for improper arguments
        if (
            ! defined $targetNode || ! defined $openListObj || ! defined $nodeHashRef
            || ! defined $universalPathHashRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->doDijkstra', @_);
        }

        # Perform the algorithm until we either find the shortest path to the target node or run out
        #   of nodes
        OUTER: while(
            defined $openListObj->top()
            && ($openListObj->top()->exitObj ne $targetNode)
        ) {
            # Remove the first remaining node in the open list
            $currentNode = $openListObj->extract_top();
            $currentNode->ivPoke('inOpenFlag', FALSE);

            # If this exit has a twin exit, we must prevent the twin from being added as a node to
            #   the open list, later in the algorithm
            if ($currentNode->exitObj->twinExit) {

                $twinNodeHash{$currentNode->exitObj->twinExit} = undef;
            }

            # Get the surrounding nodes. $nodeListRef is a list reference, which in turn contains a
            #   number of list references, each representing a surrounding node (one linked to
            #   $currentNode by a single GA::Obj::RegionPath)
            # The contained list references are in the form
            #   [GA::Obj::Exit, cost]
            $nodeListRef = $self->getSurrounding_dijkstra(
                $currentNode->exitObj,
                $universalPathHashRef,
            );

            # Process each surrounding node
            INNER: foreach my $nodeRef (@$nodeListRef) {

                my (
                    $surroundExitObj, $surroundCost, $surroundNode, $currentGScore, $possibleGScore,
                );

                ($surroundExitObj, $surroundCost) = @$nodeRef;

                # Skip this node if it's in the closed list
                if (
                    exists $$nodeHashRef{$surroundExitObj}
                    && ! $$nodeHashRef{$surroundExitObj}->inOpenFlag
                ) {
                    next INNER;

                # Also skip this node if it's in the forbidden (twin) node list
                } elsif (exists $twinNodeHash{$surroundExitObj->number}) {

                    next INNER;
                }

                # If the node isn't in the open list, add it to the open list
                if (! exists $$nodeHashRef{$surroundExitObj}) {

                    $surroundNode = Games::Axmud::Node::Dijkstra->new(
                        $currentNode->gScore + $surroundCost,   # G score
                        $surroundExitObj,                       # GA::Obj::Exit
                    );

                    $surroundNode->ivPoke('parent', $currentNode);
                    $surroundNode->ivPoke('cost', $surroundCost);
                    $surroundNode->ivPoke('inOpenFlag', TRUE);
                    $$nodeHashRef{$surroundExitObj} = $surroundNode;
                    $openListObj->add($surroundNode);

                } else {

                    # Otherwise the node is already in the open list. Check to see if it's cheaper
                    #   to go through the current exit, compared to the previous path
                    $surroundNode = $$nodeHashRef{$surroundExitObj};
                    $currentGScore = $surroundNode->gScore;
                    $possibleGScore = $currentNode->gScore + $surroundCost;

                    if ($possibleGScore < $currentGScore) {

                        # Change the parent
                        $surroundNode->ivPoke('parent', $currentNode);
                        $surroundNode->ivPoke('gScore', $possibleGScore);
                        $openListObj->decrease_key($surroundNode);
                    }
                }
            }
        }

        # Dijkstra algorithm complete
        return 1;
    }

    sub fillPath_dijkstra {

        # Called by $self->findUniversalPath, after a call to $self->doDijkstra
        # The initial room and the target room are now linked, along the shortest path between them,
        #   by a list of nodes, each corresponding to a GA::Obj::Exit. The path begins with a dummy
        #   room connected to the initial room, and another dummy room connected to the target room
        # Compile two lists: a list of the rooms, from one dummy room to the other (inclusive), and
        #   a corresponding list of exits used to travel between them. It's up to the calling
        #   function to remove the dummy rooms (and dummy exits) at the beginning/ends of the list
        #
        # Expected arguments
        #   $targetNode     - The target node (a GA::Obj::Exit object)
        #   $openListRef    - The Dijkstra open list, stored in a binomial heap object
        #   $nodeHashRef    - The hash of nodes, in the form $hash{exit} = node
        #   $universalPathHashRef
        #                   - A hash of paths between the exits which correspond to nodes, which
        #                       tells us the cost of moving between them
        #
        # Return values
        #   Returns an empty list on improper arguments
        #   Otherwise returns a list containing two list references. The first reference contains a
        #       list of GA::ModelObj::Room objects on the shortest path between the two dummy
        #       rooms (inclusive). The second reference contains a list of GA::Obj::Exit objects
        #       to move between them. The first list contains exactly one more item than the second.

        my ($self, $targetNode, $openListObj, $nodeHashRef, $universalPathHashRef, $check) = @_;

        # Local variables
        my (
            $currentNode,
            @emptyList, @nodeList, @roomList, @exitList,
        );

        # Check for improper arguments
        if (
            ! defined $targetNode || ! defined $openListObj || ! defined $nodeHashRef
            || ! defined $universalPathHashRef || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->fillPath_dijkstra', @_);
            return @emptyList;
        }

        if (exists $$nodeHashRef{$targetNode}) {
            $currentNode = $$nodeHashRef{$targetNode};
        } else {
            $currentNode = $openListObj->top();
        }

        while (defined $currentNode) {

            unshift(@nodeList, $currentNode->exitObj);
            $currentNode = $currentNode->parent;
        }

        if (@nodeList) {

            # Everything in @nodeList is a GA::Obj::Exit corresponding to a node along the path
            do {

                my (
                    $thisExitObj, $hashRef, $regionPathObj, $pathListRef,
                    @refList,
                );

                $thisExitObj = shift @nodeList;

                # Find the path between this node, and the next one
                if ($$universalPathHashRef{$thisExitObj->number}) {

                    push (@refList, $$universalPathHashRef{$thisExitObj->number});
                }

                if ($thisExitObj->twinExit && $$universalPathHashRef{$thisExitObj->twinExit}) {

                    push (@refList, $$universalPathHashRef{$thisExitObj->twinExit});
                }

                OUTER: foreach my $hashRef (@refList) {

                    $regionPathObj = $$hashRef{$nodeList[0]->number};
                    if ($regionPathObj) {

                        # In certain circumstances, the shortest region path between two region
                        #   exits, A and B, might go via a room with its own region exit, C
                        # Because the G score for path A-B is the same as the combined G scores for
                        #   two region paths, A-C then C-B, we might have either situation
                        # In the latter situation, the code below has added the Exit B to @exitList
                        #   on the assumption that we're going through that exit; if we aren't, then
                        #   remove it (and remove the corresponding duplicate room that would
                        #   otherwise appear in the final @roomList)
                        if (
                            @roomList
                            && $regionPathObj->roomList
                            && $roomList[-1] == $regionPathObj->ivIndex('roomList', 0)
                        ) {
                            pop @roomList;
                            pop @exitList;
                        }

                        # Add rooms and exits from this region path
                        push (@roomList, $regionPathObj->roomList);
                        push (@exitList, $regionPathObj->exitList);
                        # At region boundaries (exit nodes), we have to add the exit itself
                        if ($exitList[-1] ne $regionPathObj->stopExit) {

                            push (@exitList, $regionPathObj->stopExit);
                        }

                        last OUTER;
                    }
                }

            } until (@nodeList < 2);
        }

        return (\@roomList, \@exitList);
    }

    sub getSurrounding_dijkstra {

        # Called by $self->doDijkstra
        # Get a list of nodes surrounding the current one
        # In this function, the current node corresponds to an exit. We look up this exit in the
        #   hash of GA::Obj::RegionPath objects we created earlier to find all the connecting
        #   nodes
        #
        # Expected arguments
        #   $currentNode
        #       - The current node (a GA::Obj::Exit)
        #   $universalPathHashRef
        #       - A hash of hash references, in the form
        #           $hash{begin_exit_number} = hash_reference
        #         ...where 'begin_exit_number' is the number of the exit at one end of the path
        #       - Each 'hash_reference' is in the form
        #           $hash{end_exit_number} = blessed_ref_of_region_path_object
        #       - The GA::Obj::RegionPath contains the path which connects the two nodes (exits)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a list reference, containing a series of list references, one for each
        #       surrounding node. The inner list references are in the form
        #       [surround_node_exit_object, surrounding_node_cost]

        my ($self, $currentNode, $universalPathHashRef, $check) = @_;

        # Local variables
        my (@refList, @returnList);

        # Check for improper arguments
        if (! defined $currentNode || ! defined $universalPathHashRef || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->getSurrounding_dijkstra',
                @_,
            );
        }

        # Extract hash references from $universalPathHashRef
        if ($$universalPathHashRef{$currentNode->number}) {

            push (@refList, $$universalPathHashRef{$currentNode->number});
        }

        if ($currentNode->twinExit && $$universalPathHashRef{$currentNode->twinExit}) {

            push (@refList, $$universalPathHashRef{$currentNode->twinExit});
        }

        foreach my $hashRef (@refList) {

            foreach my $regionPathObj (values %$hashRef) {

                push (
                    @returnList,
                    [
                        $self->ivShow('exitModelHash', $regionPathObj->stopExit), # Surrounding node
                        $regionPathObj->roomCount,                                # Cost
                    ],
                );
            }
        }

        # Return a list reference, containing some list references
        return \@returnList;
    }

    sub addUniversalPath {

        # Called by $self->findUniversalPath to add a single GA::Obj::RegionPath to a hash of
        #   hashes, in the form
        #   $universalHash{begin_exit_number} = hash_reference
        # ...where 'begin_exit_number' is the number of the GA::Obj::Exit at one end of the path
        #
        # Each 'hash_reference' is in the form:
        #   $hash_reference{end_exit_number} = blessed_ref_of_region_path_object
        #
        # Expected arguments
        #   $universalPathHashRef   - a reference to the hash described above
        #   $regionPathObj          - a GA::Obj::RegionPath to add to it
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $universalPathHashRef, $regionPathObj, $check) = @_;

        # Local variables
        my $hashRef;

        # Check for improper arguments
        if (! defined $universalPathHashRef || ! defined $regionPathObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addUniversalPath', @_);
        }

        if (! exists $$universalPathHashRef{$regionPathObj->startExit}) {

            $$universalPathHashRef{$regionPathObj->startExit} = {};
        }

        $hashRef = $$universalPathHashRef{$regionPathObj->startExit};

        # Add the GA::Obj::RegionPath to the existing inner hash, or to the new inner hash
        $$hashRef{$regionPathObj->stopExit} = $regionPathObj;

        return 1;
    }

    sub createDummyRoom {

        # Called by $self->findUniversalPath
        # Creates a dummy world model room (whose model number is -1), with a one-way exit (whose
        #   exit model number is -1), leading to a real world model room
        # Otherwise creates a dummy world model room (whose model number is -2), with a one-way
        #   exit (whose exit model number is -2), leading from a real world model room
        # Once the pathfinding algorithms are complete, $self->destroyDummyRoom() is called to
        #   remove any traces of the room and its exit from the world model
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $realRoomObj    - The real world model room
        #   $number         - Set to -1 (for the exit node at the beginning of a path) or -2 (for
        #                       the exit node at the end of the path)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list in the form
        #       (dummy_room_object, dummy_exit_object)

        my ($self, $session, $realRoomObj, $number, $check) = @_;

        # Local variables
        my (
            $dummyRoomObj, $dummyExitObj, $dummyDir,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $realRoomObj || ! defined $number || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->createDummyRoom', @_);
            return @emptyList;
        }

        $dummyRoomObj = Games::Axmud::ModelObj::Room->new(
            $session,
            'dummy',
            'non_model',
        );

        $dummyRoomObj->ivPoke('number', $number);
        $self->ivAdd('modelHash', $number, $dummyRoomObj);
        $self->ivAdd('roomModelHash', $number, $dummyRoomObj);
        # (The dummy room is nominally 'in' the same region as the initial room)
        $dummyRoomObj->ivPoke('parent', $realRoomObj->parent);

        $dummyExitObj = Games::Axmud::Obj::Exit->new(
            $session,
            'dummy',            # Use a dummy direction, too!
            'non_model',        # Not a real exit model object
        );

        $dummyExitObj->ivPoke('number', $number);
        $self->ivAdd('exitModelHash', $number, $dummyExitObj);

        $dummyDir = 'dijkstra_dummy_exit';

        if ($number == -1) {

            # Dummy exit leading to the initial room
            $dummyRoomObj->ivPush('sortedExitList', $dummyDir);
            $dummyRoomObj->ivAdd('exitNumHash', $dummyDir, $number);
            $dummyExitObj->ivPoke('destRoom', $realRoomObj->number);
            $dummyExitObj->ivPoke('oneWayFlag', TRUE);
            # NB If the exit is unallocatable, ->mapDir won't be set, so we'll use 'north' as an
            #   emergency default value for ->mapDir
            if ($dummyExitObj->mapDir) {

                $dummyExitObj->ivPoke(
                    'oneWayDir',
                    $axmud::CLIENT->ivShow('constOppDirHash', $dummyExitObj->mapDir),
                );

            } else {

                # Emergency default
                $dummyExitObj->ivPoke('oneWayDir', 'north');
            }

            $dummyExitObj->ivPoke('parent', $dummyRoomObj->number);

        } else {

            # Dummy exit leading from the target room
            $realRoomObj->ivPush('sortedExitList', $dummyDir);
            $realRoomObj->ivAdd('exitNumHash', $dummyDir, $number);
            $dummyExitObj->ivPoke('destRoom', $dummyRoomObj->number);
            $dummyExitObj->ivPoke('oneWayFlag', TRUE);
            if ($dummyExitObj->mapDir) {

                $dummyExitObj->ivPoke(
                    'oneWayDir',
                    $axmud::CLIENT->ivShow('constOppDirHash', $dummyExitObj->mapDir),
                );

            } else {

                # Emergency default
                $dummyExitObj->ivPoke('oneWayDir', 'north');
            }

            $dummyExitObj->ivPoke('parent', $realRoomObj->number);
        }

        return ($dummyRoomObj, $dummyExitObj);
    }

    sub destroyDummyRoom {

        # Called by $self->findUniversalPath
        # Removes a dummy room and its dummy exit (created with a call to $self->createDummyRoom)
        #   from the world model
        #
        # Expected arguments
        #   $number         - Set to -1 (for the exit node at the beginning of a path) or -2 (for
        #                       the exit node at the end of the path)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $number, $check) = @_;

        # Local variables
        my (
            $dummyDir, $dummyExitObj, $realRoomObj,
            @dirList, @newDirList,
        );

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->destroyDummyRoom', @_);
        }

        if ($number == -2) {

            # Dummy exit leading from the target room. Update the target room
            $dummyDir = 'dijkstra_dummy_exit';
            $dummyExitObj = $self->ivShow('exitModelHash', $number);
            $realRoomObj = $self->ivShow('modelHash', $dummyExitObj->parent);

            $realRoomObj->ivDelete('exitNumHash', $dummyDir);
            @dirList = $realRoomObj->sortedExitList;
            foreach my $dir (@dirList) {

                if ($dir ne $dummyDir) {

                    push (@newDirList, $dir);
                }
            }

            $realRoomObj->ivPoke('sortedExitList', @newDirList);
        }

        # Remove the exit from the exit model
        $self->ivDelete('exitModelHash', $number);
        # Remove the room from the world model
        $self->ivDelete('modelHash', $number);
        $self->ivDelete('roomModelHash', $number);

        return 1;
    }

    # Dijkstra algorithm for GA::Obj::Route objects (used to find a path using pre-defined routes)

    sub findRoutePath {

        # Can be called by any function. Called by GA::Generic::Cmd->useRoute
        #
        # Dijkstra algorithm to find a path between two rooms using interlinked pre-defined routes,
        #   each one stored in a GA::Obj::Route object (which are stored in route cages)
        # Based on AI::Pathfinding::AStar by Aaron Dalton
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $initialRoomTag - The initial room's tag
        #   $targetRoomTag  - The target room's tag
        #   $routeType      - 'road', 'quick' or 'both'
        #
        # Return values
        #   'undef' on improper arguments or if no path can be found between the initial and target
        #       rooms
        #   Otherwise, returns a list reference containing a list of world commands to move between
        #       the initial and target rooms

        my ($self, $session, $initialRoomTag, $targetRoomTag, $routeType, $check) = @_;

        # Local variables
        my (
            $openListObj, $nodeHashRef, $currentNode, $cmdListRef,
            @routeObjList,
            %routePathHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $initialRoomTag || ! defined $targetRoomTag
            || ! defined $routeType
            || ($routeType ne 'road' && $routeType ne 'quick' && $routeType ne 'both')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->findRoutePath', @_);
        }

        # The first step is to compile a hash of routes available to us. Get a list of available
        #   route GA::Obj::Route objects (ignore circuit routes altogether)
        if ($routeType eq 'both') {
            @routeObjList = $self->listAvailableRoutes($session, undef, 'road', 'quick');
        } else {
            @routeObjList = $self->listAvailableRoutes($session, undef, $routeType);
        }

        if (! @routeObjList) {

            # No routes with which to build a path
            return undef;
        }

        # Compile a hash in the form
        #   $routeHash{start_tag} = hash_reference
        #       where 'start_tag' is the room tag of the room at one end of the route
        # Each 'hash_reference' is in the form:
        #   $hash_reference{stop_tag} = blessed_ref_of_route_object
        foreach my $routeObj (@routeObjList) {

            my $hashRef;

            # Use only hoppable route objects...
            if ($routeObj->hopFlag) {

                if (! exists $routePathHash{$routeObj->startRoom}) {

                    $routePathHash{$routeObj->startRoom} = {};
                }

                $hashRef = $routePathHash{$routeObj->startRoom};

                # Add the RouteObj to the existing inner hash, or to the new inner hash
                $$hashRef{$routeObj->stopRoom} = $routeObj;
            }
        }

        # $routePathHashRef now contains a collection of interlinked routes, which we can search to
        #   find the shortest route between the initial and target rooms (if they are linked by
        #   route objects)
        # Now we run the Dijkstra algorithm for route objects (a modified A* algorithm in which the
        #   h-score is always 0) to get the shortest path between the initial and target rooms

        # Create the open list, using a binomial heap
        $openListObj = Games::Axmud::Obj::Heap->new();
        # Create a reference to a hash of nodes, in the form
        #   $hash{room_tag} = dijkstra_node
        $nodeHashRef = {};

        # Create a node for the initial room
        $currentNode = Games::Axmud::Node::Dijkstra->new(
            0,                      # Initial G score
            undef,                  # (Exit objects not used for pre-defined routes)
            $initialRoomTag,        # Room tag of the first room object
        );

        # Add this node to the open list
        $currentNode->ivPoke('inOpenFlag', TRUE);
        $openListObj->add($currentNode);

        # Perform the Dijkstra algorithm, starting at the room tagged $initialRoomTag, and aiming
        #   for the room tagged $targetRoomTag
        $self->doRouteDijkstra($targetRoomTag, $openListObj, $nodeHashRef, \%routePathHash);

        # We can now use the nodes stored in $openListObj to find the shortest route, by tracing the
        #   path from the target room, and using the parent of each node in turn (in the standard
        #   way)
        # Get a list reference, containing the list of world commands to move between the initial
        #   and target rooms
        $cmdListRef = $self->fillPath_routeDijkstra(
            $session,
            $targetRoomTag,
            $openListObj,
            $nodeHashRef,
            \%routePathHash,
        );

        return $cmdListRef;
    }

    sub doRouteDijkstra {

        # Called by $self->findRoutePath
        # Performs the Dijkstra algorithm on two nodes, each corresponding to a room tag, in order
        #   to find the shortest path between them, and therefore the shortest path between two
        #   rooms (as described in the comments for the calling function)
        #
        # Expected arguments
        #   $targetNode     - The target node (a room tag)
        #   $openListObj    - The Dijkstra open list, stored in a binomial heap object
        #   $nodeHashRef    - The hash of nodes, in the form $hash{tag} = node
        #   $routePathHashRef
        #                   - A hash of paths between the tagged rooms, each of which correspond to
        #                       a node. The hash tells us the cost of moving between two nodes
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $targetNode, $openListObj, $nodeHashRef, $routePathHashRef, $check) = @_;

        # Local variables
        my (
            $currentNode, $gScore, $nodeListRef,
            %twinNodeHash,
        );

        # Check for improper arguments
        if (
            ! defined $targetNode || ! defined $openListObj || ! defined $nodeHashRef
            || ! defined $routePathHashRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->doRouteDijkstra', @_);
        }

        # Perform the algorithm until we either find the shortest path to the target node or run out
        #   of nodes
        OUTER: while(
            defined $openListObj->top()
            && ($openListObj->top()->roomTag ne $targetNode)
        ) {
            # Remove the first remaining node in the open list
            $currentNode = $openListObj->extract_top();
            $currentNode->ivPoke('inOpenFlag', FALSE);

            # Get the surrounding nodes. $nodeListRef is a list reference, which in turn contains a
            #   number of list references, each representing a surrounding node (one linked to
            #   $currentNode by a single GA::Obj::Route)
            # The contained list references are in the form
            #   [room_tag, cost]
            $nodeListRef = $self->getSurrounding_routeDijkstra(
                $currentNode->roomTag,
                $routePathHashRef,
            );

            # Process each surrounding node
            INNER: foreach my $nodeRef (@$nodeListRef) {

                my (
                    $surroundRoomTag, $surroundCost, $surroundNode, $currentGScore, $possibleGScore,
                );

                ($surroundRoomTag, $surroundCost) = @$nodeRef;

                # Skip this node if it's in the closed list
                if (
                    exists $$nodeHashRef{$surroundRoomTag}
                    && ! $$nodeHashRef{$surroundRoomTag}->inOpenFlag
                ) {
                    next INNER;
                }

                # If the node isn't in the open list, add it to the open list
                if (! exists $$nodeHashRef{$surroundRoomTag}) {

                    $surroundNode = Games::Axmud::Node::Dijkstra->new(
                        $currentNode->gScore + $surroundCost,   # G score
                        undef,                                  # Exits not used
                        $surroundRoomTag,                       # Node
                    );

                    $surroundNode->ivPoke('parent', $currentNode);
                    $surroundNode->ivPoke('cost', $surroundCost);
                    $surroundNode->ivPoke('inOpenFlag', TRUE);
                    $$nodeHashRef{$surroundRoomTag} = $surroundNode;
                    $openListObj->add($surroundNode);

                } else {

                    # Otherwise the node is already in the open list. Check to see if it's cheaper
                    #   to go through the current exit, compared to the previous path
                    $surroundNode = $$nodeHashRef{$surroundRoomTag};
                    $currentGScore = $surroundNode->gScore;
                    $possibleGScore = $currentNode->gScore + $surroundCost;

                    if ($possibleGScore < $currentGScore) {

                        # Change the parent
                        $surroundNode->ivPoke('parent', $currentNode);
                        $surroundNode->ivPoke('gScore', $possibleGScore);
                        $openListObj->decrease_key($surroundNode);
                    }
                }
            }
        }

        # Dijkstra algorithm complete
        return 1;
    }

    sub fillPath_routeDijkstra {

        # Called by $self->findRoutePath, after a call to $self->doRouteDijkstra
        # The initial room and the target room are now linked, along the shortest path between them,
        #   by a list of nodes, each corresponding to a room tag
        # Compile a list of world commands to travel along this path, from the initial room to the
        #   target room
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $targetNode     - The target node (a room tag)
        #   $openListRef    - The Dijkstra open list, stored in a binomial heap object
        #   $nodeHashRef    - The hash of nodes, in the form $hash{exit} = node
        #   $routePathHashRef
        #                   - A hash of paths between the room tags which correspond to nodes, which
        #                       tells us the cost of moving between them
        #
        # Return values
        #   Returns an empty list on improper arguments
        #   Otherwise returns a list reference, containing commands sequences to move between the
        #       initial and target rooms. Each command sequence corresponds to a single route object
        #       in the chain of route objects between the initial and target rooms, e.g.
        #       'north;east;north;enter cave'

        my (
            $self, $session, $targetNode, $openListObj, $nodeHashRef, $routePathHashRef, $check,
        ) = @_;

        # Local variables
        my (
            $currentNode,
            @emptyList, @nodeList, @cmdSequenceList,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $targetNode || ! defined $openListObj
            || ! defined $nodeHashRef || ! defined $routePathHashRef || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->fillPath_routeDijkstra', @_);
            return @emptyList;
        }

        if (exists $$nodeHashRef{$targetNode}) {
            $currentNode = $$nodeHashRef{$targetNode};
        } else {
            $currentNode = $openListObj->top();
        }

        while (defined $currentNode) {

            unshift(@nodeList, $currentNode->roomTag);
            $currentNode = $currentNode->parent;
        }

        if (@nodeList) {

            # Everything in @nodeList is a room tag corresponding to the beginning or end of a route
            #   object
            do {

                my ($roomTag, $hashRef, $routeObj);

                $roomTag = shift @nodeList;

                # Find the path between this node, and the next one
                if ($$routePathHashRef{$roomTag}) {

                    $hashRef = $$routePathHashRef{$roomTag};
                    $routeObj = $$hashRef{$nodeList[0]};
                    if ($routeObj) {

                        # If $routeObj->route is a speedwalk command, convert it into a chain of
                        #   world commands
                        if (index($routeObj->route, $axmud::CLIENT->constSpeedSigil) == 0) {

                            push (
                                @cmdSequenceList,
                                join(
                                    $axmud::CLIENT->cmdSep,
                                    $session->parseSpeedWalk($routeObj->route),
                                ),
                            );

                        } else {

                            # $routeObj->route is already a single world command or a chain of
                            #   world commands
                            push (@cmdSequenceList, $routeObj->route);
                        }
                    }
                }

            } until (@nodeList < 2);
        }

        return \@cmdSequenceList;
    }

    sub getSurrounding_routeDijkstra {

        # Called by $self->doRouteDijkstra
        # Get a list of nodes surrounding the current one
        # In this function, the current node corresponds to a room tag. We look up this node in the
        #   hash of GA::Obj::Route objects we created earlier to find all the connecting nodes
        #
        # Expected arguments
        #   $currentNode
        #       - The current node (a room tag)
        #   $routePathHashRef
        #       - A hash of hash references, in the form
        #           $hash{start_tag} = hash_reference
        #         ...where 'start_tag' is the tag of a room at one end of the route
        #       - Each 'hash_reference' is in the form
        #           $hash{stop_tag} = blessed_ref_of_route_object
        #       - The GA::Obj::Route contains the path which connects the two nodes (tagged rooms)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a list reference, containing a series of list references, one for each
        #       surrounding node. The inner list references are in the form
        #       [surround_node_exit_object, surrounding_node_cost]

        my ($self, $currentNode, $routePathHashRef, $check) = @_;

        # Local variables
        my (
            $hashRef,
            @returnList,
        );

        # Check for improper arguments
        if (! defined $currentNode || ! defined $routePathHashRef || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->getSurrounding_routeDijkstra',
                @_,
            );
        }

        # Extract hash references from $routePathHashRef
        if ($$routePathHashRef{$currentNode}) {

            $hashRef = $$routePathHashRef{$currentNode};

            foreach my $routeObj (values %$hashRef) {

                push (@returnList, [
                    $routeObj->stopRoom,    # Surrounding node
                    $routeObj->stepCount,   # Cost
                ]);
            }
        }

        # Return a list reference, containing some list references
        return \@returnList;
    }

    sub listAvailableRoutes {

        # Called by $self->findRoutePath, GA::Cmd::ListRoute->do or by any another function
        # Returns a list of routes that are available from the current route cages (so, if there is
        #   a 'centre' > 'shop' road route associated with the current world's route cage, and
        #   another one associated with the current character's route cage, only the latter appears
        #   in the returned list, because character cage always have priority over world cage)
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Optional arguments
        #   $startRoom  - When called by GA::Cmd::ListRoute->do, this function returns a list of
        #                   routes starting from the room with the tag $startroom. Set to
        #                   'undef' when called by $self->findRoutePath
        #   @typeList   - Can comprise 0, 1, 2 or 3 of the strings 'road', 'quick' and 'circuit', in
        #                   any order. If the list is not empty, only those routes matching the
        #                   elements are returned. If it empty, all eligible routes are returned (so
        #                   an empty list is the same as the list ('road', 'quick', 'circuit')
        #
        # Return values
        #   An empty list on improper arguments, if @typeList contains invalid route types, if no
        #       route cages are found or if $startRoom is specified, but a route from that location
        #       doesn't exist
        #   Otherwise, returns a list of RouteObjs

        my ($self, $session, $startRoom, @typeList) = @_;

        # Local variables
        my (
            $match,
            @emptyList, @returnArray, @categoryList, @cageList,
            %typeHash, %startRoomHash, %roadRouteHash, %quickRouteHash, %circuitRouteHash,
        );

        # Check for improper arguments
        if (! defined $session) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->listAvailableRoutes', @_);
            return @emptyList;
        }

        # Check the contents of @typeList, and compile a hash of types
        if (@typeList) {

            foreach my $item (@typeList) {

                if ($item ne 'road' && $item ne 'quick' && $item ne 'circuit') {

                    $session->writeError(
                        'Invalid route type \'' . $item . '\'',
                        $self->_objClass . '->listAvailableRoutes',
                    );

                    return @emptyList;

                } else {

                    $typeHash{$item} = undef;
                }
            }

        } else {

            # If @typeList is empty, the calling function requires road, quick AND circuit routes
            $typeHash{'road'} = undef;
            $typeHash{'quick'} = undef;
            $typeHash{'circuit'} = undef;
        }

        # Get a list of profile categories (each possessing one route cage) in reverse priority
        #   order (i.e., a list starting with the lowest-priority world profile)
        @categoryList = reverse $session->profPriorityList;
        # Get a list of existing route cages in the same order
        foreach my $category (@categoryList) {

            # Find the current cage for this category, if there is one
            my $cageObj = $session->findCurrentCage('Route', $category);
            if ($cageObj) {

                push (@cageList, $cageObj);
            }
        }

        if (! @cageList) {

            # No route cages found (very unlikely)
            return @emptyList;
        }

        OUTER: foreach my $cageObj (@cageList) {

            my (@routeObjList, @newList);

            # Compile a list of GA::Obj::Route objects to process
            @routeObjList = $cageObj->ivValues('routeHash');

            # If a start room was specified, eliminate all route objects with the wrong start room
            if ($startRoom) {

                foreach my $routeObj (@routeObjList) {

                    if ($routeObj->startRoom eq $startRoom) {

                        push (@newList, $routeObj);
                    }
                }

                @routeObjList = @newList;
            }

            # Now copy the route objects into three hashes, one for each type of route, in the form
            #   $roadRouteHash{'start@@@stop'} = blessed_reference_to_route_object
            #   $quickRouteHash{'start@@@stop'} = blessed_reference_to_route_object
            #   $circuitRouteHash{'start@@@name'} = blessed_reference_to_route_object
            # ...where 'start' is the start room's tag, 'stop' the stop room's tag (for 'road' and
            #   'quick' routes) and 'name' is the circuit name (for 'circuit' routes)
            # Because @categoryList (and therefore @cageList) are in reverse priority order, at the
            #   end of the OUTER loop, these three hashes will contain the highest-priority route
            #   between two rooms (or the highest priority circuit with a given name)
            foreach my $routeObj (@routeObjList) {

                my $key;

                if ($routeObj->routeType eq 'road') {

                    $key = $routeObj->startRoom . '@@@' . $routeObj->stopRoom;
                    $roadRouteHash{$key} = $routeObj;

                } elsif ($routeObj->routeType eq 'quick') {

                    $key = $routeObj->startRoom . '@@@' . $routeObj->stopRoom;
                    $quickRouteHash{$key} = $routeObj;

                } elsif ($routeObj->routeType eq 'circuit') {

                    $key = $routeObj->startRoom . '@@@' . $routeObj->circuitName;
                    $circuitRouteHash{$key} = $routeObj;
                }
            }
        }

        # Only return the specified route types
        if (exists $typeHash{'road'}) {

            push (@returnArray, values %roadRouteHash);
        }

        if (exists $typeHash{'quick'}) {

            push (@returnArray, values %quickRouteHash);
        }

        if (exists $typeHash{'circuit'}) {

            push (@returnArray, values %circuitRouteHash);
        }

        return @returnArray;
    }

    # Other functions called by anything (not necessarily just GA::Obj::Map and GA::Win::Map )

    sub parseObj {

        # Can be called by anything, but called frequently by the Locator task
        # Parses a line (or lines) containing a list of things
        #   e.g. 'A sword, a shield and a helmet are here.'
        #   e.g. 'Two big evil guards, a troll and three small torches.'
        # Creates model objects for each of the things found
        #   e.g. Creates 2 guard 'sentient' objects, a troll 'sentient' object and three torch
        #   'portable' objects
        #
        # Expected arguments
        #   $session        - The parent GA::Session object
        #   $multipleFlag   - If set to TRUE, treats '5 coins' as a single object, with its
        #                       ->multiple IV set to 5. If the flag is set to FALSE, treats
        #                       '5 coins' as 5 separate objects
        #
        # Expected arguments
        #   @lineList       - A line (or lines) containing the list(s) of things (may be an empty
        #                       list)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list of blessed references to the newly-created objects (may be
        #       an empty list if @lineList was empty, or if the lines can't be parsed)

        my ($self, $session, $multipleFlag, @lineList) = @_;

        # Local variables
        my (
            $worldObj, $dictObj, $regex, $thingCount, $numberFlag, $guessFlag,
            @tempList, @tempList2, @tempList3, @andOrList, @thingArray, @articleList, @columnList,
            @returnArray,
            %pseudoObjHash, %articleHash, %numberHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $multipleFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parseObj', @_);
        }

        if ($axmud::CLIENT->debugParseObjFlag) {

            if ($multipleFlag) {
                $self->writeDebug('WORLD MODEL: Parsing objects multiple flag turned ON');
            } else {
                $self->writeDebug('WORLD MODEL: Parsing objects multiple flag turned OFF');
            }
        }

        # Import the current world profile and dictionary
        $worldObj = $session->currentWorld;
        $dictObj = $session->currentDict;

        # Import the hash of pseudo-objects
        %pseudoObjHash = $dictObj->pseudoObjHash;
        # Import a hash of number words
        %numberHash = $dictObj->numberHash;
        # Import a list of articles (in English, 'the', 'a' and 'an')
        @articleList = ($dictObj->definiteList,  $dictObj->indefiniteList);
        # Convert to a hash for quick lookup
        foreach my $item (@articleList) {

            $articleHash{$item} = undef;
        }

        # Stage 1 - convert any capital letters into lower-case letters and remove the
        #   characteristic room contents patterns (e.g. 'is here', 'are here' etc) from lines of
        #   text in the list
        OUTER: foreach my $line (@lineList) {

            $line = lc($line);
            INNER: foreach my $pattern ($worldObj->contentPatternList) {

                $line =~ s/$pattern//gi;
            }
        }

        # Stage 2 - look for pseudo-objects (strings that will confuse the parser) and replace them
        # Test each pseudo-object against each line
        OUTER: foreach my $line (@lineList) {

            INNER: foreach my $pseudo (keys %pseudoObjHash) {

                my $replace = $pseudoObjHash{$pseudo};
                $line =~ s/$pseudo/$replace/g;
            }
        }

        # Stage 3 - remove multiples like '[ 5]' that tend to appear in worlds that use a single
        #   object per line, optionally preceded by a multiplier. This multiplier is applied to
        #   every object on that line
        $regex = '[\(\[\{\<]\s*(\d+)\s*[\)\]\}\>]';
        foreach my $line (@lineList) {

            my $num;

            if ($line =~ m/$regex/) {

                $num = $1;
                # Stage 5 will detect a simple integer, so replace the '[ 5]' with ' 5 '
                $line =~ s/$regex/$num /;
            }
        }

        # Stage 4 - split into a list of objects (or groups of objects)
        #   e.g. 'Two big evil guards, a troll and three small torches.'
        #
        #   @thingArray[0][n]
        #
        #   [0] = two big evil guards
        #   [1] = a troll
        #   [2] = three small torches

        # Split the lines of @lineList by full stops and commas
        foreach my $line (@lineList) {

            push (@tempList, split("\\.", $line));
        }

        foreach my $item (@tempList) {

            push (@tempList2, split("\\,", $item));
        }

        # Further split the lines of @lineList by and/ors
        # Compile a list of and/or words from the current dictionary
        @andOrList = ($dictObj->andList, $dictObj->orList);
        # Surround each and/or word with whitespace, so that the word 'author' doesn't get split
        #   into 'auth' and 'or'
        foreach my $andOr (@andOrList) {

            $andOr = ' ' . $andOr . ' ';
        }

        # Do the split
        foreach my $andOr (@andOrList) {

            foreach my $item (@tempList2) {

                push (@tempList3, split (/$andOr/ , $item));
            }

            # Reset the lists, ready for the next iteration of the loop (if any)
            @tempList2 = @tempList3;
            @tempList3 = ();
        }

        # Trim unnecessary whitespace from each object (or group of objects) in the list. The TRUE
        #   argument tells the function to trim whitespace in the middle of the string, too
        foreach my $item (@tempList2) {

            $item = $axmud::CLIENT->trimWhitespace($item, TRUE);
        }

        # If a pseudo-object's replacement string is an empty string, one or more of the elements in
        #   @tempList2 will be empty. Eliminate those lines
        # In addition, if a list of objects is spread over several lines, we might have artifacts
        #   like 'the' and 'a' at the end of a line; they will now exist as items in @tempList2.
        #   Eliminate those, too
        foreach my $item (@tempList2) {

            if ($item && (! exists $articleHash{$item})) {

                push (@tempList3, $item);
            }
        }

        # Insert the list of objects (or groups of objects) into the first column of a 2-dimensional
        #   array
        # Use $thingCount to remember how many items there are
        $thingCount = scalar @tempList3;
        @thingArray = (\@tempList3);

        # Stage 5 - assign a number to everything in the list of objects (or group of objects)
        # The number might be 0, a decimal fraction, or -1 for 'unknown number greater than 1'
        # Remove the number word and any definite/indefinite articles
        #
        #   e.g. 'Two big evil guards, a troll and three small torches.'
        #
        #   @thingArray[0][n]           [1][n]              [2][n]
        #
        #   [0] = two big evil guards   [0] big evil guards [0] 2
        #   [1] = a troll               [1] troll           [1] 1
        #   [2] = three small torches   [2] small torches   [2] 3
        OUTER: for (my $count = 0; $count < $thingCount; $count++) {

            my (
                $pattern, $grpString, $string, $numberFlag,
                @wordList,
            );

            # Special case: if the string matches the current world's ->multiplePattern, use that as
            #   the multiple (and remove it)
            $pattern = $worldObj->multiplePattern;
            if ($pattern && $thingArray[0][$count] =~ m/$pattern/) {

                $grpString = $1;
                if ($grpString && $grpString =~ m/^\d+$/ && $grpString > 0) {

                    # Set the multiple
                    $thingArray[2][$count] = $grpString;
                    # Store the rest of the string, with the matching pattern substituted out
                    $string = $thingArray[0][$count];
                    $string =~ s/$pattern//;
                    $thingArray[1][$count] = $string;
                    next OUTER;
                }
            }

            # Split each thing into a list of word, e.g. ('two', 'evil', 'guards')
            @wordList = split(/\s+/, $thingArray[0][$count]);

            # If the first word is an article (and it's not the only word in the thing), remove the
            #   article
            if (exists $articleHash{$wordList[0]} && scalar @wordList > 1) {

                # Remove the article
                shift @wordList;
            }

            # Remove any integer numbers from the beginning
            if ($axmud::CLIENT->intCheck($wordList[0])) {

                # Integer number found at beginning of $thing. Remove it and assign it to [2][n]
                $thingArray[2][$count] = $wordList[0];

                # Only remove the first number
                shift @wordList;
                $numberFlag = TRUE;

            # Remove any number words from the beginning, and convert it to a decimal number
            #   e.g. 'two trolls' -> 2, 'half of the cake' -> 0.5, 'some cake' -> -1
            #   (-1 represents an indeterminate number, the resulting of converting 'some')
            } elsif (exists $numberHash{$wordList[0]}) {

                # Number word found at beginning of $thing. Remove it, convert it to a decimal
                #   number and assign it to [2][n]
                $thingArray[2][$count] = $numberHash{$wordList[0]};

                # Only remove one number word
                shift @wordList;
                $numberFlag = TRUE;
            }

            if (! $numberFlag) {

                # Treat this item as one thing
                $thingArray[2][$count] = 1;
            }

            # Recombine the word list into a string without articles or number words at
            #   the beginning
            $thingArray[1][$count] = join(' ', @wordList);
        }

        # Stage 6 - extract pseudo-adjectives, because they mess everything up
        # Pseudo-adjectives are stored in a hash which translates them either into a simple one-word
        #   adjective or marks them as something that should be removed completely
        #       $hash{'slightly suspicious'} = 'suspicious'
        #           - treat the adjective as 'suspicious'
        #       $hash{'gruesome remains of'} = undef
        #           - pretend this object doesn't have an adjective
        # The contents of [1][n] is moved to [3][n]; any pseudo-adjectives are removed from [3][n]
        #   and the replacement is put in [4][n]
        #
        #   e.g. 'A slightly suspicious cake and the gruesome remains of a corpse'
        #
        #   @thingArray[0][n]                       [1][n]                              [2][n]
        #
        #   [0] = a slightly suspicious cake        [0] slightly suspicious cake        [0] 1
        #   [1] = the gruesome remains of a corpse  [1] gruesome remains of a corpse    [1] 1
        #
        #   [3][n]      [4][n]
        #
        #   cake        suspicious
        #   a corpse    undef
        #
        #   e.g. 'Two big evil guards, a troll and three small torches.' (contains no
        #       pseudo-adjectives)
        #
        #   @thingArray[0][n]           [1][n]              [2][n]  [3][n]              [4][n]
        #
        #   [0] = two big evil guards   [0] big evil guards [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torches   [2] 3   [2] small torches   [2] undef

        OUTER: for (my $count = 0; $count < $thingCount; $count++) {

            my $largest;

            # Find the largest pseudo-adjective that matches
            $largest = '';

            INNER: foreach my $pseudoAdj ($dictObj->ivKeys('pseudoAdjHash')) {

                if (
                    $thingArray[1][$count] =~ m/$pseudoAdj/
                    && length ($pseudoAdj) > length ($largest)
                ) {
                    $largest = $pseudoAdj;
                }
            }

            if ($largest) {

                # Remove the largest pseudo-adjective from [1][n], and move its substitution to
                #   [4][n]. (If the substitution is an empty string, don't put anything in [4][n])
                $thingArray[3][$count] = $thingArray[1][$count];
                $thingArray[3][$count] =~ s/$largest//;
                if ($dictObj->ivShow('pseudoAdjHash', $largest)) {

                    $thingArray[4][$count] = $dictObj->ivShow('pseudoAdjHash', $largest);
                }

            } else {

                # No pseudo-adjective found
                $thingArray[3][$count] = $thingArray[1][$count];
                $thingArray[4][$count] = undef;
            }
        }

        # Stage 7 - extract pseudo-nouns from [3][n]
        # Pseudo-nouns are stored in a hash which translates them either into a simple one-word noun
        #   $hash{'major general'} = 'major'
        # If a pseudo-noun is found, it is replaced with its substitution, and the substitution is
        #   copied to [5][n] as the main noun
        #
        #   e.g. 'An attractive major general'
        #
        #   @thingArray[0][n]                   [1][n]                          [2][n]
        #
        #   [0] = an attractive major general   [0] attractive major general    [0] 1
        #
        #   [3][n]                  [4][n]      [5][n]
        #
        #   [0] attractive major    [0] undef   major
        #
        #   e.g. 'Two big evil guards, a troll and three small torches.' (contains no pseudo-nouns)
        #
        #   @thingArray[0][n]           [1][n]              [2][n]  [3][n]
        #
        #   [0] = two big evil guards   [0] big evil guards [0] 2   [0] big evil guards
        #   [1] = a troll               [1] troll           [1] 1   [1] troll
        #   [2] = three small torches   [2] small torches   [2] 3   [2] small torches
        #
        #   [4][n]      [5][n]
        #
        #   [0] undef   [0] undef
        #   [1] undef   [1] undef
        #   [2] undef   [2] undef

        OUTER: for (my $count = 0; $count < $thingCount; $count++) {

            my ($largest, $substitution);

            # Find the largest pseudo-noun that matches
            $largest = '';

            INNER: foreach my $pseudoNoun ($dictObj->ivKeys('pseudoNounHash')) {

                if (
                    $thingArray[3][$count] =~ m/$pseudoNoun/
                    && length ($pseudoNoun) > length ($largest)
                ) {
                    $largest = $pseudoNoun;
                }
            }

            if ($largest) {

                # Replace the largest pseudo-noun from [3][n] with its substitution
                $substitution = $dictObj->ivShow('pseudoNounHash', $largest);
                $thingArray[3][$count] =~ s/$largest/$substitution/;
                # Copy the substitution into [5][n] as the main noun
                $thingArray[5][$count] = $substitution;
            }
        }

        # Stage 8 - Try to separate nouns and adjectives, reducing plurals to singular forms and
        #   declined adjectives to undeclined forms, where possible
        #
        #   e.g. 'Two big evil guards, a troll and three small torches.'
        #
        #   @thingArray[0][n]           [1][n]              [2][n]  [3][n]              [4][n]
        #
        #   [0] = two big evil guards   [0] big evil guard  [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torch     [2] 3   [2] small torches   [2] undef
        #
        #   [5][n]      [6][n]  [7][n]      [8][n]  [9][n]      [10][n] [11][n]
        #
        #   [0] guards  undef   undef       undef   big evil    undef   undef
        #   [1] troll   undef   undef       undef   undef       undef   undef
        #   [2] torches undef   undef       undef   undef       small   undef
        #
        #   [5][n] contains the first word - working from right to left - that's a known noun (or
        #       pseudo-noun)
        #   [6][n] contains any other words which are known nouns
        #   [7][n] contains the dictionary section the first noun was found in (e.g. 'weapon')
        #   [8][n] contains the type of the first noun, if it's a portable or decoration (e.g.
        #       'torch')
        #   [9][n] contains all words which are known adjectives
        #   [10][n] contains all words which aren't known nouns or adjectives
        #   [11][n] contains all declined adjectives

        OUTER: for (my $count = 0; $count < $thingCount; $count++) {

            my @wordList;

            # Split [3][n] into words
            @wordList = split(/\s+/, $thingArray[3][$count]);
            # If the noun is more likely to come at the end (i.e. English) than at the front (e.g.
            #   French), reverse the order of the words
            if ($dictObj->nounPosn eq 'adj_noun') {

                @wordList = reverse (@wordList);
            }

            INNER: foreach my $word (@wordList) {

                my ($singular, $undeclined, $modFlag);

                # It's possible that $word may be an empty string, or 'undef', in an object like
                #   'a pair of dirty and smelly trousers', when 'pair of' is a pseudo-adjective,
                #   'dirty' & 'smelly' are adjectives, and 'trousers' is a noun - because the
                #   parser will interpret this as two objects, 'a pair of dirty' and 'smelly
                #   trousers', the former of which contains no nouns
                if (! $word) {

                    next INNER;
                }

                if ($self->ivExists('knownCharHash', $word)) {

                    # For characters, [5][n] should contain only one word, the character's name
                    # If there's anything in [5][n] (main noun) already, move it to [6][n] (other
                    #   nouns)
                    if (defined $thingArray[5][$count]) {

                        if (! defined $thingArray[6][$count]) {

                            # First word in [6][n]
                            $thingArray[6][$count] = $thingArray[5][$count];

                        } else {

                            # Not first word in [6][n]
                            $thingArray[6][$count]
                                = $thingArray[5][$count] . ' ' . $thingArray[6][$count];
                        }
                    }

                    # Character's name goes into [5][n]
                    $thingArray[5][$count] = $word;

                    # Remaining nouns go into [6][n]...
                    if (! defined $thingArray[6][$count]) {

                        # First word in [6][n]
                        $thingArray[6][$count] = $word;

                    } else {

                        # Not first word in [6][n]
                        $thingArray[6][$count] = $word . ' ' . $thingArray[6][$count];
                    }

                    # Mark the object as a character (in [7][n])
                    $thingArray[7][$count] = 'char';
                    next INNER;
                }

                # See if the word is already known, before trying to convert it to a singular (as
                #   if it were a noun) or trying to undecline it (as if it were an adjective)
                if (
                    # Word exists as a noun somewhere in the dictionary...
                    $dictObj->ivExists('combNounHash', $word)
                    # ...and it's not a special plural form, such as 'stadia' for stadium
                    && (! $dictObj->ivExists('reversePluralNounHash', $word))
                ) {
                    # This is a known noun. First noun goes into [5][n]
                    if (! defined $thingArray[5][$count]) {

                        $thingArray[5][$count] = $word;

                    # Remaining nouns go into [6][n] (unless the same noun is already in [5][n]
                    #   after a pseudo-noun subsitution was placed there)
                    } elsif ($word ne $thingArray[5][$count]) {

                        if (! defined $thingArray[6][$count]) {

                            # First word in [6][n]
                            $thingArray[6][$count] = $word;

                        } else {

                            # Not first word in [6][n]
                            $thingArray[6][$count] = $word . ' ' . $thingArray[6][$count];
                        }
                    }

                    next INNER;
                }

                if (
                    # Word exists as an adjective somewhere in the dictionary...
                    $dictObj->ivExists('combAdjHash', $word)
                    # ...and it's not a special declined form, e.g. 'heureuse' for heureux
                    && (! $dictObj->ivExists('reverseDeclinedAdjHash', $word))
                ) {
                   # This is a known adjective. Put it into [9][n]
                    if (! defined $thingArray[9][$count]) {

                        # First word in [9][n]
                        $thingArray[9][$count] = $word;

                    } else {

                        # Not first word in [9][n]
                        $thingArray[9][$count] = $word . ' ' . $thingArray[9][$count]
                    }

                    next INNER;
                }

                # Assume it's a plural noun, and try to reduce it to a singular noun
                $singular = $dictObj->convertToSingular($word);
                # For confirmed plurals, update the object's base string, so 'two big evil guards'
                #   generates the base string 'big evil guard' rather 'big evil guards', as this is
                #   useful for the Locator task window (and probably elsewhere, too)
                if ($thingArray[2][$count] > 1 && $singular ne $word) {

                    $thingArray[1][$count] =~ s/$word/$singular/g;
                    # (Only do this once per object)
                    $modFlag = TRUE;
                }

                if ($dictObj->ivExists('combNounHash', $singular)) {

                    # This is a known noun. First noun goes into [5][n]. If $word is in [5][n],
                    #   replace it by a singular
                    if (! defined $thingArray[5][$count] || $thingArray[5][$count] eq $word) {

                        $thingArray[5][$count] = $singular;

                    # Remaining nouns go into [6][n] (unless the same noun is already in [5][n]
                    #   after a pseudo-noun subsitution was placed there)
                    } elsif ($singular ne $thingArray[5][$count]) {

                        if (! defined $thingArray[6][$count]) {

                            # First word in [6][n]
                            $thingArray[6][$count] = $singular;

                        } else {

                            # Not first word in [6][n]
                            $thingArray[6][$count] = $singular . ' ' . $thingArray[6][$count];
                        }
                    }

                    next INNER;
                }

                # Assume it's a declined adjective, and try to reduce it to an undeclined adjective
                $undeclined = $dictObj->convertToUndeclined($word);
                if ($dictObj->ivExists('combAdjHash', $undeclined)) {

                    # This is a known adjective. Put it into [9][n]. If $word is in [9][n],
                    #   replace it by the undecliend form
                    if (! defined $thingArray[9][$count] || $thingArray[9][$count] eq $word) {

                        # First word in [9][n]
                        $thingArray[9][$count] = $undeclined;

                    } else {

                        # Not first word in [9][n]
                        $thingArray[9][$count] = $undeclined . ' ' . $thingArray[9][$count]
                    }

                    if ($word ne $undeclined) {

                        # This is a known declinable adjective. Put the undeclined form into [11][n]
                        if (! defined $thingArray[11][$count]) {

                            # First word in [9][n]
                            $thingArray[11][$count] = $word;

                        } else {

                            # Not first word in [9][n]
                            $thingArray[11][$count] = $word . ' ' . $thingArray[11][$count]
                        }
                    }

                    next INNER;
                }

                # Words which aren't known nouns or adjectives go into [10][n] (but don't add
                #   ignorable words)
                if (! $dictObj->ivExists('ignoreWordHash', $word)) {

                    if (! defined $thingArray[10][$count]) {

                        # First word in [10][n]
                        $thingArray[10][$count] = $word;

                    } else {

                        # Not first word in [10][n]
                        $thingArray[10][$count] = $word.' '.$thingArray[10][$count]
                    }
                }
            }
        }

        # Stage 9 - any words which aren't recognised nouns or adjectives should be added to the
        #   dictionary's list of unknown words (if this is allowed); but words in the dictionary's
        #   ignore list should not
        if ($worldObj->collectUnknownWordFlag) {

            OUTER: for (my $count = 0; $count < $thingCount; $count++) {

                if (defined $thingArray[10][$count]) {

                    my @wordList;

                    # Split [10][n] into words
                    @wordList = split(/\s+/, $thingArray[10][$count]);
                    # If the noun is more likely to come at the end (i.e. English) than at the front
                    #   (e.g. French), reverse the order of the words
                    if ($dictObj->nounPosn eq 'adj_noun') {

                        @wordList = reverse (@wordList);
                    }

                    # Empty [10][n] so it can be rebuilt, minus any ignorable words
                    $thingArray[10][$count] = '';

                    # Add each word to the dictionary's list of unknown words
                    foreach my $word (@wordList) {

                        $dictObj->ivAdd('unknownWordHash', $word, undef);

                        if (! $thingArray[10][$count]) {
                            $thingArray[10][$count] = $word;
                        } else {
                            $thingArray[10][$count] .= ' ' . $word;
                        }
                    }
                }
            }
        }

        # Stage 10 - if there's no recognised first noun in [5][n], we need to guess at one
        #   Use the last (or the first) word in [10][n] (unrecognised words)
        #   If there's nothing in [10][n], use the last (or the first) word in [9][n] (adjectives)
        #       or [4][n] (pseudo-adjective replacement)
        #   In either case, remove the selected word from [4][n], [9][n] or [10][n], and put it in
        #       [5][n]
        #
        #   e.g. 'Two big evil guards, a troll and three small torches.'
        #
        #   @thingArray[0][n]           [1][n]              [2][n]  [3][n]              [4][n]
        #
        #   [0] = two big evil guards   [0] big evil guard  [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torch     [2] 3   [2] small torches   [2] undef
        #
        #   [5][n]      [6][n]  [7][n]      [8][n]  [9][n]      [10][n] [11][n]
        #
        #   [0] guards  undef   undef       undef   big evil    undef   undef
        #   [1] troll   undef   undef       undef   undef       undef   undef
        #   [2] torches undef   undef       undef   undef       small   undef

        OUTER: for (my $count = 0; $count < $thingCount; $count++) {

            my @wordList;

            if (! defined $thingArray[5][$count]) {

                # If there's anything in [10][n], use the first word (which would have been the last
                #   word in 'three small torches', if 'torch' wasn't a recognised noun)
                if (defined $thingArray[10][$count]) {

                    @wordList = split(/\s+/,  $thingArray[10][$count]);
                    # Reverse the order for French (and similar languages)
                    if ($dictObj->nounPosn eq 'noun_adj') {

                        @wordList = reverse (@wordList);
                    }

                    $thingArray[5][$count] = shift @wordList;
                    $thingArray[10][$count] = join(' ', @wordList);
                    $guessFlag = TRUE;

                } elsif (defined $thingArray[9][$count]) {

                    @wordList = split(/\s+/, $thingArray[9][$count]);
                    # Reverse the order for French (and similar languages)
                    if ($dictObj->nounPosn eq 'noun_adj') {

                        @wordList = reverse (@wordList);
                    }

                    $thingArray[5][$count] = shift @wordList;
                    $thingArray[9][$count] = join(' ', @wordList);
                    $guessFlag = TRUE;

                } elsif (defined $thingArray[4][$count]) {

                    @wordList = split(/\s+/, $thingArray[4][$count]);
                    # Reverse the order for French (and similar languages)
                    if ($dictObj->nounPosn eq 'noun_adj') {

                        @wordList = reverse (@wordList);
                    }

                    $thingArray[5][$count] = shift @wordList;
                    $thingArray[4][$count] = join(' ', @wordList);
                    $guessFlag = TRUE;

                } else {

                    $self->writeWarning(
                        '17056 Unable to parse object \'' . $thingArray[0][$count] . '\'',
                        $self->_objClass . '->parseObj',
                    );

                    $thingArray[5][$count] = '(unparsed object)';
                }
            }
        }

        # Stage 11 - If [2][n] indicates a plural and we had to guess at the first noun, using an
        #   unknown word (in [10][n]) or even an adjective (in [9][n]), we need to try to reduce
        #   it to its singular form, in case it's a plural.
        #
        #   e.g. 'Two big evil guards, a troll and three small torches.'
        #
        #   @thingArray[0][n]           [1][n]              [2][n]  [3][n]              [4][n]
        #
        #   [0] = two big evil guards   [0] big evil guard  [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torch     [2] 3   [2] small torches   [2] undef
        #
        #   [5][n]      [6][n]  [7][n]      [8][n]  [9][n]      [10][n] [11][n]
        #
        #   [0] guard   undef   undef       undef   big evil    undef   undef
        #   [1] troll   undef   undef       undef   undef       undef   undef
        #   [2] torch   undef   undef       undef   undef       small   undef

        if ($guessFlag) {

            OUTER: for (my $count = 0; $count < $thingCount; $count++) {

                my $standard;

                # If it's a known character, don't try to reduce it from plural to singular
                if (defined $thingArray[7][$count] && $thingArray[7][$count] eq 'char') {

                    next OUTER;

                } elsif ($thingArray[2][$count] > 1) {

                    $thingArray[5][$count]
                        = $dictObj->convertToSingular($thingArray[5][$count]);
                }
            }
        }

        # Stage 12 - work out what kind of object everything is ('portable', 'creature', 'sentient',
        #   etc). If the object is already known to be a character, skip this stage
        #
        #   e.g. 'Two big evil guards, a troll and three small torches.'
        #
        #   @thingArray[0][n]           [1][n]              [2][n]  [3][n]              [4][n]
        #
        #   [0] = two big evil guards   [0] big evil guard  [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torch     [2] 3   [2] small torches   [2] undef
        #
        #   [5][n]      [6][n]  [7][n]      [8][n]  [9][n]      [10][n] [11][n]
        #
        #   [0] guard   undef   sentient    undef   big evil    undef   undef
        #   [1] troll   undef   race        undef   undef       undef   undef
        #   [2] torch   undef   portable    torch   undef       small   undef

        OUTER: for (my $count = 0; $count < $thingCount; $count++) {

            # If it's a known character, don't need to work out what kind of thing it is
            if (defined $thingArray[7][$count] && $thingArray[7][$count] eq 'char') {

                next OUTER;

            } elsif ($dictObj->ivExists('combNounHash', $thingArray[5][$count])) {

                # It's  a recognised noun. The parent dictionary goes into [7][n]...
                my $parentDict = $dictObj->ivShow(
                    'combNounHash',
                    $thingArray[5][$count],
                );
                $thingArray[7][$count] = $parentDict;

                # ...if it's a portable or decoration, the type goes into [8][n]
                if ($parentDict eq 'portable') {

                    if ($dictObj->ivExists('portableTypeHash', $thingArray[5][$count])) {

                        $thingArray[8][$count] = $dictObj->ivShow(
                            'portableTypeHash',
                            $thingArray[5][$count],
                        );

                    } else {

                        $thingArray[8][$count] = 'other';
                    }

                } elsif ($parentDict eq 'decoration') {

                    if (
                        $dictObj->ivExists(
                            'decorationTypeHash',
                            $thingArray[5][$count]),
                    ) {
                        $thingArray[8][$count] = $dictObj->ivShow(
                            'decorationTypeHash',
                            $thingArray[5][$count],
                        );

                    } else {

                        $thingArray[8][$count] = 'other';
                    }

                } else {
                    $thingArray[8][$count] = undef;
                }

            } else {

                # It's not a recognised noun
                $thingArray[7][$count] = undef;
                $thingArray[8][$count] = undef;
            }
        }

        # Stage 13 - for objects marked 'sentient' or 'creature' (or temporarily as 'race' or
        #   'guild'), and for objects of unknown category (because they're not in the current
        #   dictionary), we need to know whether they are known minions. $self->minionStringHash
        #   contains a list of keys (e.g. 'Obelix', 'hairy orc') which represent a minion
        #   object (stored as the corresponding value). If the object's base string (in [1][n])
        #   contains one of these minion strings, it's a minion, and [7][n] must be changed; [12][n]
        #   is set to the matching minion string ('Obelix', 'hairy orc') and [13][n] is set for
        #   minions which belong to the user
        #
        #   e.g. 'Two big evil guards, a troll and three small torches.'
        #
        #   @thingArray[0][n]           [1][n]              [2][n]  [3][n]              [4][n]
        #
        #   [0] = two big evil guards   [0] big evil guard  [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torch     [2] 3   [2] small torches   [2] undef
        #
        #   [5][n]      [6][n]  [7][n]      [8][n]  [9][n]      [10][n] [11][n] [12][n] [13][n]
        #
        #   [0] guard   undef   sentient    undef   big evil    undef   undef   undef   undef
        #   [1] troll   undef   minion      undef   undef       undef   undef   troll   undef
        #   [2] torch   undef   portable    torch   undef       small   undef   undef   undef

        OUTER: for (my $count = 0; $count < $thingCount; $count++) {

            if (
                ! defined $thingArray[7][$count]
                || $thingArray[7][$count] eq 'sentient' || $thingArray[7][$count] eq 'creature'
                || $thingArray[7][$count] eq 'race' || $thingArray[7][$count] eq 'guild'
            ) {
                INNER: foreach my $minionString ($self->ivKeys('minionStringHash')) {

                    my $minionObj;

                    if ($thingArray[1][$count] =~ m/$minionString/i) {

                        # It's a minion
                        $thingArray[7][$count] = 'minion';
                        $thingArray[12][$count] = $minionString;

                        # Is it one of our own minions?
                        $minionObj = $self->ivShow('minionStringHash', $minionString);
                        if ($minionObj->ownMinionFlag) {
                            $thingArray[13][$count] = TRUE;
                        } else {
                            $thingArray[13][$count] = FALSE;
                        }

                        next OUTER;
                    }
                }
            }
        }

        # Stage 14 - for each separate object, create a new non-model object, and put its blessed
        #   reference into @returnArray
        #
        #   e.g. 'Two big evil guards, a troll and three small torches.'
        #
        #   @thingArray[0][n]           [1][n]              [2][n]  [3][n]              [4][n]
        #
        #   [0] = two big evil guards   [0] big evil guard  [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torch     [2] 3   [2] small torches   [2] undef
        #
        #   [5][n]      [6][n]  [7][n]      [8][n]  [9][n]      [10][n] [11][n] [12][n] [13][n]
        #
        #   [0] guard   undef   sentient    undef   big evil    undef   undef   undef   undef
        #   [1] troll   undef   minion      undef   undef       undef   undef   troll   undef
        #   [2] torch   undef   portable    torch   undef       small   undef   undef   undef

        # Trim unnecessary whitespace from every word (or group of words)
        OUTER: for (my $thing = 0; $thing < $thingCount; $thing++) {

            INNER: for (my $column = 0; $column < 11; $column++) {

                if (defined $thingArray[$column][$thing]) {

                    $thingArray[$column][$thing]
                        = $axmud::CLIENT->trimWhitespace($thingArray[$column][$thing]);
                }
            }
        }

        # Show debug information, if the global flag is set
        if ($axmud::CLIENT->debugParseObjFlag) {

            @columnList = (
                '(original)',                                   # column 0
                '(base string)',                                # column 1
                '(multiple)',                                   # column 2
                '(base string without pseudo noun/adjective)',  # column 3
                '(pseudo adjective replacement)',               # column 4
                '(1st noun)',                                   # column 5
                '(other noun)',                                 # column 6
                '(dictionary word type)',                       # column 7
                '(portable/decoration type)',                   # column 8
                '(1st adjective)',                              # column 9
                '(oth adjectives)',                             # column 10
                '(root adjective)',                             # column 11
                '(minion string)',                              # column 12
                '(own minion flag)',                            # column 13
            );

            $self->writeDebug('WORLD MODEL: Objects parsed: ' . $thingCount);

            OUTER: for (my $rowCount = 0; $rowCount < $thingCount; $rowCount++) {

                $self->writeDebug('   Object #' . ($rowCount + 1));

                INNER: for (my $columnCount = 0; $columnCount < 14; $columnCount++) {

                    $self->writeDebug(
                        '      Column ' . $columnCount . ' ' . $columnList[$columnCount],
                    );

                    if (defined $thingArray[$columnCount][$rowCount]) {
                        $self->writeDebug('         ' . $thingArray[$columnCount][$rowCount]);
                    } else {
                        $self->writeDebug('         <undef>');
                    }
                }
            }

            $self->writeDebug('WORLD MODEL: End of object parsing messages');
        }

        # Process each thing in $thingArray
        OUTER: for (my $count = 0; $count < $thingCount; $count++) {

            my ($total, $obj);

            # Don't create a non-model object for an unparsable thing
            if ($thingArray[5][$count] eq  '(unparsed object)') {

                next OUTER;
            }

            # Each entry represents at least 1 object, even it its number is 0.5, 0.33 or -1
            $total = $thingArray[2][$count];
            if ($total < 2) {

                $total = 1;
            }

            # Sanity check - in case some idiot creates a room with "999999999 hobbits", limit
            #   the number of world model objects to be created
            if ($total > $axmud::CLIENT->constParseObjMax) {

                $total = $axmud::CLIENT->constParseObjMax;
            }

            if ($total > 1 && $multipleFlag) {

                # Create a single object to represent '5 coins' or 'five coins'
                $obj = $self->createParsedObj($session, TRUE, \@thingArray, $count);
                if ($obj) {

                    push (@returnArray, $obj);
                }

            } else {

                # If $total is 1, create a single object. Otherwise, create multiple objects,
                #   e.g. create five objects for '5 axes'
                OUTER: for (my $number = 0; $number < $total; $number++) {

                    $obj = $self->createParsedObj($session, FALSE, \@thingArray, $count);
                    if ($obj) {

                        push (@returnArray, $obj);
                    }
                }
            }
        }

        # Parsing complete
        return @returnArray;
    }

    sub createParsedObj {

        # Called by $self->parseObj once for every non-model object to be created
        #
        # Expected arguments
        #   $session        - The parent GA::Session object
        #   $multipleFlag   - If flag is set to TRUE, treats '5 coins' as a single object, with its
        #                       ->multiple IV set to 5. If the flag is set to FALSE, treats '5
        #                       coins' as 5 seperate objects
        #   $arrayRef       - The 2D array containing information about objects in the world
        #                       collected during parsing
        #   $count          - The object in $arrayRef that's being processed. If $count = 3, then
        #                       we're processing the data in $$arrayRef[3][n]
        #
        # Return values
        #   'undef' on improper errors or if a non-model object isn't created
        #   Otherwise returns the blessed reference of the object

        my ($self, $session, $multipleFlag, $arrayRef, $count, $check) = @_;

        # Local variables
        my (
            $dictObj, $obj, $deathFlag, $package,
            @wordList, @guildRaceList,
            %deathWordHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $multipleFlag || ! defined $arrayRef
            || ! defined $count || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->createParsedObj', @_);
        }

        # Import the current dictionary
        $dictObj = $session->currentDict;

        # For objects whose nouns are a known 'race' or 'guild' word, classify the object as a
        #   'sentient' (since 'sentient' has a higher priority, a word which is both a known
        #   'sentient' word and a known 'guild'/'race' word will already have been classified as a
        #   'sentient' object)
        # For known characters, if there's already a GA::ModelObj::Char, use that; otherwise, create
        #   one
        if (defined $$arrayRef[7][$count] && $$arrayRef[7][$count] eq 'char') {

            if ($self->ivExists('knownCharHash', $$arrayRef[5][$count])) {

                # Use the existing object
                $obj = $self->ivShow('knownCharHash', $$arrayRef[5][$count])

            } else {

                # Create a new object temporarily, but don't save it in $self->knownCharHash
                $obj = Games::Axmud::ModelObj::Char->new(
                    $session,
                    $$arrayRef[5][$count],      # Name
                    FALSE,                      # Non-model object
                );

                if (! $obj) {

                    # Couldn't create the non-model object
                    return undef;
                }
            }
        }

        # For everything else...
        if (! $obj) {

            # Import the hash of death words
            %deathWordHash = $dictObj->deathWordHash;

            # Check all of the describing words (nouns, adjectives and unknowns); if any of them are
            #   in the dictionary's deathlist, then this object is a corpse
            # Split [1][n] into words, so we can check each seperately
            @wordList = split(/\s+/, $$arrayRef[1][$count]);
            OUTER: foreach my $word (@wordList) {

                if (exists $deathWordHash{$word}) {

                    # Death word found!
                    $deathFlag = TRUE;
                    last OUTER;
                }
            }

            # For dead things, classify it as a portable corpse
            if ($deathFlag) {

                # Dead minions are not GA::ModelObj::Minion objects!
                if (defined $$arrayRef[7][$count] && $$arrayRef[7][$count] eq 'minion') {

                    $$arrayRef[12][$count] = undef;
                    $$arrayRef[13][$count] = undef;
                }

                $$arrayRef[7][$count] = 'portable';
                $$arrayRef[8][$count] = 'corpse';

            # For unrecognised nouns (when [7][n] is 'undef'), classify them as 'decoration' for now
            } elsif (! defined $$arrayRef[7][$count] && ! $deathFlag) {

                $$arrayRef[7][$count] = 'decoration';
                $$arrayRef[8][$count] = 'other';
            }

            # Decide which package to use
            if ($$arrayRef[7][$count] eq 'guild' || $$arrayRef[7][$count] eq 'race') {
                $package = 'Games::Axmud::ModelObj::Sentient';      # Treat as a 'sentient'
            } else {
                $package = 'Games::Axmud::ModelObj::' . ucfirst($$arrayRef[7][$count]);
            }

            # Create the non-model object
            $obj = $package->new(
                $session,
                $$arrayRef[5][$count],      # Name
                FALSE,                      # Non-model object
            );

            if (! $obj) {

                # Couldn't create the non-model object
                return undef;
            }
        }

        # Set the new object's IVs

        # Main noun
        $obj->ivPoke('noun', $$arrayRef[5][$count]);
        # (Default noun tag is the same as the main noun)
        $obj->ivPoke('nounTag', $$arrayRef[5][$count]);

        # Other nouns
        if (defined $$arrayRef[6][$count]) {

            @wordList = split(/\s+/, $$arrayRef[6][$count]);
            foreach my $word (@wordList) {

                $obj->ivPush('otherNounList', $word);
            }
        }

        # Adjective list
        if (defined $$arrayRef[9][$count]) {

            @wordList = split(/\s+/, $$arrayRef[9][$count]);
            foreach my $word (@wordList) {

                $obj->ivPush('adjList', $word);
            }
        }

        # Pseudo-adjective (modified)
        if (defined $$arrayRef[4][$count]) {

            $obj->ivPush('pseudoAdjList', $$arrayRef[4][$count]);
        }

        # Root adjective list
        if (defined $$arrayRef[11][$count]) {

            @wordList = split(/\s+/, $$arrayRef[11][$count]);
            foreach my $word (@wordList) {

                $obj->ivPush('rootAdjList', $word);
            }
        }

        # Unknown words
        if (defined $$arrayRef[10][$count]) {

            @wordList = split(/\s+/,  $$arrayRef[10][$count]);
            foreach my $word (@wordList) {

                $obj->ivPush('unknownWordList', $word);
            }
        }

        # Minions
        if (defined $$arrayRef[12][$count]) {

            if ($$arrayRef[13][$count]) {

                $obj->ivPoke('ownMinionFlag', TRUE);
            }
        }

        # Set the multiple
        if ($multipleFlag) {

            # e.g. A single object represents '5 coins'
            $obj->ivPoke('multiple', $$arrayRef[2][$count]);

        } elsif ($$arrayRef[2][$count] > 1) {

            # e.g. One object is created for 'an axe', or five separate objects are created for
            #   'five axes'
            $obj->ivPoke('multiple', 1);

        } else {

            # When parsing 'half a cake', $$arrayRef[2][$count] is set to 0.5. Use that multiple
            #   even though $multipleFlag isn't set
            $obj->ivPoke('multiple', $$arrayRef[2][$count]);
        }

        # Base string (e.g. 'big evil guards')
        $obj->ivPoke('baseString', $$arrayRef[1][$count]);

        # If it's a character, minion, sentient or creature object, we need to set those properties,
        #   too
        if  (
            $$arrayRef[7][$count] eq 'char' || $$arrayRef[7][$count] eq 'minion'
            || $$arrayRef[7][$count] eq 'sentient' || $$arrayRef[7][$count] eq 'creature'
            || $$arrayRef[7][$count] eq 'guild'     # Treated as a 'sentient' object
            || $$arrayRef[7][$count] eq 'race'      # Treated as a 'sentient' object
        ) {
            # Compile a list of words, any one of which might be a known guild or race word

            # Main noun
            @guildRaceList = ($$arrayRef[5][$count]);

            # Other nouns
            if (defined $$arrayRef[6][$count]) {

                push (@guildRaceList, split(/\s+/, $$arrayRef[6][$count]));
            }

            # Adjectives
            if (defined $$arrayRef[9][$count]) {

                push (@guildRaceList, split(/\s+/, $$arrayRef[9][$count]));
            }

            # Unknown words
            if (defined $$arrayRef[10][$count]) {

                push (@guildRaceList, split(/\s+/, $$arrayRef[10][$count]));
            }

            # Find the first word in @guildRaceList that's a known guild word, and use it
            OUTER: foreach my $word (@guildRaceList) {

                if ($dictObj->ivExists('guildHash', $word)) {

                    $obj->ivPoke('guild', $word);
                    last OUTER;
                }
            }

            # Find the first word in @guildRaceList that's a known race word, and use it
            OUTER: foreach my $word (@guildRaceList) {

                if ($dictObj->ivExists('raceHash', $word)) {

                    $obj->ivPoke('race', $word);
                    last OUTER;
                }
            }
        }

        # If it's a portable or decoration, we need to set its type
        if  ($$arrayRef[7][$count] eq 'portable' || $$arrayRef[7][$count] eq 'decoration') {

            $obj->ivPoke('type', $$arrayRef[8][$count]);
        }

        # Object creation complete
        return $obj;
    }

    sub objCompare {

        # Can be called by anything to compare model objects (or non-model objects)
        #
        # Compares a $targetObj against a list of one or more possibly similar objects,
        #   @compareList, to see whether $targetObj matches any of the objects in @compareList (i.e.
        #   to see whether $targetObj seems to be the same object as an object in @compareList)
        # (If $targetObj is to be compared against a single object, then @compareList should contain
        #   only one element)
        #
        # Assigns every object in @compareList a score from 0-100, with 0 representing totally
        #   different objects and 100 representing absolutely identical objects
        # $sensitivity is also a number between 0-100. If anything in @compareList gets a score
        #   equal to or greater than $sensitivity, we say that it matches $targetObj
        # We return the highest score of the first matching object, or 'undef' if no matching
        #   objects are found
        # ->objCompare is very sensitive. If $targetObj has no adjectives, ->objCompare will assume
        #   that a matching object also has no adjectives. For a less demanding comparison, use
        #   $self->objMatch
        # Good values for $sensitivity are 70-80 (for a close match) or 90 (for a very close
        #   match)
        #
        # Expected arguments
        #   $sensitivity    - A value between 0-100
        #
        # Optional arguments
        #   $targetObj      - Blessed reference of a model object (or non-model object). If 'undef',
        #                       no comparison takes place (but debug messages are displayed, if
        #                       allowed)
        #   @compareList    - List of objects against which to compare $targetObj. If an empty list,
        #                       no comparison takes place
        #
        # Return values
        #   'undef' on improper arguments or if nothing in @compareList matches $targetObj with a
        #       high enough score
        #   Otherwise, when the first match with a high enough score is found, returns the score
        #       (which will be a value between 0-100, greater or equal to $sensitivity)

        my ($self, $sensitivity, $targetObj, @compareList) = @_;

        # Local variables
        my (@targetList, @otherList);

        # Check for improper arguments
        if (! defined $sensitivity) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->objCompare', @_);
        }

        # If no targets were specified, then there's nothing to compare
        if (! $targetObj || ! @compareList) {

            if ($axmud::CLIENT->debugCompareObjFlag) {

                $self->writeDebug('->objCompare');
                if (! $targetObj) {
                    $self->writeDebug('   No target specified (code error?)');
                } elsif (! @compareList) {
                    $self->writeDebug('   No comparison objects specified (code error?)');
                }
            }

            return undef;
        }

        OUTER: foreach my $compareObj (@compareList) {

            my $score;

            # Award points depending on matches between the two object's IVs
            $score = 0;     # Points gained (out of 100)

            # Compare all possible nouns; if there are no nouns in common, the two objects can't
            #   possibly be the same
            @targetList = ($targetObj->noun, $targetObj->otherNounList);
            @otherList = ($compareObj->noun, $compareObj->otherNounList);
            if (! $self->listCompare(\@targetList, \@otherList)) {

                # No nouns in common - objects must be different
                next OUTER;
            }

            # Check the main noun
            if ($targetObj->noun eq $compareObj->noun) {

                $score += 40;
            }

            # Check the other nouns
            @targetList = $targetObj->otherNounList;
            @otherList = $compareObj->otherNounList;
            $score += (15 * $self->listCompare(\@targetList, \@otherList));

            # Check the adjectives
            @targetList = $targetObj->adjList;
            @otherList = $compareObj->adjList;
            $score += (15 * $self->listCompare(\@targetList, \@otherList));

            # Check the pseudo-adjectives
            @targetList = $targetObj->pseudoAdjList;
            @otherList = $compareObj->pseudoAdjList;
            $score += (15 * $self->listCompare(\@targetList, \@otherList));

            # Check the unknown word list
            @targetList = $targetObj->unknownWordList;
            @otherList = $compareObj->unknownWordList;
            $score += (15 * $self->listCompare(\@targetList, \@otherList));

            # Don't need decimal places (and it ruins the confirmation message)
            $score = int($score);

            if ($axmud::CLIENT->debugCompareObjFlag) {

                $self->writeDebug('->objCompare');
                $self->writeDebug('   Target: ' . $targetObj->noun . ', Comparison object: '
                    . $compareObj->noun . ', score ' . $score . ' (sensitivity ' . $sensitivity
                    . ')',
                );
            }

            if ( $score >= $sensitivity) {

                # The two objects are close enough
                if ($axmud::CLIENT->debugCompareObjFlag) {

                    $self->writeDebug('   Objects MATCH');
                }

                return $score;
            }
        }

        # None of the objects in @compareList match $targetObj at the specified sensitivity
        return undef;
    }

    sub objMatch {

        # Can be called by anything to compare model objects (or non-model objects)
        #
        # Compares a $targetObj against a list of one or more possibly similar objects,
        #   @compareList, to see whether $targetObj matches any of the objects in @compareList (i.e.
        #   to see whether $targetObj seems to be the same object as an object in @compareList)
        # (If $targetObj is to be compared against a single object, then @compareList should contain
        #   only one element)
        #
        # Works much like $self->objCompare, except that this function is less demanding: it assumes
        #   that objects in @compareList have incomplete IVs (e.g. perhaps having only their ->noun
        #   IV set to something)
        # Only properties of objects in @compareList that have been set are checked against the IVs
        #   in $targetObj
        # ->objCompare is more demanding - it expects that if $targetObj has no adjectives, the
        #   things in @compareList will also have no adjectives
        #
        # Assigns every object in @compareList a score, which is then adjusted to create a
        #   percentage score, with 0 representing totally different objects and 100 representing
        #   objects that are complete matches
        # $sensitivity is also a number between 0-100. If anything in @compareList gets a score
        #   equal to or greater than $sensitivity, we say that it matches $targetObj and return the
        #   score. Otherwise, we return 'undef'
        # Good values for $sensitivity are 70-80 (for a close match) or 90 (for a very close
        #   match).
        #
        # Expected arguments
        #   $sensitivity    - A value between 0-100
        #   $targetObj      - Blessed reference of a model object (or non-model object)
        #
        # Optional arguments
        #   @compareList    - List of objects against which to compare $targetObj (empty lists are
        #                       allowed)
        #
        # Return values
        #   'undef' on improper arguments or if nothing in @compareList matches $targetObj with a
        #       high enough score
        #   Otherwise, when the first match with a high enough score is found, returns the score
        #       (which will be a value between 0-100, greater or equal to $sensitivity)

        my ($self, $sensitivity, $targetObj, @compareList) = @_;

        # Local variables
        my (@targetList, @otherList);

        # Check for improper arguments
        if (! defined $sensitivity || ! defined $targetObj) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->objMatch', @_);
        }

        # If @compareList is empty, then there's nothing to compare
        if (! @compareList) {

            return undef;
        }

        OUTER: foreach my $compareObj (@compareList) {

            my ($score, $maxScore, $percentage);

            # Award points depending on matches between the two object's IVs
            $score = 0;         # Points gained
            $maxScore = 0;      # Max points available (up to 100)

            # Compare all possible nouns; if there are no nouns in common, the two objects can't
            #   possibly be the same
            @targetList = ($targetObj->noun, $targetObj->otherNounList);
            @otherList = ($compareObj->noun, $compareObj->otherNounList);
            if (! $self->listCompare(\@targetList, \@otherList)) {

                # No nouns in common - objects must be different
                next OUTER;
            }

            # Check the main noun (if $targetObj has one)
            if ($compareObj->noun && $targetObj->noun && $targetObj->noun eq $compareObj->noun) {

                $score += 40;
                $maxScore += 40;
            }

            # Check the other nouns (if $targetObj has any)
            if ($compareObj->otherNounList) {

                @targetList = $targetObj->otherNounList;
                @otherList = $compareObj->otherNounList;
                $score += (15 * $self->listCompare(\@targetList, \@otherList));
                $maxScore += 15;
            }

            # Check the adjectives (if $targetObj has any)
            if ($compareObj->adjList) {

                @targetList = $targetObj->adjList;
                @otherList = $compareObj->adjList;
                $score += (15 * $self->listCompare(\@targetList, \@otherList));
                $maxScore += 15;
            }

            # Check the pseudo-adjectives (if $targetObj has any)
            if ($compareObj->pseudoAdjList) {

                @targetList = $targetObj->pseudoAdjList;
                @otherList = $compareObj->pseudoAdjList;
                $score += (15 * $self->listCompare(\@targetList, \@otherList));
                $maxScore += 15;
            }

            # Check the unknown word list (if $targetObj has any)
            if ($compareObj->unknownWordList) {

                @targetList = $targetObj->unknownWordList;
                @otherList = $compareObj->unknownWordList;
                $score += (15 * $self->listCompare(\@targetList, \@otherList));
                $maxScore += 15;
            }

            # We don't want to divide by zero...
            if (! $score) {

                if ($axmud::CLIENT->debugCompareObjFlag) {

                    $self->writeDebug('->objMatch');
                    $self->writeDebug('   Target: ' . $targetObj->noun . ', Comparison object: '
                        . $compareObj->noun . ', score ' . $score . ' (sensitivity ' . $sensitivity
                        . ')',
                    );
                }

                next OUTER;
            }

            # Adjust $score so that it's a score out of 100
            $percentage = int(($score / $maxScore) * 100);

            if ($axmud::CLIENT->debugCompareObjFlag) {

                $self->writeDebug('->objMatch');
                $self->writeDebug('   Target: ' . $targetObj->noun . ', Comparison object: '
                    . $compareObj->noun . ', score ' . $score . ', max score ' . $maxScore
                    . ', percentage ' . $percentage . '% (sensitivity ' . $sensitivity . ')',
                );
            }

            if ( $percentage >= $sensitivity) {

                # The two objects are close enough
                if ($axmud::CLIENT->debugCompareObjFlag) {

                    $self->writeDebug('   Objects MATCH');
                }

                return $percentage;
            }
        }

        # None of the objects in @compareList match $targetObj at the specified sensitivity
        return undef;
    }

    sub listCompare {

        # Called by $self->objCompare and $self->objMatch
        #
        # Calculates the intersection between two lists, and returns a value between 0 and 1
        #   e.g. 0 means no common elements in the lists
        #   e.g. 1 means the lists are identical
        #   e.g. 0.5 would be the return value for the lists (fred, barney, wilma, betty) and
        #       (fred, barney) (because 50% of the elements of the shorter list are present in the
        #       longer one)
        # N.B. It doesn't matter which of the two lists is larger
        #
        # Expected arguments
        #   targetListRef   - Reference to an (anonymous) list, e.g. the adjectives describing a
        #                       non-model object
        #   objectListRef   - Reference to an (anonymous) list, e.g. the adjectives describing a
        #                       different non-model object
        #
        # Return values
        #   0 (not 'undef') on improper arguments
        #   Otheriwse, retuns a decimal number between 0 and 1

        my ($self, $targetListRef, $objectListRef, $check) = @_;

        # Local variables
        my (
            @targetList, @objectList, @intersection,
            %grepHash,
        );

        # Check for improper arguments
        if (! defined $targetListRef || ! defined $objectListRef || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->listCompare', @_);
            return 0;
        }

        # De-reference the passed lists
        @targetList = @$targetListRef;
        @objectList = @$objectListRef;

        # Find the intersection between the two lists
        if (! @targetList && ! @objectList) {

            # Identical (empty) lists
            return 1;

        } elsif (@targetList && @objectList) {

            # Neither list is empty
            %grepHash = map{$_ =>1} @targetList;
            @intersection = grep( $grepHash{$_}, @objectList);

            if (@targetList > @objectList) {

                # Return percentage of elements in @objectList that also appear in @targetList
                return (scalar @intersection / @targetList);

            } else {

                # Return percentage of elements in @targetList that also appear in @objectList
                return (scalar @intersection / @objectList);
            }

        } else {

            # One of the lists is empty, so they are not at all alike
            return 0;
        }
    }

    sub compileRedrawRooms {

        # Called by several functions (e.g. called by ->moveRoomsLabels)
        # Given a list of rooms which must be redrawn, expand that list to include any connecting
        #   rooms (which guarantees that the exits between them are redrawn correctly)
        # Returns a list in the form that GA::Win::Map->markObjs expects
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @roomList       - A list of room model objects (can be an empty list)
        #
        # Return values
        #   An empty list on improper arguments or if @roomList is empty
        #   Otherwise, returns the expanded list of rooms, in the form
        #       (string, room_object, string, room_object...)
        #   ...where 'string' is the literal string 'room', and 'room_object' is an affected room
        #       object (GA::ModelObj::Room)

        my ($self, @roomList) = @_;

        # Local variables
        my (
            @returnList,
            %checkHash,
        );

        # (No improper arguments to check)

        # Compile a hash of specified rooms (to eliminate duplicates)
        foreach my $roomObj (@roomList) {

            $checkHash{$roomObj->number} = $roomObj;
        }

        # Add any connected rooms to that hash
        foreach my $roomObj (@roomList) {

            foreach my $exitNum (
                # Add rooms connected by outgoing exits
                $roomObj->ivValues('exitNumHash'),
                # Add rooms connected by incoming one-way, uncertain (etc) exits
                $roomObj->ivKeys('uncertainExitHash'),
                $roomObj->ivKeys('oneWayExitHash'),
                $roomObj->ivKeys('randomExitHash'),
            ) {
                my ($exitObj, $roomObj);

                $exitObj = $self->ivShow('exitModelHash', $exitNum);
                if ($exitObj) {

                    $roomObj = $self->ivShow('modelHash', $exitObj->parent);
                    if ($roomObj) {

                        $checkHash{$roomObj->number} = $roomObj;
                    }
                }
            }

            # Also add destination rooms for any involuntary/repulse exit patterns which specify a
            #   destination
            foreach my $roomNum ($roomObj->ivKeys('invRepExitHash')) {

                my $roomObj = $self->ivShow('modelHash', $roomNum);
                if ($roomObj) {

                    $checkHash{$roomObj->number} = $roomObj;
                }
            }
        }

        # Compose a list in the form (string, object, string, object...)
        foreach my $roomObj (values %checkHash) {

            push (@returnList, 'room', $roomObj);
        }

        # Operation complete
        return @returnList;
    }

    sub findObjNumber {

        # In a room filled with 'three hairy orcs, two ugly orcs and a dwarf', with corresponding
        #   model objects stored in the Locator task's ->tempObjList IV as follows:
        #
        #   object1     'hairy orc'
        #   object2     'hairy orc'
        #   object3     'hairy orc'
        #   object4     'ugly orc'
        #   object5     'ugly orc'
        #   object6     'dwarf'
        #
        # ...this function works out the object's likely number on a world which numbers them
        #   'hairy orc 1', 'hairy orc2' or 'orc 1', ... 'orc 5'
        # This function is called with the blessed reference for one of these objects, $completeObj.
        #   The function's task is to find how many of the objects occuring in the list up to and
        #   including $completeObj match a partially-defined model object, $partialObj
        #
        # e.g.  If $completeObj is object4, and if $partialObj is an 'orc', this function returns 4
        #   If $completeObj is object4, and if $partialObj is an 'ugly orc', returns 1
        #   If $completeObj does not appear in the Locator task's ->tempObjList, returns 'undef'
        #
        # Expected arguments
        #   $session        - The parent GA::Session
        #   $completeObj    - A real object in the Locator task's current room
        #   $partialObj     - A partially-defined matching object
        #
        # Return values
        #   'undef' on improper arguments, if $completeObj doesn't appear in the Locator task's
        #       ->tempObjList or if the Locator task isn't running
        #   Otherwise returns a number, 1 or above, matching the object's likely numbering on the
        #       world

        my ($self, $session, $completeObj, $partialObj, $check) = @_;

        # Local variables
        my ($taskObj, $posn, $count, $number);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $completeObj || ! defined $partialObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->findObjNumber', @_);
        }

        # Import the Locator task
        $taskObj = $session->locatorTask;

        # Check that there is a Locator task running and that $completeObj really is in the task's
        #   current room
        if (! $taskObj || ! $taskObj->roomObj || ! $taskObj->roomObj->tempObjList) {

            return undef;
        }

        # Find $completeObj's position in the current room's object list
        $posn = $taskObj->roomObj->ivFind('tempObjList', $completeObj);
        if (! defined $posn) {

            # Not in the current room
            return undef;

        } elsif ($posn == 1) {

            # The world must number this object as #1
            return 1;
        }

        # Check every object in the list before $posn, to see how many match $partialObj
        $number = 1;    # $completeObj matches $partialObj
        for (my $count = 0; $count < $posn; $count++) {

            if (
                $self->objMatch(
                    100,
                    $partialObj,
                    $taskObj->roomObj->ivIndex('tempObjList', $count),
                )
            ) {
                $number++;
            }
        }

        return $number;
    }

    sub findRegionmap {

        # Can be called by anything
        # Given the ->number of a region model object (GA::ModelObj::Region), returns the equivalent
        #   regionmap object (GA::Obj::Regionmap)
        #
        # Expected arguments
        #   $number     - The number of a region model object
        #
        # Return values
        #   'undef' on improper arguments or if no matching regionmap is found
        #   Otherwise returns the matching GA::Obj::Regionmap

        my ($self, $number, $check) = @_;

        # Local variables
        my $regionObj;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findRegionmap', @_);
        }

        $regionObj = $self->ivShow('regionModelHash', $number);
        if (! $regionObj) {

            return undef;

        } else {

            return $self->ivShow('regionmapHash', $regionObj->name);
        }
    }

    sub reversePath {

        # Attempts to convert a path, consisting of a list of directions, into the opposite path
        # To convert a single direction, pass a list containing just the direction
        #       e.g. $pathList[0] = 'n' -> 's'
        # To convert a string consisting of several movement commands separated by the command
        #   separator, pass a list containing just the string
        #       e.g. $pathList[0] = 'n;nw;w;n;u' -> 'd;s;e;se;s'
        # To convert a list of directions, pass the list. The directions are converted into their
        #   opposites and the list is returned in the opposite order
        #       e.g. @pathList = ('n', 'nw', 'w') -> ('e', 'se', 's')
        # Only standard directions are converted into opposites. Other kinds of directions are left
        #   alone, under the assumption that the same word is used for the exit in both directions
        #       e.g. $pathList[0] = 'n;nw;closet;d' -> 'd;closet;se;s'
        # Standard secondary directions can have more than one opposite. Also, all the opposite
        #   directions in the list can be converted to abbreviated forms, if required
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $mode       - 'no_abbrev' - do not abbreviate / if there is more than one opposite
        #                   direction, use the first one
        #               - 'abbrev' - abbreviate / if there is more than one opposite direction, use
        #                   the first one
        #               - 'no_abbrev_opp' - do not abbreviate / return all opposite directions
        #               - 'abbrev_opp' - abbreviate / return all opposite directions
        #   @pathList   - a list of strings containing single directions or paths
        #
        # Notes
        #   For $modes 'no_abbrev_opp' and 'abbrev_opp', the opposite directions are returned as a
        #       string separated by a space, just as they occur in the dictionary
        #   e.g. 'entrance' -> 'exit out'
        #   In that case, it's up to the calling function to choose which direction to use
        #
        # Return values
        #   An empty list on improper arguments (including if @pathList is empty or $mode isn't
        #       a valid value)
        #   Otherwise returns the reversed list of directions, as described above

        my ($self, $session, $mode, @pathList) = @_;

        # Local variables
        my (
            $cmdSep, $dictObj,
            @emptyList,
        );

        # Check for improper arguments
        if (
            ! defined $mode
            || (
                $mode ne 'no_abbrev' && $mode ne 'abbrev' && $mode ne 'no_abbrev_opp'
                && $mode ne 'abbrev_opp'
            )
            || ! @pathList
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->reversePath', @_);
            return @emptyList;
        }

        $cmdSep = $axmud::CLIENT->cmdSep;
        $dictObj = $session->currentDict;

        foreach my $path (@pathList) {

            my @dirList = split(/$cmdSep/, $path);

            foreach my $dir (@dirList) {

                # If it's a standard direction, convert it into the opposite standard direction. If
                #   it's not a standard direction, don't change it
                if ($dictObj->ivExists('combDirHash', $dir)) {

                    # Do not abbreviate
                    if ($mode eq 'no_abbrev' || $mode eq 'no_abbrev_opp') {

                        $dir = $dictObj->ivShow('combOppDirHash', $dir);

                    # Abbreviate
                    } elsif ($mode eq 'abbrev' || $mode eq 'abbrev_opp') {

                        $dir = $dictObj->abbrevDir($dictObj->ivShow('combOppDirHash', $dir));
                    }

                    # If there is more than one opposite direction, use the first one
                    if ($mode eq 'no_abbrev' || $mode eq 'abbrev') {

                        my $position = index($dir, ' ');
                        if ($position > -1) {

                            $dir = substr($dir, ($position -1));
                        }
                    }
                }
            }

            @dirList = reverse @dirList;
            $path = join($cmdSep, @dirList);
        }

        @pathList = reverse @pathList;
        return (@pathList);
    }

    sub checkExitState {

        # Called by GA::Task::Locator->processExits (or by any other code)
        # On some worlds, the verbose list of exits indicates the state of an exit by surrounding
        #   some (or all) exits with exit state strings, e.g. the brackets in
        #       'Obvious exits : north, (east), west'
        # Given a string containing a single exit (e.g. 'north' or '(east)'), this function removes
        #   the exit state strings from the beginning, middle or end of each exit, if they occur,
        #   and returns both the modified string and the corresponding exit state (one of the
        #   possible values of GA::Obj::Exit->exitState, e.g. 'locked')
        #
        # Expected arguments
        #   $profObj    - The calling session's current world profile object
        #   $exit       - A string containing a single exit, optionally starting/ending or
        #                   containing exit state strings
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form
        #       (state, mod_exit)
        #   ...where 'state' is one of the possible values of GA::Obj::Exit->exitState (e.g. 'open',
        #       'closed', impass'), and 'mod_exit' is the modified form of $exit, with all valid
        #       exit state strings removed

        my ($self, $profObj, $exit, $check) = @_;

        # Local variables
        my (@emptyList, @stringList);

        # Check for improper arguments
        if (! defined $profObj || ! defined $exit || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->checkExitState', @_);
            return @emptyList,
        }

        @stringList = $profObj->exitStateStringList;
        if (@stringList) {

            do {

                my ($state, $start, $middle, $end, $result, $modExit);

                $state = shift @stringList;
                $start = shift @stringList;
                $middle = shift @stringList;
                $end = shift @stringList;

                # Test the exit for exit state strings, and remove them if found (e.g. remove the
                #   brackets from '(east)'
                ($result, $modExit) = $self->testExitState(
                    $exit,
                    $start,
                    $middle,
                    $end,
                );

                if ($result) {

                    return ($state, $modExit);
                }

            } until (! @stringList);
        }

        # Default exit state is 'normal' (exit is passable, or state not known)
        return ('normal', $exit);
    }

    sub testExitState {

        # Called by $self->checkExitState (only)
        # On some worlds, the verbose list of exits indicates the state of an exit by surrounding
        #   some (or all) exits with exit state strings, e.g. the brackets in
        #       'Obvious exits : north, (east), west'
        # On some other worlds, the verbose list of exits indicates an exit state by surrounding
        #   some characters at the beginning (usually just one character) with symbols, e.g.
        #   'Obvious exits : (n)orth, east, (w)est'
        # This function tests an exit string like 'north', '(north)' or '(n)orth' to see if it
        #   contains a set of exit state strings, and then returns a list containing the result of
        #   the test and a modified exit string, with the exit state strings removed if found
        #
        # Expected arguments
        #   $exit       - A string containing a single exit, optionally containing exit state
        #                   strings
        #
        # Optional arguments
        #   $start      - A string containing characters that should be found at the beginning of
        #                   $exit (an empty string, if nothing should be removed from the beginning)
        #   $middle     - A string containing characters that should be found in the middle of
        #                   $exit (or an empty string)
        #   $end        - A string containing characters that should be found at the end of $exit
        #                   (or an empty string)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form
        #       (result, mod_exit)
        #   ...where 'result' is TRUE if all the expected exit state strings are present (FALSE if
        #       not) and where 'mod_exit' is the modified form of $exit, with all the exit state
        #       strings removed

        my ($self, $exit, $start, $middle, $end, $check) = @_;

        # Local variables
        my (
            $modExit, $posn,
            @emptyList,
        );

        # Check for improper arguments
        if (
            ! defined $exit || ! defined $start || ! defined $middle || ! defined $end
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->testExitState', @_);
            return @emptyList;
        }

        # Special case: if $start, $middle and $end are all empty strings, then no exit state is
        #   detectable (and the exit's state will be set to 'normal'
        if (! $start && ! $middle && ! $end) {

            return (FALSE, $exit);
        }

        # $exit (e.g. 'north') has already been reduced to lower-case characters, so we must also
        #   make sure that $start, $middle and $end are lower-case characters
        $start = lc($start);
        $middle = lc($middle);
        $end = lc($end);

        $modExit = $exit;

        if ($start) {

            if (index($modExit, $start) == 0) {

                # Remove the exit state string
                $modExit = substr($modExit, (length $start));

            } else {

                # Exit state strings not found. Return the exit string unmodified
                return (FALSE, $exit);
            }
        }

        # If $middle and $end are both non-empty strings, $middle must occur before $end. If only
        #   $middle is set, it can occur in the middle or at the end. If only $end is set, it can
        #   occur only at the end
        # Removing $middle before looking for $end accomplishes this
        if ($middle) {

            # (Second symbol can occur in middle or at end of $exit)
            $posn = index($modExit, $middle);
            if ($posn > -1) {

                substr($modExit, $posn, length($middle)) = '';

            } else {

                # Exit state strings not found. Return the exit string unmodified
                return (FALSE, $exit);
            }
        }

        if ($end) {

            $posn = index($modExit, $end);
            if ($posn > -1 && $posn == (length($modExit) - length($end))) {

                substr($modExit, $posn, length($end)) = '';

            } else {

                # Exit state strings not found. Return the exit string unmodified
                return (FALSE, $exit);
            }
        }

        # All expected exit state strings found
        return (TRUE, $modExit);
    }

    sub checkRoomAlignment {

        # Called by GA::Win::Map->moveSelectedObjects, $self->connectRegionBrokenExit and
        #   $self->modifyIncomingExits
        # When an exit, which was formerly a region exit, is involved in a move operation, and when
        #   that move places the exit's parent room and the destination room in the same regionmap,
        #   it is probably now a broken exit
        # However, if (by chance) the two rooms are aligned along the direction of the exit, it's
        #   not a broken exit but a normal one
        # In addition, we check whether there are any existing rooms in a direct line between the
        #   two rooms. If any existing rooms are found, we consider that the two rooms aren't
        #   aligned
        # NB Rooms are only considered to be aligned along the north-south, east-west,
        #   northeast-southwest, northwest-southeast and up-down axes
        #
        # We also perform the same check in a 'connect to click' operation and when adding an exit
        #   manually
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $exitObj    - The GA::Obj::Exit object to check
        #
        # Return values
        #   'undef' on improper arguments, if the exit is a retracing exit, if the two rooms aren't
        #       aligned or if there are existing rooms between the exit's departure and arrival
        #       rooms
        #   1 if the two rooms are aligned

        my ($self, $session, $exitObj, $check) = @_;

        # Local variables
        my (
            $departRoomObj, $arriveRoomObj, $regionmapObj, $mapDir, $listRef, $xPos, $yPos, $zPos,
            $xVector, $yVector, $zVector, $count,
            %vectorHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkRoomAlignment', @_);
        }

        # Sanity check: we can't check for a room alignment if the exit's ->mapDir is not set (which
        #   it won't be, if it's unallocatable)
        if (! $exitObj->mapDir) {

            return undef;
        }

        # Get a shortcut for the exit's ->mapDir
        $mapDir = $exitObj->mapDir;
        # We can check that ->mapDir isn't in a northnortheast direction (etc) by checking if its
        #   length is greater than ten characters (e.g. northwest is only 9)
        if (length ($exitObj->mapDir) > 10) {

            # We don't consider that the rooms are aligned
            return undef;
        }

        # Get the blessed references of the exit's parent room and of the destination room
        $departRoomObj = $self->ivShow('modelHash', $exitObj->parent);
        $arriveRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);
        # Get the regionmap to check
        $regionmapObj = $self->findRegionmap($departRoomObj->parent);

        # Import the vector hash, in the form
        #   %vectorHash         => {
        #       north           => [0, -1, 0],
        #       northeast       => [1, -1, 0],
        #       east            => [1, 0, 0],
        #       southeast       => [1, 1, 0],
        #       south           => [0, 1, 0],
        #       southwest       => [-1, 1, 0],
        #       west            => [-1, 0, 0],
        #       northwest       => [-1, -1, 0],
        #       up              => [0, 0, 1],
        #       down            => [0, 0, -1],
        #   },
        # NB It also includes entries for northnorthwest, etc, but we're not using them
        %vectorHash = $session->mapWin->constVectorHash;
        $listRef = $vectorHash{$mapDir};

        # Check the general direction between the two rooms
        if (
            # Movement along x axis (west -> east)
            (($$listRef[0] == 0) && ($departRoomObj->xPosBlocks != $arriveRoomObj->xPosBlocks))
            || (($$listRef[0] == 1) && ($departRoomObj->xPosBlocks >= $arriveRoomObj->xPosBlocks))
            || (($$listRef[0] == -1) && ($departRoomObj->xPosBlocks <= $arriveRoomObj->xPosBlocks))
            # Movement along y axis (north -> south)
            || (($$listRef[1] == 0) && ($departRoomObj->yPosBlocks != $arriveRoomObj->yPosBlocks))
            || (($$listRef[1] == 1) && ($departRoomObj->yPosBlocks >= $arriveRoomObj->yPosBlocks))
            || (($$listRef[1] == -1) && ($departRoomObj->yPosBlocks <= $arriveRoomObj->yPosBlocks))
            # Movement along z axis (down > up)
            || (($$listRef[2] == 0) && ($departRoomObj->zPosBlocks != $arriveRoomObj->zPosBlocks))
            || (($$listRef[2] == 1) && ($departRoomObj->zPosBlocks >= $arriveRoomObj->zPosBlocks))
            || (($$listRef[2] == -1) && ($departRoomObj->zPosBlocks <= $arriveRoomObj->zPosBlocks))
        ) {
            # The rooms are not aligned
            return undef;
        }

        # Check that the path between the two rooms is in one of the ten primary directions checked
        #   by this function
        $xVector = $arriveRoomObj->xPosBlocks - $departRoomObj->xPosBlocks;
        $yVector = $arriveRoomObj->yPosBlocks - $departRoomObj->yPosBlocks;
        $zVector = $arriveRoomObj->zPosBlocks - $departRoomObj->zPosBlocks;

        # Remove minus signs so we can test whether the magnitudes of $xVector and $yVector are
        #   the same
        if ($xVector < 0) {$xVector *= -1};
        if ($yVector < 0) {$yVector *= -1};

        if (
            # ne, se, sw, nw
            ! (
                $$listRef[0] && $$listRef[1] && (! $$listRef[2])
                && $xVector && $yVector && (! $zVector) && $xVector == $yVector
            )
            # n, s
            && ! (
                (! $$listRef[0]) && $$listRef[1] && (! $$listRef[2])
                && (! $xVector) && $yVector && (! $zVector)
            )
            # w, e
            && ! (
                $$listRef[0] && (! $$listRef[1]) && (! $$listRef[2])
                && $xVector && (! $yVector) && (! $zVector)
            )
            # u, d
            && ! (
                (! $$listRef[0]) && (! $$listRef[1]) && $$listRef[2]
                && (! $xVector) && (! $yVector) && $zVector
            )
        ) {
            # The rooms are not aligned
            return undef;
        }

        # Check that there are no existing rooms in between $departRoomObj and $arriveRoomObj that
        #   would clash with the drawn exit
        $xPos = $departRoomObj->xPosBlocks;
        $yPos = $departRoomObj->yPosBlocks;
        $zPos = $departRoomObj->zPosBlocks;
        $count = 0;
        do {

            $count++;

            # Check the next gridblock on the flightpath between $departRoomObj and
            #   $arriveRoomObj
            $xPos += $$listRef[0];
            $yPos += $$listRef[1];
            $zPos += $$listRef[2];

            if (
                $xPos == $arriveRoomObj->xPosBlocks
                && $yPos == $arriveRoomObj->yPosBlocks
                && $zPos == $arriveRoomObj->zPosBlocks
            ) {
                # We've checked every gridblock between the two rooms, and found no existing
                #   rooms on the way. In addition, the rooms are aligned in the direction
                #   drawn as $mapDir
                return 1;

            } else {

                # If there's a room in this gridblock, return 0 to show that the exit can't
                #   be drawn here, and that it must therefore be marked as a broken exit
                if ($regionmapObj->fetchRoom($xPos, $yPos, $zPos)) {

                    return undef;
                }
            }

        # Don't bother looking beyond the maximum drawn exit size (currently 16)
        } until ($count >= $self->maxExitLengthBlocks);

        return 1;
    }

    ##################
    # Accessors - set

    # Definitely keep

    sub set_adjacentMode {

        my ($self, $mode, $count, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_adjacentMode', @_);
        }

        # Update IVs
        $self->ivPoke('adjacentMode', $mode);
        if (defined $count) {

            $self->ivPoke('adjacentCount', $count);
        }

        return 1;
    }

    sub set_autoCompareMax {

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoCompareMax', @_);
        }

        # Update IVs
        $self->ivPoke('autoCompareMax', $number);

        return 1;
    }

    sub set_autoSlideMax {

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoSlideMax', @_);
        }

        # Update IVs
        $self->ivPoke('autoSlideMax', $number);

        return 1;
    }

    sub set_autoOpenWinFlag {

        # Called by GA::Cmd::ToggleAutomapper->do

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoOpenWinFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('autoOpenWinFlag', TRUE);
        } else {
            $self->ivPoke('autoOpenWinFlag', FALSE);
        }

        # Also need to update the check button in every Automapper window
        foreach my $mapWin ($self->collectMapWins()) {

            $self->worldModelObj->toggleFlag(
                'autoOpenWinFlag',
                $self->autoOpenWinFlag,
                FALSE,      # Don't call $mapWin->drawRegion
                'auto_open_win',
            );
        }

        return 1;
    }

    sub add_buttonSet {

        # Called by GA::Win::Map->addToolbar

        my ($self, $set, $check) = @_;

        # Check for improper arguments
        if (! defined $set || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_buttonSet', @_);
        }

        $self->ivPush('buttonSetList', $set);

        return 1;
    }

    sub del_buttonSet {

        # Called by GA::Win::Map->removeToolbar

        my ($self, $set, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $set || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_buttonSet', @_);
        }

        foreach my $item ($self->buttonSetList) {

            if ($item ne $set) {

                push (@list, $item);
            }
        }

        $self->ivPoke('buttonSetList', @list);

        return 1;
    }

    sub set_buttonSetList {

        # Called by GA::Win::Map->enableToolbar

        my ($self, @list) = @_;

        # (No improper arguments to check)

        $self->ivPoke('buttonSetList', @list);

        return 1;
    }

    sub set_exitAltDir {

        my ($self, $exitObj, $string, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_exitAltDir', @_);
        }

        $exitObj->ivPoke('altDir', $string);

        return 1;
    }

    sub add_preferRoomFlag {

        # Called by GA::Win::Map->addRoomFlagButton

        my ($self, $roomFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $roomFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_preferRoomFlag', @_);
        }

        # Don't add duplicate room flags. The calling code should take care of this, but we'll
        #   check anyway
        foreach my $item ($self->preferRoomFlagList) {

            if ($item eq $roomFlag) {

                return undef;
            }
        }

        # Update the list
        $self->ivPush('preferRoomFlagList', $roomFlag);

        return 1;
    }

    sub del_preferRoomFlag {

        # Called by GA::Win::Map->addRoomFlagButton

        my ($self, $roomFlag, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $roomFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_preferRoomFlag', @_);
        }

        foreach my $item ($self->preferRoomFlagList) {

            if ($item ne $roomFlag) {

                push (@list, $item);
            }
        }

        $self->ivPoke('preferRoomFlagList', @list);

        return 1;
    }

    sub reset_preferRoomFlagList {

        # Called by GA::Win::Map->removeRoomFlagButton

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->reset_preferRoomFlagList',
                @_,
            );
        }

        $self->ivEmpty('preferRoomFlagList');

        return 1;
    }

    sub add_preferBGColour {

        # Called by GA::Win::Map->addBGColourButton

        my ($self, $colour, $check) = @_;

        # Check for improper arguments
        if (! defined $colour || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_preferBGColour', @_);
        }

        # Don't add duplicate colours
        foreach my $item ($self->preferBGColourList) {

            if ($item eq $colour) {

                return undef;
            }
        }

        # Update the list
        $self->ivPush('preferBGColourList', $colour);

        return 1;
    }

    sub del_preferBGColour {

        # Called by GA::Win::Map->removeBGColourButton

        my ($self, $colour, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $colour || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_preferBGColour', @_);
        }

        foreach my $item ($self->preferBGColourList) {

            if ($item ne $colour) {

                push (@list, $item);
            }
        }

        $self->ivPoke('preferBGColourList', @list);

        return 1;
    }

    sub reset_preferBGColourList {

        # Called by GA::Win::Map->removeBGColourButton

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->reset_preferBGColourList',
                @_,
            );
        }

        $self->ivEmpty('preferBGColourList');

        return 1;
    }

    sub toggle_componentFlag {

        # Called by GA::Cmd::ToggleAutomapper->do

        my ($self, $iv, $check) = @_;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_componentFlag', @_);
        }

        # Toggle the flag
        if ($self->$iv) {
            $self->ivPoke($iv, FALSE);
        } else {
            $self->ivPoke($iv, TRUE);
        }

        # Also need to update the check button in every Automapper window
        $self->toggleWinComponents($iv, $self->$iv);

        return 1;
    }

    sub set_exitLengthBlocks {

        my ($self, $type, $length, $check) = @_;

        # Check for improper arguments
        if (! defined $type || ! defined $length || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_exitLengthBlocks', @_);
        }

        if ($type eq 'vertical') {
            $self->ivPoke('verticalExitLengthBlocks', $length);
        } else {
            $self->ivPoke('horizontalExitLengthBlocks', $length);
        }

        return 1;
    }

    sub set_obscuredExitRadius {

        my ($self, $radius, $check) = @_;

        # Check for improper arguments
        if (! defined $radius || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_obscuredExitRadius', @_);
        }

        $self->ivPoke('obscuredExitRadius', $radius);

        return 1;
    }

    sub set_lightStatus {

        # Called by GA::Cmd::SetLightStatus->do

        my ($self, $status, $check) = @_;

        # Check for improper arguments
        if (! defined $status || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_lightStatus', @_);
        }

        $self->ivPoke('lightStatus', $status);

        return 1;
    }

    sub set_lightStatusList {

        # Called by GA::Cmd::SetLightList->do

        my ($self, @list) = @_;

        # Check for improper arguments
        if (! @list) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_lightStatusList', @_);
        }

        $self->ivPoke('lightStatusList', @list);

        return 1;
    }

    sub set_mapLabelStyle {

        # Called by GA::Win::Map->addLabelAtBlockCallback, ->addLabelAtClickCallback and
        #   ->setLabelCallback

        my ($self, $style, $check) = @_;

        # Check for improper arguments
        if (! defined $style || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_mapLabelStyle', @_);
        }

        $self->ivPoke('mapLabelStyle', $style);

        return 1;
    }

    sub set_matchDescripCharCount {

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_matchDescripCharCount',
                @_,
            );
        }

        # Update IVs
        $self->ivPoke('matchDescripCharCount', $number);

        return 1;
    }

    sub set_minionStringHash {

        # Called by GA::Cmd::DeleteMinionString->do

        my ($self, %hash) = @_;

        # (No improper arguments to check)

        $self->ivPoke('minionStringHash', %hash);

        return 1;
    }

    sub set_paintAllRoomsFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_paintAllRoomsFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('paintAllRoomsFlag', TRUE);
        } else {
            $self->ivPoke('paintAllRoomsFlag', FALSE);
        }

        return 1;
    }

    sub set_preDrawMinRooms {

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_preDrawMinRooms', @_);
        }

        # Update IVs
        $self->ivPoke('preDrawMinRooms', $number);

        return 1;
    }

    sub set_quickPaintMultiFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_quickPaintMultiFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('quickPaintMultiFlag', TRUE);
        } else {
            $self->ivPoke('quickPaintMultiFlag', FALSE);
        }

        return 1;
    }

    sub set_preDrawAllocation {

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_preDrawAllocation', @_);
        }

        # Update IVs
        $self->ivPoke('preDrawAllocation', $number);

        return 1;
    }

    sub set_preDrawRetainRooms {

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_preDrawRetainRooms', @_);
        }

        # Update IVs
        $self->ivPoke('preDrawRetainRooms', $number);

        return 1;
    }

    sub set_roomFlagShowMode {

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_roomFlagShowMode', @_);
        }

        # Update IVs
        $self->ivPoke('roomFlagShowMode', $mode);

        # Must redraw the menu in any automapper windows, so that the new room flag appears in them
        $self->updateMapMenuToolbars();

        return 1;
    }

    sub set_searchSelectRoomsFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_searchSelectRoomsFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('searchSelectRoomsFlag', TRUE);
        } else {
            $self->ivPoke('searchSelectRoomsFlag', FALSE);
        }

        return 1;
    }

    sub set_showCanvasFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_showCanvasFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('showCanvasFlag', TRUE);
        } else {
            $self->ivPoke('showCanvasFlag', FALSE);
        }

        return 1;
    }

    sub set_showMenuBarFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_showMenuBarFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('showMenuBarFlag', TRUE);
        } else {
            $self->ivPoke('showMenuBarFlag', FALSE);
        }

        return 1;
    }

    sub set_showToolbarFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_showToolbarFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('showToolbarFlag', TRUE);
        } else {
            $self->ivPoke('showToolbarFlag', FALSE);
        }

        return 1;
    }

    sub set_showTreeViewFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_showTreeViewFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('showTreeViewFlag', TRUE);
        } else {
            $self->ivPoke('showTreeViewFlag', FALSE);
        }

        return 1;
    }

    sub add_teleport {

        # Called by GA::Cmd::AddTeleport

        my ($self, $room, $cmd, $check) = @_;

        # Check for improper arguments
        if (! defined $room || ! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_teleport', @_);
        }

        $self->ivAdd('teleportHash', $room, $cmd);

        return 1;
    }

    sub del_teleport {

        # Called by GA::Cmd::DeleteTeleport

        my ($self, $room, $check) = @_;

        # Check for improper arguments
        if (! defined $room || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_teleport', @_);
        }

        $self->ivDelete('teleportHash', $room);

        return 1;
    }

    ##################
    # Accessors - get

    sub author
        { $_[0]->{author} }
    sub date
        { $_[0]->{date} }
    sub version
        { $_[0]->{version} }
    sub descripList
        { my $self = shift; return @{$self->{descripList}}; }

    sub modelCreationDate
        { $_[0]->{modelCreationDate} }
    sub modelCreationVersion
        { $_[0]->{modelCreationVersion} }
    sub modelConvertedFlag
        { $_[0]->{modelConvertedFlag} }
    sub modelConvertedVersion
        { $_[0]->{modelConvertedVersion} }
    sub modelSaveFileCount
        { $_[0]->{modelSaveFileCount} }

    sub modelHash
        { my $self = shift; return %{$self->{modelHash}}; }
    sub regionModelHash
        { my $self = shift; return %{$self->{regionModelHash}}; }
    sub roomModelHash
        { my $self = shift; return %{$self->{roomModelHash}}; }
    sub weaponModelHash
        { my $self = shift; return %{$self->{weaponModelHash}}; }
    sub armourModelHash
        { my $self = shift; return %{$self->{armourModelHash}}; }
    sub garmentModelHash
        { my $self = shift; return %{$self->{garmentModelHash}}; }
    sub charModelHash
        { my $self = shift; return %{$self->{charModelHash}}; }
    sub minionModelHash
        { my $self = shift; return %{$self->{minionModelHash}}; }
    sub sentientModelHash
        { my $self = shift; return %{$self->{sentientModelHash}}; }
    sub creatureModelHash
        { my $self = shift; return %{$self->{creatureModelHash}}; }
    sub portableModelHash
        { my $self = shift; return %{$self->{portableModelHash}}; }
    sub decorationModelHash
        { my $self = shift; return %{$self->{decorationModelHash}}; }
    sub customModelHash
        { my $self = shift; return %{$self->{customModelHash}}; }

    sub modelObjCount
        { $_[0]->{modelObjCount} }
    sub modelActualCount
        { $_[0]->{modelActualCount} }
    sub modelDeletedList
        { my $self = shift; return @{$self->{modelDeletedList}}; }
    sub modelBufferList
        { my $self = shift; return @{$self->{modelBufferList}}; }
    sub mostRecentNum
        { $_[0]->{mostRecentNum} }

    sub exitModelHash
        { my $self = shift; return %{$self->{exitModelHash}}; }
    sub exitObjCount
        { $_[0]->{exitObjCount} }
    sub exitActualCount
        { $_[0]->{exitActualCount} }
    sub exitDeletedList
        { my $self = shift; return @{$self->{exitDeletedList}}; }
    sub exitBufferList
        { my $self = shift; return @{$self->{exitBufferList}}; }
    sub mostRecentExitNum
        { $_[0]->{mostRecentExitNum} }

    sub regionmapHash
        { my $self = shift; return %{$self->{regionmapHash}}; }
    sub reverseRegionListFlag
        { $_[0]->{reverseRegionListFlag} }
    sub firstRegion
        { $_[0]->{firstRegion} }

    sub preDrawAllowFlag
        { $_[0]->{preDrawAllowFlag} }
    sub preDrawMinRooms
        { $_[0]->{preDrawMinRooms} }
    sub preDrawRetainRooms
        { $_[0]->{preDrawRetainRooms} }
    sub preDrawAllocation
        { $_[0]->{preDrawAllocation} }

    sub knownCharHash
        { my $self = shift; return %{$self->{knownCharHash}}; }
    sub minionStringHash
        { my $self = shift; return %{$self->{minionStringHash}}; }

    sub lightStatus
        { $_[0]->{lightStatus} }
    sub constLightStatusList
        { my $self = shift; return @{$self->{constLightStatusList}}; }
    sub lightStatusList
        { my $self = shift; return @{$self->{lightStatusList}}; }

    sub roomTagHash
        { my $self = shift; return %{$self->{roomTagHash}}; }

    sub teleportHash
        { my $self = shift; return %{$self->{teleportHash}}; }

    sub autoOpenWinFlag
        { $_[0]->{autoOpenWinFlag} }
    sub pseudoWinFlag
        { $_[0]->{pseudoWinFlag} }
    sub showMenuBarFlag
        { $_[0]->{showMenuBarFlag} }
    sub showToolbarFlag
        { $_[0]->{showToolbarFlag} }
    sub showTreeViewFlag
        { $_[0]->{showTreeViewFlag} }
    sub showCanvasFlag
        { $_[0]->{showCanvasFlag} }
    sub buttonSetList
        { my $self = shift; return @{$self->{buttonSetList}}; }
    sub preferRoomFlagList
        { my $self = shift; return @{$self->{preferRoomFlagList}}; }
    sub preferBGColourList
        { my $self = shift; return @{$self->{preferBGColourList}}; }

    sub defaultGridWidthBlocks
        { $_[0]->{defaultGridWidthBlocks} }
    sub defaultGridHeightBlocks
        { $_[0]->{defaultGridHeightBlocks} }
    sub defaultBlockWidthPixels
        { $_[0]->{defaultBlockWidthPixels} }
    sub defaultBlockHeightPixels
        { $_[0]->{defaultBlockHeightPixels} }
    sub defaultRoomWidthPixels
        { $_[0]->{defaultRoomWidthPixels} }
    sub defaultRoomHeightPixels
        { $_[0]->{defaultRoomHeightPixels} }

    sub maxGridWidthBlocks
        { $_[0]->{maxGridWidthBlocks} }
    sub maxGridHeightBlocks
        { $_[0]->{maxGridHeightBlocks} }
    sub maxBlockWidthPixels
        { $_[0]->{maxBlockWidthPixels} }
    sub maxBlockHeightPixels
        { $_[0]->{maxBlockHeightPixels} }
    sub maxRoomWidthPixels
        { $_[0]->{maxRoomWidthPixels} }
    sub maxRoomHeightPixels
        { $_[0]->{maxRoomHeightPixels} }

    sub defaultMapWidthPixels
        { $_[0]->{defaultMapWidthPixels} }
    sub defaultMapHeightPixels
        { $_[0]->{defaultMapHeightPixels} }

    sub regionSchemeHash
        { my $self = shift; return %{$self->{regionSchemeHash}}; }
    sub defaultSchemeObj
        { $_[0]->{defaultSchemeObj} }

    sub defaultBackgroundColour
        { $_[0]->{defaultBackgroundColour} }
    sub defaultNoBackgroundColour
        { $_[0]->{defaultNoBackgroundColour} }
    sub defaultRoomColour
        { $_[0]->{defaultRoomColour} }
    sub defaultRoomTextColour
        { $_[0]->{defaultRoomTextColour} }
    sub defaultSelectBoxColour
        { $_[0]->{defaultSelectBoxColour} }
    sub defaultBorderColour
        { $_[0]->{defaultBorderColour} }
    sub defaultCurrentBorderColour
        { $_[0]->{defaultCurrentBorderColour} }
    sub defaultCurrentFollowBorderColour
        { $_[0]->{defaultCurrentFollowBorderColour} }
    sub defaultCurrentWaitBorderColour
        { $_[0]->{defaultCurrentWaitBorderColour} }
    sub defaultCurrentSelectBorderColour
        { $_[0]->{defaultCurrentSelectBorderColour} }
    sub defaultLostBorderColour
        { $_[0]->{defaultLostBorderColour} }
    sub defaultLostSelectBorderColour
        { $_[0]->{defaultLostSelectBorderColour} }
    sub defaultGhostBorderColour
        { $_[0]->{defaultGhostBorderColour} }
    sub defaultGhostSelectBorderColour
        { $_[0]->{defaultGhostSelectBorderColour} }
    sub defaultSelectBorderColour
        { $_[0]->{defaultSelectBorderColour} }
    sub defaultRoomAboveColour
        { $_[0]->{defaultRoomAboveColour} }
    sub defaultRoomBelowColour
        { $_[0]->{defaultRoomBelowColour} }
    sub defaultRoomTagColour
        { $_[0]->{defaultRoomTagColour} }
    sub defaultSelectRoomTagColour
        { $_[0]->{defaultSelectRoomTagColour} }
    sub defaultRoomGuildColour
        { $_[0]->{defaultRoomGuildColour} }
    sub defaultSelectRoomGuildColour
        { $_[0]->{defaultSelectRoomGuildColour} }
    sub defaultExitColour
        { $_[0]->{defaultExitColour} }
    sub defaultSelectExitColour
        { $_[0]->{defaultSelectExitColour} }
    sub defaultSelectExitTwinColour
        { $_[0]->{defaultSelectExitTwinColour} }
    sub defaultSelectExitShadowColour
        { $_[0]->{defaultSelectExitShadowColour} }
    sub defaultRandomExitColour
        { $_[0]->{defaultRandomExitColour} }
    sub defaultImpassableExitColour
        { $_[0]->{defaultImpassableExitColour} }
    sub defaultMysteryExitColour
        { $_[0]->{defaultMysteryExitColour} }
    sub defaultCheckedDirColour
        { $_[0]->{defaultCheckedDirColour} }
    sub defaultDragExitColour
        { $_[0]->{defaultDragExitColour} }
    sub defaultExitTagColour
        { $_[0]->{defaultExitTagColour} }
    sub defaultSelectExitTagColour
        { $_[0]->{defaultSelectExitTagColour} }
    sub defaultMapLabelColour
        { $_[0]->{defaultMapLabelColour} }
    sub defaultSelectMapLabelColour
        { $_[0]->{defaultSelectMapLabelColour} }

    sub mapLabelStyleHash
        { my $self = shift; return %{$self->{mapLabelStyleHash}}; }
    sub mapLabelStyle
        { $_[0]->{mapLabelStyle} }
    sub mapLabelAlignXFlag
        { $_[0]->{mapLabelAlignXFlag} }
    sub mapLabelAlignYFlag
        { $_[0]->{mapLabelAlignYFlag} }
    sub mapLabelTextViewFlag
        { $_[0]->{mapLabelTextViewFlag} }

    sub roomFilterApplyHash
        { my $self = shift; return %{$self->{roomFilterApplyHash}}; }
    sub roomFlagHash
        { my $self = shift; return %{$self->{roomFlagHash}}; }
    sub roomFlagOrderedList
        { my $self = shift; return @{$self->{roomFlagOrderedList}}; }
    sub allRoomFiltersFlag
        { $_[0]->{allRoomFiltersFlag} }
    sub roomFlagShowMode
        { $_[0]->{roomFlagShowMode} }
    sub roomTerrainInitHash
        { my $self = shift; return %{$self->{roomTerrainInitHash}}; }
    sub roomTerrainHash
        { my $self = shift; return %{$self->{roomTerrainHash}}; }

    sub paintFromTitleHash
        { my $self = shift; return %{$self->{paintFromTitleHash}}; }
    sub paintFromDescripHash
        { my $self = shift; return %{$self->{paintFromDescripHash}}; }
    sub paintFromExitHash
        { my $self = shift; return %{$self->{paintFromExitHash}}; }
    sub paintFromObjHash
        { my $self = shift; return %{$self->{paintFromObjHash}}; }
    sub paintFromRoomCmdHash
        { my $self = shift; return %{$self->{paintFromRoomCmdHash}}; }

    sub currentRoomMode
        { $_[0]->{currentRoomMode} }
    sub roomInteriorMode
        { $_[0]->{roomInteriorMode} }
    sub roomInteriorXOffset
        { $_[0]->{roomInteriorXOffset} }
    sub roomInteriorYOffset
        { $_[0]->{roomInteriorYOffset} }

    sub drawExitMode
        { $_[0]->{drawExitMode} }
    sub obscuredExitFlag
        { $_[0]->{obscuredExitFlag} }
    sub obscuredExitRedrawFlag
        { $_[0]->{obscuredExitRedrawFlag} }
    sub obscuredExitRadius
        { $_[0]->{obscuredExitRadius} }
    sub maxObscuredExitRadius
        { $_[0]->{maxObscuredExitRadius} }
    sub drawOrnamentsFlag
        { $_[0]->{drawOrnamentsFlag} }
    sub horizontalExitLengthBlocks
        { $_[0]->{horizontalExitLengthBlocks} }
    sub verticalExitLengthBlocks
        { $_[0]->{verticalExitLengthBlocks} }
    sub maxExitLengthBlocks
        { $_[0]->{maxExitLengthBlocks} }
    sub drawBentExitsFlag
        { $_[0]->{drawBentExitsFlag} }

    sub matchTitleFlag
        { $_[0]->{matchTitleFlag} }
    sub matchDescripFlag
        { $_[0]->{matchDescripFlag} }
    sub matchDescripCharCount
        { $_[0]->{matchDescripCharCount} }
    sub matchExitFlag
        { $_[0]->{matchExitFlag} }
    sub analyseDescripFlag
        { $_[0]->{analyseDescripFlag} }
    sub matchSourceFlag
        { $_[0]->{matchSourceFlag} }
    sub matchVNumFlag
        { $_[0]->{matchVNumFlag} }

    sub updateTitleFlag
        { $_[0]->{updateTitleFlag} }
    sub updateDescripFlag
        { $_[0]->{updateDescripFlag} }
    sub updateExitFlag
        { $_[0]->{updateExitFlag} }
    sub updateSourceFlag
        { $_[0]->{updateSourceFlag} }
    sub updateVNumFlag
        { $_[0]->{updateVNumFlag} }
    sub updateRoomCmdFlag
        { $_[0]->{updateRoomCmdFlag} }
    sub updateOrnamentFlag
        { $_[0]->{updateOrnamentFlag} }

    sub assistedMovesFlag
        { $_[0]->{assistedMovesFlag} }
    sub assistedBreakFlag
        { $_[0]->{assistedBreakFlag} }
    sub assistedPickFlag
        { $_[0]->{assistedPickFlag} }
    sub assistedUnlockFlag
        { $_[0]->{assistedUnlockFlag} }
    sub assistedOpenFlag
        { $_[0]->{assistedOpenFlag} }
    sub assistedCloseFlag
        { $_[0]->{assistedCloseFlag} }
    sub assistedLockFlag
        { $_[0]->{assistedLockFlag} }
    sub protectedMovesFlag
        { $_[0]->{protectedMovesFlag} }
    sub superProtectedMovesFlag
        { $_[0]->{superProtectedMovesFlag} }
    sub craftyMovesFlag
        { $_[0]->{craftyMovesFlag} }

    sub setTwinOrnamentFlag
        { $_[0]->{setTwinOrnamentFlag} }

    sub newRoomScriptList
        { my $self = shift; return @{$self->{newRoomScriptList}}; }
    sub arriveScriptList
        { my $self = shift; return @{$self->{arriveScriptList}}; }

    sub countVisitsFlag
        { $_[0]->{countVisitsFlag} }
    sub allowModelScriptFlag
        { $_[0]->{allowModelScriptFlag} }
    sub allowRoomScriptFlag
        { $_[0]->{allowRoomScriptFlag} }
    sub intelligentExitsFlag
        { $_[0]->{intelligentExitsFlag} }
    sub followAnchorFlag
        { $_[0]->{followAnchorFlag} }
    sub capitalisedRoomTagFlag
        { $_[0]->{capitalisedRoomTagFlag} }
    sub showTooltipsFlag
        { $_[0]->{showTooltipsFlag} }
    sub showNotesFlag
        { $_[0]->{showNotesFlag} }
    sub explainGetLostFlag
        { $_[0]->{explainGetLostFlag} }
    sub disableUpdateModeFlag
        { $_[0]->{disableUpdateModeFlag} }
    sub updateExitTagFlag
        { $_[0]->{updateExitTagFlag} }
    sub drawRoomEchoFlag
        { $_[0]->{drawRoomEchoFlag} }
    sub allowTrackAloneFlag
        { $_[0]->{allowTrackAloneFlag} }
    sub showAllPrimaryFlag
        { $_[0]->{showAllPrimaryFlag} }
    sub allowCtrlCopyFlag
        { $_[0]->{allowCtrlCopyFlag} }

    sub autoCompareMode
        { $_[0]->{autoCompareMode} }
    sub autoCompareAllFlag
        { $_[0]->{autoCompareAllFlag} }
    sub autoCompareMax
        { $_[0]->{autoCompareMax} }
    sub autoSlideMode
        { $_[0]->{autoSlideMode} }
    sub autoSlideMax
        { $_[0]->{autoSlideMax} }
    sub autoRescueFlag
        { $_[0]->{autoRescueFlag} }
    sub autoRescueFirstFlag
        { $_[0]->{autoRescueFirstFlag} }
    sub autoRescuePromptFlag
        { $_[0]->{autoRescuePromptFlag} }
    sub autoRescueNoMoveFlag
        { $_[0]->{autoRescueNoMoveFlag} }
    sub autoRescueVisitsFlag
        { $_[0]->{autoRescueVisitsFlag} }
    sub autoRescueForceFlag
        { $_[0]->{autoRescueForceFlag} }

    sub lastFilePath
        { $_[0]->{lastFilePath} }
    sub lastVirtualAreaPath
        { $_[0]->{lastVirtualAreaPath} }
    sub trackPosnFlag
        { $_[0]->{trackPosnFlag} }
    sub trackingSensitivity
        { $_[0]->{trackingSensitivity} }
    sub avoidHazardsFlag
        { $_[0]->{avoidHazardsFlag} }
    sub postProcessingFlag
        { $_[0]->{postProcessingFlag} }
    sub quickPathFindFlag
        { $_[0]->{quickPathFindFlag} }
    sub autocompleteExitsFlag
        { $_[0]->{autocompleteExitsFlag} }
    sub collectCheckedDirsFlag
        { $_[0]->{collectCheckedDirsFlag} }
    sub drawCheckedDirsFlag
        { $_[0]->{drawCheckedDirsFlag} }
    sub checkableDirMode
        { $_[0]->{checkableDirMode} }

    sub adjacentMode
        { $_[0]->{adjacentMode} }
    sub adjacentCount
        { $_[0]->{adjacentCount} }
    sub updateBoundaryHash
        { my $self = shift; return %{$self->{updateBoundaryHash}}; }
    sub deleteBoundaryHash
        { my $self = shift; return %{$self->{deleteBoundaryHash}}; }
    sub updatePathHash
        { my $self = shift; return %{$self->{updatePathHash}}; }
    sub updateDelayFlag
        { $_[0]->{updateDelayFlag} }
    sub checkLevelsHash
        { my $self = shift; return %{$self->{checkLevelsHash}}; }

    sub mudlibPath
        { $_[0]->{mudlibPath} }
    sub mudlibExtension
        { $_[0]->{mudlibExtension} }

    sub painterObj
        { $_[0]->{painterObj} }
    sub constPainterIVList
        { my $self = shift; return @{$self->{constPainterIVList}}; }
    sub paintAllRoomsFlag
        { $_[0]->{paintAllRoomsFlag} }
    sub quickPaintMultiFlag
        { $_[0]->{quickPaintMultiFlag} }

    sub searchMaxMatches
        { $_[0]->{searchMaxMatches} }
    sub searchMaxObjects
        { $_[0]->{searchMaxObjects} }
    sub searchSelectRoomsFlag
        { $_[0]->{searchSelectRoomsFlag} }
    sub locateMaxObjects
        { $_[0]->{locateMaxObjects} }
    sub locateRandomInRegionFlag
        { $_[0]->{locateRandomInRegionFlag} }
    sub locateRandomAnywhereFlag
        { $_[0]->{locateRandomAnywhereFlag} }

    sub pathFindStepLimit
        { $_[0]->{pathFindStepLimit} }

    sub drawPauseNum
        { $_[0]->{drawPauseNum} }
    sub recalculatePauseNum
        { $_[0]->{recalculatePauseNum} }

    sub mapFont
        { $_[0]->{mapFont} }
    sub roomTagRatio
        { $_[0]->{roomTagRatio} }
    sub roomGuildRatio
        { $_[0]->{roomGuildRatio} }
    sub exitTagRatio
        { $_[0]->{exitTagRatio} }
    sub labelRatio
        { $_[0]->{labelRatio} }
    sub roomTextRatio
        { $_[0]->{roomTextRatio} }

    sub blockUnselectFlag
        { $_[0]->{blockUnselectFlag} }
}

# Package must return a true value
1
