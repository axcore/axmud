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
# Games::Axmud::Obj::Loop
# Loop objects, handling the client loop (in GA::Client) and the session loop (in GA::Session).
#   Implemented using a Glib::Timeout. Not suitable for use with other parts of the code (write your
#   own Glib::Timeout functions!)

{ package Games::Axmud::Obj::Loop;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->startClientLoop and GA::Session->startSessionLoop
        # Creates the GA::Obj::Loop, handling a Glib::Timeout loop on behalf of a GA::Client or
        #   GA::Session
        #
        # Expected arguments
        #   $owner          - The GA::Client or GA::Session on whose behalf the loop is handled
        #   $func           - The function to call when the loop spins (i.e. $owner->$func() )
        #   $type           - The loop type: (GA::Client) 'client', (GA::Session) 'session'
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $owner, $func, $type, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $owner || ! defined $func || ! defined $type
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'loop_' . $type,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # The GA::Client or GA::Session on whose behalf the loop is handled
            owner                       => $owner,
            # The function to call when the loop spins (i.e. $owner->$func() )
            func                        => $func,
            # The loop type: (GA::Client) 'client', (GA::Session) 'session'
            type                        => $type,

            # The Glib::Timeout which spins the loop
            id                          => undef,
            # The loop delay, in seconds (set by $self->startLoop); absolute minimum value of 0.01
            delay                       => undef,
            # The time at which the loop first spun (system time, in seconds)
            startTime                   => undef,
            # The time at which the loop first spun, or which it spun after a restart (having been
            #   suspended due to a Perl error), whichever is later
            restartTime                 => undef,
            # The time at which the loop halted (system time, in seconds)
            stopTime                    => undef,
            # The time at which the loop last spun (seconds after ->startTime)
            spinTime                    => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    sub startLoop {

        # Called by GA::Client->startClientLoop and GA::Session->startSessionLoop
        # Sets up the loop by creating a new Glib::Timeout
        #
        # Expected arguments
        #   $delay      - The loop delay, in seconds. If less than 0.01 is specified, then 0.01 is
        #                   used instead
        #
        # Return values
        #   'undef' on improper arguments or if the loop can't be started
        #   1 on success

        my ($self, $delay, $check) = @_;

        # Local variables
        my $id;

        # Check for improper arguments
        if (! defined $delay || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->startLoop', @_);
        }

        # Set absolute minimum delay
        if ($delay < 0.01) {

            $delay = 0.01;
        }

        # If the loop had already been started (and was suspended after a Perl error), remove the
        #   previous Glib::Timeout
        if ($self->id) {

            # If the old Glib::Timeout had not expired, we'll get a 'GLib-Critical' error; trap it
            #   using an 'eval' statement
            eval { Glib::Source->remove($self->id); };
        }

        # Start the loop. The Glib::Timeout calls $self->func every $self->delay seconds. In the
        #   call to Glib::Timeout->add, we must convert the delay to milliseconds
        $id = Glib::Timeout->add(($delay * 1000), sub{ $self->spinLoop() });
        if (! $id) {

            # The task loop can't be started
            return undef;

        } else {

            # Loop started. If the loop is being re-started after a suspension, we should
            #   continue using the previous loop start time (for the benefit of any code which is
            #   executing its own timeout, for example)
            if (! defined $self->startTime) {

                # Loop started for first time
                $self->ivPoke('startTime', $axmud::CLIENT->getTime());
                $self->ivPoke('restartTime', $self->startTime);

            } else {

                # Loop re-started after a suspension
                $self->ivPoke('restartTime', $axmud::CLIENT->getTime());
            }

            # Update remaining IVs
            $self->ivPoke('id', $id);
            $self->ivPoke('delay', $delay);
            $self->ivPoke('spinTime', 0);

            return 1;
        }
    }

    sub stopLoop {

        # Called by GA::Client->stopClientLoop and GA::Session->stopSessionLoop
        # Stops the loop by terminating the Glib::Timeout
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the loop isn't running or if it can't be stopped
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->stopLoop', @_);
        }

        if (! $self->id) {

            # The loop isn't running
            return undef;
        }

        # Stop the loop
        if (! Glib::Source->remove($self->id)) {

            # Loop wasn't stopped
            return undef;

        } else {

            # Loop stopped. Update IVs
            $self->ivUndef('id');
            $self->ivUndef('delay');

            $self->ivPoke('stopTime', $axmud::CLIENT->getTime());
            $self->ivPoke(
                'spinTime',
                Math::Round::nearest(0.001, ($self->stopTime() - $self->startTime)),
            );

            return 1;
        }
    }

    sub spinLoop {

        # Callback, called by a Glib::Timeout created by $self->startLoop whenever the loop spins
        # Updates IVs and calls the function specified by $self->owner and $self->func
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($owner, $func);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->spin', @_);
        }

        # Import IVs
        $owner = $self->owner;
        $func = $self->func;

        # Do nothing if the owner is currently processing another spin (either from this loop, or
        #   from any other loop with the same owner)
        if (
            ($self->type eq 'client' && $owner->clientLoopSpinFlag)
            || ($self->type eq 'session' && $owner->sessionLoopSpinFlag)
        ) {
            # Do nothing
            return 1;

        } else {

            # Forbid other loop spins with the same owner until this one is finished)
            $owner->set_loopSpinFlag(TRUE);
        }

        # Update IVs. The subtraction produces a system rounding error, so we need to round the
        #   value to 3dp
        $self->ivPoke(
            'spinTime',
            Math::Round::nearest(0.001, ($axmud::CLIENT->getTime() - $self->startTime)),
        );

        # Call the loop's owner
        $owner->$func($self);

        # Spin complete
        $owner->set_loopSpinFlag(FALSE);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub owner
        { $_[0]->{owner} }
    sub func
        { $_[0]->{func} }
    sub type
        { $_[0]->{type} }

    sub id
        { $_[0]->{id} }
    sub delay
        { $_[0]->{delay} }
    sub startTime
        { $_[0]->{startTime} }
    sub restartTime
        { $_[0]->{restartTime} }
    sub stopTime
        { $_[0]->{stopTime} }
    sub spinTime
        { $_[0]->{spinTime} }
}

# Package must return a true value
1
