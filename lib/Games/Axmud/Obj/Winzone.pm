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
# Games::Axmud::Obj::Winzone
# A winzone object marks out an area on the Gtk3::Grid used by an 'internal' window as being in use
#   by a single widget, and stores the widget type used

{ package Games::Axmud::Obj::Winzone;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Winmap->setupStandardWinmap and GA::Cmd::AddWinzone->do
        # Create a new instance of the winzone object, each of which marks out an area of the
        #   Gtk3::Grid used by an 'internal' window as being in use by a table object (inheriting
        #   from GA::Generic::Table), and specifies the type of table object used
        #
        # Expected arguments
        #   $winmapObj      - The parent GA::Obj::Winmap object
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $winmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $winmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $winmapObj->name . '_winzone',
            _objClass                   => $class,
            _parentFile                 => 'winmaps',
            _parentWorld                => undef,
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # The parent GA::Obj::Winmap object
            winmapObj                   => $winmapObj,

            # Other IVs
            # ---------

            # The winzone's number within the parent winmap (matches
            #   GA::Obj::Winmap->zoneCount) - set by GA::Obj::Winmap->addWinzone when the winzone is
            #   added to the winmap
            number                      => undef,
            # The package name for the table object handling the Gtk3::Widget in this winzone
            #   (inherits from GA::Generic::Table)
            packageName                 => undef,
            # An optional name to give to the table object, when it is created. If not specified,
            #   the table object's own ->name is the same as its ->number. However, the code that
            #   calls GA::Strip::Table->addTableObj can specify a name and, if so, that name is used
            # If specified, ->objName can be any string (avoid using short strings or numbers. No
            #   part of the code checks that table object names are unique; if two or more table
            #   objects share the same name, usually the one with the lowest ->number 'wins')
            # Max 16 characters
            objName                     => undef,
            # Hash of initialisation settings for the table object. The table object should use
            #   default initialisation settings unless it can succesfully interpret one or more of
            #   the key-value pairs in the hash, if there are any
            initHash                    => {},

            # The coordinates of the winzone within the winmap's Gtk3::Grid
            # Coordinates of the top-left corner (e.g. 0,0)
            left                        => undef,
            top                         => undef,
            # Coordinates of the bottom-right corner (e.g. 59, 59)
            right                       => undef,
            bottom                      => undef,
            # The size of the winzone (e.g. 60, 60)
            width                       => undef,
            height                      => undef,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Create a clone of an existing winzone
        #
        # Expected arguments
        #   $winmapObj      - The new winzone's parent GA::Obj::Winmap object
        #   $number         - The number of the new winzone in the parent winmap
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($self, $winmapObj, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $winmapObj || ! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Setup
        my $clone = {
            _objName                    => $winmapObj->name . '_winzone',
            _objClass                   => $self->_objClass,
            _parentFile                 => 'winmaps',
            _parentWorld                => undef,
            _privFlag                   => TRUE,                # All IVs are private

            winmapObj                   => $winmapObj,

            number                      => $number,
            packageName                 => $self->packageName,
            objName                     => $self->objName,
            initHash                    => {$self->initHash},

            left                        => $self->left,
            top                         => $self->top,
            right                       => $self->right,
            bottom                      => $self->bottom,
            width                       => $self->width,
            height                      => $self->height,
        };

        # Bless the new winzone into existence
        bless $clone, $self->_objClass;

        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    sub set_number {

        # Called by GA::Obj::Winmap->addWinzone once this winzone has been added to a winmap

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_number', @_);
        }

        $self->ivPoke('number', $number);

        return 1;
    }

    sub set_vars {

        # Called by GA::Cmd::AddWinzone->do and ModifyWinzone->do
        # Sets multiple instance variables for this winzone object
        #
        # Expected arguments
        #   $standardCmd    - The client command that called this function: 'addwinzone' or
        #                       'modifywinzone'
        #
        # Optional arguments
        #   A list in the form: (
        #       $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $packageName, $objName,
        #       $positionFlag, $sizeFlag, $packageNameFlag, $objNameFlag,
        #       $initHashRef, $removeHashRef,
        #   )
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $standardCmd,
            $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $packageName, $objName,
            $positionFlag, $sizeFlag, $packageNameFlag, $objNameFlag,
            $initHashRef, $removeHashRef,
        ) = @_;

        # Check for improper arguments
        if (! defined $standardCmd) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_number', @_);
        }

        # Set IVs
        if ($packageNameFlag) {

            $self->ivPoke('packageName', $packageName);     # Never 'undef'
            $self->ivEmpty('initHash');
        }

        if ($sizeFlag) {

            $self->ivPoke('width', $widthBlocks);
            $self->ivPoke('height', $heightBlocks);
        }

        if ($positionFlag) {

            $self->ivPoke('left', $xPosBlocks);
            $self->ivPoke('top', $yPosBlocks);
            $self->ivPoke('right', $xPosBlocks + $self->width - 1);
            $self->ivPoke('bottom', $yPosBlocks + $self->height - 1);
        }

        if ($objNameFlag) {

            $self->ivPoke('objName', $objName);             # May be 'undef'
        }

        foreach my $key (keys %$initHashRef) {

            $self->ivAdd('initHash', $key, $$initHashRef{$key});
        }

        foreach my $key (keys %$removeHashRef) {

            $self->ivDelete('initHash', $key);
        }

        return 1;
    }

    ##################
    # Accessors - get

    sub winmapObj
        { $_[0]->{winmapObj} }

    sub number
        { $_[0]->{number} }
    sub packageName
        { $_[0]->{packageName} }
    sub objName
        { $_[0]->{objName} }
    sub initHash
        { my $self = shift; return %{$self->{initHash}}; }

    sub left
        { $_[0]->{left} }
    sub top
        { $_[0]->{top} }
    sub right
        { $_[0]->{right} }
    sub bottom
        { $_[0]->{bottom} }
    sub width
        { $_[0]->{width} }
    sub height
        { $_[0]->{height} }
}

# Package must return a true value
1
