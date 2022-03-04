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
# Games::Axmud::Obj::RegionScheme
# Region scheme object, used to set the colours used by the automapper window

{ package Games::Axmud::Obj::RegionScheme;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::WorldModel->new and ->addRegionScheme
        # Creates the GA::Obj::RegionScheme, used to set the colours used by the automapper window
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $wmObj      - The parent GA::Obj::WorldModel (not stored as an IV)
        #   $name       - Unique name for this region scheme (max 16 chars)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $wmObj, $name, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $wmObj || ! defined $name
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid and not already in use by another region scheme
        if ($name ne 'default' && ! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                   $class . '->new',
            );

        } elsif ($wmObj->ivExists('regionSchemeHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: region scheme \'' . $name . '\' already exists',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => 'region_scheme_' . $name,
            _objClass                   => $class,
            _parentFile                 => 'worldmodel',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,       # All IVs are public

            # IVs
            # ---

            # Unique name for this regon scheme (max 16 chars)
            name                        => $name,

            # Colours for the region scheme, corresponding to IVs for default colours in the
            #   parent GA::Obj::WorldModel object
            backgroundColour            => undef,       # Set below
            # (There is no ->noBackgroundColour IV; always use
            #   GA::Obj::WorldModel->defaultNoBackgroundColour)
            roomColour                  => undef,
            roomTextColour              => undef,
            selectBoxColour             => undef,
            borderColour                => undef,
            currentBorderColour         => undef,
            currentFollowBorderColour   => undef,
            currentWaitBorderColour     => undef,
            currentSelectBorderColour   => undef,
            lostBorderColour            => undef,
            lostSelectBorderColour      => undef,
            ghostBorderColour           => undef,
            ghostSelectBorderColour     => undef,
            selectBorderColour          => undef,
            roomAboveColour             => undef,
            roomBelowColour             => undef,
            roomTagColour               => undef,
            selectRoomTagColour         => undef,
            roomGuildColour             => undef,
            selectRoomGuildColour       => undef,
            exitColour                  => undef,
            selectExitColour            => undef,
            selectExitTwinColour        => undef,
            selectExitShadowColour      => undef,
            randomExitColour            => undef,
            impassableExitColour        => undef,
            mysteryExitColour           => undef,
            checkedDirColour            => undef,
            dragExitColour              => undef,
            exitTagColour               => undef,
            selectExitTagColour         => undef,
            mapLabelColour              => undef,
            selectMapLabelColour        => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        # Give the colours their initial values
        $self->reset($wmObj);

        return $self;
    }

    ##################
    # Methods

    sub reset {

        # Called by $self->new, or by any other code
        # Resets colours for this region scheme to match the default colours of the parent
        #   GA::Obj::WorldModel object
        #
        # Expected arguments
        #   $wmObj  - The parent GA::Obj::WorldModel
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $wmObj, $check) = @_;

        # Check for improper arguments
        if (! defined $wmObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset', @_);
        }

        $self->ivPoke('backgroundColour', $wmObj->defaultBackgroundColour);
        $self->ivPoke('roomColour', $wmObj->defaultRoomColour);
        $self->ivPoke('roomTextColour', $wmObj->defaultRoomTextColour);
        $self->ivPoke('selectBoxColour', $wmObj->defaultSelectBoxColour);
        $self->ivPoke('borderColour', $wmObj->defaultBorderColour);
        $self->ivPoke('currentBorderColour', $wmObj->defaultCurrentBorderColour);
        $self->ivPoke('currentFollowBorderColour', $wmObj->defaultCurrentFollowBorderColour);
        $self->ivPoke('currentWaitBorderColour', $wmObj->defaultCurrentWaitBorderColour);
        $self->ivPoke('currentSelectBorderColour', $wmObj->defaultCurrentSelectBorderColour);
        $self->ivPoke('lostBorderColour', $wmObj->defaultLostBorderColour);
        $self->ivPoke('lostSelectBorderColour', $wmObj->defaultLostSelectBorderColour);
        $self->ivPoke('ghostBorderColour', $wmObj->defaultGhostBorderColour);
        $self->ivPoke('ghostSelectBorderColour', $wmObj->defaultGhostSelectBorderColour);
        $self->ivPoke('selectBorderColour', $wmObj->defaultSelectBorderColour);
        $self->ivPoke('roomAboveColour', $wmObj->defaultRoomAboveColour);
        $self->ivPoke('roomBelowColour', $wmObj->defaultRoomBelowColour);
        $self->ivPoke('roomTagColour', $wmObj->defaultRoomTagColour);
        $self->ivPoke('selectRoomTagColour', $wmObj->defaultSelectRoomTagColour);
        $self->ivPoke('roomGuildColour', $wmObj->defaultRoomGuildColour);
        $self->ivPoke('selectRoomGuildColour', $wmObj->defaultSelectRoomGuildColour);
        $self->ivPoke('exitColour', $wmObj->defaultExitColour);
        $self->ivPoke('selectExitColour', $wmObj->defaultSelectExitColour);
        $self->ivPoke('selectExitTwinColour', $wmObj->defaultSelectExitTwinColour);
        $self->ivPoke('selectExitShadowColour', $wmObj->defaultSelectExitShadowColour);
        $self->ivPoke('randomExitColour', $wmObj->defaultRandomExitColour);
        $self->ivPoke('impassableExitColour', $wmObj->defaultImpassableExitColour);
        $self->ivPoke('mysteryExitColour', $wmObj->defaultMysteryExitColour);
        $self->ivPoke('checkedDirColour', $wmObj->defaultCheckedDirColour);
        $self->ivPoke('dragExitColour', $wmObj->defaultDragExitColour);
        $self->ivPoke('exitTagColour', $wmObj->defaultExitTagColour);
        $self->ivPoke('selectExitTagColour', $wmObj->defaultSelectExitTagColour);
        $self->ivPoke('mapLabelColour', $wmObj->defaultMapLabelColour);
        $self->ivPoke('selectMapLabelColour', $wmObj->defaultSelectMapLabelColour);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }

    sub backgroundColour
        { $_[0]->{backgroundColour} }
    sub roomColour
        { $_[0]->{roomColour} }
    sub roomTextColour
        { $_[0]->{roomTextColour} }
    sub selectBoxColour
        { $_[0]->{selectBoxColour} }
    sub borderColour
        { $_[0]->{borderColour} }
    sub currentBorderColour
        { $_[0]->{currentBorderColour} }
    sub currentFollowBorderColour
        { $_[0]->{currentFollowBorderColour} }
    sub currentWaitBorderColour
        { $_[0]->{currentWaitBorderColour} }
    sub currentSelectBorderColour
        { $_[0]->{currentSelectBorderColour} }
    sub lostBorderColour
        { $_[0]->{lostBorderColour} }
    sub lostSelectBorderColour
        { $_[0]->{lostSelectBorderColour} }
    sub ghostBorderColour
        { $_[0]->{ghostBorderColour} }
    sub ghostSelectBorderColour
        { $_[0]->{ghostSelectBorderColour} }
    sub selectBorderColour
        { $_[0]->{selectBorderColour} }
    sub roomAboveColour
        { $_[0]->{roomAboveColour} }
    sub roomBelowColour
        { $_[0]->{roomBelowColour} }
    sub roomTagColour
        { $_[0]->{roomTagColour} }
    sub selectRoomTagColour
        { $_[0]->{selectRoomTagColour} }
    sub roomGuildColour
        { $_[0]->{roomGuildColour} }
    sub selectRoomGuildColour
        { $_[0]->{selectRoomGuildColour} }
    sub exitColour
        { $_[0]->{exitColour} }
    sub selectExitColour
        { $_[0]->{selectExitColour} }
    sub selectExitTwinColour
        { $_[0]->{selectExitTwinColour} }
    sub selectExitShadowColour
        { $_[0]->{selectExitShadowColour} }
    sub randomExitColour
        { $_[0]->{randomExitColour} }
    sub impassableExitColour
        { $_[0]->{impassableExitColour} }
    sub mysteryExitColour
        { $_[0]->{mysteryExitColour} }
    sub checkedDirColour
        { $_[0]->{checkedDirColour} }
    sub dragExitColour
        { $_[0]->{dragExitColour} }
    sub exitTagColour
        { $_[0]->{exitTagColour} }
    sub selectExitTagColour
        { $_[0]->{selectExitTagColour} }
    sub mapLabelColour
        { $_[0]->{mapLabelColour} }
    sub selectMapLabelColour
        { $_[0]->{selectMapLabelColour} }
}

# Package must return a true value
1
