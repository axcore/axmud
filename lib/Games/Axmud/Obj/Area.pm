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
# Games::Axmud::Obj::Area
# Handles an area, comprising the space used by a single window, within a zone object's internal
#   grid

{ package Games::Axmud::Obj::Area;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Zone->addArea
        # Create a new instance of the area object, which stores details about an area of a zone
        #   object's (GA::Obj::Zone) internal grid. The area comprises the space used by a single
        #   window
        #
        # Expected arguments
        #   $number         - The area's unique number within the zone
        #   $zoneObj        - The GA::Obj::Zone to which this area belongs
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $zoneObj, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $zoneObj || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'area',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # The area's number on the zone object's internal grid (matches a key in
            #   GA::Obj::Zone->areaHash) - set later on
            number                      => $number,
            # The GA::Obj::Zone to which this area belongs
            zoneObj                     => $zoneObj,

            # The coordinates of the area within the zone's internal grid, in gridblocks
            layer                       => undef,
            # (Coordinates of the top-left corner)
            leftBlocks                  => undef,
            topBlocks                   => undef,
            # (Coordinates of the bottom-right corner)
            rightBlocks                 => undef,
            bottomBlocks                => undef,
            # (The size of the area)
            widthBlocks                 => undef,
            heightBlocks                => undef,

            # The window object (something inheriting from GA::Generic::Win) that fills this area of
            #   the zone object's internal grid
            winObj                      => undef,
            # The current size and position of the window on the workspace (in pixels)
            xPosPixels                  => undef,
            yPosPixels                  => undef,
            widthPixels                 => undef,
            heightPixels                => undef,
        };

        # Bless the zone layout into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    sub set_posn {

        my ($self, $xPosPixels, $yPosPixels, $widthPixels, $heightPixels, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $xPosPixels || ! defined $yPosPixels || ! defined $widthPixels
            || ! defined $heightPixels || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_zone', @_);
        }

        $self->ivPoke('xPosPixels', $xPosPixels);
        $self->ivPoke('yPosPixels', $yPosPixels);
        $self->ivPoke('widthPixels', $widthPixels);
        $self->ivPoke('heightPixels', $heightPixels);

        return 1;
    }

    sub set_win {

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_win', @_);
        }

        $self->ivPoke('winObj', $winObj);

        return 1;
    }

    sub set_zone {

        my ($self, $layer, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $layer || ! defined $xPosBlocks || ! defined $yPosBlocks
            || ! defined $widthBlocks || ! defined $heightBlocks || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_zone', @_);
        }

        $self->ivPoke('layer', $layer);

        $self->ivPoke('leftBlocks', $xPosBlocks);
        $self->ivPoke('topBlocks', $yPosBlocks);
        $self->ivPoke('rightBlocks', $xPosBlocks + $widthBlocks - 1);
        $self->ivPoke('bottomBlocks', $yPosBlocks + $heightBlocks - 1);
        $self->ivPoke('widthBlocks', $widthBlocks);
        $self->ivPoke('heightBlocks', $heightBlocks);

        return 1;
    }

    ##################
    # Accessors - get

    sub number
        { $_[0]->{number} }
    sub zoneObj
        { $_[0]->{zoneObj} }

    sub layer
        { $_[0]->{layer} }
    sub leftBlocks
        { $_[0]->{leftBlocks} }
    sub topBlocks
        { $_[0]->{topBlocks} }
    sub rightBlocks
        { $_[0]->{rightBlocks} }
    sub bottomBlocks
        { $_[0]->{bottomBlocks} }
    sub widthBlocks
        { $_[0]->{widthBlocks} }
    sub heightBlocks
        { $_[0]->{heightBlocks} }

    sub winObj
        { $_[0]->{winObj} }
    sub xPosPixels
        { $_[0]->{xPosPixels} }
    sub yPosPixels
        { $_[0]->{yPosPixels} }
    sub widthPixels
        { $_[0]->{widthPixels} }
    sub heightPixels
        { $_[0]->{heightPixels} }
}

# Package must return a true value
1
