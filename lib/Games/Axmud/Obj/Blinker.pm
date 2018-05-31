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
# Games::Axmud::Obj::Blinker
# Blinker objects handle a blinker (a little blob of colour which is lit up, briefly, when data is
#   sent to and forth from the world)

{ package Games::Axmud::Obj::Blinker;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::ConnectInfo->createStandardBlinkers
        # Creates a new blinker object handling a blinker (a little blob of colour which is lit up,
        #   briefly, when data is sent to and forth from the world)
        #
        # Expected arguments
        #   $number         - A unique number for the blinker within the parent strip object
        #                       (GA::Strip::ConnectInfo)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $check) = @_;

        # Local variables
        my ($onColour, $offColour);

        # Check for improper arguments
        if (! defined $class || ! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Set standard blinker colours
        if ($number == 0) {
            $onColour = '#800080',      # HTML purple
        } elsif ($number == 1) {
            $onColour = '#FFFFFF',      # HTML white
        } elsif ($number == 2) {
            $onColour = '#FF0000',      # HTML red
        } else {
            $onColour = '#FFFF00',      # Fallback: HTML yellow
        }

        $offColour = '#A9A9A9',         # HTML darkgray

        # Setup
        my $self = {
            _objName                    => 'blinker_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # A unique number for the blinker within the parent strip object
            #   (GA::Strip::ConnectInfo)
            number                      => $number,

            # The Gnome2::Canvas item (Gnome2::Canvas::Item) that actually draws the blinker
            canvasItem                  => undef,

            # Flag set to TRUE if the blinker is currently ON, FALSE if it is currently OFF
            onFlag                      => FALSE,
            # The blinker's colours when 'off' and 'on'
            onColour                    => $onColour,
            offColour                   => $offColour,
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

    sub canvasItem
        { $_[0]->{canvasItem} }

    sub onFlag
        { $_[0]->{onFlag} }
    sub onColour
        { $_[0]->{onColour} }
    sub offColour
        { $_[0]->{offColour} }
}

# Package must return true
1
