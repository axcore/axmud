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
# Games::Axmud::Obj::ZoneModel
# A zone model is a template for real zone objects (GA::Obj::Zone) which are stored in a zonemap
#   (GA::Obj::Zonemap)

{ package Games::Axmud::Obj::ZoneModel;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Zonemap->setupStandardZonemap and GA::Cmd::AddZoneModel->do
        # Create a new instance of the zone model object, a blueprint for real zone objects
        #   (GA::Obj::Zone) which are stored in a workspace grid object (GA::Obj::WorkspaceGrid)
        #
        # Expected arguments
        #   $zonemapObj     - The parent GA::Obj::Zonemap object
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $zonemapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $zonemapObj || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $zonemapObj->name . '_model',
            _objClass                   => $class,
            _parentFile                 => 'zonemaps',
            _parentWorld                => undef,
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # The parent GA::Obj::Zonemap object
            zonemapObj                  => $zonemapObj,

            # Other IVs
            # ---------

            # The zone model's number within the parent zonemap (matches
            #   GA::Obj::Zonemap->modelCount) - set by GA::Obj::Zonemap->addZoneModel when the zone
            #   model is added to the zonemap
            number                      => undef,

            # The coordinates of the zone model within the zonemap's 60x60 grid
            # Coordinates of the top-left corner (e.g. 0,0)
            left                        => undef,
            top                         => undef,
            # Coordinates of the bottom-right corner (e.g. 59, 59)
            right                       => undef,
            bottom                      => undef,
            # The size of the zone (e.g. 60, 60)
            width                       => undef,
            height                      => undef,

            # If this flag is set, the zone model is reserved for certain window types
            reservedFlag                => FALSE,
            # For reserved zone models, a hash of window types allowed to use it. Hash in the form
            #   $reservedHash{window_name} = window_type
            # ...where 'window_type' is one of the window types specified by
            #   GA::Client->constGridWinTypeHash, and 'window_name' is either the same as the window
            #   type, or something different that further limits the type of window allowed to use
            #   it:
            #       window_type     window_name
            #       -----------     -----------
            #       main            main
            #       map             map
            #       protocol        Any string chosen by the protocol code, (default value is
            #                           'protocol')
            #       fixed           Any string chosen by the controlling code (default value is
            #                           'fixed')
            #       custom          Any string chosen by the controlling code. For task windows,
            #                           the name of the task (e.g. 'status_task', for other windows,
            #                           default value is 'custom'
            #       external        The external window's name (e.g. 'Notepad')
            reservedHash                => {},
            # For reserved zones, it's often preferable to use only a single layer. When this flag
            #   is set to TRUE, only a single layer is used by the zone (the default one specified
            #   by GA::Obj::WorkspaceGrid->defaultLayer)
            multipleLayerFlag           => TRUE,

            # When GA::Client->shareMainWinFlag = FALSE, meaning every session has its own 'main'
            #   window, we probably want to prevent multiple sessions from sharing the same zone
            # If this IV is defined, this zone model is reserved for a single session. The IV's
            #   value can be any non-empty string. All zone models with the same ->ownerString are
            #   reserved for a particular session.
            # The first session to place one of its windows into any 'owned' zone claims all of
            #   those zones for itself. If this IV is 'undef', the corresponding zone is available
            #   for any session to use (subject to the restrictions above)
            # NB Even if ->ownerString is set, it is ignored when GA::Client->shareMainWinFlag
            #   = TRUE (meaning all sessions share a single 'main' window). This default behaviour
            #   guards against the user selecting a zonemap such as 'horizontal', which is designed
            #   for GA::Client->shareMainWinFlag = FALSE
            ownerString                 => undef,

            # In which corner the zone should start placing windows ('top_left', 'top_right',
            #   'bottom_left', 'bottom_right');
            startCorner                 => 'top_left',
            # In which direction the zone should place windows first ('horizontal' move horizontally
            #   after the first window, if possible, 'vertical' move vertically after the first
            #   window, if possible)
            orientation                 => 'vertical',
            # The default winmap names to use in this zone with 'main' windows and other 'internal'
            #   windows. If not specified, the corresponding GA::Client IVs are used as default
            #   winmaps
            defaultEnabledWinmap        => undef,
            defaultDisabledWinmap       => undef,
            defaultInternalWinmap       => undef,

            # Sometimes it's useful to set the maximum number of areas (each containing a single
            #   window) allowed in the zone, especially for zones reserved for certain types of
            #   windows. If set to 0, there is no maximum
            areaMax                     => 0,
            # It's very often useful to set the maximum number of areas allowed in one layer of
            #   the zone, because this helps to fill a zone with windows easily. Unlike ->areaMax
            #   which is an absolute maximum, if any layer is full then new windows are just moved
            #   to another layer
            visibleAreaMax              => 0,
            # The sizes of areas within a zone normally depend on $self->visibleAreaMax; i.e. if
            #   ->visibleAreaMax is set to 2, each area takes up half the zone
            # If ->visibleAreaMax is set to 0 (meaning unlimited areas), the default area size
            #   is set by the following two variables. They show the default size of an area in
            #   terms of the zonemap's 60x60 grid
            # If ->visibleAreaMax is set to 0 and either or both of these variables are set to 0,
            #   then either or both of the default area sizes is used when areas are created
            defaultAreaWidth            => 0,
            defaultAreaHeight           => 0,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Create a clone of an existing zone model
        #
        # Expected arguments
        #   $zonemapObj     - The new zone model's parent GA::Obj::Zonemap object
        #   $number         - The number of the new zone model in the parent zonemap
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($self, $zonemapObj, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $zonemapObj || ! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Setup
        my $clone = {
            _objName                    => $zonemapObj->name . '_model',
            _objClass                   => $self->_objClass,
            _parentFile                 => 'zonemaps',
            _parentWorld                => undef,
            _privFlag                   => TRUE,                # All IVs are private

            zonemapObj                  => $zonemapObj,

            number                      => $number,

            left                        => $self->left,
            top                         => $self->top,
            right                       => $self->right,
            bottom                      => $self->bottom,
            width                       => $self->width,
            height                      => $self->height,

            reservedFlag                => $self->reservedFlag,
            reservedHash                => {$self->reservedHash},
            multipleLayerFlag           => $self->multipleLayerFlag,

            ownerString                 => $self->ownerString,

            startCorner                 => $self->startCorner,
            orientation                 => $self->orientation,
            defaultEnabledWinmap        => $self->defaultEnabledWinmap,
            defaultDisabledWinmap       => $self->defaultDisabledWinmap,
            defaultInternalWinmap       => $self->defaultInternalWinmap,

            areaMax                     => $self->areaMax,
            visibleAreaMax              => $self->visibleAreaMax,
            defaultAreaWidth            => $self->defaultAreaWidth,
            defaultAreaHeight           => $self->defaultAreaHeight,
        };

        # Bless the new zone model into existence
        bless $clone, $self->_objClass;

        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    sub set_multipleLayerFlag {

        # Called by $self->modifyStandardZonemap

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_multipleLayerFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('multipleLayerFlag', TRUE);
        } else {
            $self->ivPoke('multipleLayerFlag', FALSE);
        }

        return 1;
    }

    sub set_number {

        # Called by GA::Obj::Zonemap->addZoneModel once this zone model has been added to a zonemap

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_number', @_);
        }

        $self->ivPoke('number', $number);

        return 1;
    }

    sub set_vars {

        # Called by GA::Cmd::AddZoneModel->do and ModifyZoneModel->do
        # Sets multiple instance variables for this zone model object
        #
        # Expected arguments
        #   $standardCmd    - The client command that called this function: 'addzonemodel' or
        #                       'modifyzonemodel'
        #
        # Optional arguments
        #   A list in the form: (
        #       $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $startCorner, $orientation,
        #       $maxWindows, $maxVisibleWindows, $defaultWidthBlocks, $defaultHeightBlocks,
        #       $ownerID, $enabledWinmap, $disabledWinmap, $gridWinmap,
        #       $positionFlag, $sizeFlag, $singleLayerFlag, $startCornerFlag, $orientationFlag,
        #       $maxWindowFlag, $maxVisibleWindowFlag, $defaultWidthFlag, $defaultHeightFlag,
        #       $ownerIDFlag, $enabledWinmapFlag, $disabledWinmapFlag, $gridWinmapFlag,
        #       $reservedFlag,
        #       %reservedWinHash
        #   )
        #
        # Notes
        #   Many elements in the argument list correspond to one of this object's IVs. Any scalar
        #       element which is set to 'undef' causes the corresponding IV to be set to its default
        #       value. If %reservedWinHash is empty, the corresponding IV is emptied.
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $standardCmd,
            $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $startCorner, $orientation,
            $maxWindows, $maxVisibleWindows, $defaultWidthBlocks, $defaultHeightBlocks, $ownerID,
            $enabledWinmap, $disabledWinmap, $gridWinmap,
            $positionFlag, $sizeFlag, $singleLayerFlag, $startCornerFlag, $orientationFlag,
            $maxWindowFlag, $maxVisibleWindowFlag, $defaultWidthFlag, $defaultHeightFlag,
            $ownerIDFlag, $enabledWinmapFlag, $disabledWinmapFlag, $gridWinmapFlag,
            $reservedFlag,
            %reservedWinHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $standardCmd) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_number', @_);
        }

        # Set IVs
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

        if ($reservedFlag) {

            $self->ivPoke('reservedFlag', TRUE);
            foreach my $winName (keys %reservedWinHash) {

                $self->ivAdd('reservedHash', $winName, $reservedWinHash{$winName});
            }

        } elsif ($standardCmd eq 'addzonemodel') {

            $self->ivPoke('reservedFlag', FALSE);
            $self->ivEmpty('reservedHash');
        }

        if ($singleLayerFlag) {
            $self->ivPoke('multipleLayerFlag', TRUE);
        } elsif ($standardCmd eq 'addzonemodel') {
            $self->ivPoke('multipleLayerFlag', FALSE);                  # Default
        }

        if ($startCornerFlag) {
            $self->ivPoke('startCorner', $startCorner);
        } elsif ($standardCmd eq 'addzonemodel') {
            $self->ivPoke('startCorner', 'top_left');                   # Default
        }

        if ($orientationFlag) {
            $self->ivPoke('orientation', $orientation);
        } elsif ($standardCmd eq 'addzonemodel') {
            $self->ivPoke('orientation', 'vertical');                   # Default
        }

        if ($maxWindowFlag) {
            $self->ivPoke('areaMax', $maxWindows);
        } elsif ($standardCmd eq 'addzonemodel') {
            $self->ivPoke('areaMax', 0);                                # Default
        }

        if ($maxVisibleWindowFlag) {
            $self->ivPoke('visibleAreaMax', $maxVisibleWindows);
        } elsif ($standardCmd eq 'addzonemodel') {
            $self->ivPoke('visibleAreaMax', 0);                         # Default
        }

        if ($defaultWidthFlag) {
            $self->ivPoke('defaultAreaWidth', $defaultWidthBlocks);
        } elsif ($standardCmd eq 'addzonemodel') {
            $self->ivPoke('defaultAreaWidth', 0);                       # Default
        }

        if ($defaultHeightFlag) {
            $self->ivPoke('defaultAreaHeight', $defaultHeightBlocks);
        } elsif ($standardCmd eq 'addzonemodel') {
            $self->ivPoke('defaultAreaHeight', 0);                      # Default
        }

        if ($ownerIDFlag) {
            $self->ivPoke('ownerString', $ownerID);                     # May be 'undef'
        } else {
            $self->ivUndef('ownerString');                              # Default
        }

        if ($enabledWinmapFlag) {
            $self->ivPoke('defaultEnabledWinmap', $enabledWinmap);      # May be 'undef'
        } else {
            $self->ivUndef('defaultEnabledWinmap');                     # Default
        }

        if ($disabledWinmapFlag) {
            $self->ivPoke('defaultDisabledWinmap', $disabledWinmap);    # May be 'undef'
        } else {
            $self->ivUndef('defaultDisabledWinmap');                    # Default
        }

        if ($gridWinmapFlag) {
            $self->ivPoke('defaultInternalWinmap', $gridWinmap);        # May be 'undef'
        } else {
            $self->ivUndef('defaultInternalWinmap');                    # Default
        }

        return 1;
    }

    ##################
    # Accessors - get

    sub zonemapObj
        { $_[0]->{zonemapObj} }

    sub number
        { $_[0]->{number} }

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

    sub reservedFlag
        { $_[0]->{reservedFlag} }
    sub reservedHash
        { my $self = shift; return %{$self->{reservedHash}}; }
    sub multipleLayerFlag
        { $_[0]->{multipleLayerFlag} }

    sub ownerString
        { $_[0]->{ownerString} }

    sub startCorner
        { $_[0]->{startCorner} }
    sub orientation
        { $_[0]->{orientation} }
    sub defaultEnabledWinmap
        { $_[0]->{defaultEnabledWinmap} }
    sub defaultDisabledWinmap
        { $_[0]->{defaultDisabledWinmap} }
    sub defaultInternalWinmap
        { $_[0]->{defaultInternalWinmap} }

    sub areaMax
        { $_[0]->{areaMax} }
    sub visibleAreaMax
        { $_[0]->{visibleAreaMax} }
    sub defaultAreaWidth
        { $_[0]->{defaultAreaWidth} }
    sub defaultAreaHeight
        { $_[0]->{defaultAreaHeight} }
}

# Package must return a true value
1
