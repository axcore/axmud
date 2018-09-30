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
# Games::Axmud::Obj::SkillHistory
# Object storing details of the character's history of advancing skills

{ package Games::Axmud::Obj::SkillHistory;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Task::Advance->doStage
        # Creates a new instance of the skill history object
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $skill      - The skill that was being advanced, at the moment this object was created
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $skill, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $skill || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $skill,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _objClass                   => $class,
            _privFlag                   => FALSE,           # All IVs are public

            # IVs
            # ---

            # The skill advanced
            skill                       => $skill,
            # How the skill was advanced ('order' because of the guild profile's ->advanceOrderList,
            #   'cycle' because of the guild profile's ->advanceCycleList, or 'manual' because the
            #   user advanced manually, either because the lists are empty or because the user wants
            #   to ignore them
            advanceMethod               => 'manual',        # Default value

            # The skill's level at the time of being advanced
            skillLevel                  => 0,
            # How many times the skill had been advanced, after this advance
            skillAdvanceCount           => 0,
            # XP spent advancing the skill this time (0 if unknown)
            skillThisXP                 => 0,
            # XP needed to advance the skill, next time (0 if unknown)
            skillNextXP                 => 0,
            # Cash spent advancing the skill this time (0 if unknown)
            skillThisCash               => 0,
            # Cash needed to adance the skill, next time (0 if unknown)
            skillNextCash               => 0,
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

    sub skill
        { $_[0]->{skill} }
    sub advanceMethod
        { $_[0]->{advanceMethod} }

    sub skillLevel
        { $_[0]->{skillLevel} }
    sub skillAdvanceCount
        { $_[0]->{skillAdvanceCount} }
    sub skillThisXP
        { $_[0]->{skillThisXP} }
    sub skillNextXP
        { $_[0]->{skillNextXP} }
    sub skillThisCash
        { $_[0]->{skillThisCash} }
    sub skillNextCash
        { $_[0]->{skillNextCash} }
}

# Package must return a true value
1
