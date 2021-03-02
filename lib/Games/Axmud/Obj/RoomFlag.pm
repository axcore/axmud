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
# Games::Axmud::Obj::RoomFlag
# An object storing settings for a single room flag used by the world model

{ package Games::Axmud::Obj::RoomFlag;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the room flag object (which stores settings for a single room
        #   flag used by the world model)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - The room flag name, e.g. 'blocked_room' (max 16 characters)
        #   $customFlag - TRUE if a custom flag created by the user; FALSE for a built-in room flag
        #
        # Return values
        #   'undef' on improper arguments or if $name is too long
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $customFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $class || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check maximum name length
        if ((length $name) > 16) {

            return undef;
        }

        # $customFlag should be TRUE or FALSE
        if (! $customFlag) {
            $customFlag = FALSE;
        } else {
            $customFlag = TRUE;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'worldmodel',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The room flag name, e.g. 'blocked_room' (max 16 characters)
            name                        => $name,
            # Short version of the name, usually two character (e.g. 'Bl'). Cannot be modified by
            #   the user
            shortName                   => undef,
            # A description for the room flag, e.g. 'Room is blocked'. Cannot be modified by the
            #   user
            descrip                     => undef,

            # This room flag's position in the room flag priority list, with the highest-priority
            #   room flag being 1, and the lowest being a value in the 100s. Can be modified by the
            #   user (indirectly, as the ->priority in all room flag objects must be set at the
            #   same time)
            priority                    => undef,
            # The room filter to which this room flag belongs (one of the values in
            #   GA::Client->constRoomFilterList). Cannot be modified by the user
            filter                      => undef,
            # The colour with which the automapper windows draws a room with this room flag (an
            #   RGB colour tag, e.g. '#ABCDEF'; case-insensitive). Can be modified by the user
            colour                      => undef,

            # Flag set to TRUE for a custom room flag, added by the user (and which can be deleted
            #   by the user); FALSE for a built-in room flag which can't be deleted
            customFlag                  => $customFlag,
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

    sub name
        { $_[0]->{name} }
    sub shortName
        { $_[0]->{shortName} }
    sub descrip
        { $_[0]->{descrip} }

    sub priority
        { $_[0]->{priority} }
    sub filter
        { $_[0]->{filter} }
    sub colour
        { $_[0]->{colour} }

    sub customFlag
        { $_[0]->{customFlag} }
}

# Package must return a true value
1
