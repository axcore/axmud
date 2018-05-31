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
# Games::Axmud::Obj::DrawingArea
# The code that handles a Gtk2::Gdk::DrawingArea

{ package Games::Axmud::Obj::DrawingArea;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::ConfigWin->addDrawingArea
        # Creates a new instance of the drawing area object which handles a Gtk2::Gdk::DrawingArea
        #   (usually used in an 'edit' or 'pref' window)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $check) = @_;

        # Check for improper arguments
        if (! defined $class || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'drawing_area',
            _objClass                   => $class,
            _parentFile                 => undef,           # No parent file object
            _parentWorld                => undef,           # No parent file object
            _privFlag                   => FALSE,           # All IVs are public

            # Drawing area IVs
            # ----------------

            # Width/height of the drawing area in pixels
            width                       => undef,
            height                      => undef,

            # Gtk2 widgets
            scrolledWin                 => undef,
            hAdjustment                 => undef,
            viewPort                    => undef,
            drawingArea                 => undef,
            eventBox                    => undef,

            # The pixmap on which stuff is drawn
            pixmap                      => undef,
            graphicsContext             => undef,
            colourMap                   => undef,

            # Used to record colour contexts
            allocatedColourHash         => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub getColour {

        # Returns a colour used by drawing areas, looking up the colour if need be, or using a
        #   previously looked-up colour
        #
        # Expected arguments
        #   $colourName     - A colour like 'red' or 'black'
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the drawing area colour

        my ($self, $colourName, $check) = @_;

        # Local variables
        my $newColour;

        # Check for improper arguments
        if (! defined $colourName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getColour', @_);
        }

        # Don't lookup the same colour more than once. On each occasion, store it in the
        #   $self->allocatedColourHash
        if ($self->ivExists('allocatedColourHash', $colourName)) {

            return $self->ivShow('allocatedColourHash', $colourName);

        } else {

            # Look up the colour
            $newColour = Gtk2::Gdk::Color->parse($colourName);
            $self->colourMap->alloc_color($newColour, TRUE, TRUE);

            # Store it in the IV
            $self->ivAdd('allocatedColourHash', $colourName, $newColour);

            return $newColour;
        }
    }

    sub setColour {

        # Called by $self->drawPoints, ->drawLine, ->drawRectangle and ->drawPolygon
        # Prepares the drawing area by getting or creating a Gtk2 graphics context in the correct
        #   colour
        #
        # Expected arguments
        #   $colour     - A transcribable colour, e.g. 'blue'
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the Gtk2::Gdk::GC retrieved or created

        my ($self, $colour, $check) = @_;

        # Local variables
        my ($colourMap, $graphicsContext);

        # Check for improper arguments
        if (! defined $colour || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setColour', @_);
        }

        # Get the colour map and graphics context
        $colourMap = $self->pixmap->get_colormap();
        $graphicsContext = $self->pixmap->{gc} || Gtk2::Gdk::GC->new($self->pixmap);

        # Set the drawing colour
        $graphicsContext->set_foreground($self->getColour($colour));

        return $graphicsContext;
    }

    sub drawPoints {

        # Draws a series of pixels in the specified drawing area
        #
        # Expected arguments
        #   $drawable   - A list reference used by Gtk2::Gdk::Drawable, in the form
        #                   [X1, Y1, X2, Y2, ...],
        #   $colour     - A transcribable colour, e.g. 'blue'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $drawable, $colour, $check) = @_;

        # Local variables
        my $graphicsContext;

        # Check for improper arguments
        if (! defined $drawable || ! defined $colour || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->drawPoints', @_);
        }

        # Set the drawing colour
        $graphicsContext = $self->setColour($colour);
        if ($graphicsContext) {

            # Draw the points
            $self->pixmap->draw_points($graphicsContext, @$drawable);

            # Without this line the screen won't be updated until a screen action
            $self->drawingArea->queue_draw();
        }

        return 1;
    }

    sub drawLine {

        # Draws a line in the specified drawing area
        #
        # Expected arguments
        #   $drawable   - A list reference used by Gtk2::Gdk::Drawable, in the form
        #                   [startX, startY, stopX, stopY], e.g. [0, 0, 100, 100]
        #   $colour     - A transcribable colour, e.g. 'blue'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $drawable, $colour, $check) = @_;

        # Local variables
        my $graphicsContext;

        # Check for improper arguments
        if (! defined $drawable || ! defined $colour || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->drawLine', @_);
        }

        # Set the drawing colour
        $graphicsContext = $self->setColour($colour);
        if ($graphicsContext) {

            # Draw the line
            $self->pixmap->draw_line($graphicsContext, @$drawable);

            # Without this line the screen won't be updated until a screen action
            $self->drawingArea->queue_draw();
        }

        return 1;
    }

    sub drawRectangle {

        # Draws a rectangle in the specified drawing area
        # NB Corrects for a possible Gtk2 issue by adjusting the width and height of a rectangle
        #   that isn't filled-in
        #
        # Expected arguments
        #   $drawable   - A list reference used by Gtk2::Gdk::Drawable, in the form
        #                   [startX, startY, width, height], e.g. [0, 0, 150, 100]
        #   $colour     - A transcribable colour, e.g. 'blue'
        #   $fillFlag   - If set to TRUE, the rectangle is filled in; otherwise set to FALSE
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $drawable, $colour, $fillFlag, $check) = @_;

        # Local variables
        my $graphicsContext;

        # Check for improper arguments
        if (! defined $drawable || ! defined $colour || ! defined $fillFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->drawRectangle', @_);
        }

        # Set the drawing colour
        $graphicsContext = $self->setColour($colour);
        if ($graphicsContext) {

            # NB - for some reason (perhaps a Gtk2 issue), a rectangle that isn't filled in is
            #   drawn with a width and height 1 pixel bigger than the arguments specify. A
            #   filled-in rectangle is drawn correctly. Make a correction here
            if (! $fillFlag) {

                $$drawable[2]--;    # Width
                $$drawable[3]--;    # Height
            }

            # Draw the rectangle
            $self->pixmap->draw_rectangle($graphicsContext, $fillFlag, @$drawable);

            # Without this line the screen won't be updated until a screen action
            $self->drawingArea->queue_draw();
        }

        return 1;
    }

    sub drawPolygon {

        # Draws a polygon in the specified drawing area
        #
        # Expected arguments
        #   $drawable   - A list reference used by Gtk2::Gdk::Drawable, in the form
        #                   [X, Y, X, Y, X, Y...], e.g. [10, 10, 20, 20, 10, 30]
        #   $colour     - A transcribable colour, e.g. 'blue'
        #   $fillFlag   - If set to TRUE, the polygon is filled in; otherwise set to FALSE
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $drawable, $colour, $fillFlag, $check) = @_;

        # Local variables
        my $graphicsContext;

        # Check for improper arguments
        if (! defined $drawable || ! defined $colour || ! defined $fillFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->drawPolygon', @_);
        }

        # Set the drawing colour
        $graphicsContext = $self->setColour($colour);
        if ($graphicsContext) {

            # Draw the rectangle
            $self->pixmap->draw_polygon($graphicsContext, $fillFlag, @$drawable);

            # Without this line the screen won't be updated until a screen action
            $self->drawingArea->queue_draw();
        }

        return 1;
    }

    sub drawPangoText {

        # Draws pango markup text in the specified drawing area
        #
        # Expected arguments
        #   $xPos, $yPos    - The coordinates at which to draw
        #   $text           - The pango markup text to draw, e.g.
        #                       "<span background = '#000000'"
        #                       . " foreground = '#FF0000'"
        #                       . " size = '20000'"
        #                       . " weight = 'heavy'>"
        #                       . "Exact time:\n"
        #                       . "</span>"
        #
        #                       . "<span background = '#000000'"
        #                       . " foreground = '#00FF00'"
        #                       . " size = '30000'"
        #                       . " weight = 'ultralight'>"
        #                       . "<i><u>midnight</u></i>"
        #                       . "</span>"
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $xPos, $yPos, $text, $check) = @_;

        # Local variables
        my ($pixmap, $graphicsContext, $pangoLayout, $fontDescrip);

        # Check for improper arguments
        if (! defined $xPos || ! defined $yPos || ! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->drawPangoText', @_);
        }

        # Get the pixmap in use
        $pixmap = $self->pixmap;
        # Get the graphics context
        $graphicsContext = Gtk2::Gdk::GC->new($pixmap);

        # Create the pango layout
        $pangoLayout = $self->drawingArea->create_pango_layout("");

        # Set the font description
        $fontDescrip = Gtk2::Pango::FontDescription->from_string(
            $axmud::CLIENT->constFont . ' ' . $axmud::CLIENT->constFontSize       # 'Monospace 10'
        );

        $pangoLayout->set_font_description($fontDescrip);

        # Set the pango markup
        $pangoLayout->set_markup($text);

        # Draw the text onto the pixmap
        $pixmap->draw_layout($graphicsContext, $xPos, $yPos, $pangoLayout);
        # Without this line the screen won't be updated until a screen action
        $self->drawingArea->queue_draw();

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub width
        { $_[0]->{width} }
    sub height
        { $_[0]->{height} }

    sub scrolledWin
        { $_[0]->{scrolledWin} }
    sub hAdjustment
        { $_[0]->{hAdjustment} }
    sub viewPort
        { $_[0]->{viewPort} }
    sub drawingArea
        { $_[0]->{drawingArea} }
    sub eventBox
        { $_[0]->{eventBox} }

    sub pixmap
        { $_[0]->{pixmap} }
    sub graphicsContext
        { $_[0]->{graphicsContext} }
    sub colourMap
        { $_[0]->{colourMap} }

    sub allocatedColourHash
        { my $self = shift; return %{$self->{allocatedColourHash}}; }
}

# Package must return true
1
