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
# Games::Axmud::Node::XXX
# Module containing node objects for the GA::Obj::WorldModel object's pathfinding algorithms

{ package Games::Axmud::Node::AStar;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::WorldModel->findPath and ->doAStar
        # Create a new instance of the A star algorithm node. When looking for the shortest path
        #   between two rooms in the same region, one node object is created for every
        #   GA::ModelObj::Room considered for inclusion in the path
        #
        # Expected arguments
        #   $roomObj    - The GA::ModelObj::Room for this node
        #   $gScore     - The node's initial g score
        #   $hScore     - The node's initial h score
        #
        # Return values
        #   'undef' on failure
        #   Blessed reference to the newly-created object on success

        my ($class, $roomObj, $gScore, $hScore) = @_;

        # (No checking for improper arguments - we want maximum speed)

        # Setup
        my $self = {
            _objName                    => 'a_star_node_' . $roomObj->number,
            _objClass                   => $class,
            _parentFile                 => undef,           # No parent file object
            _parentWorld                => undef,           # No parent file object
            _privFlag                   => FALSE,           # All IVs are public

            # Object IVs
            # ----------

            roomObj                     => $roomObj,        # A GA::ModelObj::Room
            arriveExitObj               => undef,           # A GA::Obj::Exit, set later

            gScore                      => $gScore,
            hScore                      => $hScore,
            fScore                      => $gScore + $hScore,
            parent                      => undef,           # A GA::ModelObj::Room
            cost                        => 0,               # Estimated cost of moving to the target
            inOpenFlag                  => FALSE,           # In open list stored in a binomial heap
            heap                        => undef,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub cmp {

        # Called by the open list stored in the binomial heap used by the world model's A* algorithm
        # Compares this node against another node, and returns the one with the lower F score
        #
        # Expected arguments
        #   $otherNode  - The GA::Node::AStar to compare with this one
        #
        # Return values
        #   Returns the blessed reference of either this node, or $otherNode, depending on which has
        #       the lower F score

        my ($self, $otherNode, $check) = @_;

        # (No checking for improper arguments - we want maximum speed)

        return ($self->fScore <=> $otherNode->fScore);
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub roomObj
        { $_[0]->{roomObj} }
    sub arriveExitObj
        { $_[0]->{arriveExitObj} }

    sub gScore
        { $_[0]->{gScore} }
    sub hScore
        { $_[0]->{hScore} }
    sub fScore
        { $_[0]->{fScore} }
    sub parent
        { $_[0]->{parent} }
    sub cost
        { $_[0]->{cost} }
    sub inOpenFlag
        { $_[0]->{inOpenFlag} }
    sub heap
        { $_[0]->{heap} }
}

{ package Games::Axmud::Node::Dijkstra;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::WorldModel->findUniversalPath
        # Create a new instance of the Dijkstra algorithm node. When looking for the shortest path
        #   between two rooms in different regions, one node object is created for every region
        #   exit. A further node is created for a dummy exit leading to the initial room, and
        #   another for a (temporary) exit leading to the target room
        #
        # Also called by GA::Obj::WorldModel->findRoutePath
        # Create a new instance of the Dijkstra algorithm node. When looking for the shortest path
        #   between two rooms using only pre-defined routes (stored in GA::Obj::Route objects),
        #   one node object is created for every tagged room at the beginning or end of a single
        #   route
        #
        # Expected arguments
        #   $gScore     - The node's initial g-score
        #
        # Optional arguments
        #   $exitObj    - The GA::Obj::Exit for this node (set to 'undef' when called by
        #                   ->findRoutePath)
        #   $roomTag    - The room tag for this node (set to 'undef' when called by ->findRoutePath)
        #
        # Return values
        #   'undef' on failure
        #   Blessed reference to the newly-created object on success

        my ($class, $gScore, $exitObj, $roomTag) = @_;

        # Local variables
        my $name;

        # (No checking for improper arguments - we want maximum speed)

        if ($exitObj) {
            $name = 'dijkstra_node_' . $exitObj->number;
        } else {
            $name = 'dijkstra_node_' . $roomTag;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => undef,           # No parent file object
            _parentWorld                => undef,           # No parent file object
            _privFlag                   => FALSE,           # All IVs are public

            # Object IVs
            # ----------

            # The world model uses nodes based on exit objects
            exitObj                     => $exitObj,        # A GA::Obj::Exit
            # The ';drive' command uses nodes based on room tags
            roomTag                     => $roomTag,        # Matches GA::ModelObj::Room->roomTag

            gScore                      => $gScore,
            hScore                      => 0,               # H-score always 0 in Dijkstra algorithm
            fScore                      => $gScore,         # ...so F-score is the same as G-score
            parent                      => undef,           # GA::Obj::Exit
            cost                        => 0,               # Estimated cost of moving to the target
            inOpenFlag                  => FALSE,           # In open list stored in a binomial heap
            heap                        => undef,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub cmp {

        # Called by the open list stored in the binomial heap
        # Compares this node against another node, and returns the one with the lower F score
        #
        # Expected arguments
        #   $otherNode  - The GA::Node::Dijkstra to compare with this one
        #
        # Return values
        #   Returns the blessed reference of either this node, or $otherNode, depending on which has
        #       the lower F score

        my ($self, $otherNode, $check) = @_;

        # (No checking for improper arguments - we want maximum speed)

        return ($self->fScore <=> $otherNode->fScore);
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub exitObj
        { $_[0]->{exitObj} }
    sub roomTag
        { $_[0]->{roomTag} }

    sub gScore
        { $_[0]->{gScore} }
    sub hScore
        { $_[0]->{hScore} }
    sub fScore
        { $_[0]->{fScore} }
    sub parent
        { $_[0]->{parent} }
    sub cost
        { $_[0]->{cost} }
    sub inOpenFlag
        { $_[0]->{inOpenFlag} }
    sub heap
        { $_[0]->{heap} }
}

# Package must return a true value
1
