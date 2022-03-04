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
# Games::Axmud::Obj::Repeat
# Handles repeating commands (created with ';intervalrepeat')

{ package Games::Axmud::Obj::Repeat;

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
        #   $cmd        - The command to send
        #   $number     - How often to send it (minimum value 1)
        #   $waitTime   - How long to wait between sending each command, in seconds (minimum 1
        #                   second)
        #
        # Return values
        #   'undef' on improper arguments or if $number or $time are invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $cmd, $number, $waitTime, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $cmd || ! defined $number
            || ! defined $waitTime || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $number and $waitTime are valid positive integers
        if ($number =~ /\D/ || $number < 1 || $waitTime =~ /\D/ || $waitTime < 1) {

            return undef;
        }

        # Setup
        my $self = {
            _objName                => $cmd,
            _objClass               => $class,
            _parentFile             => undef,       # No parent file object
            _parentWorld            => undef,       # No parent file object
            _privFlag               => TRUE,        # All IVs are private

            # IVs
            # ---

            # Which command to send
            cmd                         => $cmd,
            # How many more times to send it
            number                      => $number,
            # How long to wait between sending each command (in seconds)
            waitTime                    => $waitTime,
            # The time at which to send the next command, in seconds (matches
            #   GA::Session->sessionTime). The first command is sent on the next session loop
            nextCheckTime               => 0,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub sendCmd {

        # Called by GA::Session->taskLoop when it's time to re-send the command
        # Sends the command and updates IVs
        #
        # Expected arguments
        #   $session    - The parent GA::Session
        #
        # Return values
        #   'undef' on improper arguments or if this object has now finished sending commands
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sendCmd', @_);
        }

        # Send the command
        $session->worldCmd($self->cmd);
        if ($self->number <= 1) {

             # Don't send the command again
            return undef;

        } else {

            # Set the time at which the command will be sent again
            $self->ivDecrement('number');
            $self->ivPoke('nextCheckTime', ($session->sessionTime + $self->waitTime));

            return 1;
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub cmd
        { $_[0]->{cmd} }
    sub number
        { $_[0]->{number} }
    sub waitTime
        { $_[0]->{waitTime} }
    sub nextCheckTime
        { $_[0]->{nextCheckTime} }
}

# Package must return a true value
1
