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
# Games::Axmud::Obj::ConnectHistory
# Stores basic information about previous connections to a world (stored in the world profile)

{ package Games::Axmud::Obj::ConnectHistory;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->doConnect
        # Prepare a new instance of the connection history object (stored in the world profile),
        #   which stores details for each connection (or attempted connection), but not for 'connect
        #   offline' sessions
        #
        # Expected arguments
        #   $session        - The parent GA::Session (not stored as an IV)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $check) = @_;

        # Local variables
        my ($connectingTime, $char);

        # Check for improper arguments
        if (! defined $class || ! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Set initial IV values
        $connectingTime = int($axmud::CLIENT->getTime());
        if ($session->currentChar) {

            $char = $session->currentChar->name;
        }

        # Setup
        my $self = {
            _objName                    => 'connect_history_obj',
            _objClass                   => $class,
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => TRUE,                       # All IVs are private

            # Object IVs
            # ----------

            # System times (all matching Time::HiRes::gettimeofday() )
            # Time at which a connection to the world was attempted (GA::Session->status was set to
            #   'connecting')
            connectingTime              => $connectingTime,
            # Time at which a connection to the world was completed (GA::Session->status was set to
            #   'connected')
            connectedTime               => undef,
            # Time at which a disconnection occured (GA::Session->status was set to 'disconnected')
            # NB Not set when GA::Session->doTempDisconnect is called to temporarily mark the
            #   sesson 'disconnected' during an MXP crosslinking operation
            disconnectedTime            => undef,
            # Axmud may crash, or be terminated suddenly, in which case the end of the connection
            #   won't be recorded. This IV is updated by the GA::Session every second, so that after
            #   a crash, we at least have the time that the world profile's data file was last saved
            currentTime                 => $connectingTime,
            # The length of the connetion, set to 0 when GA::Session->status is set to 'connected',
            #   updated every time ->currentTime is updated, and given a final value when
            #   GA::Session->status is set to 'disconnected'
            connectionLength            => undef,
            # The character profile used by this connection. 'undef' if no current character is set
            #   when the connection is opened (GA::Session->status was set to 'connecting', so
            #   using ';setchar' won't change its value)
            # NB If the user connects to a world without specifying a character, but later types
            #   ';setchar' while still connected, GA::Generic::Cmd->setProfile calls $self->set_char
            #   to set this IV. The IV is not updated in other circumstances, for example if the
            #   current character profile is changed from one to another
            char                        => $char,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    sub set_char {

        # Called by GA::Generic::Cmd->setProfile. Can only be used if $self->char is currently
        #   undefined

        my ($self, $char, $check) = @_;

        # Check for improper arguments
        if (! defined $char || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_char', @_);
        }

        # Update IVs
        if (! defined $self->char) {

            $self->ivPoke('char', $char);
        }

        return 1;
    }

    sub set_connectedTime {

        # Called by Session->connectionComplete

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_connectedTime', @_);
        }

        # Update IVs
        $self->ivPoke('connectedTime', int($axmud::CLIENT->getTime()));
        $self->ivPoke('connectionLength', 0);

        return 1;
    }

    sub set_currentTime {

        # Called by Session->spinMaintainLoop

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_currentTime', @_);
        }

        # Update IVs
        $self->ivPoke('currentTime', int($axmud::CLIENT->getTime()));
        $self->ivPoke('connectionLength', int($self->currentTime) - int($self->connectingTime));

        return 1;
    }

    sub set_disconnectedTime {

        # Called by Session->stop, ->doDisconnect, ->reactDisconnect

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_disconnectedTime', @_);
        }

        # Update IVs
        $self->ivPoke('disconnectedTime', int($axmud::CLIENT->getTime()));
        $self->ivPoke('currentTime', $self->disconnectedTime);
        $self->ivPoke('connectionLength', int($self->currentTime) - int($self->connectingTime));

        return 1;
    }

    ##################
    # Accessors - get

    sub connectingTime
        { $_[0]->{connectingTime} }
    sub connectedTime
        { $_[0]->{connectedTime} }
    sub disconnectedTime
        { $_[0]->{disconnectedTime} }
    sub currentTime
        { $_[0]->{currentTime} }
    sub connectionLength
        { $_[0]->{connectionLength} }
    sub char
        { $_[0]->{char} }
}

# Package must return true
1
