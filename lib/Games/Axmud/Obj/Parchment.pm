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
# Games::Axmud::Obj::Parchment
# Handles canvas widgets and canvas objects for drawing a single region
# Games::Axmud::Obj::ParchmentLevel
# Stores the canvas objects drawn on a single level in that region

{ package Games::Axmud::Obj::Parchment;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Win::Map->setCurrentRegion and ->preparePreDraw
        # Creates a parchment object, which handles canvas widgets and canvas objects for drawing a
        #   single region
        #
        # Expected arguments
        #   $name           - The name of the region/regionmap (matching a key in
        #                           GA::Obj::WorldModel->regionmapHash)
        #   $worldModelObj  - The world model (GA::Obj::WorldModel) used by this session
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $name, $worldModelObj, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => undef,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The name of the region/regionmap (matching a key in
            #   GA::Obj::WorldModel->regionmapHash)
            name                        => $name,
            # The world model (GA::Obj::WorldModel) used by this session
            worldModelObj               => $worldModelObj,

            # A hash of Goo2Canvas::Canvas widgets, one for each level on which rooms, exits and
            #   labels are drawn
            # Hash in the form
            #   $canvasWidgetHash{level} = Goo2Canvas::Canvas
            canvasWidgetHash            => {},
            # In order to make the background the colour we want, a single Goo2Canvas::CanvasRect
            #   (called the 'background canvas object) is drawn, one for each level
            # Hash in the form
            #   $bgHash{level} = Goo2Canvas::CanvasRect
            bgCanvasObjHash             => {},

            # The map itself is just a collection of GA::ModelObj::Room objects, GA::Obj::Exit
            #   objects and GA::Obj::MapLabel objects. They are stored in each region's
            #   GA::Obj::Regionmap
            # This parchment objects consists of one or more canvas widgets (Goo2Canvas::Canvas
            #   objects, stored above), and a collection of canvas objects
            #   (Goo2Canvas::CanvasRect, Goo2Canvas::CanvasText, etc)
            # Each GA::ModelObj::Room, GA::Obj::Exit and GA::Obj::MapLabel object is drawn using
            #   one or more canvas objects
            # In order to stack the canvas objects correctly (i.e. so labels appear above rooms),
            #   we need to know which canvas objects have been drawn on each level
            # A parchment level object (GA::Obj::ParchmentLevel) stores all the canvas objects
            #   drawn on each level. Hash in the form
            #   $levelHash{level} = blessed_reference_to_parchment_level_object
            levelHash                   => {},

            # Coloured squares and rectangles are stored here, not in the parchment level object
            # Hash of coloured gridblocks (for background colouring, not a clickable object on the
            #   map), in the form
            #   $colouredSquareHash{'x_y_z'} = canvas_object
            colouredSquareHash          => {},
            # Hash of coloured rectangles (for background colouring, not a clickable object on the
            #   map), in the form
            #   $colouredRectHash{object-number_level} = canvas_object
            colouredRectHash            => {},

            # When we need to draw (or redraw) objects on the canvas, we might want to
            #   1. Draw the objects right away, because they're drawn on the visible region and
            #       level
            #   2. Don't draw the objects yet, because we want to wait until something is finished
            #       before we do the drawing
            #   3. Don't draw the objects yet, because they're not drawn on the visible region and
            #       level; add them to the queue so they can be drawn by background processes (i.e.
            #       regular calls to GA::Win::Map->winUpdate)
            #
            # For (1) draw things right away, code can call GA::Win::Map->doDraw with a list of
            #   things to draw. Anything that's not on the visible region and level is added to the
            #   queue (3)
            #
            # For (2) drawn things soon, code can call GA::Win::Map->markObjs. Any objects on the
            #   visible region and level are added to these hashes; any other objects are added to
            #   the queue (3)
            # When it's time to draw the marked objects, the code can just call ->doDraw again
            #
            # Since we're using hashes, it's safe to call ->doDraw or ->markObjs with the same
            #   object multiple times
            # Drawing a room will redraw any room tags/room guilds associated with that room. If
            #   the room tag/room guild has already been drawn, it is not drawn a second time during
            #   any single call to GA::Win::Map->doDraw.
            # The same applies for exits; drawing an exit will redraw its exit tag. If the exit tag
            #   has already been drawn, it is not drawn a second time during any single call to
            #   GA::Win::Map->doDraw
            # Hash of rooms to be drawn soon, in the form
            #   $markedRoomHash{model_number} = blessed_reference_to_room_object
            markedRoomHash              => {},
            # Hash of room tags to be drawn soon, in the form
            #   $markedRoomTagHash{model_number} = blessed_reference_to_room_object
            markedRoomTagHash           => {},
            # Hash of room guilds to be drawn soon, in the form
            #   $markedRoomGuildHash{model_number} = blessed_reference_to_room_object
            markedRoomGuildHash         => {},
            # Hash of exits to be drawn soon, in the form
            #   $markedExitHash{exit_model_number} = blessed_reference_to_exit_object
            markedExitHash              => {},
            # Hash of exit tagss to be drawn soon, in the form
            #   $markedExitTagHash{exit_model_number} = blessed_reference_to_exit_object
            markedExitTagHash           => {},
            # Hash of labels to be drawn soon, in the form
            #   $markedLabelHash{label_number} = blessed_reference_to_label_object
            markedLabelHash             => {},
            #
            # For (3) draw things using background processes, objects are added to these hashes
            #   until the background processes are ready to draw them
            # Canvas objects are arranged in a stack (so that labels are drawn above rooms). The
            #   stack is in the order:
            #   7   - labels and draggable exits (placed at the top of the stack)
            #   6   - room tags, room guilds and exit tags
            #   5   - exits, exit ornaments and checked directions
            #   4   - room interior text
            #   3   - room boxes
            #   2   - room echoes and fake room boxes
            #   1   - coloured rectangles on the map background
            #   0   - coloured blocks on the map background
            #   -   - map background (at the bottom of the stack)
            # When pre-drawing, objects are drawn in stack order, from bottom to top; in very large
            #   maps (thousands of rooms), GooCanvas2 can complete the drawing much more quickly
            #   when everything can be raised to the top of the stack, rather than being
            #   arbitrarily inserted somewhere in the middle
            #
            # Hash of rooms whose room echoes are waiting to be drawn. in the form
            #   $queueRoomEchoHash{model_number} = blessed_reference_to_room_object
            # (When the echo is drawn, the room is removed from this hash, and added to the next)
            queueRoomEchoHash           => {},
            # Hash of rooms whose room boxes are waiting to be drawn, in the form
            #   $queueRoomBoxHash{model_number} = blessed_reference_to_room_object
            # (When the box is drawn, the room is removed from this hash, and added to the next)
            queueRoomBoxHash            => {},
            # Hash of rooms whose interior text is waiting to be drawn, in the form
            #   $queueRoomTextHash{model_number} = blessed_reference_to_room_object
            # (When the text is drawn, the room is removed from this hash, and added to the next)
            queueRoomTextHash           => {},
            # Hash of rooms whose exits, exit ornaments and checked directions are waiting to be
            #   drawn, in the form
            #   $queueRoomExitHash{model_number} = blessed_reference_to_room_object
            # (When the text is drawn, the room is removed from this hash, and added to the next)
            queueRoomExitHash           => {},
            # Hash of rooms whose room tags, room guilds and exit tags are waiting to be drawn, in
            #   the form
            #   $queueRoomInfoHash{model_number} = blessed_reference_to_room_object
            # (When the text is drawn, the room is completely drawn, so is removed from this hash)
            queueRoomInfoHash           => {},
            # Hash of labels waiting to be drawn, in the form
            #   $queueLabelHash{label_number} = blessed_reference_to_label_object
            queueLabelHash              => {},

            # When obscured rooms are enabled, exits are only drawn for rooms near the current room,
            #   or for selected rooms (and selected exits), and for rooms whose rooms flags match
            #   those in GA::Client->constRoomNoObscuredHash (e.g. 'main_route')
            # When obscured rooms are enabled, this hash is reset by a call to
            #   GA::Win::Map->compileNoObscuredRooms. The hash contains any rooms which are due to
            #   be drawn, and which should not be obscured
            # Hash in the form
            #   $noObscuredRoomHash{model_number} = undef
            noObscuredRoomHash          => {},
            # When $self->noObscuredRoomHash, any rooms that are being removed from the hash are
            #   stored in this IV. The calling code uses this IV to destroy the room's exit canvas
            #   objects, if required
            reObscuredRoomHash          => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    # Get canvas objects

    sub getDrawnRoom {

        # Called by various functions
        # Given a room model object (GA::ModelObj::Room), returns a reference to a list of canvas
        #   objects that have been used to draw it (or 'undef', if that room isn't yet drawn in this
        #   region)
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #
        # Return values
        #   'undef' on improper arguments or if the room object has not been drawn
        #   Otherwise returns the list reference described above

        my ($self, $roomObj, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getDrawnRoom', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            return $levelObj->ivShow(
                'drawnRoomHash',
                $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks,
            );

        } else {

            # Room not drawn
            return undef;
        }
    }

    sub getDrawnExit {

        # Called by various functions
        # Given an exit model object (GA::Obj::Exit), returns a reference to a list of canvas
        #   objects that have been used to draw it (or 'undef', if that exit isn't yet drawn in this
        #   region)
        #
        # Expected arguments
        #   $exitObj    - The exit model object
        #
        # Optional arguments
        #   $roomObj    - The exit's parent room, if known. Otherwise this function fetches it
        #
        # Return values
        #   'undef' on improper arguments or if the exit object has not been drawn
        #   Otherwise returns the list reference described above

        my ($self, $exitObj, $roomObj, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getDrawnExit', @_);
        }

        if (! $roomObj) {

            $roomObj = $self->worldModelObj->ivShow('modelHash', $exitObj->parent);
        }

        if ($roomObj) {

            $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
            if ($levelObj) {

                return $levelObj->ivShow('drawnExitHash', $exitObj->number);
            }
        }

        # Exit not drawn
        return undef;
    }

    sub getDrawnLabel {

        # Called by various functions
        # Given a map label object (GA::Obj::MapLabel), returns a reference to a list of canvas
        #   objects that have been used to draw it (or 'undef', if that room isn't yet drawn in this
        #   region)
        #
        # Expected arguments
        #   $labelObj   - The map label object
        #
        # Return values
        #   'undef' on improper arguments or if the label object has not been drawn
        #   Otherwise returns the list reference described above

        my ($self, $labelObj, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $labelObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getDrawnLabel', @_);
        }

        $levelObj = $self->ivShow('levelHash', $labelObj->level);
        if ($levelObj) {

            return $levelObj->ivShow('drawnLabelHash', $labelObj->number);

        } else {

            # Label not drawn
            return undef;
        }
    }

    # Add canvas objects

    sub addDrawnRoom {

        # After drawing a room model object (GA::ModelObj::Room), the automapper window calls this
        #   function to store the canvas object(s)
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $listRef, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnRoom', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $levelObj->ivAdd(
                'drawnRoomHash',
                $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks,
                $listRef,
            );
        }

        return 1;
    }

    sub addDrawnRoomEcho {

        # After drawing a room echo for a room model object (GA::ModelObj::Room), the automapper
        #   window calls this function to store the canvas object(s)
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #   $mode       - +1 if this echo is drawn just above the room, -1 if it's drawn just below
        #                   the room
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $mode, $listRef, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $mode || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnRoomEcho', @_);
        }

        $levelObj = $self->ivShow('levelHash', ($roomObj->zPosBlocks + $mode));
        if ($levelObj) {

            $levelObj->ivAdd(
                'drawnRoomEchoHash',
                $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks,
                $listRef,
            );
        }

        return 1;
    }

    sub addDrawnRoomTag {

        # After drawing a room tag for a room model object (GA::ModelObj::Room), the automapper
        #   window calls this function to store the canvas object(s)
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $listRef, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnRoomTag', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $levelObj->ivAdd(
                'drawnRoomTagHash',
                $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks,
                $listRef,
            );
        }

        return 1;
    }

    sub addDrawnRoomGuild {

        # After drawing a room guild for a room model object (GA::ModelObj::Room), the automapper
        #   window calls this function to store the canvas object(s)
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $listRef, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnRoomGuild', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $levelObj->ivAdd(
                'drawnRoomGuildHash',
                $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks,
                $listRef,
            );
        }

        return 1;
    }

    sub addDrawnRoomText {

        # After drawing room text for a room model object (GA::ModelObj::Room), the automapper
        #   window calls this function to store the canvas object(s)
        # This function might be called more than once while drawing a room, so if canvas objects
        #   for the room already exist, the new canvas objects are added to them
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $listRef, $check) = @_;

        # Local variables
        my ($levelObj, $posn, $oldListRef);

        # Check for improper arguments
        if (! defined $roomObj || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnRoomText', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
            $oldListRef = $levelObj->ivShow('drawnRoomTextHash', $posn);
            if (defined $oldListRef) {

                push (@$oldListRef, @$listRef);

            } else {

                $levelObj->ivAdd('drawnRoomTextHash', $posn, $listRef);
            }
        }

        return 1;
    }

    sub addDrawnExit {

        # After drawing an exit model object (GA::Obj::Exit), the automapper window calls this
        #   function to store the canvas object(s)
        #
        # Expected arguments
        #   $roomObj    - The parent room model object
        #   $exitObj    - The exit model object
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $exitObj, $listRef, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $exitObj || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnExit', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $levelObj->ivAdd('drawnExitHash', $exitObj->number, $listRef);
        }

        return 1;
    }

    sub addDrawnExitTag {

        # After drawing an exit tag for an exit model object (GA::Obj::Exit), the automapper window
        #   calls this function to store the canvas object(s)
        #
        # Expected arguments
        #   $roomObj    - The parent room model object
        #   $exitObj    - The exit model object
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $exitObj, $listRef, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $exitObj || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnExitTag', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $levelObj->ivAdd('drawnExitTagHash', $exitObj->number, $listRef);
        }

        return 1;
    }

    sub addDrawnOrnament {

        # After drawing an exit ornament for an exit model object (GA::Obj::Exit), the automapper
        #   window calls this function to store the canvas object(s)
        #
        # Expected arguments
        #   $roomObj    - The parent room model object
        #   $exitObj    - The exit model object
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $exitObj, $listRef, $check) = @_;

        # Local variables
        my ($levelObj, $oldListRef);

        # Check for improper arguments
        if (! defined $roomObj || ! defined $exitObj || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnOrnament', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            # This function might be called twice; once for an exit, and once for its twin exit, in
            #   which case combine the canvas objects drawn into one list
            $oldListRef = $levelObj->ivShow('drawnOrnamentHash', $exitObj->number);
            if (! defined $oldListRef) {
                $levelObj->ivAdd('drawnOrnamentHash', $exitObj->number, $listRef);
            } else {
                push (@$oldListRef, @$listRef);
            }
        }

        return 1;
    }

    sub addDrawnLabel {

        # After drawing a map model object (GA::Obj::MapLabel), the automapper window calls this
        #   function to store the canvas object(s)
        #
        # Expected arguments
        #   $labelObj   - The map label object
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $labelObj, $listRef, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $labelObj || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnLabel', @_);
        }

        $levelObj = $self->ivShow('levelHash', $labelObj->level);
        if ($levelObj) {

            $levelObj->ivAdd('drawnLabelHash', $labelObj->number, $listRef);
        }

        return 1;
    }

    sub addDrawnCheckedDir {

        # After drawing one or more checked directions for a room model object (GA::ModelObj::Room),
        #   the automapper window calls this function to store the canvas object(s)
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #   $listRef    - Reference to a list of canvas objects
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $listRef, $check) = @_;

        # Local variables
        my $levelObj;

        # Check for improper arguments
        if (! defined $roomObj || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawnCheckedDir', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $levelObj->ivAdd(
                'drawnCheckedDirHash',
                $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks,
                $listRef,
            );
        }

        return 1;
    }

    # Delete canvas objects

    sub deleteDrawnRoom {

        # Called by various functions
        # Checks whether a room model object (GA::ModelObj::Room) has been drawn for this region. If
        #   so, removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #
        # Optional arguments
        #   $allFlag    - If TRUE, canvas objects for any room echoes/room tags/room guilds/room
        #                   text/checked directions are removed at the same time. FALSE (or
        #                   'undef') otherwise
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $allFlag, $check) = @_;

        # Local variables
        my ($levelObj, $posn, $listRef);

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnRoom', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
            $listRef = $levelObj->ivShow('drawnRoomHash', $posn);
            if (defined $listRef) {

                # Delete these canvas objects
                foreach my $canvasObj (@$listRef) {

                    $canvasObj->remove();
                }

                $levelObj->ivDelete('drawnRoomHash', $posn);
            }

            if ($allFlag) {

                foreach my $echoLevel (($roomObj->zPosBlocks + 1), ($roomObj->zPosBlocks - 1)) {

                    my $echoLevelObj = $self->ivShow('levelHash', $echoLevel);
                    if ($echoLevelObj) {

                        $listRef = $echoLevelObj->ivShow('drawnRoomEchoHash', $posn);
                        if (defined $listRef) {

                            foreach my $canvasObj (@$listRef) {

                                $canvasObj->remove();
                            }

                            $echoLevelObj->ivDelete('drawnRoomEchoHash', $posn);
                        }
                    }
                }

                $listRef = $levelObj->ivShow('drawnRoomTagHash', $posn);
                if (defined $listRef) {

                    foreach my $canvasObj (@$listRef) {

                        $canvasObj->remove();
                    }

                    $levelObj->ivDelete('drawnRoomTagHash', $posn);
                }

                $listRef = $levelObj->ivShow('drawnRoomGuildHash', $posn);
                if (defined $listRef) {

                    foreach my $canvasObj (@$listRef) {

                        $canvasObj->remove();
                    }

                    $levelObj->ivDelete('drawnRoomGuildHash', $posn);
                }

                $listRef = $levelObj->ivShow('drawnRoomTextHash', $posn);
                if (defined $listRef) {

                    foreach my $canvasObj (@$listRef) {

                        $canvasObj->remove();
                    }

                    $levelObj->ivDelete('drawnRoomTextHash', $posn);
                }

                $listRef = $levelObj->ivShow('drawnCheckedDirHash', $posn);
                if (defined $listRef) {

                    foreach my $canvasObj (@$listRef) {

                        $canvasObj->remove();
                    }

                    $levelObj->ivDelete('drawnCheckedDirHash', $posn);
                }
            }
        }

        return 1;
    }

    sub deleteDrawnRoomEcho {

        # Called by various functions
        # Checks whether a room echo for a room model object (GA::ModelObj::Room) has been drawn for
        #   this region. If so, removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $check) = @_;

        # Local variables
        my $posn;

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnRoomEcho', @_);
        }

        $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;

        foreach my $level (($roomObj->zPosBlocks + 1), ($roomObj->zPosBlocks - 1)) {

            my ($levelObj, $posn, $listRef);

            $levelObj = $self->ivShow('levelHash', $level);
            if ($levelObj) {

                $listRef = $levelObj->ivShow('drawnRoomEchoHash', $posn);
                if (defined $listRef) {

                    # Delete these canvas objects
                    foreach my $canvasObj (@$listRef) {

                        $canvasObj->remove();
                    }

                    $levelObj->ivDelete('drawnRoomEchoHash', $posn);
                }
            }
        }

        return 1;
    }

    sub deleteDrawnRoomTag {

        # Called by various functions
        # Checks whether a room tag for a room model object (GA::ModelObj::Room) has been drawn for
        #   this region. If so, removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $check) = @_;

        # Local variables
        my ($levelObj, $posn, $listRef);

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnRoomTag', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
            $listRef = $levelObj->ivShow('drawnRoomTagHash', $posn);
            if (defined $listRef) {

                # Delete these canvas objects
                foreach my $canvasObj (@$listRef) {

                    $canvasObj->remove();
                }

                $levelObj->ivDelete('drawnRoomTagHash', $posn);
            }
        }

        return 1;
    }

    sub deleteDrawnRoomGuild {

        # Called by various functions
        # Checks whether a room guild for a room model object (GA::ModelObj::Room) has been drawn
        #   for this region. If so, removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $check) = @_;

        # Local variables
        my ($levelObj, $posn, $listRef);

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnRoomGuild', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
            $listRef = $levelObj->ivShow('drawnRoomGuildHash', $posn);
            if (defined $listRef) {

                # Delete these canvas objects
                foreach my $canvasObj (@$listRef) {

                    $canvasObj->remove();
                }

                $levelObj->ivDelete('drawnRoomGuildHash', $posn);
            }
        }

        return 1;
    }

    sub deleteDrawnRoomText {

        # Called by various functions
        # Checks whether room text for a room model object (GA::ModelObj::Room) has been drawn for
        #   this region. If so, removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $check) = @_;

        # Local variables
        my ($levelObj, $posn, $listRef);

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnRoomText', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
            $listRef = $levelObj->ivShow('drawnRoomTextHash', $posn);
            if (defined $listRef) {

                # Delete these canvas objects
                foreach my $canvasObj (@$listRef) {

                    $canvasObj->remove();
                }

                $levelObj->ivDelete('drawnRoomTextHash', $posn);
            }
        }

        return 1;
    }

    sub deleteDrawnExit {

        # Called by various functions
        # Checks whether an exit model object (GA::Obj::Exit) has been drawn for this region. If
        #   so, removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $exitObj    - The exit model object
        #
        # Optional arguments
        #   $roomObj    - The exit's parent room, if known. Otherwise this function fetches it
        #   $allFlag    - If TRUE, canvas objects for any exit tags/ornaments are removed at the
        #                   same time. FALSE (or 'undef') otherwise
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $roomObj, $allFlag, $check) = @_;

        # Local variables
        my ($levelObj, $listRef);

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnExit', @_);
        }

        if (! $roomObj) {

            $roomObj = $self->worldModelObj->ivShow('modelHash', $exitObj->parent);
        }

        if ($roomObj) {

            $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
            if ($levelObj) {

                $listRef = $levelObj->ivShow('drawnExitHash', $exitObj->number);
                if (defined $listRef) {

                    # Delete these canvas objects
                    foreach my $canvasObj (@$listRef) {

                        $canvasObj->remove();
                    }

                    $levelObj->ivDelete('drawnExitHash', $exitObj->number);
                }

                if ($allFlag) {

                    $listRef = $levelObj->ivShow('drawnExitTagHash', $exitObj->number);
                    if (defined $listRef) {

                        foreach my $canvasObj (@$listRef) {

                            $canvasObj->remove();
                        }

                        $levelObj->ivDelete('drawnExitTagHash', $exitObj->number);
                    }

                    $listRef = $levelObj->ivShow('drawnOrnamentHash', $exitObj->number);
                    if (defined $listRef) {

                        foreach my $canvasObj (@$listRef) {

                            $canvasObj->remove();
                        }

                        $levelObj->ivDelete('drawnOrnamentHash', $exitObj->number);
                    }
                }
            }
        }

        return 1;
    }

    sub deleteDrawnExitTag {

        # Called by various functions
        # Checks whether an exit tag for an exit model object (GA::Obj::Exit) has been drawn for
        #   this region. If so, removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $exitObj    - The exit model object
        #
        # Optional arguments
        #   $roomObj    - The exit's parent room, if known. Otherwise this function fetches it
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $roomObj, $check) = @_;

        # Local variables
        my ($levelObj, $listRef);

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnExitTag', @_);
        }

        if (! $roomObj) {

            $roomObj = $self->worldModelObj->ivShow('modelHash', $exitObj->parent);
        }

        if ($roomObj) {

            $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
            if ($levelObj) {

                $listRef = $levelObj->ivShow('drawnExitTagHash', $exitObj->number);
                if (defined $listRef) {

                    # Delete these canvas objects
                    foreach my $canvasObj (@$listRef) {

                        $canvasObj->remove();
                    }

                    $levelObj->ivDelete('drawnExitTagHash', $exitObj->number);
                }
            }
        }

        return 1;
    }

    sub deleteDrawnOrnament {

        # Called by various functions
        # Checks whether an exit ornament for an exit model object (GA::Obj::Exit) has been drawn
        #   for this region. If so, removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $exitObj    - The exit model object
        #
        # Optional arguments
        #   $roomObj    - The exit's parent room, if known. Otherwise this function fetches it
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $exitObj, $roomObj, $check) = @_;

        # Local variables
        my ($levelObj, $listRef);

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnOrnament', @_);
        }

        if (! $roomObj) {

            $roomObj = $self->worldModelObj->ivShow('modelHash', $exitObj->parent);
        }

        if ($roomObj) {

            $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
            if ($levelObj) {

                $listRef = $levelObj->ivShow('drawnOrnamentHash', $exitObj->number);
                if (defined $listRef) {

                    # Delete these canvas objects
                    foreach my $canvasObj (@$listRef) {

                        $canvasObj->remove();
                    }

                    $levelObj->ivDelete('drawnOrnamentHash', $exitObj->number);
                }
            }
        }

        return 1;
    }

    sub deleteDrawnLabel {

        # Called by various functions
        # Checks whether a map label object (GA::Obj::MapLabel) has been drawn for this region. If
        #   so, removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $labelObj   - The map label object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $labelObj, $check) = @_;

        # Local variables
        my ($levelObj, $listRef);

        # Check for improper arguments
        if (! defined $labelObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnLabel', @_);
        }

        $levelObj = $self->ivShow('levelHash', $labelObj->level);
        if ($levelObj) {

            $listRef = $levelObj->ivShow('drawnLabelHash', $labelObj->number);
            if (defined $listRef) {

                # Delete these canvas objects
                foreach my $canvasObj (@$listRef) {

                    $canvasObj->remove();
                }

                $levelObj->ivDelete('drawnLabelHash', $labelObj->number);
            }
        }

        return 1;
    }

    sub deleteDrawnCheckedDir {

        # Called by various functions
        # Checks whether checked directions for a room model object (GA::ModelObj::Room) have been
        #   drawn for this region. If so, removes the canvas objects used to draw them and updates
        #   IVs
        #
        # Expected arguments
        #   $roomObj    - The room model object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $roomObj, $check) = @_;

        # Local variables
        my ($levelObj, $posn, $listRef);

        # Check for improper arguments
        if (! defined $roomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteDrawnCheckedDir', @_);
        }

        $levelObj = $self->ivShow('levelHash', $roomObj->zPosBlocks);
        if ($levelObj) {

            $posn = $roomObj->xPosBlocks . '_' . $roomObj->yPosBlocks . '_' . $roomObj->zPosBlocks;
            $listRef = $levelObj->ivShow('drawnCheckedDirHash', $posn);
            if (defined $listRef) {

                # Delete these canvas objects
                foreach my $canvasObj (@$listRef) {

                    $canvasObj->remove();
                }

                $levelObj->ivDelete('drawnCheckedDirHash', $posn);
            }
        }

        return 1;
    }

    sub deleteColouredSquare {

        # Called by various functions
        # Checks whether a particular coloured square has been drawn for this region. If so,
        #   removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $string     - A string used to stored the coloured square in $self->colouredSquareHash;
        #                   in the form 'x_y' (for squares visible on all levels) or 'x_y_z' (for
        #                   squares visible only on one level)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $string, $check) = @_;

        # Local variables
        my $canvasObj;

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteColouredSquare', @_);
        }

        $canvasObj = $self->ivShow('colouredSquareHash', $string);
        if ($canvasObj) {

            # $string is in the form 'x_y_z'. Delete the canvas object
            $canvasObj->remove();
            $self->ivDelete('colouredSquareHash', $string);

        } else {

            # $string is in the form 'x_y'. Check all levels
            foreach my $level ($self->ivKeys('levelHash')) {

                my $key = $string . '_' . $level;
                $canvasObj = $self->ivShow('colouredSquareHash', $key);
                if ($canvasObj) {

                    # Delete the canvas object
                    $canvasObj->remove();
                    $self->ivDelete('colouredSquareHash', $key);
                }
            }
        }

        return 1;
    }

    sub deleteColouredRect {

        # Called by various functions
        # Checks whether a particular coloured rectangle has been drawn for this region. If so,
        #   removes the canvas objects used to draw it and updates IVs
        #
        # Expected arguments
        #   $string     - A string used to stored the coloured rectangle in $self->colouredRectHash;
        #                   in the form 'object-number' (for rectangles visible on all levels) or
        #                   'object-number_level' (for rectangles visible only on one level)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $string, $check) = @_;

        # Local variables
        my $canvasObj;

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteColouredRect', @_);
        }

        $canvasObj = $self->ivShow('colouredRectHash', $string);
        if ($canvasObj) {

            # $string is in the form 'object-number_level'. Delete the canvas object
            $canvasObj->remove();
            $self->ivDelete('colouredRectHash', $string);

        } else {

            # $string is in the form 'object-number'. Check all levels
            foreach my $level ($self->ivKeys('levelHash')) {

                my $key = $string . '_' . $level;
                $canvasObj = $self->ivShow('colouredRectHash', $key);
                if ($canvasObj) {

                    # Delete the canvas object
                    $canvasObj->remove();
                    $self->ivDelete('colouredRectHash', $key);
                }
            }
        }

        return 1;
    }

    ##################
    # Accessors - set

    sub reset_markedHash {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_markedHash', @_);
        }

        $self->ivEmpty('markedRoomHash');
        $self->ivEmpty('markedRoomTagHash');
        $self->ivEmpty('markedRoomGuildHash');
        $self->ivEmpty('markedExitHash');
        $self->ivEmpty('markedExitTagHash');
        $self->ivEmpty('markedLabelHash');

        return 1;
    }

    sub reset_queueHash {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_queueHash', @_);
        }

        $self->ivEmpty('queueRoomEchoHash');
        $self->ivEmpty('queueRoomBoxHash');
        $self->ivEmpty('queueRoomTextHash');
        $self->ivEmpty('queueRoomExitHash');
        $self->ivEmpty('queueRoomInfoHash');
        $self->ivEmpty('queueLabelHash');

        return 1;
    }

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub worldModelObj
        { $_[0]->{worldModelObj} }

    sub canvasWidgetHash
        { my $self = shift; return %{$self->{canvasWidgetHash}}; }
    sub bgCanvasObjHash
        { my $self = shift; return %{$self->{bgCanvasObjHash}}; }

    sub levelHash
        { my $self = shift; return %{$self->{levelHash}}; }

    sub colouredSquareHash
        { my $self = shift; return %{$self->{colouredSquareHash}}; }
    sub colouredRectHash
        { my $self = shift; return %{$self->{colouredRectHash}}; }

    sub markedRoomHash
        { my $self = shift; return %{$self->{markedRoomHash}}; }
    sub markedRoomTagHash
        { my $self = shift; return %{$self->{markedRoomTagHash}}; }
    sub markedRoomGuildHash
        { my $self = shift; return %{$self->{markedRoomGuildHash}}; }
    sub markedExitHash
        { my $self = shift; return %{$self->{markedExitHash}}; }
    sub markedExitTagHash
        { my $self = shift; return %{$self->{markedExitTagHash}}; }
    sub markedLabelHash
        { my $self = shift; return %{$self->{markedLabelHash}}; }

    sub queueRoomEchoHash
        { my $self = shift; return %{$self->{queueRoomEchoHash}}; }
    sub queueRoomBoxHash
        { my $self = shift; return %{$self->{queueRoomBoxHash}}; }
    sub queueRoomTextHash
        { my $self = shift; return %{$self->{queueRoomTextHash}}; }
    sub queueRoomExitHash
        { my $self = shift; return %{$self->{queueRoomExitHash}}; }
    sub queueRoomInfoHash
        { my $self = shift; return %{$self->{queueRoomInfoHash}}; }
    sub queueLabelHash
        { my $self = shift; return %{$self->{queueLabelHash}}; }

    sub noObscuredRoomHash
        { my $self = shift; return %{$self->{noObscuredRoomHash}}; }
    sub reObscuredRoomHash
        { my $self = shift; return %{$self->{reObscuredRoomHash}}; }
}

