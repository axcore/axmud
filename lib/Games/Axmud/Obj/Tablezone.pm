# Copyright (C) 2011-2019 A S Lewis
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
# Games::Axmud::Obj::Tablezone
# A tablezone object marks out an area on the Gtk3::Grid used by an 'internal' window as being in
#   use by a single widget, and stores the widget type used

{ package Games::Axmud::Obj::Tablezone;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Create a new instance of the tablezone object, each of which marks out an area of the
        #   Gtk3::Grid used by an 'internal' window as being in use by a table object (inheriting
        #   from GA::Generic::Table), and specifies the type of table object used
        #
        # Expected arguments
        #   $number
        #       - The tablezone's number within the parent strip object (matches
        #           GA::Strip::Table->zoneCount)
        #   $packageName
        #       - The package name of the table object which fills the space marked out by this
        #           tablezone, e.g. GA::Table::Pane
        #   $left, $top
        #       - The coordinates of the top-left corner of the tablezone on the table
        #   $right, $bottom
        #       - The coordinates of the top-right corner of the tablezone on the table
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $packageName, $left, $top, $right, $bottom, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $packageName || ! defined $left
            || ! defined $top || ! defined $right || ! defined $bottom || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                   => 'tablezone_' . $number,
            _objClass                  => $class,
            _parentFile                => undef,       # No parent file object
            _parentWorld               => undef,       # No parent file object
            _privFlag                  => TRUE,        # All IVs are private

            # IVs
            # ---

            # The tablezone's number within the parent strip object (matches
            #   GA::Strip::Table->zoneCount)
            number                      => $number,
            # The package name of the table object which fills the space marked out by this
            #   tablezone, e.g. GA::Table::Pane
            packageName                 => $packageName,

            # The coordinates of the tablezone within the strip object's Gtk3::Grid
            # Coordinates of the top-left corner (e.g. 0x0)
            left                        => $left,
            top                         => $top,
            # Coordinates of the bottom-right corner (e.g. 59x59)
            right                       => $right,
            bottom                      => $bottom,
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
    sub packageName
        { $_[0]->{packageName} }

    sub left
        { $_[0]->{left} }
    sub top
        { $_[0]->{top} }
    sub right
        { $_[0]->{right} }
    sub bottom
        { $_[0]->{bottom} }
}

# Package must return a true value
1
