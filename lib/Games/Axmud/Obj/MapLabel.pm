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
# Games::Axmud::Obj::MapLabel
# The object that handles a label on the Automapper window's map

{ package Games::Axmud::Obj::MapLabel;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the map label object
        #
        # Expected arguments
        #   $session    - The GA::Session which created this object (not stored as an IV)
        #   $name       - The initial contents of the label, e.g. 'Town Hall' (no maximum size, and
        #                   empty strings are acceptable)
        #   $region     - The name of the regionmap to which this label belongs
        #   $xPosPixels, $yPosPixels
        #               - The map coordinates of the pixel in which the top-left corner of the label
        #                   is situated
        #   $level      - The map level on which the label is drawn (matches
        #                   GA::Obj::Regionmap->currentLevel)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $region, $xPosPixels, $yPosPixels, $level, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $region
            || ! defined $xPosPixels || ! defined $yPosPixels || ! defined $level || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'worldmodel',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,       # All IVs are public

            # Object IVs
            # ----------

            # The contents of the label, e.g. 'Town Hall' (no maximum size, and empty strings
            #   are acceptable)
            name                        => $name,
            # The label's number in the regionmap (set later)
            number                      => undef,
            # The name of the regionmap to which this label belongs
            region                      => $region,
            # The pixel at which the top-left corner of the label is drawn
            xPosPixels                  => $xPosPixels,
            yPosPixels                  => $yPosPixels,
            # The map level on which the label is drawn
            level                       => $level,
            # Relative text size for this label. Default is 1. GA::Win::Map allows it to be
            #   switched to 2 (label is twice as large) or 4 (label is four times as large).
            relSize                     => 1,
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
    sub number
        { $_[0]->{number} }
    sub region
        { $_[0]->{region} }
    sub xPosPixels
        { $_[0]->{xPosPixels} }
    sub yPosPixels
        { $_[0]->{yPosPixels} }
    sub level
        { $_[0]->{level} }
    sub relSize
        { $_[0]->{relSize} }
}

# Package must return true
1
