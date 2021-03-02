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
# Games::Axmud::ModelObj::XXX
# All model objects (the world model itself can be found in world_model.pm)

{ package Games::Axmud::ModelObj::Region;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'region' model object (which represents an area of the
        #   world)
        #
        # Expected arguments
        #   $session        - The parent GA::Session (not stored as an IV)
        #   $name           - A name for the region, e.g. 'woodlands' (NB If $name is longer than 32
        #                       characters, it is shortened)
        #   $modelFlag      - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parentRegion   - World model number of the region to which this region belongs ('undef'
        #                       if there isn't a parent region or it this is a non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parentRegion, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'region');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parentRegion;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = FALSE;
        $self->{aliveFlag}              = FALSE;
        $self->{sentientFlag}           = FALSE;
        $self->{portableFlag}           = FALSE;
        $self->{saleableFlag}           = FALSE;
        $self->{privateHash}            = {};

        # No group 2 IVs for regions
        # No group 3 IVs for regions
        # No group 4 IVs for regions

        # Set group 5 IVs
        # Flag set to TRUE if this region is temporary, in which case Axmud deletes it (and
        #   everything it contains) at the end of the current session, or if that's not possible, at
        #   the beginning of the next one
        $self->{tempRegionFlag}     = FALSE;

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub countChildren {

        # Called by GA::Cmd::ModelReport->do
        # Counts the number of rooms in this region (actually, counts the number of child
        #   GA::ModelObj::Room objects)
        # Counts the number of non-room objects in this region (actually, counts the number of
        #   children which aren't room objects, and the number of children of rooms which aren't
        #   GA::Obj::Exit objects). Makes a separate count of child regions which aren't included
        #   in the main count
        # Counts the number of exits in this region (actually, counts the number of child
        #   room objects, then counts the number of exits that each of those rooms has)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the counts as a list in the form
        #       (room_count, exit_count, other_count, child_region_count)

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $roomCount, $exitCount, $otherCount, $childRegionCount,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->countChildren', @_);
            return @emptyList;
        }

        # Initialise variables
        $roomCount = 0;
        $exitCount = 0;
        $otherCount = 0;
        $childRegionCount = 0;

        OUTER: foreach my $num ($self->ivKeys('childHash')) {

            my $obj = $session->worldModelObj->ivShow('modelHash', $num);

            if ($obj->category eq 'room') {

                $roomCount++;
                if ($obj->childHash) {

                    $otherCount += $obj->ivPairs('childHash');
                }

                if ($obj->exitNumHash) {

                    $exitCount += $obj->ivPairs('exitNumHash');
                }

            } elsif ($obj->category eq 'region') {

                $childRegionCount++;

            } else {

                $otherCount++;
            }
        }

        return ($roomCount, $exitCount, $otherCount, $childRegionCount);
    }

    sub countChildrenCategories {

        # Called by GA::Cmd::ModelReport->do
        # A modified version of $self->countChildren, which also counts the category of each
        #   child object that isn't a room or exit
        #
        # Counts the number of rooms in this region (actually, counts the number of child
        #   GA::ModelObj::Room objects)
        # Counts the number of non-room objects in this region (actually, counts the number of
        #   children which aren't room objects, and the number of children of rooms which aren't
        #   GA::Obj::Exit ). Compiles a hash of categories, in the form
        #       $categoryHash{category_of_object} = number_of_occurences
        # Counts the number of exits in this region (actually, counts the number of child
        #   room objects, then counts the number of exits that each of those rooms has)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the counts as a list in the form
        #       (room_count, exit_count, other_count, reference_to_category_hash)

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $roomCount, $exitCount, $otherCount,
            @emptyList,
            %categoryHash,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->countChildrenCategories', @_);
            return @emptyList;
        }

        # Initialise variables
        $roomCount = 0;
        $exitCount = 0;
        $otherCount = 0;
        %categoryHash = (
            'weapon' => 0,
            'armour' => 0,
            'garment' => 0,
            'character' => 0,
            'minion' => 0,
            'sentient' => 0,
            'creature' => 0,
            'portable' => 0,
            'decoration' => 0,
            'custom' => 0,

        );

        OUTER: foreach my $num ($self->ivKeys('childHash')) {

            my $obj = $session->worldModelObj->ivShow('modelHash', $num);

            if ($obj->category eq 'room') {

                $roomCount++;
                if ($obj->childHash) {

                    INNER: foreach my $otherNum ($obj->ivKeys('childHash')) {

                        my $otherObj = $session->worldModelObj->ivShow('modelHash', $otherNum);

                        $otherCount++;
                        $categoryHash{$otherObj->category} = $categoryHash{$otherObj->category} + 1;
                    }
                }

                if ($obj->exitNumHash) {

                    $exitCount += $obj->ivPairs('exitNumHash');
                }

            } elsif ($obj->category ne 'region') {   # Regions can have child regions

                $otherCount++;
                $categoryHash{$obj->category} = $categoryHash{$obj->category} + 1;
            }
        }

        return ($roomCount, $exitCount, $otherCount, \%categoryHash);
    }

    sub countVisits {

        # Called by GA::Cmd::ModelReport->do
        # Checks every room in this region (actually, all child objects which are
        #   GA::ModelObj::Room objects)
        # Counts the number of rooms that have been visited, and compiles a hash in the form
        #       $hash{character_name} = number_of_visits
        # ...where 'number_of_visits' counts the rooms visited by 'character_name', not including
        #   rooms whose 'dummy_room' room flag is set
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form
        #       (
        #           number_of_rooms, number_of_dummy_rooms, number_of_rooms_never_visited,
        #           reference_to_compiled_hash
        #       )
        #   ...where:
        #       'number_of_rooms' counts the rooms whose 'dummy_room' flag is not set,
        #       'number_of_dummy_rooms' counts the rooms whose 'dummy_room' flag is set,
        #       'number_of_rooms_never_visited' counts the rooms never visited by any character,
        #           not including rooms whose 'dummy_room' room flag is set

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $roomCount, $dummyCount, $noVisitCount,
            @emptyList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->countVisits', @_);
            return @emptyList;
        }

        # Initialise variables
        $roomCount = 0;
        $dummyCount = 0;
        $noVisitCount = 0;

        OUTER: foreach my $num ($self->ivKeys('childHash')) {

            my $obj = $session->worldModelObj->ivShow('modelHash', $num);

            if ($obj->category eq 'room') {

                if ($obj->ivExists('roomFlagHash', 'dummy_room')) {

                    $dummyCount++;

                } else {

                    $roomCount++;

                    if (! $obj->visitHash) {

                        $noVisitCount++;

                    } else {

                        INNER: foreach my $char ($obj->ivKeys('visitHash')) {

                            if (! exists $hash{$char}) {
                                $hash{$char} = 1;
                            } else {
                                $hash{$char} = $hash{$char} + 1;
                            }
                        }
                    }
                }
            }
        }

        return ($roomCount, $dummyCount, $noVisitCount, \%hash);
    }

    sub countCharVisits {

        # Called by GA::Cmd::ModelReport->do
        # Checks every room in this region (actually, all child objects which are
        #   GA::ModelObj::Room objects)
        # Counts the number of rooms that have been visited by a specified character, and the
        #   number that haven't (not including any rooms whose 'dummy_room' room flag is set,
        #   which are counted separately)
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $char       - The name of the character to check
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form
        #       (
        #           number_of_rooms, number_of_dummy_rooms, number_of_rooms_visited,
        #           number_of_rooms_never_visited,
        #       )
        #   ...where:
        #       'number_of_rooms' counts the rooms whose 'dummy_room' flag is not set,
        #       'number_of_dummy_rooms' counts the rooms whose 'dummy_room' flag is set,
        #       'number_of_rooms_visited' and 'number_of_rooms_never_visited' do not include rooms
        #           whose 'dummy_room' room flag is set

        my ($self, $session, $char, $check) = @_;

        # Local variables
        my (
            $roomCount, $dummyCount, $visitCount, $noVisitCount,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $char || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->countCharVisits', @_);
            return @emptyList;
        }

        # Initialise variables
        $roomCount = 0;
        $dummyCount = 0;
        $noVisitCount = 0;
        $visitCount = 0;

        foreach my $num ($self->ivKeys('childHash')) {

            my $obj = $session->worldModelObj->ivShow('modelHash', $num);

            if ($obj->category eq 'room') {

                if ($obj->ivExists('roomFlagHash', 'dummy_room')) {

                    $dummyCount++;

                } else {

                    $roomCount++;

                    if (! $obj->visitHash || ! $obj->ivExists('visitHash', $char)) {
                        $noVisitCount++;
                    } else {
                        $visitCount++;
                    }
                }
            }
        }

        return ($roomCount, $dummyCount, $visitCount, $noVisitCount);
    }

    sub countGuilds {

        # Called by GA::Cmd::ModelReport->do
        # Checks every room in this region (actually, all child objects which are
        #   GA::ModelObj::Room objects)
        # Counts the number of rooms that are marked as guild rooms, and compiles a hash in the form
        #   $hash{guild_name} = number_of_rooms
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Optional arguments
        #   @guildList  - List of GA::Profile::Guild names. If specified, only those guilds are
        #                   counted (but the counts still return the totals for all guilds)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form
        #       (total_number_of_rooms, total_number_of_guild_rooms, reference_to_compiled_hash)

        my ($self, $session, @guildList) = @_;

        # Local variables
        my (
            $roomCount, $guildRoomCount,
            @emptyList,
            %hash, %restrictHash,
        );

        # Check for improper arguments
        if (! defined $session) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->countGuilds', @_);
            return @emptyList;
        }

        # Initialise variables
        $roomCount = 0;
        $guildRoomCount = 0;
        foreach my $guild (@guildList) {

            $restrictHash{$guild} = undef;
        }

        foreach my $num ($self->ivKeys('childHash')) {

            my $obj = $session->worldModelObj->ivShow('modelHash', $num);

            if ($obj->category eq 'room') {

                $roomCount++;

                if ($obj->roomGuild) {

                    $guildRoomCount++;

                    if (! @guildList || exists $restrictHash{$obj->roomGuild}) {

                        if (exists $hash{$obj->roomGuild}) {
                            $hash{$obj->roomGuild} = $hash{$obj->roomGuild} + 1;
                        } else {
                            $hash{$obj->roomGuild} = 1;
                        }
                    }
                }
            }
        }

        return ($roomCount, $guildRoomCount, \%hash);
    }

    sub countRoomFlags {

        # Called by GA::Cmd::ModelReport->do
        # Checks every room in this region (actually, all child objects which are
        #   GA::ModelObj::Room objects)
        # Counts the number of rooms that have room flags, and compiles a hash in the form
        #       $hash{room_flag} = number_of_rooms
        #
        # Expected arguments
        #   $session       - The calling function's GA::Session
        #
        # Optional arguments
        #   @roomFlagList  - List of room flags. If specified, only those room flags are counted
        #                       (but the counts still return the totals for all room flags)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form
        #       (total_number_of_rooms, total_number_of_room_flags, reference_to_compiled_hash)

        my ($self, $session, @roomFlagList) = @_;

        # Local variables
        my (
            $roomCount, $roomFlagCount,
            @emptyList,
            %hash, %restrictHash,
        );

        # Check for improper arguments
        if (! defined $session) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->countRoomFlags', @_);
            return @emptyList;
        }

        # Initialise variables
        $roomCount = 0;
        $roomFlagCount = 0;
        foreach my $guild (@roomFlagList) {

            $restrictHash{$guild} = undef;
        }

        OUTER: foreach my $num ($self->ivKeys('childHash')) {

            my $obj = $session->worldModelObj->ivShow('modelHash', $num);

            if ($obj->category eq 'room') {

                $roomCount++;

                if ($obj->roomFlagHash) {

                    $roomFlagCount++;

                    INNER: foreach my $flag ($obj->ivKeys('roomFlagHash')) {

                        if (! @roomFlagList || exists $restrictHash{$flag}) {

                            if (exists $hash{$flag}) {
                                $hash{$flag} = $hash{$flag} + 1;
                            } else {
                                $hash{$flag} = 1;
                            }
                        }
                    }
                }
            }
        }

        return ($roomCount, $roomFlagCount, \%hash);
    }

    sub countRooms {

        # Called by GA::Cmd::ModelReport->do
        # Counts the number of rooms in this region
        # Keeps track of the number of rooms with at least one title and room description, as well
        #   as rooms with title(s) but no descrip(s), descrip(s) but no title(s) and rooms with
        #   neither titles nor descrips
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the counts as a list in the form
        #       (
        #           total_rooms_in_region, titles_and_descrips_count, titles_only_count,
        #           descrips_only_count, neither_count,
        #       )

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $roomCount, $bothCount, $titleCount, $descripCount, $noneCount,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->countExits', @_);
            return @emptyList;
        }

        # Initialise variables
        $roomCount = 0;
        $bothCount = 0;
        $titleCount = 0;
        $descripCount = 0;
        $noneCount = 0;

        OUTER: foreach my $num ($self->ivKeys('childHash')) {

            my $obj = $session->worldModelObj->ivShow('modelHash', $num);

            if ($obj->category eq 'room') {

                $roomCount++;

                if ($obj->titleList && $obj->descripHash) {
                    $bothCount++;
                } elsif ($obj->titleList) {
                    $titleCount++;
                } elsif ($obj->descripHash) {
                    $descripCount++;
                } else {
                    $noneCount++;
                }
            }
        }

        return ($roomCount, $bothCount, $titleCount, $descripCount, $noneCount);
    }

    sub countExits {

        # Called by GA::Cmd::ModelReport->do
        # Counts the number of exits in this region (actually, counts the number of child
        #   GA::ModelObj::Room objects, and then counts each of their exits)
        # Keeps track of the number of unallocated, unallocatable, uncertain and incomplete exits,
        #   as well as the total number of exits. (Distinguishes between normal incomplete exits,
        #   and incomplete exits which have been marked as 'impassabe'/'mystery')
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the counts as a list in the form
        #       (
        #           total_exits_in_region, unallocated_count, unallocatable_count, uncertain_count,
        #           incomplete_not_impassable, incomplete_impassable_count, incomplete_myster_count,
        #       )

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $exitCount, $unallocatedCount, $unallocatableCount, $uncertainCount, $incompleteCount,
            $incompImpassCount, $incompMysteryCount,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->countExits', @_);
            return @emptyList;
        }

        # Initialise variables
        $exitCount = 0;
        $unallocatedCount = 0;
        $unallocatableCount = 0;
        $uncertainCount = 0;
        $incompleteCount = 0;
        $incompImpassCount = 0;
        $incompMysteryCount = 0;

        OUTER: foreach my $num ($self->ivKeys('childHash')) {

            my $obj = $session->worldModelObj->ivShow('modelHash', $num);

            if ($obj->category eq 'room' && $obj->exitNumHash) {

                INNER: foreach my $exitNumber ($obj->ivValues('exitNumHash')) {

                    my $exitObj = $session->worldModelObj->ivShow('exitModelHash', $exitNumber);

                    $exitCount++;

                    if ($exitObj->drawMode eq 'temp_alloc') {

                        $unallocatedCount++;

                    } elsif ($exitObj->drawMode eq 'temp_unalloc') {

                        $unallocatedCount++;
                        $unallocatableCount++;

                    } elsif (
                        $exitObj->destRoom
                        && (! $exitObj->twinExit)
                        && (! $exitObj->retraceFlag)
                        && (! $exitObj->oneWayFlag)
                        && ($exitObj->randomType eq 'none')
                    ) {
                        $uncertainCount++;

                    } elsif (! $exitObj->destRoom) {

                        if ($exitObj->exitOrnament eq 'impass') {
                            $incompImpassCount++;
                        } elsif ($exitObj->exitOrnament eq 'mystery') {
                            $incompMysteryCount++;
                        } elsif ($exitObj->randomType eq 'none') {
                            $incompleteCount++;
                        }
                    }
                }
            }
        }

        return (
            $exitCount, $unallocatedCount, $unallocatableCount, $uncertainCount, $incompleteCount,
            $incompImpassCount, $incompMysteryCount,
        );
    }

    sub countCheckedDirs {

        # Called by GA::Cmd::ModelReport->do
        # Counts the number of checked directions in this region (actually, counts the number of
        #   child GA::ModelObj::Room objects, and then counts each of their checked directions)
        # Keeps track of the number of checkable directions at the same time
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   %dirHash    - A hash of custom primary directions which are checkable, in the form
        #                   $hash{custom_primary_dir} = undef
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the counts as a list in the form
        #       ( total_exits_in_region, checked_direction_count, checkable_direction_count )

        my ($self, $session, %dirHash) = @_;

        # Local variables
        my (
            $exitCount, $checkedCount, $checkableCount,
            %emptyHash,
        );

        # Check for improper arguments
        if (! defined $session || ! %dirHash) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->countCheckedDirs', @_);
            return %emptyHash;
        }

        # Initialise variables
        $exitCount = 0;
        $checkedCount = 0;
        $checkableCount = 0;

        foreach my $childNum ($self->ivKeys('childHash')) {

            my (
                $childObj,
                %thisHash,
            );

            $childObj = $session->worldModelObj->ivShow('modelHash', $childNum);

            if ($childObj->category eq 'room') {

                foreach my $exitNum ($childObj->ivValues('exitNumHash')) {

                    my $exitObj = $session->worldModelObj->ivShow('exitModelHash', $exitNum);

                    $exitCount++;
                }

                # Checkable directions are all of those remaining in %thisHash after deleting
                #   actual exit objects and checked directions
                %thisHash = %dirHash;
                foreach my $dir ($childObj->ivKeys('checkedDirHash')) {

                    delete $thisHash{$dir};
                }

                foreach my $dir ($childObj->sortedExitList) {

                    delete $thisHash{$dir};
                }

                $checkedCount += $childObj->ivPairs('checkedDirHash');
                $checkableCount += scalar (keys %thisHash);
            }
        }

        return ($exitCount, $checkedCount, $checkableCount);
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs
    sub tempRegionFlag
        { $_[0]->{tempRegionFlag} }
}

