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
# Games::Axmud::Obj::ColourScheme
# Colour scheme objects, used by pane objects (GA::Table::Pane) to set colours and fonts in the pane
#   object's textview(s)

{ package Games::Axmud::Obj::ColourScheme;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->createStandardColourSchemes or GA::Cmd::AddColourScheme->do
        # Creates the GA::Obj::ColourScheme, used by pane objects (GA::Table::Pane) to set colours
        #   and fonts in the pane object's textview(s)
        #
        # Expected arguments
        #   $name       - Unique name for this colour scheme (max 16 chars)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid and not already in use by another colour scheme
        # NB There is a colour scheme for every type of 'grid' or 'free' window (except 'dialogue'
        #   windows), with the same name as the window object's ->winType, and those names would
        #   normally be refused as invalid by GA::Client->nameCheck
        if (
            ! $axmud::CLIENT->ivExists('constGridWinTypeHash', $name)
            && ! $axmud::CLIENT->ivExists('constFreeWinTypeHash', $name)
            && ! $axmud::CLIENT->nameCheck($name, 16)
        ) {
            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                   $class . '->new',
            );

        } elsif ($axmud::CLIENT->ivExists('colourSchemeHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: colour scheme \'' . $name . '\' already exists',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => 'colour_scheme_' . $name,
            _objClass                   => $class,
            _parentFile                 => 'winmaps',
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => FALSE,       # All IVs are public

            # IVs
            # ---

            # Unique name for this colour scheme (max 16 chars)
            name                        => $name,

            # The colour scheme. Each value is an Axmud colour tag
            textColour                  => $axmud::CLIENT->constTextColour,
            underlayColour              => $axmud::CLIENT->constUnderlayColour,
            backgroundColour            => $axmud::CLIENT->constBackgroundColour,
            # The font and fontsize
            font                        => $axmud::CLIENT->constFont,
            fontSize                    => $axmud::CLIENT->constFontSize,
        };

        # Bless the object into existence
        bless $self, $class;

        # If this is a standard colour scheme (with the same name as a type of 'grid' or 'free'
        #   window), set the default colours/fonts
        if (
            $axmud::CLIENT->ivExists('constWinmapNameHash', $name)
            || $axmud::CLIENT->ivExists('constFreeWinTypeHash', $name)
        ) {
            if (! $self->setupStandardColourScheme()) {

                return $axmud::CLIENT->writeError(
                    'Can\'t set up the standard colour scheme \'' . $name . '\'',
                    $class . '->new',
                );
            }
        }

        return $self;
    }

    ##################
    # Methods

    sub setupStandardColourScheme {

        # Called by $self->new whenever the specified name of the colour scheme is the name of a
        #   type of 'grid' or 'free' window
        # (Could be called by any other function in order to reset a standard colour scheme)
        # Sets default colours/fonts for this colour scheme
        #
        # Return values
        #   'undef' on improper arguments or if $name isn't one of the standard colour scheme names
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->setupStandardColourScheme',
                @_,
            );
        }

        # Default colour schemes for 'grid' windows
        if ($axmud::CLIENT->ivExists('constGridWinTypeHash', $self->name)) {

            $self->ivPoke('textColour', $axmud::CLIENT->constTextColour);
            $self->ivPoke('backgroundColour', $axmud::CLIENT->constBackgroundColour);
            $self->ivPoke('font', $axmud::CLIENT->constFont);
            $self->ivPoke('fontSize', $axmud::CLIENT->constFontSize);

            return 1;

        # Default colour schemes for 'free' windows
        } elsif ($axmud::CLIENT->ivExists('constFreeWinTypeHash', $self->name)) {

            $self->ivPoke('textColour', '#000000');
            $self->ivPoke('backgroundColour', '#FFFFFF');
            $self->ivPoke('font', $axmud::CLIENT->constFont);

            if ($self->name eq 'gui') {

                # (Fit a little more help text into the GUI window)
                $self->ivPoke('fontSize', ($axmud::CLIENT->constFontSize - 1));

            } else {

                $self->ivPoke('fontSize', $axmud::CLIENT->constFontSize);
            }

            return 1;

        } else {

            # Not a standard colour scheme
            return undef;
        }
    }

    ##################
    # Accessors - set

    sub repair {

        # Can be called by anything that's about to apply a colour scheme to a window (for example,
        #   called by Games::Axmud::Cmd::UpdateColourScheme->do
        # Checks that the scheme's IVs are valid and attempts to repair any problems; incorrect
        #   colour tags could cause multiple Gtk errors or even a crash
        #
        # Checks that the underlay colour uses an underlay colour tag and not a normal text colour
        #   tag. If so, converts one to the other
        # Checks that the colour tags are recognised and replaced them with default ones, if not
        # Checks that the font size is an actual integer
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($mode, $underlayFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->repair', @_);
        }

        if (! defined $self->textColour) {

            $self->ivPoke('textColour', $axmud::CLIENT->constTextColour);

        } else {

            ($mode, $underlayFlag) = $axmud::CLIENT->checkColourTags($self->textColour);
            if (! $mode) {

                # Invalid colour tag
                $self->ivPoke('textColour', $axmud::CLIENT->constTextColour);

            } elsif ($underlayFlag) {

                # Underlay colour tag; convert it
                $self->ivPoke('textColour', $axmud::CLIENT->swapColours($self->textColour));
            }
        }

        if (! defined $self->underlayColour) {

            $self->ivPoke('underlayColour', $axmud::CLIENT->constUnderlayColour);

        } else {

            ($mode, $underlayFlag) = $axmud::CLIENT->checkColourTags($self->underlayColour);
            if (! $mode) {

                # Invalid colour tag
                $self->ivPoke('underlayColour', $axmud::CLIENT->constUnderlayColour);

            } elsif (! $underlayFlag) {

                # Text colour tag; convert it
                $self->ivPoke('underlayColour', $axmud::CLIENT->swapColours($self->underlayColour));
            }
        }

        if (! defined $self->backgroundColour) {

            $self->ivPoke('backgroundColour', $axmud::CLIENT->constBackgroundColour);

        } else {

            ($mode, $underlayFlag) = $axmud::CLIENT->checkColourTags($self->backgroundColour);
            if (! $mode) {

                # Invalid colour tag
                $self->ivPoke('backgroundColour', $axmud::CLIENT->constBackgroundColour);

            } elsif ($underlayFlag) {

                # Underlay colour tag; convert it
                $self->ivPoke(
                    'backgroundColour',
                    $axmud::CLIENT->swapColours($self->backgroundColour),
                );
            }
        }

        if (! defined $self->font) {

            $self->ivPoke('font', $axmud::CLIENT->constFont);

        }

        if (! defined $self->fontSize || ! $axmud::CLIENT->floatCheck($self->fontSize, 0)) {

            $self->ivPoke('fontSize', $axmud::CLIENT->constFontSize);
        }

        # Operation complete
        return 1;
    }

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }

    sub textColour
        { $_[0]->{textColour} }
    sub underlayColour
        { $_[0]->{underlayColour} }
    sub backgroundColour
        { $_[0]->{backgroundColour} }
    sub font
        { $_[0]->{font} }
    sub fontSize
        { $_[0]->{fontSize} }
}

# Package must return true
1
