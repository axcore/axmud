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
# Games::Axmud::Obj::Exit
# An exit in the exit model

{ package Games::Axmud::Obj::Exit;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the exit object (which represents an exit between two rooms in
        #   the world, one of which may be unknown)
        #
        # Expected arguments
        #   $session        - The parent GA::Session (not stored as an IV)
        #   $dir            - The exit's nominal direction - the one that would be expected to
        #                       appear in the parent room's list of exits, e.g. 'north', 'portal'
        #                       (absolute max length 64 chars; can include spaces and
        #                       non-alphanumeric characters)
        #   $modelFlag      - TRUE if this is an exit model object, FALSE if it's a non-exit model
        #                       object
        #
        # Optional arguments
        #   $parentRoom     - World model number of the parent room ('undef' if there isn't a parent
        #                       room or it this is a non-exit model object)
        #
        # Return values
        #   'undef' on improper arguments or if $nomDir is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $dir, $modelFlag, $parentRoom, $check) = @_;

        # Local variables
        my ($string, $parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $dir || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $dir isn't longer than the maximum
        if (length ($dir) > 64) {

            if (! $session->loginFlag) {

                # Not logged in yet - the illegal direction is probably some graphics displayed by
                #   the world on connection, not something that's part of a list of exits
                # Don't display an error message
                return undef;

            } else {

                # Reduce $dir to a manageably short string, so that the error message doesn't
                #   take up several lines
                $dir = substr($dir, 0, 64);
                # Reduce uninformative whitespace
                $dir =~ s/\s+/ /g;

                # If the automapper has a current room, we should use it in the error message
                if ($session->mapObj->currentRoom) {
                    $string = ' (automapper current room: ' . $session->mapObj->currentRoom->number
                                . ')';
                } else {
                    $string = '';
                }

                return $axmud::CLIENT->writeError(
                    'Illegal direction \'' . $dir . '...\' (max 32 chars)' . $string,
                    $class . '->new',
                );
            }
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = {
            _objName                    => $dir,
            _objClass                   => $class,
            _parentFile                 => $parentFile,     # May be 'undef'
            _parentWorld                => $parentProf,     # May be 'undef'
            _privFlag                   => FALSE,           # All IVs are public

            # Compatibility IVs
            # -----------------

            # Used for compatibility with model objects (inheriting GA::Generic::ModelObj)
            name                        => $dir,
            category                    => 'exit',
            modelFlag                   => $modelFlag,
            number                      => undef,           # Set later
            parent                      => $parentRoom,

            # Exit IVs
            # --------

            # Private property hash - customisable hash of properties for the exit
            privateHash                 => {},

            # IVs unique to exit model objects
            # What type of exit this is - 'primaryDir', 'primaryAbbrev', 'secondaryDir',
            #   'secondaryAbbrev' ('undef' for other kinds of exit, or if type unknown. Matches a
            #   value in the dictionary object's ->combDirHash)
            exitType                    => undef,

            # The exit's nominal direction - the one that would be expected to appear in the parent
            #   room's list of exits, e.g. 'north', 'portal' (absolute max length 32 chars; can
            #   include spaces and non-alphanumeric characters)
            dir                         => $dir,
            # For primary directions, the standard primary direction that corresponds to $self->dir
            #   (which is a custom primary direction)
            # For other directions, one of eighteen standard primary directions (north, northeast,
            #   east, southeast, south, southwest, west, northwest, up, down, and northnortheast
            #   etc) which isn't already in use, and which the automapper can use to draw this
            #   direction
            # (Set to 'undef' if the exit is unallocatable, i.e. there are no available primary
            #   directions that can be allocated to it)
            mapDir                      => undef,
            # When ->dir isn't a primary direction, ->mapDir is temporarily allocated one of
            #   the sixteen available cardinal directions (the primary directions minus 'up' and
            #   'down'), so the exit can be drawn on the map
            # This IV tracks what is happening and tells the automapper how to draw the exit
            #   'primary' - ->dir is a primary direction
            #   'temp_alloc' - ->dir is not a primary direction. The exit has been allocated a
            #       temporary cardinal direction from one of the sixteen available cardinal
            #       directions (those not in use by other exits); this temporary direction is stored
            #       in ->mapDir
            #   'temp_unalloc' - ->dir is not a primary direction. The exit has not been allocated a
            #       temporary cardinal direction because none of them are available (all in use by
            #       by other exits); ->mapDir is still 'undef'
            #   'perm_alloc' - the user has allocated a permanent primary direction (the automapper
            #       can only allocate the sixteen cardinal directions as temporary directions, but
            #       the user can allocate all eighteen primary directions), which is stored in
            #       ->mapDir
            drawMode                    => 'primary',

            # The exit's tag, if it has been given one, used to display the destination region.
            #   Maximum 40 characters (allows for the region name, which has a maximum of 32 chars,
            #   plus a word like 'to')
            exitTag                     => undef,
            # The offset (in pixels) where the exit tag is drawn on the map. (0, 0) means draw the
            #   tag at the standard position; (10, -10) means draw it 10 pixels to the right, 10
            #   pixels higher
            exitTagXOffset              => 0,
            exitTagYOffset              => 0,

            # Flag set to TRUE if this exit should be drawn as a broken exit (leads to a room at an
            #   arbitrary position in the same region), FALSE if not a broken exit
            brokenFlag                  => FALSE,
            # Flag set to TRUE if this is a broken exit that should be drawn as a bent line; set to
            #   FALSE if the exit should be drawn as a simple square, attached to its room
            bentFlag                    => FALSE,
            # For bent broken exits, a list of offsets in the form (x, y, x, y...) indicating the
            #   bends in the line, relative to the start of the bending section of the exit (at the
            #   edge of the parent room's gridblock). An empty list of the 'bent' section is
            #   straight
            bendOffsetList              => [],
            # Flag set to TRUE if this exit is a region exit (leads to a room in a different
            #   region), FALSE if not a region exit
            regionFlag                  => FALSE,
            # For a region that has 100s of region exits, the world model would have to recalculate
            #   thousands of region paths every time someone deletes an exit. So that we can
            #   drastically reduce this number, when a region has several region exits all leading
            #   to the same other region, only one of them is usually marked as being a
            #   'super-region' exit (the one used for pathfinding). The user can change the
            #   super-region exit, or add additional ones, if they want
            # Flag set to TRUE if this is a region exit AND a super-region exit; FALSE otherwise
            superFlag                   => FALSE,
            # Flag set to TRUE if this exit was a super-region exit, but was converted to a normal
            #   exit by the user; it can only be converted back to a super-region exit by the user
            #   (and can't be converted automatically by, for example,
            #   GA::Obj::WorldModel->updateRegionPaths). Set to FALSE otherwise
            notSuperFlag                => FALSE,
            # Flag set to TRUE if the exit is 'hidden' - i.e. doesn't appear in the room's exit
            #   list, but exists nonetheless (NB this isn't an ornament)
            hiddenFlag                  => FALSE,
            # What kind of random exit this is:
            #   'none' - not a random exit
            #   'same_region' - a random exit leading somewhere in the same region
            #   'any_region' - a random exit leading anywhere
            #   'room_list' - a random exit leading to one of a defined list of rooms
            randomType                  => 'none',
            # For ->randomType 'room_list', a list of destination room numbers. Ignored when
            #   ->randomType is not 'room_list'. When the character moves through a random exit, the
            #   Locator task's current room is compared to each of these rooms, in the order in
            #   which they're stored
            randomDestList              => [],

            # Number of the world model room, to which this exit leads ('undef' if unknown)
            destRoom                    => undef,
            # Exit model number of the destination room's exit that is the opposite of this one
            #   ('undef' if this isn't a known two-way exit)
            twinExit                    => undef,
            # Flag set to TRUE if this is a known uni-directional exit (e.g. you can go north from A
            #   to B, but you can't go south from B to A), FALSE if not
            oneWayFlag                  => FALSE,
            # For one-way exits, the primary direction in which the far end of a one-way exit as
            #   drawn (i.e. where it touches the destination room). By default, the opposite of this
            #   exit's ->mapDir (so if the exit leads east, it touches the destination room at the
            #   point, where a hypothetical west exit would be drawn)
            # For non-one way exits, set to 'undef'
            # NB For unallocated exits, ->mapDir is 'undef', so ->oneWayDir gets set to an
            #   emergency default value, 'north'
            oneWayDir                   => undef,
            # Flag set to TRUE if this is a retracing exit (a special kind of one-way exit which
            #   leads back to the room), FALSE if not. When this flag is set, ->oneWayFlag is not
            #   set
            retraceFlag                 => FALSE,
            # If this exit leads to exactly the same room as another one (e.g. if 'enter cave' leads
            #   to the same room as 'west'), there's no need to draw both of them on the map. If
            #   'enter cave' is this exit, then 'west' is this exit's 'shadow exit'; this exit is
            #   not drawn by the map (because 'west' will be drawn instead)
            # The exit model number of the shadow exit (or 'undef' if no shadow exit)
            shadowExit                  => undef,

            # Exit ornament flags
            # Flag set to TRUE if this is a door which can be broken down (if locked), FALSE if not
            breakFlag                   => FALSE,
            # Flag set to TRUE if this exit is a pickable lock, FALSE if not
            pickFlag                    => FALSE,
            # Flag set to TRUE if this exit is some kind of lockable door, FALSE if not
            lockFlag                    => FALSE,
            # Flag set to TRUE if this exit is some kind of door (is openable), FALSE if not
            openFlag                    => FALSE,
            # Flag set to TRUE if this exit is completely impassable, FALSE if not
            impassFlag                  => FALSE,
            # Flag set to TRUE if any of the ornament flags are set to TRUE (for quick checking),
            #   FALSE if not
            ornamentFlag                => FALSE,

            # The exit's current state, if known. Possible values are 'normal' (exit is passable or
            #   state not known), 'open' (exit is an open door), 'closed' (exit is a closed door),
            #   'locked' (exit is a locked door), 'secret' (exit is secret, not normally visible),
            #   'secret_open' (exit is a secret open door), 'secret_closed' (exit is a secret
            #   closed door'), 'secret_locked' (exit is a secret locked door), 'impass' (exit is
            #   impassable), 'dark' (exit's destination room is dark), 'danger' (exit's destination
            #   room is dangerous), 'other' (some other situation, known only to the user, when the
            #   exit is surrounded by exit state strings defined in
            #   GA::Profile::World->exitStateOtherList)
            # NB ->exitState is never set to 'ignore'. When the exit is surrounded by exit state
            #   strings defined in GA::Profile::World->exitStateIgnoreList, this IV is not modified
            #   (but the state strings are still removed)
            exitState                   => 'normal',
            # Any information about the exit (usually a string describing the destination, or
            #   occasionally the destination type). Set only if one of the patterns in
            #   GA::Profile::World->exitInfoPatternList matches the exit, when it appears in a room
            #   statement exit list; the first backreference (if any) is used to set this IV
            info                        => undef,

            # Hash of commands used during assisted moves, in the form
            #   $assistedHash{profile_name} = sequence_of_commands
            # e.g.
            #   $assistedHash{'wizard'} = 'wave wand;fly across river'
            #   $assistedHash{'bilbo'} = 'wear ring;squeeze past guards'
            # During an assisted move, the key-value pair for the highest-priority current profile
            #   found in the hash is used. If none are found, the IVs below are consulted; if all
            #   else fails, the value of $self->dir is used (see the comments in
            #   $self->getAssisted() for a full explanation)
            assistedHash                => {},

            # Hashes that can be used by the automapper in 'assisted moves' mode to automatically
            #   get through openable/lockable doors
            # Each hash is usually empty, or contains a single key-value pair. If it contains
            #   multiple key-value pairs, the automapper will try them all

            # Hash of model objects required to break down the door (empty if it's not breakable),
            #   in the form
            #       $breakHash{world_model_obj_number} = 'command_to_break_down_door'
            # Usually contains a single key-value pair. If the value is 'undef', the standard
            #   'break_with' command (defined in the command cage) is used instead
            breakHash                   => {},
            # Hash of model objects required to pick the door lock (empty if it's not pickable), in
            #   the form
            #       $pickHash{world_model_obj_number} = 'command_to_pick_lock'
            # Usually contains a single key-value pair. If the value is 'undef', the standard
            #   'pick_with' command (defined in the command cages) is used instead
            pickHash                    => {},
            # Hash of model objects required to unlock the door (empty if it's not lockable), in the
            #   form
            #       $unlockHash{world_model_obj_number} = 'command_to_unlock'
            # Usually contains a single key-value pair. If the value is 'undef', the standard
            #   'unlock_with' command (defined in the command cages) is used instead
            unlockHash                  => {},
            # Hash of model objects required to open the door (empty if it's not openable), in the
            #   form
            #       $openHash{world_model_obj_number} = 'command_to_open'
            # Usually contains a single key-value pair. If the value is 'undef', the standard
            #   'open_dir' command (defined in the command cages) is used instead
            openHash                    => {},
            # Hash of model objects required to close the door (empty if it's not openable), in the
            #   form
            #       $closeHash{world_model_obj_number} = 'command_to_close'
            # Usually contains a single key-value pair. If the value is 'undef', the standard
            #   'close_dir' command (defined in the command cages) is used instead
            closeHash                   => {},
            # Hash of model objects required to lock the door (empty if it's not lockable), in the
            #   form
            #       $lockHash{world_model_obj_number} = 'command_to_lock'
            # Usually contains a single key-value pair. If the value is 'undef', the standard
            #   'lock_with' command (defined in the command cages) is used instead
            lockHash                    => {},

            # Command to break down the door - a simple string, if you don't want to go to the
            #   trouble of defining model objects (e.g. 'break door with crowbar') - if
            #   $self->breakHash is empty, this command is used instead. If this IV is set to
            #   'undef', the standard 'break' command (defined in the command cages) is used
            breakCmd                    => undef,
            # Command to pick the door lock - a simple string, if you don't want to go to the
            #   trouble of defining model objects (e.g. 'pick north door with red lockpick') - if
            #   $self->pickHash is empty, this command is used instead. If this IV is set to
            #   'undef', the standard 'pick' command (defined in the command cages) is used
            pickCmd                     => undef,
            # Command to unlock the door - a simple string, if you don't want to go to the trouble
            #   of defining model objects (e.g. 'unlock north door with red key') - if
            #   $self->unlockHash is empty, this command is used instead. If this IV is set to
            #   'undef', the standard 'unlock' command (defined in the command cages) is used
            unlockCmd                   => undef,
            # Command to open the door - a simple string, if you don't want to go to the trouble of
            #   defining model objects (e.g. 'open north door') - if $self->openHash is empty, this
            #   command is used instead. If this IV is set to 'undef', the standard 'open_dir'
            #   command (defined in the command cages) is used
            openCmd                     => undef,
            # Command to close the door - a simple string, if you don't want to go to the trouble of
            #   defining model objects (e.g. 'close north door') - if $self->openHash is empty, this
            #   command is used instead. If this IV is set to 'undef', the standard 'close_dir'
            #   command (defined in the command cages) is used
            closeCmd                    => undef,
            # Command to unlock the door - a simple string, if you don't want to go to the trouble
            #   of defining model objects (e.g. 'lock north door with red key') - if $self->lockHash
            #   is empty, this command is used instead. If this IV is set to 'undef', the standard
            #   'lock' command (defined in the command cages) is used
            lockCmd                     => undef,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub getAssisted {

        # Called by GA::Session->checkAssistedMove
        # Checks several of this object's IVs and returns a sequence of one or more commands,
        #   separated by Axmud's command separator, as a string
        #
        # The IVs are checked in the order
        #   1. ->assistedHash
        #   2. ->breakHash, ->pickHash, ->unlockHash, ->openHash, ->closeHash, ->lockHash
        #   3. ->breakCmd, ->pickCmd, ->unlockCmd, ->openCmd, ->closeCmd, ->lockCmd
        #   4. ->dir
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments or if no assisted move can be found
        #   Otherwise, a sequence of one or more commands, e.g. 'open door;north'

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $wmObj, $cmdString, $cmd,
            @priorityList, @breakList, @pickList, @unlockList, @openList, @closeList, @lockList,
            @cmdList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getAssisted', @_);
        }

        # Import the world model object (for convenience)
        $wmObj = $session->worldModelObj;

        # 1. ->assistedHash
        # -----------------

        # Import the session's profile priority list
        @priorityList = $session->profPriorityList;

        # Check each category of profile in turn
        foreach my $category (@priorityList) {

            my $profObj = $session->ivShow('currentProfHash', $category);
            if ($profObj && $self->ivExists('assistedHash', $profObj->name)) {

                # A complete assisted move is available for this profile
                return $self->ivShow('assistedHash', $profObj->name);
            }
        }

        # 2. ->breakHash, ->pickHash, etc
        # -------------------------------

        # These IVs should contain, ideally, only one key-value pair; if they contain more than
        #   one pair, use them all (hoping one command sequence will work)

        if ($wmObj->assistedBreakFlag && $self->breakFlag && $self->breakHash) {

            push (@breakList, $self->ivValues('breakHash'));
        }

        if ($wmObj->assistedPickFlag && $self->pickFlag && $self->pickHash) {

            push (@pickList, $self->ivValues('pickHash'));
        }

        if ($wmObj->assistedUnlockFlag && $self->lockFlag && $self->unlockHash) {

            push (@unlockList, $self->ivValues('unlockHash'));
        }

        if ($wmObj->assistedOpenFlag && $self->openFlag && $self->openHash) {

            push (@openList, $self->ivValues('openHash'));
        }

        if ($wmObj->assistedCloseFlag && $self->openFlag && $self->closeHash) {

            push (@closeList, $self->ivValues('closeHash'));
        }

        if ($wmObj->assistedLockFlag && $self->lockFlag && $self->lockHash) {

            push (@lockList, $self->ivValues('lockHash'));
        }

        # 3. ->breakCmd, ->pickCmd, etc
        # -----------------------------

        # Only consult the IVs for which the corresponding part 2 IVs yielded nothing

        if ($wmObj->assistedBreakFlag && $self->breakFlag && ! @breakList) {

            if ($self->breakCmd) {

                push (@breakList, $self->breakCmd);

            } else {

                # Use the command cage's standard 'break' command, if it is set
                $cmd = $session->prepareCmd('break', 'direction', $self->dir);
                if ($cmd) {

                    push (@breakList, $cmd);
                }
            }
        }

        if ($wmObj->assistedPickFlag && $self->pickFlag && ! @pickList) {

            if ($self->pickCmd) {

                push (@pickList, $self->pickCmd);

            } else {

                # Use the command cage's standard 'pick' command, if it is set
                $cmd = $session->prepareCmd('pick', 'direction', $self->dir);
                if ($cmd) {

                    push (@pickList, $cmd);
                }
            }
        }

        if ($wmObj->assistedUnlockFlag && $self->lockFlag && ! @unlockList) {

            if ($self->unlockCmd) {

                push (@unlockList, $self->unlockCmd);

            } else {

                # Use the command cage's standard 'unlock' command, if it is set
                $cmd = $session->prepareCmd('unclock', 'direction', $self->dir);
                if ($cmd) {

                    push (@unlockList, $cmd);
                }
            }
        }

        if ($wmObj->assistedOpenFlag && $self->openFlag && ! @openList) {

            if ($self->openCmd) {

                push (@openList, $self->openCmd);

            } else {

                # Use the command cage's standard 'open_dir' command, if it is set
                $cmd = $session->prepareCmd('open_dir', 'direction', $self->dir);
                if ($cmd) {

                    push (@openList, $cmd);
                }
            }
        }

        if ($wmObj->assistedCloseFlag && $self->openFlag && ! @closeList) {

            if ($self->closeCmd) {

                push (@closeList, $self->closeCmd);

            } else {

                # Use the command cage's standard 'close_dir' command, if it is set
                $cmd = $session->prepareCmd('close_dir', 'direction', $self->dir);
                if ($cmd) {

                    push (@closeList, $cmd);
                }
            }
        }

        if ($wmObj->assistedLockFlag && $self->lockFlag && ! @lockList) {

            if ($self->lockCmd) {

                push (@lockList, $self->lockCmd);

            } else {

                # Use the command cage's standard 'lock' command, if it is set
                $cmd = $session->prepareCmd('lock', 'direction', $self->dir);
                if ($cmd) {

                    push (@lockList, $cmd);
                }
            }
        }

        # 4. ->dir
        # --------

        # Now, combine the six lists into a single list and insert the actual direction of movement,
        #   $self->dir, in the right place

        if (@breakList) {

            # Don't try to close or lock a door which has been broken down
            @cmdList = (@breakList, $self->dir);

        } elsif (@pickList) {

            @cmdList = (@pickList, @openList, $self->dir, @closeList, @lockList);

        } elsif (@unlockList) {

            @cmdList = (@unlockList, @openList, $self->dir, @closeList, @lockList);

        } elsif (@openList) {

            @cmdList = (@openList, @closeList, $self->dir, @lockList);
        }

        # Combine the commands (and sequences of commands) into a single string, with each
        #   individual world command separated from the next one by Axmud's command separator
        $cmdString = join($axmud::CLIENT->cmdSep, @cmdList);

        # Return the string
        return $cmdString;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub category
        { $_[0]->{category} }
    sub modelFlag
        { $_[0]->{modelFlag} }
    sub number
        { $_[0]->{number} }
    sub parent
        { $_[0]->{parent} }

    sub privateHash
        { my $self = shift; return %{$self->{privateHash}}; }

    sub exitType
        { $_[0]->{exitType} }

    sub dir
        { $_[0]->{dir} }
    sub mapDir
        { $_[0]->{mapDir} }
    sub drawMode
        { $_[0]->{drawMode} }

    sub exitTag
        { $_[0]->{exitTag} }
    sub exitTagXOffset
        { $_[0]->{exitTagXOffset} }
    sub exitTagYOffset
        { $_[0]->{exitTagYOffset} }

    sub brokenFlag
        { $_[0]->{brokenFlag} }
    sub bentFlag
        { $_[0]->{bentFlag} }
    sub bendOffsetList
        { my $self = shift; return @{$self->{bendOffsetList}}; }
    sub regionFlag
        { $_[0]->{regionFlag} }
    sub superFlag
        { $_[0]->{superFlag} }
    sub notSuperFlag
        { $_[0]->{notSuperFlag} }
    sub hiddenFlag
        { $_[0]->{hiddenFlag} }
    sub randomType
        { $_[0]->{randomType} }
    sub randomDestList
        { my $self = shift; return @{$self->{randomDestList}}; }

    sub destRoom
        { $_[0]->{destRoom} }
    sub twinExit
        { $_[0]->{twinExit} }
    sub oneWayFlag
        { $_[0]->{oneWayFlag} }
    sub oneWayDir
        { $_[0]->{oneWayDir} }
    sub retraceFlag
        { $_[0]->{retraceFlag} }
    sub shadowExit
        { $_[0]->{shadowExit} }

    sub breakFlag
        { $_[0]->{breakFlag} }
    sub pickFlag
        { $_[0]->{pickFlag} }
    sub lockFlag
        { $_[0]->{lockFlag} }
    sub openFlag
        { $_[0]->{openFlag} }
    sub impassFlag
        { $_[0]->{impassFlag} }
    sub ornamentFlag
        { $_[0]->{ornamentFlag} }

    sub exitState
        { $_[0]->{exitState} }
    sub info
        { $_[0]->{info} }

    sub assistedHash
        { my $self = shift; return %{$self->{assistedHash}}; }

    sub breakHash
        { my $self = shift; return %{$self->{breakHash}}; }
    sub pickHash
        { my $self = shift; return %{$self->{pickHash}}; }
    sub unlockHash
        { my $self = shift; return %{$self->{unlockHash}}; }
    sub openHash
        { my $self = shift; return %{$self->{openHash}}; }
    sub closeHash
        { my $self = shift; return %{$self->{closeHash}}; }
    sub lockHash
        { my $self = shift; return %{$self->{lockHash}}; }

    sub breakCmd
        { $_[0]->{breakCmd} }
    sub pickCmd
        { $_[0]->{pickCmd} }
    sub unlockCmd
        { $_[0]->{unlockCmd} }
    sub openCmd
        { $_[0]->{openCmd} }
    sub closeCmd
        { $_[0]->{closeCmd} }
    sub lockCmd
        { $_[0]->{lockCmd} }
}

# Package must return true
1
