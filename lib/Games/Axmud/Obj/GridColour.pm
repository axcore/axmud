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
# Games::Axmud::Obj::GridColour
# Object for storing details about a rectangular area of the automapper window's background map,
#   and the colour it uses (useful for representing map features that aren't actually accessible to
#   the player, such as rivers and mountain ranges)

{ package Games::Axmud::Obj::GridColour;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Regionmap->storeRect
        # Creates a new instance of the grid colour object destination object (which stores details
        #   about a rectangular area of the automapper window's background map and the colour it
        #   uses; useful for representing map features that aren't actually accessible to the
        #   player, such as rivers and mountain ranges)
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $number     - Unique number for this workspace object
        #   $colour     - The colour to use; an RGB colour tag like '#ABCDEF' (case-insensitive)
        #   $x1, $y1    - Coordinates on the parent regionmap's grid, representing the top-left
        #                   corner of the rectangle
        #   $x2, $y2    - Coordinates on the parent regionmap's grid, representing the bottom-right
        #                   corner of the rectangle
        #
        # Optional arguments
        #   $level      - The level (i.e., the z-coordinate), corresponding to the parent
        #                   regionmap's ->currentLevel. If 'undef', the rectangle is drawn on every
        #                   level
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $number, $colour, $x1, $y1, $x2, $y2, $level, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $number || ! defined $colour
            || ! defined $x1 || ! defined $y1 || ! defined $x2 || ! defined $y2 || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $number,
            _objClass                   => $class,
            _parentFile                 => 'worldmodel',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # Unique number for this workspace object
            number                      => $number,
            # The colour to use; an RGB colour tag like '#ABCDEF' (case-insensitive)
            colour                      => $colour,
            # Coordinates on the parent regionmap's grid, representing the top-left corner of the
            #   rectangle
            x1                          => $x1,
            y1                          => $y1,
            # Coordinates on the parent regionmap's grid, representing the bottom-right corner of
            #   the rectangle
            x2                          => $x2,
            y2                          => $y2,
            # The level (i.e., the z-coordinate), corresponding to the parent regionmap's
            #   ->currentLevel. If 'undef', the rectangle is drawn on every level
            level                       => $level,
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
    sub colour
        { $_[0]->{colour} }
    sub x1
        { $_[0]->{x1} }
    sub y1
        { $_[0]->{y1} }
    sub x2
        { $_[0]->{x2} }
    sub y2
        { $_[0]->{y2} }
    sub level
        { $_[0]->{level} }
}

# Package must return a true value
1
