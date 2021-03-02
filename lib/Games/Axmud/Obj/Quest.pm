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
# Games::Axmud::Obj::Quest
# Handles quests

{ package Games::Axmud::Obj::Quest;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Cmd::AddQuest->do
        # Creates a new instance of the quest object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this quest (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid and not already in use by another quest (quests are stored
        #   in the current world profile)
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );

        } elsif ($session->currentWorld->ivExists('questHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: current world profile already has a quest called \''
                . $name . '\'',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,                       # All IVs are public

            # IVs
            # ---

            # A unique name for the quest (max 16 chars)
            name                        => $name,
            # If this quest can be solved with a stored mission, the name of the mission ('undef' if
            #   not)
            missionName                 => undef,

            # How many quest points the quest is worth (0 if not known, or not applicable)
            questPoints                 => 0,
            # How much XP the quest is worth (0 if not known, or not applicable)
            questXP                     => 0,
            # How much cash (in the world profile's standard unit) the quest is worth (0 if now
            #   known, or not applicable)
            questCash                   => 0,

            # A list containing lines of text, where you can a store a solution (if you want to)
            solutionList                => [],
            # A list containing lines of text, where you can store comments (if you want to)
            commentList                 => [],

            # A hash where you can store any values you like. The keys shouldn't be longer than 16
            #   characters, so the ';listquest' command can display them properly
            privateHash                 => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Called by GA::Cmd::CloneQuest->do
        # Creates a clone of an existing quest object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function
        #   $name       - A unique string name for this quest object (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Check that $name is valid and not already in use by another quest (quests are stored
        #   in the current world profile)
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->new',
            );

        } elsif ($session->currentWorld->ivExists('questHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: current world profile already has a quest called \''
                . $name . '\'',
                $self->_objClass . '->new',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,                       # All IVs are public

            # IVs
            # ---

            name                        => $name,
            missionName                 => $self->missionName,

            questPoints                 => $self->questPoints,
            questXP                     => $self->questXP,
            questCash                   => $self->questCash,

            solutionList                => [$self->solutionList],
            commentList                 => [$self->commentList],

            privateHash                 => {$self->privateHash},
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub missionName
        { $_[0]->{missionName} }

    sub questPoints
        { $_[0]->{questPoints} }
    sub questXP
        { $_[0]->{questXP} }
    sub questCash
        { $_[0]->{questCash} }

    sub solutionList
        { my $self = shift; return @{$self->{solutionList}}; }
    sub commentList
        { my $self = shift; return @{$self->{commentList}}; }

    sub privateHash
        { my $self = shift; return %{$self->{privateHash}}; }
}

# Package must return a true value
1
