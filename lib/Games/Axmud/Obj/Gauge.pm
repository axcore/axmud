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
# Games::Axmud::Obj::Gauge
# Handles a 'main' window gauge

{ package Games::Axmud::Obj::Gauge;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::GaugeBox->addGauge or ->addTextGauge
        # Prepare a new instance of the Axmud gauge object which handles a single text of graphical
        #   gauge in the 'main' window
        #
        # Expected arguments
        #   $session        - The calling GA::Session, which is responsible for keeping the gauge
        #                       up-to-date
        #   $number         - Unique number for this gauge
        #   $level          - The unique number of the GA::Obj::GaugeLevel object, representing the
        #                       gauge level on which this gauge is drawn (matches a key in
        #                       GA::Strip::GaugeBox->gaugeLevelHash)
        #   $textFlag       - TRUE if this is a text gauge, FALSE if this is a graphical gauge
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $number, $level, $textFlag, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $number || ! defined $level ||
            ! defined $textFlag || defined $check
        ) {
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

            # Unique number for this gauge
            number                      => $number,
            # The unique number of the gauge level on which this gauge is drawn (matches a key in
            #   GA::Strip::GaugeBox->gaugeLevelHash)
            level                       => $level,
            # The number of the GA::Session that's responsible for keeping the gauge up-to-date
            session                     => $session,

            # IVs used with both text and graphical gauges

            # Flag set to TRUE for text gauges, FALSE for graphical gauges
            textFlag                    => $textFlag,
            # The value and maximum value displayed by the gauge (both number >=0,
            #   $value <= $maxValue)
            value                       => 1,
            maxValue                    => 1,
            # If TRUE, the total size of the gauge is ($value + $maxValue). If FALSE (or 'undef'),
            #   the total size is $maxValue
            addFlag                     => FALSE,
            # The label to use. If 'undef' or an empty string, no label is used
            label                       => undef,
            # For MXP gauges, the entity used to set ->value (compulsory), and the entity used to
            #   set ->maxValue (optional)
            mxpEntity                   => undef,
            mxpMaxEntity                => undef,

            # IVs used with graphical gauges only

            # The colour to use in the 'full' part of the gauge (an RGB colour tag, default white)
            fullColour                  => '#FFFFFF',
            # The colour to use in the 'empty' part of the gauge (an RGB colour tag, default black)
            emptyColour                 => '#000000',
            # The label colour (an RGB colour tag, default red)
            labelColour                 => '#FF0000',
            # If flag is TRUE, the label text (if displayed) is supplemented with the values; e.g.
            #   'HP: 37/100'. If FALSE (or 'undef'), only the text in $label is visible
            labelFlag                   => FALSE,

            # Hash of data for use by whatever part of the code is controlling the gauge (for
            #   example, the Status task uses it to remember which of its IVs contains the
            #   numerical values to display in the gauge)
            privateHash                 => {},
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
    sub level
        { $_[0]->{level} }
    sub session
        { $_[0]->{session} }

    sub textFlag
        { $_[0]->{textFlag} }
    sub value
        { $_[0]->{value} }
    sub maxValue
        { $_[0]->{maxValue} }
    sub addFlag
        { $_[0]->{addFlag} }
    sub label
        { $_[0]->{label} }
    sub mxpEntity
        { $_[0]->{mxpEntity} }
    sub mxpMaxEntity
        { $_[0]->{mxpMaxEntity} }

    sub fullColour
        { $_[0]->{fullColour} }
    sub emptyColour
        { $_[0]->{emptyColour} }
    sub labelColour
        { $_[0]->{labelColour} }
    sub labelFlag
        { $_[0]->{labelFlag} }

    sub privateHash
        { my $self = shift; return %{$self->{privateHash}}; }
}

# Package must return a true value
1
