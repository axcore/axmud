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
# Games::Axmud::Obj::MapLabel
# The object that handles a label on the Automapper window's map
#
# Games::Axmud::Obj::MapLabelSet
# The object that stores a set of text attributes, such as colour, size and style, which apply to
#   multiple labels

{ package Games::Axmud::Obj::MapLabel;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the map label object, which handles a label on the Automapper
        #   window's map
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
        # Optional arguments
        #   $style      - The name of the map label style to use (a GA::Obj::MapLabelStyle). If
        #                   defined, that style is applied to the label's text. If not defined,
        #                   the style depends on IVs in this object
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $session, $name, $region, $xPosPixels, $yPosPixels, $level, $style, $check,
        ) = @_;

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

            # The contents of the label, e.g. 'Town Hall'. No maximum size, and newline characters
            #   are acceptable for multi-line labels; but the name must contain at least one non-
            #   space character
            name                        => $name,
            # The label's number in the regionmap (set later by GA::Obj::Regionmap->storeLabel)
            number                      => undef,
            # The name of the regionmap to which this label belongs
            region                      => $region,
            # An ID for the label, so the automapper window can tell apart labels from different
            #   regions. The ID combines ->region and ->number, e.g. 'town_42' (set later by
            #   GA::Obj::Regionmap->storeLabel)
            id                          => undef,

            # The pixel at which the top-left corner of the label is drawn
            xPosPixels                  => $xPosPixels,
            yPosPixels                  => $yPosPixels,
            # The map level on which the label is drawn
            level                       => $level,

            # The name of the map label style to use (a GA::Obj::MapLabelStyle)
            style                       => $style,

            # If $self->style is 'undef', a custom style is applied using the following IVs (if
            #   $self->style is set, the following IVs are ignored)

            # Text colour (an RGB tag like '#ABCDEF', case-insensitive)
            textColour                  =>
                $session->worldModelObj->defaultSchemeObj->mapLabelColour,
            # Underlay colour (an RGB tag, only used if defined)
            underlayColour              => undef,
            # Text's relative size (a number in the range 0.5-10, with the default size being 1)
            relSize                     => 1,
            # Style attributes (all values TRUE or FALSE)
            italicsFlag                 => FALSE,
            boldFlag                    => FALSE,
            underlineFlag               => FALSE,
            strikeFlag                  => FALSE,
            # If TRUE, a box is drawn around the text
            boxFlag                     => FALSE,
            # The angle of rotation (in degrees). 0 represents normal text; acceptable values are
            #   0-359
            rotateAngle                 => 0,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    sub set_style {

        # Setting a style resets the style IVs that are no longer used

        my ($self, $session, $style, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $style || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_style', @_);
        }

        # Update IVs
        $self->ivPoke('style', $style);

        $self->ivPoke('textColour', $session->worldModelObj->defaultSchemeObj->mapLabelColour);
        $self->ivUndef('underlayColour');
        $self->ivPoke('relSize', 1);
        $self->ivPoke('italicsFlag', FALSE);
        $self->ivPoke('boldFlag', FALSE);
        $self->ivPoke('italicsFlag', FALSE);
        $self->ivPoke('underlineFlag', FALSE);
        $self->ivPoke('strikeFlag', FALSE);
        $self->ivPoke('boxFlag', FALSE);
        $self->ivPoke('rotateAngle', 0);

        return 1;
    }

    sub reset_style {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_style', @_);
        }

        # Update IVs
        $self->ivUndef('style');

        return 1;
    }

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub number
        { $_[0]->{number} }
    sub region
        { $_[0]->{region} }
    sub id
        { $_[0]->{id} }

    sub xPosPixels
        { $_[0]->{xPosPixels} }
    sub yPosPixels
        { $_[0]->{yPosPixels} }
    sub level
        { $_[0]->{level} }

    sub style
        { $_[0]->{style} }

    sub textColour
        { $_[0]->{textColour} }
    sub underlayColour
        { $_[0]->{underlayColour} }
    sub relSize
        { $_[0]->{relSize} }
    sub italicsFlag
        { $_[0]->{italicsFlag} }
    sub boldFlag
        { $_[0]->{boldFlag} }
    sub underlineFlag
        { $_[0]->{underlineFlag} }
    sub strikeFlag
        { $_[0]->{strikeFlag} }
    sub boxFlag
        { $_[0]->{boxFlag} }
    sub rotateAngle
        { $_[0]->{rotateAngle} }
}