{ package Games::Axmud::Obj::ParchmentLevel;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Win::Map->createMap
        # Stores the canvas objects drawn on a single level in a region
        #
        # Expected arguments
        #   $region - The name of the regionmap (and also of the parent parchment object,
        #               GA::Obj::Parchment)
        #   $level  - The regionmap level (matches a possible value for
        #               GA::Obj::Regionmap->currentLevel)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $region, $level, $check) = @_;

        # Check for improper arguments
        if (! defined $region || ! defined $level || ! defined $level || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $region . '_' . $level,
            _objClass                   => $class,
            _parentFile                 => undef,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # A name for this object, combining the region name and level
            name                        => $region . '_' . $level,
            # The region name and level as separate IVs
            region                      => $region,
            level                       => $level,

            # The map itself is just a collection of GA::ModelObj::Room objects, GA::Obj::Exit
            #   objects and GA::Obj::MapLabel objects. They are stored in each region's
            #   GA::Obj::Regionmap
            # Each GA::ModelObj::Room, GA::Obj::Exit and GA::Obj::MapLabel object is drawn using
            #   one or more canvas objects
            # These hashes work in parallel with the regionmap's ->gridRoomHash, ->gridRoomTagHash,
            #   ->gridRoomGuildHash, ->gridExitHash, ->gridExitTagHash and ->gridLabelHash. The keys
            #   are the same for each, but the values in these hashes contain a reference to a list
            #   of canvas objects (which may be a list containing one canvas object)
            # Only one room is allowed per gridblock, but exits and labels can be drawn freely
            #
            # These hashes contain everything currently drawn in this region, at this level (but
            #   they will be incomplete, if we haven't finished drawing objects in this region yet)
            # (NB Coloured squares and rectangles are stored in the parent parchment object)
            #
            # Hash of drawn rooms from this regionmap, in the form
            #   $drawnRoomHash{'x_y_z'} = [canvas_object, canvas_object...]
            drawnRoomHash               => {},
            # Hash of drawn room echos from this regionmap, in the form
            #   $drawnRoomEchoHash{'x_y_z'} = [canvas_object, canvas_object...]
            # NB A room has two echoes, one on the level above it, one on the level below; therefore
            #   two parchment level objects will have an entry for each room
            drawnRoomEchoHash           => {},
            # Hash of drawn rooms with room tags from this regionmap, in the form
            #   $drawnRoomTagHash{'x_y_z'} =  [canvas_object, canvas_object...]
            drawnRoomTagHash            => {},
            # Hash of drawn rooms with room guilds from this regionmap, in the form
            #   $drawnRoomGuildHash{'x_y_z'} =  [canvas_object, canvas_object...]
            drawnRoomGuildHash          => {},
            # Hash of drawn rooms that have text drawn within their interiors, in the form
            #   $drawnRoomTextHash{'x_y_z'} = [canvas_object, canvas_object...]
            drawnRoomTextHash           => {},
            # Hash of drawn exits from this regionmap (not necessarily all the exits in all the
            #   rooms), in the form
            #       $drawnExitHash{exit_model_number} = [canvas_object, canvas_object...]
            drawnExitHash               => {},
            # Hash of drawn exits with exit tags from this regionmap, in the form
            #   $drawnExitTagHash{exit_model_number} = [canvas_object, canvas_object...]
            drawnExitTagHash            => {},
            # Hash of drawn exits from this regionmap that have exit ornaments, in the form
            #   $drawnOrnamentHash{exit_model_number} = [canvas_object, canvas_object...]
            drawnOrnamentHash           => {},
            # Hash of (all) labels that exist in this regionmap, in the form
            #   $drawnLabelHash{label_number} = [canvas_object, canvas_object...]
            drawnLabelHash              => {},
            # Hash of checked directions for each room, if they have been drawn. Checked directions
            #   can't be clicked (selected), so all the canvas objects for checked directions in a
            #   room are stored together as a single key-value pair. Hash in the form
            #   $drawnCheckedDirHash{'x_y_z'} = [canvas_object, canvas_object...]
            drawnCheckedDirHash         => {},

            # Canvas objects are arranged in a stack (so that labels are drawn above rooms). The
            #   stack is in the order:
            #   7   - labels and draggable exits (placed at the top of the stack)
            #   6   - room tags, room guilds and exit tags
            #   5   - exits, exit ornaments and checked directions
            #   4   - room interior text
            #   3   - room boxes
            #   2   - room echoes and fake room boxes
            #   1   - coloured rectangles on the map background
            #   0   - coloured blocks on the map background
            #   -   - map background (at the bottom of the stack)
            # GooCanvas provides ->lower and ->raise functions, which move a canvas object above or
            #   below an existing canvas object (or to the top/bottom of the stack)
            # It would be nice to place a new room above the highest existing room in the stack, but
            #   we can't, because if the room is deleted we have no way of finding the next-highest
            #   room in the stack
            # Instead, we'll create eight slave canvas objects, hidden away in one corner of the
            #   map. Because the slave objects are never deleted, we can place every new canvas
            #   object immediately below one of the slave objects
            # Hence, we have a list of eight stunt objects, [0 1 2 3 4 5 6 7]. For example, the
            #   slave object at index 3 is just above all room boxes, and therefore all new room
            #   boxes are added to the stack just below it
            slaveCanvasObjList          => [],
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
    sub region
        { $_[0]->{region} }
    sub level
        { $_[0]->{level} }

    sub drawnRoomHash
        { my $self = shift; return %{$self->{drawnRoomHash}}; }
    sub drawnRoomEchoHash
        { my $self = shift; return %{$self->{drawnRoomEchoHash}}; }
    sub drawnRoomTagHash
        { my $self = shift; return %{$self->{drawnRoomTagHash}}; }
    sub drawnRoomGuildHash
        { my $self = shift; return %{$self->{drawnRoomGuildHash}}; }
    sub drawnRoomTextHash
        { my $self = shift; return %{$self->{drawnRoomTextHash}}; }
    sub drawnExitHash
        { my $self = shift; return %{$self->{drawnExitHash}}; }
    sub drawnExitTagHash
        { my $self = shift; return %{$self->{drawnExitTagHash}}; }
    sub drawnOrnamentHash
        { my $self = shift; return %{$self->{drawnOrnamentHash}}; }
    sub drawnLabelHash
        { my $self = shift; return %{$self->{drawnLabelHash}}; }
    sub drawnCheckedDirHash
        { my $self = shift; return %{$self->{drawnCheckedDirHash}}; }

    sub slaveCanvasObjList
        { my $self = shift; return @{$self->{slaveCanvasObjList}}; }
}

# Package must return a true value
1
