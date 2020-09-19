# Copyright (C) 2011-2020 A S Lewis
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
# Games::Axmud::Obj::GaugeLevel
# Handles a horizontal level in a 'main' window gauge

{ package Games::Axmud::Obj::GaugeLevel;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::GaugeBox->addGaugeLevel
        # Prepare a new instance of the Axmud gauge level object which handles a single level
        #   (horizontal region) of gauges text or graphical gauges, belonging to a single session,
        #   in the 'main' window
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $number         - Unique number for this gauge level (unique across all sessions)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file
            _parentWorld                => undef,       # No parent world
            _privFlag                   => FALSE,       # All IVs are public

            # Object IVs
            # ----------

            # Unique number for this gauge level
            number                      => $number,
            # The number of the GA::Session that's responsible for keeping the gauge up-to-date
            session                     => $session,

            # Hash of GA::Obj::Gauge objects drawn on this gauge level. Hash in the form
            #   $gaugeHash{unique_number} = gauge_object
            # ...where 'unique_number' is the gauge object's number, unique across all sessions
            gaugeHash                   => {},
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

    sub number
        { $_[0]->{number} }
    sub session
        { $_[0]->{session} }

    sub gaugeHash
        { my $self = shift; return %{$self->{gaugeHash}}; }
}

# Package must return a true value
1