{ package Games::Axmud::ModelObj::Room;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'room' model object (which represents a single room in the
        #   world)
        #
        # Expected arguments
        #   $session        - The parent GA::Session (not stored as an IV)
        #   $descrip        - A string to describe the room - the same as its room title, if that's
        #                       available; if not, a shortened version of the verbose description
        #                       (NB as of v1.1.408, the $descrip is no longer stored anywhere)
        #   $mode           - 'model' for an room model object (stored in
        #                       GA::Obj::WorldModel->modelHash), 'non_model' for non-model room
        #                       object, for example one used by the Locator task, or 'global' for
        #                       the room object stored in the global variable $DEFAULT_ROOM (and
        #                       which provides default values for all room object IVs)
        #
        # Optional arguments
        #   $parentRegion   - World model number of the region to which this room belongs ('undef'
        #                       if there isn't a parent region or it this is a non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $descrip, $mode, $parentRegion, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $descrip || ! defined $mode
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # For very large world models (10,000+ rooms), some computers tend to run out of memory
        #   which produces a Perl error and a crash
        # In response, we try to reduce the size of the world model as much as possible. Most of the
        #   memory used is for room objects and exit objects (GA::Obj::Exit). Most of the memory
        #   used by each of those objects is for IVs with default values
        # Therefore, we remove most of the IVs altogether, restoring them only if some part of the
        #   Axmud code sets the IV to a non-default value. Default values for each IV are obtained
        #   from a room object stored in a global variable, $DEFAULT_ROOM, instead of from the room
        #   object itself
        my $self;

        if ($mode eq 'global') {

            # This object is to be stored in the global variable, $DEFAULT_ROOM. Therefore it has
            #   default values for all IVs

            # Set standard IVs
            $self->{_objName}               = 'room';
            $self->{_objClass}              = $class;
            $self->{_parentFile}            = undef;
            $self->{_parentWorld}           = undef;
            $self->{_privFlag}              = FALSE,            # All IVs are public

            # Set group 1 IVs
            $self->{name}                   = 'room';
            $self->{category}               = 'room';
            $self->{modelFlag}              = FALSE;
            $self->{number}                 = undef;
            $self->{parent}                 = $parentRegion;
            $self->{childHash}              = {};

            $self->{concreteFlag}           = FALSE;
            $self->{aliveFlag}              = FALSE;
            $self->{sentientFlag}           = FALSE;
            $self->{portableFlag}           = FALSE;
            $self->{saleableFlag}           = FALSE;

            $self->{privateHash}            = {};

            $self->{sourceCodePath}         = undef;
            $self->{notesList}              = [];

            # No group 2 IVs for rooms
            # No group 3 IVs for rooms
            # No group 4 IVs for rooms

            # Set group 5 IVs
            # The room's position in the map - specifically, its coordinates on the regionmap grid
            #   tied to this room's parent region
            $self->{xPosBlocks}             = undef;
            $self->{yPosBlocks}             = undef;
            $self->{zPosBlocks}             = undef;
            # The room's tag, if it has been given one. Maximum 16 characters, and cannot contain
            #   the sequence '@@@', which is needed for route objects
            $self->{roomTag}                = undef;
            # The offset (in pixels) where the room tag is drawn on the map. (0, 0) means draw the
            #   tag at the standard position; (10, -10) means draw it 10 pixels to the right, 10
            #   pixels higher
            $self->{roomTagXOffset}         = 0;
            $self->{roomTagYOffset}         = 0;
            # The name of the guild, if this is a guild room ('undef' if all guilds can advance
            #   skills here)
            $self->{roomGuild}              = undef;
            # The offset (in pixels) where the guild name is drawn on the map
            $self->{roomGuildXOffset}       = 0;
            $self->{roomGuildYOffset}       = 0;

            # When we move north from room A to a new room B, and when room B has an exit in the
            #   opposite direction, room A's departure exit is drawn as an 'uncertain' exit - we can
            #   definitely move north from A to B, and probably move south from B to A
            # Until this is confirmed - at which point room A's departure exit becomes a one-way
            #   exit or a two-way exit - room B doesn't know that it has been set as the room A's
            #   departure exit's ->destinationRoom
            # This is a problem because, if room B is deleted, room A's departure exit still points
            #   to the deleted room
            # This room object is room B, and this hash IV contains a list of room A departure
            #   exits - uncertain exits - which lead here. The hash is in the form
            #       $uncertainExitHash{room_A_exit_number} = room_B_opposite_exit_number
            # When an uncertain exit is created, the exit's destination room - this object - is told
            #   to update the hash
            # When an uncertain exit becomes a two-way exit, the entry is deleted
            $self->{uncertainExitHash}      = {};
            # We have the same issue with one-way exits. If we move north from room A to a new room
            #   B, when room B doesn't have an exit in the opposite direction, room A's departure
            #   exit is drawn as a '1-way' exit
            # If room B is deleted, the one-way exit still points to it; if room B is moved to a new
            #   place in the same region, the automapper will still try to draw a one-way exit
            #   between them
            # This room object is room B, and this hash IV contains a list of room A departure exits
            #   - one-way exits - which lead here. The hash is in the form
            #       $oneWayExitHash{room_A_exit_number} = undef
            # When an one-way exit is created, the exit's destination room - this object - is told
            #   to update the hash
            $self->{oneWayExitHash}         = {};
            # Also the same issue with involuntary/repulse exits patterns which have a defined
            #   destination room which is this room. When a pattern with a destination room is
            #   added, it is stored here. Hash in the form
            #       $invRepExitHash{departure_room_number} = undef
            $self->{invRepExitHash}         = {};
            # Also the same issue with random exits which lead to a defined list of rooms, one of
            #   which which is this room. When a random exit adds this room to its list, it is
            #   stored here. Hash in the form
            #       $randomExitHash{exit_number} = undef
            $self->{randomExitHash}         = {};
            # Some worlds have invisible exits hidden around the game for the user to discover. This
            #   hash stores 'checked directions' - primary and secondary directions which the user
            #   has tried, while the character was in this room (and while collection of checked
            #   directions was turned on), and which generated a failed exit message
            # If an exit in the same direction is subsequently created, or if an unallocated exit is
            #   allocated to the same direction, the entry in this hash is automatically deleted
            # Hash in the form
            #   $checkedDirHash{custom_primary_direction} = number_of_failed_attempts;
            $self->{checkedDirHash}        = {};
            # Wilderness mode. Many worlds have 'wilderness' areas where exits aren't explicitly
            #   stated, but are assumed to exist between adjacent rooms
            # There are three settings for this mode:
            #   'normal'   - All of this room's exits have a GA::Obj::Exit, and the automapper
            #       window draws each of those exits
            #   'wild'      - None of this room's exits have a GA::Obj::Exit, and the automapper
            #       window does not draw the room with any exits. Axmud assumes that movement
            #       between this room and any adjacent room (and back again) is possible
            #   'border'    - Like 'wild', except that Axmud assumes that movement between this room
            #       and any adjacent room is possible, but only if the adjacent room's ->wildMode is
            #       set to 'wild' or 'border'. If the adjacent room's ->wildMode is set to 'normal',
            #       Axmud assumes that no exit exists between the two rooms unless it has been
            #       explicitly added to the model with a GA::Obj::Exit
            $self->{wildMode}               = 'normal';

            # List of titles (i.e. brief descriptions) for this room
            $self->{titleList}              = [];
            # Hash of known descriptions (i.e. verbose descriptions) for this room
            #   $self->descripHash{status} = description;
            # 'status' is the current value of the world model's ->lightStatus, which is usually one
            #   of 'day', 'night' or 'darkness'
            # When this object is created, ->descripHash contains a single key-value pair - the
            #   current light status and description. More pairs can be added later
            $self->{descripHash}            = {};
            # GA::Profile::World->unspecifiedRoomPatternList provides a list of patterns that match
            #   a line in 'unspecified' rooms (those that don't use a recognisable room statement;
            #   typically a room whose exit list is completely obscured)
            # If this room is an unspecified room, a list of patterns that match a line telling us
            #   that the character has arrived in the room. The world profile's unspecified patterns
            #   are checked after these ones; patterns in this list should match lines that are only
            #   used with this room
            $self->{unspecifiedPatternList} = [];
            # For non-model room objects, flag set to TRUE if the room has an unspecified room
            #   statement (e.g. 'You emerge from the bushes covered in thorns' - the character is in
            #   a new room, but we don't know which one, or anything about its description, contents
            #   and exits)
            $self->{unspecifiedFlag}        = FALSE;
            # For non-model room objects, set to TRUE if the room is dark (right now), so that we
            #   don't know its description, contents or exits; set to FALSE otherwise
            $self->{currentlyDarkFlag}      = FALSE;

            # List of named exits, listed in the same order that standard exits use
            #   e.g. ('north', 'northeast', 'east'...)
            # For non-model rooms, it won't include hidden exits
            $self->{sortedExitList}         = [];
            # List of exit objects in the format
            #   $exitNumHash{direction} = exit_number_in_exit_model (model rooms)
            #   $exitNumHash{direction} = exit_object (non-model rooms)
            #       ('direction' matches an element in $self->sortedExitList)
            # For non-model rooms, this hash won't include hidden exits
            $self->{exitNumHash}            = {};

            # List of failed exit patterns for this room, which tells the Locator task that a
            #   movement command has failed (but that the exit used was blocked only temporarily,
            #   for example when a guard is sometimes present, and sometimes not)
            $self->{failExitPatternList}
                                            = [];
            # A list of strings which match the text sent by the world, when we leave this room and
            #   arrive at the destination room, but when the world doesn't send a room statement for
            #   the destination room (called a 'faller' in LPmuds)
            $self->{specialDepartPatternList}
                                            = [];
            # Hash of involuntary exit patterns for this room, which tells the Locator task that an
            #   involuntary move has taken place (for example, when dragged by a river from one room
            #   to another)
            # The keys in the hash are patterns matching a line of received text
            # The corresponding values can be 'undef' if the destination room is unknown. Otherwise,
            #   it can be any of these (checked in this order):
            #       1. The destination room's number
            #       2. A direction matching which matches an exit object's nominal direction, >dir
            #       3. A standard primary direction which matches an exit object's drawn map
            #           direction, ->mapDir
            #       4. Any other value (including if no matching exits exist) is treated like an
            #           unknown destination room
            $self->{involuntaryExitPatternHash}
                                            = {};
            # Hash of repulsed exit patterns for this room, which tells the Locator that not only
            #   did an attempted move fail, but that the character has been moved to a new
            #   (different) room - often in the opposite direction
            # The keys in the hash are patterns matching a line of received text
            # The corresponding values can be 'undef' if the destination room is unknown. Otherwise,
            #   it can be any of these (checked in this order):
            #       1. The destination room's number
            #       2. A direction matching which matches an exit object's nominal direction, >dir
            #       3. A standard primary direction which matches an exit object's drawn map
            #           direction, ->mapDir
            #       4. Any other value (including if no matching exits exist) is treated like an
            #           unknown destination room
            $self->{repulseExitPatternHash} = {};

            # For worlds that provide a list of commands available in the room (typically instead of
            #   an exit list, but not necessarily), a list of those commands
            $self->{roomCmdList}            = [];
            # A temporary list of room commands. Set whenever $self->roomCmdList is set. Thereafter,
            #   when the user types ';roomcommand', the first command is removed from the list,
            #   executed as a world command, and added to the end of the list
            $self->{tempRoomCmdList}        = [];

            # Records the number of visits to this room for each character. Hash in the form
            #   $visitHash{character_name} = number_of_visits
            $self->{visitHash}              = {};
            # Flag set to TRUE if this room can only be entered by certain guilds, races or indeed
            #   named characters
            $self->{exclusiveFlag}          = FALSE;
            # A hash of guilds, races, named chars etc allowed in this room (shouldn't include world
            #   profiles), in the form
            #   $exclusiveHash{profile_name} = undef
            $self->{exclusiveHash}          = {};

            # Room flag hash - a hash of room properties. If the key exists in a hash, the 'flag' is
            #   'set to TRUE'; if a key doesn't exist in the hash, the 'flag' is 'set to FALSE'.
            #   (The key's corresponding value is always 'undef'.)
            # If this hash is empty, all the flags are 'set to FALSE'.
            # GA::Obj::WorldModel has an equivalent hash containing all of the keys below. The key's
            #   value is the colour the room should be painted, if the flag is set. When more than
            #   one flag is set, GA::Obj::WorldModel works out for itself which should take priority
            $self->{roomFlagHash}           = {};
            # On the last occasion that the room was drawn, the room flag that was used to draw the
            #   room's interior (i.e. the highest priority room flag - so we only have to look it up
            #   once per drawing cycle). Set to 'undef' if no room flags are set for this room
            $self->{lastRoomFlag}           = undef;

            # GA::Generic::ModelObj defines ->sourceCodePath, the path to the object's source code
            #   on the world (if known)
            # If the room is in a virtual area, this should be set to something like
            #   '/filepath/forest/24,3' - the 'path' that the world gives for this individual room.
            #   The following IV should be set to the file path for the virtual area itself, e.g.
            #   '/filepath/forest'. If set to 'undef', the room isn't in a virtual area
            $self->{virtualAreaPath}        = undef;

            # Data from this room supplied by various MUD protocols. At the moment, MSDP and MXP
            #   data is supported
            # Note that MSDP is not used by the Locator task/automapper, as it often received after
            #   the room statement (and after the automapper needs it)
            #
            # Hash storing data about the room. When MSDP supplies data, the following key-value
            #   pairs are added:
            #   'vnum'          => some_value,
            #   'name'          => some_value,
            #   'area'          => some_value,
            #   'xpos'          => some_value,
            #   'ypos'          => some_value,
            #   'zpos'          => some_value,
            #   'terrain'       => some_value,
            # When MXP supplies data, the following key-value pair is added:
            #   'vnum'          => some_value,
            $self->{protocolRoomHash}       = {};
            # Hash storing data about the room's exits. When MSDP supplies data, the following
            #   key-value pair(s) are added:
            #   'abbrev_exit'   => destination_room_vnum,
            $self->{protocolExitHash}       = {};

            # List of blessed references to objects currently in this room (including player
            #   characters). This IV is used for non-model rooms created by the Locator task; it
            #   contains non-model objects for the contents of the Locator's current room
            $self->{tempObjList}            = [];
            # Hash of hidden objects, in the form
            #   $hiddenObjHash{number_of_hidden_object} = 'commands_to_obtain_it'
            # The keys of ->hiddenObjHash are a subset of the keys in $self->childHash.
            $self->{hiddenObjHash}          = {};
            # Hash of things that can be 'searched' (or 'examined'), and the response in the form
            #   $searchHash{string} = response
            #   e.g. $searchHash{fireplace} = 'It's an empty fireplace'
            # Decorations which can be interacted with get their own model object,
            #   GA::ModelObj::Decoration, and are stored in $self->childHash; this hash is used to
            #   store things that only exist in response to 'search' or 'examine' commands
            $self->{searchHash}             = {};

            # List of recognised nouns that appear in the verbose description (set by the
            #   automapper, when the user allows it)
            $self->{nounList}               = [];
            # List of recognised adjectives that appear in the verbose description (set by the
            #   automapper, when the user allows it)
            $self->{adjList}                = [];

            # List of Axbasic scripts to run, when the character arrives in this room (if the
            #   automapper knows the current location). Only non-task based scripts are suitable for
            #   this list
            $self->{arriveScriptList}       = [];

        } elsif ($mode eq 'model') {

            # This object is stored in the world model, i.e. in GA::Obj::WorldModel->modelHash

            # Set standard IVs
#            $self->{_objName}               = 'room';
#            $self->{_objClass}              = $class;
            $self->{_parentFile}            = 'worldmodel';
            $self->{_parentWorld}           = $session->currentWorld->name;
#            $self->{_privFlag}              = FALSE,            # All IVs are public

            # Set group 1 IVs
#            $self->{category}               = 'room';
            $self->{modelFlag}              = TRUE;
            $self->{number}                 = undef;            # Set later
            $self->{parent}                 = $parentRegion;

            # Set group 5 IVs
            $self->{xPosBlocks}             = undef;
            $self->{yPosBlocks}             = undef;
            $self->{zPosBlocks}             = undef;

        } elsif ($mode eq 'non_model') {

            # This object is not stored in the world model (e.g. room objects used by the Locator
            #   task)

            # Set standard IVs
#            $self->{_objName}               = 'room';
#            $self->{_objClass}              = $class;
            $self->{_parentFile}            = undef;
            $self->{_parentWorld}           = undef;
#            $self->{_privFlag}              = FALSE,            # All IVs are public

            # Set group 1 IVs
#            $self->{category}               = 'room';
            $self->{modelFlag}              = FALSE;
            $self->{number}                 = undef;            # Set later
            $self->{parent}                 = undef;

            # Set group 5 IVs
            $self->{xPosBlocks}             = undef;
            $self->{yPosBlocks}             = undef;
            $self->{zPosBlocks}             = undef;
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
                concreteFlag aliveFlag sentientFlag portableFlag saleableFlag unspecifiedFlag
                currentlyDarkFlag exclusiveFlag
            )
        ) {
            if (exists $self->{$iv} && ! $self->{$iv}) {

                delete $self->{$iv};
            }
        }

        # Deal with non-flag scalars which are undefined by default
        foreach my $iv (
            qw (
                sourceCodePath roomTag roomGuild lastRoomFlag virtualAreaPath
            )
        ) {
            if (exists $self->{$iv} && ! defined $self->{$iv}) {

                delete $self->{$iv};
            }
        }

        # Deal with non-flag scalars which have a defined value by default
        %hash = (
            'name'              => 'room',
            'category'          => 'room',
            'roomTagXOffset'    => 0,
            'roomTagYOffset'    => 0,
            'roomGuildXOffset'  => 0,
            'roomGuildYOffset'  => 0,
            'wildMode'          => 'normal',
        );

        foreach my $iv (keys %hash) {

            if (exists $self->{$iv} && $self->{$iv} eq $hash{$iv}) {

                delete $self->{$iv};
            }
        }

        # Deal with lists which are empty by default
        foreach my $iv (
            qw (
                notesList titleList unspecifiedPatternList sortedExitList failExitPatternList
                specialDepartPatternList roomCmdList tempRoomCmdList tempObjList nounList adjList
                arriveScriptList
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
                childHash privateHash uncertainExitHash oneWayExitHash invRepExitHash randomExitHash
                checkedDirHash descripHash exitNumHash involuntaryExitPatternHash
                repulseExitPatternHash visitHash exclusiveHash roomFlagHash protocolRoomHash
                protocolExitHash hiddenObjHash searchHash
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

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # To conserve memory, IVs with default values don't exist in the blessed reference; instead, we
    #   obtain them from a default room object stored in the global variable $DEFAULT_ROOM

    sub _objName {
        if ( ! exists $_[0]->{_objName} )
            { $axmud::DEFAULT_ROOM->{_objName} } else { $_[0]->{_objName} }
    }
    sub _objClass {
        if ( ! exists $_[0]->{_objClass} )
            { $axmud::DEFAULT_ROOM->{_objClass} } else { $_[0]->{_objClass} }
    }
    sub _parentFile
        { $_[0]->{_parentFile} }
    sub _parentWorld
        { $_[0]->{_parentWorld} }
    sub _privFlag {
        if ( ! exists $_[0]->{_privFlag} )
            { $axmud::DEFAULT_ROOM->{_privFlag} } else { $_[0]->{_privFlag} }
    }

    # Group 1 IVs
    sub name {
        if ( ! exists $_[0]->{name} )
            { $axmud::DEFAULT_ROOM->{name} } else { $_[0]->{name} }
    }
    sub category {
        if ( ! exists $_[0]->{category} )
            { $axmud::DEFAULT_ROOM->{category} } else { $_[0]->{category} }
    }
    sub modelFlag
        { $_[0]->{modelFlag} }
    sub number
        { $_[0]->{number} }
    sub parent
        { $_[0]->{parent} }
    sub childHash {
        my $self = shift;
        if ( ! exists $self->{childHash} )
            { return %{$axmud::DEFAULT_ROOM->{childHash}}; }
        else
            { return %{$self->{childHash}}; }
    }

    sub concreteFlag {
        if ( ! exists $_[0]->{concreteFlag} )
            { $axmud::DEFAULT_ROOM->{concreteFlag} } else { $_[0]->{concreteFlag} }
    }
    sub aliveFlag {
        if ( ! exists $_[0]->{aliveFlag} )
            { $axmud::DEFAULT_ROOM->{aliveFlag} } else { $_[0]->{aliveFlag} }
    }
    sub sentientFlag {
        if ( ! exists $_[0]->{sentientFlag} )
            { $axmud::DEFAULT_ROOM->{sentientFlag} } else { $_[0]->{sentientFlag} }
    }
    sub portableFlag {
        if ( ! exists $_[0]->{portableFlag} )
            { $axmud::DEFAULT_ROOM->{portableFlag} } else { $_[0]->{portableFlag} }
    }
    sub saleableFlag {
        if ( ! exists $_[0]->{saleableFlag} )
            { $axmud::DEFAULT_ROOM->{saleableFlag} } else { $_[0]->{saleableFlag} }
    }

    sub privateHash {
        my $self = shift;
        if ( ! exists $self->{privateHash} )
            { return %{$axmud::DEFAULT_ROOM->{privateHash}}; }
        else
            { return %{$self->{privateHash}}; }
    }

    sub sourceCodePath {
        if ( ! exists $_[0]->{sourceCodePath} )
            { $axmud::DEFAULT_ROOM->{sourceCodePath} } else { $_[0]->{sourceCodePath} }
    }
    sub notesList {
        my $self = shift;
        if ( ! exists $self->{notesList} )
            { return @{$axmud::DEFAULT_ROOM->{notesList}}; }
        else
            { return @{$self->{notesList}}; }
    }

    # Group 5 IVs
    sub xPosBlocks
        { $_[0]->{xPosBlocks} }
    sub yPosBlocks
        { $_[0]->{yPosBlocks} }
    sub zPosBlocks
        { $_[0]->{zPosBlocks} }
    sub roomTag {
        if ( ! exists $_[0]->{roomTag} )
            { $axmud::DEFAULT_ROOM->{roomTag} } else { $_[0]->{roomTag} }
    }
    sub roomTagXOffset {
        if ( ! exists $_[0]->{roomTagXOffset} )
            { $axmud::DEFAULT_ROOM->{roomTagXOffset} } else { $_[0]->{roomTagXOffset} }
    }
    sub roomTagYOffset {
        if ( ! exists $_[0]->{roomTagYOffset} )
            { $axmud::DEFAULT_ROOM->{roomTagYOffset} } else { $_[0]->{roomTagYOffset} }
    }
    sub roomGuild {
        if ( ! exists $_[0]->{roomGuild} )
            { $axmud::DEFAULT_ROOM->{roomGuild} } else { $_[0]->{roomGuild} }
    }
    sub roomGuildXOffset {
        if ( ! exists $_[0]->{roomGuildXOffset} )
            { $axmud::DEFAULT_ROOM->{roomGuildXOffset} } else { $_[0]->{roomGuildXOffset} }
    }
    sub roomGuildYOffset {
        if ( ! exists $_[0]->{roomGuildYOffset} )
            { $axmud::DEFAULT_ROOM->{roomGuildYOffset} } else { $_[0]->{roomGuildYOffset} }
    }

    sub uncertainExitHash {
        my $self = shift;
        if ( ! exists $self->{uncertainExitHash} )
            { return %{$axmud::DEFAULT_ROOM->{uncertainExitHash}}; }
        else
            { return %{$self->{uncertainExitHash}}; }
    }
    sub oneWayExitHash {
        my $self = shift;
        if ( ! exists $self->{oneWayExitHash} )
            { return %{$axmud::DEFAULT_ROOM->{oneWayExitHash}}; }
        else
            { return %{$self->{oneWayExitHash}}; }
    }
    sub invRepExitHash {
        my $self = shift;
        if ( ! exists $self->{invRepExitHash} )
            { return %{$axmud::DEFAULT_ROOM->{invRepExitHash}}; }
        else
            { return %{$self->{invRepExitHash}}; }
    }
    sub randomExitHash {
        my $self = shift;
        if ( ! exists $self->{randomExitHash} )
            { return %{$axmud::DEFAULT_ROOM->{randomExitHash}}; }
        else
            { return %{$self->{randomExitHash}}; }
    }
    sub checkedDirHash {
        my $self = shift;
        if ( ! exists $self->{checkedDirHash} )
            { return %{$axmud::DEFAULT_ROOM->{checkedDirHash}}; }
        else
            { return %{$self->{checkedDirHash}}; }
    }
    sub wildMode {
        if ( ! exists $_[0]->{wildMode} )
            { $axmud::DEFAULT_ROOM->{wildMode} } else { $_[0]->{wildMode} }
    }

    sub titleList {
        my $self = shift;
        if ( ! exists $self->{titleList} )
            { return @{$axmud::DEFAULT_ROOM->{titleList}}; }
        else
            { return @{$self->{titleList}}; }
    }
    sub descripHash {
        my $self = shift;
        if ( ! exists $self->{descripHash} )
            { return %{$axmud::DEFAULT_ROOM->{descripHash}}; }
        else
            { return %{$self->{descripHash}}; }
    }
    sub unspecifiedPatternList {
        my $self = shift;
        if ( ! exists $self->{unspecifiedPatternList} )
            { return @{$axmud::DEFAULT_ROOM->{unspecifiedPatternList}}; }
        else
            { return @{$self->{unspecifiedPatternList}}; }
    }
    sub unspecifiedFlag {
        if ( ! exists $_[0]->{unspecifiedFlag} )
            { $axmud::DEFAULT_ROOM->{unspecifiedFlag} } else { $_[0]->{unspecifiedFlag} }
    }
    sub currentlyDarkFlag {
        if ( ! exists $_[0]->{currentlyDarkFlag} )
            { $axmud::DEFAULT_ROOM->{currentlyDarkFlag} } else { $_[0]->{currentlyDarkFlag} }
    }

    sub sortedExitList {
        my $self = shift;
        if ( ! exists $self->{sortedExitList} )
            { return @{$axmud::DEFAULT_ROOM->{sortedExitList}}; }
        else
            { return @{$self->{sortedExitList}}; }
    }
    sub exitNumHash {
        my $self = shift;
        if ( ! exists $self->{exitNumHash} )
            { return %{$axmud::DEFAULT_ROOM->{exitNumHash}}; }
        else
            { return %{$self->{exitNumHash}}; }
    }
    sub failExitPatternList {
        my $self = shift;
        if ( ! exists $self->{failExitPatternList} )
            { return @{$axmud::DEFAULT_ROOM->{failExitPatternList}}; }
        else
            { return @{$self->{failExitPatternList}}; }
    }
    sub specialDepartPatternList {
        my $self = shift;
        if ( ! exists $self->{specialDepartPatternList} )
            { return @{$axmud::DEFAULT_ROOM->{specialDepartPatternList}}; }
        else
            { return @{$self->{specialDepartPatternList}}; }
    }
    sub involuntaryExitPatternHash {
        my $self = shift;
        if ( ! exists $self->{involuntaryExitPatternHash} )
            { return %{$axmud::DEFAULT_ROOM->{involuntaryExitPatternHash}}; }
        else
            { return %{$self->{involuntaryExitPatternHash}}; }
    }
    sub repulseExitPatternHash {
        my $self = shift;
        if ( ! exists $self->{repulseExitPatternHash} )
            { return %{$axmud::DEFAULT_ROOM->{repulseExitPatternHash}}; }
        else
            { return %{$self->{repulseExitPatternHash}}; }
    }

    sub roomCmdList {
        my $self = shift;
        if ( ! exists $self->{roomCmdList} )
            { return @{$axmud::DEFAULT_ROOM->{roomCmdList}}; }
        else
            { return @{$self->{roomCmdList}}; }
    }
    sub tempRoomCmdList {
        my $self = shift;
        if ( ! exists $self->{tempRoomCmdList} )
            { return @{$axmud::DEFAULT_ROOM->{tempRoomCmdList}}; }
        else
            { return @{$self->{tempRoomCmdList}}; }
    }

    sub visitHash {
        my $self = shift;
        if ( ! exists $self->{visitHash} )
            { return %{$axmud::DEFAULT_ROOM->{visitHash}}; }
        else
            { return %{$self->{visitHash}}; }
    }
    sub exclusiveFlag {
        if ( ! exists $_[0]->{exclusiveFlag} )
            { $axmud::DEFAULT_ROOM->{exclusiveFlag} } else { $_[0]->{exclusiveFlag} }
    }
    sub exclusiveHash {
        my $self = shift;
        if ( ! exists $self->{exclusiveHash} )
            { return %{$axmud::DEFAULT_ROOM->{exclusiveHash}}; }
        else
            { return %{$self->{exclusiveHash}}; }
    }

    sub roomFlagHash {
        my $self = shift;
        if ( ! exists $self->{roomFlagHash} )
            { return %{$axmud::DEFAULT_ROOM->{roomFlagHash}}; }
        else
            { return %{$self->{roomFlagHash}}; }
    }
    sub lastRoomFlag {
        if ( ! exists $_[0]->{lastRoomFlag} )
            { $axmud::DEFAULT_ROOM->{lastRoomFlag} } else { $_[0]->{lastRoomFlag} }
    }

    sub virtualAreaPath {
        if ( ! exists $_[0]->{virtualAreaPath} )
            { $axmud::DEFAULT_ROOM->{virtualAreaPath} } else { $_[0]->{virtualAreaPath} }
    }

    sub protocolRoomHash {
        my $self = shift;
        if ( ! exists $self->{protocolRoomHash} )
            { return %{$axmud::DEFAULT_ROOM->{protocolRoomHash}}; }
        else
            { return %{$self->{protocolRoomHash}}; }
    }
    sub protocolExitHash {
        my $self = shift;
        if ( ! exists $self->{protocolExitHash} )
            { return %{$axmud::DEFAULT_ROOM->{protocolExitHash}}; }
        else
            { return %{$self->{protocolExitHash}}; }
    }

    sub tempObjList {
        my $self = shift;
        if ( ! exists $self->{tempObjList} )
            { return @{$axmud::DEFAULT_ROOM->{tempObjList}}; }
        else
            { return @{$self->{tempObjList}}; }
    }
    sub hiddenObjHash {
        my $self = shift;
        if ( ! exists $self->{hiddenObjHash} )
            { return %{$axmud::DEFAULT_ROOM->{hiddenObjHash}}; }
        else
            { return %{$self->{hiddenObjHash}}; }
    }
    sub searchHash {
        my $self = shift;
        if ( ! exists $self->{searchHash} )
            { return %{$axmud::DEFAULT_ROOM->{searchHash}}; }
        else
            { return %{$self->{searchHash}}; }
    }

    sub nounList {
        my $self = shift;
        if ( ! exists $self->{nounList} )
            { return @{$axmud::DEFAULT_ROOM->{nounList}}; }
        else
            { return @{$self->{nounList}}; }
    }
    sub adjList {
        my $self = shift;
        if ( ! exists $self->{adjList} )
            { return @{$axmud::DEFAULT_ROOM->{adjList}}; }
        else
            { return @{$self->{adjList}}; }
    }

    sub arriveScriptList {
        my $self = shift;
        if ( ! exists $self->{arriveScriptList} )
            { return @{$axmud::DEFAULT_ROOM->{arriveScriptList}}; }
        else
            { return @{$self->{arriveScriptList}}; }
    }
}

{ package Games::Axmud::ModelObj::Weapon;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'weapon' model object
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the weapon, e.g. 'sword' - usually the same as $self->noun
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the room where this object is found, the shop from
        #                   which it can be bought or the NPC from which it is liberated ('undef'
        #                   if there is no parent object or it this is a non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'weapon');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = TRUE;
        $self->{aliveFlag}              = FALSE;
        $self->{sentientFlag}           = FALSE;
        $self->{portableFlag}           = TRUE;
        $self->{saleableFlag}           = TRUE;
        $self->{privateHash}            = {};

        # Set group 2 IVs (but leave other IVs set to their default values)
        $self->{noun}                   = $name;
        # No group 3 IVs for weapons
        # Set group 4 IVs (but leave other IVs set to their default values)
        $self->{explicitFlag}           = TRUE;
        $self->{fixableFlag}            = TRUE;
        $self->{sellableFlag}           = TRUE;
        # No group 5 IVs for weapons

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs (none for this object)
}

{ package Games::Axmud::ModelObj::Armour;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'armour' model object
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the armour, e.g. 'shield' - usually the same as $self->noun
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the room where this object is found, the shop from
        #                   which it can be bought or the NPC from which it is liberated ('undef'
        #                   if there is no parent object or it this is a non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'armour');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = TRUE;
        $self->{aliveFlag}              = FALSE;
        $self->{sentientFlag}           = FALSE;
        $self->{portableFlag}           = TRUE;
        $self->{saleableFlag}           = TRUE;
        $self->{privateHash}            = {};

        # Set group 2 IVs (but leave other IVs set to their default values)
        $self->{noun}                   = $name;
        # No group 3 IVs for armours
        # Set group 4 IVs (but leave other IVs set to their default values)
        $self->{explicitFlag}           = TRUE;
        $self->{fixableFlag}            = TRUE;
        $self->{sellableFlag}           = TRUE;
        # No group 5 IVs for armours

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs (none for this object)
}

{ package Games::Axmud::ModelObj::Garment;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'garment' model object
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the garment, e.g. 'shirt' - usually the same as $self->noun
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the room where this object is found, the shop from
        #                   which it can be bought or the NPC from which it is liberated ('undef'
        #                   if there is no parent object or it this is a non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'garment');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = TRUE;
        $self->{aliveFlag}              = FALSE;
        $self->{sentientFlag}           = FALSE;
        $self->{portableFlag}           = TRUE;
        $self->{saleableFlag}           = TRUE;
        $self->{privateHash}            = {};

        # Set group 2 IVs (but leave other IVs set to their default values)
        $self->{noun}                   = $name;
        # No group 3 IVs for garments
        # Set group 4 IVs (but leave other IVs set to their default values)
        $self->{explicitFlag}           = TRUE;
        $self->{fixableFlag}            = TRUE;
        $self->{sellableFlag}           = TRUE;
        # No group 5 IVs for garments

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs (none for this object)
}

{ package Games::Axmud::ModelObj::Char;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'character' model object (which represents a character on
        #   the world which isn't the one you're using at the moment)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - The character's name (absolute max 32 chars)
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the parent object; probably never used, but the
        #                   parent could conceivably be a 'custom' model object
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Special check (for character and minion objects only) - name must not be longer than 32
        #   chars
        if (! $axmud::CLIENT->nameCheck($name, 32)) {

            return $session->writeError('Illegal name \'' . $name . '\'', $class . '->new');
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'char');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = TRUE;
        $self->{aliveFlag}              = TRUE;
        $self->{sentientFlag}           = TRUE;
        $self->{portableFlag}           = FALSE;
        $self->{saleableFlag}           = FALSE;
        $self->{privateHash}            = {};

        # Set group 2 IVs (but leave other IVs set to their default values)
        $self->{noun}                   = $name;
        # Group 3 IVs - use default values
        # No group 4 IVs for characters

        # Set group 5 IVs
        # The character's guild, if known ('undef' if not)
        $self->{guild}                  = undef;
        # The character's race, if known ('undef' if not)
        $self->{race}                   = undef;
        # Flag set to TRUE if this character is owned by you, FALSE if it is owned by someone else
        $self->{ownCharFlag}            = FALSE;
        # A string representing the owner of the character. Can be set to anything - the owner's
        #   real-life name, or their nickname, or the name of their main character. Characters owned
        #   by you can also have this set to anything - 'me' or 'HandsomeKing', etc
        $self->{owner}                  = undef;

        # What sort of character is this? ('mortal' for an ordinary character, 'wiz' for any kind of
        #   admin, immortal or coder, 'test' for one of the world's official playtesting characters
        #   at the world, if they're allowed)
        $self->{mortalStatus}           = 'mortal';

        # Diplomatic status
        # Can mark this character as 'friendly', 'neutral' or 'hostile'
        $self->{diplomaticStatus}       = 'neutral';
        # Flag set to TRUE if this character has ever attacked one of yours, FALSE if not
        $self->{grudgeFlag}             = FALSE;
        # What to do, if this character attacks you. Flag set to TRUE for 'fight', FALSE for 'run
        #   away'
        $self->{fightBackFlag}          = FALSE;

        # The character's level (if known exactly, 0 if not)
        $self->{level}                  = 0;
        # If the exact level isn't known, a level for which the character is definitely stronger
        #   (approximate)
        $self->{weakerLevel}            = 0;
        # If the exact level isn't known, a level for which the character is definitely weaker
        #   (approximate)
        $self->{strongerLevel}          = 0;
        # Other info about the character, if known ('undef' if not)
        $self->{totalXP}                = undef;
        $self->{totalQP}                = undef;
        # List of quests the character has completed (if known)
        $self->{questList}              = [];

        # What the character was carrying, last time they were seen (just a simple list of strings
        #   - not linked to model objects)
        $self->{inventoryList}          = [];

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs
    sub guild
        { $_[0]->{guild} }
    sub race
        { $_[0]->{race} }
    sub ownCharFlag
        { $_[0]->{ownCharFlag} }
    sub owner
        { $_[0]->{owner} }

    sub mortalStatus
        { $_[0]->{mortalStatus} }

    sub diplomaticStatus
        { $_[0]->{diplomaticStatus} }
    sub grudgeFlag
        { $_[0]->{grudgeFlag} }
    sub fightBackFlag
        { $_[0]->{fightBackFlag} }

    sub level
        { $_[0]->{level} }
    sub weakerLevel
        { $_[0]->{weakerLevel} }
    sub strongerLevel
        { $_[0]->{strongerLevel} }
    sub totalXP
        { $_[0]->{totalXP} }
    sub totalQP
        { $_[0]->{totalQP} }
    sub questList
        { my $self = shift; return @{$self->{questList}}; }

    sub inventoryList
        { my $self = shift; return @{$self->{inventoryList}}; }
}

{ package Games::Axmud::ModelObj::Minion;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'minion' model object (which represents a non-player
        #   character directly controlled - at the moment, or in general - by a character)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - The minion's name (absolute max 32 chars)
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the parent object; probably never used, but the
        #                   parent could conceivably be a 'custom' model object
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Special check (for character and minion objects only) - name must not be longer than 32
        #   chars
        if (! $axmud::CLIENT->nameCheck($name, 32)) {

            return $session->writeError('Illegal name \'' . $name . '\'', $class . '->new');
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'minion');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = TRUE;
        $self->{aliveFlag}              = TRUE;
        $self->{sentientFlag}           = TRUE;         # Minions are made sentient by default
        $self->{portableFlag}           = FALSE;
        $self->{saleableFlag}           = FALSE;
        $self->{privateHash}            = {};

        # Set group 2 IVs (but leave other IVs set to their default values)
        $self->{noun}                   = $name;
        # Group 3 IVs - use default values
        # No group 4 IVs for minions

        # Set group 5 IVs
        # The minion's guild, if known ('undef' if not)
        $self->{guild}                  = undef;
        # The minion's race, if known ('undef' if not)
        $self->{race}                   = undef;
        # Flag set to TRUE if this minion is owned by you, FALSE if it is owned by someone else
        $self->{ownMinionFlag}          = FALSE;

        # The minion's level (if known exactly, 0 if not)
        $self->{level}                  = 0;
        # If the exact level isn't known, a level for which the minion is definitely stronger
        #   (approximate)
        $self->{weakerLevel}            = 0;
        # If the exact level isn't known, a level for which the minion is definitely weaker
        #   (approximate)
        $self->{strongerLevel}          = 0;

        # What the minion was carrying, last time they were seen (just a simple list of strings -
        #   not linked to model objects)
        $self->{inventoryList}          = [];

        # The cost of acquiring this minion (if it can be bought), in the world profile's standard
        #   currency unit
        $self->{value}                  = 0;

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs
    sub guild
        { $_[0]->{guild} }
    sub race
        { $_[0]->{race} }
    sub ownMinionFlag
        { $_[0]->{ownMinionFlag} }

    sub level
        { $_[0]->{level} }
    sub weakerLevel
        { $_[0]->{weakerLevel} }
    sub strongerLevel
        { $_[0]->{strongerLevel} }

    sub inventoryList
        { my $self = shift; return @{$self->{inventoryList}}; }

    sub value
        { $_[0]->{value} }
}

{ package Games::Axmud::ModelObj::Sentient;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'sentient' model object (representing an NPC capable of
        #   language, at least in theory)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the sentient, e.g. 'guard' - usually the same as $self->noun
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the room where this object is found or the region in
        #                   which it wanders ('undef' if there is no parent object or it this is a
        #                   non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'sentient');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = TRUE;
        $self->{aliveFlag}              = TRUE;
        $self->{sentientFlag}           = TRUE;
        $self->{portableFlag}           = FALSE;
        $self->{saleableFlag}           = FALSE;
        $self->{privateHash}            = {};

        # Set group 2 IVs (but leave other IVs set to their default values)
        $self->{noun}                   = $name;
        # Group 3 IVs - use default values
        # No group 4 IVs for sentients

        # Set group 5 IVs
        # The sentient's guild, if known  ('undef' if not)
        $self->{guild}                  = undef,
        # The sentient's race, if known ('undef' if not)
        $self->{race}                   = undef,

        # Flag set to TRUE if the sentient has ever said anything, FALSE if not
        $self->{talkativeFlag}          = FALSE;
        # List of things the sentient has said (a list of strings)
        $self->{talkList}               = [];
        # Flag set to TRUE if the sentient has ever been noticed performing an action, FALSE if not
        $self->{actionFlag}             = FALSE;
        # List of text received when the sentient performs an action
        $self->{actionList}             = [];
        # Flag set to TRUE if the sentient has ever initiated combat, FALSE if not
        $self->{unfriendlyFlag}         = FALSE;
        # Whether the sentient is 'good', 'evil' or 'neutral' (default is neutral)
        $self->{morality}               = 'neutral';

        # Flag set to TRUE if the sentient tends to wander around of its own volition, FALSE if not
        $self->{wanderFlag}             = FALSE;
        # Flag set to TRUE if the sentient has ever fleed combat, FALSE if not
        $self->{fleeFlag}               = FALSE;
        # Flag set to TRUE if the sentient tends to flee combat quickly, FALSE if not
        $self->{quickFleeFlag}          = FALSE;
        # Flag set to TRUE if this sentient should NEVER be attacked, FALSE if not
        $self->{noAttackFlag}           = FALSE;
        # Flag set to TRUE if this sentient mercies, rather than kills, its opponents; FALSE if not
        $self->{mercyFlag}              = FALSE;
        # The name of the quest with which this sentient is associated ('undef' if no quest)
        $self->{questName}              = undef;

        # The sentient's level (if known exactly, 0 if not)
        $self->{level}                  = 0;
        # If the exact level isn't known, a level for which the sentient is definitely stronger
        #   (approximate)
        $self->{weakerLevel}            = 0;
        # If the exact level isn't known, a level for which the sentient is definitely weaker
        #   (approximate)
        $self->{strongerLevel}          = 0;

        # What the sentient was carrying, last time it was seen (just a simple list of strings
        #   - not linked to model objects)
        $self->{inventoryList}          = [];
        # Every time the sentient's cash is stolen, the amount is entered into this list (until the
        #   list contains ten entries) - from this, the average amount of cash carried by the
        #   sentient can be generated
        $self->{cashList}               = [];

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs
    sub guild
        { $_[0]->{guild} }
    sub race
        { $_[0]->{race} }

    sub talkativeFlag
        { $_[0]->{talkativeFlag} }
    sub talkList
        { my $self = shift; return @{$self->{talkList}}; }
    sub actionFlag
        { $_[0]->{actionFlag} }
    sub actionList
        { my $self = shift; return @{$self->{actionList}}; }
    sub unfriendlyFlag
        { $_[0]->{unfriendlyFlag} }
    sub morality
        { $_[0]->{morality} }

    sub wanderFlag
        { $_[0]->{wanderFlag} }
    sub fleeFlag
        { $_[0]->{fleeFlag} }
    sub quickFleeFlag
        { $_[0]->{quickFleeFlag} }
    sub noAttackFlag
        { $_[0]->{noAttackFlag} }
    sub mercyFlag
        { $_[0]->{mercyFlag} }
    sub questName
        { $_[0]->{questName} }

    sub level
        { $_[0]->{level} }
    sub weakerLevel
        { $_[0]->{weakerLevel} }
    sub strongerLevel
        { $_[0]->{strongerLevel} }

    sub inventoryList
        { my $self = shift; return @{$self->{inventoryList}}; }
    sub cashList
        { my $self = shift; return @{$self->{cashList}}; }
}

{ package Games::Axmud::ModelObj::Creature;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'creature' model object (representing an NPC not capable of
        #   language, at least in theory)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the creature, e.g. 'spider' - usually the same as $self->noun
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the room where this object is found or the region in
        #                   which it wanders ('undef' if there is no parent object or it this is a
        #                   non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'creature');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = TRUE;
        $self->{aliveFlag}              = TRUE;
        $self->{sentientFlag}           = FALSE;
        $self->{portableFlag}           = FALSE;
        $self->{saleableFlag}           = FALSE;
        $self->{privateHash}            = {};

        # Set group 2 IVs (but leave other IVs set to their default values)
        $self->{noun}                   = $name;
        # Group 3 IVs - use default values
        # No group 4 IVs for creatures

        # Set group 5 IVs
        # The creature's guild, if known  ('undef' if not)
        $self->{guild}                  = undef,
        # The creature's race, if known ('undef' if not)
        $self->{race}                   = undef,

        # Flag set to TRUE if the creature has ever been noticed performing an action, FALSE if not
        $self->{actionFlag}             = FALSE;
        # List of text received when the creature performs an action
        $self->{actionList}             = [];
        # Flag set to TRUE if the creature has ever initiated combat, FALSE if not
        $self->{unfriendlyFlag}         = FALSE;
        # Whether the creature is 'good', 'evil' or 'neutral' (default is neutral)
        $self->{morality}               = 'neutral';

        # Flag set to TRUE if the creature tends to wander around of its own volition, FALSE if not
        $self->{wanderFlag}             = FALSE;
        # Flag set to TRUE if the creature has ever fleed combat, FALSE if not
        $self->{fleeFlag}               = FALSE;
        # Flag set to TRUE if the creature tends to flee combat quickly, FALSE if not
        $self->{quickFleeFlag}          = FALSE;
        # Flag set to TRUE if this creature should NEVER be attacked, FALSE if not
        $self->{noAttackFlag}           = FALSE;
        # Flag set to TRUE if this creature mercies, rather than kills, its opponents; FALSE if not
        $self->{mercyFlag}              = FALSE;
        # The name of the quest with which this creature is associated ('undef' if no quest)
        $self->{questName}              = undef;

        # The creature's level (if known exactly, 0 if not)
        $self->{level}                  = 0;
        # If the exact level isn't known, a level for which the creature is definitely stronger
        #   (approximate)
        $self->{weakerLevel}            = 0;
        # If the exact level isn't known, a level for which the creature is definitely weaker
        #   (approximate)
        $self->{strongerLevel}          = 0;

        # What the creature was carrying, last time it was seen (just a simple list of strings
        #   - not linked to model objects)
        $self->{inventoryList}          = [];
        # Every time the creature's cash is stolen, the amount is entered into this list (until the
        #   list contains ten entries) - from this, the average amount of cash carried by the
        #   creature can be generated
        $self->{cashList}               = [];

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs
    sub guild
        { $_[0]->{guild} }
    sub race
        { $_[0]->{race} }

    sub actionFlag
        { $_[0]->{actionFlag} }
    sub actionList
        { my $self = shift; return @{$self->{actionList}}; }
    sub unfriendlyFlag
        { $_[0]->{unfriendlyFlag} }
    sub morality
        { $_[0]->{morality} }

    sub wanderFlag
        { $_[0]->{wanderFlag} }
    sub fleeFlag
        { $_[0]->{fleeFlag} }
    sub quickFleeFlag
        { $_[0]->{quickFleeFlag} }
    sub noAttackFlag
        { $_[0]->{noAttackFlag} }
    sub mercyFlag
        { $_[0]->{mercyFlag} }
    sub questName
        { $_[0]->{questName} }

    sub level
        { $_[0]->{level} }
    sub weakerLevel
        { $_[0]->{weakerLevel} }
    sub strongerLevel
        { $_[0]->{strongerLevel} }

    sub inventoryList
        { my $self = shift; return @{$self->{inventoryList}}; }
    sub cashList
        { my $self = shift; return @{$self->{cashList}}; }
}

{ package Games::Axmud::ModelObj::Portable;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'portable' model object (representing any object that can be
        #   picked up, at least in theory, and which isn't a weapon, armour or garment)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the portable, e.g. 'bucket' - usually the same as $self->noun
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the room where this object is found, the shop from
        #                   which it can be bought or the NPC from which it is liberated ('undef'
        #                   if there is no parent object or it this is a non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'portable');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = TRUE;
        $self->{aliveFlag}              = FALSE;
        $self->{sentientFlag}           = FALSE;
        $self->{portableFlag}           = TRUE;
        $self->{saleableFlag}           = TRUE;
        $self->{privateHash}            = {};

        # Set group 2 IVs (but leave other IVs set to their default values)
        $self->{noun}                   = $name;
        # No group 3 IVs for portables
        # Set group 4 IVs (but leave other IVs set to their default values)
        $self->{explicitFlag}           = TRUE;
        $self->{fixableFlag}            = FALSE;
        $self->{sellableFlag}           = TRUE;

        # Set group 5 IVs
        # The object's type (matches a portable type in the dictionary object)
        $self->{type}                   = 'other';

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs
    sub type
        { $_[0]->{type} }
}

{ package Games::Axmud::ModelObj::Decoration;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'decoration' model object (representing any object that
        #   can't be picked up, at least in theory, but which can be interacted with)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the decoration, e.g. 'curtain' - usually the same as
        #                   $self->noun
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the room where this object is found ('undef' if
        #                   there is no parent object or it this is a non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'decoration');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
        $self->{concreteFlag}           = TRUE;
        $self->{aliveFlag}              = FALSE;
        $self->{sentientFlag}           = FALSE;
        $self->{portableFlag}           = FALSE;
        $self->{saleableFlag}           = FALSE;
        $self->{privateHash}            = {};

        # Set group 2 IVs (but leave other IVs set to their default values)
        $self->{noun}                   = $name;
        # No group 3 IVs for decorations
        # Set group 4 IVs (but leave other IVs set to their default values)
        $self->{explicitFlag}           = FALSE;
        $self->{fixableFlag}            = FALSE;
        $self->{sellableFlag}           = FALSE;

        # Set group 5 IVs
        # The object's type (matches a decoration type in the dictionary object)
        $self->{type}                   = 'other';

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs
    sub type
        { $_[0]->{type} }
}

{ package Games::Axmud::ModelObj::Custom;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::ModelObj Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the 'custom' model object (which can represent any concept)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the custom object, e.g. 'big_idea'
        #   $modelFlag  - TRUE if this is a model object, FALSE if it's a non-model object
        #
        # Optional arguments
        #   $parent     - World model number of the parent object ('undef' if there is no parent
        #                   object or it this is a non-model object)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $modelFlag, $parent, $check) = @_;

        # Local variables
        my ($parentFile, $parentProf);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $modelFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($modelFlag) {

            $parentFile = 'worldmodel';
            $parentProf = $session->currentWorld->name;
        }

        # Setup
        my $self = Games::Axmud::Generic::ModelObj->new($session, $name, 'custom');

        # Set standard IVs
        $self->{_objName}               = $name;
        $self->{_objClass}              = $class;
        $self->{_parentFile}            = $parentFile;      # May be 'undef'
        $self->{_parentWorld}           = $parentProf;      # May be 'undef'
        $self->{_privFlag}              = FALSE,            # All IVs are public

        # Set group 1 IVs (most should be set separately for each instance of this object)
        $self->{parent}                 = $parent;
        $self->{childHash}              = {};
#       $self->{concreteFlag}           = FALSE;
#       $self->{aliveFlag}              = FALSE;
#       $self->{sentientFlag}           = FALSE;
#       $self->{portableFlag}           = FALSE;
#       $self->{saleableFlag}           = FALSE;
#       $self->{privateHash}            = {};

        # Group 2 IVs - use default values
        # No group 3 IVs for custom model objects
        # Group 4 IVs - use default values
        # No group 5 IVs for custom model objects

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 5 IVs (none for this object)
}

# Package must return a true value
1
