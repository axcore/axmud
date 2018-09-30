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
# Games::Axmud::Obj::Map
# The automapper object (separate and independent from the Automapper window object, GA::Win::Map)

{ package Games::Axmud::Obj::Map;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->setupProfiles
        #
        # Creates a new instance of the automapper object, which monitors the character's current
        #   location in the world.
        # The Automapper window itself is handled by GA::Win::Map. There is always an automapper
        #   object running, regardless of whether the Automapper window is open, or not
        #
        # Expected arguments
        #   $session        - The parent GA::Session
        #
        # Return values
        #   'undef' on improper arguments or if there is already an automapper object for this
        #       session
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'automapper',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # The parent GA::Session
            session                     => $session,
            # The session's current world model object (set by GA::Session->setupProfiles)
            worldModelObj               => undef,
            # The current Automapper window, GA::Map::Win, if open (undef, if not)
            mapWin                      => undef,

            # Automapper object IVs
            # ---------------------

            # Blessed reference of the current location (a GA::ModelObj::Room, 'undef' if there is
            #   no current location)
            currentRoom                 => undef,
            # Blessed reference of the last known location (a GA::ModelObj::Room), set when the
            #   automapper gets lost
            lastKnownRoom               => undef,
            # When the user types a command like 'e;enter cave;n', a separate GA::Buffer::Cmd
            #   object is created for each of the three commands, and the object's ->interpretCmd
            #   gets called each time
            # ->interpretCmd attemps to work out whether 'enter cave' is a movement command or not,
            #   but the automapper's ->currentRoom probably doesn't know anything about an exit
            #   called 'enter cave'
            # $self->ghostRoom is set equal to $self->currentRoom whenever the Locator processes a
            #   room statement, and isn't expecting any more room statements
            # Thereafter, each call to ->interpretCmd attemps to work out the destination room of
            #   the command; if a destination room is found, ->ghostRoom is set
            # In that way, ->interpretCmd can check the exits from rooms other than the current
            #   room, and in the command 'e;enter cave;n' will correctly work out that 'enter cave'
            #   will be a movement command from that room, once the character reaches it
            # ->ghostRoom is set to 'undef' whenever ->currentRoom is set to 'undef'
            ghostRoom                   => undef,

            # When the Automapper window isn't open, this object can track the character's position
            #   - but only when this flag is set to TRUE
            # Initially set to FALSE by default. Set to FALSE when the Automapper window opens or to
            #   TRUE when the Automapper window closes (if $self->currentRoom is set by then). Set
            #   to TRUE and back to FALSE by $self->setCurrentRoom)
            trackAloneFlag              => FALSE,
            # When the session's ->status is 'offline', $self->showPseudoStatement can construct a
            #   plausible room statement similar to what the user would see, if the character were
            #   to be wandering around the world
            # The type of statement to construct: 'verbose', 'short' or 'brief'
            pseudoStatementMode         => 'verbose',

            # IVs to handle random exits of the type 'temp_region', once the characters goes through
            #   it: the room object containing the exit, and its destination room
            tempRandomOriginRoom        => undef,
            tempRandomDestRoom          => undef,
            # The automapper window's ->mode when the character moved through the random exit, used
            #   to set the mode back to its original value (in the temporary region, we need the
            #   mode set to 'update')
            # Set to 'follow', 'update' or 'undef' if the automapper window isn't open
            tempRandomMode              => undef,
        };

        # Bless the window object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub openWin {

        # Called by GA::Session->start and ->setupProfiles, and by GA::Cmd::OpenAutomapper->do
        # If there is already an Automapper window open, reset it, and make this object its owner.
        #   Otherwise, create a new Automapper window
        # NB When the window closes, GA::Win::Map calls $self->set_mapWin
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error resetting an existing Automapper
        #       window, or opening a new one
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($winObj, $regionObj, $stripObj, $left, $right, $top, $bottom, $tableObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->openWin', @_);
        }

        if ($self->session->mapWin) {

            # There is already an Automapper window open. Reset it, and make this object the owner
            if (! $self->session->mapWin->winReset($self)) {

                # Due to the error, we're force to close the window
                $self->session->mapWin->winDestroy();

                return $self->writeError(
                    'Could not reset the Automapper window - window closed',
                    $self->_objClass . '->openWin',
                );

            } else {

                # This object is now the window's owner
                $self->ivPoke('mapWin', $self->session->mapWin);

                # Reset this object's IVs
                $self->ivUndef('currentRoom');
                $self->ivUndef('lastKnownRoom');
                $self->ivUndef('ghostRoom');
                $self->ivPoke('trackAloneFlag', FALSE);

                # If the Locator is running, it no longer knows the world model number of the
                #   current room
                if ($self->session->locatorTask) {

                    $self->session->locatorTask->resetModelRoom();
                }
            }

        } else {

            # Open a new Automapper window

            # Try to open a pseudo-window, if allowed
            if (! $axmud::CLIENT->shareMainWinFlag && $self->worldModelObj->pseudoWinFlag) {

                # If there are any holders (GA::Table::Holder) with an ->id set to 'map', we can
                #   use the space they occupy, rather than looking for a new space
                $stripObj = $self->session->mainWin->tableStripObj;
                $tableObj = $stripObj->replaceHolder(
                    'map',
                    'Games::Axmud::Table::PseudoWin',
                    undef,          # No ->objName
                    # ->initHash
                    'frame_title'       => 'Automapper',
                    'win_type'          => 'map',
                    'win_name'          => 'map',
                    'owner'             => $self->session,
                    'session'           => $self->session,
                );

                if (! $tableObj) {

                    # Ask the session's 'main' window for the size and position of another table
                    #   object, using the winmap's default winzone size, and check whether space
                    #   exists for another table object
                    ($left, $right, $top, $bottom) = $stripObj->findPosn();

                    if (defined $left) {

                        # Create the GA::Table::PseudoWin object at the specified size and
                        #   position
                        $tableObj = $stripObj->addTableObj(
                            'Games::Axmud::Table::PseudoWin',
                            $left,
                            $right,
                            $top,
                            $bottom,
                            undef,          # No ->objName
                            # ->initHash
                            'frame_title'       => 'Automapper',
                            'win_type'          => 'map',
                            'win_name'          => 'map',
                            'owner'             => $self->session,
                            'session'           => $self->session,
                        );
                    }
                }

                if ($tableObj) {

                    $winObj = $tableObj->pseudoWinObj;
                }
            }

            # If not allowed (or if a pseudo-window can't be opened), open a normal 'grid' window
            if (! $winObj) {

                $winObj = $self->session->mainWin->workspaceObj->createGridWin(
                    'map',                      # Window type
                    'map',                      # Window name
                    'Automapper',               # Window title
                    undef,                      # 'map' windows don't use winmaps
                    undef,                      # Use default package name, GA::Win::Map
                    undef,                      # No windows exists yet
                    undef,                      # Ditto
                    $self->session,             # Owner is the GA::Session, not this object
                    $self->session,             # Must be a session
                    $self->session->mainWin->workspaceObj->findWorkspaceGrid($self->session),
                                                # Session's workspace grid object
                );
            }

            # If neither form of window can be opened, only then show an error
            if (! $winObj) {

                return $self->writeError(
                    'Could not open the Automapper window',
                    $self->_objClass . '->openWin',
                );
            }

            # Update IVs (for both 'grid' windows and pseudo-windows)
            $self->ivPoke('mapWin', $winObj);
            $winObj->set_mapObj($self);

            # If this object's current room set, tell the Automapper window to draw that room's
            #   region and level now
            if ($self->currentRoom) {

                $regionObj = $self->worldModelObj->ivShow('modelHash', $self->currentRoom->parent);
                if ($regionObj) {

                    $winObj->setCurrentRegion(
                        $regionObj->name,
                        TRUE,               # Set the correct current level at the same time
                    );
                }

                # Also switch to 'follow' mode, so that the automapper continues to track the
                #   character's location
                $winObj->setMode('follow');
            }
        }

        return 1;
    }

    sub setCurrentRoom {

        # Can be called by anything
        # Sets the current location (a room object in the current world model)
        # If the automapper is open, redraws both the old current location (if there is one), and
        #   the new one
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $newRoomObj - The new current room (a GA::ModelObj::Room object). If 'undef', there is
        #                   no current room
        #   $lostFunc   - If defined, this automapper object is now 'lost' and $self->lastKnownRoom
        #                   needs to be set. $lostFunc is a string describing the calling function
        #                   (which is therefore available for debugging purposes, if necessary).
        #                   Otherwise set to 'undef'
        #
        # Return values
        #   'undef' on improper arguments, if a world model room object matching $newRoomNum
        #       doesn't exist, or if it isn't a room object
        #   1 otherwise

        my ($self, $newRoomObj, $lostFunc, $check) = @_;

        # Local variables
        my (
            $currentRoomFlag, $taskObj, $dictObj, $oldRoomObj, $text, $moveCount, $regionObj,
            $switchFlag, $anchorLine,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setCurrentRoom', @_);
        }

        # If the Automapper window's menu bar is open, we get a long stream of Gtk2 errors, so make
        #   sure it's closed
        if ($self->mapWin) {

            $self->mapWin->menuBar->deactivate();
        }

        # Import the Locator task (if it is running) and the session's current dictionary
        $taskObj = $self->session->locatorTask;
        $dictObj = $self->session->currentDict;

        # If there was a previous current location (or a room marked as the last known location),
        #   remember which one it is...
        if ($self->currentRoom) {

            $oldRoomObj = $self->currentRoom;
            $currentRoomFlag = TRUE;

        } elsif ($self->lastKnownRoom) {

            $oldRoomObj = $self->lastKnownRoom;
        }

        # ...before setting the new current location
        if ($newRoomObj) {

            $self->ivPoke('currentRoom', $newRoomObj);

            # In 'connect offline' mode, display a pseudo-room statement using details stored in the
            #   new current room (but only if $self->currentRoom was not already set, because in
            #   that case, the pseudo-room statement will have already been displayed by
            #   $self->pseudoWorldCmd)
            if (! $currentRoomFlag && $self->session->status eq 'offline') {

                $anchorLine = $self->showPseudoStatement($dictObj, $newRoomObj);
                if (! defined $anchorLine) {

                    # Could not produce a pseudo-room statement because no room statement components
                    #   of the statement type specified by $self->pseudoStatementMode are available.
                    # In this unlikely situation, mark the character as lost. Call this function
                    #   recursively, to make things easier
                    return $self->setCurrentRoom(undef, $self->_objClass . '->setCurrentRoom');
                }

                # The Locator task normally creates a non-model room when it spots a room statement.
                #   Instruct it create a non-model room based on $newRoomObj, and tell it to not
                #   look for room statements in the text just displayed by the call to
                #   ->showPseudoStatement
                $taskObj->usePseudoStatement($dictObj, $newRoomObj, $anchorLine);
            }

            # We don't need the last known location, if we are not lost
            if ($self->lastKnownRoom) {

                $self->ivUndef('lastKnownRoom');
            }

            # Also set the ghost room, whenever the current room is set (but only if the Automapper
            #   window is open, or if $self->trackAloneFlag is not set)
            # v1.0.285 Tweaked so that the ghost room isn't reset (i.e. to 'undef') if the IF
            #   condition is false, which occasionally causes the automapper to get lost when moving
            #   in non-primary/non-secondary directions
            if (
                $taskObj
                && ! $taskObj->moveList
                && ($self->mapWin || $self->trackAloneFlag)
            ) {
                $self->setGhostRoom($newRoomObj);
#           } else {
#               $self->setGhostRoom();
            }

        } else {

            $self->ivUndef('currentRoom');
            $self->setGhostRoom();                      # No ghost room
            $self->ivPoke('trackAloneFlag', FALSE);     # Stop 'track alone' mode, if it was on

            if ($lostFunc) {

                # The automapper object is lost
                $self->ivPoke('lastKnownRoom', $oldRoomObj);

                # We can save the user the bother of having to reset the Locator task, before
                #   setting a new current room, by resetting the list of room statements the task
                #   is expecting
                $taskObj->resetMoveList();

                # Display a warning in the 'main' window...
                $moveCount = $taskObj->ivNumber('moveList');
                $text = 'MAP: Automapper has lost track of the current location';
                if ($taskObj && $moveCount) {

                    $text .= ' (Locator task still expecting ';

                    if ($moveCount == 1) {
                        $text .= '1 more room statement)';
                    } else {
                        $text .= $moveCount . ' more room statements)';
                    }
                }

                $self->session->writeText($text);

                # ...and play a sound effect, if sound is turned on
                $axmud::CLIENT->playSound('lost');

                # If the Automapper window is open...
                if ($self->mapWin) {

                    # If the Automapper window is not in 'wait' mode, the mode must be changed to
                    #   'wait' mode ('update' mode would allow invalid changes to be written to the
                    #   map, and 'follow' mode is confusing for the user if it's allowed to remain
                    #   in place after getting lost)
                    if ($self->mapWin->mode ne 'wait') {

                        $self->mapWin->setMode('wait');
                    }

                    # Reset the window's title bar (in case it's showing the number of rooms the
                    #   Locator was expecting)
                    $self->mapWin->setWinTitle();
                }

            } else {

                # The last known location must be explicitly reset
                $self->ivUndef('lastKnownRoom');
            }
        }

        # If the Automapper window is open and the new current location isn't in the current
        #   regionmap, on the current level, then change one or both
        if ($self->mapWin && $newRoomObj) {

            # Is the new room in the current region?
            if (
                ! $self->mapWin->currentRegionmap
                || $self->mapWin->currentRegionmap->number != $newRoomObj->parent
            ) {
                # Switch region
                $regionObj = $self->worldModelObj->ivShow('modelHash', $newRoomObj->parent);
                $self->mapWin->setCurrentRegion(
                    $regionObj->name,
                    TRUE,               # Set the correct current level at the same time
                );

                $switchFlag = TRUE;

            } elsif ($self->mapWin->currentRegionmap->currentLevel ne $newRoomObj->zPosBlocks) {

                # Switch level
                $self->mapWin->setCurrentLevel($newRoomObj->zPosBlocks);
            }
        }

        # If the character previously moved through a 'temp_region' random exit into a temporary
        #   region, check that this new room is in the same region
        if (
            $self->currentRoom
            && $self->tempRandomDestRoom
            && $self->tempRandomDestRoom->parent != $self->currentRoom->parent
        ) {
            # Delete the temporary region, which is no longer required
            $self->worldModelObj->deleteRegions(
                $self->session,
                FALSE,               # Don't update automapper yet
                $self->worldModelObj->ivShow('modelHash', $self->tempRandomDestRoom->parent),
            );

            # Reset IVs
            $self->ivUndef('tempRandomOriginRoom');
            $self->ivUndef('tempRandomDestRoom');
            $self->ivUndef('tempRandomMode');
        }

        # If the Automapper window is open, redraw the previous current location (if there was one)
        #   and the new current location (if there is one), both at the same time if possible
        #   - unless the current region/level has changed, in which case they've already been
        #   re-drawn
        if (! $switchFlag && $self->mapWin) {

            # Final check that neither room has been deleted in the last few microseconds (we think
            #   this code can make a deleted room re-appear on the map, but we're not sure)
            if ($oldRoomObj && ! $self->worldModelObj->ivExists('modelHash', $oldRoomObj->number)) {

                $oldRoomObj = undef;
            }

            if ($newRoomObj && ! $self->worldModelObj->ivExists('modelHash', $newRoomObj->number)) {

                $newRoomObj = undef;
            }

            if ($oldRoomObj && $newRoomObj) {

                # Draw both rooms together
                $self->mapWin->doDraw(
                    'room', $oldRoomObj,
                    'room', $newRoomObj,
                );

            } elsif ($oldRoomObj) {

                # Redraw the old room
                $self->mapWin->doDraw('room', $oldRoomObj);

            } elsif ($newRoomObj) {

                # Redraw the new room
                $self->mapWin->doDraw('room', $newRoomObj);
            }
        }

        # If the Automapper window is not open, enable 'track alone' mode
        if (! $self->mapWin) {

            $self->ivPoke('trackAloneFlag', TRUE);
        }

        # Update the Locator task, if it's running
        $self->updateLocator();

        # If the Automapper window is open...
        if ($self->mapWin) {

            # In tracking mode, need to check the current location's position within the visible
            #   map, and move the scrollbars, if necessary
            $self->mapWin->trackPosn();

            # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
            $self->mapWin->restrictWidgets();
        }

        return 1;
    }

    sub setLastKnownRoom {

        # Can be called by anything
        # Sets the last known room - the last known location before the automapper got lost
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $newRoomObj - The new last known room (a GA::ModelObj::Room object). If 'undef', there
        #                   is no last known room
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $newRoomObj, $check) = @_;

        # Local variables
        my $oldRoomObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setLastKnownRoom', @_);
        }

        $self->ivPoke('lastKnownRoom', $newRoomObj);  # Now set to 'undef' if there is no ghost room

        return 1;
    }

    sub setGhostRoom {

        # Can be called by anything. Not called by ->setCurrentRoom if the room has just been set as
        #   the current room
        # Sets the ghost room - the presumed actual location of the character when a movement
        #   command is typed, and redraws both the old ghost room (if there is one), and the new one
        # NB If the Automapper window is open and in 'wait mode', or if the window isn't open and
        #   $self->trackAloneFlag isn't set, the ghost room is reset, regardless of any arguments
        #   passed to this function (because we don't want the ghost room visibly moving around the
        #   map, when the user has clicked the 'wait' mode button)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $newRoomObj - The new ghost room (a GA::ModelObj::Room object). If 'undef', there is
        #                   no ghost room
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $newRoomObj, $check) = @_;

        # Local variables
        my $oldRoomObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setGhostRoom', @_);
        }

        # If there was a previous ghost room, remember which one it is...
        if ($self->ghostRoom) {

            $oldRoomObj = $self->ghostRoom;
        }

        # Special case: if not following or updating the map, reset the ghost room
        if (
            ($self->mapWin && $self->mapWin->mode eq 'wait')
            || (! $self->mapWin && ! $self->trackAloneFlag)
        ) {
            $self->ivUndef('ghostRoom');

        } else {

            # Otherwise, set the new ghost room (if any)
            $self->ivPoke('ghostRoom', $newRoomObj);   # Now set to 'undef' if no ghost room
        }

        # If the Automapper window is open, redraw the old ghost room (if there was one) and the new
        #   ghost room (if there is one), both at the same time if possible
        # If either room isn't in the current regionmap, on the current level, then we don't need to
        #   redraw it
        if ($self->mapWin && $self->mapWin->currentRegionmap) {

            if ($oldRoomObj) {

                if (
                    ($oldRoomObj->parent != $self->mapWin->currentRegionmap->number)
                    || ($oldRoomObj->zPosBlocks != $self->mapWin->currentRegionmap->currentLevel)
                ) {
                    $oldRoomObj = undef;   # Don't redraw it
                }
            }

            if ($newRoomObj) {

                if (
                    ($newRoomObj->parent != $self->mapWin->currentRegionmap->number)
                    || ($newRoomObj->zPosBlocks != $self->mapWin->currentRegionmap->currentLevel)
                ) {
                    $newRoomObj = undef;   # Don't redraw it
                }
            }

            # Final check that neither room has been deleted in the last few microseconds (we think
            #   this code can make a deleted room re-appear on the map, but we're not sure)
            if ($oldRoomObj && ! $self->worldModelObj->ivExists('modelHash', $oldRoomObj->number)) {

                $oldRoomObj = undef;
            }

            if ($newRoomObj && ! $self->worldModelObj->ivExists('modelHash', $newRoomObj->number)) {

                $newRoomObj = undef;
            }

            if ($oldRoomObj && $newRoomObj) {

                # Draw both rooms together
                $self->mapWin->doDraw(
                    'room', $oldRoomObj,
                    'room', $newRoomObj,
                );

            } elsif ($oldRoomObj) {

                # Redraw the old room
                $self->mapWin->doDraw('room', $oldRoomObj);

            } elsif ($newRoomObj) {

                # Redraw the new room
                $self->mapWin->doDraw('room', $newRoomObj);
            }
        }

        return 1;
    }

    sub updateLocator {

        # Can be called by anything, including many GA::Win::Map functions
        # Updates the Locator task (if it is running) with this object's current location
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $taskObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateLocator', @_);
        }

        $taskObj = $self->session->locatorTask;
        if ($taskObj) {

            # Tell the Locator which world model room is current
            if ($self->currentRoom) {

                $taskObj->set_modelNumber($self->currentRoom->number);

                # Copy the room tag into the Locator's non-model room, if there is a room tag (and
                #   if the Locator has a non-model room)
                if ($taskObj->roomObj) {

                    if ($self->currentRoom->roomTag) {

                        $taskObj->roomObj->ivPoke('roomTag', $self->currentRoom->roomTag);

                    } else {

                        # The non-model room's room tag must be reset
                        $taskObj->roomObj->ivUndef('roomTag');
                    }
                }

            } else {

                $taskObj->set_modelNumber();
                if ($taskObj->roomObj) {

                    # The room tag of the non-model room must be reset
                    $taskObj->roomObj->ivUndef('roomTag');
                }
            }

            # Refresh the Locator task's window to display the changes
            $taskObj->refreshWin();
        }

        return 1;
    }

    # Locator task functions

    sub moveKnownDirSeen {

        # Called by GA::Task::Locator->processLine->main (at stage 3) when the character moves in
        #   a known direction
        #
        # Expected arguments
        #   $cmdObj     - The GA::Buffer::Cmd object that stores the movement command
        #
        # Return values
        #   'undef' on improper arguments, if no changes are made to $self->currentRoom or if
        #       a called function return 'undef'
        #   1 otherwise

        my ($self, $cmdObj, $check) = @_;

        # Local variables
        my (
            $dictObj, $parentRegion, $regionmapObj, $dir, $exitObj, $standardDir, $mapDir,
            $customDir, $dirType, $primaryFlag, $exitNum, $destRoomObj, $vectorRef, $exitLength,
            $xPosBlocks, $yPosBlocks, $zPosBlocks, $number, $existRoomObj, $oppExitObj,
            $destWildMode,
        );

        # Check for improper arguments
        if (! defined $cmdObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->moveKnownDirSeen', @_);
        }

        # Import the current dictionary (for convenience)
        $dictObj = $self->session->currentDict;

        # PART 1    - basic checks
        #
        # Do nothing if:
        #   1. The Automapper window is open and is in 'wait' mode
        #   2. The Automapper window isn't open, and $self->trackAloneFlag is FALSE
        #   3. The current room isn't known (regardless of whether the Automapper window is open)
        if (
            ($self->mapWin && $self->mapWin->mode eq 'wait')
            || (! $self->mapWin && ! $self->trackAloneFlag)
            || ! $self->currentRoom
        ) {
            return undef;
        }

        # PART 2    - return from temporary regions
        #
        # If the character moved through a 'temp_region' random exit, check the Locator task's
        #   current room. If it matches the random exit's parent room, then there's no need to worry
        #   about updating the map; just move the player back to the original room and destroy the
        #   temporary region
        if ($self->checkTempRandomReturn()) {

            return 1;
        }

        # PART 3    - get current room's region
        #
        # Get the current room's parent region and, from there, the regionmap
        $parentRegion = $self->worldModelObj->ivShow('modelHash', $self->currentRoom->parent);
        if ($parentRegion) {

            $regionmapObj = $self->worldModelObj->ivShow('regionmapHash', $parentRegion->name);
        }

        if (! $regionmapObj) {

            # The current room doesn't appear to be in a region - so nothing we can do
            if ($self->worldModelObj->explainGetLostFlag) {

                $self->session->writeText(
                    'MAP: Lost due to internal error (cannot find regionmap)',
                );
            }

            # The presence of a second argument means 'the character is lost'
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->moveKnownDirSeen',    # Character now lost
            );
        }

        # PART 4    - get direction of movement
        #
        # Set $dir, the direction of movement, so that we can work out which exit object is being
        #   used. For assisted moves, we already know the exit object used (which will save us some
        #   time)
        if ($cmdObj->assistedFlag) {

            $dir = $cmdObj->cmd;
            $exitObj = $cmdObj->assistedExitObj;

        # For redirect mode commands, use the original command, which should contain only a
        #   direction
        } elsif ($cmdObj->redirectFlag) {

            $dir = $cmdObj->cmd;

        # For normal movement commands, the direction of movement has been stripped from
        #   $cmdObj->cmd and stored in ->moveDir
        } else {

            $dir = $cmdObj->moveDir;
        }

        # PART 5    - identify an exit object (GA::Obj::Exit) matching the direction
        #
        #   $dir can be any of the following:
        #   (i) The original command used in an assisted move
        #           - $standardDir, $mapDir and $customDir are set directly from the buffer object
        #               (but $customDir is only set if it's a primary direction)
        #
        #   (ii) A custom primary direction - one of the values in GA::Obj::Dict->primaryDirHash
        #           (e.g. 'nord', sud') or ->primaryAbbrevHash (e.g. 'n', 's')
        #           - $standardDir/$mapDir are set to the equivalent key (the words 'north', 'up'
        #               etc)
        #           - $customDir is set to the value of the key in ->primaryDirHash (so that if $dir
        #               is 'n', $customDir gets set to the unabbreviated custom direction 'nord')
        #           - If $dir is abbreviated, it is unabbreviated (so its value is the same as
        #               $customDir)
        #
        #   (iii) A recognised secondary direction - one of the values in
        #           GA::Obj::Dict->secondaryDirHash (e.g. 'out') or ->secondaryAbbrevHash
        #               (e.g. 'o')
        #           - $standardDir is set to the equivalent key (the words 'in', 'entrance',
        #               'portal' etc)
        #           - $mapDir / $customDir are not set (the key's corresponding value is always
        #               equal to $dir)
        #           - If $dir is abbreviated, it is unabbreviated (so its value is the same as
        #               $standardDir)
        #
        #   (iv) A direction not stored in the dictionary, such as 'enter well'
        #           - Neither $standardDir nor $customDir are set

        if ($cmdObj->assistedFlag) {

            # (i) The original command used in an assisted move
            $standardDir = $cmdObj->assistedPrimary;
            $mapDir = $cmdObj->assistedPrimary;
            $customDir = $cmdObj->assistedExitObj->dir;
            if (! $dictObj->checkPrimaryDir($customDir)) {

                $customDir = undef;     # Not a primary direction, so we don't need it here
            }

        } else {

            # If $dir is a custom primary or secondary direction...
            if ($dictObj->ivExists('combDirHash', $dir)) {

                # Get the custom direction's type (one of the values 'primaryDir', 'primaryAbbrev',
                #   'secondaryDir' or 'secondaryAbbrev'), which partially matches the name of the
                #   hash IV which stores that type of direction
                $dirType = $dictObj->ivShow('combDirHash', $dir);
                $standardDir = $dictObj->ivShow('combRevDirHash', $dir);

                # (ii) Customised primary direction
                if ($dirType eq 'primaryDir' || $dirType eq 'primaryAbbrev') {

                    $mapDir = $standardDir;
                    $customDir = $dictObj->ivShow('primaryDirHash', $standardDir);
                    # Make sure $dir isn't the abbreviated version of the direction
                    $dir = $customDir;
                    # For the benefit of basic mapping mode, set a flag
                    $primaryFlag = TRUE;

                # (iii) Recognised secondary direction
                } elsif ($dirType eq 'secondaryDir' || $dirType eq 'secondaryAbbrev') {

                    # Make sure $dir isn't the abbreviated version of the direction
                    $dir = $dictObj->ivShow('secondaryDirHash', $standardDir);
                }
            }

            # Check the current room's exits. Does an exit in this direction already exist?
            if ($self->currentRoom->ivExists('exitNumHash', $dir)) {

                $exitNum = $self->currentRoom->ivShow('exitNumHash', $dir);
                $exitObj = $self->worldModelObj->ivShow('exitModelHash', $exitNum);

            # Otherwise, if $dir is a primary direction, see if an existing exit from the current
            #   room has the same drawn map direction
            } elsif ($standardDir && $customDir) {

                OUTER: foreach my $number ($self->currentRoom->ivValues('exitNumHash')) {

                    my $otherExitObj = $self->worldModelObj->ivShow('exitModelHash', $number);

                    if (
                        $otherExitObj->mapDir
                        && $otherExitObj->mapDir eq $customDir
                        # (Don't leave using an exit attached to a shadow exit; leave via the shadow
                        #   exit instead)
                        && (! $otherExitObj->shadowExit)
                    ) {
                        $exitObj = $otherExitObj;
                        last OUTER;
                    }
                }
            }
        }

        # PART 6   - In crafty moves mode, if an exit matching the direction $dir doesn't exist,
        #               create a hidden exit right now (even if the world itself doesn't include the
        #               exit in its exit lists - I'm looking at you, Discworld!)
        if (
            ! $exitObj
            && $self->mapWin
            && $self->mapWin->mode eq 'update'
            && $self->worldModelObj->craftyMovesFlag
            && ! $self->worldModelObj->protectedMovesFlag
            # Don't do this when departing from wilderness rooms
            && $self->currentRoom->wildMode eq 'normal'
        ) {
            $exitObj = $self->worldModelObj->addExit(
                $self->session,
                FALSE,              # Don't update Automapper window yet
                $self->currentRoom,
                $dir,
                $mapDir,
            );

            if ($exitObj) {

                $self->worldModelObj->setHiddenExit(
                    FALSE,              # Don't update Automapper window yet
                    $exitObj,
                    TRUE,               # Hidden exit
                );
            }
        }

        # PART 7    - deal with impassable, random, unallocated and unallocated exits
        #
        # If the character is using an exit marked as impassable, then we're now lost
        if ($exitObj && $exitObj->exitOrnament eq 'impass') {

            # Show an explanation, if allowed
            if ($self->worldModelObj->explainGetLostFlag) {

                $self->session->writeText(
                    'MAP: Lost because the character used an exit marked as \'impassable\'',
                );
            }

            # The presence of a second argument means 'the character is lost'
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->moveKnownDirSeen',    # Defined string marks character as lost
            );

        # If the character is using a random exit...
        } elsif ($exitObj && $exitObj->randomType ne 'none') {

            # Either locate the new current location, or mark the character as lost (depending on
            #   the world model's IVs)
            return $self->reactRandomExit($exitObj);

        # If the character attemps to move through an unallocated exit, we are now lost
        } elsif ($exitObj && $exitObj->drawMode eq 'temp_alloc') {

            # Show an explanation, if allowed
            if ($self->worldModelObj->explainGetLostFlag) {

                $self->session->writeText(
                    'MAP: Lost because the character used an unallocated exit',
                );
            }

            # The presence of a second argument means 'the character is lost'
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->moveKnownDirSeen',    # Defined string marks character as lost
            );

        # If the character attempts to move through an unallocatable exit which doesn't have a
        #   destination room, we are now lost
        } elsif ($exitObj && $exitObj->drawMode eq 'temp_unalloc' && ! $exitObj->destRoom) {

            # Show an explanation, if allowed
            if ($self->worldModelObj->explainGetLostFlag) {

                $self->session->writeText(
                    'MAP: Lost because the character used an unallocatable exit which doesn\'t'
                    . ' have a destination room set',
                );
            }

            # The presence of a second argument means 'the character is lost'
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->moveKnownDirSeen',    # Defined string marks character as lost
            );
        }

        # PART 8    - deal with ordinary exits whose destination room is already set
        #
        # If an exit matching $dir exists, and it leads to a known room, we can use the room
        if ($exitObj && $exitObj->destRoom) {

            $destRoomObj = $self->worldModelObj->ivShow('modelHash', $exitObj->destRoom);
            if ($destRoomObj) {

                return $self->useExistingRoom(
                    $self->currentRoom,
                    $destRoomObj,
                    $dir,
                    $customDir,
                    $exitObj,
                );
            }
        }

        # PART 9    - check the location where we would expect a destination room to be placed for
        #               movement in the direction $dir, and see if a room exists there
        #
        # For primary directions, check the gridblock to which the exit is supposed to lead and see
        #   see if there's already a room at that location
        # (If the automapper window isn't open, we don't need this information)
        if ($self->mapWin) {

            if ($standardDir && $customDir) {

                # Work out the location's coordinates on the map
                $vectorRef = $self->mapWin->ivShow('constSpecialVectorHash', $standardDir);

                if ($standardDir eq 'up' || $standardDir eq 'down') {
                    $exitLength = $self->worldModelObj->verticalExitLengthBlocks;
                } else {
                    $exitLength = $self->worldModelObj->horizontalExitLengthBlocks;
                }

                $xPosBlocks = $self->currentRoom->xPosBlocks + ($$vectorRef[0] * $exitLength);
                $yPosBlocks = $self->currentRoom->yPosBlocks + ($$vectorRef[1] * $exitLength);
                $zPosBlocks = $self->currentRoom->zPosBlocks + ($$vectorRef[2] * $exitLength);

            # For non-primary directions for which the exit has been allocated a map direction
            #   (stored in ->mapDir), work out the gridblock to which the exit is supposed to lead
            } elsif ($exitObj && $exitObj->mapDir) {

                # Work out the location's coordinates on the map
                $vectorRef = $self->mapWin->ivShow('constSpecialVectorHash', $exitObj->mapDir);
                $exitLength = $self->worldModelObj->getExitLength($exitObj);
                $xPosBlocks = $self->currentRoom->xPosBlocks + ($$vectorRef[0] * $exitLength);
                $yPosBlocks = $self->currentRoom->yPosBlocks + ($$vectorRef[1] * $exitLength);
                $zPosBlocks = $self->currentRoom->zPosBlocks + ($$vectorRef[2] * $exitLength);
            }
        }

        if (defined $xPosBlocks) {

            # Check that location actually fits on the map
            if (! $regionmapObj->checkGridBlock($xPosBlocks, $yPosBlocks, $zPosBlocks)) {

                # The Automapper window can't draw rooms outside the map, so the character is now
                #   lost. Display an explanation, if allowed
                if ($self->worldModelObj->explainGetLostFlag) {

                    $self->session->writeText(
                        'MAP: Lost because new room\'s location is outside the region\'s'
                        . ' boundaries (after a move in a primary direction)',
                    );
                }

                # The presence of a second argument means 'the character is lost'
                return $self->setCurrentRoom(
                    undef,
                    $self->_objClass . '->moveKnownDirSeen',    # Character now lost
                );

            } else {

                # Otherwise, if there is a room at that location, we can use it
                $number = $regionmapObj->fetchRoom($xPosBlocks, $yPosBlocks, $zPosBlocks);
                if (defined $number) {

                    $existRoomObj = $self->worldModelObj->ivShow('modelHash', $number);
                }
            }
        }

        # PART 10   - deal with movement between rooms, when one (or both) rooms is in wilderness
        #               mode
        if ($existRoomObj) {

            # A room exists where we'd expect to find a destination room

            if (
                ($self->currentRoom->wildMode eq 'normal' && $existRoomObj->wildMode eq 'border')
                || ($self->currentRoom->wildMode eq 'border' && $existRoomObj->wildMode eq 'normal')
            ) {
                # Between 'normal' and 'border' rooms (in either direction), when the automapper
                #   exists and is in 'update' mode, create an exit if one doesn't already exist
                if (
                    ! $exitObj
                    && $self->mapWin
                    && $self->mapWin->mode eq 'update'
                    && $primaryFlag
                ) {
                    $exitObj = $self->worldModelObj->addExit(
                        $self->session,
                        FALSE,              # Don't update Automapper window yet
                        $self->currentRoom,
                        $dir,
                        $mapDir,
                    );
                }

                if (! $exitObj) {

                    # Between 'normal' and 'border' rooms, an exit object is required, so the
                    #   character is now lost. Display an explanation, if allowed
                    if ($self->worldModelObj->explainGetLostFlag) {

                        $self->session->writeText(
                            'MAP: Lost because no exit object exists between a normal room and a'
                            . ' wilderness border room',
                        );
                    }

                    # The presence of a second argument means 'the character is lost'
                    return $self->setCurrentRoom(
                        undef,
                        $self->_objClass . '->moveKnownDirSeen',    # Character now lost
                    );
                }

                # If an exit from the destination room in the opposite direction already exists,
                #   find it
                OUTER: foreach my $number ($existRoomObj->ivValues('exitNumHash')) {

                    my $otherExitObj = $self->worldModelObj->ivShow('exitModelHash', $number);

                    if (
                        $otherExitObj->mapDir
                        && $otherExitObj->mapDir eq $dictObj->ivShow('primaryOppHash', $mapDir)
                        # (Don't leave using an exit attached to a shadow exit; leave via the shadow
                        #   exit instead)
                        && (! $otherExitObj->shadowExit)
                    ) {
                        $oppExitObj = $otherExitObj;
                        last OUTER;
                    }
                }

                # Otherwise, if ->autocompleteExitsFlag is set, create an exit in the opposite
                #   direction and make them two-way exits
                if (! $oppExitObj && $self->worldModelObj->autocompleteExitsFlag) {

                    # Create an opposite exit from the destination room, pointing back to the
                    #   current room
                    $oppExitObj = $self->worldModelObj->addExit(
                        $self->session,
                        FALSE,                  # Don't update Automapper window yet
                        $existRoomObj,
                        $dictObj->ivShow('primaryOppHash', $mapDir),
                        $axmud::CLIENT->ivShow('constOppDirHash', $mapDir),
                    );
                }

                # Mark the exit from the 'normal' room leading to the 'border' room as a hidden exit
                #   (it may or may not be hidden in the room statement, depending on the world;
                #   marking it hidden takes care of both situations)
                if ($self->currentRoom->wildMode eq 'normal') {

                    $self->worldModelObj->setHiddenExit(
                        FALSE,              # Don't update Automapper window yet
                        $exitObj,
                        TRUE,               # Hidden exit
                    );

                } elsif ($existRoomObj->wildMode eq 'normal' && $oppExitObj) {

                    $self->worldModelObj->setHiddenExit(
                        FALSE,              # Don't update Automapper window yet
                        $oppExitObj,
                        TRUE,               # Hidden exit
                    );
                }

                # Use the existing room as the destination room
                return $self->useExistingRoom(
                    $self->currentRoom,
                    $existRoomObj,
                    $dir,
                    $customDir,
                    $exitObj,
                );

            } elsif (
                $self->currentRoom->wildMode ne 'normal'
                && $existRoomObj->wildMode ne 'normal'
            ) {
                # Between 'border' and 'wild' rooms (in either direction), use the existing room as
                #   the destination room
                return $self->useExistingRoom(
                    $self->currentRoom,
                    $existRoomObj,
                    $dir,
                    $customDir,
                    undef,              # No exit is drawn between 'wild' and 'border' rooms
                );
            }

        } elsif (! $existRoomObj && $self->mapWin && $self->mapWin->mode eq 'update') {

            # No room exists where we'd expect to find a destination room, but the automapper window
            #   is open and in 'update' mode, so we can create one

            # Set the wilderness mode for the new destination room. If the painter is enabled, use
            #   the mode it specifies; otherwise use the default mode
            if ($self->mapWin->painterFlag) {
                $destWildMode = $self->worldModelObj->painterObj->wildMode;
            } else {
                $destWildMode = 'normal';
            }

            if (
                ($self->currentRoom->wildMode eq 'normal' && $destWildMode eq 'border')
                || ($self->currentRoom->wildMode eq 'border' && $destWildMode eq 'normal')
            ) {
                # Between 'normal' and 'border' rooms (in either direction), create an exit
                #   departing from the current room, if one doesn't already exist
                if (! $exitObj && $primaryFlag) {

                    $exitObj = $self->worldModelObj->addExit(
                        $self->session,
                        FALSE,              # Don't update Automapper window yet
                        $self->currentRoom,
                        $dir,
                        $mapDir,
                    );
                }

                if (! $exitObj) {

                    # Between 'normal' and 'border' rooms, an exit object is required, so the
                    #   character is now lost. Display an explanation, if allowed
                    if ($self->worldModelObj->explainGetLostFlag) {

                        $self->session->writeText(
                            'MAP: Lost because no exit object exists between a normal and a'
                            . ' wilderness border room',
                        );
                    }

                    # The presence of a second argument means 'the character is lost'
                    return $self->setCurrentRoom(
                        undef,
                        $self->_objClass . '->moveKnownDirSeen',    # Character now lost
                    );
                }

                # Create a destination room at the specified location, but don't give it the
                #   properties of the Locator task's current room and don't update the map yet
                # NB Call ->createNewRoom directly, rather than calling it indirectly via a call to
                #   $self->autoProcessNewRoom; in this situation, we're not concerned about the
                #   special cases that ->autoProcessNewRoom handles. Also, a call to
                #   ->autoProcessNewRoom will cause a one-way exit to be drawn on the map window,
                #   then quickly redrawn as a two-way exit, which is very annoying
                $destRoomObj = $self->createNewRoom(
                    $regionmapObj,          # Use the same region as the current room
                    $xPosBlocks,            # Co-ordinates of room on the region's grid
                    $yPosBlocks,
                    $zPosBlocks,
                    undef,                  # Don't change GA::Win::Map->mode
                    FALSE,                  # New room is not current room (yet)
                    FALSE,                  # New room doesn't take properties from Locator (yet)
                    FALSE,                  # Don't update Automapper windows now
                );

                if (! $destRoomObj) {

                    if ($self->worldModelObj->explainGetLostFlag) {

                        $self->session->writeText(
                            'MAP: Lost due to internal error (cannot create new room)',
                        );
                    }

                    # The presence of a second argument means 'the character is lost'
                    return $self->setCurrentRoom(
                        undef,
                        $self->_objClass . '->moveKnownDirSeen',    # Character now lost
                    );

                    return undef;
                }

                # Set the destination room's ->wildMode...
                $destRoomObj->ivPoke('wildMode', $destWildMode);
                # ...and now we can update its properties from the Locator task's current room,
                #   because the exits are no longer copied
                $self->worldModelObj->updateRoom(
                    $self->session,
                    FALSE,                  # Don't update Automapper windows now
                    $destRoomObj,
                );

                # If ->autocompleteExitsFlag is set, create an exit in the opposite direction and
                #   make them two-way exits
                if ($self->worldModelObj->autocompleteExitsFlag) {

                    # Create an opposite exit from the destination room, pointing back to the
                    #   current room
                    $oppExitObj = $self->worldModelObj->addExit(
                        $self->session,
                        FALSE,                  # Don't update Automapper window yet
                        $destRoomObj,
                        $dictObj->ivShow('primaryOppHash', $mapDir),
                        $axmud::CLIENT->ivShow('constOppDirHash', $mapDir),
                    );

                    if (! $oppExitObj) {

                        if ($self->worldModelObj->explainGetLostFlag) {

                            $self->session->writeText(
                                'MAP: Lost due to internal error (cannot create new exit)',
                            );
                        }

                        # The presence of a second argument means 'the character is lost'
                        return $self->setCurrentRoom(
                            undef,
                            $self->_objClass . '->moveKnownDirSeen',    # Character now lost
                        );

                        return undef;
                    }
                }

                # Use the destination room as the new current room, connecting the two rooms
                #   together (with a one-way or two-way exit, as appropriate)
                return $self->useExistingRoom(
                    $self->currentRoom,
                    $destRoomObj,
                    $dir,
                    $customDir,
                    $exitObj,
                );

            } elsif ($self->currentRoom->wildMode ne 'normal' && $destWildMode ne 'normal') {

                # Between 'border' and 'wild' rooms (in either direction), create a new room with
                #   no exits
                $destRoomObj = $self->createNewRoom(
                    $regionmapObj,          # Use the same region as the current room
                    $xPosBlocks,            # Co-ordinates of room on the region's grid
                    $yPosBlocks,
                    $zPosBlocks,
                    undef,                  # Don't change GA::Win::Map->mode
                    FALSE,                  # New room is not current room (yet)
                    FALSE,                  # New room doesn't take properties from Locator (yet)
                    FALSE,                  # Don't update Automapper windows now
                );

                # Set the destination room's ->wildMode...
                $destRoomObj->ivPoke('wildMode', $destWildMode);
                # ...and now we can update its properties from the Locator task's current room,
                #   because the exits are no longer copied
                $self->worldModelObj->updateRoom(
                    $self->session,
                    FALSE,                  # Don't update Automapper windows now
                    $destRoomObj,
                );

                # Use the destination room as the new current room without connecting the two rooms
                #   together
                return $self->useExistingRoom(
                    $self->currentRoom,
                    $destRoomObj,
                    $dir,
                    $customDir,
                    undef,                  # Definitely no exit object
                );
            }
        }

        # PART 11   - in basic mapping mode and when the character is following someone/something,
        #               we can create an exit right now, if one doesn't already exist (assuming
        #               that the automapper window is open and in 'update' mode)
        #
        # In Basic mapping mode - for worlds in which room statements don't include a list of exits
        #   - if the character moves in a primary direction, we must create a new exit in that
        #   direction
        # This also applies if the room statement was a follow anchor pattern, caused by the
        #   character following someone to a new room, and no new room statement is expected
        #   (but only if the world model flag permits it)
        if (
            ! $exitObj
            && $self->mapWin
            && $self->mapWin->mode eq 'update'
            && $primaryFlag
            && (
                $self->session->currentWorld->basicMappingFlag
                || ($cmdObj->followAnchorFlag && $self->worldModelObj->followAnchorFlag)
            )
        ) {
            $exitObj = $self->worldModelObj->addExit(
                $self->session,
                FALSE,              # Don't update Automapper window yet
                $self->currentRoom,
                $dir,
                $mapDir,
            );

            # If the destination room is about to be created, this new exit will be one-way. If
            #   ->autocompleteExitsFlag is set, it's nicer to create a two-way exit
            if ($self->worldModelObj->autocompleteExitsFlag) {

                # Create a destination room at the specified location and give it the properties of
                #   the Locator task's current room, but don't update the map yet
                # NB Call ->createNewRoom directly, rather than calling it indirectly via a call to
                #   $self->autoProcessNewRoom; in this situation, we're not concerned about the
                #   special cases that ->autoProcessNewRoom handles. Also, a call to
                #   ->autoProcessNewRoom will cause a one-way exit to be drawn on the map window,
                #   then quickly redrawn as a two-way exit, which is very annoying
                $destRoomObj = $self->createNewRoom(
                    $regionmapObj,          # Use the same region as the current room
                    $xPosBlocks,            # Co-ordinates of room on the region's grid
                    $yPosBlocks,
                    $zPosBlocks,
                    undef,                  # Don't change GA:Map::Win->mode
                    FALSE,                  # New room is not current room (yet)
                    TRUE,                   # New room takes properties from Locator
                    FALSE,                  # Don't update Automapper windows now
                );

                if (! $destRoomObj) {

                    if ($self->worldModelObj->explainGetLostFlag) {

                        $self->session->writeText(
                            'MAP: Lost due to internal error (cannot create new room)',
                        );
                    }

                    # The presence of a second argument means 'the character is lost'
                    return $self->setCurrentRoom(
                        undef,
                        $self->_objClass . '->moveKnownDirSeen',    # Character now lost
                    );
                }

                # Create an opposite exit from the destination room, pointing back to the
                #   current room
                $oppExitObj = $self->worldModelObj->addExit(
                    $self->session,
                    FALSE,                  # Don't update Automapper window yet
                    $destRoomObj,
                    $dictObj->ivShow('primaryOppHash', $mapDir),
                    $axmud::CLIENT->ivShow('constOppDirHash', $mapDir),
                );

                if (! $oppExitObj) {

                    if ($self->worldModelObj->explainGetLostFlag) {

                        $self->session->writeText(
                            'MAP: Lost due to internal error (cannot create new exit)',
                        );
                    }

                    # The presence of a second argument means 'the character is lost'
                    return $self->setCurrentRoom(
                        undef,
                        $self->_objClass . '->moveKnownDirSeen',    # Character now lost
                    );

                } else {

                    # Connect the two rooms together, creating a two-way exit between them, and
                    #   make the destination room the new current room
                    return $self->useExistingRoom(
                        $self->currentRoom,
                        $destRoomObj,
                        $dir,
                        $customDir,
                        $exitObj,
                    );
                }
            }
        }

        # PART 12   - if we identified a possible destination room in PART 7, we can use it
        if ($existRoomObj) {

            # Use it
            return $self->useExistingRoom(
                $self->currentRoom,
                $existRoomObj,
                $dir,
                $customDir,
                $exitObj,
            );
        }

        # PART 13   - no possible destination room exists; either create a new room, or mark the
        #               character as being lost
        if (! $self->mapWin) {

            # New rooms can't be created when the Automapper window isn't open, so the character is
            #   now lost. Display an explanation, if allowed
            if ($self->worldModelObj->explainGetLostFlag) {

                $self->session->writeText(
                    'MAP: Lost because new rooms can\'t be added to the world model when the'
                    . ' Automapper window isn\'t open',
                );
            }

            # The presence of a second argument means 'the character is lost'
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->moveKnownDirSeen',    # Character now lost
            );

        } elsif (! $exitObj) {

            # Can't connect a departure room to an arrival room, if we don't know which exit is
            #   being used - it may be the result of a world command like 'move box', which has been
            #   interpreted (incorrectly) as a movement command. The character is now lost
            #   lost
            if ($self->worldModelObj->explainGetLostFlag) {

                $self->session->writeText(
                    'MAP: Lost because of a departure in an unknown direction',
                );
            }

            # The presence of a second argument means 'the character is lost'
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->moveKnownDirSeen',    # Character now lost
            );

        } elsif ($self->mapWin->mode eq 'follow') {

            # The automapper can't create new rooms in 'follow' mode, so the character is now lost.
            #   Display an explanation, if allowed
            if ($self->worldModelObj->explainGetLostFlag) {

                $self->session->writeText(
                    'MAP: Lost because the Automapper window can\'t create new rooms in'
                    . ' \'follow\' mode',
                );
            }

            # The presence of a second argument means 'the character is lost'
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->moveKnownDirSeen',    # Character now lost
            );

        } elsif ($self->mapWin->mode eq 'update') {

            # Not in basic mapping mode and the character is not following someone/something
            # Check that we can create a new room and, if so, create it
            if (
                ! $self->autoProcessNewRoom(
                    $dir,
                    $regionmapObj,
                    $xPosBlocks,
                    $yPosBlocks,
                    $zPosBlocks,
                    $mapDir,
                    $customDir,
                    $exitObj,
                )
            ) {
                if ($self->worldModelObj->explainGetLostFlag) {

                    $self->session->writeText(
                        'MAP: Lost due to internal error (cannot process new room)',
                    );
                }

                # The presence of a second argument means 'the character is lost'
                return $self->setCurrentRoom(
                    undef,
                    $self->_objClass . '->moveKnownDirSeen',    # Character now lost
                );
            }
        }

        return 1;
    }

    sub moveUnknownDirSeen {

        # Called by GA::Task::Locator->processLine->main (at stage 3) when the character moves in
        #   an unknown direction
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no changes are made to $self->currentRoom
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->moveUnknownDirSeen', @_);
        }

        # Do nothing if:
        #   1. The Automapper window is open and is in 'wait' mode
        #   2. The Automapper window isn't open, and $self->trackAloneFlag is FALSE
        #   3. The current room isn't known (regardless of whether the Automapper window is open)
        if (
            ($self->mapWin && $self->mapWin->mode eq 'wait')
            || (! $self->mapWin && ! $self->trackAloneFlag)
            || ! $self->currentRoom
        ) {
            return undef;
        }

        # If the character moved through a 'temp_region' random exit, check the Locator task's
        #   current room. If it matches the random exit's parent room, then there's no need to worry
        #   about updating the map; just move the player back to the original room and destroy the
        #   temporary region
        if ($self->checkTempRandomReturn()) {

            return 1;
        }

        # Otherwise, we are now lost. Display an explanatory message, if necessary
        if ($self->worldModelObj->explainGetLostFlag) {

            $self->session->writeText('MAP: Lost after a move in an unknown direction');
        }

        return $self->setCurrentRoom(
            undef,
            $self->_objClass . '->moveUnknownDirSeen',    # Character now lost
        );

        return 1;
    }

    sub teleportSeen {

        # Called by GA::Task::Locator->processLine->main (at stage 3) when the character teleports
        #   to a known destination
        # This is a slimmed-down version of $self->moveKnownDirSeen
        #
        # Expected arguments
        #   $cmdObj     - The GA::Buffer::Cmd object that stores the movement command
        #
        # Return values
        #   'undef' on improper arguments or if no changes are made to $self->currentRoom
        #   1 otherwise

        my ($self, $cmdObj, $check) = @_;

        # Local variables
        my $destRoomObj;

        # Check for improper arguments
        if (! defined $cmdObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->teleportSeen', @_);
        }

        # Do nothing if:
        #   1. The Automapper window is open and is in 'wait' mode
        #   2. The Automapper window isn't open, and $self->trackAloneFlag is FALSE
        #   3. The current room isn't known (regardless of whether the Automapper window is open)
        if (
            ($self->mapWin && $self->mapWin->mode eq 'wait')
            || (! $self->mapWin && ! $self->trackAloneFlag)
            || ! $self->currentRoom
        ) {
            return undef;
        }

        # Check that the destination room still exists (just in case)
        # NB This function doesn't create a new world model room, if the Automapper window is in
        #   'update' mode
        $destRoomObj = $self->worldModelObj->ivShow('modelHash', $cmdObj->teleportDestRoom);
        if (! $destRoomObj || $destRoomObj->category ne 'room') {

            # Show an explanation, if allowed
            if ($self->worldModelObj->explainGetLostFlag) {

                $self->session->writeText(
                    'MAP: Lost because the character tried to teleport to a room that no longer'
                    . ' exists',
                );
            }

            # The TRUE argument means 'the character is lost'
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->teleportSeen',    # Defined string marks character as lost
            );

        } else {

            # Use the destination room
            return $self->useExistingRoom(
                $self->currentRoom,
                $destRoomObj,
                $cmdObj->cmd,
            );
        }

        return 1;
    }

    sub lookGlanceSeen {

        # Called by GA::Task::Locator->processLine->main (at stage 3) as the result of
        #   a look/glance command (i.e. the character hasn't moved)
        #
        # Expected arguments
        #   $cmdObj     - The GA::Buffer::Cmd object that stores the look/glance command (not
        #                   required by this function, actually)
        #
        # Return values
        #   'undef' on improper arguments or if no changes are made to $self->currentRoom
        #   1 otherwise

        my ($self, $cmdObj, $check) = @_;

        # Check for improper arguments
        if (! defined $cmdObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->lookGlanceSeen', @_);
        }

        # Do nothing if:
        #   1. The Automapper window is open and is in 'wait' mode
        #   2. The Automapper window isn't open, and $self->trackAloneFlag is FALSE
        #   3. The current room isn't known (regardless of whether the Automapper window is open)
        if (
            ($self->mapWin && $self->mapWin->mode eq 'wait')
            || (! $self->mapWin && ! $self->trackAloneFlag)
            || ! $self->currentRoom
        ) {
            return undef;
        }

        # Update the existing room to give it the same properties as the Locator's non-model
        #   room (where appropriate)
        $self->updateRoom($self->currentRoom);
        # Mark the objects to be redrawn (in every Automapper window)
        $self->worldModelObj->updateMaps('room', $self->currentRoom);

        # The Locator task has a non-model room matching the automapper's ->currentRoom, so
        #   remind the Locator of which world model room is the matching one
        $self->updateLocator();

        return 1;
    }

    sub failedExitSeen {

        # Called by GA::Task::Locator->processLine->main (at stage 3) when the character fails to
        #   move (because a known failed exit pattern is seen)
        #
        # Expected arguments
        #   $pattern     - One of the patterns from the world profile's ->doorPatternList or
        #                   ->failExitPatternList
        #
        # Optional arguments
        #   $dir         - The presumed direction of the failed move (matches GA::Obj::Exit->dir).
        #                   If 'undef', it is probably because two failed exit patterns (or a failed
        #                   exit and a closed door pattern) appeared one after the other; the
        #                   Locator interpreted the first one as a failed move, but doesn't know
        #                   what kind of move caused the second one
        #
        # Return values
        #   'undef' on improper arguments, if the failed exit can't be processed or if an exit
        #       object corresponding to the direction $dir can't be found
        #   1 otherwise

        my ($self, $pattern, $dir, $check) = @_;

        # Local variables
        my (
            $worldObj, $dictObj, $primSecFlag, $standard,
            @redrawList,
        );

        # Check for improper arguments
        if (! defined $pattern || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->failedExitSeen', @_);
        }

        # Do nothing if:
        #   1. The Automapper window is open and is in 'wait' mode
        #   2. The Automapper window isn't open, and $self->trackAloneFlag is FALSE
        #   3. The current room isn't known (regardless of whether the Automapper window is open)
        #   4. $dir was set to 'undef' - if the Locator isn't sure to which room a failed exit
        #       pattern belongs, we can't work it out, either
        if (
            ($self->mapWin && $self->mapWin->mode eq 'wait')
            || (! $self->mapWin && ! $self->trackAloneFlag)
            || ! $self->currentRoom
            || ! defined $dir
        ) {
            return undef;
        }

        # Import the current world profile and current dictionary (for convenience)
        $worldObj = $self->session->currentWorld;
        $dictObj = $self->session->currentDict;

        # If $dir is a primary/secondary direction, but abbreviated, unabbreviate it
        if ($dictObj->checkPrimaryDir($dir) || $dictObj->checkSecondaryDir($dir)) {

            $primSecFlag = TRUE;
            $dir = $dictObj->unabbrevDir($dir);
        }

        # Find the current room's exit object corresponding to the direction $dir
        foreach my $number ($self->currentRoom->ivValues('exitNumHash')) {

            my ($exitObj, $twinExitObj);

            $exitObj = $self->worldModelObj->ivShow('exitModelHash', $number);
            if ($exitObj && $exitObj->dir eq $dir) {

                # $exitObj is the exit responsible. Give it an ornament (but only when the
                #   Automapper window is open and is in 'update' mode)
                if ($self->mapWin && $self->mapWin->mode eq 'update') {

                    if (defined $worldObj->ivFind('lockedPatternList', $pattern)) {

                        # Set the exit as lockable
                        $self->worldModelObj->setExitOrnament(
                            FALSE,       # Don't update Automapper windows now
                            $exitObj,
                            'lock',
                        );

                    } elsif (defined $worldObj->ivFind('doorPatternList', $pattern)) {

                        # Set the exit as openable
                        $self->worldModelObj->setExitOrnament(
                            FALSE,       # Don't update Automapper windows now
                            $exitObj,
                            'open',
                        );
                    }
                }

                # If there are no more room statements expected, we know exactly where the
                #   character's current location is, and so it's safe to set the ghost room as the
                #   current room (allowing the next movement command entered by the user to be used
                #   in an assisted move)
                # Otherwise, the ghost room needs to be reset entirely
                if (
                    $self->session->locatorTask
                    && ! $self->session->locatorTask->moveList
                ) {
                    $self->setGhostRoom($self->currentRoom);
                } else {
                    $self->setGhostRoom();
                }

                # Mark the room as needing to be redrawn. Also mark the exit's destination room, if
                #   there is one, so that (for example) when an exit becomes impassable, the twin
                #   exit is drawn properly
                push (@redrawList,
                    'room',
                    $self->worldModelObj->ivShow('modelHash', $exitObj->parent),
                );

                if ($exitObj->twinExit) {

                    $twinExitObj = $self->worldModelObj->ivShow('exitModelHash',$exitObj->twinExit);
                    if ($twinExitObj) {

                        push (@redrawList,
                            'room',
                            $self->worldModelObj->ivShow('modelHash', $twinExitObj->parent),
                        );
                    }
                }

                # Mark the objects to be redrawn (in every Automapper window)
                $self->worldModelObj->updateMaps(@redrawList);

                return 1;
            }
        }

        # No exit object exists in the direction $dir
        # For primary/secondary directions, make a record of the failed exit, if allowed to do so
        #   (in Axmud terminology this is called a checked direction)
        if ($primSecFlag && $self->worldModelObj->collectCheckedDirsFlag) {

            if ($self->currentRoom->ivExists('checkedDirHash', $dir)) {
                $self->currentRoom->ivIncHash('checkedDirHash', $dir);
            } else {
                $self->currentRoom->ivAdd('checkedDirHash', $dir, 1);
            }

            # Mark the room to be redrawn (in every Automapper window)
            $self->worldModelObj->updateMaps('room', $self->currentRoom);
        }

        # Corresponding exit object not found
        return undef;
    }

    sub involuntaryExitSeen {

        # Called by GA::Task::Locator->processLine->main (at stage 3) when the character moves
        #   involuntarily (i.e. when a known involuntary exit pattern is seen)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no changes are made to $self->currentRoom
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->involuntaryExitSeen', @_);
        }

        # Do nothing if:
        #   1. The Automapper window is open and is in 'wait' mode
        #   2. The Automapper window isn't open, and $self->trackAloneFlag is FALSE
        #   3. The current room isn't known (regardless of whether the Automapper window is open)
        if (
            ($self->mapWin && $self->mapWin->mode eq 'wait')
            || (! $self->mapWin && ! $self->trackAloneFlag)
            || ! $self->currentRoom
        ) {
            return undef;
        }

        # We are now lost. Display an explanatory message, if necessary
        if ($self->worldModelObj->explainGetLostFlag) {

            $self->session->writeText('MAP: Lost because an involuntary exit was detected');
        }

        return $self->setCurrentRoom(
            undef,
            $self->_objClass . '->involuntaryExitSeen',    # Character now lost
        );

        return 1;
    }

    # Locator task support functions

    sub autoProcessNewRoom {

        # Called by GA::Obj::Map->moveKnownDirSeen when the Automapper window is in 'update' mode
        #   and the character's move requires us to (probably) create a new room
        #
        # Expected arguments
        #   $dir            - The command that we think was responsible for the move ('north', 'up',
        #                       'cross bridge' etc)
        #   $regionmapObj   - The current room's regionmap (the new room will be placed in the same
        #                       region)
        #   $xPosBlocks, $yPosBlocks, $zPosBlocks
        #                   - The grid coordinates of the new room's likely position, as calculated
        #                       by the calling function
        #
        # Optional arguments
        #   $mapDir         - For primary directions, the standard form of $customDir. Set to
        #                       'undef' for non-primary directions
        #   $customDir      - For primary directions, set to the unabbreviated form of $dir (so its
        #                       value may be the same as $dir, or not). Set to 'undef' for
        #                       non-primary directions
        #   $exitObj        - The GA::Obj::Exit corresponding to the direction of the move, if
        #                       known (otherwise set to 'undef')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $dir, $regionmapObj, $xPosBlocks, $yPosBlocks, $zPosBlocks, $mapDir, $customDir,
            $exitObj, $redrawRoomObj,
            $check,
        ) = @_;

        # Local variables
        my (
            $successFlag, $listRef, $xPos, $yPos, $zPos, $count, $foundRoomObj, $exitFlag,
            $exitLength, $maxLength,
            %uncertainHash,
        );

        # Check for improper arguments
        if (
            ! defined $dir || ! defined $regionmapObj || ! defined $xPosBlocks
            || ! defined $yPosBlocks || ! defined $zPosBlocks || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->autoProcessNewRoom', @_);
        }

        # Deal with two special cases, both of which depend on the value of the world model's
        #   ->intelligentExitsFlag

        # 1. There are two rooms, A and B. A has an uncertain exit which leads to B, but A is also a
        #   broken exit. Should B lead back to A, or does it actually lead to a new room?
        if (
            $exitObj
            && ! $exitObj->destRoom && $exitObj->randomType eq 'none'   # $exitObj is incomplete
            && $self->currentRoom->uncertainExitHash
        ) {
            # The current room is room B, and its exit which might lead back to room A in the
            #   direction $dir is $exitObj
            OUTER: foreach my $oppExitNumber ($self->currentRoom->ivKeys('uncertainExitHash')) {

                my ($oppExitObj, $oppRoomObj);

                # Get the exit from room A
                $oppExitObj = $self->worldModelObj->ivShow('exitModelHash', $oppExitNumber);
                if ($oppExitObj && ($oppExitObj->brokenFlag || $oppExitObj->regionFlag)) {

                    # Get room A
                    $oppRoomObj = $self->worldModelObj->ivShow('modelHash', $oppExitObj->parent);

                    # Check if the exit is in the right opposite direction
                    if ($self->worldModelObj->checkOppPrimary($exitObj, $oppRoomObj)) {

                        if ($self->worldModelObj->intelligentExitsFlag) {

                            # Instead of creating a new room, we should use the existing room,
                            #   $oppRoomObj, creating a (broken) two-way exit

                            # Connect the current location to the existing room, if they're not
                            #   already connected (and if they are, make it a two-way exit)z
                            $self->worldModelObj->connectRooms(
                                $self->session,
                                FALSE,       # Don't update Automapper windows now
                                $self->currentRoom,
                                $oppRoomObj,
                                $dir,
                                $mapDir,
                                $exitObj,
                            );

                            # Mark the exit from B to A as a broken/region exit, too
                            if ($oppExitObj->brokenFlag) {

                                $self->worldModelObj->setBrokenExit(
                                    FALSE,       # Don't update Automapper windows now
                                    $exitObj,
                                );

                            } elsif ($oppExitObj->regionFlag) {

                                $self->worldModelObj->setRegionExit(
                                    FALSE,       # Don't update Automapper windows now
                                    $exitObj,
                                );
                            }

                            # Update the number of character visits to this room (if allowed)
                            $self->worldModelObj->updateVisitCount(
                                $self->session,
                                # Don't update Automapper windows now (the call to ->updateRoom will
                                #   do that)
                                FALSE,
                                $oppRoomObj->number,
                            );

                            # Tell the automapper window to graffiti the room (when graffiti mode is
                            #   on)
                            $self->mapWin->add_graffiti($oppRoomObj);

                            # Update the existing room to give it the same properties as the
                            #   Locator's non-model room (where appropriate)
                            $self->updateRoom($oppRoomObj);

                            # Paint the room, if required to do so
                            if (
                                $self->mapWin->painterFlag
                                && $self->worldModelObj->paintAllRoomsFlag
                            ) {
                                $self->mapWin->paintRoom($oppRoomObj);
                            }

                            # The call to ->updateRoom marks $oppRoomObj as needing to be redrawn in
                            #   every Automapper window; make sure $self->currentRoom is also
                            #   redrawn in every Automapper window
                            $self->worldModelObj->updateMaps('room', $self->currentRoom);

                            # In both 'update' mode and 'follow' mode, $existingRoom is the new
                            #   location
                            $self->setCurrentRoom($oppRoomObj);

                            $successFlag = TRUE;
                            last OUTER;

                        } else {

                            # Intelligent uncertain exits are disabled. Convert the uncertain exit
                            #   to a one-way exit
                            $self->worldModelObj->convertUncertainExit(
                                # Don't update Automapper windows now (the call to ->createNewRoom
                                #   will do that)
                                FALSE,
                                $oppExitObj,
                                $self->currentRoom,
                            );
                        }
                    }
                }
            }
        }

        # 2. There are two rooms, A and B. B is one gridblock north of A and the 'north' exit from A
        #   to B is not a broken (or region) exit. The exit length is currently set to 2 gridblocks.
        #   When we go south from B, should it lead to room A - ignoring the exit length, and using
        #   the first room in the direction 'south' it finds - or should a new room be created 1
        #   gridblock south of A, with a broken exit leading to it?
        if (! $successFlag && $exitObj) {

            $exitLength = $self->worldModelObj->getExitLength($exitObj);

            if (
                ! $exitObj->destRoom
                && $exitObj->randomType eq 'none'   # $exitObj is incomplete
                && $exitLength > 1
                && $exitObj->dir
                && $exitObj->mapDir
            ) {
                # The current room is room B, and its exit which might lead back to room A in the
                #   direction $dir is $exitObj
                # We need to check the gridblocks between the one occupied by room B, and the one
                #   at which a new room, C, would be created (described by $xPosBlocks, $yPosBlocks,
                #   $zPosBlocks, supplied by the calling function), stopping at the first room we
                #   find (which will be room A)

                # Import a vector hash, in the form
                #   %vectorHash         => {
                #        north                   => [0, -1, 0],
                #        northnortheast          => [1, -2, 0],
                #        northeast               => [1, -1, 0],
                #        eastnortheast           => [2, -1, 0],
                #        east                    => [1, 0, 0],
                #        eastsoutheast           => [2, 1, 0],
                #        southeast               => [1, 1, 0],
                #        southsoutheast          => [1, 2, 0],
                #        south                   => [0, 1, 0],
                #        southsouthwest          => [-1, 2, 0],
                #        southwest               => [-1, 1, 0],
                #        westsouthwest           => [-2, 1, 0],
                #        west                    => [-1, 0, 0],
                #        westnorthwest           => [-2, -1, 0],
                #        northwest               => [-1, -1, 0],
                #        northnorthwest          => [-1, -2, 0],
                #        up                      => [0, 0, 1],
                #        down                    => [0, 0, -1],
                #   },
                # Extract from %vectorHash the list corresponding to the $exitObj's primary
                #   direction
                $listRef = $self->mapWin->ivShow('constSpecialVectorHash', $exitObj->mapDir);

                # Check every gridblock between B and C, looking for room A
                $xPos = $self->currentRoom->xPosBlocks;
                $yPos = $self->currentRoom->yPosBlocks;
                $zPos = $self->currentRoom->zPosBlocks;
                $count = 0;

                do {

                    my $number;

                    $xPos += $$listRef[0];
                    $yPos += $$listRef[1];
                    $zPos += $$listRef[2];
                    $count++;

                    # Don't look at room C...
                    if ($xPos != $xPosBlocks && $yPos != $yPosBlocks && $zPos != $zPosBlocks) {

                        $exitFlag = TRUE;

                    } else {

                        # If there's a room A at this gridblock, store it in $foundRoom
                        $number = $regionmapObj->fetchRoom($xPos, $yPos, $zPos);
                        if (defined $number) {

                            $foundRoomObj = $self->worldModelObj->ivShow('modelHash', $number);
                        }
                    }

                } until ($foundRoomObj || $exitFlag || $count >= $exitLength);

                if ($foundRoomObj) {

                    # We've found a room A directly between rooms B and C
                    # If the 'intelligent uncertain exits' flag is set, connect B to A rather than
                    #   to C, ignoring the exit length specified by the world model's
                    #   ->horizontalExitLengthBlocks or ->verticalExitLengthBlocks
                    if ($self->worldModelObj->intelligentExitsFlag) {

                        $self->useExistingRoom(
                            $self->currentRoom,
                            $foundRoomObj,
                            $dir,
                            $customDir,
                            $exitObj,
                        );

                        $successFlag = TRUE;

                    } else {

                        # Mark the exit as a broken exit. In a moment, a new room will be drawn
                        #   as usual
                        $self->worldModelObj->setBrokenExit(
                            FALSE,       # Don't update Automapper windows now
                            $exitObj,
                        );

                        # If there is an incoming uncertain exit in the opposite direction, it must
                        #   be converted to a one-way exit
                        %uncertainHash = $self->currentRoom->uncertainExitHash;
                        foreach my $uncertainExitNum (keys %uncertainHash) {

                            my ($oppExitNum, $oppExitObj, $uncertainExitObj);

                            $oppExitNum = $uncertainHash{$uncertainExitNum};

                            if ($oppExitNum == $exitObj->number) {

                                # Convert it a one-way exit
                                $uncertainExitObj = $self->worldModelObj->ivShow(
                                    'exitModelHash',
                                    $uncertainExitNum,
                                );

                                if ($uncertainExitObj) {

                                    $self->worldModelObj->convertUncertainExit(
                                        TRUE,       # Update Automapper windows now
                                        $uncertainExitObj,
                                        $self->currentRoom,
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }

        if (! $successFlag) {

            # In 'update' mode, for a movement in a primary direction, create a new room at the
            #   specified location, make it the current room, give it the properties of the
            #   Locator task's current room, and update the map
            if (
                ! $self->createNewRoom(
                    $regionmapObj,          # Use the same region as the current room
                    $xPosBlocks,            # Co-ordinates of room on the region's grid
                    $yPosBlocks,
                    $zPosBlocks,
                    undef,                  # Don't change GA::Win::Map->mode
                    TRUE,                   # New room is current room
                    TRUE,                   # New room takes properties from Locator
                    $self->currentRoom,
                    $dir,                   # Connect rooms together...
                    $mapDir,                #   ('undef' if $dir is a non-primary direction)
                    $exitObj,               # ...using existing exit (if set)
                )
            ) {
                return undef;
            }

            # Check the world model for Axbasic scripts and, if any are found, execute them
            if ($self->worldModelObj->allowModelScriptFlag) {

                foreach my $script ($self->worldModelObj->newRoomScriptList) {

                    $self->session->pseudoCmd('runscript ' . $script);
                }
            }
        }

        return 1;
    }

    sub createNewRoom {

        # Called by $self->moveKnownDirSeen, ->autoProcessNewRoom and ->reactRandomExit
        # Also called by GA::Win::Map->enableCanvasPopupMenu, ->canvasEventHandler,
        #   ->addFirstRoomCallback, ->addRoomAtBlockCallback
        # Creates a new room - adding a new object to the world model. At the moment, new rooms can
        #   only be created when the automapper window is open, but this function checks for that
        #   (just in case of future changes)
        # If the process fails, deletes the world model object (if already created) and displays an
        #   error
        #
        # Expected arguments
        #   $regionmapObj   - The GA::Obj::Regionmap in which the new room will be created. Usually
        #                       (but not always) matches the regionmap visible in the automapper
        #                       window for this session
        #   $xPosBlocks, $yPosBlocks, $zPosBlocks
        #                   - The coordinates of the new room on the regionmap's grid
        #
        # Optional arguments
        #   $mode           - The new automapper window's ->mode after the room has been created. If
        #                       'undef', the window's ->mode isn't changed
        #   $currentFlag    - If set to TRUE, the new room is made the current location (if FALSE
        #                       or 'undef', the current location isn't changed)
        #   $updateFlag     - If set to TRUE, the room's properties are updated to match those of
        #                       the Locator task's current room (depending on certain flags, and
        #                       only when $currentFlag is TRUE; otherwise set to FALSE or 'undef')
        #   $connectRoomObj - The room from which the character just departed ('undef' if not known)
        #   $dir            - The command used to move (e.g. 'n', 'enter well' - matches
        #                       GA::Obj::Exit->dir) ('undef' if unknown)
        #   $mapDir         - How the exit is drawn on the map - one of Axmud's standard primary
        #                       directions (e.g. 'north', 'south', 'up) ('undef' if unknown)
        #   $exitObj        - The GA::Obj::Exit through which the character moved (if 'undef', a new
        #                       exit object can be created)
        #
        # Return values
        #   'undef' on improper arguments or if the new room isn't created
        #   Otherwise returns the GA::ModelObj::Room created

        my (
            $self, $regionmapObj, $xPosBlocks, $yPosBlocks, $zPosBlocks, $mode, $currentFlag,
            $updateFlag, $connectRoomObj, $dir, $mapDir, $exitObj, $check,
        ) = @_;

        # Local variables
        my (
            $text, $result, $roomObj, $filePath, $virtualPath,
            @matchList, @selectList,
        );

        # Check for improper arguments
        if (
            ! defined $regionmapObj || ! defined $xPosBlocks || ! defined $yPosBlocks
            || ! defined $zPosBlocks || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->createNewRoom', @_);
        }

        if ($updateFlag && $self->worldModelObj->autoCompareFlag && $self->mapWin) {

            # Before creating the new room, compare the Locator's current room against all rooms
            #   already in the region, looking for matches - in case we're about to create a
            #   duplicate room
            @matchList = $self->autoCompareLocatorRoom($regionmapObj);
            if (@matchList) {

                # Select all the matching rooms
                # GA::Win::Map->setSelectedObj expects a list in the form
                #   (room_object, 'room', room_object, 'room', ...)
                foreach my $obj (@matchList) {

                    push (@selectList, $obj, 'room');
                }

                # First unselect all selected objects, then selecting just the matching rooms
                if ($self->mapWin->currentRegionmap) {

                    $self->mapWin->setSelectedObj();
                    $self->mapWin->setSelectedObj(
                        \@selectList,
                        TRUE,           # Select multiple objects
                    );
                }

                # Show a 'dialogue' window as a warning
                if (@matchList == 1) {
                    $text = 'The Locator\'s current room matches 1 room';
                } else {
                    $text = 'The Locator\'s current room matches ' . scalar @matchList . ' rooms';
                }

                $text .= ' in the current region. Do you want to continue?';

                $result = $self->mapWin->showMsgDialogue(
                    'Add new room',
                    'warning',
                    $text,
                    'yes-no',
                );

                if ($result ne 'yes') {

                    # If there is a current room, mark the automapper as lost
                    if ($self->currentRoom) {

                        return $self->setCurrentRoom(
                            undef,
                            $self->_objClass . '->createNewRoom',    # Character now lost
                        );

                        # Display an explanatory message, if necessary
                        if ($self->worldModelObj->explainGetLostFlag) {

                            $self->session->writeText(
                                'MAP: Lost after user declined to create a new room',
                            );
                        }
                    }

                    # Don't create the new room
                    return undef;
                }
            }
        }

        # Create the room object. Tell the world model not to update automappers immediately - we
        #   might want to mark the room as current
        $roomObj = $self->worldModelObj->addRoom(
            $self->session,
            TRUE,               # Update Automapper windows now
            $regionmapObj->name,
            $xPosBlocks,
            $yPosBlocks,
            $zPosBlocks,
        );

        if (! $roomObj) {

            # Operation failed
            if ($self->mapWin) {

                $self->mapWin->showMsgDialogue(
                    'New room',
                    'error',
                    'Could not create the new room',
                    'ok',
                );

            } else {

                $self->session->writeText('MAP: Could not create a new room');
            }

            return undef;
        }

        # Set the automapper's mode, if a new mode was specified
        if ($mode && $self->mapWin) {

            $self->mapWin->setMode($mode);
        }

        # Set the current location (which causes both the previous current location, if there was
        #   one, and the new current location to be redrawn)
        if ($currentFlag) {

            # Update the number of character visits to this room, if allowed
            $self->worldModelObj->updateVisitCount(
                $self->session,
                # Don't update Automapper windows now (the call to ->updateRoom will do that)
                FALSE,
                $roomObj->number,
            );

            # Mark this room with graffiti (when graffiti mode is on)
            if ($self->mapWin) {

                $self->mapWin->add_graffiti($roomObj);
            }

            # Paint the room, if required to do so
            if ($self->mapWin && $self->mapWin->painterFlag) {

                $self->mapWin->paintRoom($roomObj);
            }

            # If necessary, give the new room the properties of the Locator task's current room
            if ($updateFlag) {

                $self->updateRoom($roomObj, $connectRoomObj, $exitObj, $mapDir);
            }

            # If the previous room is known, connect it to this room
            if ($connectRoomObj && $dir) {

                $self->worldModelObj->connectRooms(
                    $self->session,
                    TRUE,       # Update Automapper windows now (for the benefit of $connectRoomObj)
                    $connectRoomObj,
                    $roomObj,
                    $dir,
                    $mapDir,
                    $exitObj,
                );
            }

            # Set the current location
            $self->setCurrentRoom($roomObj);

        } else {

            # Just draw the new room (in every Automapper window)
            $self->worldModelObj->updateMaps('room', $roomObj);
        }

        return $roomObj;
    }

    sub useExistingRoom {

        # Called by $self->moveKnownDirSeen when it has decided that the move from one room
        #   ($departRoomObj) in the direction $dir has resulted in arrival at the room
        #   $arriveRoomObj
        # Updates the Automapper window as required
        #
        # Expected arguments
        #   $departRoomObj  - The GA::ModelObj::Room from which the character left
        #   $arriveRoomObj  - The GA::ModelObj::Room to which the character has arrived
        #   $dir            - The command that we think was responsible for the move ('north', 'up',
        #                       'cross bridge' etc)
        #
        # Optional arguments
        #   $customDir      - How the exit is drawn on the map - matches a value in
        #                       GA::Obj::Dict->primaryDirHash (e.g. 'north', 'south', 'up'). If
        #                       'undef', the exit can't be drawn on the map
        #   $exitObj        - An existing GA::Obj::Exit to use, if known. If none is specified,
        #                       the destination room's ->exitNumHash is consulted to provide it
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $departRoomObj, $arriveRoomObj, $dir, $customDir, $exitObj, $check) = @_;

        # Local variables
        my ($standardDir, $result, $msg);

        # Check for improper arguments
        if (
            ! defined $departRoomObj || ! defined $arriveRoomObj || ! defined $dir || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->useExistingRoom', @_);
        }

        # If $customDir was specified, convert it to a standard primary direction
        if ($customDir) {

            $standardDir = $self->session->currentDict->ivShow('combRevDirHash', $customDir);
        }

        # If the Locator task has created a non-model room object for the current room, see if
        #   it matches $arriveRoomObj
        # The TRUE argument means that a dark or unspecified non-model room matches any model room
        # The second return value is only ever set after a call from this function; if set to TRUE,
        #   we have to display a message, explaining why the automapper is now lost
        ($result, $msg) = $self->worldModelObj->compareRooms(
            $self->session,
            $arriveRoomObj,
            TRUE,
        );

        if (! $result) {

            if ($self->worldModelObj->explainGetLostFlag && $msg) {

                $self->session->writeText('MAP: ' . $msg);
            }

            # The existing room isn't the one we were expecting, so the automapper is now lost (an
            #   explanatory message has already been displayed, if necessary)
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->useExistingRoom',    # Character now lost
            );

        } else {

            # The Locator task's room matches $arriveRoomObj. If the Automapper window is open and
            #   and in 'update' mode, update the map
            if ($self->mapWin && $self->mapWin->mode eq 'update') {

                # Connect the two rooms if they're not already connected (and if they are, make
                #   the exit between them two-way exits)
                # NB Don't connect two rooms if either one is in wilderness mode
                if (
                    ($departRoomObj->wildMode eq 'normal' && $arriveRoomObj->wildMode ne 'wild')
                    || ($arriveRoomObj->wildMode eq 'normal' && $departRoomObj->wildMode ne 'wild')
                ) {

                    $self->worldModelObj->connectRooms(
                        $self->session,
                        TRUE,       # Update Automapper windows now (for benefit of $departRoomObj)
                        $departRoomObj,
                        $arriveRoomObj,
                        $dir,
                        $standardDir,
                        $exitObj,
                    );
                }
            }

            # Update the number of character visits to this room (if allowed)
            $self->worldModelObj->updateVisitCount(
                $self->session,
                # Don't update Automapper windows now (the call to ->updateRoom will do that)
                FALSE,
                $arriveRoomObj->number,
            );

            # Tell the automapper window to graffiti the room (when graffiti mode is on)
            if (
                $self->mapWin
                && ($self->mapWin->mode eq 'follow' || $self->mapWin->mode eq 'update')
            ) {
                $self->mapWin->add_graffiti($arriveRoomObj);
            }

            # Update the arrival room to give it the same properties as the Locator's non-model
            #   room (where appropriate)
            $self->updateRoom($arriveRoomObj);

            # Paint the room, if required to do so
            if (
                $self->mapWin
                && $self->mapWin->painterFlag
                && $self->worldModelObj->paintAllRoomsFlag
                && $self->mapWin->mode eq 'update'
            ) {
                $self->mapWin->paintRoom($arriveRoomObj);
            }

            # $arriveRoomObj is the new location
            $self->setCurrentRoom($arriveRoomObj);

            # Check for room scripts
            if ($self->worldModelObj->allowRoomScriptFlag) {

                # Check the GA::ModelObj::Room for Axbasic scripts and, if any are found, execute
                #   them
                foreach my $script ($arriveRoomObj->arriveScriptList) {

                    $self->session->pseudoCmd('runscript ' . $script);
                }
            }

            if ($self->worldModelObj->allowModelScriptFlag) {

                # Check the world model for Axbasic scripts and, if any are found, execute
                #   them
                foreach my $script ($self->worldModelObj->arriveScriptList) {

                    $self->session->pseudoCmd('runscript ' . $script);
                }
            }
        }

        return 1;
    }

    sub reactRandomExit {

        # Called by $self->moveKnownDirSeen to decide what to do, when the character uses a random
        #   exit (one whose ->randomType is not 'none')
        #
        # Expected arguments
        #   $exitObj    - The GA::Obj::Exit used
        #
        # Return values
        #   'undef' on improper arguments or if there's an error calling $self->setCurrentRoom
        #   1 otherwise

        my ($self, $exitObj, $check) = @_;

        # Local variables
        my (
            $regionObj, $regionmapObj, $lostMsg, $originRoomObj, $originMode,
            @locateList, @foundList, @selectList,
        );

        # Check for improper arguments
        if (! defined $exitObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reactRandomExit', @_);
        }

        # Get the current room's parent region and regionmap
        $regionObj = $self->worldModelObj->ivShow('modelHash', $self->currentRoom->parent);
        $regionmapObj = $self->worldModelObj->ivShow('regionmapHash', $regionObj->name);

        # Random exit type 'same_region' - exit leads to a random location in the same region
        if ($exitObj->randomType eq 'same_region') {

            if ($self->worldModelObj->locateRandomInRegionFlag) {

                # Try to locate the new current room. Get a list of room numbers in the current
                #   region
                @locateList = $regionmapObj->ivValues('gridRoomHash');

                # If the region contains more rooms than the locate operation limit, don't try to
                #   locate the current location, but mark the character as lost
                if (
                    $self->worldModelObj->locateMaxObjects
                    && $self->worldModelObj->locateMaxObjects < @locateList
                ) {
                    $lostMsg = 'MAP: Lost because the character used a random exit leading to the'
                                    . ' same region, which contains more than '
                                    . $self->worldModelObj->locateMaxObjects . 'rooms';
                }

            } else {

                # Write a message that would be displayed, if
                #   GA::Obj::WorldModel->explainGetLostFlag were set
                $lostMsg = 'MAP: Lost because the character used a random exit leading to the same'
                                . ' region',
            }

        # Random exit type 'any_region' - exit leads to a random location anywhere in the world
        } elsif ($exitObj->randomType eq 'any_region') {

            if ($self->worldModelObj->locateRandomAnywhereFlag) {

                @locateList = $self->worldModelObj->ivKeys('roomModelHash');

                if (
                    $self->worldModelObj->locateMaxObjects
                    && $self->worldModelObj->locateMaxObjects < @locateList
                ) {
                    $lostMsg = 'MAP: Lost because the character used a random exit leading to any'
                                    . ' region, which collectively contain more than '
                                    . $self->worldModelObj->locateMaxObjects . 'rooms';
                }

            } else {

                $lostMsg = 'MAP: Lost because the character used a random exit leading to any'
                                . ' region',
            }

        # Random exit type 'temp_region' - exit leads to a destination room in a new temporary
        #   region
        } elsif ($exitObj->randomType eq 'temp_region') {

            # Can only create new rooms when the automapper window is open (can't do it when
            #   $self->trackAloneFlag is TRUE)
            if (! $self->mapWin) {

                $lostMsg = 'MAP: Lost because random exit leads to a temporary region, but can only'
                                . ' only create new rooms and regions when the automapper window is'
                                . ' open';

            } else {

                # Create a new temporary region,
                $regionObj = $self->worldModelObj->addRegion(
                    $self->session,
                    TRUE,           # Update Automapper windows now
                    undef,          # Generate a region name
                    undef,          # No parent region
                    TRUE,           # Temporary region
                );

                if (! $regionObj) {

                    $lostMsg = 'MAP: Lost because random exit leads to a temporary region, but'
                                    . ' could not create a new temporary region',

                } else {

                    $originRoomObj = $self->currentRoom;
                    if ($self->mapWin) {

                        $originMode = $self->mapWin->mode;
                    }

                    # Create a new room in the temporary region
                    $regionmapObj = $self->worldModelObj->ivShow('regionmapHash', $regionObj->name);
                    if (
                        ! $self->createNewRoom(
                            $regionmapObj,
                            $regionmapObj->getGridCentre(),     # Put new room at centre of region
                            'update',                           # Switch to 'update' mode
                            TRUE,                               # New room is current room
                            TRUE,                               # Room takes properties from Locator
                        )
                    ) {
                        $lostMsg = 'MAP: Lost due to internal error (cannot process new room)';

                    } else {

                        # The automapper window's mode must be switched to 'update', if it's not
                        #   already
                        if ($self->mapWin && $self->mapWin->mode eq 'follow') {

                            $self->mapWin->setMode('update');
                        }

                        # Update IVs, ready for the character to return the original room
                        $self->ivPoke('tempRandomOriginRoom', $originRoomObj);
                        $self->ivPoke('tempRandomDestRoom', $self->currentRoom);
                        $self->ivPoke('tempRandomMode', $originMode);

                        # The new current room is already set, so that's the end of the operation
                        return 1;
                    }
                }
            }

        # Random exit type 'room_list' - exit leads to one of a defined list of rooms (no limit to
        #   the number of rooms to search, in this case)
        } else {

            @locateList = $exitObj->randomDestList;
            if (! @locateList) {

                $lostMsg = 'MAP: Lost because the character used a random exit with no destination'
                                . ' rooms set',
            }
        }

        # Mark the character as lost, if necessary
        if ($lostMsg) {

            # Display the message only if the flag is set
            if ($self->worldModelObj->explainGetLostFlag) {

                $self->session->writeText($lostMsg);
            }

            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->reactRandomExit',    # Character now lost
            );

        } else {

            # Try to locate the new current room. Put any matching rooms into @foundList so that,
            #   if there is more than one matching room, we can choose which room to use
            OUTER: foreach my $roomNum (@locateList) {

                my $roomObj = $self->worldModelObj->ivShow('modelHash', $roomNum);

                if ($self->worldModelObj->locateRoom($self->session, $roomObj)) {

                    push (@foundList, $roomObj);

                    # For random exit type 3, we use the first room found
                    if ($exitObj->randomType eq 'room_list') {

                        last OUTER;
                    }
                }
            }

            if (! @foundList) {

                # No matching rooms found; character is now lost
                if ($self->worldModelObj->explainGetLostFlag) {

                    $self->session->writeText(
                        'MAP: Lost because the character used a random exit, but no matching rooms'
                        . ' were found',
                    );
                }

                return $self->setCurrentRoom(
                    undef,
                    $self->_objClass . '->reactRandomExit',    # Character now lost
                );

            } elsif (@foundList == 1) {

                # This is the new current room
                return $self->setCurrentRoom($foundList[0]);

            } else {

                # There is more than one matching room. Select all the matching rooms, so the user
                #   can decide which to use (if the Automapper window is open)

                if ($self->mapWin) {

                    # First unselect any currently selected objects
                    $self->mapWin->setSelectedObj();

                    # Select all of the matching rooms. $self->setSelectedObj expects a list in the
                    #   form:
                    #       (room_object, 'room', room_object, 'room', ...)
                    foreach my $roomObj (@foundList) {

                        push (@selectList, $roomObj, 'room');
                    }

                    $self->mapWin->setSelectedObj(
                        \@selectList,
                        TRUE,           # Select multiple objects
                    );
                }

                if ($self->worldModelObj->explainGetLostFlag) {

                    $self->session->writeText(
                        'MAP: Lost because the character used a random exit, and there is more than'
                            . ' one possible new location',
                    );
                }

                return $self->setCurrentRoom(
                    undef,
                    $self->_objClass . '->reactRandomExit',    # Character now lost
                );
            }
        }
    }

    sub updateRoom {

        # Called by $self->moveKnownDirSeen, $self->lookGlanceSeen and $self->createNewRoom in order
        #   to update the properties of a room object in the world model to match those of the
        #   Locator task's non-model current room
        # If the Automapper window is open and is in 'update' mode, GA::Obj::WorldModel is called
        #   to do the bulk of the updating
        #
        # Expected arguments
        #   $modelRoomObj
        #       - A GA::ModelObj::Room in the world model
        #
        # Optional arguments
        #   $connectRoomObj, $connectExitObj, $mapDir
        #       - When called by $self->createNewRoom, the room from which we arrived and the exit/
        #           standard direction used to depart from it (if known). Used when temporarily
        #           allocating primary directions to unallocated exits
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $modelRoomObj, $connectRoomObj, $connectExitObj, $mapDir, $check) = @_;

        # Check for improper arguments
        if (! defined $modelRoomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRoom', @_);
        }

        # If the Automapper window is open (and in 'follow' or 'update' mode), or if the Automapper
        #   window is closed but we're tracking the character's location, update the region's count
        #   of living and non-living things in the current room
        if (
            ($self->mapWin && ($self->mapWin->mode eq 'follow' || $self->mapWin->mode eq 'update'))
            || (! $self->mapWin && $self->trackAloneFlag)
        ) {
            $self->worldModelObj->countRoomContents($self->session, $modelRoomObj);
        }

        # If the Automapper window is open (and in 'update' room), we can update the room's
        #   properties
        if ($self->mapWin && $self->mapWin->mode eq 'update') {

            $self->worldModelObj->updateRoom(
                $self->session,
                TRUE,                   # Update Automapper windows now
                $modelRoomObj,
                $connectRoomObj,
                $connectExitObj,
                $mapDir,
            );
        }

        # Update complete
        return 1;
    }

    sub autoCompareLocatorRoom {

        # Called by $self->createNewRoom
        # Compares the Locator's current room against all rooms in the same regionmap. Returns a
        #   list of all the matching rooms
        #
        # Expected arguments
        #   $regionmapObj  - The GA::Obj::Regionmap containing the current room
        #
        # Return values
        #   An empty list on improper arguments or if there are no matching rooms
        #   Otherwise returns a list of blessed references to matching GA::ModelObj::Room objects

        my ($self, $regionmapObj, $check) = @_;

        # Local variables
        my (@emptyList, @roomList, @returnList);

        # Check for improper arguments
        if (! defined $regionmapObj || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->autoCompareLocatorRoom', @_);
            return @emptyList;
        }

        # Don't do anything if the Locator task isn't running or doesn't know about the current room
        if (! $self->session->locatorTask || ! $self->session->locatorTask->roomObj) {

            return @emptyList;
        }

        # Get a list of rooms in the same regionmap
        @roomList = $regionmapObj->ivValues('gridRoomHash');
        foreach my $roomNum (@roomList) {

            my ($roomObj, $result);

            $roomObj = $self->worldModelObj->ivShow('modelHash', $roomNum);

            # Compare the two rooms. The TRUE argument means that all rooms that have never been
            #   matched before are matches
            ($result) = $self->worldModelObj->compareRooms($self->session, $roomObj, undef, TRUE);
            if (! $result) {

                # $roomObj matches the Locator's current room
                push (@returnList, $roomObj);
            }
        }

        return @returnList;
    }

    sub checkTempRandomReturn {

        # Called by $self->moveKnownDirSeen and ->moveUnknownDirSeen
        # If the character moved through a 'temp_region' random exit, check the Locator task's
        #   current room. If it matches the random exit's parent room, then there's no need to worry
        #   about updating the map; just move the player back to the original room and destroy the
        #   temporary region
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the situation described above doesn't apply
        #   1 if the the character has been moved back to the original room

        my ($self, $check) = @_;

        # Local variables
        my ($result, $originRoom, $destRoom, $mode);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkTempRandomReturn', @_);
        }

        if (
            ! $self->session->locatorTask
            || ! $self->session->locatorTask->roomObj
            || ! $self->tempRandomOriginRoom
        ) {
            return undef;
        }

        ($result) = $self->worldModelObj->compareRooms($self->session, $self->tempRandomOriginRoom);
        if (! $result) {

            return undef;
        }

        # Reset IVs for the function's we're about to call, keeping a temporary local copy for
        #   ourselves
        $originRoom = $self->tempRandomOriginRoom;
        $destRoom = $self->tempRandomDestRoom;
        $mode = $self->tempRandomMode;

        $self->ivUndef('tempRandomOriginRoom');
        $self->ivUndef('tempRandomDestRoom');
        $self->ivUndef('tempRandomMode');

        # Move the character to the original room
        $self->setCurrentRoom($originRoom);
        # Delete the temporary region we've just moved from
        $self->worldModelObj->deleteRegions(
            $self->session,
            TRUE,               # Update automapper now
            $self->worldModelObj->ivShow('modelHash', $destRoom->parent),
        );

        # If the automapper window is open (and was open, when we first moved through the random
        #   exit), restore its ->mode
        if ($self->mapWin && $mode && $self->mapWin->mode ne $mode) {

            $self->mapWin->setMode($mode);
        }

        # Return 1 so the calling function knows it doesn't have to worry about updating the world
        #   model
        return 1;
    }

    # 'Connect offline' session mode functions

    sub showPseudoStatement {

        # Called by $self->setCurrentRoom and ->pseudoWorldCmd
        # When the current session's ->status is 'offline', we can simulate the room statements that
        #   the user would see, if the character was actually wandering around the world
        # Use the details stored in the current world profile and a specified room model object to
        #   construct a plausible room statement, and display it in the 'main' window
        #
        # Expected arguments
        #   $dictObj        - The session's current dictionary
        #   $modelRoomObj   - A GA::ModelObj::Room in the world model
        #
        # Return values
        #   'undef' on improper arguments or if the current world profile doesn't specify room
        #       statement components for the type of room statement specified by
        #       $self->pseudoStatementMode
        #   Otherwise, returns the display buffer line (matches a key in
        #       GA::Session->displayBufferHash) of the pseudo-statement's anchor line

        my ($self, $dictObj, $modelRoomObj, $check) = @_;

        # Local variables
        my (
            $worldObj, $wmObj, $string, $anchorOffset, $anchorNum, $bufferAnchorNum,
            @componentList, @lineList,
        );

        # Check for improper arguments
        if (! defined $dictObj || ! defined $modelRoomObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showPseudoStatement', @_);
        }

        # Import the current world profile and world model object (for convenience)
        $worldObj = $self->session->currentWorld;
        $wmObj = $self->session->worldModelObj;

        # A string to display after the title or verbose descrip components
        $string = ' [';
        if ($modelRoomObj->roomTag) {

            if ($wmObj->capitalisedRoomTagFlag) {
                $string .= uc($modelRoomObj->roomTag) . ' ';
            } else {
                $string .= $modelRoomObj->roomTag . ' ';
            }
        }

        $string .= '#' . $modelRoomObj->number . ']';

        # Import a list of room statement components for the type of statement specified by
        #   $self->pseudoStatementMode
        if ($self->pseudoStatementMode eq 'verbose') {

            @componentList = $worldObj->verboseComponentList;
            $anchorOffset = $worldObj->verboseAnchorOffset;

        } elsif ($self->pseudoStatementMode eq 'short') {

            @componentList = $worldObj->shortComponentList;
            $anchorOffset = $worldObj->shortAnchorOffset;

        } elsif ($self->pseudoStatementMode eq 'brief') {

            @componentList = $worldObj->briefComponentList;
            $anchorOffset = $worldObj->briefAnchorOffset;
        }

        if (! @componentList) {

            # No room statement components have been specified for this type of room statement
            return undef;
        }

        # Process each component in turn, constructing a plausible statement constisting of one or
        #   more lines stored in @lineList
        OUTER: foreach my $component (@componentList) {

            my (
                $componentObj, $lightStatus, $matchFlag, $titleString, $exitString, $delim,
                @descripList, @abbrevList,
            );

            # $component can be any custom-named key in GA::Profile::World->componentHash; get the
            #   corresponding GA::Obj::Component object
            $componentObj = $worldObj->ivShow('componentHash', $component);

            if ($component eq 'anchor') {

                # We need to remember which line in @lineList is the anchor line.
                if ($anchorOffset == -1) {

                    # The anchor line shares a line with the component before it
                    $anchorNum = scalar @lineList;

                } else {

                    # The anchor line shares a line with the component after it, or is on its own
                    #   line
                    $anchorNum = (scalar @lineList + 1);
                }

            } elsif ($componentObj->type eq 'verb_title' || $componentObj->type eq 'brief_title') {

                # Use the first available room title
                if ($modelRoomObj->titleList) {
                    push (@lineList, $modelRoomObj->ivFirst('titleList') . $string);
                } else {
                    push (@lineList, '<no room title>' . $string);
                }

                # (Only show $string once)
                $string = '';

            } elsif ($componentObj->type eq 'verb_descrip') {

                if ($modelRoomObj->descripHash) {

                    # Use the verbose description matching the current light status; otherwise, use
                    #   the first verbose description matching a standard light status if possible.
                    #   If all else fails, use a random verbose description
                    $lightStatus = $wmObj->lightStatus;
                    if ($modelRoomObj->ivExists('descripHash', $lightStatus)) {

                        push (
                            @lineList,
                            $modelRoomObj->ivShow('descripHash', $lightStatus) . $string,
                        );

                    } else {

                        INNER: foreach my $otherStatus ($wmObj->lightStatusList) {

                            if ($modelRoomObj->ivExists('descripHash', $otherStatus)) {

                                push (
                                    @lineList,
                                    $modelRoomObj->ivShow('descripHash', $otherStatus),
                                );

                                $matchFlag = TRUE;
                                last INNER;
                            }
                        }

                        if (! $matchFlag) {

                            # Use a random description
                            @descripList = $modelRoomObj->ivValues('descripHash');
                            push (@lineList, $descripList[0] . $string);
                        }
                    }

                } else {

                    push (@lineList, '<no verbose description>' . $string);
                }

                # (Only show $string once)
                $string = '';

            } elsif ($componentObj->type eq 'verb_exit') {

                $exitString = 'Exits: ';

                if ($modelRoomObj->sortedExitList) {
                    $exitString .= join(', ', $modelRoomObj->sortedExitList);
                } else {
                    $exitString .= '<no exits>';
                }

                push (@lineList, $exitString);

            } elsif (
                $componentObj->type eq 'verb_content'
                || $componentObj->type eq 'brief_content'
            ) {
                # No way to tell whether the patterns in GA::Profile::World->contentPatternList
                #   appear at the beginning of a line, in the middle or at the end, so just display
                #   a straight list of objects
                INNER: foreach my $number ($modelRoomObj->ivKeys('childHash')) {

                    my $obj = $wmObj->ivShow('modelHash', $number);

                    if ($obj->baseString) {
                        push(@lineList, ucfirst ($obj->name) . ' (' . $obj->baseString . ')');
                    } elsif ($obj->name) {
                        push (@lineList, ucfirst($obj->name));
                    }
                }

            } elsif (
                $componentObj->type eq 'brief_exit'
                || $componentObj->type eq 'brief_title_exit'
                || $componentObj->type eq 'brief_exit_title'
            ) {
                # Get a room title and an exit list, then combine them into a single string, in the
                #   right order
                $titleString = '';
                $exitString = '';

                # Use the first available room title
                if ($modelRoomObj->titleList) {
                    $titleString = $modelRoomObj->ivFirst('titleList');
                } else {
                    $titleString = '<no room title>';
                }

                # Get a list of exits
                if ($worldObj->briefExitDelimiterList) {
                    $delim = $worldObj->ivFirst('briefExitDelimiterList');
                } else {
                    $delim = ' ';       # Last resort - use a space between exits
                }

#                if ($worldObj->briefExitLeftMarkerList) {
#
#                    $exitString .= $worldObj->ivFirst('briefExitLeftMarkerList');
#                }

                if ($modelRoomObj->sortedExitList) {

                    # Convert exits to their abbreviated forms, if possible
                    foreach my $exitName ($modelRoomObj->sortedExitList) {

                        push (@abbrevList, $dictObj->abbrevDir($exitName));
                    }

                    $exitString .= join($delim, @abbrevList);

                } else {

                    $exitString .= '<no exits>';
                }

#                if ($worldObj->briefExitRightMarkerList) {
#
#                    $exitString .= $worldObj->ivFirst('briefExitRightMarkerList');
#                }

                # Combine the strings in the right order
                if ($componentObj->type eq 'brief_exit') {
                    push (@lineList, $exitString);
                } elsif ($componentObj->type eq 'brief_title_exit') {
                    push (@lineList, $titleString . ' / ' . $exitString);
                } elsif ($componentObj->type eq 'brief_exit_title') {
                    push (@lineList, $exitString . ' / ' . $titleString);
                }

            } elsif ($componentObj->type eq 'mudlib_path') {

                if ($modelRoomObj->sourceCodePath) {
                    push (@lineList, $modelRoomObj->sourceCodePath);
                } else {
                    push (@lineList, '<no path>');
                }
            }
        }

        if (@lineList) {

            # Insert an empty line, so that there's a gap between room statements
            $self->session->processIncomingData(" \n");

            # Display the pseudo-room statement in the 'main' window
            for (my $count = 0; $count < scalar @lineList; $count++) {

                my $line = $lineList[$count];

                # If the regexes used to compose $line used an initial ^ or a final $ character,
                #   remove them
                if (substr($line, 0, 1) eq '^') {

                    $line = substr($line, 1);
                }

                # Also swap any '\ ' special characters for plain spaces
                $line =~ s/\\ / /g;

                if (substr($line, -1, 1) eq '$') {

                    $line = substr($line, 0, ((length $line) - 1));
                }

                $self->session->processIncomingData("$line\n");

                if ($count == $anchorNum) {

                    # This was the anchor line; remember the line's number in the display buffer
                    $bufferAnchorNum = $self->session->displayBufferCount;
                }
            }

        } else {

            # If all else fails, show this bare-bones room statement
            $self->session->processIncomingData(
                '<current room #' . $modelRoomObj->number . ' \'' . $modelRoomObj->name . "\'>\n",
            );
        }

        if (! defined $bufferAnchorNum) {

            # As an emergency fallback, use the last line of the pseudo-statement as the anchor line
            $bufferAnchorNum = $self->session->displayBufferCount;
        }

        return $bufferAnchorNum;
    }

    sub pseudoWorldCmd {

        # Called by GA::Session->dispatchCmd, ->checkRedirect or ->checkAssisted, when the
        #   session's status is 'offline', and when this automapper has a ->currentRoom set
        # The most recently-processed world command has been stored in the session's command buffer;
        #   the buffer object may consist of one or more commands, depending on whether assisted
        #   moves were processed
        # If the world command from which the buffer object was created (i.e. the command after
        #   processing by aliases, but before processing by redirect mode / assisted moves) matches
        #   any of the current room's exits, simulate a move using that exit
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $cmdObj - The GA::Buffer::Cmd object created for the world command. If 'undef', this
        #               function finds it
        #
        # Return values
        #   'undef' on improper arguments or if no simulated move occurs
        #   1 otherwise

        my ($self, $cmdObj, $check) = @_;

        # Local variables
        my (
            $dictObj, $tempType, $dir, $exitObj, $primaryDir, $dirType, $exitNum, $destRoomObj,
            $msg, $anchorLine,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pseudoWorldCmd', @_);
        }

        # Find the command buffer object, if not specified
        if (! $cmdObj) {

            $cmdObj = $self->session->ivShow(
                'cmdBufferHash',
                $self->session->cmdBufferLast,
            );
        }

        # Import the current dictionary
        $dictObj = $self->session->currentDict;

        # (The rest of the function is adapted from $self->moveKnownDirSeen)

        # Do nothing if:
        #   1. The Automapper window is open and is in 'wait' mode
        #   2. The Automapper window isn't open, and $self->trackAloneFlag is FALSE
        #   3. The current room isn't known (regardless of whether the Automapper window is open)
        #   4. The command buffer object wasn't created by a look, glance or movement command
        if (
            ($self->mapWin && $self->mapWin->mode eq 'wait')
            || (! $self->mapWin && ! $self->trackAloneFlag)
            || ! $self->currentRoom
            || (! $cmdObj->moveFlag && ! $cmdObj->lookFlag && ! $cmdObj->glanceFlag)
        ) {
            return undef;
        }

        # For look/glance commands, re-display the current room's pseudo-room statement
        if ($cmdObj->lookFlag || $cmdObj->glanceFlag) {

            # Temporarily alter the value stored in $self->pseudoStatementMode, so that we can show
            #   a verbose (or short verbose) room statement in response to a 'look' command, and
            #   a brief statement in response to a 'glance' command (but only if those types of
            #   room statement are available in the current world profile)
            if (
                ($self->pseudoStatementMode eq 'verbose' || $self->pseudoStatementMode eq 'short')
                && $cmdObj->glanceFlag
                && $self->session->currentWorld->briefComponentList
            ) {
                $tempType = $self->pseudoStatementMode;
                $self->ivPoke('pseudoStatementMode', 'brief')

            } elsif (
                $self->pseudoStatementMode eq 'brief'
                && $cmdObj->lookFlag
                && $self->session->currentWorld->verboseComponentList
            ) {
                $tempType = 'brief';
                $self->ivPoke('pseudoStatementMode', 'verbose')
            }

            $anchorLine = $self->showPseudoStatement($dictObj, $self->currentRoom);
            if (! defined $anchorLine) {

                # Could not produce a pseudo-room statement because no room statement components
                #   of the statement type specified by $self->pseudoStatementMode are available.
                # In this unlikely situation, mark the character as lost
                return $self->setCurrentRoom(undef, $self->_objClass . '->pseudoWorldCmd');
            }

            # The Locator task normally creates a non-model room when it spots a room statement.
            #   Instruct it create a non-model room based on $newRoomObj, and tell it to not look
            #   for room statements in the text just displayed by the call to ->showPseudoStatement
            # (It's necessary to do this, even though the new non-model room will probably be
            #   identical to the first one - it stops the Locator from looking for anchor lines
            #   in the text produced by the call to ->showPseudoStatement)
            $self->session->locatorTask->usePseudoStatement(
                $dictObj,
                $self->currentRoom,
                $anchorLine,
            );

            # Restore the old value of $self->pseudoStatementMode, if it was temporarily changed
            if (defined $tempType) {

                $self->ivPoke('pseudoStatementMode', $tempType);
            }

            return 1;
        }

        # Set $dir, the direction of movement, so that we can work out which exit object is being
        #   used. For assisted moves, we already know the exit object used (which will save us some
        #   time)
        if ($cmdObj->assistedFlag) {

            $dir = $cmdObj->cmd;
            $exitObj = $cmdObj->assistedExitObj;
            $primaryDir = $cmdObj->assistedPrimary;

        } else {

            # For redirect mode commands, use the original command, which should contain only a
            #   direction
            if ($cmdObj->redirectFlag) {

                $dir = $cmdObj->cmd;

            # For normal movement commands, the direction of movement has been stripped from
            #   $cmdObj->cmd and stored in ->moveDir
            } else {

                $dir = $cmdObj->moveDir;
            }

            # If $dir is a primary direction, get the standard primary direction
            if ($dictObj->ivExists('combDirHash', $dir)) {

                $dirType = $dictObj->ivShow('combDirHash', $dir);
                if ($dirType eq 'primaryDir' || $dirType eq 'primaryAbbrev') {

                    $primaryDir = $dictObj->ivShow('combRevDirHash', $dir);
                }
            }

            # Check the current room's exits. Does an exit in this direction already exist?
            if ($self->currentRoom->ivExists('exitNumHash', $dir)) {

                $exitNum = $self->currentRoom->ivShow('exitNumHash', $dir);
                $exitObj = $self->worldModelObj->ivShow('exitModelHash', $exitNum);

            # Otherwise, if $dir is a primary direction, see if an existing exit from the current
            #   room has the same drawn map direction
            } elsif ($primaryDir) {

                OUTER: foreach my $number ($self->currentRoom->ivValues('exitNumHash')) {

                    my $otherExitObj = $self->worldModelObj->ivShow('exitModelHash', $number);

                    if (
                        $otherExitObj->mapDir
                        && $otherExitObj->mapDir eq $primaryDir
                        #   Don't leave using an exit attached to a shadow exit; leave via the
                        #   shadow exit instead)
                        && (! $otherExitObj->shadowExit)
                    ) {
                        $exitObj = $otherExitObj;
                        last OUTER;
                    }
                }
            }
        }

        if (! $exitObj) {

            # Failsafe - do nothing if no exit found
            return undef;

        # In 'connect offline' mode, movements through exits which are marked impassable, which are
        #   random exits or which have no destination room mean that the character is now 'lost'
        } elsif (
            $exitObj->exitOrnament eq 'impass'
            || $exitObj->randomType ne 'none'
            || ! $exitObj->destRoom
        ) {
            # Show an explanation, if allowed
            if ($self->worldModelObj->explainGetLostFlag) {

                if ($exitObj->exitOrnament eq 'impass') {

                    $msg = 'MAP: Lost because the character used an exit marked as \'impassable\'';

                } elsif ($exitObj->randomType ne 'none') {

                    $msg = 'MAP: Lost because the character used a random exit while in \'connect'
                            . ' offline\' mode';

                } else {

                    $msg = 'MAP: Lost because the character used an exit with no destination in'
                            . ' \'connect offline\' mode';
                }

                $self->session->writeText($msg);
            }

            # The TRUE argument means 'the character is lost'
            return $self->setCurrentRoom(
                undef,
                $self->_objClass . '->pseudoWorldCmd',    # Defined string marks character as lost
            );

        } else {

            # Get the destination room
            $destRoomObj = $self->worldModelObj->ivShow('modelHash', $exitObj->destRoom);
            # Simulate the world sending the new room statement to us
            $anchorLine = $self->showPseudoStatement($dictObj, $destRoomObj);

            # The Locator task normally creates a non-model room when it spots a room statement.
            #   Instruct it create a non-model room based on $newRoomObj, and tell it to not look
            #   for room statements in the text just displayed by the call to ->showPseudoStatement
            $self->session->locatorTask->usePseudoStatement($dictObj, $destRoomObj, $anchorLine);
            # $destRoomObj is the new location
            $self->setCurrentRoom($destRoomObj);

            return 1;
        }
    }

    ##################
    # Accessors - set

    sub set_mapWin {

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_mapWin', @_);
        }

        # Update IVs
        $self->ivPoke('mapWin', $winObj);       # Can be 'undef'

        return 1;
    }

    sub set_pseudoStatementMode {

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_pseudoStatementMode',
                @_,
            );
        }

        if ($mode ne 'verbose' && $mode ne 'short' && $mode ne 'brief') {

            return undef;

        } else {

            $self->ivPoke('pseudoStatementMode', $mode);
            return 1;
        }
    }

    sub reset_tempRandom {

        # Called by GA::Obj::WorldModel->deleteObj, when a room matching one of the following IVs
        #   is deleted
        # In that case, we can forget about returning to the original location

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_tempRandom', @_);
        }

        # Just reset the IVs and forget about them
        $self->ivUndef('tempRandomOriginRoom');
        $self->ivUndef('tempRandomDestRoom');
        $self->ivUndef('tempRandomMode');

        return 1;
    }

    sub set_trackAloneFlag {

        # Called by GA::Win::Map to make sure the value of $self->trackAloneFlag is correct when
        #   the window opens/closes

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_trackAloneFlag', @_);
        }

        # If the character previously moved through a 'temp_region' random exit into a temporary
        #   region, we can simply delete the temporary region when the automapper window closes
        if ($self->tempRandomOriginRoom) {

            # Delete the temporary region. If $self->currentRoom was in that region, it's reset too
            $self->worldModelObj->deleteRegions(
                $self->session,
                FALSE,               # Don't update automapper yet
                $self->worldModelObj->ivShow('modelHash', $self->tempRandomDestRoom->parent),
            );

            # Reset IVs
            $self->ivUndef('tempRandomOriginRoom');
            $self->ivUndef('tempRandomDestRoom');
            $self->ivUndef('tempRandomMode');

            # There's no longer any position to track
            $flag = FALSE;
        }

        if ($flag) {
            $self->ivPoke('trackAloneFlag', TRUE);
        } else {
            $self->ivPoke('trackAloneFlag', FALSE);
        }

        return 1;
    }

    sub set_worldModelObj {

        my ($self, $worldModelObj, $check) = @_;

        # Check for improper arguments
        if (! defined $worldModelObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_worldModelObj', @_);
        }

        $self->ivPoke('worldModelObj', $worldModelObj);

        # Reset the current room
        $self->setCurrentRoom();

        # Inform the Automapper window, if it is open
        if ($self->mapWin) {

            $self->mapWin->set_worldModelObj($worldModelObj);
        }

        return 1;
    }

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }
    sub worldModelObj
        { $_[0]->{worldModelObj} }
    sub mapWin
        { $_[0]->{mapWin} }

    sub currentRoom
        { $_[0]->{currentRoom} }
    sub lastKnownRoom
        { $_[0]->{lastKnownRoom} }
    sub ghostRoom
        { $_[0]->{ghostRoom} }

    sub trackAloneFlag
        { $_[0]->{trackAloneFlag} }
    sub pseudoStatementMode
        { $_[0]->{pseudoStatementMode} }

    sub tempRandomOriginRoom
        { $_[0]->{tempRandomOriginRoom} }
    sub tempRandomDestRoom
        { $_[0]->{tempRandomDestRoom} }
    sub tempRandomMode
        { $_[0]->{tempRandomMode} }
}

# Package must return a true value
1
