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
# Games::Axmud::Obj::WorldModel
# Handles the world model

{ package Games::Axmud::Obj::WorldModel;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->setupProfiles
        # Create a new instance of the (main) world model object
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
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

            # An additional hash for character model objects. Contains exactly the same number
            #   of entries as $self->charModelHash, but this hash is in the form
            #   $knownCharHash{name} = blessed_reference_to_character_model_object
            # Used to make sure that character model objects don't have duplicate names (i.e. you
            #   can't have two character objects whose ->name is 'Gandalf')
            knownCharHash               => {},
            # A collection of 'minion strings', where several minion strings (e.g. 'hairy orc',
            #   'hairy orcs', 'Glob the orc') may represent the same minion model object.
            # Unlike $self->minionModelHash, this hash can only contain one key-value pair for each
            #   possible minion string. Also, the value may be a model object or a non-model object;
            #   in either case, it's possible to compare the object against other model/non-model
            #   objects, to see if they match.
            # Minion strings are case-insensitive.
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
            #   are called room tags. The maximum size is 16 characters.
            # Room tags are unique - a room tag called 'tower' can either belong to no room at all,
            #   or a single room. However, room tags are case-insensitive - you can refer to a
            #   room's tag as 'tower', 'TOWER' or 'tOwEr', if you like
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

            # Default colours - used to reset colours to defaults
            defaultBackgroundColour     => '#FFFF99',   # Cream - map displayed
            defaultNoBackgroundColour   => '#FFFFFF',   # White - no map
            defaultRoomColour           => '#FFFFFF',   # White - room
            defaultRoomTextColour       => '#000000',   # Black - text inside room
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
            defaultDragExitColour       => '#FF0000',   # Red - draggable exit
            defaultExitTagColour        => '#000000',   # Black - exit tag
            defaultSelectExitTagColour  => '#0088FF',   # Blue - selected exit tag
            defaultMapLabelColour       => '#C90640',   # Dark red - map label
            defaultSelectMapLabelColour => '#0088FF',   # Blue - selected label

            # Current colours
            backgroundColour            => undef,       # Set below
            noBackgroundColour          => undef,       # Set below
            roomColour                  => undef,
            roomTextColour              => undef,
            borderColour                => undef,
            currentBorderColour         => undef,
            currentFollowBorderColour   => undef,
            currentWaitBorderColour     => undef,
            currentSelectBorderColour   => undef,
            lostBorderColour            => undef,
            lostSelectBorderColour      => undef,
            ghostBorderColour           => undef,
            ghostSelectBorderColour     => undef,
            selectBorderColour          => undef,
            roomAboveColour             => undef,
            roomBelowColour             => undef,
            roomTagColour               => undef,
            selectRoomTagColour         => undef,
            roomGuildColour             => undef,
            selectRoomGuildColour       => undef,
            exitColour                  => undef,
            selectExitColour            => undef,
            selectExitTwinColour        => undef,
            selectExitShadowColour      => undef,
            randomExitColour            => undef,
            impassableExitColour        => undef,
            dragExitColour              => undef,
            exitTagColour               => undef,
            selectExitTagColour         => undef,
            mapLabelColour              => undef,
            selectMapLabelColour        => undef,

            # Room flags - a collection of flags used by room model object
            # If any of the keys listed below exist in room model object's ->roomFlagHash, we use
            #   the colours and short labels defined by this object to draw the room
            # The list/hash IVs below are initialised using GA::Client->constRoomFilterList and
            #   GA::Client->constRoomFlagList
            # NB Changing the contents of the list/hash IVs below will automatically update features
            #   in the automapper window (GA::Win::Map)
            #
            # MARKERS
            #   blocked_room
            #               - Set if this room shouldn't be available to pathfinding functions (or
            #                   similar code)
            #   interesting - Set if this room is marked as interesting
            #   investigate - Set if this room is marked as worth coming back later to investigate
            #   unexplored
            #               - Set if this room hasn't been visited yet
            #   unspecified - Set if this room has an 'unspecified' room statement
            #   avoid_room  - Set if this room is marked as worth avoiding
            #   mortal_danger
            #               - Set if entering this room will probably get the character killed
            #   danger      - Set if entering this room is dangerous
            #   dummy_room  - Set if this room is not actually accessible
            #   rent_room   - Set if this room is where the character can rent (store stuff)
            #   camp_room   - Set if this room is where the character can camp
            #   stash_room  - Set if this room is where you like to leave things temporarily
            #   hide_room   - Set if this room is where you like to hide
            #   random_room - Set if this room is randomly-generated
            #   immortal_room
            #               - Set if this room is only accessible to administrative users
            #
            # NAVIGATION
            #   world_centre
            #               - Set if this room has been designated the centre of the world
            #   world_start
            #               - Set if this room is the room where new players start
            #   meet_point  - Set if this room has been designated as a meeting point (usually a
            #                   room in the world at the centre of a town, near shops)
            #   main_route  - Set if this is a main route
            #   minor_route - Set if this is a minor route
            #   cross_route - Set if this is where two or more routes meet
            #   arrow_route - Set if this room leads in the right direction
            #   wrong_route - Set if this room leads in the wrong direction
            #   portal      - Set if this room contains some kind of portal
            #   sign_post   - Set if this room contains a signpost
            #   moving_boat - Set if this room is on a (moving) boat
            #   vehicle     - Set if this room is on a (moving) vehicle
            #   fixed_boat  - Set if this room is on a (stationary) boat
            #   swim_room   - Set if this room is in water, so the character needs to swim
            #   fly_room    - Set if this room is in the air, so the character needs to fly
            #
            # COMMERCIAL
            #   shop_general
            #               - Set if this room is a general store
            #   shop_weapon - Set if this room is a weapon shop
            #   shop_armour - Set if this room is an armour shop
            #   shop_clothes
            #               - Set if this room is a clothes shop
            #   shop_special
            #               - Set if this room is some other kind of shop
            #   shop_empty  - Set if this room is an empty shop
            #   smithy      - Set if this room is a smithy
            #   bank        - Set if this room is a bank
            #   pub         - Set if this room is some kind of pub
            #   restaurant  - Set if this room is some kind of restaurant (where the character can
            #                   eat)
            #   takeaway    - Set if this room is some kind of takeaway (where the character can buy
            #                   food to carry)
            #   auction     - Set if this room is an auction house
            #   post_office - Set if this room is a post office
            #
            # BUILDINGS
            #   library     - Set if this room is where books, parchments, signs, notice boards and
            #                   so on are available
            #   theatre     - Set if this room is a theatre or performance venue
            #   temple      - Set if this room is some kind of temple or shrine
            #   church      - Set if this room is a church or cathedral
            #   hotel       - Set if this room is a hotel
            #   storage     - Set if this room is somewhere you can store things
            #   office      - Set if this room is an office
            #   jail        - Set if this room is a jail or dungeon
            #   hospital    - Set if this room is some kind of hospital
            #   stable      - Set if this room is a room where animals are stored
            #   tent        - Set if this room is inside a tent
            #   house       - Set if this room is an ordinary house or home
            #   ord_building
            #               - Set if this room is an ordinary building
            #   bulletin_board
            #               - Set if this room contains some kind of bulleting board
            #
            # STRUCTURES
            #   building    - Set if this is any kind of building
            #   gate        - Set if this is at (or outside) a city gate
            #   wall        - Set if this is on (or alongside) a city wall
            #   tower       - Set if this is on (or inside) a tower
            #   staircase   - Set if this is on a staircase
            #   tunnel      - Set if this is in a tunnel
            #   bridge      - Set if this is a on a bridge
            #   fountain    - Set if this room has a fountain
            #   well        - Set if this is a well or water source
            #   farm        - Set if this is a farm
            #   field       - Set if this is a field
            #   park        - Set if this is a park/garden
            #   graveyard   - Set if this is a graveyard
            #   port        - Set if this is a port/harbour/jetty
            #   maze        - Set if this is a maze
            #
            # TERRAIN
            #   forest      - Set if this is a forest/wood
            #   clearing    - Set if this is a clearing
            #   grassland   - Set if this is a grassland/plain
            #   swamp       - Set if this is a swamp/marsh
            #   desert      - Set if this is a desert
            #   beach       - Set if this is a beach/coast
            #   river       - Set if this is a river/stream
            #   lake        - Set if this is a lake
            #   sea         - Set if this is a sea/ocean
            #   cave        - Set if this is a cave
            #   mountain    - Set if this is a mountainous area
            #   rocky       - Set if this is rocky landscape
            #   icy         - Set if this is icy landscape
            #   hill        - Set if this is a hill
            #   pit         - Set if this is next to (or inside) a pit or hole
            #
            # OBJECTS
            #   weapon      - Set if the room contains a weapon
            #   armour      - Set if the room contains an armour
            #   garment     - Set if the room contains a garment
            #   major_npc
            #               - Set if the room contains an important NPC
            #   talk_npc    - Set if the room contains a talking NPC
            #   npc         - Set if the room contains any NPC
            #   portable    - Set if the room contains a portable object
            #   decoration  - Set if the room contains a decoration object
            #   money       - Set if the room contains money
            #   treasure    - Set if the room contains a valuable object
            #   collectable - Set if the room contains a collectable object
            #
            # LIGHT
            #   outside     - Set if this room is outside
            #   inside      - Set if this room is inside
            #   overground  - Set if this room is above ground
            #   underground - Set if this room is underground
            #   torch       - Set if average player needs a torch in this room
            #   always_dark - Set if this room is always dark
            #
            # GUILDS
            #   guild_entrance
            #               - Set if this room is an entrance to a guild (possibly guarded)
            #   guild_main  - Set if this is a room inside the guild where a character can advance
            #                   skills and/or join the guild
            #   guild_practice
            #               - Set if this room is where a character can practice guild skills
            #   guild_shop  - Set if this is a room inside the guild where a character can buy
            #                   guild-specific items
            #   guild_other - Set if this is a room inside the guild where a character can't advance
            #                   skills or buy guild-specific items
            #
            # QUESTS
            #   quest_room  - Set if this room is important in a quest
            #   quest_begin - Set if this room is the start of a quest
            #   quest_end   - Set if this room is the end of a quest
            #
            # ATTACKS
            #   peaceful    - Set if the world doesn't allow fights in this room
            #   recovery    - Set if this room lets the character recover from fights more quickly
            #
            #   char_dead   - Set if any character has ever died in this room
            #   char_pass_out
            #               - Set if any character has ever been knocked out in this room
            #
            # Default IVs set up from the constant GA::Client IVs
            # A list of room filters, in the standard order
            defaultRoomFilterList       => [],          # Set by $self->setupRoomFlags
            # Whether each filter is released, or not
            #   e.g. $hash{'markers'} = TRUE            # -> 'markers' filter released
            #   e.g. $hash{'terrain'} = FALSE           # -> 'terrain' filter applied
            defaultRoomFilterHash       => {},
            # Which room flag text to display in the room's interior
            #   e.g. $hash{'stash_room'} = 'St',
            defaultRoomFlagTextHash     => {},
            # Which room colour takes priority - the lower the value, the higher the priority its
            #   its matching key takes
            #   e.g. $hash{'stash_room'} = 11,
            defaultRoomFlagPriorityHash => {},
            # Which flag belongs to which filter
            #   e.g. $hash{'stash_room'} = 'markers'
            defaultRoomFlagFilterHash   => {},
            # What colour the room should be drawn
            #   e.g. $hash{'stash_room'} = '#CEAAAD'
            defaultRoomFlagColourHash   => {},
            # How each flag is described in the menu
            #   e.g. $hash{'stash_room'} = 'Room for stashing things'
            defaultRoomFlagDescripHash  => {},
            # A list of keys from the hashes above, in a standard order
            #   e.g. ['stash_room', 'hide_room', 'interesting', ...]
            defaultRoomFlagOrderedList  => [],
            # A hash showing which filters apply to which flags. The key is a room filter; the value
            #   is a reference to a list containing all the flags matching the filter
            #   e.g. $hash{'markers'} = ['stash_room', 'hide_room', 'interesting', 'investigate'..]
            defaultRoomFlagReverseHash  => {},

            # IVs initially copied from the default IVs above
            roomFilterList              => [],      # Set below
            roomFilterHash              => {},
            roomFlagTextHash            => {},
            roomFlagPriorityHash        => {},
            roomFlagFilterHash          => {},
            roomFlagColourHash          => {},
            roomFlagDescripHash         => {},
            roomFlagOrderedList         => [],
            roomFlagReverseHash         => {},
            # A single flag which, when set to TRUE, releases all filters, overriding the contents
            #   of ->roomFilterHash (set to FALSE otherwise)
            allRoomFiltersFlag          => TRUE,

            # MSDP can supply a 'TERRAIN' variable for each room. If so, those variables are
            #   collected initially in this hash, in the form
            #       $roomTerrainInitHash{terrain_type} = undef
            roomTerrainInitHash         => {},
            # The user can then allocate a terrain to one of Axmud's room flags (in which case new
            #   rooms have their room flags set automatically, as if the painter was on), or choose
            #   to ignore the terrain type. Hash of allocated terrain types, in the form
            #       $roomTerrainHash{terrain_type} = room_flag
            #       $roomTerrainHash{terrain_type} = undef (to ignore the terrain type)
            roomTerrainHash             => {},

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
            #   'room_content' - Draw room contents
            #   'hidden_count' - Draw hidden objects counts
            #   'temp_count' - Draw temporary contents counts
            #   'word_count' - Draw recognised word counts
            #   'room_flag' - Draw room flag text (which matches the room's highest priority room
            #       flag)
            #   'visit_count' - Draw # of character visits
            #   'profile_count' - Draw room's exclusive profiles
            #   'title_descrip' - Draw room titles/verbose descriptions
            #   'exit_pattern' - Draw assisted moves/exit patterns
            #   'source_code' - Draw source code path
            #   'vnum' - Draw world's room vnum
            roomInteriorMode            => 'none',

            # How exits are drawn
            #   'ask_regionmap' - Let each individual regionmap decide (between no exits, simple
            #       exits and complex exits)
            #   'no_exit' - Draw no exits (only the rooms themselves are drawn)
            #   'simple_exit' - Draw simple exits (all exists are simple lines, with arrows for
            #       one-way exits)
            #   'complex_exit' - Draw complex exits (there are four kinds of exits drawn -
            #       incomplete, uncertain, one-way and two-way)
            drawExitMode                => 'ask_regionmap',
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
            #   profile's ->basicMappingMode is not 0 (meaning, don't use basic mapping)
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
            #   instead; set to FALSE otherwise). Ignore when assisted moves are not turned on
            protectedMovesFlag          => FALSE,
            # Flag set to TRUE if super protected moves turned on; after the first warning message,
            #   all unprocessed commands are removed, so (for example) in 'north;get torch', if
            #   the 'north' command fails, 'get torch' is never processed. Ignored if
            #   ->proctedMovesFlag is FALSE
            superProtectedMovesFlag     => FALSE,

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
            # Flag set to TRUE if the automapper, when about to create a new room, should
            #   automatically check it against other rooms in the region - and produce a warning if
            #   it finds a match (set to FALSE otherwise)
            autoCompareFlag             => FALSE,
            # Flag set to TRUE if the automapper should create a new exit object when the character
            #   moves, and the move is detected by the Locator task using a 'follow anchor' pattern.
            #   If FALSE, the automapper becomes lost, instead
            followAnchorFlag            => FALSE,
            # Flag set to TRUE if room tags should be displayed in capitals (set to FALSE otherwise)
            capitalisedRoomTagFlag      => TRUE,
            # Flag set to TRUE if tooltips should be visible (set to FALSE otherwise)
            showTooltipsFlag            => TRUE,
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
            # NB If basic mapping mode (GA::Profile::World->basicMappingMode) is on, travelling from
            #   one room to a new room normally creates a one-way exit. When the user prefers to
            #   create two-way exits instead, they can set this flag to TRUE
            autocompleteExitsFlag       => FALSE,

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
            # When rooms are added to or deleted from a regionmap, we need to re-calculate the
            #   regionmap's highest and lowest occupied levels. This hash contains all the
            #   regionmaps that need to be checked. Hash in the form
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
            painterIVList               => [
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

        # Set current colours (so the literal values above only need appear once)
        $self->{backgroundColour}       = $self->{defaultBackgroundColour};
        $self->{noBackgroundColour}     = $self->{defaultNoBackgroundColour};
        $self->{roomColour}             = $self->{defaultRoomColour};
        $self->{roomTextColour}         = $self->{defaultRoomTextColour};
        $self->{borderColour}           = $self->{defaultBorderColour};
        $self->{currentBorderColour}    = $self->{defaultCurrentBorderColour};
        $self->{currentFollowBorderColour}
                                        = $self->{defaultCurrentFollowBorderColour};
        $self->{currentWaitBorderColour}
                                        = $self->{defaultCurrentWaitBorderColour};
        $self->{currentSelectBorderColour}
                                        = $self->{defaultCurrentSelectBorderColour};
        $self->{lostBorderColour}       = $self->{defaultLostBorderColour};
        $self->{lostSelectBorderColour} = $self->{defaultLostSelectBorderColour};
        $self->{ghostBorderColour}      = $self->{defaultGhostBorderColour};
        $self->{ghostSelectBorderColour}
                                        = $self->{defaultGhostSelectBorderColour};
        $self->{selectBorderColour}     = $self->{defaultSelectBorderColour};
        $self->{roomAboveColour}        = $self->{defaultRoomAboveColour};
        $self->{roomBelowColour}        = $self->{defaultRoomBelowColour};
        $self->{roomTagColour}          = $self->{defaultRoomTagColour};
        $self->{selectRoomTagColour}    = $self->{defaultSelectRoomTagColour};
        $self->{roomGuildColour}        = $self->{defaultRoomGuildColour};
        $self->{selectRoomGuildColour}  = $self->{defaultSelectRoomGuildColour};
        $self->{exitColour}             = $self->{defaultExitColour};
        $self->{selectExitColour}       = $self->{defaultSelectExitColour};
        $self->{selectExitTwinColour}   = $self->{defaultSelectExitTwinColour};
        $self->{selectExitShadowColour} = $self->{defaultSelectExitShadowColour};
        $self->{randomExitColour}       = $self->{defaultRandomExitColour};
        $self->{impassableExitColour}   = $self->{defaultImpassableExitColour};
        $self->{dragExitColour}         = $self->{defaultDragExitColour};
        $self->{exitTagColour}          = $self->{defaultExitTagColour};
        $self->{selectExitTagColour}    = $self->{defaultSelectExitTagColour};
        $self->{mapLabelColour}         = $self->{defaultMapLabelColour};
        $self->{selectMapLabelColour}   = $self->{defaultSelectMapLabelColour};

        # Set room flags and room filters
        $self->setupRoomFlags();

        $self->{roomFilterList}         = $self->{defaultRoomFilterList};
        $self->{roomFilterHash}         = $self->{defaultRoomFilterHash};
        $self->{roomFlagTextHash}       = $self->{defaultRoomFlagTextHash};
        $self->{roomFlagPriorityHash}   = $self->{defaultRoomFlagPriorityHash};
        $self->{roomFlagFilterHash}     = $self->{defaultRoomFlagFilterHash};
        $self->{roomFlagColourHash}     = $self->{defaultRoomFlagColourHash};
        $self->{roomFlagDescripHash}    = $self->{defaultRoomFlagDescripHash};
        $self->{roomFlagOrderedList}    = $self->{defaultRoomFlagOrderedList};
        $self->{roomFlagReverseHash}    = $self->{defaultRoomFlagReverseHash};

        # Create a painter object - a non-model GA::ModelObj::Room used to 'paint' other rooms
        #   by copying its IVs into theirs
        $self->resetPainter($session);

        return $self;
    }

    ##################
    # Methods

    # Methods called by ->new

    sub setupRoomFlags {

        # Called by $self->new to set the contents of several default IVs for room flags
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
            $priority,
            @filterList, @flagList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupRoomFlags', @_);
        }

        # Import the two compounds IVs, which we use to setup the remaining default IVs
        @filterList = $axmud::CLIENT->constRoomFilterList;
        @flagList = $axmud::CLIENT->constRoomFlagList;

        # Set up the default room filter IVs
        do {

            my $filter = shift @filterList;
            my $setting = shift @filterList;

            $self->ivPush('defaultRoomFilterList', $filter);
            $self->ivAdd('defaultRoomFilterHash', $filter, $setting);

        } until (! @filterList);

        # Set up the default room flag IVs
        $priority = 0;
        do {

            my (
                $flag, $short, $filter, $colour, $descrip, $miniListRef,
                @miniList,
            );

            $flag = shift @flagList;
            $short = shift @flagList;
            $filter = shift @flagList;
            $colour = shift @flagList;
            $descrip = shift @flagList;

            $self->ivAdd('defaultRoomFlagTextHash', $flag, $short);
            $priority++;
            $self->ivAdd('defaultRoomFlagPriorityHash', $flag, $priority);
            $self->ivAdd('defaultRoomFlagFilterHash', $flag, $filter);
            $self->ivAdd('defaultRoomFlagColourHash', $flag, $colour);
            $self->ivAdd('defaultRoomFlagDescripHash', $flag, $descrip);
            $self->ivPush('defaultRoomFlagOrderedList', $flag);

            if ($self->ivExists('defaultRoomFlagReverseHash', $filter)) {

                $miniListRef = $self->ivShow('defaultRoomFlagReverseHash', $filter);
                push (@$miniListRef, $flag);
                $self->ivAdd('defaultRoomFlagReverseHash', $filter, $miniListRef);

            } else {

                push (@miniList, $flag);
                $self->ivAdd('defaultRoomFlagReverseHash', $filter, \@miniList);
            }

        } until (! @flagList);

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
        my $tempObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRoomFlags', @_);
        }

        # Create a temporary GA::Obj::WorldModel object
        $tempObj = Games::Axmud::Obj::WorldModel->new($session);

        # Copy all room flag IVs from the temporary object to this one
        $self->ivPoke('defaultRoomFilterList', $tempObj->defaultRoomFilterList);
        $self->ivPoke('defaultRoomFilterHash', $tempObj->defaultRoomFilterHash);
        $self->ivPoke('defaultRoomFlagTextHash', $tempObj->defaultRoomFlagTextHash);
        $self->ivPoke('defaultRoomFlagPriorityHash', $tempObj->defaultRoomFlagPriorityHash);
        $self->ivPoke('defaultRoomFlagFilterHash', $tempObj->defaultRoomFlagFilterHash);
        $self->ivPoke('defaultRoomFlagColourHash', $tempObj->defaultRoomFlagColourHash);
        $self->ivPoke('defaultRoomFlagDescripHash', $tempObj->defaultRoomFlagDescripHash);
        $self->ivPoke('defaultRoomFlagOrderedList', $tempObj->defaultRoomFlagOrderedList);
        $self->ivPoke('defaultRoomFlagReverseHash', $tempObj->defaultRoomFlagReverseHash);

        $self->ivPoke('roomFilterList', $tempObj->roomFilterList);
        $self->ivPoke('roomFilterHash', $tempObj->roomFilterHash);
        $self->ivPoke('roomFlagTextHash', $tempObj->roomFlagTextHash);
        $self->ivPoke('roomFlagPriorityHash', $tempObj->roomFlagPriorityHash);
        $self->ivPoke('roomFlagFilterHash', $tempObj->roomFlagFilterHash);
        $self->ivPoke('roomFlagDescripHash', $tempObj->roomFlagDescripHash);
        $self->ivPoke('roomFlagOrderedList', $tempObj->roomFlagOrderedList);
        $self->ivPoke('roomFlagReverseHash', $tempObj->roomFlagReverseHash);
        $self->ivPoke('allRoomFiltersFlag', $tempObj->allRoomFiltersFlag);

        # The user may have made their own modifications to ->roomFlagColourHash. Keep the original
        #   hash, but make sure any new room flags have been added, and that any old ones are
        #   removed
        foreach my $roomFlag ($tempObj->ivKeys('roomFlagColourHash')) {

            my $colour = $tempObj->ivShow('roomFlagColourHash', $roomFlag);

            if (! $self->ivExists('roomFlagColourHash', $roomFlag)) {

                # It's a new room flag
                $self->ivAdd('roomFlagColourHash', $roomFlag, $colour);
            }
        }

        foreach my $roomFlag ($self->ivKeys('roomFlagColourHash')) {

            if (! $tempObj->ivExists('roomFlagColourHash', $roomFlag)) {

                # It's an old room flag, which should be removed
                $self->ivDelete('roomFlagColourHash', $roomFlag);
            }
        }

        # Operation complete
        return 1;
    }

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
        $roomObj = Games::Axmud::ModelObj::Room->new($session, 'world model painter', FALSE);
        if ($roomObj) {

            $self->ivPoke('painterObj', $roomObj);
            return $roomObj;

        } else {

            $self->ivUndef('painterObj');
            return undef;
        }
    }

    # Methods called by GA::Session->spinMaintainLoop

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

                CENTRE: foreach my $exitString ($regionmapObj->ivKeys('regionPathHash')) {

                    my $pathObj = $regionmapObj->ivShow('regionPathHash', $exitString);

                    INNER: foreach my $exitNum ($pathObj->exitList) {

                        if (exists $otherHash{$exitNum}) {

                            # Replace the path
                            $self->replaceRegionPath($session, $pathObj, $regionmapObj, FALSE);

                            last INNER;
                        }
                    }
                }

                CENTRE: foreach my $exitString ($regionmapObj->ivKeys('safeRegionPathHash')) {

                    my $pathObj = $regionmapObj->ivShow('safeRegionPathHash', $exitString);

                    INNER: foreach my $exitNum ($pathObj->exitList) {

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
            if ($exitObj->impassFlag) {

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
            $safeFlag,
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
        # When a model room is added, moved or deleted, the parent regionmap's name is temporarily
        #   stored in $self->checkLevelsHash
        # Ask each regionmap to re-calculate its highest and lowest occupied levels
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRegionLevels', @_);
        }

        foreach my $regionName ($self->ivKeys('checkLevelsHash')) {

            my ($regionmapObj, $high, $low);

            $regionmapObj = $self->ivShow('regionmapHash', $regionName);

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

            # If there are no rooms in the regionmap, $high and $low will be 'undef' which is, in
            #   that situation, also the correct value for the IVs
            $regionmapObj->ivPoke('highestLevel', $high);
            $regionmapObj->ivPoke('lowestLevel', $low);
        }

        # Update any GA::Win::Map objects using this world model
        foreach my $mapWin ($self->collectMapWins()) {

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

    # Other region path methods

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
        #   $name           - A name for the new region (if more than 32 characters, it is
        #                       shortened)
        # Optional arguments
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
        my ($regionObj, $regionmapObj);

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRegion', @_);
        }

        # If $name is an empty string, we can't add it as a region
        if (! $name) {

            return undef;
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
        # Inform the region object and the regionmap object of each other's existence
        $regionmapObj->ivPoke('number', $regionObj->number);
        $regionObj->ivPoke('regionmapObj', $regionmapObj);

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

        # Called by GA::Win::Map->createNewRoom or by any other function
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
        $roomObj = Games::Axmud::ModelObj::Room->new($session, $name, TRUE, $regionmapObj->number);
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

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap eq $regionmapObj
                    && $mapWin->currentRegionmap->currentLevel == $zPosBlocks
                ) {
                    # ...mark the room to be drawn
                    $mapWin->markObjs('room', $roomObj);
                }

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
        #       - When the calling function was in turn called by GA::Win::Map->createNewRoom, the
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
            $taskObj, $taskRoomObj, $name, $terrain,
            @list,
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
            @list = $modelRoomObj->titleList;
            if (! @list) {

                # The model room's title list is empty, so simply copy the Locator room's title list
                #   across (even if it, too, is empty)
                $modelRoomObj->ivPoke('titleList', $taskRoomObj->titleList)

            } else {

                OUTER: foreach my $taskTitle ($taskRoomObj->titleList) {

                    foreach my $modelTitle (@list) {

                        if ($taskTitle eq $modelTitle) {

                            # The model room already has this room title
                            next OUTER;
                        }
                    }

                    # The model room doesn't already have this room title
                    push (@list, $taskTitle);
                }

                # Store the combined list of brief descriptions
                $modelRoomObj->ivPoke('titleList', @list);
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
        if ($self->updateExitFlag) {

            # An exit's nominal direction is the one we'd expect to find in a room statement
            #   (e.g. 'Obvious exits are: east, south, north') and are stored in the exit object's
            #   ->dir
            # Room objects save their exits in two IVs: a hash in the form...
            #   ->exitNumHash{nominal_direction} = number_in_exit_model
            # ...and a list, with the nominal directions sorted in a standard order
            # Any nominal directions in the Locator room's hash which don't exist in the map's
            #   hash are added to the world model as new exits. Any that already exist are updated
            foreach my $exitObj ($taskRoomObj->ivValues('exitNumHash')) {

                $self->updateExit(
                    $session,
                    FALSE,       # Don't update Automapper windows now
                    $modelRoomObj,
                    $taskRoomObj,
                    $exitObj,
                );
            }

            # Now, check the model room's list of exit objects, looking for those which don't yet
            #   have a map direction (->mapDir) set (which will be the case for any new exits we've
            #   just created in non-primary directions)
            # Allocate them one of the sixteen cardinal directions that are not already in use. If
            #   all sixteen cardinal directions are in use, the exit object's ->mapDir remains set
            #   to 'undef' (and isn't explicity drawn in the map)
            # (When this function is called by GA::Obj::Map->updateRoom which was, in turn, called
            #   by $self->createNewRoom when moving from an existing departure room to a new arrival
            #   room, we pass information about the departure room to the function so that, if we
            #   moved using an allocated exit, any unallocated exits in the arrival room can be
            #   drawn in the opposite direction)
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

                    $modelRoomObj->ivAdd(
                        'roomFlagHash',
                        $self->ivShow('roomTerrainHash', $terrain),
                    );
                }
            }
        }

        # Update room commands
        if ($self->updateRoomCmdFlag) {

            $modelRoomObj->ivPoke('roomCmdList', $taskRoomObj->roomCmdList);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Compile a list of rooms to be marked for drawing (if $connectRoomObj is not on the
            #   visible region level, it won't get drawn, so there's no danger in marking it to be
            #   drawn here)
            @list = ('room', $modelRoomObj);
            if ($connectRoomObj) {

                push (@list, 'room', $connectRoomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $modelRoomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $modelRoomObj->zPosBlocks
                ) {
                    # ...mark the room(s) to be drawn
                    $mapWin->markObjs(@list);
                }
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

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $roomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                ) {
                    # ...mark the room to be drawn
                    $mapWin->markObjs('room', $roomObj);
                }
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
            TRUE,
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
                $standardDir = $dictObj->checkStandardDir($dir);
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

        # Set the exit type (e.g. 'primaryDir', 'primaryAbbrev', etc)
        $exitObj->ivPoke(
            'exitType',
            $session->currentDict->ivShow('combDirHash', $exitObj->dir),
        );

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap eq $roomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                ) {
                    # ...mark the exit to be drawn
                    $mapWin->markObjs('exit', $exitObj);
                }
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
        # Return values
        #   'undef' on improper arguments or if the function tries and fails to create a new exit
        #   Otherwise, returns the model number of the newly-added exit object

        my ($self, $session, $updateFlag, $modelRoomObj, $taskRoomObj, $taskExitObj, $check) = @_;

        # Local variables
        my ($modelExitNum, $modelExitObj, $standardDir, $regionObj);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $updateFlag || ! defined $modelRoomObj
            || ! defined $taskRoomObj || ! defined $taskExitObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateExit', @_);
        }

        # Does the world model room object already have an exit in this direction?
        if (! $modelRoomObj->ivExists('exitNumHash', $taskExitObj->dir)) {

            # It doesn't, so add a new one
            $modelExitObj = $self->addExit(
                $session,
                FALSE,              # Don't update Automapper windows now
                $modelRoomObj,
                $taskExitObj->dir,
            );

            if (! $modelExitObj) {

                # Nothing more we can do
                return undef;
            }


            # Decide how to draw the exit on the map. Is its direction a recognised custom primary
            #   direction?
            $standardDir = $session->currentDict->checkStandardDir($modelExitObj->dir);
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
            $modelExitNum = $modelRoomObj->ivShow('exitNumHash', $taskExitObj->dir);
            $modelExitObj = $self->ivShow('exitModelHash', $modelExitNum);

            # Any region paths using the existing exit will have to be updated
            $regionObj = $self->ivShow('modelHash', $modelRoomObj->parent);
            $self->ivAdd('updatePathHash', $modelExitObj->number, $regionObj->name);
            if ($modelExitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $modelExitObj->number, $regionObj->name);
            }
        }

        # Update the model exit with the non-model exit's flags (specifically: if the non-model
        #   exit has its flag set to TRUE, then so must the model exit)
        if ($taskExitObj->breakFlag) {

            $modelExitObj->ivPoke('breakFlag', TRUE);
        }

        if ($taskExitObj->pickFlag) {

            $modelExitObj->ivPoke('pickFlag', TRUE);
        }

        if ($taskExitObj->lockFlag) {

            $modelExitObj->ivPoke('lockFlag', TRUE);
        }

        if ($taskExitObj->openFlag) {

            $modelExitObj->ivPoke('openFlag', TRUE);
        }

        if ($taskExitObj->impassFlag) {

            $modelExitObj->ivPoke('impassFlag', TRUE);
        }

        if ($taskExitObj->ornamentFlag) {

            $modelExitObj->ivPoke('ornamentFlag', TRUE);
        }

        # If the non-model exit has its ->exitState set, we can also use that to update the model
        #   exit's ornaments (if this behavious is allowed by the setting of
        #   $self->updateOrnamentFlag, but don't overrule the existing ornament, if any)
        if (
            ! $modelExitObj->ornamentFlag
            && $self->updateOrnamentFlag
            && $taskExitObj->exitState
        ) {
            if ($taskExitObj->exitState eq 'impass') {

                $modelExitObj->ivPoke('impassFlag', TRUE);
                $modelExitObj->ivPoke('ornamentFlag', TRUE);

            } elsif (
                $taskExitObj->exitState eq 'locked'
                || $taskExitObj->exitState eq 'secret_locked'
            ) {
                $modelExitObj->ivPoke('lockFlag', TRUE);
                $modelExitObj->ivPoke('ornamentFlag', TRUE);

            } elsif (
                $taskExitObj->exitState eq 'open'
                || $taskExitObj->exitState eq 'closed'
                || $taskExitObj->exitState eq 'secret_open'
                || $taskExitObj->exitState eq 'secret_closed'
            ) {
                $modelExitObj->ivPoke('openFlag', TRUE);
                $modelExitObj->ivPoke('ornamentFlag', TRUE);
            }
        }

        # Also set the exit info, if it was collected
        if ($taskExitObj->info) {

            $modelExitObj->ivPoke('info', $taskExitObj->info);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap eq $modelRoomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $modelRoomObj->zPosBlocks
                ) {
                    # ...mark the exit to be drawn
                    $mapWin->markObjs('exit', $modelExitObj);
                }
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
        # Return values
        #   'undef' on improper arguments, if the map coordinates are invalid or if the label can't
        #       be created
        #   Otherwise returns the new GA::Obj::MapLabel created

        my (
            $self, $session, $updateFlag, $regionmapObj, $xPosPixels, $yPosPixels, $level,
            $labelText, $check,
        ) = @_;

        # Local variables
        my $labelObj;

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

        # Create the new map label object
        $labelObj = Games::Axmud::Obj::MapLabel->new(
            $session,
            $labelText,
            $regionmapObj->name,
            $xPosPixels, $yPosPixels, $level,
        );

        if (! $labelObj) {

            return undef;
        }

        # Add the label to the regionmap
        $regionmapObj->storeLabel($labelObj);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap eq $regionmapObj
                    && $mapWin->currentRegionmap->currentLevel == $level
                ) {
                    # ...mark the room to be drawn
                    $mapWin->markObjs('label', $labelObj);
                }
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

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $parentObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $parentObj->zPosBlocks
                ) {
                    # ...mark the (parent)room to be drawn
                    $mapWin->markObjs('room', $parentObj);
                }
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

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $parentObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $parentObj->zPosBlocks
                ) {
                    # ...mark the (parent)room to be drawn
                    $mapWin->markObjs('room', $parentObj);
                }
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

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $parentObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $parentObj->zPosBlocks
                ) {
                    # ...mark the (parent)room to be drawn
                    $mapWin->markObjs('room', $parentObj);
                }
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
            if ($obj->uncertainExitHash) {

                foreach my $uncertainExitNum ($obj->ivKeys('uncertainExitHash')) {

                    my $uncertainExitObj = $self->ivShow('exitModelHash', $uncertainExitNum);

                    if (
                        $uncertainExitObj
                        && $uncertainExitObj->destRoom
                        && $uncertainExitObj->destRoom == $obj->number
                    ) {
                        # (The call to $self->abandonUncertainExit updates $self->updateBoundaryHash
                        #   and ->updatePathHash)
                        $self->abandonUncertainExit(
                            $updateFlag,
                            $uncertainExitObj,
                        );
                    }
                }
            }

            # Do the same for one-way exits which lead to this soon-to-be-deleted room
            if ($obj->oneWayExitHash) {

                foreach my $oneWayExitNum ($obj->ivKeys('oneWayExitHash')) {

                    my $oneWayExitObj = $self->ivShow('exitModelHash', $oneWayExitNum);

                    if (
                        $oneWayExitObj
                        && $oneWayExitObj->destRoom
                        && $oneWayExitObj->destRoom == $obj->number
                    ) {
                        # (The call to $self->abandonOneWayExit updates $self->updateBoundaryHash
                        #   and ->updatePathHash)
                        $self->abandonOneWayExit(
                            $updateFlag,
                            $oneWayExitObj,
                        );
                    }
                }
            }

            # Do the same for random exits which lead to this soon-to-be-deleted room
            if ($obj->randomExitHash) {

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
        # Also deletes the corresponding GA::Obj::Regionmap
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

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteRegions', @_);
        }

        # If @regionList is empty, do nothing
        if (! @regionList) {

            return undef;
        }

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
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                INNER: foreach my $regionObj (@regionList) {

                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $regionObj->number
                    ) {
                        # Show no current region, which deletes all canvas objects
                        $mapWin->setCurrentRegion();
                        last INNER;
                    }
                }

                # After any deletion operation, all selected canvas objects must be un-selected
                $mapWin->setSelectedObj();

                # Update the window's treeview (containing the list of regions)
                $mapWin->resetTreeView();
            }
        }

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

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                INNER: foreach my $regionObj (@regionList) {

                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $regionObj->number
                    ) {
                        # Show no current region, which deletes all canvas objects
                        $mapWin->setCurrentRegion();
                        last INNER;
                    }
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
        my @mapWinList;

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteRooms', @_);
        }

        # If @roomList is empty, do nothing
        if (! @roomList) {

            return undef;
        }

        foreach my $roomObj (@roomList) {

            my ($regionObj, $regionmapObj);

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
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);
            $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);
            $regionmapObj->removeRoom($roomObj);

            # If the room has a room tag, update the hash of room tags
            if ($roomObj->roomTag) {

                $self->ivDelete('roomTagHash', $roomObj->roomTag);
            }

            # Delete the room object and its child objects and exit objects (if any)
            $self->deleteObj(
                $session,
                TRUE,       # Update Automapper windows now - is applied to the room's exits
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

                foreach my $roomObj (@roomList) {

                    # Delete the label's canvas object (if it exists)
                    $mapWin->deleteCanvasObj('room', $roomObj, TRUE);

                    # If the room is on the automapper's region and level, delete the canvas objects
                    #   for the room's room tag and room guild (if any). Its exits will have been
                    #   deleted in the call to ->deleteObj just above
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $roomObj->parent
                        && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                    ) {
                        if ($roomObj->roomTag) {

                            $mapWin->deleteCanvasObj('room_tag', $roomObj, TRUE);
                        }

                        if ($roomObj->roomGuild) {

                            $mapWin->deleteCanvasObj('room_guild', $roomObj, TRUE);
                        }
                    }

                    # Some other function may have placed the room on the automapper's list of
                    #   objects to draw; if so, remove it
                    if ($mapWin->ivExists('markedRoomHash', $roomObj->number)) {

                        $mapWin->del_drawObj('markedRoomHash', $roomObj->number);
                    }

                    # The same applies to room tags and room guilds belonging to this room
                    if ($mapWin->ivExists('markedRoomTagHash', $roomObj->number)) {

                        $mapWin->del_drawObj('markedRoomTagHash', $roomObj->number);
                    }

                    if ($mapWin->ivExists('markedRoomGuildHash', $roomObj->number)) {

                        $mapWin->del_drawObj('markedRoomGuildHash', $roomObj->number);
                    }
                }

                # After any deletion operation, all selected canvas objects must be un-selected
                $mapWin->setSelectedObj();
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

        # Make sure the deleted rooms are not marked to be re-drawn
        foreach my $mapWin ($self->collectMapWins()) {

            foreach my $roomObj (@roomList) {

                $mapWin->del_markedRoom($roomObj->number);
            }
        }

        return 1;
    }

    sub deleteExits {

        # Called by GA::Win::Map->deleteExitCallback, GA::Cmd::DeleteExit->do and $self->deleteObj
        #   $self->deleteObj
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
            %roomHash,
            @redrawList, @mapWinList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $updateFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteExits', @_);
        }

        # If @exitList is empty, do nothing
        if (! @exitList) {

            return undef;
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
                $twinRoomObj =  $self->ivShow('modelHash', $twinExitObj->parent);
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
                # Also update the twin exit's regionmap (if there is one)
                if ($twinRoomObj && $twinExitObj) {

                    $twinRegionObj = $self->ivShow('modelHash', $twinRoomObj->parent);
                    $twinRegionmapObj = $self->ivShow('regionmapHash', $twinRegionObj->name);
                    $twinRegionmapObj->resetExit($twinExitObj);
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

                    # Delete the exit's canvas object (if it exists)
                    $mapWin->deleteCanvasObj('exit', $exitObj, TRUE);
                    # Delete the exit tag's canvas object (which might exist, even if the exit's
                    #   canvas object does not)
                    $mapWin->deleteCanvasObj('exit_tag', $exitObj, TRUE);

                    # (Code reinstated at v1.0.106)
                    # Some other function may have placed the exit and the exit tag (if any) on the
                    #   automapper's list of objects to draw; if so, remove them
                    if ($mapWin->ivExists('markedExitHash', $exitObj->number)) {

                        $mapWin->del_drawObj('markedExitHash', $exitObj->number);
                    }

                    if ($mapWin->ivExists('markedExitTagHash', $exitObj->number)) {

                        $mapWin->del_drawObj('markedExitTagHash', $exitObj->number);
                    }
                }

                # After any deletion operation, all selected canvas objects must be un-selected
                $mapWin->setSelectedObj();

                # Redraw all rooms marked to be redrawn
                $mapWin->markObjs(@redrawList);
            }
        }

        # Make sure the deleted exits are not marked to be re-drawn
        foreach my $mapWin ($self->collectMapWins()) {

            foreach my $exitObj (@exitList) {

                $mapWin->del_markedExit($exitObj->number);
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

            $mapWin->del_markedExit($exitObj->number);
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

        foreach my $labelObj (@labelList) {

            # Get the label's parent regionmap
            my $regionmapObj = $self->ivShow('regionmapHash', $labelObj->region);

            # Remove the label from the regionmap
            $regionmapObj->removeLabel($labelObj);

            # Update any GA::Win::Map objects using this world model (if allowed)
            if ($updateFlag) {

                foreach my $mapWin ($self->collectMapWins()) {

                    # Delete the label's canvas object (if it exists)
                    $mapWin->deleteCanvasObj('label', $labelObj, TRUE);

                    # After any deletion operation, all selected canvas objects must be un-selected
                    $mapWin->setSelectedObj();
                }
            }
        }

        # Make sure the deleted labels are not marked to be re-drawn
        foreach my $mapWin ($self->collectMapWins()) {

            foreach my $labelObj (@labelList) {

                $mapWin->del_markedLabel($labelObj->number);
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
        #   $roomHashRef        - Reference to a hash of GA::ModelObj::Room objects to move
        #   $labelHashRef       - Reference to a hash of GA::Obj::MapLabel objects to move
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
            %roomHash, %labelHash, %checkExitHash,
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

            foreach my $mapWin ($self->collectMapWins()) {

                # For this Automapper window, if either the old or new regionmaps are visible,
                #   redraw the whole region
                if (
                    $mapWin->currentRegionmap
                    && (
                        $mapWin->currentRegionmap eq $oldRegionmapObj
                        || $mapWin->currentRegionmap eq $newRegionmapObj
                    )
                ) {
                    $mapWin->drawRegion();
                }
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

                # Redraw the dragged object (let the Automapper window check whether it's on the
                #   currently visible region and level)
                $mapWin->markObjs(@redrawList);
            }
        }

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

            # We only need to redraw rooms on the currently visible regionmap and level
            foreach my $mapWin ($self->collectMapWins()) {

                if (
                    $obj->category eq 'room'
                    && $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $obj->parent
                    && $mapWin->currentRegionmap->currentLevel == $obj->zPosBlocks
                ) {
                    # Mark the room to be drawn
                    $mapWin->markObjs('room', $obj);
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

            # We only need to redraw rooms on the currently visible regionmap and level
            foreach my $mapWin ($self->collectMapWins()) {

                if (
                    $obj->category eq 'room'
                    && $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $obj->parent
                    && $mapWin->currentRegionmap->currentLevel == $obj->zPosBlocks
                ) {
                    # Mark the room to be drawn
                    $mapWin->markObjs('room', $obj);
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

                if (
                    $obj->category eq 'room'
                    && $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $obj->parent
                    && $mapWin->currentRegionmap->currentLevel == $obj->zPosBlocks
                ) {
                    # Mark the room to be drawn
                    $mapWin->markObjs('room', $obj);
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

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $parentObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $parentObj->zPosBlocks
                ) {
                    # ...mark the (parent) room to be drawn
                    $mapWin->markObjs('room', $parentObj);
                }
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

            my @redrawList;

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
            }
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

                # Redraw the region to remove the displayed counts
                $mapWin->drawRegion();
            }
        }

        return 1;
    }

    sub removeRoomFlags {

        # Called by GA::Win::Map->removeRoomFlagsCallback
        # Removes a room flag from every room in an existing region, and redraws the region
        #
        # Expected arguments
        #   $regionmapObj   - The GA::Obj::Regionmap whose counts should be reset
        #   $roomFlag       - The room flag to remove (matches a key in $self->roomFlagTextHash)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of modified rooms (may be 0)

        my ($self, $regionmapObj, $roomFlag, $check) = @_;

        # Local variables
        my $count;

        # Check for improper arguments
        if (! defined $regionmapObj || ! defined $roomFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeRoomFlags', @_);
        }

        # Remove the room flag from any room in the specified region which uses it
        $count = 0;

        foreach my $roomNum ($regionmapObj->ivValues('gridRoomHash')) {

            my $roomObj = $self->ivShow('modelHash', $roomNum);

            if ($roomObj->ivExists('roomFlagHash', $roomFlag)) {

                $roomObj->ivDelete('roomFlagHash', $roomFlag);
                $count++;
            }
        }

        # Update each Automapper window
        foreach my $mapWin ($self->collectMapWins()) {

            if ($mapWin->currentRegionmap eq $regionmapObj) {

                # Redraw the region to update the modified rooms
                $mapWin->drawRegion();
            }
        }

        return $count;
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
                    # Redraw the regionmap, which empties the drawn map
                    $mapWin->drawRegion();
                }
            }
        }

        return 1
    }

    sub connectRegionBrokenExit {

        # Called by GA::Win::Map->connectExitToRoom, GA::Cmd::DeleteRoom->do,
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

        # This function uses 'dialogue' windows. While the dialogue window is open, we don't want
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

            push (@redrawList, $self->ivShow('modelHash', $exitObj->destRoom));
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

                if ($oppExitObj->impassFlag || $oppExitObj->randomType ne 'none') {

                    # The opposite exit is impassable, so it can't be made a twin (or it is a random
                    #   exit, and it should remain a random exit)
                    # Therefore, $exitObj must be made one-way
                    $forceOneWayFlag = TRUE;
                }

                if (
                    ! $oppExitObj->destRoom
                    && $oppExitObj->randomType eq 'none'
                    && ! $forceOneWayFlag
                ) {
                    # Prompt the user to modify it
                    $choice = $session->mapWin->showMsgDialogue(
                        'Set up twin exit',
                        'question',
                        "Would you like to modify the clicked\n"
                        . "room\'s existing \'" . $exitObj->dir . "\' exit to lead\n"
                        . "back to the original room?",
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

                if (@comboList) {

                    # Prompt the user for an exit
                    $choice = $session->mapWin->showComboDialogue(
                        'Set up twin exit',
                        "Choose one of the clicked room\'s existing exits\n"
                        . "to lead back to the original room (or click the\n"
                        . "'Cancel' button to mark this exit as one-way)",
                        FALSE,
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

                # If this is the Automapper window which called this function...
                if ($mapWin->session eq $session) {

                    # Set the displayed region, which redraws the room containing the specified exit
                    $mapWin->setCurrentRegion($parentRegionObj->name);

                } else {

                    # For other Automapper windows, let them worry about whether the rooms to be
                    #   re-drawn are actually visible)
                    $mapWin->markObjs(@redrawList);
                }
            }
        }

        # Allow $self->updateRegionPaths to be called again
        $self->ivPoke('updateDelayFlag', FALSE);

        return 1;
    }

    # Modify model objects - rooms

    sub updateRegion {

        # Can be called by anything to force any Automapper windows to redraw their current region
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $region     - The name of a regionmap. If specified, only this region is redrawn; any
        #                   Automapper windows showing a different region are ignored. If set to
        #                   'undef', all Automapper windows using this world model have their
        #                   region redrawn
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

            if (! $regionmapObj || $mapWin->currentRegionmap eq $regionmapObj) {

                # Redraw the window's current region
                $mapWin->drawRegion();
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
        #   @list       - A list to send to each Automapper window's ->markObjs, in the form
        #                   (type, object, type, object...)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, @list) = @_;

        # Check for improper arguments
        if (! @list) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateMaps', @_);
        }

        foreach my $mapWin ($self->collectMapWins()) {

            # Mark the objects to be drawn
            $mapWin->markObjs(@list);
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

            # Mark the objects to be drawn
            $mapWin->markObjs(@list);
        }

        return 1;
    }

    sub connectRooms {

        # Called by GA::Obj::Map->autoProcessNewRoom, ->useExistingRoom,
        #   GA::Win::Map->createNewRoom, $self->connectRegions or any other function
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
        #
        # Return values
        #   'undef' on improper arguments or if the rooms can't be connected
        #   1 otherwise

        my (
            $self, $session, $updateFlag, $departRoomObj, $arriveRoomObj, $dir, $mapDir, $exitObj,
            $oppExitObj,
            $check,
        ) = @_;

        # Local variables
        my (
            $number, $departExitObj, $standardDir, $departRegionFlag, $arriveExitObj,
            $arriveRegionFlag, $departRegionObj, $arriveRegionObj,
            @list,
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
                $standardDir = $session->currentDict->checkPrimaryDir($dir);

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

            $self->setRetracingExit(
                FALSE,          # Don't update Automapper windows now
                $departExitObj,
            );

        # If we're not using an existing exit object which already has an opposite exit...
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

            if ($arriveExitObj) {

                # An opposite exit exists
                $arriveRegionFlag = $arriveExitObj->regionFlag;

                if (
                    (
                        $self->autocompleteExitsFlag
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
                    if ($self->autocompleteExitsFlag) {

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
        if ($departExitObj->impassFlag) {

            $self->setExitOrnament(
                FALSE,              # Don't update Automapper windows yet
                $departExitObj,
            );
        }

        # The twin exit object (if any) also loses its impassable status
        if ($arriveExitObj && $arriveExitObj->impassFlag) {

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
            @list = ('room', $arriveRoomObj);
            if ($departRoomObj) {

                push (@list, 'room', $departRoomObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $arriveRoomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $arriveRoomObj->zPosBlocks
                ) {
                    # ...mark the room(s) to be drawn
                    $mapWin->markObjs(@list);
                }
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

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap eq $roomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                ) {
                    # ...mark the room to be drawn
                   $mapWin->markObjs('room', $roomObj);
                }
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

                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $roomObj->parent
                    && $mapWin->currentRegionmap->currentLevel eq $roomObj->zPosBlocks
                ) {
                    $mapWin->markObjs('room', $roomObj);
                }
            }
        }

        return 1;
    }

    sub resetRemoteData {

        # Called by GA::Win::Map->resetRemoteCallback
        # Removes the remote date stored in room model objects (originally supplied by the MSDP/MXP
        #   protocols)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                       be updated now, FALSE if not (in which case, they can be updated
        #                       later by the calling function, when it is ready)
        #
        # Return values
        #   'undef' on improper arguments or if no record(s) are deleted
        #   1 otherwise

        my ($self, $updateFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $updateFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetRemoteData', @_);
        }

        foreach my $roomObj ($self->ivValues('roomModelHash')) {

            if ($roomObj->protocolRoomHash || $roomObj->protocolExitHash) {

                $roomObj->ivEmpty('protocolRoomHash');
                $roomObj->ivEmpty('protocolExitHash');

                # Update any GA::Win::Map objects using this world model (if allowed)
                if ($updateFlag) {

                    foreach my $mapWin ($self->collectMapWins()) {

                        if (
                            $mapWin->currentRegionmap
                            && $mapWin->currentRegionmap->number eq $roomObj->parent
                            && $mapWin->currentRegionmap->currentLevel eq $roomObj->zPosBlocks
                        ) {
                            $mapWin->markObjs('room', $roomObj);
                        }
                    }
                }
            }
        }

        return 1;
    }

    sub addExitPattern {

        # Can be called by anything
        # Adds a failed exit pattern to a specified room
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room to update
        #   $type       - The type of pattern to add - 'fail', 'involuntary', 'repulse' or 'special'
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
        } elsif ($type eq 'involuntary') {
            $roomObj->ivPush('involuntaryExitPatternList', $pattern);
        } elsif ($type eq 'repulse') {
            $roomObj->ivPush('repulseExitPatternList', $pattern);
        } elsif ($type eq 'special') {
            $roomObj->ivPush('specialDepartPatternList', $pattern);
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
        #                   $self->roomFlagTextHash)
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

                my ($regionObj, $listRef);

                $regionObj = $self->ivShow('modelHash', $regionNum);
                $listRef = $regionHash{$regionNum};

                $self->recalculateSafePaths(
                    $session,
                    $self->ivShow('regionmapHash', $regionObj->name),
                    @$listRef,
                );
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Update each Automapper window which is showing a region which contains any of the
            #   rooms in @roomList
            foreach my $mapWin ($self->collectMapWins()) {

                my (
                    $roomListRef,
                    @redrawList,
                );

                if (exists $regionHash{$mapWin->currentRegionmap->number}) {

                    $roomListRef = $regionHash{$mapWin->currentRegionmap->number};
                    foreach my $roomObj (@$roomListRef) {

                        push (@redrawList, 'room', $roomObj);
                    }

                    # Redraw affected rooms in this region
                    $mapWin->markObjs(@redrawList);
                }
            }
        }

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
            $oldRoomNum, $oldRoomObj, $regionObj, $regionmapObj,
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
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);
        $regionmapObj->storeRoomTag($roomObj);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # $roomObj must be redrawn
            push (@redrawList, 'room', $roomObj);

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap eq $regionmapObj
                    && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                ) {
                    # ...mark the room(s) to be drawn
                    $mapWin->markObjs(@redrawList);
                }
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
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);
        $regionmapObj->removeRoomTag($roomObj);

        # Reset the room object's own IV
        $roomObj->ivUndef('roomTag');

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap eq $regionmapObj
                    && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                ) {
                    # ...mark the room to be drawn
                    $mapWin->markObjs('room', $roomObj);
                }
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

            my ($regionObj, $regionmapObj);

            # Set the room's guild. $guildName might be 'undef'
            $roomObj->ivPoke('roomGuild', $guildName);

            # Update the regionmap
            $regionObj = $self->ivShow('modelHash', $roomObj->parent);
            $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);

            if ($guildName) {
                $regionmapObj->storeRoomGuild($roomObj);
            } else {
                $regionmapObj->removeRoomGuild($roomObj);
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                INNER: foreach my $roomObj (@roomList) {

                    # If the automapper is showing the same region and level...
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number == $roomObj->parent
                        && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                    ) {
                        # ...mark the room(s) to be drawn
                       $mapWin->markObjs('room', $roomObj);
                    }
                }
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

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                INNER: foreach my $roomObj (@roomList) {

                    # If the automapper is showing the same region and level...
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number == $roomObj->parent
                        && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                    ) {
                        # ...mark the room(s) to be drawn
                        $mapWin->markObjs('room', $roomObj);
                    }
                }
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

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                INNER: foreach my $roomObj (@roomList) {

                    # If the automapper is showing the same region and level...
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number == $roomObj->parent
                        && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                    ) {
                        # ...mark the room(s) to be drawn
                        $mapWin->markObjs('room', $roomObj);
                    }
                }
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

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number == $roomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                ) {
                    # ...mark the room to be drawn
                    $mapWin->markObjs('room', $roomObj);
                }
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

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                INNER: foreach my $roomObj (@roomList) {

                    # If the automapper is showing the same region and level...
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number == $roomObj->parent
                        && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                    ) {
                        # ...mark the room(s) to be drawn
                        $mapWin->markObjs('room', $roomObj);
                    }
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

    # Modify model objects - exits

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
        # Converts an exit into a broken exit (cancelling its status as a region exit, if need be)
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
        my ($roomObj, $regionObj, $destRoomObj);

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setBrokenExit', @_);
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
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        # Mark the exit as broken...
        $exitObj->ivPoke('brokenFlag', TRUE);
        $self->checkBentExit($exitObj, $roomObj, $destRoomObj);

        # ...and definitely not a region exit
        $exitObj->ivPoke('regionFlag', FALSE);
        $self->cancelExitTag(
            FALSE,              # Don't update Automapper windows yet
            $exitObj,
            $self->ivShow('regionmapHash', $regionObj->name),
        );

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

                # Mark both the exit and its destination room to be redrawn
                $mapWin->markObjs(
                    'exit', $exitObj,
                    'room', $roomObj,
                );
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

            # Mark both rooms to be redrawn
            @redrawList = (
                'room', $roomObj,
                'room', $self->ivShow('modelHash', $incomingExitObj->parent),
            );

            foreach my $mapWin ($self->collectMapWins()) {

                $mapWin->markObjs(@redrawList);
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

            # Mark both rooms to be redrawn
            @redrawList = (
                'room', $destRoomObj,
                'room', $self->ivShow('modelHash', $exitObj->parent),
            );

            foreach my $mapWin ($self->collectMapWins()) {

              $mapWin->markObjs(@redrawList);
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

        # Modify $exitObj
        $exitObj->ivUndef('destRoom');
        $exitObj->ivUndef('twinExit');
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

        # Set ->randomType too, just to be safe
        $exitObj->ivPoke('randomType', 'none');

        # Any region paths using the exits will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        # Modify the $twinExitObj, if it still exists
        if ($twinExitObj) {

            # Find the parent room and region
            $twinRoomObj = $self->ivShow('modelHash', $twinExitObj->parent);
            $twinRegionObj = $self->ivShow('modelHash', $twinRoomObj->parent);

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

            # Any region paths using the exits will have to be updated
            $self->ivAdd('updatePathHash', $twinExitObj->number, $twinRegionObj->name);
            if ($twinExitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $twinExitObj->number, $twinRegionObj->name);
            }
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # If the exit has a twin, that must be redrawn, too
            @list = ('exit', $exitObj);
            if ($twinExitObj) {

                push (@list, 'exit', $twinExitObj);
            }

            foreach my $mapWin ($self->collectMapWins()) {

                # Mark the objects to be drawn
                $mapWin->markObjs(@list);
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

                # Mark the object to be drawn
                $mapWin->markObjs('exit', $exitObj);
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
        my ($roomObj, $regionObj, $destRoomObj);

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
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
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

        $exitObj->ivPoke('regionFlag', FALSE);
        $self->cancelExitTag(
            FALSE,              # Don't update Automapper windows yet
            $exitObj,
            $self->ivShow('regionmapHash', $regionObj->name),
        );

        # Inform the destination room that it has lost an incoming 1-way exit (if the destination
        #   room still exits)
        if ($destRoomObj) {

            $destRoomObj->ivDelete('oneWayExitHash', $exitObj->number);
        }

        # Any region paths using the exits will have to be updated
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        if ($exitObj->regionFlag) {

            $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Mark the object to be drawn
                $mapWin->markObjs('exit', $exitObj);
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
                ! $exitObj->oneWayFlag
                && ! (
                    $exitObj->destRoom
                    && ! $exitObj->twinExit
                    && ! $exitObj->retraceFlag
                    && $exitObj->randomType eq 'none'
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

                # Mark the object to be drawn
                $mapWin->markObjs(
                    'room', $roomObj1,
                    'room', $roomObj2,
                );
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

                # Mark the objects to be drawn
               $mapWin->markObjs(@list);
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

               $mapWin->markObjs('room', $roomObj);
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
        #                   region or 'room_list' if the exit leads to a random location in the
        #                   exit's ->randomDestList
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
            || ($exitType ne 'same_region' && $exitType ne 'any_region' && $exitType ne 'room_list')
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

                # Mark the objects to be drawn
               $mapWin->markObjs(@redrawList);
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

                $mapWin->markObjs('room', $roomObj);
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
            $roomObj, $regionObj, $regionmapObj, $destRegionNum,
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
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);

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
                    $self->ivAdd('updatePathHash', $otherExitObj->number, $regionObj->name);
                    $self->ivAdd('updateBoundaryHash', $otherExitObj->number, $regionObj->name);

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

                # Mark the objects to be drawn
               $mapWin->markObjs(@redrawList);
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
        $regionObj = $self->ivShow('modelHash', $roomObj->parent);
        $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);

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
        $self->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
        $self->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);

        # Mark the exit's parent room to be re-drawn
        push (@redrawList, 'room', $self->ivShow('modelHash', $exitObj->parent));

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # Mark the objects to be drawn
               $mapWin->markObjs(@redrawList);
            }
        }

        return 1;
    }

    sub setImpassableExit {

        # Called by $self->setExitOrnament (should not be called by anything else)
        # Converts any kind of exit into an (incomplete) impassable exit
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

        # Update the exit. The ornament flags, including ->impassFlag, are set by the calling
        #   function
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
        $exitObj->ivPoke('exitState', 'impass');

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

                # Mark the objects to be drawn
                $mapWin->markObjs(@redrawList);
            }
        }

        return 1;
    }

    sub setExitOrnament {

        # Can be called by anything (especially by $self->setMultipleOrnaments)
        # Only one of the five GA::Obj::Exit IVs ->breakFlag, ->pickFlag, ->lockFlag, ->openFlag
        #   or ->impassFlag should be set to TRUE at any time (by default, none of them are set to
        #   TRUE)
        # Sets one of the ornament IVs and resets the others (or, resets all of them)
        # Optionally sets (or resets) the ornament of this exit's twin exit if there is one) to
        #   match
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $exitObj    - The exit object to modify
        #
        # Optional arguments
        #   $iv         - The IV to set, e.g. 'breakFlag'. If set to 'undef', all 5 IVs are reset
        #   $twinFlag   - If set to TRUE, the twin exit's ornament (if there is a twin exit) is set
        #                   to match
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $updateFlag, $exitObj, $iv, $twinFlag, $check) = @_;

        # Local variables
        my (
            $regionFlag, $twinExitObj, $twinRegionFlag, $roomObj, $regionObj, $twinRoomObj,
            $twinRegionObj,
        );

        # Check for improper arguments
        if (
            ! defined $updateFlag || ! defined $exitObj
            || (
                defined $iv && $iv ne 'breakFlag' && $iv ne 'pickFlag' && $iv ne 'lockFlag'
                && $iv ne 'openFlag' && $iv ne 'impassFlag'
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

        # Reset the IVs
        $exitObj->ivPoke('breakFlag', FALSE);
        $exitObj->ivPoke('pickFlag', FALSE);
        $exitObj->ivPoke('lockFlag', FALSE);
        $exitObj->ivPoke('openFlag', FALSE);
        $exitObj->ivPoke('impassFlag', FALSE);
        $exitObj->ivPoke('ornamentFlag', FALSE);

        # Set an IV, if one was specified
        if ($iv) {

            $exitObj->ivPoke($iv, TRUE);
            $exitObj->ivPoke('ornamentFlag', TRUE);

            if ($iv eq 'impassFlag') {

                # Convert this exit into an incomplete impassable exit
                $self->setImpassableExit(
                    FALSE,      # Don't update Automapper windows yet
                    $exitObj,
                );

            } elsif ($exitObj->exitState eq 'impass') {

                # The exit's state is no longer impassable
                $exitObj->ivPoke('exitState', 'normal');       # State not known
            }
        }

        # The call to ->setImpassableExit updates ->updatePathHash and ->updateBoundaryHash. If it
        #   was not called, those IVs must be updated now
        if (! $iv || $iv ne 'impassFlag') {

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

            $twinExitObj->ivPoke('breakFlag', FALSE);
            $twinExitObj->ivPoke('pickFlag', FALSE);
            $twinExitObj->ivPoke('lockFlag', FALSE);
            $twinExitObj->ivPoke('openFlag', FALSE);
            $twinExitObj->ivPoke('impassFlag', FALSE);
            $twinExitObj->ivPoke('ornamentFlag', FALSE);

            if ($iv) {

                $twinExitObj->ivPoke($iv, TRUE);
                $twinExitObj->ivPoke('ornamentFlag', TRUE);

                if ($iv eq 'impassFlag') {

                    # Convert this exit into an incomplete impassable exit
                    $self->setImpassableExit(
                        FALSE,      # Don't update Automapper windows yet
                        $twinExitObj,
                    );

                } elsif ($twinExitObj->exitState eq 'impass') {

                    # The exit's state is no longer impassable
                    $twinExitObj->ivPoke('exitState', 'normal');       # State not known
                }
            }

            # The call to ->setImpassableExit updates ->updatePathHash and ->updateBoundaryHash. If
            #   it was not called, those IVs must be updated now
            # Find the parent region
            $twinRoomObj = $self->ivShow('modelHash', $twinExitObj->parent);
            $twinRegionObj = $self->ivShow('modelHash', $twinRoomObj->parent);
            # Update the hashes
            $self->ivAdd('updatePathHash', $twinExitObj->number, $twinRegionObj->name);
            if ($twinExitObj->regionFlag) {

                $self->ivAdd('updateBoundaryHash', $twinExitObj->number, $twinRegionObj->name);
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
        #   $iv             - The GA::Obj::Exit IV corresponding to the exit ornament (e.g.
        #                       'pickFlag'). If 'undef', every exit is reset so that it has no
        #                       ornaments
        #   @exitList       - A list of exit objects to modify. If the list is empty, no exits are
        #                       modified
        #
        # Return values
        #   'undef' on improper arguments or if @exitList is empty
        #   1 otherwise

        my ($self, $updateFlag, $iv, @exitList) = @_;

        # Local variables
        my %roomHash;

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
                $iv,                            # May be 'undef'
                $self->setTwinOrnamentFlag,
            );
        }

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                INNER: foreach my $roomObj (values %roomHash) {

                    # If the automapper is showing the same region and level...
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $roomObj->parent
                        && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                    ) {
                        # ...mark the room to be drawn
                       $mapWin->markObjs('room', $roomObj);
                    }
                }
            }
        }

        return 1;
    }

    sub addAssistedMove {

        # Called by GA::Win::Map->addExitCallback and ->setAssistedMoveCallback
        # Adds an assisted move to a specified exit object
        #
        # Expected arguments
        #   $exitObj        - The GA::Obj::Exit to be modified
        #   $profile        - The name of a profile. When it's a current profile, this assisted move
        #                       is available
        #   $cmdSequence    - A sequence of one or more world commands (separated by the usual
        #                       command separator) that comprise the assisted move, e.g.
        #                       'north;open door;east'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $profile, $cmdSequence, $check) = @_;

        # Check for improper arguments
        if (! defined $exitObj || ! defined $profile || ! defined $cmdSequence || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addAssistedMove', @_);
        }

        # Update the exit object
        $exitObj->ivAdd('assistedHash', $profile, $cmdSequence);

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

        # Redraw the room (and its exits), as well as any connecting rooms (and their converted
        #   exits), if allowed
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
            $regionObj,
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
        push (@redrawList, $roomObj);

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

            OUTER: foreach my $mapWin ($self->collectMapWins()) {

                INNER: foreach my $otherRoomObj (@redrawList) {

                    # If the automapper is showing the same region and level...
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $otherRoomObj->parent
                        && $mapWin->currentRegionmap->currentLevel == $otherRoomObj->zPosBlocks
                    ) {
                        # ...mark the room to be drawn
                        $mapWin->markObjs('room', $otherRoomObj);
                    }
                }

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

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $roomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                ) {
                    # ...mark the room to be drawn
                   $mapWin->markObjs('room', $roomObj);
                }

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

                $mapWin->markObjs(@redrawList);

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
                $regionObj = $self->ivShow('modelHash', $roomObj->parent);
                $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);
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

                    # If the automapper is showing the same region...
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $regionmapObj->number
                        && $mapWin->currentRegionmap->currentLevel == $regionmapObj->currentLevel
                    ) {
                        # ...mark the exit to be drawn
                        $mapWin->markObjs('exit', $exitObj);
                    }
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
                $regionObj = $self->ivShow('modelHash', $roomObj->parent);
                $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);
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

                    # If the automapper is showing the same region...
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $regionmapObj->number
                        && $mapWin->currentRegionmap->currentLevel == $regionmapObj->currentLevel
                    ) {
                        # ...mark the exit to be drawn
                       $mapWin->markObjs('exit', $exitObj);
                    }
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

                    # If the automapper is showing the same region...
                    if (
                        $mapWin->currentRegionmap
                        && $mapWin->currentRegionmap->number eq $roomObj->parent
                        && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                    ) {
                        # ...mark the exit to be drawn
                       $mapWin->markObjs('exit', $exitObj);
                    }
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

        # If the exit has no bends, then our job is fairly easy
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

                # If the automapper is showing the same region...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $roomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                ) {
                    # ...mark the room to be drawn
                    $mapWin->markObjs('room', $roomObj);
                }
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

        my ($self, $updateFlag, $exitObj, $index, $check) = @_;

        # Local variables
        my $roomObj;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $exitObj || ! defined $index || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeExitBend', @_);
        }

        # GA::Obj::Exit->bendOffsetList is in the form (x, y, x, y...). Remove a single pair of
        #   (x, y) coordinates; e.g. if $index = 2, remove the 5th and 6th coordinates
        $index *= 2;
        $exitObj->ivSplice('bendOffsetList', $index, 2);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            # Get the exit's parent room
            $roomObj = $self->ivShow('modelHash', $exitObj->parent);

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->number eq $roomObj->parent
                    && $mapWin->currentRegionmap->currentLevel == $roomObj->zPosBlocks
                ) {
                    # ...mark the room to be drawn
                    $mapWin->markObjs('room', $roomObj);
                }
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

    sub setLabelName {

        # Called by GA::Win::Map->editLabelCallback
        # Sets the specified label's ->name IV (containing the text displayed) and redraw the label
        #   (if allowed)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $labelObj   - The GA::Obj::MapLabel to modify
        #   $name       - The new text for the label
        #
        # Return values
        #   'undef' on improper arguments or if @roomList is empty
        #   1 otherwise

        my ($self, $updateFlag, $labelObj, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $labelObj || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setLabelName', @_);
        }

        # Update the label
        $labelObj->ivPoke('name', $name);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->name eq $labelObj->region
                    && $mapWin->currentRegionmap->currentLevel == $labelObj->level
                ) {
                    # ...mark the label to be drawn
                    $mapWin->markObjs('label', $labelObj);
                }
            }
        }

        return 1;
    }

    sub setLabelSize {

        # Called by GA::Win::Map->enableLabelsColumn and ->enableLabelsPopupMenu
        # Sets the specified label's ->relSize IV (containing the label's relative size, with 1
        #   being the default value) and redraw the label (if allowed)
        #
        # Expected arguments
        #   $updateFlag - Flag set to TRUE if all Automapper windows using this world model should
        #                   be updated now, FALSE if not (in which case, they can be updated later
        #                   by the calling function, when it is ready)
        #   $labelObj   - The GA::Obj::MapLabel to modify
        #   $size       - The new relative size for the label
        #
        # Return values
        #   'undef' on improper arguments or if @roomList is empty
        #   1 otherwise

        my ($self, $updateFlag, $labelObj, $size, $check) = @_;

        # Check for improper arguments
        if (! defined $updateFlag || ! defined $labelObj || ! defined $size || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setLabelSize', @_);
        }

        # Update the label
        $labelObj->ivPoke('relSize', $size);

        # Update any GA::Win::Map objects using this world model (if allowed)
        if ($updateFlag) {

            foreach my $mapWin ($self->collectMapWins()) {

                # If the automapper is showing the same region and level...
                if (
                    $mapWin->currentRegionmap
                    && $mapWin->currentRegionmap->name eq $labelObj->region
                    && $mapWin->currentRegionmap->currentLevel == $labelObj->level
                ) {
                    # ...mark the label to be drawn
                    $mapWin->markObjs('label', $labelObj);
                }
            }
        }

        return 1;
    }

    # Other functions called by GA::Obj::Map and GA::Win::Map

    sub compareRooms {

        # Called by GA::Obj::Map->useExistingRoom to compare the current location according to
        #   the Locator task (GA::Task::Locator->roomObj, a non-model room object), with the current
        #   location according to the automapper (which is in the world model)
        # Also called by GA::Win::Map->autoCompareLocatorRoom
        # How the rooms are compared depends on the values of various flags
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $modelRoomObj   - A GA::ModelObj::Room somewhere in the world model
        #
        # Optional arguments
        #   $noBlanksFlag   - Set to TRUE when called by ->autoCompareLocatorRoom. Doesn't allow
        #                       matching with empty, dark or unspecified rooms
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form (result, error_message), where:
        #       - 'result' is set to 1 if the rooms match, or 'undef' if they don't (or if there is
        #           an error)
        #       - 'error_message' is a string to display on failure; otherwise 'error_message' is
        #           'undef'

        my ($self, $session, $modelRoomObj, $noBlanksFlag, $check) = @_;

        # Local variables
        my (
            $taskObj, $matchFlag,
            @emptyList,
            %modelExitHash, %taskExitHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $modelRoomObj || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->compareRooms', @_);
            return @emptyList;
        }

        # If a blank room has been added to the map, it always matches any Locator room
        if (! $noBlanksFlag && ! $modelRoomObj->everMatchedFlag) {

            # This should happen only once for each world model room
            $modelRoomObj->ivPoke('everMatchedFlag', TRUE);

            return (1, undef);  # No error message
        }

        # Import the Locator task
        $taskObj = $session->locatorTask;
        # If the Locator task isn't running, or if it doesn't know the current location, the rooms
        #   aren't a match
        if (! $taskObj || ! $taskObj->roomObj) {

            return (undef, 'Lost because Locator doesn\'t exist or current location not known');
        }

        # Dark rooms and unspecified rooms are a match for any rooms (unless the $noBlanksFlag
        #   is set)
        if (
            ! $noBlanksFlag
            && ($taskObj->roomObj->unspecifiedFlag || $taskObj->roomObj->currentlyDarkFlag)
        ) {
            return (1, undef);  # No error message
        }

        # Compare the rooms' properties, taking into account the values of various flags

        # Compare room titles (if allowed). If one or the other room doesn't have a title, we can't
        #   tell at this stage whether they match
        if (
            $self->matchTitleFlag
            && $modelRoomObj->titleList
            && $taskObj->roomObj->titleList
        ) {
            $matchFlag = FALSE;

            OUTER: foreach my $modelTitle ($modelRoomObj->titleList) {

                foreach my $taskTitle ($taskObj->roomObj->titleList) {

                    if ($modelTitle eq $taskTitle) {

                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $matchFlag) {

                # The two rooms's titles don't match
                return (undef, 'Lost because rooms\' titles don\'t match');
            }
        }

        # Compare (verbose) descriptions (if allowed). If one or the other doesn't have a verbose
        #   description, we can't tell at this stage whether they match
        if (
            $self->matchDescripFlag
            && $modelRoomObj->descripHash
            && $taskObj->roomObj->descripHash
        ) {
            $matchFlag = FALSE;

            OUTER: foreach my $modelDescrip ($modelRoomObj->ivValues('descripHash')) {

                INNER: foreach my $taskDescrip ($taskObj->roomObj->ivValues('descripHash')) {

                    # Compare the entire verbose descriptions, if allowed
                    if (! $self->matchDescripCharCount) {

                        if ($modelDescrip eq $taskDescrip) {

                            $matchFlag = TRUE;
                            last OUTER;
                        }

                    # Otherwise, compare the first part of the verbose descriptions - namely, the
                    #   first $self->matchDescripCharCount characters
                    } elsif (
                        substr($modelDescrip, 0, $self->matchDescripCharCount)
                        eq substr ($taskDescrip, 0, $self->matchDescripCharCount)
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
        }

        # Compare exits (if allowed)
        if ($self->matchExitFlag && ! $session->currentWorld->basicMappingMode) {

            $matchFlag = FALSE;

            # Import hashes of exits, in the form
            #   $exitNumHash{direction} = exit_number_in_exit_model (model rooms)
            #   $exitNumHash{direction} = exit_object (non-model rooms)
            %modelExitHash = $modelRoomObj->exitNumHash;
            %taskExitHash = $taskObj->roomObj->exitNumHash;

            # Compare the keys in both hashes. Delete matching exits from each hash; if there are
            #   any exits left (or missing), the rooms don't match
            foreach my $dir (keys %modelExitHash) {

                my ($exitNum, $exitObj);

                $exitNum = $modelExitHash{$dir};
                $exitObj = $self->ivShow('exitModelHash', $exitNum);
                if ($exitObj && $exitObj->hiddenFlag) {

                    # The Exit should exist here
                    delete $modelExitHash{$dir};
                    # The exit shouldn't exist here - delete it anyway, just in case
                    delete $taskExitHash{$dir};

                } elsif (! exists $taskExitHash{$dir}) {

                    # Missing exit in the Locator's current room, so the rooms don't match
                    return (
                        undef,
                        'Lost because of missing exit (\'' . $dir . '\') in Locator task\'s'
                        . ' current room (automapper current room is #' . $modelRoomObj->number
                        . ', Locator room exits: ' . join(', ', $taskObj->roomObj->sortedExitList)
                        . ')',
                    );

                } else {

                    # Exit exists in both hashes (and isn't hidden)
                    delete $modelExitHash{$dir};
                    delete $taskExitHash{$dir};
                }
            }

            if (%taskExitHash) {

                # Missing exit in the model's room, so the rooms don't match
                return (
                    undef,
                    'Lost because of missing exit(s) in the automapper\'s current room: '
                    . join(', ', keys %taskExitHash) . ' (room #' . $modelRoomObj->number . ')',
                );
            }
        }

        # Compare source code paths (if allowed)
        if (
            $self->matchSourceFlag
            && $modelRoomObj->sourceCodePath
            && $taskObj->roomObj->sourceCodePath
            && $modelRoomObj->sourceCodePath ne $taskObj->roomObj->sourceCodePath
        ) {
            # The two rooms' source code paths don't match
            return (undef, 'Lost because rooms\' source code paths don\'t match');
        }

        # Compare world's room vnums (if allowed)
        if (
            $self->matchVNumFlag
            && defined $modelRoomObj->ivShow('protocolRoomHash', 'vnum')
            && defined $taskObj->roomObj->ivShow('protocolRoomHash', 'vnum')
            && $modelRoomObj->ivShow('protocolRoomHash', 'vnum')
                    ne $taskObj->roomObj->ivShow('protocolRoomHash', 'vnum')
        ) {
            # The two rooms' vnums don't match
            return (undef, 'Lost because rooms\' world vnums don\'t match');
        }

        # The rooms match
        return (1, undef);  # No error message
    }

    sub locateRoom {

        # Variation on $self->compareRooms, but called only by
        #   GA::Win::Map->locateCurrentRoomCallback and GA::Obj::Map->reactRandomExit
        # Compares a specified world model room against the Locator's current room.
        # Unlike ->compareRooms, which is restricted in which components it can compare (according
        #   to the current settings of GA::Obj::WorldModel->matchTitleFlag, etc), this function
        #   compares all components and inspects the whole (verbose) description as well as the
        #   source code path (if set)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $mapRoomObj     - A GA::ModelObj::Room somewhere in the world model
        #
        # Return values
        #   'undef' on improper arguments or if the rooms don't match
        #   1 if the rooms do match

        my ($self, $session, $mapRoomObj, $check) = @_;

        # Local variables
        my (
            $taskRoomObj, $count, $matchFlag,
            %mapExitHash, %taskExitHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $mapRoomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->locateRoom', @_);
        }

        # The calling function should have checked that the Locator task exists and that it knows
        #   about the current location; it should also have checked that the Locator task's
        #   current room isn't dark or unspecified. We'll assume none of these are the case. (No
        #   point repeating the check if this function will be called many times in succession)

        # Import the Locator task's current room
        $taskRoomObj = $session->locatorTask->roomObj;

        # Check that both rooms have either a room title we can compare, or that both have a
        #   (verbose) description we can compare
        $count = 0;
        if (! $taskRoomObj->titleList || ! $mapRoomObj->titleList) {

            $count++;
        }

        if (! $taskRoomObj->descripHash || ! $mapRoomObj->descripHash) {

            $count++;
        }

        if ($count > 1) {

            # There's no title or description to compare, so these rooms can't be matched
            return undef;
        }

        # Compare room titles (if present in both rooms)
        if ($taskRoomObj->titleList && $mapRoomObj->titleList) {

            OUTER: foreach my $mapTitle ($mapRoomObj->titleList) {

                INNER: foreach my $taskTitle ($taskRoomObj->titleList) {

                    if ($mapTitle eq $taskTitle) {

                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $matchFlag) {

                # The two rooms titles don't match
                return undef;
            }
        }

        # Compare verbose descriptions (if present in both rooms)
        if ($taskRoomObj->descripHash && $mapRoomObj->descripHash) {

            $matchFlag = FALSE;

            OUTER: foreach my $mapDescrip ($mapRoomObj->ivValues('descripHash')) {

                INNER: foreach my $taskDescrip ($taskRoomObj->ivValues('descripHash')) {

                    if ($mapDescrip eq $taskDescrip) {

                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $matchFlag) {

                # The two rooms's verbose descriptions don't match
                return undef;
            }
        }

        # Compare exits (but not in 'basic mapping' mode, where the exits are not immediately
        #   available)
        if (! $session->currentWorld->basicMappingMode) {

            $matchFlag = FALSE;
            # Import hashes of exits. Each hash is in the form
            #   $hash{nominal_direction) = blessed_reference_to_exit_object
            %mapExitHash = $mapRoomObj->exitNumHash;
            %taskExitHash = $taskRoomObj->exitNumHash;

            # Compare the keys in both hashes. Delete matching exits from each hash; if there are
            #   any exits left (or missing), the rooms don't match
            foreach my $exitDir (keys %mapExitHash) {

                my ($exitNum, $exitObj);

                $exitNum = $mapExitHash{$exitDir};
                $exitObj = $self->ivShow('exitModelHash', $exitNum);

                # Ignore exits marked as hidden - they won't appear in the Locator room's list of
                #   exits
                if ($exitObj->hiddenFlag) {

                    # Exit should exist here
                    delete $mapExitHash{$exitDir};
                    # Exit shouldn't exist here - delete it anyway, just in case
                    delete $taskExitHash{$exitDir};

                } elsif (! exists $taskExitHash{$exitDir}) {

                    # Missing exit in the Locator's current room, so the rooms don't match
                    return undef;

                } else {

                    delete $mapExitHash{$exitDir};
                    delete $taskExitHash{$exitDir};
                }
            }

            if (%taskExitHash) {

                # Missing exit in the map's room, so the rooms don't match
                return undef;
            }
        }

        # Compare source code paths (if present in both rooms. This step is probably unnecessary,
        #   since if we knew $taskRoomObj's source code path, we wouldn't be trying to locate
        #   the equivalent room in the map. But, for consistency, we'll check anyway)
        if ($taskRoomObj->sourceCodePath && $mapRoomObj->sourceCodePath) {

            if ($taskRoomObj->sourceCodePath ne $mapRoomObj->sourceCodePath) {

                # The two rooms titles don't match
                return undef;
            }
        }

        # The rooms match
        return 1;
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
        #   (e.g. 'Obvious exits: north, southeast, up, out')
        # If ->dir is a custom primary direction, the ->mapDir is set to the equivalent standard
        #   primary direction at the time the exit object is created. If ->dir is a recognised
        #   secondary direction which has been given an equivalent standard primary direction, it
        #   will have been used. Otherwise, ->mapDir will still be set to 'undef'
        # This function can be called once all of a new room's exits have been created in order to
        #   allocated standard primary directions to all exits which don't have one yet. However,
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
        my $cardinalDir;

        # Check for improper arguments
        if (! defined $session || ! defined $roomObj || ! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->allocateCardinalDir', @_);
        }

        # If the exit's nominal direction ->dir is a secondary direction that should be auto-
        #   allocated a primary direction, allocate that primary direction
        if (
            $session->currentDict->ivExists('secondaryDirHash', $exitObj->dir)
            && defined $session->currentDict->ivShow('secondaryAutoHash', $exitObj->dir)
        ) {
            $cardinalDir = $session->currentDict->ivShow('secondaryAutoHash', $exitObj->dir);

            # Update the selected exit and instruct the world model to update its Automapper windows
            $self->setExitMapDir(
                $session,
                FALSE,                   # Don't update Automapper windows yet
                $roomObj,
                $exitObj,
                $cardinalDir,
            );

            return $cardinalDir;
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
        my ($regionObj, $regionmapObj, $livingCount, $nonLivingCount);

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
        $regionObj = $self->ivShow('modelHash', $modelRoomObj->parent);
        if ($regionObj) {

            $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);
        }

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

        # Called by GA::Obj::Map->moveKnownDirSeen and ->autoProcessNewRoom
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

            my ($menuItem, $iconItem);

            if ($drawFlag && $mapWin->currentRegionmap) {

                # Redraw the current region
                $mapWin->drawRegion();
            }

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($menuName && $mapWin->ivExists('menuToolItemHash', $menuName)) {

                $menuItem = $mapWin->ivShow('menuToolItemHash', $menuName);
                $menuItem->set_active($self->$iv);
            }

            # Set the equivalent toolbar button, if there is one
            if ($iconName && $mapWin->ivExists('menuToolItemHash', $iconName)) {

                $iconItem = $mapWin->ivShow('menuToolItemHash', $iconName);
                $iconItem->set_active($self->$iv);
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

            my ($menuItem, $iconItem);

            if ($drawFlag && $mapWin->currentRegionmap) {

                # Redraw the current region
                $mapWin->drawRegion();

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
            }

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($menuName && $mapWin->ivExists('menuToolItemHash', $menuName)) {

                $menuItem = $mapWin->ivShow('menuToolItemHash', $menuName);
                $menuItem->set_active(TRUE);
            }

            # Set the equivalent toolbar button, if there is one
            if ($iconName && $mapWin->ivExists('menuToolItemHash', $iconName)) {

                $iconItem = $mapWin->ivShow('menuToolItemHash', $iconName);
                $iconItem->set_active(TRUE);
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
                $menuItem = $mapWin->ivShow('menuToolItemHash', 'show_menu_bar');

            } elsif ($iv eq 'showToolbarFlag') {

                $mapWin->redrawWidgets('toolbar');
                $menuItem = $mapWin->ivShow('menuToolItemHash', 'show_toolbar');

            } elsif ($iv eq 'showTreeViewFlag') {

                $mapWin->redrawWidgets('treeview');
                $menuItem = $mapWin->ivShow('menuToolItemHash', 'show_treeview');

            } elsif ($iv eq 'showCanvasFlag') {

                # If there's a current region, we don't need it any more
                if (! $flag && $mapWin->currentRegionmap) {

                    $mapWin->setCurrentRegion();
                }

                $mapWin->redrawWidgets('canvas');
                $menuItem = $mapWin->ivShow('menuToolItemHash', 'show_canvas');
            }

            if ($menuItem) {

                $menuItem->set_active($self->$iv);
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
            $self->ivAdd('roomFilterHash', $filter, TRUE);
        } else {
            $self->ivAdd('roomFilterHash', $filter, FALSE);
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            my ($menuName, $menuItem, $iconName, $iconItem);

            if ($mapWin->currentRegionmap) {

                # Redraw the current region
                $mapWin->drawRegion();
            }

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            $menuName = $filter . '_filter';
            if ($mapWin->ivExists('menuToolItemHash', $menuName)) {

                $menuItem = $mapWin->ivShow('menuToolItemHash', $menuName);
                $menuItem->set_active($flag);
            }

            # Set the equivalent toolbar button
            $iconName = 'icon_' . $filter . '_filter';
            if ($mapWin->ivExists('menuToolItemHash', $iconName)) {

                $iconItem = $mapWin->ivShow('menuToolItemHash', $iconName);
                $iconItem->set_active($flag);
            }

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

            my ($menuName, $menuItem, $iconName, $iconItem);

            if ($mapWin->currentRegionmap) {

                # Redraw the current region
                $mapWin->drawRegion();
            }

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            $menuName = 'interior_mode_' . $mode;
            if ($mapWin->ivExists('menuToolItemHash', $menuName)) {

                $menuItem = $mapWin->ivShow('menuToolItemHash', $menuName);
                $menuItem->set_active(TRUE);
            }

            # Set the equivalent toolbar button
            $iconName = 'icon_interior_mode_' . $mode;
            if ($mapWin->ivExists('menuToolItemHash', $iconName)) {

                $iconItem = $mapWin->ivShow('menuToolItemHash', $iconName);
                $iconItem->set_active(TRUE);
            }

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

            if ($mapWin->currentRegionmap && $mapWin->currentRegionmap eq $regionmapObj) {

                # Redraw the current region
                $mapWin->drawRegion();
            }

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($mode eq 'no_exit') {
                $menuName = 'region_draw_no_exits';
            } elsif ($mode eq 'simple_exit') {
                $menuName = 'region_draw_simple_exits';
            } elsif ($mode eq 'complex_exit') {
                $menuName = 'region_draw_complex_exits';
            }

            if ($mapWin->ivExists('menuToolItemHash', $menuName)) {

                $menuItem = $mapWin->ivShow('menuToolItemHash', $menuName);
                $menuItem->set_active(TRUE);
            }

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
            $regionmapObj, $oldOffsetXPos, $oldOffsetYPos, $offsetXPos, $offsetYPos, $startXPos,
            $startYPos, $width, $height, $adjustFlag,
        );

        # Check for improper arguments
        if (! defined $mapWin || ! defined $magnification || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setMagnification', @_);
        }

        $regionmapObj = $mapWin->currentRegionmap;
        $regionmapObj->ivPoke('magnification', $magnification);

        # When we fully zoom out, so that there are no scroll bars visible, Gnome2::Canvas helpfully
        #   forgets the scrollbar's position. This means that the current room, if we were centred
        #   on it, is no longer centred. Therefore we have to get the scrollbar's position, change
        #   the map's visible size, and then - if the map is fully zoomed out, and the scrollbars
        #   have disappeared - record their position, for the next time the user zooms in

        # Get the visible map's size and position. The six return values are all numbers in the
        #   range 0-1
        ($oldOffsetXPos, $oldOffsetYPos) = $mapWin->getMapPosn();

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
        if ($width == 1 && ! $regionmapObj->maxZoomOutXFlag) {

            # We have fully zoomed out, and we weren't already fully zoomed out. Inform the
            #   regionmap
            $regionmapObj->ivPoke('maxZoomOutXFlag', TRUE);
            # Remember the position of the scrollbars before the zoom
            $regionmapObj->ivPoke('scrollXPos', $oldOffsetXPos);

        } elsif ($width != 1 && $regionmapObj->maxZoomOutXFlag) {

            # We have just zoomed in from a maximum zoom out. Reset the flags in the regionmap
            $regionmapObj->ivPoke('maxZoomOutXFlag', FALSE);
            $adjustFlag = TRUE;
        }

        if ($height == 1 && ! $regionmapObj->maxZoomOutYFlag) {

            $regionmapObj->ivPoke('maxZoomOutYFlag', TRUE);
            $regionmapObj->ivPoke('scrollYPos', $oldOffsetYPos);

        } elsif ($height != 1 && $regionmapObj->maxZoomOutYFlag) {

            $regionmapObj->ivPoke('maxZoomOutYFlag', FALSE);
            $adjustFlag = TRUE;
        }

        if ($adjustFlag) {

            # In every affected Automapper window, re-centre the map at the correct position
            foreach my $otherMapWin ($self->collectMapWins()) {

                if (
                    $otherMapWin->currentRegionmap
                    && $otherMapWin->currentRegionmap eq $regionmapObj
                ) {
                    $otherMapWin->setMapPosn($regionmapObj->scrollXPos, $regionmapObj->scrollYPos);
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
        }

        # Update every Automapper window using this world model
        foreach my $mapWin ($self->collectMapWins()) {

            if ($mapWin->currentRegionmap) {

                # Reset zoom factor (magnification) to 1
                $mapWin->zoomCallback(1);
                # Reset the scrollbars
                $mapWin->setMapPosn(0.5, 0.5);
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

            my ($menuName, $menuItem, $iconName, $iconItem);

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
            if ($mapWin->ivExists('menuToolItemHash', $menuName)) {

                $menuItem = $mapWin->ivShow('menuToolItemHash', $menuName);
                $menuItem->set_active(TRUE);
            }

            # Set the equivalent toolbar button
            $iconName = 'icon_' . $menuName;
            if ($mapWin->ivExists('menuToolItemHash', $iconName)) {

                $iconItem = $mapWin->ivShow('menuToolItemHash', $iconName);
                $iconItem->set_active(TRUE);
            }

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);
        }

        return 1;
    }

    # (Called from GA::Win::Map menu, 'Mode' column)

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

            my $menuItem;

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($mapWin->ivExists('menuToolItemHash', 'disable_update_mode')) {

                $menuItem = $mapWin->ivShow('menuToolItemHash', 'disable_update_mode');
                $menuItem->set_active($self->disableUpdateModeFlag);
            }

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

            my $menuItem;

            $mapWin->set_ignoreMenuUpdateFlag(TRUE);

            # Update the menu item
            if ($mapWin->ivExists('menuToolItemHash', 'show_tooltips')) {

                $menuItem = $mapWin->ivShow('menuToolItemHash', 'show_tooltips');
                $menuItem->set_active($self->showTooltipsFlag);
            }

            $mapWin->set_ignoreMenuUpdateFlag(FALSE);

            if (! $flag) {

                # If the tooltip window is currently visible, hide it
                $mapWin->hideTooltips();
            }
        }

        return 1;
    }

    # A* algorithm functions (used to find a path between two rooms in the same region)

    sub findPath {

        # Can be called by any function
        #
        # A* algorithm to find a path between two rooms in the same region, based on
        #   AI::Pathfinding::AStar by Aaron Dalton
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
        #   @otherHazardList
        #                   - An optional list of room flags that should be considered hazardous,
        #                       for the purposes of this algorithm (not an error if it contains
        #                       duplicate room flags, or if it contains room flags already on the
        #                       hazardous room flags list)
        #                   - NB Room flags in this list are considered hazardous, even if
        #                       $avoidHazardsFlag is FALSE
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns two list references. The first reference contains a list of
        #       GA::ModelObj::Room objects on the shortest path between the rooms $initialNode and
        #       $targetNode (inclusive). The second reference contains a list of GA::Obj::Exit
        #       objects used to move along the path. The first list contains exactly one more item
        #       than the second (exception: if no path can be found, both lists are empty)

        my ($self, $initialNode, $targetNode, $avoidHazardsFlag, @otherHazardList) = @_;

        # Local variables
        my (
            $currentNode, $path, $openListObj, $nodeHashRef, $pathRoomListRef, $pathExitListRef,
            @emptyList,
            %hazardHash,
        );

        # Check for improper arguments
        if (! defined $initialNode || ! defined $targetNode) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findPath', @_);
            return @emptyList;
        }

        # Create a combined hash of hazardous room flags (whose rooms must be avoided by the
        #   algorithm). If the function returns an empty hash, then all rooms can be used
        %hazardHash = $self->compileRoomHazards($avoidHazardsFlag, @otherHazardList);

        # Create the open list, using a binomial heap
        $openListObj = Heap::Binomial->new();
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
        $self->doAStar($targetNode, $openListObj, $nodeHashRef, %hazardHash);

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
        #   %hazardHash     - A hash of room flags. The path won't use any rooms with a room flag
        #                       stored as a key in this hash. If an empty hash, all rooms are
        #                       considered
        #
        # Return values
        #   'undef' on improper arguments, if the room has no room flags, or if none of the room's
        #       list of room flags are on the hazardous flags list
        #   1 if any of the room's list of room flags are on the hazardous flags list

        my ($self, $roomObj, %hazardHash) = @_;

        # Check for improper arguments
        if (! defined $roomObj) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkRoomHazards', @_);
        }

        # Check each flag in turn
        foreach my $flag ($roomObj->ivKeys('roomFlagHash')) {

            if (exists $hazardHash{$flag}) {

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
        #   from the paths typically produced by the A* and Djikstra algorithms
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

        # The principle of A*/Djikstra post-processing is to compare two rooms, numbered n and (n+2)
        # If there is a clear line of sight between them (if we can move using one of the ten
        #   primary directions from (n) to (n+2)), and if there is exactly one room between them,
        #   in the line of site, that is not room (n+1), then we can swap room (n+1) to the room
        #   directly between rooms (n) and (n+2)
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
                            && ! $self->checkRoomHazards($newRoomObj, %hazardHash)
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
        #   $nodeHashRef    - The hash of nodes, in the form $hash{room} = node
        #
        # Optional arguments
        #   %hazardHash     - A hash of room flags. The path won't use any rooms with a room flag
        #                       stored as a key in this hash. If an empty hash, all rooms are
        #                       considered
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $targetNode, $openListObj, $nodeHashRef, %hazardHash) = @_;

        # Local variables
        my ($currentNode, $gScore, $nodeListRef);

        # Check for improper arguments
        if (! defined $targetNode || ! defined $openListObj || ! defined $nodeHashRef) {

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
                %hazardHash,
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
        #
        # Optional arguments
        #   %hazardHash     - A hash of room flags. The path won't use any rooms with a room flag
        #                       stored as a key in this hash. If an empty hash, all rooms are
        #                       considered
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

        my ($self, $currentNode, $targetNode, %hazardHash) = @_;

        # Local variables
        my (
            @returnList,
            %roomHash,
        );

        # Check for improper arguments
        if (! defined $currentNode || ! defined $targetNode) {

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
                # Ignore exits in a different region - to find a path between rooms in different
                #   regions, $self->findUniversalPath should be called, not $self->findPath
                if ($exitObj->regionFlag) {

                    next OUTER;

                } elsif ($exitObj->destRoom) {

                    $destRoomObj = $self->ivShow('modelHash', $exitObj->destRoom);

                    # We don't use a destination room if it has any of the room flags in
                    #   %hazardHash
                    # We also don't use exits that have shadow exits (it's normally better to use
                    #   the 'north' shadow exit, rather than the 'open curtains' exit) and exits
                    #   which lead to rooms that can only be visited by certain guilds, races and
                    #   characters (etc); the latter restrictions saves us a whole lot of bother
                    if (
                        (! $destRoomObj->exclusiveFlag)
                        && (! $exitObj->shadowExit)
                        && (! $self->checkRoomHazards($destRoomObj, %hazardHash))
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

    # Djikstra algorithm (used to find a path between two rooms in different regions)

    sub findUniversalPath {

        # Can be called by any function
        #
        # Djikstra algorithm to find a path between two rooms in different regions, based on
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
        #   @otherHazardList
        #                   - An optional list of room flags that should be considered hazardous,
        #                       for the purposes of this algorithm (not an error if it contains
        #                       duplicate room flags, or if it contains room flags already on the
        #                       hazardous room flags list)
        #                   - NB This list is IGNORED if the initial and target rooms are not in
        #                       the same region
        #                   - NB Room flags in this list are considered hazardous, even if
        #                       $avoidHazardsFlag is FALSE
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
            $self, $session, $initialRoomObj, $targetRoomObj, $avoidHazardsFlag, @otherHazardList,
        ) = @_;

        # Local variables
        my (
            $dummyRoomObj, $dummyExitObj, $initialRegionObj, $initialRegionmapObj, $index,
            $dummyRoomObj2, $dummyExitObj2, $targetRegionObj, $targetRegionmapObj,
            $openListObj, $nodeHashRef, $currentNode, $pathRoomListRef, $pathExitListRef,
            @emptyList, @initialExitNumList, @initialRoomList, @targetExitNumList, @targetRoomList,
            @returnRoomList, @returnExitList,
            %universalPathHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $initialRoomObj || ! defined $targetRoomObj) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findUniversalPath', @_);
            return @emptyList;
        }

        # If the two rooms are in the same region, we can use $self->findPath
        if ($initialRoomObj->parent == $targetRoomObj->parent) {

            return $self->findPath(
                $initialRoomObj,
                $targetRoomObj,
                $avoidHazardsFlag,
                @otherHazardList,
            );
        }

        # If any exits in the exit model have been modified, we may need to check and re-calculate
        #   regions paths, before calculating a path between the two rooms
        if ($self->updatePathHash || $self->updateBoundaryHash) {

            $self->updateRegionPaths();
        }

        # The first step is to compile a hash of region paths that traverse every region in the
        #   world model, leading from one region exit to another region exit in the same region
        # At either end of each path is the node we'll use in our Djikstra algorithm. The nodes are
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
        # The Djikstra algorithm we'll employ uses exits as its nodes. The initial room can have
        #   several exits, any of which might be on the shortest path to the target room. So, we'll
        #   create a dummy room object - with a world model number set to -1 - with a dummy one-way
        #   exit which leads to the initial room.
        # When the algorithm is finished, we'll discard the room (and its exit)
        ($dummyRoomObj, $dummyExitObj) = $self->createDummyRoom($session, $initialRoomObj, -1);

        # Get the initial room's regionmap
        $initialRegionObj = $self->ivShow('modelHash', $initialRoomObj->parent);
        $initialRegionmapObj = $self->ivShow('regionmapHash', $initialRegionObj->name);
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
                $avoidHazardsFlag,
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
        $targetRegionObj = $self->ivShow('modelHash', $targetRoomObj->parent);
        $targetRegionmapObj = $self->ivShow('regionmapHash', $targetRegionObj->name);
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
                $avoidHazardsFlag,
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
        # Now we run the Djikstra algorithm (a modified A* algorithm in which the h-score is
        #   always 0) to get the shortest path between the initial and target rooms

        # Create the open list, using a binomial heap
        $openListObj = Heap::Binomial->new();
        # Create a reference to a hash of nodes, in the form
        #   $nodeHashRef{exit_object} = node
        # ...where 'exit_object' is a GA::Obj::Exit, and node is a GA::Node::Djikstra object
        $nodeHashRef = {};

        # Create a node for the initial exit
        $currentNode = Games::Axmud::Node::Djikstra->new(
            0,                  # Initial G score
            $dummyExitObj,      # Dummy exit object leading to the initial room
        );

        # Add this node to the open list
        $currentNode->ivPoke('inOpenFlag', TRUE);
        $openListObj->add($currentNode);

        # Perform the Djikstra algorithm, starting at the exit $dummyExitObj, and aiming for the
        #   exit $dummyExitObj2
        $self->doDjikstra($dummyExitObj2, $openListObj, $nodeHashRef, \%universalPathHash);

        # We can now use the nodes stored in $openListObj to find the shortest route, by tracing the
        #   path from the target room, and using the parent of each node in turn (in the standard
        #   way)
        # Get two list references, one containing the rooms in the shortest path between
        #   $dummyRoomObj and $dummyRoomObj2, and the other containing the exits to move along the
        #   path
        ($pathRoomListRef, $pathExitListRef) = $self->fillPath_djikstra(
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

    sub doDjikstra {

        # Called by $self->findUniversalPath
        # Performs the Djikstra algorithm on two nodes, each corresponding to an exit in two
        #   different regions, in order to find the shortest path between them, and therefore the
        #   shortest path between two rooms (as described in the comments for the calling function)
        #
        # Expected arguments
        #   $targetNode      - The target node (a dummy GA::Obj::Exit that the calling function
        #                       created, which leads away from the target room to a dummy
        #                       GA::ModelObj::Room)
        #   $openListObj    - The Djikstra open list, stored in a binomial heap object
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
            return $axmud::CLIENT->writeImproper($self->_objClass . '->doDjikstra', @_);
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
            $nodeListRef = $self->getSurrounding_djikstra(
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

                    $surroundNode = Games::Axmud::Node::Djikstra->new(
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

        # Djikstra algorithm complete
        return 1;
    }

    sub fillPath_djikstra {

        # Called by $self->findUniversalPath, after a call to $self->doDjikstra
        # The initial room and the target room are now linked, along the shortest path between them,
        #   by a list of nodes, each corresponding to a GA::Obj::Exit. The path begins with a dummy
        #   room connected to the initial room, and another dummy room connected to the target room
        # Compile two lists: a list of the rooms, from one dummy room to the other (inclusive), and
        #   a corresponding list of exits used to travel between them. It's up to the calling
        #   function to remove the dummy rooms (and dummy exits) at the beginning/ends of the list
        #
        # Expected arguments
        #   $targetNode     - The target node (a GA::Obj::Exit object)
        #   $openListRef    - The Djikstra open list, stored in a binomial heap object
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
            @emptyList, @refList, @nodeList, @roomList, @exitList,
        );

        # Check for improper arguments
        if (
            ! defined $targetNode || ! defined $openListObj || ! defined $nodeHashRef
            || ! defined $universalPathHashRef || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->fillPath_djikstra', @_);
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

                my ($thisExitObj, $hashRef, $regionPathObj, $pathListRef);

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

    sub getSurrounding_djikstra {

        # Called by $self->doDjikstra
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
                $self->_objClass . '->getSurrounding_djikstra',
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
            '<dummy room>',
            FALSE,              # Not a real world model object
        );

        $dummyRoomObj->ivPoke('number', $number);
        $self->ivAdd('modelHash', $number, $dummyRoomObj);
        $self->ivAdd('roomModelHash', $number, $dummyRoomObj);
        # (The dummy room is nominally 'in' the same region as the initial room)
        $dummyRoomObj->ivPoke('parent', $realRoomObj->parent);

        $dummyExitObj = Games::Axmud::Obj::Exit->new(
            $session,
            'dummy',            # Use a dummy direction, too!
            FALSE,              # Not a real exit model object
        );

        $dummyExitObj->ivPoke('number', $number);
        $self->ivAdd('exitModelHash', $number, $dummyExitObj);

        $dummyDir = 'djikstra_dummy_exit';

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
            $dummyDir = 'djikstra_dummy_exit';
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

    # Djikstra algorithm for GA::Obj::Route objects (used to find a path using pre-defined routes)

    sub findRoutePath {

        # Can be called by any function. Called by GA::Generic::Cmd->useRoute
        #
        # Djikstra algorithm to find a path between two rooms using interlinked pre-defined routes,
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
        # Now we run the Djikstra algorithm for route objects (a modified A* algorithm in which the
        #   h-score is always 0) to get the shortest path between the initial and target rooms

        # Create the open list, using a binomial heap
        $openListObj = Heap::Binomial->new();
        # Create a reference to a hash of nodes, in the form
        #   $hash{room_tag} = djikstra_node
        $nodeHashRef = {};

        # Create a node for the initial room
        $currentNode = Games::Axmud::Node::Djikstra->new(
            0,                      # Initial G score
            undef,                  # (Exit objects not used for pre-defined routes)
            $initialRoomTag,        # Room tag of the first room object
        );

        # Add this node to the open list
        $currentNode->ivPoke('inOpenFlag', TRUE);
        $openListObj->add($currentNode);

        # Perform the Djikstra algorithm, starting at the room tagged $initialRoomTag, and aiming
        #   for the room tagged $targetRoomTag
        $self->doRouteDjikstra($targetRoomTag, $openListObj, $nodeHashRef, \%routePathHash);

        # We can now use the nodes stored in $openListObj to find the shortest route, by tracing the
        #   path from the target room, and using the parent of each node in turn (in the standard
        #   way)
        # Get a list reference, containing the list of world to move between the initial and target
        #   rooms
        $cmdListRef = $self->fillPath_routeDjikstra(
            $targetRoomTag,
            $openListObj,
            $nodeHashRef,
            \%routePathHash,
        );

        return $cmdListRef;
    }

    sub doRouteDjikstra {

        # Called by $self->findRoutePath
        # Performs the Djikstra algorithm on two nodes, each corresponding to a room tag, in order
        #   to find the shortest path between them, and therefore the shortest path between two
        #   rooms (as described in the comments for the calling function)
        #
        # Expected arguments
        #   $targetNode     - The target node (a room tag)
        #   $openListObj    - The Djikstra open list, stored in a binomial heap object
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
            return $axmud::CLIENT->writeImproper($self->_objClass . '->doRouteDjikstra', @_);
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
            $nodeListRef = $self->getSurrounding_routeDjikstra(
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

                    $surroundNode = Games::Axmud::Node::Djikstra->new(
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

        # Djikstra algorithm complete
        return 1;
    }

    sub fillPath_routeDjikstra {

        # Called by $self->findRoutePath, after a call to $self->doRouteDjikstra
        # The initial room and the target room are now linked, along the shortest path between them,
        #   by a list of nodes, each corresponding to a room tag
        # Compile a list of world commands to travel along this path, from the initial room to the
        #   target room
        #
        # Expected arguments
        #   $targetNode     - The target node (a room tag)
        #   $openListRef    - The Djikstra open list, stored in a binomial heap object
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

        my ($self, $targetNode, $openListObj, $nodeHashRef, $routePathHashRef, $check) = @_;

        # Local variables
        my (
            $currentNode,
            @emptyList, @nodeList, @cmdSequenceList,
        );

        # Check for improper arguments
        if (
            ! defined $targetNode || ! defined $openListObj || ! defined $nodeHashRef
            || ! defined $routePathHashRef || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->fillPath_routeDjikstra', @_);
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

                        push (@cmdSequenceList, $routeObj->route);
                    }
                }

            } until (@nodeList < 2);
        }

        return \@cmdSequenceList;
    }

    sub getSurrounding_routeDjikstra {

        # Called by $self->doRouteDjikstra
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
                $self->_objClass . '->getSurrounding_routeDjikstra',
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
        #   e.g. 'Two big guards, a troll and three small torches.'
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
                $self->writeDebug('   multiple flag ON');
            } else {
                $self->writeDebug('   multiple flag OFF');
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
                $pattern, $backRef, $string, $numberFlag,
                @wordList,
            );

            # Special case: if the string matches the current world's ->multiplePattern, use that as
            #   the multiple (and remove it)
            $pattern = $worldObj->multiplePattern;
            if ($pattern && $thingArray[0][$count] =~ m/$pattern/) {

                $backRef = $1;
                if ($backRef && $backRef =~ m/^\d+$/ && $backRef > 0) {

                    # Set the multiple
                    $thingArray[2][$count] = $backRef;
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
        #   [0] = two big evil guards   [0] big evil guards [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torches   [2] 3   [2] small torches   [2] undef
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

                my ($singular, $undeclined);

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
        #   [0] = two big evil guards   [0] big evil guards [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torches   [2] 3   [2] small torches   [2] undef
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
        #   [0] = two big evil guards   [0] big evil guards [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torches   [2] 3   [2] small torches   [2] undef
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
        #   [0] = two big evil guards   [0] big evil guards [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torches   [2] 3   [2] small torches   [2] undef
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
        #   [0] = two big evil guards   [0] big evil guards [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torches   [2] 3   [2] small torches   [2] undef
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
        #   [0] = two big evil guards   [0] big evil guards [0] 2   [0] big evil guards [0] undef
        #   [1] = a troll               [1] troll           [1] 1   [1] troll           [1] undef
        #   [2] = three small torches   [2] small torches   [2] 3   [2] small torches   [2] undef
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

            $self->writeDebug('->parseObj, objects parsed: ' . $thingCount);

            OUTER: for (my $rowCount = 0; $rowCount < $thingCount; $rowCount++) {

                $self->writeDebug('   Object #' . ($rowCount + 1));

                INNER: for (my $columnCount = 0; $columnCount < 14; $columnCount++) {

                    $self->writeDebug(
                        '      Column ' . $columnCount . ' ' . $columnList[$columnCount],
                    );

                    if (defined $thingArray[$columnCount][$rowCount]) {
                        $self->writeDebug('      ' . $thingArray[$columnCount][$rowCount]);
                    } else {
                        $self->writeDebug('      <undef>');
                    }
                }
            }
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
            $departRoomObj, $arriveRoomObj, $regionObj, $regionmapObj, $mapDir,
            $listRef, $xPos, $yPos, $zPos, $xVector, $yVector, $zVector, $count,
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
        $regionObj = $self->ivShow('modelHash', $departRoomObj->parent);
        $regionmapObj = $self->ivShow('regionmapHash', $regionObj->name);

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

    sub defaultBackgroundColour
        { $_[0]->{defaultBackgroundColour} }
    sub defaultNoBackgroundColour
        { $_[0]->{defaultNoBackgroundColour} }
    sub defaultRoomColour
        { $_[0]->{defaultRoomColour} }
    sub defaultRoomTextColour
        { $_[0]->{defaultRoomTextColour} }
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

    sub backgroundColour
        { $_[0]->{backgroundColour} }
    sub noBackgroundColour
        { $_[0]->{noBackgroundColour} }
    sub roomColour
        { $_[0]->{roomColour} }
    sub roomTextColour
        { $_[0]->{roomTextColour} }
    sub borderColour
        { $_[0]->{borderColour} }
    sub currentBorderColour
        { $_[0]->{currentBorderColour} }
    sub currentFollowBorderColour
        { $_[0]->{currentFollowBorderColour} }
    sub currentWaitBorderColour
        { $_[0]->{currentWaitBorderColour} }
    sub currentSelectBorderColour
        { $_[0]->{currentSelectBorderColour} }
    sub lostBorderColour
        { $_[0]->{lostBorderColour} }
    sub lostSelectBorderColour
        { $_[0]->{lostSelectBorderColour} }
    sub ghostBorderColour
        { $_[0]->{ghostBorderColour} }
    sub ghostSelectBorderColour
        { $_[0]->{ghostSelectBorderColour} }
    sub selectBorderColour
        { $_[0]->{selectBorderColour} }
    sub roomAboveColour
        { $_[0]->{roomAboveColour} }
    sub roomBelowColour
        { $_[0]->{roomBelowColour} }
    sub roomTagColour
        { $_[0]->{roomTagColour} }
    sub selectRoomTagColour
        { $_[0]->{selectRoomTagColour} }
    sub roomGuildColour
        { $_[0]->{roomGuildColour} }
    sub selectRoomGuildColour
        { $_[0]->{selectRoomGuildColour} }
    sub exitColour
        { $_[0]->{exitColour} }
    sub selectExitColour
        { $_[0]->{selectExitColour} }
    sub selectExitTwinColour
        { $_[0]->{selectExitTwinColour} }
    sub selectExitShadowColour
        { $_[0]->{selectExitShadowColour} }
    sub randomExitColour
        { $_[0]->{randomExitColour} }
    sub impassableExitColour
        { $_[0]->{impassableExitColour} }
    sub dragExitColour
        { $_[0]->{dragExitColour} }
    sub exitTagColour
        { $_[0]->{exitTagColour} }
    sub selectExitTagColour
        { $_[0]->{selectExitTagColour} }
    sub mapLabelColour
        { $_[0]->{mapLabelColour} }
    sub selectMapLabelColour
        { $_[0]->{selectMapLabelColour} }

    sub defaultRoomFilterList
        { my $self = shift; return @{$self->{defaultRoomFilterList}}; }
    sub defaultRoomFilterHash
        { my $self = shift; return %{$self->{defaultRoomFilterHash}}; }
    sub defaultRoomFlagTextHash
        { my $self = shift; return %{$self->{defaultRoomFlagTextHash}}; }
    sub defaultRoomFlagPriorityHash
        { my $self = shift; return %{$self->{defaultRoomFlagPriorityHash}}; }
    sub defaultRoomFlagFilterHash
        { my $self = shift; return %{$self->{defaultRoomFlagFilterHash}}; }
    sub defaultRoomFlagColourHash
        { my $self = shift; return %{$self->{defaultRoomFlagColourHash}}; }
    sub defaultRoomFlagDescripHash
        { my $self = shift; return %{$self->{defaultRoomFlagDescripHash}}; }
    sub defaultRoomFlagOrderedList
        { my $self = shift; return @{$self->{defaultRoomFlagOrderedList}}; }
    sub defaultRoomFlagReverseHash
        { my $self = shift; return %{$self->{defaultRoomFlagReverseHash}}; }

    sub roomFilterList
        { my $self = shift; return @{$self->{roomFilterList}}; }
    sub roomFilterHash
        { my $self = shift; return %{$self->{roomFilterHash}}; }
    sub roomFlagTextHash
        { my $self = shift; return %{$self->{roomFlagTextHash}}; }
    sub roomFlagPriorityHash
        { my $self = shift; return %{$self->{roomFlagPriorityHash}}; }
    sub roomFlagFilterHash
        { my $self = shift; return %{$self->{roomFlagFilterHash}}; }
    sub roomFlagColourHash
        { my $self = shift; return %{$self->{roomFlagColourHash}}; }
    sub roomFlagDescripHash
        { my $self = shift; return %{$self->{roomFlagDescripHash}}; }
    sub roomFlagOrderedList
        { my $self = shift; return @{$self->{roomFlagOrderedList}}; }
    sub roomFlagReverseHash
        { my $self = shift; return %{$self->{roomFlagReverseHash}}; }
    sub allRoomFiltersFlag
        { $_[0]->{allRoomFiltersFlag} }

    sub roomTerrainInitHash
        { my $self = shift; return %{$self->{roomTerrainInitHash}}; }
    sub roomTerrainHash
        { my $self = shift; return %{$self->{roomTerrainHash}}; }

    sub currentRoomMode
        { $_[0]->{currentRoomMode} }
    sub roomInteriorMode
        { $_[0]->{roomInteriorMode} }

    sub drawExitMode
        { $_[0]->{drawExitMode} }
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
    sub autoCompareFlag
        { $_[0]->{autoCompareFlag} }
    sub followAnchorFlag
        { $_[0]->{followAnchorFlag} }
    sub capitalisedRoomTagFlag
        { $_[0]->{capitalisedRoomTagFlag} }
    sub showTooltipsFlag
        { $_[0]->{showTooltipsFlag} }
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
    sub painterIVList
        { my $self = shift; return @{$self->{painterIVList}}; }
    sub paintAllRoomsFlag
        { $_[0]->{paintAllRoomsFlag} }

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
}

# Package must return true
1