{ package Games::Axmud::Obj::MapLabelStyle;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the map label style object, which stores a set of text
        #   attributes, such as colour, size and style, that apply to muliple labels
        #
        # Expected arguments
        #   $session    - The GA::Session which created this object (not stored as an IV)
        #   $name       - A unique string name for this profile (min 1 char, max 16 chars,
        #                   containing any text)
        #
        # Optional arguments
        #   $textColour - The text colour to use (an RGB tag like '#ABCDEF', case-insensitive). If
        #                   'undef' or an invalid value, the default text colour is applied
        #   $underlayColour
        #               - The underlay colour to use (an RGB tag like '#ABCDEF', case-insensitive).
        #                   If 'undef' or an invalid value, no underlay colour is applied
        #   $relSize    - The text's relative size (a number in the range 0.5-10, with the default
        #                   size being 1). If 'undef' or an invalid value, the default size is
        #                   applied
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $textColour, $underlayColour, $relSize, $check) = @_;

        # Local variables
        my ($type, $underlayFlag);

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid and not already in use by another set
        if ($name eq '' || length ($name) > 16) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );
        }

        # Apply default values
        if (defined $textColour) {

            ($type, $underlayFlag) = $axmud::CLIENT->checkColourTags($textColour, 'rgb');
        }

        if (! defined $textColour || ! $type || $underlayFlag) {

            if (! $session->worldModelObj) {

                # World model not created yet; use emergency default
                $textColour = '#000000';

            } else {

                $textColour = $session->worldModelObj->defaultSchemeObj->mapLabelColour;
            }

        } else {

            $textColour = uc($textColour);
        }

        if (defined $underlayColour) {

            ($type, $underlayFlag) = $axmud::CLIENT->checkColourTags($underlayColour, 'rgb');

            if (! $type || $underlayFlag) {

                $underlayColour = undef;
            }
        }

        if (! defined $relSize || ! $axmud::CLIENT->floatCheck($relSize, 0.5, 10)) {

            $relSize = 1;
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

            # A unique string name for this profile (max 16 chars, containing A-Za-z0-9_ - 1st char
            #   can't be number, non-Latin alphabets acceptable. Must not exist as a key in the
            #   global hash of reserved names, $axmud::CLIENT->constReservedHash)
            name                        => $name,

            # Text colour (an RGB tag like '#ABCDEF', case-insensitive)
            textColour                  => $textColour,
            # Underlay colour (an RGB tag, only used if defined)
            underlayColour              => $underlayColour,
            # Text's relative size (a number in the range 0.5-10, with the default size being 1)
            relSize                     => $relSize,
            # Style attributes (all values TRUE or FALSE)
            italicsFlag                 => FALSE,
            boldFlag                    => FALSE,
            underlineFlag               => FALSE,
            strikeFlag                  => FALSE,
            # If TRUE, a box is drawn around the text
            boxFlag                     => FALSE,
            # The angle of rotation (in degrees). 0 represents normal text; acceptable values are
            #   0-359
            rotateAngle                 => 0,
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

    sub textColour
        { $_[0]->{textColour} }
    sub underlayColour
        { $_[0]->{underlayColour} }
    sub relSize
        { $_[0]->{relSize} }
    sub italicsFlag
        { $_[0]->{italicsFlag} }
    sub boldFlag
        { $_[0]->{boldFlag} }
    sub underlineFlag
        { $_[0]->{underlineFlag} }
    sub strikeFlag
        { $_[0]->{strikeFlag} }
    sub boxFlag
        { $_[0]->{boxFlag} }
    sub rotateAngle
        { $_[0]->{rotateAngle} }
}

# Package must return a true value
1
