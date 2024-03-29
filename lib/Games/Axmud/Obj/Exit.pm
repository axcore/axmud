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
# Games::Axmud::Obj::Exit
# An exit in the exit model

{ package Games::Axmud::Obj::Exit;

    use strict;
    use warnings;
#   use diagnostics;

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
        #   $mode           - 'model' for an exit model object (stored in
        #                       GA::Obj::WorldModel->exitModelHash), 'non_model' for non-model
        #                       exit object, for example one used by the Locator task, or 'global'
        #                       for the exit object stored in the global variable $DEFAULT_EXIT (and
        #                       which provides default values for all exit object IVs)
        #
        # Optional arguments
        #   $parentRoom     - World model number of the parent room ('undef' if there isn't a parent
        #                       room or it this is a non-exit model object)
        #
        # Return values
        #   'undef' on improper arguments or if $nomDir is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $dir, $mode, $parentRoom, $check) = @_;

        # Local variables
        my $string;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $dir || ! defined $mode
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

            } elsif ($axmud::CLIENT->debugExitFlag) {

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

                return $session->mainWin->writeDebug(
                    'Illegal direction \'' . $dir . '...\' (max 64 chars)' . $string,
                );

            } else {

                # No debug message to display
                return undef;
            }
        }

        # For very large world models (10,000+ rooms), some computers tend to run out of memory
        #   which produces a Perl error and a crash
        # In response, we try to reduce the size of the world model as much as possible. Most of the
        #   memory used is for room objects (GA::ModelObj::Room) and exit objects. Most of the
        #   memory used by each of those objects is for IVs with default values
        # Therefore, we remove most of the IVs altogether, restoring them only if some part of the
        #   Axmud code sets the IV to a non-default value. Default values for each IV are obtained
        #   from an exit object stored in a global variable, $DEFAULT_EXIT, instead of from the exit
        #   object itself
        my $self;

        if ($mode eq 'global') {

            # This object is to be stored in the global variable, $DEFAULT_EXIT. Therefore it has
            #   default values for all IVs
            $self = {
                _objName                    => 'exit',
                _objClass                   => $class,
                _parentFile                 => undef,
                _parentWorld                => undef,
                _privFlag                   => FALSE,           # All IVs are public

                # Compatibility IVs
                # -----------------

                # Used for compatibility with model objects (inheriting GA::Generic::ModelObj)
                name                        => 'exit',
                category                    => 'exit',
                modelFlag                   => FALSE,
                number                      => undef,
                parent                      => undef,

                # Exit IVs
                # --------

                # Private property hash - customisable hash of properties for the exit
                privateHash                 => {},

                # IVs unique to exit model objects
                # What type of exit this is - 'primaryDir', 'primaryAbbrev', 'secondaryDir',
                #   'secondaryAbbrev', 'relativeDir', 'relativeAbbrev'
                # 'undef' for other kinds of exit, or if type unknown. Matches a value in the
                #   dictionary object's ->combDirHash)
                exitType                    => undef,

                # The exit's nominal direction - the one that would be expected to appear in the
                #   parent room's list of exits, e.g. 'north', 'portal' (absolute max length 32
                #   chars; can include spaces and non-alphanumeric characters)
                dir                         => undef,
                # A string if alternative nominal directions (for worlds like Discworld, in which
                #   the same exit might be called 'forwards' or 'backwards', depending on which
                #   direction the character arrived from)
                # The nominal direction (->dir) of exits in the Locator task's current room is
                #   compared against model exits' ->altDir in a Perl index operation. If ->dir is
                #   found somewhere in ->altDir, the exits are a match (e.g. ->dir 'right', ->altDir
                #   'left right' produces a match)
                # Set to 'undef' for all exits that don't have alternative nominal directions
                altDir                      => undef,
                # For primary directions, the standard primary direction that corresponds to
                #   $self->dir (which is a custom primary direction)
                # For other directions, one of eighteen standard primary directions (north,
                #   northeast, east, southeast, south, southwest, west, northwest, up, down, and
                #   northnortheast etc) which isn't already in use, and which the automapper can use
                #   to draw this direction
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
                #       directions (those not in use by other exits); this temporary direction is
                #       stored in ->mapDir
                #   'temp_unalloc' - ->dir is not a primary direction. The exit has not been
                #       allocated a temporary cardinal direction because none of them are available
                #       (all in use by by other exits); ->mapDir is still 'undef'
                #   'perm_alloc' - the user has allocated a permanent primary direction (the
                #       automapper can only allocate the sixteen cardinal directions as temporary
                #       directions, but the user can allocate all eighteen primary directions),
                #       which is stored in ->mapDir
                drawMode                    => 'primary',

                # The exit's tag, if it has been given one, used to display the destination region.
                #   Maximum 40 characters (allows for the region name, which has a maximum of 32
                #   chars, plus a word like 'to')
                exitTag                     => undef,
                # The offset (in pixels) where the exit tag is drawn on the map. (0, 0) means draw
                #   the tag at the standard position; (10, -10) means draw it 10 pixels to the
                #   right, 10 pixels higher
                exitTagXOffset              => 0,
                exitTagYOffset              => 0,

                # Flag set to TRUE if this exit should be drawn as a broken exit (leads to a room at
                #   an arbitrary position in the same region), FALSE if not a broken exit
                brokenFlag                  => FALSE,
                # Flag set to TRUE if this is a broken exit that should be drawn as a bent line; set
                #   to FALSE if the exit should be drawn as a simple square, attached to its room
                bentFlag                    => FALSE,
                # For bent broken exits, a list of offsets in the form (x, y, x, y...) indicating
                #   the bends in the line, relative to the start of the bending section of the exit
                #   (at the edge of the parent room's gridblock). An empty list of the 'bent'
                #   section is straight
                bendOffsetList              => [],
                # Flag set to TRUE if this exit is a region exit (leads to a room in a different
                #   region), FALSE if not a region exit
                regionFlag                  => FALSE,
                # For a region that has 100s of region exits, the world model would have to
                #   recalculate thousands of region paths every time someone deletes an exit. So
                #   that we can drastically reduce this number, when a region has several region
                #   exits all leading to the same other region, only one of them is usually marked
                #   as being a 'super-region' exit (the one used for pathfinding). The user can
                #   change the super-region exit, or add additional ones, if they want
                # Flag set to TRUE if this is a region exit AND a super-region exit; FALSE otherwise
                superFlag                   => FALSE,
                # Flag set to TRUE if this exit was a super-region exit, but was converted to a
                #   normal exit by the user; it can only be converted back to a super-region exit by
                #   the user (and can't be converted automatically by, for example,
                #   GA::Obj::WorldModel->updateRegionPaths). Set to FALSE otherwise
                notSuperFlag                => FALSE,
                # Flag set to TRUE if the exit is 'hidden' - i.e. doesn't appear in the room's exit
                #   list, but exists nonetheless (NB this isn't an ornament)
                hiddenFlag                  => FALSE,
                # What kind of random exit this is:
                #   'none' - not a random exit
                #   'same_region' - a random exit leading somewhere in the same region
                #   'any_region' - a random exit leading anywhere
                #   'temp_region' - a random exit leading to a temporary region, which should be
                #       created when the character passes through the exit, and destroyed when the
                #       player passes back through the exit to the original room
                #   'room_list' - a random exit leading to one of a defined list of rooms
                randomType                  => 'none',
                # For ->randomType 'room_list', a list of destination room numbers. Ignored when
                #   ->randomType is not 'room_list'. When the character moves through a random exit,
                #   the Locator task's current room is compared to each of these rooms, in the order
                #   in which they're stored
                randomDestList              => [],

                # Number of the world model room, to which this exit leads ('undef' if unknown)
                destRoom                    => undef,
                # Exit model number of the destination room's exit that is the opposite of this one
                #   ('undef' if this isn't a known two-way exit)
                twinExit                    => undef,
                # Flag set to TRUE if this is a known uni-directional exit (e.g. you can go north
                #   from A to B, but you can't go south from B to A), FALSE if not
                oneWayFlag                  => FALSE,
                # For one-way exits, the primary direction in which the far end of a one-way exit is
                #   drawn (i.e. where it touches the destination room). By default, the opposite of
                #   this exit's ->mapDir (so if the exit leads east, it touches the destination room
                #   at the point, where a hypothetical west exit would be drawn)
                # For non-one way exits, set to 'undef'
                # NB For unallocated exits, ->mapDir is 'undef', so ->oneWayDir gets set to an
                #   emergency default value, 'north'
                oneWayDir                   => undef,
                # Flag set to TRUE if this is a retracing exit (a special kind of one-way exit which
                #   leads back to the room), FALSE if not. When this flag is set, ->oneWayFlag is
                #   not set
                retraceFlag                 => FALSE,
                # If this exit leads to exactly the same room as another one (e.g. if 'enter cave'
                #   leads to the same room as 'west'), there's no need to draw both of them on the
                #   map. If 'enter cave' is this exit, then 'west' is this exit's 'shadow exit';
                #   this exit is not drawn by the map (because 'west' will be drawn instead)
                # The exit model number of the shadow exit (or 'undef' if no shadow exit)
                shadowExit                  => undef,

                # What type of exit ornament this exit has:
                #   'none' - has no ornament
                #   'break' - exit is a door which can be broken down (if locked)
                #   'pick' - exit is some kind of lockable door, that has a pickable lock
                #   'lock' - exit is some kind of lockable door
                #   'open' - exit is some kind of openable door
                #   'impass' - exit is completely impassable
                #   'mystery' - the method of going through the exit is currently unknown
                exitOrnament                => 'none',
                # The exit's current state, if known. Possible values are those specified by
                #   GA::Client->constExitStateHash: 'normal' (exit is passable or state not known),
                #   'open' (exit is an open door), 'closed' (exit is a closed door), 'locked' (exit
                #   is a locked door), 'secret' (exit is secret, not normally visible),
                #   'secret_open' (exit is a secret open door), 'secret_closed' (exit is a secret
                #   closed door'), 'secret_locked' (exit is a secret locked door), 'impass' (exit is
                #   impassable), 'dark' (exit's destination room is dark), 'danger' (exit's
                #   destination room is dangerous), 'emphasis' (world emphasises the exit in some
                #   way, for example to show an important route),  'other' (some other situation,
                #   known only to the user, when the exit is surrounded by exit state strings
                #   defined in GA::Profile::World->exitStateOtherList)
                # NB ->exitState is never set to 'ignore'. That value is used by
                #   GA::Profile::World->exitStateStringList for any symbols that look like an exit
                #   state (e.g. the bracktes in '[east]'), but which should be ignored
                # NB ->exitState is never set to one of the custom strings allowed by
                #   GA::Profile::World->exitStateStringList. If a custom string is specified there,
                #   this IV is set to the default value of 'normal'
                exitState                   => 'normal',
                # Any information about the exit (usually a string describing the destination, or
                #   occasionally the destination type). Set only if one of the patterns in
                #   GA::Profile::World->exitInfoPatternList matches the exit, when it appears in a
                #   room statement exit list; the first group substring (if any) is used to set this
                #   IV
                exitInfo                    => undef,

                # Hash of commands used during assisted moves, in the form
                #   $assistedHash{profile_name} = sequence_of_commands
                # e.g.
                #   $assistedHash{'wizard'} = 'wave wand;fly across river'
                #   $assistedHash{'bilbo'} = 'wear ring;squeeze past guards'
                # During an assisted move, the key-value pair for the highest-priority current
                #   profile found in the hash is used. If none are found, the IVs below are
                #   consulted; if all else fails, the value of $self->dir is used (see the comments
                #   in $self->getAssisted() for a full explanation)
                assistedHash                => {},
                # Commands to get past a door. The hash is empty by default, meaning that the
                #   standard break/pick/unlock/open/close/lock command, defined by command cages, is
                #   used
                # Otherwise it contains one or more key-value pairs in the general form
                #   $doorHash{door_type} = command_to_get_through_the_door
                # 'door_type' can be any of the following
                #   break       e.g. 'break door with crowbar'
                #   pick        e.g. 'pick north door with red lockpick'
                #   unlock      e.g. 'unlock north door with red key'
                #   open        e.g. 'open north door'
                #   close       e.g. 'close north door'
                #   lock        e.g. 'lock north door with red key'
                doorHash                    => {},
            };

        } elsif ($mode eq 'model') {

            # This object is stored in the world model, i.e. in GA::Obj::WorldModel->exitModelHash
            $self = {
#                _objName                    => 'exit',
#                _objClass                   => $class,
                _parentFile                 => 'worldmodel',
                _parentWorld                => $session->currentWorld->name,
#                _privFlag                   => FALSE,           # All IVs are public

                # Compatibility IVs
                # -----------------

                # Used for compatibility with model objects (inheriting GA::Generic::ModelObj)
                modelFlag                   => TRUE,
                number                      => undef,           # Set later
                parent                      => $parentRoom,

                # Exit IVs
                # --------
                dir                         => $dir,
            };

        } elsif ($mode eq 'non_model') {

            # This object is not stored in the world model (e.g. exit objects used by the Locator
            #   task)
            $self = {
#                _objName                    => 'exit',
#                _objClass                   => $class,
                _parentFile                 => undef,
                _parentWorld                => undef,
#                _privFlag                   => FALSE,           # All IVs are public

                # Compatibility IVs
                # -----------------

                # Used for compatibility with model objects (inheriting GA::Generic::ModelObj)
                modelFlag                   => FALSE,
                number                      => undef,           # Set later
                parent                      => undef,

                # Exit IVs
                # --------
                dir                         => $dir,
            };
        }

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub compress {

        # Called by GA::Obj::File->updateExtractedData and GA::Cmd::CompressModel->do
        # Drastically reduce the amount of memory used by each exit object by completely removing
        #   IVs whose values are the default values for an exit object (the code obtains the
        #   default values from the exit object stored in the global variable $DEFAULT_EXIT,
        #   instead)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->compress', @_);
        }

        # Deal with universal IVs
        foreach my $iv ( qw (_objName _objClass _privFlag) ) {

            delete $self->{$iv};
        }

        # Deal with flag scalars which are FALSE by default
        foreach my $iv (
            qw (
                brokenFlag bentFlag regionFlag superFlag notSuperFlag hiddenFlag oneWayFlag
                retraceFlag
            )
        ) {
            if (exists $self->{$iv} && ! $self->{$iv}) {

                delete $self->{$iv};
            }
        }

        # Deal with non-flag scalars which are undefined by default
        foreach my $iv (
            qw (
                exitType altDir mapDir exitTag destRoom twinExit oneWayDir shadowExit exitInfo
            )
        ) {
            if (exists $self->{$iv} && ! defined $self->{$iv}) {

                delete $self->{$iv};
            }
        }

        # Deal with non-flag scalars which have a defined value by default
        %hash = (
            'name'              => 'exit',
            'category'          => 'exit',
            'drawMode'          => 'primary',
            'exitTagXOffset'    => 0,
            'exitTagYOffset'    => 0,
            'randomType'        => 'none',
            'exitOrnament'      => 'none',
            'exitState'         => 'normal',
        );

        foreach my $iv (keys %hash) {

            if (exists $self->{$iv} && $self->{$iv} eq $hash{$iv}) {

                delete $self->{$iv};
            }
        }

        # Deal with lists which are empty by default
        foreach my $iv (
            qw (
                bendOffsetList randomDestList
            )
        ) {
            if (exists $self->{$iv}) {

                my $listRef = $self->{$iv};
                if (! @$listRef) {

                    delete $self->{$iv};
                }
            }
        }

        # Deal with hashes which are empty by default
        foreach my $iv (
            qw (
                privateHash assistedHash doorHash
            )
        ) {
            if (exists $self->{$iv}) {

                my $hashRef = $self->{$iv};
                if (! %$hashRef) {

                    delete $self->{$iv};
                }
            }
        }

        # Operation complete
        return 1;
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
        #   2. ->doorHash
        #   3. ->dir
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
            $wmObj, $cmd, $cmdString,
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

        # 2. ->doorHash
        # -------------

        # Only consult the IVs for which the corresponding part 2 IVs yielded nothing

        if ($wmObj->assistedBreakFlag && $self->exitOrnament eq 'break' && ! @breakList) {

            $cmd = $self->ivShow('doorHash', 'break');
            if (defined $cmd) {

                push (@breakList, $cmd);

            } else {

                # Use the command cage's standard 'break' command, if it is set
                $cmd = $session->prepareCmd('break', 'direction', $self->dir);
                if (defined $cmd) {

                    push (@breakList, $cmd);
                }
            }
        }

        if ($wmObj->assistedPickFlag && $self->exitOrnament eq 'pick' && ! @pickList) {

            $cmd = $self->ivShow('doorHash', 'pick');
            if (defined $cmd) {

                push (@breakList, $cmd);

            } else {

                # Use the command cage's standard 'pick' command, if it is set
                $cmd = $session->prepareCmd('pick', 'direction', $self->dir);
                if (defined $cmd) {

                    push (@pickList, $cmd);
                }
            }
        }

        if ($wmObj->assistedUnlockFlag && $self->exitOrnament eq 'lock' && ! @unlockList) {

            $cmd = $self->ivShow('doorHash', 'unlock');
            if (defined $cmd) {

                push (@breakList, $cmd);

            } else {

                # Use the command cage's standard 'unlock' command, if it is set
                $cmd = $session->prepareCmd('unlock', 'direction', $self->dir);
                if (defined $cmd) {

                    push (@unlockList, $cmd);
                }
            }
        }

        if ($wmObj->assistedOpenFlag && $self->exitOrnament eq 'open' && ! @openList) {

            $cmd = $self->ivShow('doorHash', 'open');
            if (defined $cmd) {

                push (@breakList, $cmd);

            } else {

                # Use the command cage's standard 'open_dir' command, if it is set
                $cmd = $session->prepareCmd('open_dir', 'direction', $self->dir);
                if (defined $cmd) {

                    push (@openList, $cmd);
                }
            }
        }

        if ($wmObj->assistedCloseFlag && $self->exitOrnament eq 'open' && ! @closeList) {

            $cmd = $self->ivShow('doorHash', 'close');
            if (defined $cmd) {

                push (@breakList, $cmd);

            } else {

                # Use the command cage's standard 'close_dir' command, if it is set
                $cmd = $session->prepareCmd('close_dir', 'direction', $self->dir);
                if (defined $cmd) {

                    push (@closeList, $cmd);
                }
            }
        }

        if ($wmObj->assistedLockFlag && $self->exitOrnament eq 'lock' && ! @lockList) {

            $cmd = $self->ivShow('doorHash', 'lock');
            if (defined $cmd) {

                push (@breakList, $cmd);

            } else {

                # Use the command cage's standard 'lock' command, if it is set
                $cmd = $session->prepareCmd('lock', 'direction', $self->dir);
                if (defined $cmd) {

                    push (@lockList, $cmd);
                }
            }
        }

        # (Obviously, there's no standard command for 'mystery' exits)

        # 3. ->dir
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

        if (! @cmdList) {

            return undef;

        } else {

            # Combine the commands (and sequences of commands) into a single string, with each
            #   individual world command separated from the next one by Axmud's command separator
            $cmdString = join($axmud::CLIENT->cmdSep, @cmdList);

            # Return the string
            return $cmdString;
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # To conserve memory, IVs with default values don't exist in the blessed reference; instead, we
    #   obtain them from a default exit object stored in the global variable $DEFAULT_EXIT

    sub _objName {
        if ( ! exists $_[0]->{_objName} )
            { $axmud::DEFAULT_EXIT->{_objName} } else { $_[0]->{_objName} }
    }
    sub _objClass {
        if ( ! exists $_[0]->{_objClass} )
            { $axmud::DEFAULT_EXIT->{_objClass} } else { $_[0]->{_objClass} }
    }
    sub _parentFile
        { $_[0]->{_parentFile} }
    sub _parentWorld
        { $_[0]->{_parentWorld} }
    sub _privFlag {
        if ( ! exists $_[0]->{_privFlag} )
            { $axmud::DEFAULT_EXIT->{_privFlag} } else { $_[0]->{_privFlag} }
    }

    sub name {
        if ( ! exists $_[0]->{name} )
            { $axmud::DEFAULT_EXIT->{name} } else { $_[0]->{name} }
    }
    sub category {
        if ( ! exists $_[0]->{category} )
            { $axmud::DEFAULT_EXIT->{category} } else { $_[0]->{category} }
    }
    sub modelFlag
        { $_[0]->{modelFlag} }
    sub number
        { $_[0]->{number} }
    sub parent
        { $_[0]->{parent} }

    sub privateHash {
        my $self = shift;
        if ( ! exists $self->{privateHash} )
            { return %{$axmud::DEFAULT_EXIT->{privateHash}}; }
        else
            { return %{$self->{privateHash}}; }
    }

    sub exitType {
        if ( ! exists $_[0]->{exitType} )
            { $axmud::DEFAULT_EXIT->{exitType} } else { $_[0]->{exitType} }
    }

    sub dir
        { $_[0]->{dir} }
    sub altDir {
        if ( ! exists $_[0]->{altDir} )
            { $axmud::DEFAULT_EXIT->{altDir} } else { $_[0]->{altDir} }
    }
    sub mapDir {
        if ( ! exists $_[0]->{mapDir} )
            { $axmud::DEFAULT_EXIT->{mapDir} } else { $_[0]->{mapDir} }
    }
    sub drawMode {
        if ( ! exists $_[0]->{drawMode} )
            { $axmud::DEFAULT_EXIT->{drawMode} } else { $_[0]->{drawMode} }
    }

    sub exitTag {
        if ( ! exists $_[0]->{exitTag} )
            { $axmud::DEFAULT_EXIT->{exitTag} } else { $_[0]->{exitTag} }
    }
    sub exitTagXOffset {
        if ( ! exists $_[0]->{exitTagXOffset} )
            { $axmud::DEFAULT_EXIT->{exitTagXOffset} } else { $_[0]->{exitTagXOffset} }
    }
    sub exitTagYOffset {
        if ( ! exists $_[0]->{exitTagYOffset} )
            { $axmud::DEFAULT_EXIT->{exitTagYOffset} } else { $_[0]->{exitTagYOffset} }
    }

    sub brokenFlag {
        if ( ! exists $_[0]->{brokenFlag} )
            { $axmud::DEFAULT_EXIT->{brokenFlag} } else { $_[0]->{brokenFlag} }
    }
    sub bentFlag {
        if ( ! exists $_[0]->{bentFlag} )
            { $axmud::DEFAULT_EXIT->{bentFlag} } else { $_[0]->{bentFlag} }
    }
    sub bendOffsetList {
        my $self = shift;
        if ( ! exists $self->{bendOffsetList} )
            { return @{$axmud::DEFAULT_EXIT->{bendOffsetList}}; }
        else
            { return @{$self->{bendOffsetList}}; }
    }
    sub regionFlag {
        if ( ! exists $_[0]->{regionFlag} )
            { $axmud::DEFAULT_EXIT->{regionFlag} } else { $_[0]->{regionFlag} }
    }
    sub superFlag {
        if ( ! exists $_[0]->{superFlag} )
            { $axmud::DEFAULT_EXIT->{superFlag} } else { $_[0]->{superFlag} }
    }
    sub notSuperFlag {
        if ( ! exists $_[0]->{notSuperFlag} )
            { $axmud::DEFAULT_EXIT->{notSuperFlag} } else { $_[0]->{notSuperFlag} }
    }
    sub hiddenFlag {
        if ( ! exists $_[0]->{hiddenFlag} )
            { $axmud::DEFAULT_EXIT->{hiddenFlag} } else { $_[0]->{hiddenFlag} }
    }
    sub randomType {
        if ( ! exists $_[0]->{randomType} )
            { $axmud::DEFAULT_EXIT->{randomType} } else { $_[0]->{randomType} }
    }
    sub randomDestList {
        my $self = shift;
        if ( ! exists $self->{randomDestList} )
            { return @{$axmud::DEFAULT_EXIT->{randomDestList}}; }
        else
            { return @{$self->{randomDestList}}; }
    }

    sub destRoom {
        if ( ! exists $_[0]->{destRoom} )
            { $axmud::DEFAULT_EXIT->{destRoom} } else { $_[0]->{destRoom} }
    }
    sub twinExit {
        if ( ! exists $_[0]->{twinExit} )
            { $axmud::DEFAULT_EXIT->{twinExit} } else { $_[0]->{twinExit} }
    }
    sub oneWayFlag {
        if ( ! exists $_[0]->{oneWayFlag} )
            { $axmud::DEFAULT_EXIT->{oneWayFlag} } else { $_[0]->{oneWayFlag} }
    }
    sub oneWayDir {
        if ( ! exists $_[0]->{oneWayDir} )
            { $axmud::DEFAULT_EXIT->{oneWayDir} } else { $_[0]->{oneWayDir} }
    }
    sub retraceFlag {
        if ( ! exists $_[0]->{retraceFlag} )
            { $axmud::DEFAULT_EXIT->{retraceFlag} } else { $_[0]->{retraceFlag} }
    }
    sub shadowExit {
        if ( ! exists $_[0]->{shadowExit} )
            { $axmud::DEFAULT_EXIT->{shadowExit} } else { $_[0]->{shadowExit} }
    }

    sub exitOrnament {
        if ( ! exists $_[0]->{exitOrnament} )
            { $axmud::DEFAULT_EXIT->{exitOrnament} } else { $_[0]->{exitOrnament} }
    }
    sub exitState {
        if ( ! exists $_[0]->{exitState} )
            { $axmud::DEFAULT_EXIT->{exitState} } else { $_[0]->{exitState} }
    }
    sub exitInfo {
        if ( ! exists $_[0]->{exitInfo} )
            { $axmud::DEFAULT_EXIT->{exitInfo} } else { $_[0]->{exitInfo} }
    }

    sub assistedHash {
        my $self = shift;
        if ( ! exists $self->{assistedHash} )
            { return %{$axmud::DEFAULT_EXIT->{assistedHash}}; }
        else
            { return %{$self->{assistedHash}}; }
    }
    sub doorHash {
        my $self = shift;
        if ( ! exists $self->{doorHash} )
            { return %{$axmud::DEFAULT_EXIT->{doorHash}}; }
        else
            { return %{$self->{doorHash}}; }
    }
}

# Package must return a true value
1
