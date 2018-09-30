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
# Games::Axmud::Obj::Zonemap
# A zonemap is a plan for arranging windows on a workspace grid which has been split into one or
#   more zones

{ package Games::Axmud::Obj::Zonemap;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->createStandardZonemaps or GA::Cmd::AddZonemap->new
        # Creates a new zonemap which consists of a 60x60 grid (a size which is hard-coded and
        #   cannot be changed). The coordinates of the top-left corner of the grid are (0,0), and
        #   the coordinates of the bottom-right corner are (59,59)
        # The grid is divided into GA::ZoneModel objects 'zone models', blueprints for real
        #   GA::Obj::Zone objects when they are created
        # Because the blocks of a zonemap grid are an arbitrary size, the zonemap can be applied to
        #   a workspace of any size
        #
        # Expected arguments
        #   $name           - A unique name for the zonemap (max 16 chars)
        #
        # Optional arguments
        #   $tempFlag       - Set to TRUE if this is a temporary zonemap just for this $session,
        #                       that isn't saved and can't be modified by the user. If set to FALSE
        #                       (or 'undef'), a normal zonemap
        #   $tempSession    - For temporary zonemaps, the parent GA::Session ('undef' for normal
        #                       zonemaps)
        #
        # Notes
        #   GA::Client->constZonemapHash defines some standard zonemaps with names like 'single',
        #       'basic', 'extended', 'widescreen', 'horizontal', 'vertical'
        #   Calling $self->new with $name set to one of the defined strings will fill the zonemap
        #       with zones; otherwise the zonemap remains empty until some other code fills it
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $name, $tempFlag, $tempSession, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that the zonemap name is unique and isn't too long
        if ($axmud::CLIENT->ivExists('zonemapHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: zonemap \'' . $name . '\' already exists',
                $class . '->new',
            );

        } elsif (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: illegal name \'' . $name . '\'',
                $class . '->new',
            );
        }

        # Set default IV values
        if (! defined $tempFlag) {

            $tempFlag = FALSE;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _parentFile                 => 'zonemaps',
            _parentWorld                => undef,
            _objClass                   => $class,
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # A unique name for the zonemap
            name                        => $name,

            # The size of the zonemap grid (cannot be changed)
            gridSize                    => 60,
            # Hash of zone model objects associated with this map, in the form
            #   $modelHash{number} = blessed_reference_to_zone_model_object
            modelHash                   => {},
            # Number of zone models ever created for this zonemap (used to give every zone model
            #   object a number unique to the zonemap)
            modelCount                  => 0,
            # Flag set to TRUE when the zonemap becomes full
            fullFlag                    => FALSE,

            # Some code (such as the MXP protocol) requires temporary zonemaps
            # Temporary zonemaps are not saved by GA::Obj::File->saveDataFile, nor can they be
            #   modified by the user
            tempFlag                    => $tempFlag,
            # For temporary zonemaps, the GA::Session which created them is the only session which
            #   is allowed to use them, and is stored here. Set to 'undef' for non-temporary
            #   zonemaps (set below)
            tempSession                 => $tempSession,
        };

        # Bless the object into existence
        bless $self, $class;

        # Set up the zonemap to its default (empty) state
        $self->resetZonemap();

        # If this is a standard zonemap, auto-create some zone models within the zonemap
        if ($axmud::CLIENT->ivExists('constZonemapHash', $name)) {

            if (! $self->setupStandardZonemap()) {

                return $axmud::CLIENT->writeError(
                    'Can\'t set up the standard zonemap \'' . $name . '\' - error creating zone'
                    . ' models',
                    $class . '->new',
                );
            }
        }

        return $self;
    }

    sub clone {

        # Called by GA::Cmd::CloneZonemap->do
        # Create a clone of an existing zonemap
        #
        # Expected arguments
        #   $name       - A name for the new zonemap (max 16 chars)
        #
        # Return values
        #   'undef' on improper arguments, if $name is invalid or if this zonemap is a temporary
        #       zonemap (which can't be cloned)
        #   Blessed reference to the newly-created object on success

        my ($self, $name, $check) = @_;

        # Local variables
        my ($count, $updateName);

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Check that the zonemap name is unique and isn't too long
        if ($axmud::CLIENT->ivExists('zonemapHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: zonemap \'' . $name . '\' already exists',
                $self . '->clone',
            );

        } elsif (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: illegal name \'' . $name . '\'',
                $self . '->clone',
            );

        } elsif ($self->tempFlag) {

            return $axmud::CLIENT->writeError(
                'Temporary zonemaps cannot be cloned',
                $self . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _parentFile                 => 'zonemaps',
            _parentWorld                => undef,
            _objClass                   => $self->_objClass,
            _privFlag                   => TRUE,        # All IVs are private

            name                        => $name,

            gridSize                    => $self->gridSize,
            modelHash                   => {},          # Set below
            modelCount                  => undef,       # Set below
            fullFlag                    => $self->fullFlag,

            tempFlag                    => undef,
            tempSession                 => undef,
        };

        # Bless the new zonemap into existence
        bless $clone, $self->_objClass;

        # Clone the zone models, in order. For example, if the old zonemap had zone models numbered
        #   (0, 1, 4, 7), in the new zonemap the cloned zone models are numbered (0, 1, 2, 3)
        $count = 0;
        foreach my $oldModelObj (sort {$a->number <=> $b->number} ($self->ivValues('modelHash'))) {

            my $cloneModelObj;

            $cloneModelObj = $oldModelObj->clone($self, $count);
            $clone->ivAdd('modelHash', $count, $cloneModelObj);

            $count++;
        }

        $clone->ivPoke('modelCount', $count);

        # If the original and clone are both standard zonemaps, it's because the clone needs to
        #   have its zone models modified to allow multiple layers
        $updateName = $axmud::CLIENT->ivShow('constZonemapHash', $self->name);
        if ($updateName && $updateName eq $name) {

            $clone->modifyStandardZonemap();
        }

        return $clone;
    }

    ##################
    # Methods

    sub setupStandardZonemap {

        # Called by $self->new whenever the specified name of the zonemap is one of the standard
        #   zonemaps defined by GA::Client->constZonemapHash
        # (Could be called by any other function in order to reset a standard zonemap, probably
        #   after a call to $self->resetZonemap)
        # Sets up some types of standard zonemap with their zone models; other types of standard
        #   zonemap are cloned from these ones
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if $name isn't one of the standard zonemap names or if
        #       any of the zone models can't be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $zone, $otherZone, $zoneLeft, $zoneRight, $zoneUpperLeft, $zoneLowerLeft,
            $zoneUpperRight, $zoneCentreRight, $zoneLowerRight,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupStandardZonemap', @_);
        }

        if ($self->name eq 'single') {

            #   'single' - The entire workspace is covered by a single zone. Windows (even 'main'
            #       windows) use their default sizes. Windows cannot be stacked above each other

            #   111111111111
            #   111111111111
            #   111111111111
            #   111111111111
            #   111111111111
            #   111111111111
            #   111111111111
            #   111111111111
            #   111111111111
            #   111111111111
            #   111111111111
            #   111111111111

            $zone = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zone) {

                # Zone model couldn't be created
                return undef;
            }

            $zone->{'left'} = 0;
            $zone->{'right'} = 59;
            $zone->{'top'} = 0;
            $zone->{'bottom'} = 59;
            $zone->{'width'} = 60;
            $zone->{'height'} = 60;

            $zone->{'reservedFlag'} = FALSE;
            $zone->{'multipleLayerFlag'} = FALSE;

            $zone->{'startCorner'} = 'top_left';
            $zone->{'orientation'} = 'horizontal';

            $zone->{'areaMax'} = 0;
            $zone->{'visibleAreaMax'} = 0;
            $zone->{'defaultAreaWidth'} = 0;
            $zone->{'defaultAreaHeight'} = 0;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zone);

        } elsif ($self->name eq 'basic') {

            #   'basic' - Intended for use when $self->shareMainWinFlag = TRUE. There are two zones.
            #       The first zone covers the left-hand 2/3 of the workspace and is reserved for a
            #       single 'main' window. The other zone covers the right-hand 1/3 of the workspace
            #       and is available for all 'grid' windows (and only those windows can be stacked
            #       above each other). The first 'main' window expands to fill the whole of its
            #       zone. Other windows use their default sizes

            #   111111112222
            #   111111112222
            #   111111112222
            #   111111112222
            #   111111112222
            #   111111112222
            #   111111112222
            #   111111112222
            #   111111112222
            #   111111112222
            #   111111112222
            #   111111112222

            # Left-hand zone
            # ==============

            $zoneLeft = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneLeft) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneLeft->{'left'} = 0;
            $zoneLeft->{'right'} = 39;
            $zoneLeft->{'top'} = 0;
            $zoneLeft->{'bottom'} = 59;
            $zoneLeft->{'width'} = 40;
            $zoneLeft->{'height'} = 60;

            $zoneLeft->{'reservedFlag'} = TRUE;
            $zoneLeft->ivAdd('reservedHash', 'main', 'main');
            $zoneLeft->{'multipleLayerFlag'} = FALSE;

            $zoneLeft->{'startCorner'} = 'top_left';
            $zoneLeft->{'orientation'} = 'vertical';

            $zoneLeft->{'areaMax'} = 1;
            $zoneLeft->{'visibleAreaMax'} = 1;
            $zoneLeft->{'defaultAreaWidth'} = 40;
            $zoneLeft->{'defaultAreaHeight'} = 60;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneLeft);

            # Right-hand zone
            # ===============

            $zoneRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneRight->{'left'} = 40;
            $zoneRight->{'right'} = 59;
            $zoneRight->{'top'} = 0;
            $zoneRight->{'bottom'} = 59;
            $zoneRight->{'width'} = 20;
            $zoneRight->{'height'} = 60;

            $zoneRight->{'reservedFlag'} = FALSE;
            $zoneRight->{'multipleLayerFlag'} = TRUE;

            $zoneRight->{'startCorner'} = 'top_left';
            $zoneRight->{'orientation'} = 'vertical';

            $zoneRight->{'areaMax'} = 0;
            $zoneRight->{'visibleAreaMax'} = 3;
            $zoneRight->{'defaultAreaWidth'} = 20;
            $zoneRight->{'defaultAreaHeight'} = 20;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneRight);

        } elsif ($self->name eq 'extended') {

            #   'extended' - Intended for use when $self->shareMainWinFlag = TRUE. The left-hand 2/3
            #       of the workspace is reserved for a single 'main' window and the Status and
            #       Locator task windows. The task windows go above the first 'main' window; the
            #       Status window is to the left of the Locator window.  The right-hand 1/3 of the
            #       workspace is reserved for a single 'map' window at the top half and any other
            #       'grid' windows at the bottom half (and only those windows can be stacked above
            #       each other)

            #   222222223333
            #   222222223333
            #   222222223333
            #   222222223333
            #   111111113333
            #   111111113333
            #   111111114444
            #   111111114444
            #   111111114444
            #   111111114444
            #   111111114444
            #   111111114444

            # Lower left-hand zone
            # ====================

            $zoneLowerLeft = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneLowerLeft) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneLowerLeft->{'left'} = 0;
            $zoneLowerLeft->{'right'} = 39;
            $zoneLowerLeft->{'top'} = 20;
            $zoneLowerLeft->{'bottom'} = 59;
            $zoneLowerLeft->{'width'} = 40;
            $zoneLowerLeft->{'height'} = 40;

            $zoneLowerLeft->{'reservedFlag'} = TRUE;
            $zoneLowerLeft->ivAdd('reservedHash', 'main', 'main');
            $zoneLowerLeft->{'multipleLayerFlag'} = FALSE;

            $zoneLowerLeft->{'startCorner'} = 'top_left';
            $zoneLowerLeft->{'orientation'} = 'horizontal';

            $zoneLowerLeft->{'areaMax'} = 1;
            $zoneLowerLeft->{'visibleAreaMax'} = 1;
            $zoneLowerLeft->{'defaultAreaWidth'} = 40;
            $zoneLowerLeft->{'defaultAreaHeight'} = 40;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneLowerLeft);

            # Upper left-hand zone
            # ====================

            $zoneUpperLeft = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneUpperLeft) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneUpperLeft->{'left'} = 0;
            $zoneUpperLeft->{'right'} = 39;
            $zoneUpperLeft->{'top'} = 0;
            $zoneUpperLeft->{'bottom'} = 19;
            $zoneUpperLeft->{'width'} = 40;
            $zoneUpperLeft->{'height'} = 20;

            $zoneUpperLeft->{'reservedFlag'} = TRUE;
            $zoneUpperLeft->ivAdd('reservedHash', 'status_task', 'custom');
            $zoneUpperLeft->ivAdd('reservedHash', 'locator_task', 'custom');
            $zoneUpperLeft->{'multipleLayerFlag'} = FALSE;

            $zoneUpperLeft->{'startCorner'} = 'top_left';
            $zoneUpperLeft->{'orientation'} = 'horizontal';

            $zoneUpperLeft->{'areaMax'} = 2;
            $zoneUpperLeft->{'visibleAreaMax'} = 2;
            $zoneUpperLeft->{'defaultAreaWidth'} = 20;
            $zoneUpperLeft->{'defaultAreaHeight'} = 20;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneUpperLeft);

            # Upper right-hand zone
            # =====================

            $zoneUpperRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneUpperRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneUpperRight->{'left'} = 40;
            $zoneUpperRight->{'right'} = 59;
            $zoneUpperRight->{'top'} = 0;
            $zoneUpperRight->{'bottom'} = 29;
            $zoneUpperRight->{'width'} = 20;
            $zoneUpperRight->{'height'} = 30;

            $zoneUpperRight->{'reservedFlag'} = TRUE;
            $zoneUpperRight->ivAdd('reservedHash', 'map', 'map');
            $zoneUpperRight->{'multipleLayerFlag'} = FALSE;

            $zoneUpperRight->{'startCorner'} = 'top_left';
            $zoneUpperRight->{'orientation'} = 'vertical';

            $zoneUpperRight->{'areaMax'} = 1;
            $zoneUpperRight->{'visibleAreaMax'} = 1;
            $zoneUpperRight->{'defaultAreaWidth'} = 20;
            $zoneUpperRight->{'defaultAreaHeight'} = 30;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneUpperRight);

            # Lower right-hand zone
            # =====================

            $zoneLowerRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneLowerRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneLowerRight->{'left'} = 40;
            $zoneLowerRight->{'right'} = 59;
            $zoneLowerRight->{'top'} = 30;
            $zoneLowerRight->{'bottom'} = 59;
            $zoneLowerRight->{'width'} = 20;
            $zoneLowerRight->{'height'} = 30;

            $zoneLowerRight->{'reservedFlag'} = FALSE;
            $zoneLowerRight->{'multipleLayerFlag'} = TRUE;

            $zoneLowerRight->{'startCorner'} = 'top_left';
            $zoneLowerRight->{'orientation'} = 'vertical';

            $zoneLowerRight->{'areaMax'} = 0;
            $zoneLowerRight->{'visibleAreaMax'} = 2;
            $zoneLowerRight->{'defaultAreaWidth'} = 20;
            $zoneLowerRight->{'defaultAreaHeight'} = 15;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneLowerRight);

        } elsif ($self->name eq 'widescreen') {

            #   'widescreen' - A modified version of 'extended' for widescreen monitors, with the
            #       the workspace divided into halves, rather than a 2/3 - 1/3 split

            #   222222333333
            #   222222333333
            #   222222333333
            #   222222333333
            #   111111333333
            #   111111333333
            #   111111444444
            #   111111444444
            #   111111444444
            #   111111555555
            #   111111555555
            #   111111555555

            # Lower left-hand zone
            # ====================

            $zoneLowerLeft = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneLowerLeft) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneLowerLeft->{'left'} = 0;
            $zoneLowerLeft->{'right'} = 29;
            $zoneLowerLeft->{'top'} = 20;
            $zoneLowerLeft->{'bottom'} = 59;
            $zoneLowerLeft->{'width'} = 30;
            $zoneLowerLeft->{'height'} = 40;

            $zoneLowerLeft->{'reservedFlag'} = TRUE;
            $zoneLowerLeft->ivAdd('reservedHash', 'main', 'main');
            $zoneLowerLeft->{'multipleLayerFlag'} = FALSE;

            $zoneLowerLeft->{'startCorner'} = 'top_left';
            $zoneLowerLeft->{'orientation'} = 'horizontal';

            $zoneLowerLeft->{'areaMax'} = 1;
            $zoneLowerLeft->{'visibleAreaMax'} = 1;
            $zoneLowerLeft->{'defaultAreaWidth'} = 30;
            $zoneLowerLeft->{'defaultAreaHeight'} = 40;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneLowerLeft);

            # Upper left-hand zone
            # ====================

            $zoneUpperLeft = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneUpperLeft) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneUpperLeft->{'left'} = 0;
            $zoneUpperLeft->{'right'} = 29;
            $zoneUpperLeft->{'top'} = 0;
            $zoneUpperLeft->{'bottom'} = 19;
            $zoneUpperLeft->{'width'} = 30;
            $zoneUpperLeft->{'height'} = 20;

            $zoneUpperLeft->{'reservedFlag'} = TRUE;
            $zoneUpperLeft->ivAdd('reservedHash', 'status_task', 'custom');
            $zoneUpperLeft->ivAdd('reservedHash', 'locator_task', 'custom');
            $zoneUpperLeft->{'multipleLayerFlag'} = FALSE;

            $zoneUpperLeft->{'startCorner'} = 'top_left';
            $zoneUpperLeft->{'orientation'} = 'horizontal';

            $zoneUpperLeft->{'areaMax'} = 2;
            $zoneUpperLeft->{'visibleAreaMax'} = 2;
            $zoneUpperLeft->{'defaultAreaWidth'} = 15;
            $zoneUpperLeft->{'defaultAreaHeight'} = 20;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneUpperLeft);

            # Upper right-hand zone
            # =====================

            $zoneUpperRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneUpperRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneUpperRight->{'left'} = 30;
            $zoneUpperRight->{'right'} = 59;
            $zoneUpperRight->{'top'} = 0;
            $zoneUpperRight->{'bottom'} = 29;
            $zoneUpperRight->{'width'} = 30;
            $zoneUpperRight->{'height'} = 30;

            $zoneUpperRight->{'reservedFlag'} = TRUE;
            $zoneUpperRight->ivAdd('reservedHash', 'map', 'map');
            $zoneUpperRight->{'multipleLayerFlag'} = FALSE;

            $zoneUpperRight->{'startCorner'} = 'top_left';
            $zoneUpperRight->{'orientation'} = 'vertical';

            $zoneUpperRight->{'areaMax'} = 1;
            $zoneUpperRight->{'visibleAreaMax'} = 1;
            $zoneUpperRight->{'defaultAreaWidth'} = 30;
            $zoneUpperRight->{'defaultAreaHeight'} = 30;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneUpperRight);

            # Centre right-hand zone 1
            # ========================

            $zoneCentreRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneCentreRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneCentreRight->{'left'} = 30;
            $zoneCentreRight->{'right'} = 59;
            $zoneCentreRight->{'top'} = 30;
            $zoneCentreRight->{'bottom'} = 44;
            $zoneCentreRight->{'width'} = 30;
            $zoneCentreRight->{'height'} = 15;

            $zoneCentreRight->{'reservedFlag'} = FALSE;
            $zoneCentreRight->{'multipleLayerFlag'} = TRUE;

            $zoneCentreRight->{'startCorner'} = 'top_left';
            $zoneCentreRight->{'orientation'} = 'horizontal';

            $zoneCentreRight->{'areaMax'} = 0;
            $zoneCentreRight->{'visibleAreaMax'} = 2;
            $zoneCentreRight->{'defaultAreaWidth'} = 15;
            $zoneCentreRight->{'defaultAreaHeight'} = 15;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneCentreRight);

            # Lower right-hand zone
            # =====================

            $zoneLowerRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneLowerRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneLowerRight->{'left'} = 30;
            $zoneLowerRight->{'right'} = 59;
            $zoneLowerRight->{'top'} = 45;
            $zoneLowerRight->{'bottom'} = 59;
            $zoneLowerRight->{'width'} = 30;
            $zoneLowerRight->{'height'} = 15;

            $zoneLowerRight->{'reservedFlag'} = FALSE;
            $zoneLowerRight->{'multipleLayerFlag'} = TRUE;

            $zoneLowerRight->{'startCorner'} = 'top_left';
            $zoneLowerRight->{'orientation'} = 'horizontal';

            $zoneLowerRight->{'areaMax'} = 0;
            $zoneLowerRight->{'visibleAreaMax'} = 2;
            $zoneLowerRight->{'defaultAreaWidth'} = 15;
            $zoneLowerRight->{'defaultAreaHeight'} = 15;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneLowerRight);

        } elsif ($self->name eq 'horizontal') {

            #   'horizontal' - Intended for use when $self->shareMainWinFlag = FALSE. The workspace
            #       is divided into two halves, left and right, with each half occupied by a single
            #       session's windows. Inside the half, the 'main' window is at the bottom, and
            #       other windows are at the top. Windows cannot be stacked above each other

            #   333333444444
            #   333333444444
            #   333333444444
            #   333333444444
            #   111111222222
            #   111111222222
            #   111111222222
            #   111111222222
            #   111111222222
            #   111111222222
            #   111111222222
            #   111111222222

            # Lower left-hand zone
            # ====================

            $zoneLowerLeft = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneLowerLeft) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneLowerLeft->{'left'} = 0;
            $zoneLowerLeft->{'right'} = 29;
            $zoneLowerLeft->{'top'} = 20;
            $zoneLowerLeft->{'bottom'} = 59;
            $zoneLowerLeft->{'width'} = 30;
            $zoneLowerLeft->{'height'} = 40;

            $zoneLowerLeft->{'reservedFlag'} = TRUE;
            $zoneLowerLeft->ivAdd('reservedHash', 'main', 'main');
            $zoneLowerLeft->{'multipleLayerFlag'} = FALSE;

            $zoneLowerLeft->{'ownerString'} = '1';

            $zoneLowerLeft->{'startCorner'} = 'top_left';
            $zoneLowerLeft->{'orientation'} = 'horizontal';

            $zoneLowerLeft->{'areaMax'} = 1;
            $zoneLowerLeft->{'visibleAreaMax'} = 1;
            $zoneLowerLeft->{'defaultAreaWidth'} = 30;
            $zoneLowerLeft->{'defaultAreaHeight'} = 40;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneLowerLeft);

            # Lower right-hand zone
            # =====================

            $zoneLowerRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneLowerRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneLowerRight->{'left'} = 30;
            $zoneLowerRight->{'right'} = 59;
            $zoneLowerRight->{'top'} = 20;
            $zoneLowerRight->{'bottom'} = 59;
            $zoneLowerRight->{'width'} = 30;
            $zoneLowerRight->{'height'} = 40;

            $zoneLowerRight->{'reservedFlag'} = TRUE;
            $zoneLowerRight->ivAdd('reservedHash', 'main', 'main');
            $zoneLowerRight->{'multipleLayerFlag'} = FALSE;

            $zoneLowerRight->{'ownerString'} = '2';

            $zoneLowerRight->{'startCorner'} = 'top_left';
            $zoneLowerRight->{'orientation'} = 'horizontal';

            $zoneLowerRight->{'areaMax'} = 1;
            $zoneLowerRight->{'visibleAreaMax'} = 1;
            $zoneLowerRight->{'defaultAreaWidth'} = 30;
            $zoneLowerRight->{'defaultAreaHeight'} = 40;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneLowerRight);

            # Upper left-hand zone
            # ====================

            $zoneUpperLeft = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneUpperLeft) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneUpperLeft->{'left'} = 0;
            $zoneUpperLeft->{'right'} = 29;
            $zoneUpperLeft->{'top'} = 0;
            $zoneUpperLeft->{'bottom'} = 19;
            $zoneUpperLeft->{'width'} = 30;
            $zoneUpperLeft->{'height'} = 20;

            $zoneUpperLeft->{'reservedFlag'} = FALSE;
            $zoneUpperLeft->{'multipleLayerFlag'} = FALSE;

            $zoneUpperLeft->{'ownerString'} = '1';

            $zoneUpperLeft->{'startCorner'} = 'top_left';
            $zoneUpperLeft->{'orientation'} = 'horizontal';

            $zoneUpperLeft->{'areaMax'} = 0;
            $zoneUpperLeft->{'visibleAreaMax'} = 2;
            $zoneUpperLeft->{'defaultAreaWidth'} = 15;
            $zoneUpperLeft->{'defaultAreaHeight'} = 20;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneUpperLeft);

            # Upper right-hand zone
            # =====================

            $zoneUpperRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneUpperRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneUpperRight->{'left'} = 30;
            $zoneUpperRight->{'right'} = 59;
            $zoneUpperRight->{'top'} = 0;
            $zoneUpperRight->{'bottom'} = 19;
            $zoneUpperRight->{'width'} = 30;
            $zoneUpperRight->{'height'} = 20;

            $zoneUpperRight->{'reservedFlag'} = FALSE;
            $zoneUpperRight->{'multipleLayerFlag'} = FALSE;

            $zoneUpperRight->{'ownerString'} = '2';

            $zoneUpperRight->{'startCorner'} = 'top_left';
            $zoneUpperRight->{'orientation'} = 'horizontal';

            $zoneUpperRight->{'areaMax'} = 0;
            $zoneUpperRight->{'visibleAreaMax'} = 2;
            $zoneUpperRight->{'defaultAreaWidth'} = 15;
            $zoneUpperRight->{'defaultAreaHeight'} = 20;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneUpperRight);

        } elsif ($self->name eq 'vertical') {

            #   'vertical' - Intended for use when $self->shareMainWinFlag = FALSE. The workspace is
            #       divided into two halves, top and bottom, with each half occupied by a single
            #       session's windows. Inside the half, the 'main' window is on the left, and other
            #       windows are on the right. Windows cannot be stacked above each other

            #   111111113333
            #   111111113333
            #   111111113333
            #   111111113333
            #   111111113333
            #   111111113333
            #   222222224444
            #   222222224444
            #   222222224444
            #   222222224444
            #   222222224444
            #   222222224444

            # Upper left-hand zone
            # ====================

            $zoneUpperLeft = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneUpperLeft) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneUpperLeft->{'left'} = 0;
            $zoneUpperLeft->{'right'} = 39;
            $zoneUpperLeft->{'top'} = 0;
            $zoneUpperLeft->{'bottom'} = 29;
            $zoneUpperLeft->{'width'} = 40;
            $zoneUpperLeft->{'height'} = 30;

            $zoneUpperLeft->{'reservedFlag'} = TRUE;
            $zoneUpperLeft->ivAdd('reservedHash', 'main', 'main');
            $zoneUpperLeft->{'multipleLayerFlag'} = FALSE;

            $zoneUpperLeft->{'ownerString'} = '1';

            $zoneUpperLeft->{'startCorner'} = 'top_left';
            $zoneUpperLeft->{'orientation'} = 'vertical';

            $zoneUpperLeft->{'areaMax'} = 1;
            $zoneUpperLeft->{'visibleAreaMax'} = 1;
            $zoneUpperLeft->{'defaultAreaWidth'} = 40;
            $zoneUpperLeft->{'defaultAreaHeight'} = 30;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneUpperLeft);

            # Lower left-hand zone
            # ====================

            $zoneLowerLeft = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneLowerLeft) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneLowerLeft->{'left'} = 0;
            $zoneLowerLeft->{'right'} = 39;
            $zoneLowerLeft->{'top'} = 30;
            $zoneLowerLeft->{'bottom'} = 59;
            $zoneLowerLeft->{'width'} = 40;
            $zoneLowerLeft->{'height'} = 30;

            $zoneLowerLeft->{'reservedFlag'} = TRUE;
            $zoneLowerLeft->ivAdd('reservedHash', 'main', 'main');
            $zoneLowerLeft->{'multipleLayerFlag'} = FALSE;

            $zoneLowerLeft->{'ownerString'} = '2';

            $zoneLowerLeft->{'startCorner'} = 'top_left';
            $zoneLowerLeft->{'orientation'} = 'vertical';

            $zoneLowerLeft->{'areaMax'} = 1;
            $zoneLowerLeft->{'visibleAreaMax'} = 1;
            $zoneLowerLeft->{'defaultAreaWidth'} = 40;
            $zoneLowerLeft->{'defaultAreaHeight'} = 30;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneLowerLeft);

            # Upper right-hand zone
            # =====================

            $zoneUpperRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneUpperRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneUpperRight->{'left'} = 40;
            $zoneUpperRight->{'right'} = 59;
            $zoneUpperRight->{'top'} = 0;
            $zoneUpperRight->{'bottom'} = 29;
            $zoneUpperRight->{'width'} = 20;
            $zoneUpperRight->{'height'} = 30;

            $zoneUpperRight->{'reservedFlag'} = FALSE;
            $zoneUpperRight->{'multipleLayerFlag'} = FALSE;

            $zoneUpperRight->{'ownerString'} = '1';

            $zoneUpperRight->{'startCorner'} = 'top_left';
            $zoneUpperRight->{'orientation'} = 'vertical';

            $zoneUpperRight->{'areaMax'} = 0;
            $zoneUpperRight->{'visibleAreaMax'} = 2;
            $zoneUpperRight->{'defaultAreaWidth'} = 20;
            $zoneUpperRight->{'defaultAreaHeight'} = 15;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneUpperRight);

            # Lower right-hand zone
            # =====================

            $zoneLowerRight = Games::Axmud::Obj::ZoneModel->new($self);
            if (! $zoneLowerRight) {

                # Zone model couldn't be created
                return undef;
            }

            $zoneLowerRight->{'left'} = 40;
            $zoneLowerRight->{'right'} = 59;
            $zoneLowerRight->{'top'} = 30;
            $zoneLowerRight->{'bottom'} = 59;
            $zoneLowerRight->{'width'} = 20;
            $zoneLowerRight->{'height'} = 30;

            $zoneLowerRight->{'reservedFlag'} = FALSE;
            $zoneLowerRight->{'multipleLayerFlag'} = FALSE;

            $zoneLowerRight->{'ownerString'} = '2';

            $zoneLowerRight->{'startCorner'} = 'top_left';
            $zoneLowerRight->{'orientation'} = 'vertical';

            $zoneLowerRight->{'areaMax'} = 0;
            $zoneLowerRight->{'visibleAreaMax'} = 2;
            $zoneLowerRight->{'defaultAreaWidth'} = 20;
            $zoneLowerRight->{'defaultAreaHeight'} = 15;

            # Update this object's map, marking the area occupied by the zone model
            $self->addZoneModel($zoneLowerRight);
        }

        # Setup complete
        return 1;
    }

    sub modifyStandardZonemap {

        # Called by $self->clone to modify the cloned zonemap to allow its zone models to have
        #   multiple layers (assuming that the original zonemap doesn't)
        # (Could be called by any other function in order to reset a standard zonemap, probably
        #   after a call to $self->resetZonemap)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->modifyStandardZonemap', @_);
        }

        # Only modify zone models not reserved for 'main' windows
        foreach my $zoneModelObj ($self->ivValues('modelHash')) {

            if (! $zoneModelObj->ivExists('reservedHash', 'main')) {

                $zoneModelObj->set_multipleLayerFlag(TRUE);
            }
        }

        return 1;
    }

    sub resetZonemap {

        # Called by $self->new, GA::Cmd::ResetZonemap->do or any other function to reset the zonemap
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetZonemap', @_);
        }

        # Reset IVs
        $self->ivEmpty('modelHash');
        $self->ivPoke('modelCount', 0);
        $self->ivPoke('fullFlag', FALSE);

        return 1;
    }

    sub checkPosnInMap {

        # Called by $self->addZoneModel and GA::Cmd::ModifyZoneModel->do
        # Checks that the zonemap is unoccupied in a certain area
        #
        # Expected arguments
        #   $xPosBlocks, $yPosBlocks
        #           - Coordinates of the top-left corner of the search area
        #   $widthBlocks, $heightBlocks
        #           - The size of the search area
        #
        # Optional arguments
        #   $ignoreObj
        #           - A GA::Obj::ZoneModel object to ignore (used when resizing a zone model. Only
        #               count the search area as occupied if it's occupied by another zone model)
        #
        # Return values
        #   'undef' on improper arguments, or if any part of the search area is occupied (except
        #       for the specified zone model, where appropriate)
        #   1 if the whole search area is unoccupied

        my (
            $self, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $ignoreObj, $check
        ) = @_;

        # Local variables
        my ($x1, $x2, $y1, $y2);

        # Check for improper arguments
        if (
            ! defined $xPosBlocks || ! defined $yPosBlocks || ! defined $widthBlocks
            || ! defined $heightBlocks || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkPosnInMap', @_);
        }

        $x1 = $xPosBlocks,
        $x2 = $x1 + $widthBlocks - 1;
        $y1 = $yPosBlocks,
        $y2 = $y1 + $heightBlocks - 1;

        foreach my $modelObj ($self->ivValues('modelHash')) {

            if (! defined $ignoreObj || $modelObj ne $ignoreObj) {

                if (
                    (
                        ($x1 >= $modelObj->left && $x1 <= $modelObj->right)
                        || ($x2 >= $modelObj->left && $x2 <= $modelObj->right)
                    ) && (
                        ($y1 >= $modelObj->top && $y1 <= $modelObj->bottom)
                        || ($y2 >= $modelObj->top && $y2 <= $modelObj->bottom)
                    )
                ) {
                    return undef;
                }
            }
        }

        # Whole search region is empty
        return 1;
    }

    sub addZoneModel {

        # Called by $self->setupStandardZonemap and GA::Cmd::AddZoneModel->do
        # Adds a zone model to the zonemap, first checking that the area specified by the zone
        #   model's IVs is unoccupied
        #
        # Expected arguments
        #   $modelObj       - Blessed reference to the GA::Obj::ZoneModel object to add to the
        #                       zonemap
        #
        # Return values
        #   'undef' on improper arguments, if the new zone model's size variables are invalid or if
        #       the specified area is occupied
        #   1 otherwise

        my ($self, $modelObj, $check) = @_;

        # Local variables
        my @grid;

        # Check for improper arguments
        if (! defined $modelObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addZoneModel', @_);
        }

        # Check that the zone model isn't bigger than the 60x60 zonemap
        if (
            $modelObj->left < 0 || $modelObj->right > ($self->gridSize - 1)
            || $modelObj->top < 0 || $modelObj->bottom > ($self->gridSize - 1)
            || ($modelObj->right - $modelObj->left + 1) != $modelObj->width
            || ($modelObj->bottom - $modelObj->top + 1) != $modelObj->height
        ) {
            return $self->writeError(
                'Illegal size/position variables specified for the zone model',
                $self->_objClass . '->addZoneModel',
            );
        }

        # Check that the area where the zone model wants to be placed isn't already allocated to
        #   another zone model
        if (
            ! $self->checkPosnInMap(
                $modelObj->left,
                $modelObj->top,
                $modelObj->width,
                $modelObj->height,
            )
        ) {
            return $self->writeError(
                'Zonemap ' . $self->name . ' already occupied at x/y ' . $modelObj->left
                . '/' . $modelObj->top . ', cannot place new zone model there',
                $self->_objClass . '->addZoneModel',
            );
        }

        # Add the zone model to the zonemap
        $modelObj->set_number($self->modelCount);
        $self->ivAdd('modelHash', $modelObj->number, $modelObj);
        $self->ivIncrement('modelCount');

        # Check to see if there are any empty gridblocks and, if there are none, set a flag
        for (my $x = 0; $x < $self->gridSize; $x++) {

            for (my $y = 0; $y < $self->gridSize; $y++) {

                # Mark this gridblock unoccupied (for the moment)
                $grid[$x][$y] = undef;
            }
        }

        foreach my $otherObj ($self->ivValues('modelHash')) {

            for (my $x = $otherObj->left; $x <= $otherObj->right; $x++) {

                for (my $y = $otherObj->top; $y <= $otherObj->bottom; $y++) {

                    # Mark this gridblock occupied
                    $grid[$x][$y] = 1;
                }
            }
        }

        $self->ivPoke('fullFlag', TRUE);
        OUTER: for (my $x = 0; $x < $self->gridSize; $x++) {

            for (my $y = 0; $y < $self->gridSize; $y++) {

                if (! $grid[$x][$y]) {

                    $self->ivPoke('fullFlag', FALSE);
                    last OUTER;
                }
            }
        }

        return 1;
    }

    sub deleteZoneModel {

        # Called by GA::Cmd::DeleteZoneModel->do
        # Deletes a zone model from the zonemap
        #
        # Expected arguments
        #   $number     - The number of the zone model to delete
        #
        # Return values
        #   'undef' on improper arguments or if the zone model $number doesn't exist
        #   1 otherwise

        my ($self, $number, $check) = @_;

        # Local variables
        my $modelObj;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteZoneModel', @_);
        }

        # Check that specified zone model exists
        $modelObj = $self->ivShow('modelHash', $number);
        if (! $modelObj) {

            return undef;

        } else {

            $self->ivDelete('modelHash', $number);
            $self->ivPoke('fullFlag', FALSE);

            return 1;
        }
    }

    sub findZoneModel {

        # Can be called by anything
        # Given an area of the zonemap that's at least partly occupied, go through the area block by
        #   block and return the first zone model found
        #
        # Expected arguments
        #   $left, $top, $width, $height
        #           - The size of the area (in gridblocks) to search. The zonemap is 60x60, so if
        #               any of these arguments are invalid (e.g. $right = 70), default values are
        #               used (e.g. $right = 59)
        #
        # Return values
        #   'undef' on improper arguments or if the search area contains no zone models
        #   Otherwise, returns the first GA::Obj::ZoneModel found

        my ($self, $left, $top, $width, $height, $check) = @_;

        # Local variables
        my ($x1, $x2, $y1, $y2);

        # Check for improper arguments
        if (
            ! defined $left || ! defined $top || ! defined $width || ! defined $height
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->findZoneModel', @_);
        }

        # Check that the arguments are valid and, if not, use default values
        if ($left < 0) {

            $left = 0;
        }

        if (($left + $width) > $self->gridSize) {

            $width = ($self->gridSize - $left);
        }

        if ($top < 0) {

            $top = 0;
        }

        if (($top + $height) > $self->gridSize) {

            $height = ($self->gridSize - $top);
        }

        # Check the search area
        $x1 = $left,
        $x2 = $x1 + $width - 1;
        $y1 = $top,
        $y2 = $y1 + $height - 1;

        foreach my $modelObj ($self->ivValues('modelHash')) {

            if (
                (
                    ($x1 >= $modelObj->left && $x1 <= $modelObj->right)
                    || ($x2 >= $modelObj->left && $x2 <= $modelObj->right)
                ) && (
                    ($y1 >= $modelObj->top && $y1 <= $modelObj->bottom)
                    || ($y2 >= $modelObj->top && $y2 <= $modelObj->bottom)
                )
            ) {
                return $modelObj;
            }
        }

        # No zone models found in the search area
        return undef;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }

    sub gridSize
        { $_[0]->{gridSize} }
    sub modelHash
        { my $self = shift; return %{$self->{modelHash}}; }
    sub modelCount
        { $_[0]->{modelCount} }
    sub fullFlag
        { $_[0]->{fullFlag} }

    sub tempFlag
        { $_[0]->{tempFlag} }
    sub tempSession
        { $_[0]->{tempSession} }
}

# Package must return a true value
1
