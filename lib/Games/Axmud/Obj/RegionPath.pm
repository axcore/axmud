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
# Games::Axmud::Obj::RegionPath
# Contains a path between two region exits in the same region

{ package Games::Axmud::Obj::RegionPath;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::WorldModel->connectRegionExits, ->replaceRegionPath and
        #   ->findUniversalPath
        #
        # Create a new instance of the region path object, which stores the shortest path between
        #   two exits in a region, both of which are region exits (which lead to a room in a
        #   different region). The path is used for quick pathfinding between two rooms in
        #   different regions
        #
        # Expected arguments
        #   $session        - The parent GA::Session (not stored as an IV)
        #   $startExit      - The number of the GA::Obj::Exit at the start of the path, whose
        #                       destination room is in a different region
        #   $stopExit       - The number of the GA::Obj::Exit at the end of the path, whose
        #                       destination room is in a different region (possibly the same region
        #                       as $startExit's destination room)
        #   $roomListRef    - Reference to a list of numbers of room objects along the path
        #   $exitListRef    - Reference to a list of numbers of exit objects which connect them.
        #                       The list will contain one less item than $roomListRef
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $startExit, $stopExit, $roomListRef, $exitListRef, $check) = @_;

        # Local variables
        my (@roomList, @exitList);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $startExit || ! defined $stopExit
            || ! defined $roomListRef || ! defined $exitListRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Convert $roomListRef, a reference to a list of room objects, into @roomList, a list of
        #   model object numbers
        foreach my $obj (@$roomListRef) {

            push (@roomList, $obj->number);
        }

        # Convert $exitListRef, a reference to a list of exit objects, into @exitList, a list of
        #   exit model numbers
        foreach my $obj (@$exitListRef) {

            push (@exitList, $obj->number);
        }

        # Setup
        my $self = {
            _objName                    => 'region_path',
            _objClass                   => $class,
            _parentFile                 => 'worldmodel',
            _parentWorld                => $session->currentWorld->name,
            # All IVs are private, but should usually be set with calls to the GA::Obj::WorldModel
            #   object
            _privFlag                   => TRUE,

            # Object IVs
            # ----------

            # The number of the GA::Obj::Exit at the start of the path, whose destination room is
            #   in a different region
            startExit                   => $startExit,
            # The number of the GA::Obj::Exit at the end of the path, whose destination room is in
            #   a different region (possibly the same region as $startExit's destination room)
            stopExit                    => $stopExit,
            # List of numbers of room objects along the path
            roomList                    => \@roomList,
            # List of numbers of exit objects which connect the rooms in $self->roomList. This list
            #   will contain one less item than $self->roomList
            exitList                    => \@exitList,
            # Shortcut to the number of rooms in ->roomList
            roomCount                   => scalar @roomList,
        };

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

    sub startExit
        { $_[0]->{startExit} }
    sub stopExit
        { $_[0]->{stopExit} }
    sub roomList
        { my $self = shift; return @{$self->{roomList}}; }
    sub exitList
        { my $self = shift; return @{$self->{exitList}}; }
    sub roomCount
        { $_[0]->{roomCount} }
}

# Package must return a true value
1
