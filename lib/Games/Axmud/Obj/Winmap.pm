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
# Games::Axmud::Obj::Winmap
# A winmap is a plan for arranging widgets in any 'grid' window except 'external' windows

{ package Games::Axmud::Obj::Winmap;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->createStandardWinmaps or GA::Cmd::AddWinmap->new
        # Creates a new winmap, which is a plan for arranging widgets in any 'internal' window
        # The winmap divides the window's client area into horizontal (by default) or vertical
        #   strips (conceptually, not using a specific Gtk2 widget)
        # One (and only one) of the strips is occupied by a Gtk2::Table, onto which any
        #   widget can be positioned. The other strips are placed above or below that strip, and
        #   typically contain things like a menu bar, a toolbar with clickable items or a
        #   Gtk2::Entry box. Besides the strips that Axmud provides, users can write their own
        #   strips and insert them via a plugin
        # The winmap only affects the window, when it is first created (or when it is reset). The
        #   Axmud code is then free to add/remove strips, or add/remove widgets to the Gtk2::Table,
        #   whenever it pleases
        #
        # Expected arguments
        #   $name           - A unique name for the winmap (max 16 chars)
        #
        # Notes
        #   GA::Client->constWinmapNameHash defines some standard winmaps
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that the winmap name is unique and isn't too long
        if ($axmud::CLIENT->ivExists('winmapHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: winmap \'' . $name . '\' already exists',
                $class . '->new',
            );

        } elsif (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: illegal name \'' . $name . '\'',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'winmaps',
            _parentWorld                => undef,
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # A unique name for the winmap
            name                        => $name,

            # A hash of world profile names. Each specified world uses this winmap as its default
            #   winmap for its 'main' window (but only if GA::Client->shareMainWinFlag = FALSE,
            #   when all sessions have their own 'main' window)
            # If plugins create winmaps tailored for a particular world, then ideally only one
            #   winmap should contain that world in this hash. Nevertheless, when creating 'main'
            #   windows, winmaps are tested in alphabetical order
            # Hash in the form
            #   $worldHash{world_profile_name} = undef;
            worldHash                   => {},

            # The order in which strip objects (inheriting from GA::Generic::Strip) are added to
            #   the window's client area
            #       'top' - vertically, from top to bottom (default)
            #       'bottom' - vertically, from bottom to top
            #       'left' - horizontally, from left to right
            #       'right' - horizontally, from right to left
            orientation                 => 'top',
            # List of package names for strip objects (inheriting from GA::Generic::Strip) with
            #   which to fill the window's client area and the initialisation settings for each
            #   object
            # List in groups of two, in the form
            #   (package_name, hash_reference, package_name, hash_reference...)
            # ...where 'package_name' is the class of the strip object (e.g. GA::Strip::GaugeBox)
            #   and 'hash_reference' is either 'undef', or is a reference to a hash containing
            #   arbitrary data to use as the strip object's initialisation settings. The strip
            #   object should use default initialisation settings unless it can succesfully
            #   interpret one or more of the key-value pairs in the hash, if there are any
            # For strip objects that are 'jealous', only the first one of its kind is added;
            #   subsequent ones are ignored
            # Must contain at least the strip object which implements the Gtk2::Table,
            #   GA::Strip::Table; if not, when the window is created that strip object is added
            #   anyway, all the others have been added
            stripInitList               => [],

            # The size of the Gtk2::Table (cannot be changed)
            tableSize                   => 60,
            # The winzone objects (GA::Obj::Winzone), each of which marks out an area of the
            #   Gtk2::Table for a single widget. Hash in the form
            #       $zoneHash{number} = blessed_reference_to_winzone_object
            # NB 'main' windows must have at last one pane object (GA::Table::Pane). The pane
            #   object with the lowest 'number' is used as the session's default pane object
            #   initially. If this hash contains no winzones that create a pane object, it can't be
            #   used with 'main' windows
            zoneHash                    => {},
            # Number of winzones ever created for this winmap (used to give every winzone object a
            #   number unique to the winmap)
            zoneCount                   => 0,
            # Flag set to TRUE when the winmap becomes full
            fullFlag                    => FALSE,

            # A suggested size for new winzones, used when table objects are added after the window
            #   is created (for example, used in 'main' windows when tasks want to create their own
            #   pane objects (GA::Table::Pane) instead of using a task window)
            # These sizes should fit neatly onto the 60x60 Gtk2::Table; for example, 15x15, or
            #   30x15, or 20x15, or 20x60.
            # The process of choosing a size and position for 'grid' windows is quite flexible, and
            #   is capable of customising window sizes to suit local conditions and to fill small
            #   gaps. However, the process for table objects is much less sophisticated. The sizes
            #   specified here, if used, are used exactly, so the safest thing to do is to use a
            #   width and height that are factors of $self->tableSize. In practice, for a 60x60
            #   grid, that means using the values 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30 or 60.
            # In addition, the size should fit neatly with the sizes of of winzones in
            #   $self->zoneHash. For example, if $self->zoneHash specifies a single pane object
            #   sizes 40x40, then the size specified here should usually be a factor of that, for
            #   example 40x20 or 20x20 or 10x20
            zoneWidth                   => 30,
            zoneHeight                  => 30,
        };

        # Bless the object into existence
        bless $self, $class;

        # Set up the winmap to its default (empty) state (not really necessary, but kept for
        #   compatibility with GA::Obj::Zonemap's design)
        $self->resetWinmap();

        # If this is a standard winmap, auto-create some winzones within the winmap
        if ($axmud::CLIENT->ivExists('constWinmapNameHash', $name)) {

            if (! $self->setupStandardWinmap()) {

                return $axmud::CLIENT->writeError(
                    'Can\'t set up the standard winmap \'' . $name . '\'',
                    $class . '->new',
                );
            }
        }

        return $self;
    }

    sub clone {

        # Called by GA::Cmd::CloneWinmap->do
        # Create a clone of an existing winmap
        #
        # Expected arguments
        #   $name       - A name for the new winmap (max 16 chars)
        #
        # Return values
        #   'undef' on improper arguments, if $name is invalid or if this winmap is a temporary
        #       winmap (which can't be cloned)
        #   Blessed reference to the newly-created object on success

        my ($self, $name, $check) = @_;

        # Local variables
        my $count;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Check that the winmap name is unique and isn't too long
        if ($axmud::CLIENT->ivExists('winmapHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: winmap \'' . $name . '\' already exists',
                $self . '->clone',
            );

        } elsif (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: illegal name \'' . $name . '\'',
                $self . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'winmaps',
            _parentWorld                => undef,
            _privFlag                   => TRUE,        # All IVs are private

            name                        => $name,

            worldHash                   => {$self->worldHash},

            orientation                 => $self->orientation,
            stripInitList               => [$self->stripInitList],

            tableSize                   => $self->tableSize,
            zoneHash                    => {},          # Set below
            zoneCount                   => undef,       # Set below
            fullFlag                    => $self->fullFlag,

            zoneWidth                   => $self->zoneWidth,
            zoneHeight                  => $self->zoneHeight,
        };

        # Bless the new winmap into existence
        bless $clone, $self->_objClass;

        # Clone the winzones, in order. For example, if the old winmap had winzones numbered
        #   (0, 1, 4, 7), in the new winmap the cloned winzones are numbered (0, 1, 2, 3)
        $count = 0;
        foreach my $oldZoneObj (sort {$a <=> $b} ($self->ivValues('zoneHash'))) {

            my $cloneZoneObj;

            $cloneZoneObj = $oldZoneObj->clone($self, $count);
            $clone->ivAdd('zoneHash', $count, $cloneZoneObj);

            $count++;
        }

        $clone->ivPoke('zoneCount', $count);

        return $clone;
    }

    ##################
    # Methods

    sub setupStandardWinmap {

        # Called by $self->new whenever the specified name of the winmap is one of the standard
        #   winmaps defined by GA::Client->constWinmapNameHash
        # (Could be called by any other function in order to reset a standard winmap, probably
        #   after a call to $self->resetWinmap)
        # Sets up the standard winmap with its winzones
        #
        # Return values
        #   'undef' on improper arguments, if $name isn't one of the standard winmap names or if
        #       any of the winzones can't be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $zone;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupStandardWinmap', @_);
        }

        # Check that this really is a standard winmap
        if (! $axmud::CLIENT->ivExists('constWinmapNameHash', $self->name)) {

            return undef;
        }

        # (These IVs the same for all standard winmaps)
        $self->ivPoke('orientation', 'top');

        # Set up $self->stripInitList
        if ($self->name eq 'main_wait') {

            # From top to bottom, the window will contain a menu bar, toolbar, Gtk2::Table and an
            #   entry box
            $self->ivPush(
                'stripInitList',
                    'Games::Axmud::Strip::MenuBar',
                        undef,
                    'Games::Axmud::Strip::Toolbar',
                        undef,
                    'Games::Axmud::Strip::Table',
                        undef,
                    'Games::Axmud::Strip::Entry',
                        undef,
            );

        } elsif ($self->name eq 'internal_wait') {

            # Contains only the Gtk2::Table
            $self->ivPush(
                'stripInitList',
                    'Games::Axmud::Strip::Table',
                        undef,
            );

        } elsif (
            $self->name eq 'main_fill'
            || $self->name eq 'main_part'
            || $self->name eq 'main_empty'
        ) {
            # From top to bottom, the window will contain a menu bar, toolbar, Gtk2::Table, a gauge
            #   box, an entry box and an info box
            $self->ivPush(
                'stripInitList',
                    'Games::Axmud::Strip::MenuBar',
                        undef,
                    'Games::Axmud::Strip::Toolbar',
                        undef,
                    'Games::Axmud::Strip::Table',
                        undef,
                    'Games::Axmud::Strip::GaugeBox',
                        undef,
                    'Games::Axmud::Strip::SearchBox',
                        undef,
                    'Games::Axmud::Strip::Entry',
                        {
                            'wipe_flag'     => TRUE,
                            'add_flag'      => TRUE,
                            'console_flag'  => TRUE,
                            'input_flag'    => TRUE,
                            'search_flag'   => TRUE,
                            'cancel_flag'   => TRUE,
                            'switch_flag'   => TRUE,
                            'scroll_flag'   => TRUE,
                            'split_flag'    => TRUE,
                        },
                    'Games::Axmud::Strip::ConnectInfo',
                        undef,
            );

        } elsif (
            $self->name eq 'basic_fill'
            || $self->name eq 'basic_part'
            || $self->name eq 'basic_empty'
        ) {
            # Contains only a Gtk2::Table
            $self->ivPush(
                'stripInitList',
                    'Games::Axmud::Strip::Table',
                        undef,
            );

        } elsif (
            $self->name eq 'entry_fill'
            || $self->name eq 'entry_part'
            || $self->name eq 'entry_empty'
        ) {
            # From top to bottom, contains a Gtk2::Table and an entry box
            $self->ivPush(
                'stripInitList',
                    'Games::Axmud::Strip::Table',
                        undef,
                    'Games::Axmud::Strip::Entry',
                        undef,
            );
        }

        # Set up $self->zoneHash
        if (
            $self->name eq 'main_fill'
            || $self->name eq 'basic_fill'
            || $self->name eq 'entry_fill'
        ) {
            $zone = Games::Axmud::Obj::Winzone->new($self);
            if (! $zone) {

                # Winzone couldn't be created
                return undef;
            }

            $zone->{'left'} = 0;
            $zone->{'right'} = 59;
            $zone->{'top'} = 0;
            $zone->{'bottom'} = 59;
            $zone->{'width'} = 60;
            $zone->{'height'} = 60;
            $zone->{'packageName'} = 'Games::Axmud::Table::Pane';

            if ($self->name eq 'main_fill') {


                $zone->{'initHash'} = {
                    # A textview object that expects split screen mode to be set to 'split'
                    'split_mode'        => 'hidden',
                };

            } else {

                $zone->{'initHash'} = {
                    # A textview object that doesn't expect split screen mode to be set to 'split'
                    'split_mode'        => 'single',
                };
            }

            # Update this object's map, marking the area occupied by the winzone
            $self->addWinzone($zone);

        } elsif ($self->name eq 'main_part') {

            $zone = Games::Axmud::Obj::Winzone->new($self);
            if (! $zone) {

                # Winzone couldn't be created
                return undef;
            }

            $zone->{'left'} = 0;
            $zone->{'right'} = 39;
            $zone->{'top'} = 0;
            $zone->{'bottom'} = 59;
            $zone->{'width'} = 40;
            $zone->{'height'} = 60;
            $zone->{'packageName'} = 'Games::Axmud::Table::Pane';

            $zone->{'initHash'} = {
                'split_mode'        => 'hidden',
            };

            # Update this object's map, marking the area occupied by the winzone
            $self->addWinzone($zone);

        } elsif (
            $self->name eq 'basic_part'
            || $self->name eq 'entry_part'
        ) {
            $zone = Games::Axmud::Obj::Winzone->new($self);
            if (! $zone) {

                # Winzone couldn't be created
                return undef;
            }

            $zone->{'left'} = 0;
            $zone->{'right'} = 29;
            $zone->{'top'} = 30;
            $zone->{'bottom'} = 59;
            $zone->{'width'} = 30;
            $zone->{'height'} = 30;
            $zone->{'packageName'} = 'Games::Axmud::Table::Pane';

            $zone->{'initHash'} = {
                'split_mode'        => 'single',
            };

            # Update this object's map, marking the area occupied by the winzone
            $self->addWinzone($zone);
        }

        # Set up $self->zoneWidth, etc
        if ($self->name eq 'main_part') {

            # (The other standard winmaps can all use the default 30x30 size)
            $self->ivPoke('zoneWidth', 20);
            $self->ivPoke('zoneHeight', 20);
        }

        # Setup complete
        return 1;
    }

    sub resetWinmap {

        # Called by $self->new, GA::Cmd::ResetWinmap->do or any other function to reset the winmap's
        #   winzones
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetWinmap', @_);
        }

        # Reset IVs
        $self->ivEmpty('zoneHash');
        $self->ivPoke('zoneCount', 0);
        $self->ivPoke('fullFlag', FALSE);

        return 1;
    }

    sub checkPosnInMap {

        # Called by $self->addWinzone and GA::Cmd::ModifyWinzone->do
        # Checks that the winzone is unoccupied in a certain area
        #
        # Expected arguments
        #   $xPosBlocks, $yPosBlocks
        #           - Coordinates of the top-left corner of the search area
        #   $widthBlocks, $heightBlocks
        #           - The size of the search area
        #
        # Optional arguments
        #   $ignoreObj
        #           - A GA::Obj::Winzone object to ignore (used when resizing a winzone. Only count
        #               the search area as occupied if it's occupied by another winzone)
        #
        # Return values
        #   'undef' on improper arguments, or if any part of the search area is occupied (except
        #       for the specified winzone, where appropriate)
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

        foreach my $zoneObj ($self->ivValues('zoneHash')) {

            if (! defined $ignoreObj || $zoneObj ne $ignoreObj) {

                if (
                    (
                        ($x1 >= $zoneObj->left && $x1 <= $zoneObj->right)
                        || ($x2 >= $zoneObj->left && $x2 <= $zoneObj->right)
                    ) && (
                        ($y1 >= $zoneObj->top && $y1 <= $zoneObj->bottom)
                        || ($y2 >= $zoneObj->top && $y2 <= $zoneObj->bottom)
                    )
                ) {
                    return undef;
                }
            }
        }

        # Whole search region is empty
        return 1;
    }

    sub addWinzone {

        # Called by $self->setupStandardWinzone and GA::Cmd::AddWinzone->do
        # Adds a winzone to the winmap, first checking that the area specified by the winzone's
        #   IVs is unoccupied
        #
        # Expected arguments
        #   $zoneObj       - Blessed reference to the GA::Obj::Winzone object to add to the winmap
        #
        # Return values
        #   'undef' on improper arguments, if the new winzone's size variables are invalid or if
        #       the specified area is occupied
        #   1 otherwise

        my ($self, $zoneObj, $check) = @_;

        # Local variables
        my @grid;

        # Check for improper arguments
        if (! defined $zoneObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addWinzone', @_);
        }

        # Check that the winzone isn't bigger than the winmap's Gtk2::Table
        if (
            $zoneObj->left < 0 || $zoneObj->right > ($self->tableSize - 1)
            || $zoneObj->top < 0 || $zoneObj->bottom > ($self->tableSize - 1)
            || ($zoneObj->right - $zoneObj->left + 1) != $zoneObj->width
            || ($zoneObj->bottom - $zoneObj->top + 1) != $zoneObj->height
        ) {
            return $axmud::CLIENT->writeError(
                'Invalid size/position variables specified for the winzone',
                $self->_objClass . '->addWinzone',
            );
        }

        # Check that the area where the winzone wants to be placed isn't already allocated to
        #   another winzone
        if (
            ! $self->checkPosnInMap(
                $zoneObj->left,
                $zoneObj->top,
                $zoneObj->width,
                $zoneObj->height,
            )
        ) {
            return $axmud::CLIENT->writeError(
                'Winmap ' . $self->name . ' already occupied at x/y ' . $zoneObj->left
                . '/' . $zoneObj->top . ', cannot place new winzone there',
                $self->_objClass . '->addWinzone',
            );
        }

        # Add the winzone to the winmap
        $zoneObj->set_number($self->zoneCount);
        $self->ivAdd('zoneHash', $zoneObj->number, $zoneObj);
        $self->ivIncrement('zoneCount');

        # Check to see if there are any empty gridblocks and, if there are none, set a flag
        for (my $x = 0; $x < $self->tableSize; $x++) {

            for (my $y = 0; $y < $self->tableSize; $y++) {

                # Mark this gridblock unoccupied (for the moment)
                $grid[$x][$y] = undef;
            }
        }

        foreach my $otherObj ($self->ivValues('zoneHash')) {

            for (my $x = $otherObj->left; $x <= $otherObj->right; $x++) {

                for (my $y = $otherObj->top; $y <= $otherObj->bottom; $y++) {

                    # Mark this gridblock occupied
                    $grid[$x][$y] = 1;
                }
            }
        }

        $self->ivPoke('fullFlag', TRUE);
        OUTER: for (my $x = 0; $x < 60; $x++) {

            for (my $y = 0; $y < 60; $y++) {

                if (! $grid[$x][$y]) {

                    $self->ivPoke('fullFlag', FALSE);
                    last OUTER;
                }
            }
        }

        return 1;
    }

    sub deleteWinzone {

        # Called by GA::Cmd::DeleteWinzone->do
        # Deletes a winzone from the winmap
        #
        # Expected arguments
        #   $number     - The number of the winzone to delete
        #
        # Return values
        #   'undef' on improper arguments or if the winzone $number doesn't exist
        #   1 otherwise

        my ($self, $number, $check) = @_;

        # Local variables
        my $zoneObj;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteWinzone', @_);
        }

        # Check that specified winzone exists
        $zoneObj = $self->ivShow('zoneHash', $number);
        if (! $zoneObj) {

            return undef;

        } else {

            $self->ivDelete('zoneHash', $number);
            $self->ivPoke('fullFlag', FALSE);

            return 1;
        }
    }

    sub findWinzone {

        # Can be called by anything
        # Given an area of the winmap that's at least partly occupied, go through the area block by
        #   block and return the first winzone found
        #
        # Expected arguments
        #   $left, $top, $width, $height
        #           - The size of the area (in gridblocks) to search. The winmap is 60x60, so if any
        #               of these arguments are invalid (e.g. $right = 70), default values are used
        #               (e.g. $right = 59)
        #
        # Return values
        #   'undef' on improper arguments or if the search area contains no winzones
        #   Otherwise, returns the first GA::Obj::Winzone found

        my ($self, $left, $top, $width, $height, $check) = @_;

        # Local variables
        my ($x1, $x2, $y1, $y2);

        # Check for improper arguments
        if (
            ! defined $left || ! defined $top || ! defined $width || ! defined $height
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->findWinzone', @_);
        }

        # Check that the arguments are valid and, if not, use default values
        if ($left < 0) {

            $left = 0;
        }

        if (($left + $width) > $self->tableSize) {

            $width = ($self->tableSize - $left);
        }

        if ($top < 0) {

            $top = 0;
        }

        if (($top + $height) > $self->tableSize) {

            $height = ($self->tableSize - $top);
        }

        # Check the search area
        $x1 = $left,
        $x2 = $x1 + $width - 1;
        $y1 = $top,
        $y2 = $y1 + $height - 1;

        foreach my $winzoneObj ($self->ivValues('zoneHash')) {

            if (
                (
                    ($x1 >= $winzoneObj->left && $x1 <= $winzoneObj->right)
                    || ($x2 >= $winzoneObj->left && $x2 <= $winzoneObj->right)
                ) && (
                    ($y1 >= $winzoneObj->top && $y1 <= $winzoneObj->bottom)
                    || ($y2 >= $winzoneObj->top && $y2 <= $winzoneObj->bottom)
                )
            ) {
                return $winzoneObj;
            }
        }

        # No zone models found in the search area
        return undef;
    }

    ##################
    # Accessors - set

    sub set_orientation {

        my ($self, $string, $check) = @_;

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_orientation', @_);
        }

        if ($string ne 'top' && $string ne 'bottom' && $string ne 'left' && $string ne 'right') {

            return undef;

        } else {

            $self->ivPoke('orientation', $string);

            return 1;
        }
    }

    sub set_stripInitList {

        my ($self, @list) = @_;

        # (No improper arguments to check)

        $self->ivPoke('stripInitList', @list);

        return 1;
    }

    sub set_worldHash {

        my ($self, %hash) = @_;

        # (No improper arguments to check)

        $self->ivPoke('worldHash', %hash);

        return 1;
    }

    sub set_zoneSize {

        my ($self, $width, $height, $check) = @_;

        # Check for improper arguments
        if (! defined $width || ! defined $height || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_zoneSize', @_);
        }

        $self->ivPoke('zoneWidth', $width);
        $self->ivPoke('zoneHeight', $height);

        return 1;
    }

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }

    sub worldHash
        { my $self = shift; return %{$self->{worldHash}}; }

    sub orientation
        { $_[0]->{orientation} }
    sub stripInitList
        { my $self = shift; return @{$self->{stripInitList}}; }

    sub tableSize
        { $_[0]->{tableSize} }
    sub zoneHash
        { my $self = shift; return %{$self->{zoneHash}}; }
    sub zoneCount
        { $_[0]->{zoneCount} }
    sub fullFlag
        { $_[0]->{fullFlag} }

    sub zoneWidth
        { $_[0]->{zoneWidth} }
    sub zoneHeight
        { $_[0]->{zoneHeight} }
}

# Package must return a true value
1
