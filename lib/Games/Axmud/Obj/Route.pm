# Copyright (C) 2011-2022 A S Lewis
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
# Games::Axmud::Obj::Route
# Handles a route between any two tagged rooms

{ package Games::Axmud::Obj::Route;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the route object, which stores a single route between any two
        #   tagged rooms in the world)
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session (not stored as an IV)
        #   $routeType  - 'road' (this route uses the world's roads and paths), 'quick' (this route
        #                   is the quickest path between two rooms), 'circuit' (this route starts
        #                   and stops in the same room)
        #   $startRoom  - The tag of the start room (matches GA::ModelObj::Room->roomTag
        #   $otherRoom  - For 'road' and 'quick' routes, the tag of the stop room. For 'circuit'
        #                   routes, the name of the circuit
        #   $route      - The route itself (a single world command, e.g. 'n', a chain of world
        #                   commands, e.g. 'n;open door;n;nw', or a speedwalk command, e.g.
        #                   '.3nw2s'). $route can be a speedwalk command even if the speedwalk sigil
        #                   is turned off (GA::Client->speedSigilFlag is FALSE). If it's a speedwalk
        #                   command, the calling function should have checked it's a valid speedwalk
        #                   command
        #   $hopFlag    - Flag set to TRUE if this route is hoppable (can be combined with other
        #                   routes to make a longer route using the ';drive' etc commands), FALSE if
        #                   not
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $routeType, $startRoom, $otherRoom, $route, $hopFlag, $check) = @_;

        # Local variables
        my (
            $cmdSep,
            @list,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $routeType || ! defined $startRoom
            || ! defined $otherRoom || ! defined $route || ! defined $hopFlag
            || ($routeType ne 'road' && $routeType ne 'quick' && $routeType ne 'circuit')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $startRoom . '_' . $otherRoom,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,                # All IVs are public

            # Object IVs
            # ----------

            # The type of route: 'road' (this route uses the world's roads and paths), 'quick' (this
            #   route is the quickest path between two rooms), 'circuit' (this route starts and
            #   stops in the same room)
            routeType                   => $routeType,
            # The tag of the start room (matches GA::ModelObj::Room->roomTag
            startRoom                   => $startRoom,
            # For 'road' and 'quick' routes, the tag of the stop room. For 'circuit' routes, the
            #   name of the circuit
            stopRoom                    => undef,
            # The name of the circuit (for 'circuit' routes) (set below)
            circuitName                 => undef,
            # The route itself (a single world command, e.g. 'n', a chain of world commands, e.g.
            #   'n;open door;n;nw', or a speedwalk command, e.g. '.3nw2s'). $route can be a
            #   speedwalk command even if the speedwalk sigil is turned off
            #   (GA::Client->speedSigilFlag is FALSE). If it's a speedwalk command, the calling
            #   function should have checked it's a valid speedwalk command
            route                       => $route,

            # Flag set to TRUE if this route is hoppable (can be combined with other routes to make
            #   a longer route using the ';drive' etc commands), FALSE if not
            hopFlag                     => $hopFlag,
            # Number of steps (distinct world commands) in $route (set below)
            stepCount                   => 0,
        };

        # Bless the object into existence
        bless $self, $class;

        # Set the remaining IVs
        if ($routeType eq 'circuit') {
            $self->{circuitName} = $otherRoom;
        } else {
            $self->{stopRoom} = $otherRoom;
        }

        # Count the number of steps (distinct world commands) in $route
        if ($route) {

            $self->resetStepCount($session);
        }

        return $self;
    }

    sub clone {

        # Creates a clone of an existing route object
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session (not stored as an IV)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Setup
        my $clone = {
            _objName                    => $self->_objName,
            _objClass                   => $self->_objClass,
            _parentFile                 => $self->_parentFile,
            _parentWorld                => $self->_parentWorld,
            _privFlag                   => FALSE,                # All IVs are public

            # Object IVs
            # ----------

            routeType                   => $self->routeType,
            startRoom                   => $self->startRoom,
            stopRoom                    => $self->stopRoom,
            circuitName                 => $self->circuitName,
            route                       => $self->route,

            hopFlag                     => $self->hopFlag,
            stepCount                   => $self->stepCount,
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    sub resetStepCount {

        # Called by $self->new or GA::Cmd::AddRoute->do
        # Sets the ->stepCount IV
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the new value of ->stepCount (which may be 0)

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $cmdSep,
            @list,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetStepCount', @_);
        }

        if (index($self->route, $axmud::CLIENT->constSpeedSigil) == 0) {

            # $self->route is a speedwalk command. If it's an invalid speedwalk command, @list will
            #   be empty
            @list = $session->parseSpeedWalk($self->route);

        } else {

            # A single world command or a chain of world commands separated by commmand separators
            $cmdSep = $axmud::CLIENT->cmdSep;
            @list = split(m/$cmdSep/, $self->route);
        }

        $self->ivPoke('stepCount', scalar @list);

        return $self->stepCount;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub routeType
        { $_[0]->{routeType} }
    sub startRoom
        { $_[0]->{startRoom} }
    sub stopRoom
        { $_[0]->{stopRoom} }
    sub circuitName
        { $_[0]->{circuitName} }
    sub route
        { $_[0]->{route} }

    sub hopFlag
        { $_[0]->{hopFlag} }
    sub stepCount
        { $_[0]->{stepCount} }
}

# Package must return a true value
1
