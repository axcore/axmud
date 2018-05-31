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
# Games::Axmud::Table::xxx
# Table objects, which handle individual widgets (usually groups of widgets, within a single
#   container widget) on an 'internal' window's Gtk2::Table

# Container table objects

{ package Games::Axmud::Table::Holder;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::Holder, which reserves an area of the table for some other table
        #   object (and creates no widgets of its own)
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'id' - If specified, can be any non-empty string. Any other code (for
        #                       example, a task) can look for holders with a certain ID and, if
        #                       one is found, replace it with their choice of table object; the
        #                       area occupied by the holder remains empty until that time. Values
        #                       might include types of 'grid' window such as 'map', or 'task' for
        #                       task windows in general, or 'status_task' for the Status task in
        #                       particular. If not specified, 'undef' or an empty string, 'task' is
        #                       used as a default value
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'id'                        => 'task',
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            $modHash{$key} = $initHash{$key};
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'holder',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object; both IVs are always set to the same
            #   widget
            packingBox                  => undef,       # Gtk2::HBox, ::VBox, ::ScrolledWindow,
                                                        #   ::Frame
            packingBox2                 => undef,       # ditto

            # Other IVs
            # ---------

            # Any non-empty string which identifies what kind of table object can be put here (see
            #   comments above)
            id                          => 'task',
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my $id;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $id = $self->ivShow('initHash', 'id');
        if (defined $id && $id ne '') {

            $id = 'task';
        }

        # Create the packing box, depending on $type
        my $packingBox = Gtk2::VBox->new(FALSE, 0);

        # For this table object, ->packingBox and ->packingBox2 always refer to the same widget
        my $packingBox2 = $packingBox;

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('id', $id);

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    # (Get equivalents)

    ##################
    # Accessors - get

    sub id
        { $_[0]->{id} }
}

{ package Games::Axmud::Table::Container;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::Container, which creates a container widget into which other
        #   widgets can be freely added
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'type' - 'horizontal'/'hbox' for a Gtk2::HBox, 'vertical'/'vbox' for a
        #                       Gtk2::VBox, 'scroll'/'scroller' for a Gtk2::ScrolledWindow, 'frame'
        #                       for a Gtk2::Frame. If an invalid 'type' or if 'type' is not
        #                       specified, 'vertical' is used
        #                   'homo_flag' - Ignored if 'type' is not 'horizontal' or 'vertical'.
        #                       If TRUE, sets the container's homogeneity flag to TRUE; if FALSE,
        #                       'undef' or not specified, sets it to FALSE
        #                   'spacing' - Ignored if 'type' is not 'horizontal' or 'vertical'. Sets
        #                       the spacing between widgets packed into the box. If specified, must
        #                       be an integer, >= 0
        #                   'scroll_horizontal' - Ignored if 'type' is not 'scroll' or 'scroller'.
        #                       Sets the horizontal scrolling policy; the value must be 'always',
        #                       'automatic' or 'never'. If 'undef', not specified or an invalid
        #                       value, 'automatic' is used
        #                   'scroll_vertical' - Ignored if 'type' is not 'scroll' or 'scroller'.
        #                       Sets the vertical scrolling policy; the value must be 'always',
        #                       'automatic' or 'never'. If 'undef', not specified or an invalid
        #                       value, 'automatic' is used      #
        #                   'frame_title' - Ignored if 'type' is not 'frame' (this is different from
        #                       the behaviour of some other table objects, for which 'frame_title'
        #                       creates a frame). If a non-empty string, the string is used as the
        #                       frame title
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'type'                      => 'vertical',
            'homo_flag'                 => FALSE,
            'spacing'                   => 0,
            'scroll_horizontal'         => 'automatic',
            'scroll_vertical'           => 'automatic',
            'frame_title'               => '',
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'homo_flag') {

                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'container',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object; both IVs are always set to the same
            #   widget
            packingBox                  => undef,       # Gtk2::HBox, ::VBox, ::ScrolledWindow,
                                                        #   ::Frame
            packingBox2                 => undef,       # ditto

            # Other IVs
            # ---------

            # The container type: 'horizontal', 'vertical', 'scroll' or 'frame'. The alternative
            #   type values 'hbox', 'vbox' and 'scroller' are converted, if specified in %initHash
            type                        => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($type, $homoFlag, $spacing, $hScroll, $vScroll, $label);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $type = $self->ivShow('initHash', 'type');
        if ($type eq 'horizontal' || $type eq 'hbox') {
            $type = 'horizontal';
        } elsif ($type eq 'vertical' || $type eq 'vbox') {
            $type = 'vertical';
        } elsif ($type eq 'scroll' || $type eq 'scroller') {
            $type = 'scroll';
        } elsif ($type eq 'frame') {
            $type = 'frame';
        } else {
            $type = 'vertical';
        }

        $homoFlag = $self->testFlag($self->ivShow('initHash', 'homo_flag'));
        $spacing = $self->testInt($self->ivShow('initHash', 'spacing'), 0, 0);

        $hScroll = $self->ivShow('initHash', 'scroll_horizontal');
        if ($hScroll ne 'always' && $hScroll ne 'automatic' && $hScroll ne 'never') {

            $hScroll = 'automatic';
        }

        $vScroll = $self->ivShow('initHash', 'scroll_vertical');
        if ($vScroll ne 'always' && $vScroll ne 'automatic' && $vScroll ne 'never') {

            $vScroll = 'automatic';
        }

        $label = $self->ivShow('initHash', 'frame_title');
        if (! defined $label) {

            $label = '';
        }

        # Create the packing box, depending on $type
        my ($packingBox, $packingBox2);
        if ($type eq 'horizontal' || $type eq 'hbox') {

            $packingBox = Gtk2::HBox->new($homoFlag, $spacing);
            $type = 'horizontal';

        } elsif ($type eq 'vertical' || $type eq 'vbox') {

            $packingBox = Gtk2::VBox->new($homoFlag, $spacing);
            $type = 'vertical';

        } elsif ($type eq 'scroll' || $type eq 'scroller') {

            $packingBox = Gtk2::ScrolledWindow->new();
            $packingBox->set_policy($hScroll, $vScroll);
            $type = 'scroll';

        } elsif ($type eq 'frame') {

            if (! $label) {
                $packingBox = Gtk2::Frame->new();
            } else {
                $packingBox = Gtk2::Frame->new($label);
            }
        }

        # For this table object, ->packingBox and ->packingBox2 always refer to the same widget
        $packingBox2 = $packingBox;

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('type', $type);

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    # Other functions

    sub packStart {

        # Can be called by anything to add a widget to the main container widget
        # If $self->type is 'horizontal' or 'vertical', this function and/or $self->packEnd can be
        #   called any number of times
        # If $self->type is 'scroll' or 'frame', either this function or $self->packEnd can be
        #   called once (in that case, both functions behave identically)
        #
        # Expected arguments
        #   $widget     - The Gtk2 widget to add to the main container widget
        #
        # Optional arguments (ignored if $self->type is not 'horizontal' or 'vertical'
        #   $expandFlag - If TRUE, the widget receives extra space when the container gets bigger.
        #                   If FALSE (or 'undef'), it stays the same size (default is FALSE)
        #   $fillFlag   - If TRUE, extra space given to the widget is allocated to the widget. If
        #                   FALSE (or 'undef'), extra space is used as padding (default is FALSE)
        #   $spacing    - The space (in pixels) between this widget and its neighbours. If
        #                   specified, must be an integer, >= 0 (default is 0)
        #
        # Return values
        #   'undef' on improper arguments or if the main container widget is full
        #   1 on success

        my ($self, $widget, $expandFlag, $fillFlag, $spacing, $check) = @_;

        # Check for improper arguments
        if (! defined $widget || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->packStart', @_);
        }

        if ($self->type eq 'horizontal' || $self->type eq 'vertical') {

            # Use TRUE or FALSE flags
            if (! $expandFlag) {
                $expandFlag = FALSE;
            } else {
                $expandFlag = TRUE;
            }

            if (! $fillFlag) {
                $fillFlag = FALSE;
            } else {
                $fillFlag = TRUE;
            }

            # Check $spacing is an integer, or use a default value
            if (! defined $spacing || ! $axmud::CLIENT->intCheck($spacing, 0)) {

                $spacing = 0;
            }

            $self->packingBox2->pack_start($widget, $expandFlag, $fillFlag, $spacing);

            return 1;

        } else {

            # Can't pack the widget if the main container widget already contains something
            if ($self->packingBox2->get_children()) {

                return undef;
            }

            if ($self->type eq 'scroll') {
                $self->packingBox2->add_with_viewport($widget);
            } else {
                $self->packingBox2->add($widget);
            }

            return 1;
        }
    }

    sub packEnd {

        # Can be called by anything to add a widget to the main container widget
        # If $self->type is 'horizontal' or 'vertical', this function and/or $self->packStart can be
        #   called any number of times
        # If $self->type is 'scroll' or 'frame', either this function or $self->packStart can be
        #   called once (in that case, both functions behave identically)
        #
        # Expected arguments
        #   $widget     - The Gtk2 widget to add to the main container widget
        #
        # Optional arguments (ignored if $self->type is not 'horizontal' or 'vertical'
        #   $expandFlag - If TRUE, the widget receives extra space when the container gets bigger.
        #                   If FALSE (or 'undef'), it stays the same size (default is FALSE)
        #   $fillFlag   - If TRUE, extra space given to the widget is allocated to the widget. If
        #                   FALSE (or 'undef'), extra space is used as padding (default is FALSE)
        #   $spacing    - The space (in pixels) between this widget and its neighbours. If
        #                   specified, must be an integer, >= 0 (default is 0)
        #
        # Return values
        #   'undef' on improper arguments or if the main container widget is full
        #   1 on success

        my ($self, $widget, $expandFlag, $fillFlag, $spacing, $check) = @_;

        # Check for improper arguments
        if (! defined $widget || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->packEnd', @_);
        }

        if ($self->type eq 'horizontal' || $self->type eq 'vertical') {

            # Use TRUE or FALSE flags
            if (! $expandFlag) {
                $expandFlag = FALSE;
            } else {
                $expandFlag = TRUE;
            }

            if (! $fillFlag) {
                $fillFlag = FALSE;
            } else {
                $fillFlag = TRUE;
            }

            # Check $spacing is an integer, or use a default value
            if (! defined $spacing || ! $axmud::CLIENT->intCheck($spacing, 0)) {

                $spacing = 0;
            }

            $self->packingBox2->pack_end($widget, $expandFlag, $fillFlag, $spacing);

            return 1;

        } else {

            # Can't pack the widget if the main container widget already contains something
            if ($self->packingBox2->get_children()) {

                return undef;
            }

            if ($self->type eq 'scroll') {
                $self->packingBox2->add_with_viewport($widget);
            } else {
                $self->packingBox2->add($widget);
            }

            return 1;
        }
    }

    sub remove {

        # Can be called by anything to remove a widget from the main container widget
        #
        # Expected arguments
        #   $widget     - The Gtk2 widget to remove from the main container widget
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $widget, $check) = @_;

        # Check for improper arguments
        if (! defined $widget || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->remove', @_);
        }

        return $axmud::CLIENT->desktopObj->removeWidget($self->packingBox2, $widget);
    }

    sub empty {

        # Can be called by anything to remove all widgets from the main container widget
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->empty', @_);
        }

        foreach my $child ($self->packingBox2->get_children()) {

            $self->packingBox2->remove($child);
        }

        return 1;
    }

    ##################
    # Accessors - set

    sub set_homo {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_homo', @_);
        }

        if ($self->type ne 'horizontal' && $self->type ne 'vertical') {

            return undef;
        }

        if (! $flag) {
            $self->packingBox2->set_homogeneous(FALSE);
        } else {
            $self->packingBox2->set_homogenous(TRUE);
        }

        return 1;
    }

    sub set_label {

        my ($self, $label, $check) = @_;

        # Check for improper arguments
        if (! defined $label || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_label', @_);
        }

        if ($self->type ne 'frame') {

            return undef;
        }

        $self->packingBox2->set_label($label);

        return 1;
    }

    sub set_scroll {

        my ($self, $hScroll, $vScroll, $check) = @_;

        # Check for improper arguments
        if (! defined $hScroll || ! defined $vScroll || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_scroll', @_);
        }

        if ($self->type ne 'scroll') {

            return undef;
        }

        foreach my $policy ($hScroll, $vScroll) {

            if ($policy ne 'always' && $policy ne 'automatic' && $policy ne 'never') {

                return undef;
            }
        }

        $self->packingBox2->set_policy($hScroll, $vScroll);

        return 1;
    }

    sub set_spacing {

        my ($self, $spacing, $check) = @_;

        # Check for improper arguments
        if (! defined $spacing || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_spacing', @_);
        }

        if (
            ($self->type ne 'horizontal' && $self->type ne 'vertical')
            || ! $axmud::CLIENT->intCheck($spacing, 0)
        ) {
            return undef;
        }

        $self->packingBox2->set_spacing();

        return 1;
    }

    # (Get equivalents)

    sub get_homo {

        # Returns flag

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_homo', @_);
        }

        if ($self->type ne 'horizontal' && $self->type ne 'vertical') {

            return undef;
        }

        if (! $self->packingBox2->get_homogeneous()) {
            return FALSE;
        } else {
            return TRUE;
        }
    }

    sub get_label {

        # Returns a string (might be an empty string)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_label', @_);
        }

        if ($self->type ne 'frame') {

            return undef;

        } else {

            return $self->packingBox2->get_label();
        }
    }

    sub get_scroll {

        # Returns list in form (policy, policy), where 'policy' is one of the strings 'always',
        #   'automatic', 'never'

        my ($self, $check) = @_;

        # Local variables
        my (@emptyList, @policyList);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->get_scroll', @_);
            return @emptyList;
        }

        if ($self->type ne 'scroll') {

            return @emptyList;
        }

        @policyList = $self->packingBox2->get_policy();

        foreach my $policy (@policyList) {

            if ($policy eq 'GTK_POLICY_ALWAYS') {
                $policy = 'always';
            } elsif ($policy eq 'GTK_POLICY_AUTOMATIC') {
                $policy = 'automatic';
            } elsif ($policy eq 'GTK_POLICY_NEVER') {
                $policy = 'never';
            }
        }

        return @policyList;
    }

    sub get_spacing {

        # Returns integer

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_spacing', @_);
        }

        if ($self->type ne 'horizontal' && $self->type ne 'vertical') {

            return undef;

        } else {

            return $self->packingBox2->get_spacing();
        }
    }

    sub get_widgets {

        # Returns the list of widgets in the main container (may be an empty list)

        my ($self, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->get_widgets', @_);
            return @emptyList;
        }

        return $self->packingBox2->get_children();
    }

    ##################
    # Accessors - get

    sub type
        { $_[0]->{type} }
}

{ package Games::Axmud::Table::MiniTable;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::MiniTable, which creates a table within a table, to which other
        #   widgets can be freely added
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'rows' - The number of rows (must be an integer > 0). If not specified
        #                       or an invalid value, 60 is used
        #                   'columns' - The number of columns (must be an integer > 0). If not
        #                       specified or an invalid value, 60 is used
        #                   'homo_flag' - If TRUE, sets the table's homogeneity flag to TRUE; if
        #                       FALSE, 'undef' or not specified, sets it to FALSE
        #                   'row_spacing' - Sets the vertical spacing between table widgets, in
        #                       pixels (must be an integer, >= 0). If not specified or an invalid
        #                       value, a spacing of 0 is used
        #                   'column_spacing' - Sets the horizontal spacing between table widgets, in
        #                       pixels (must be an integer, >= 0). If not specified or an invalid
        #                       value, a spacing of 0 is used
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'rows'                      => 60,
            'columns'                   => 60,
            'homo_flag'                 => FALSE,
            'row_spacing'               => 0,
            'column_spacing'            => 0,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'homo_flag') {

                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'mini_table',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object; both IVs are always set to the same
            #   widget
            packingBox                  => undef,       # Gtk2::Table
            packingBox2                 => undef,       # Gtk2::Table

            # Other IVs
            # ---------

            # (none)
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($rows, $columns, $homoFlag, $rowSpacing, $colSpacing);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $rows = $self->testInt($self->ivShow('initHash', 'rows'), 0, 60);
        $columns = $self->testInt($self->ivShow('initHash', 'columns'), 0, 60);
        $homoFlag = $self->testFlag($self->ivShow('initHash', 'homo_flag'));
        $rowSpacing = $self->testInt($self->ivShow('initHash', 'row_spacing'), 0, 0);
        $colSpacing = $self->testInt($self->ivShow('initHash', 'column_spacing'), 0, 0);

        # Create the packing box
        my ($packingBox, $packingBox2) = Gtk2::Table->new($rows, $columns, $homoFlag);
        $packingBox2->set_col_spacings($colSpacing);
        $packingBox2->set_row_spacings($rowSpacing);

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    # Other functions

    sub pack {

        # Can be called by anything to add a widget to the mini-table
        # Unlike GA::Strip::Table, this code doesn't perform any checks; the widget is added
        #   regardless of any existing widgets that are already on the table
        #
        # Expected arguments
        #   $widget     - The Gtk2 widget to add to the main container widget
        #   $left, Right, $top, $bottom
        #               - The table coordinates to use
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $widget, $left, $right, $top, $bottom, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $widget || ! defined $left || ! defined $right || ! defined $top
            || ! defined $bottom || defined $check
        ) {
             return $axmud::CLIENT->writeImproper($self->_objClass . '->pack', @_);
        }

        $self->packingBox2->attach($widget, $left, $right, $top, $bottom);

        return 1;
    }

    sub remove {

        # Can be called by anything to remove a widget from the mini-table
        #
        # Expected arguments
        #   $widget     - The Gtk2 widget to remove from the mini-table
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $widget, $check) = @_;

        # Check for improper arguments
        if (! defined $widget || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->remove', @_);
        }

        return $axmud::CLIENT->desktopObj->removeWidget($self->packingBox2, $widget);
    }

    sub empty {

        # Can be called by anything to remove all widgets from the mini-table
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->empty', @_);
        }

        foreach my $child ($self->packingBox2->get_children()) {

            $self->packingBox2->remove($child);
        }

        return 1;
    }

    ##################
    # Accessors - set

    sub set_homo {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_homo', @_);
        }

        if ($self->type ne 'horizontal' && $self->type ne 'vertical') {

            return undef;
        }

        if (! $flag) {
            $self->packingBox2->set_homogeneous(FALSE);
        } else {
            $self->packingBox2->set_homogenous(TRUE);
        }

        return 1;
    }

    sub set_size {

        my ($self, $rows, $columns, $check) = @_;

        # Check for improper arguments
        if (! defined $rows || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_size', @_);
        }

        if (! $axmud::CLIENT->intCheck($rows, 1) || ! $axmud::CLIENT->intCheck($columns, 1)) {

            return undef;

        } else {

            $self->packingBox2->resize($rows, $columns);

            return 1;
        }
    }

    sub set_spacing {

        my ($self, $rowSpacing, $colSpacing, $check) = @_;

        # Check for improper arguments
        if (! defined $rowSpacing || ! defined $colSpacing || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_spacing', @_);
        }

        if (
            ! $axmud::CLIENT->intCheck($rowSpacing, 0)
            || ! $axmud::CLIENT->intCheck($colSpacing, 0)
        ) {
            return undef;

        } else {

            $self->packingBox2->set_row_spacings($rowSpacing);
            $self->packingBox2->set_col_spacings($colSpacing);

            return 1;
        }
    }

    # (Get equivalents)

    sub get_homo {

        # Returns flag

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_homo', @_);
        }

        if ($self->type ne 'horizontal' && $self->type ne 'vertical') {

            return undef;
        }

        if (! $self->packingBox2->get_homogeneous()) {
            return FALSE;
        } else {
            return TRUE;
        }
    }

    sub get_size {

        # Returns list in form (rows, columns)

        my ($self, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->get_size', @_);
            return @emptyList;
        }

        return ($self->packingBox2->get_size());
    }

    sub get_spacing {

        # Returns list in form (row_spacing, col_spacing)

        my ($self, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->get_spacing', @_);
            return @emptyList;
        }

        return (
            $self->packingBox2->get_default_row_spacing,
            $self->packingBox2->get_default_col_spacing,
        );
    }

    sub get_widgets {

        # Returns the list of widgets in the mini-table (may be an empty list)

        my ($self, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->get_widgets', @_);
            return @emptyList;
        }

        return $self->packingBox2->get_children();
    }

    ##################
    # Accessors - get
}

# Simple table objects

{ package Games::Axmud::Table::Label;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::Label, which contains a simple Gtk2::Label
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'text' - The text to display in the Gtk2::Label. Can be plain text or
        #                       pango markup text. If not specified, 'undef' or an empty string, an
        #                       empty string is used
        #                   'justify' - The text's justification. If specified, should be 'left',
        #                       'right', 'centre'/'center' or 'fill' (of a Gtk2::Justification like
        #                       'GTK_JUSTIFY_LEFT'). If not specified, 'left' is used. Ignored if
        #                       'text' is not specified
        #                   'underline_flag' - If TRUE, text is underlined. If FALSE (or not
        #                       specified), text is not underlined. Ignored if 'text' is not
        #                       specified
        #                   'tooltips' - The text to display as tooltips for the button. Can be
        #                       plain text or pango markup text. If not specified, 'undef' or an
        #                       empty string, no tooltips are displayed
        #                   'align_x', 'align_y' - the Gtk2::Label's alignment, values in the range
        #                       0-1. If not specified, 'align_x' is set to 0, 'align_y' is set to
        #                       0.5. Ignored if 'text' is not specified
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'text'                      => '',
            'justify'                   => 'left',
            'underline_flag'            => TRUE,
            'tooltips'                  => undef,
            'align_x'                   => 0,
            'align_y'                   => 0.5,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'underline_flag') {

                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'label',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            packingBox                  => undef,       # Gtk2::HBox or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::HBox

            # Other IVs
            # ---------

            # Widgets
            label                       => undef,       # Gtk2::Label
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($text, $noTextFlag, $justify, $underlineFlag, $tooltips, $alignX, $alignY);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $text = $self->ivShow('initHash', 'text');
        if (! defined $text) {

            $text = '';
            $noTextFlag = TRUE;
        }

        $justify = $self->testJustify($self->ivShow('initHash', 'justify'));
        $underlineFlag = $self->testFlag($self->ivShow('initHash', 'underline_flag'));
        $tooltips = $self->ivShow('initHash', 'tooltips');
        $alignX = $self->testAlign($self->ivShow('initHash', 'align_x'), 0);
        $alignY = $self->testAlign($self->ivShow('initHash', 'align_y'), 0.5);

        # Create packing box(es)
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::HBox->new(FALSE, 0));

        # Create the Gtk2::Label
        my $label = Gtk2::Label->new();
        $packingBox2->pack_start($label, FALSE, FALSE, 0);
        $label->set_markup($self->ivShow('initHash', 'text'));

        if (! $noTextFlag) {

            $label->set_justify($justify);
            $label->set_use_underline($underlineFlag);
            $label->set_alignment($alignX, $alignY);
        }

        if (defined $tooltips && $tooltips ne '') {

            $label->set_tooltip_markup($tooltips);
        }

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('label', $label);

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    sub set_align {

        my ($self, $alignX, $alignY, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_align', @_);
        }

        $alignX = $self->testAlign($alignX, 0);
        $alignY = $self->testAlign($alignY, 0.5);

        $self->label->set_alignment($alignX, $alignY);

        return 1;
    }

    sub set_justify {

        my ($self, $justify, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_justify', @_);
        }

        $self->label->set_justify($self->testJustify($justify));

        return 1;
    }

    sub set_text {

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_text', @_);
        }

        if (! defined $text) {

            $text = '';
        }

        $self->label->set_markup($text);

        return 1;
    }

    sub set_tooltips {

        my ($self, $tooltips, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tooltips', @_);
        }

        if (! defined $tooltips || $tooltips eq '') {
            $self->label->set_tooltip_text(undef);
        } else {
            $self->label->set_tooltip_markup($tooltips);
        }

        return 1;
    }

    sub set_underline {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_underline', @_);
        }

        $self->label->set_use_underline($self->testFlag($flag));

        return 1;
    }

    # (Get equivalents)

    sub get_align {

        # Returns list in form ($alignX, $alignY);

        my ($self, $alignX, $alignY, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_align', @_);
        }

        return $self->label->get_alignment();
    }

    sub get_justify {

        # Returns 'left', 'right', 'centre', 'fill' or 'other'

        my ($self, $check) = @_;

        # Local variables
        my $justify;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_justify', @_);
        }

        $justify = $self->label->get_justify();
        if ($justify eq 'GTK_JUSTIFY_LEFT') {
            return 'left';
        } elsif ($justify eq 'GTK_JUSTIFY_RIGHT') {
            return 'right';
        } elsif ($justify eq 'GTK_JUSTIFY_CENTER') {
            return 'centre';
        } elsif ($justify eq 'GTK_JUSTIFY_FILL') {
            return 'fill';
        } else {
            return 'other';
        }
    }

    sub get_text {

        # Returns string
        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_text', @_);
        }

        return $self->label->get_text();
    }

    sub get_tooltips {

        # Returns string

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_tooltips', @_);
        }

        return $self->label->get_tooltip_text();
    }

    sub get_underline {

        # Returns TRUE or FALSE

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_underline', @_);
        }

        if ($self->label->get_use_underline()) {
            return TRUE;
        } else {
            return FALSE;
        }
    }

    ##################
    # Accessors - get

    sub label
        { $_[0]->{label} }
}

{ package Games::Axmud::Table::Button;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::Button, which contains a simple Gtk2::Button
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'func' - Reference to a function to call when the button is clicked. If
        #                       not specified or 'undef', it's up to the calling code to create its
        #                       own ->signal_connect. To obtain a reference to an OOP method, you
        #                       can use the generic object function Games::Axmud->getMethodRef()
        #                   'id' - A value passed to the function which identifies the button. If
        #                       specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'text' - The text to display in the button. In Gtk, 'text' is
        #                       officially called a mnemonic, i.e. if any character is preceded by
        #                       an underline, that character is used as a keyboard accelerator
        #                       ('press' the button by pressing ALT + character). Must be plain
        #                       text, not pango markup. If not specified, 'undef' or an empty
        #                       string, no text is displayed
        #                   'stock' - The stock Gtk2 icon and text to use on the button (e.g.
        #                       'gtk-yes', 'gtk-save'. Ignored if 'text' is specified
        #                   'image' - A Gtk2::Widget to display as an image on the button. Ignored
        #                       if 'text' or 'stock' are specified
        #                   'underline_flag' - If TRUE, text is underlined. If FALSE (or not
        #                       specified), text is not underlined. Ignored if 'text' is not
        #                       specified
        #                   'tooltips' - The text to display as tooltips for the button. Can be
        #                       plain text or pango markup text. If not specified, 'undef' or an
        #                       empty string, no tooltips are displayed
        #                   'align_x', 'align_y' - The Gtk2::Button's alignment, values in the
        #                       range 0-1. If not specified, 'align_x' and/or 'align_y' are set to
        #                       0.5. Ignored if 'text' is not specified
        #                   'normal_flag' - If TRUE (or not specified), the button's state is
        #                       'normal'. If FALSE, the button's state is 'insensitive' (nothing can
        #                       interact with it)
        #                   'expand_flag' - If TRUE, the button expands and contracts to fill the
        #                       window, even when the window is resized. If FALSE (or not
        #                       specified), the button is a fixed size
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'func'                      => undef,
            'id'                        => '',
            'text'                      => '',
            'stock'                     => undef,
            'image'                     => undef,
            'underline_flag'            => FALSE,
            'tooltips'                  => undef,
            'align_x'                   => 0.5,
            'align_y'                   => 0.5,
            'normal_flag'               => TRUE,
            'expand_flag'               => FALSE,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'underline_flag' || $key eq 'normal_flag' || $key eq 'expand_flag') {

                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } elsif ($key eq 'id' && ! defined $initHash{$key}) {

                    $modHash{$key} = '';        # 'id' value must not be 'undef'

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'button',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value except 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            packingBox                  => undef,       # Gtk2::VBox or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::VBox


            # Other IVs
            # ---------

            # Widgets
            button                      => undef,       # Gtk2::Button
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $funcRef, $funcID, $text, $stock, $image, $underlineFlag, $tooltips, $alignX, $alignY,
            $normalFlag, $expandFlag,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $funcRef = $self->ivShow('initHash', 'func');
        $funcID = $self->ivShow('initHash', 'id');
        $text = $self->ivShow('initHash', 'text');
        $stock = $self->testStock($self->ivShow('initHash', 'stock'));
        $image = $self->ivShow('initHash', 'image');
        $underlineFlag = $self->testFlag($self->ivShow('initHash', 'underline_flag'));
        $tooltips = $self->ivShow('initHash', 'tooltips');
        $alignX = $self->testAlign($self->ivShow('initHash', 'align_x'), 0.5);
        $alignY = $self->testAlign($self->ivShow('initHash', 'align_y'), 0.5);
        $normalFlag = $self->testFlag($self->ivShow('initHash', 'normal_flag'));
        $expandFlag = $self->testFlag($self->ivShow('initHash', 'expand_flag'));

        # Create packing box(es)
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::VBox->new(FALSE, 0));

        # Create the Gtk2::Button
        my $button;
        if (defined $text && $text ne '') {
            $button = Gtk2::Button->new($text);
        } elsif ($stock) {
            $button = Gtk2::Button->new_from_stock($stock);
        } else {
            $button = Gtk2::Button->new();
        }

        $packingBox2->pack_start($button, $expandFlag, $expandFlag, 0);

        if (defined $text && $text ne '') {

            $button->set_use_underline($underlineFlag);
            $button->set_alignment($alignX, $alignY);

        } elsif (! $stock && $image) {

             $button->set_image($image);
        }

        if (defined $tooltips && $tooltips ne '') {

            $button->set_tooltip_markup($tooltips);
        }

        if (! $normalFlag) {

            $button->set_state('insensitive');
        }

        # Update IVs
        $self->ivPoke('funcRef', $funcRef);
        $self->ivPoke('funcID', $funcID);
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('button', $button);

        # Set up ->signal_connects
        $self->setClickedEvent();

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    sub setClickedEvent {

        # Called by $self->objEnable
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setClickedEvent', @_);
        }

        $self->button->signal_connect('clicked' => sub {

            my $currentFuncRef = $self->funcRef;

            if ($currentFuncRef) {

                &$currentFuncRef($self, $self->button, $self->funcID);
            }
        });

        return 1;
    }

    # Other functions

    ##################
    # Accessors - set

    sub set_align {

        my ($self, $alignX, $alignY, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_align', @_);
        }

        $alignX = $self->testAlign($alignX, 0);
        $alignY = $self->testAlign($alignY, 0.5);

        $self->button->set_alignment($alignX, $alignY);

        return 1;
    }

#   sub set_func {}                 # Inherited from GA::Generic::Table

#   sub set_id {}                   # Inherited from GA::Generic::Table

    sub set_normal {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_normal', @_);
        }

        if (! $flag) {
            $self->button->set_state('insensitive');
        } else {
            $self->button->set_state('normal');
        }

        return 1;
    }

    sub set_text {

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_text', @_);
        }

        if (! defined $text) {

            $text = '';
        }

        $self->button->set_label($text);

        return 1;
    }

    sub set_tooltips {

        my ($self, $tooltips, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tooltips', @_);
        }

        if (! defined $tooltips || $tooltips eq '') {
            $self->button->set_tooltip_text(undef);
        } else {
            $self->button->set_tooltip_markup($tooltips);
        }

        return 1;
    }

    sub set_underline {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_underline', @_);
        }

        $self->button->set_use_underline($self->testFlag($flag));

        return 1;
    }

    # (Get equivalents)

    sub get_align {

        # Returns list in form ($alignX, $alignY);

        my ($self, $alignX, $alignY, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_align', @_);
        }

        return $self->button->get_alignment();
    }

    sub get_normal {

        # Returns TRUE for 'normal', FALSE for 'insensitive' or any other value

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_normal', @_);
        }

        if ($self->button->get_state eq 'normal') {
            return TRUE;
        } else {
            return FALSE;
        }

        return 1;
    }

    sub get_text {

        # Returns string
        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_text', @_);
        }

        return $self->button->get_label();
    }

    sub get_tooltips {

        # Returns string

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_tooltips', @_);
        }

        return $self->button->get_tooltip_text();
    }

    sub get_underline {

        # Returns TRUE or FALSE

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_underline', @_);
        }

        if ($self->button->get_use_underline()) {
            return TRUE;
        } else {
            return FALSE;
        }
    }

    ##################
    # Accessors - get

    sub button
        { $_[0]->{button} }
}

{ package Games::Axmud::Table::CheckButton;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::CheckButton, which contains a simple Gtk2::CheckButton
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'func' - Reference to a function to call when the button is clicked. If
        #                       not specified or 'undef', it's up to the calling code to create its
        #                       own ->signal_connect. To obtain a reference to an OOP method, you
        #                       can use the generic object function Games::Axmud->getMethodRef()
        #                   'id' - A value passed to the function which identifies the button. If
        #                       specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'text' - The text to display as a label next to the button. In In Gtk,
        #                       'text' is officially called a mnemonic, i.e. if any character is
        #                       preceded by an underline, that character is used as a keyboard
        #                       accelerator ('press' the button by pressing ALT + character). Must
        #                       be plain text, not pango markup. If not specified, 'undef' or an
        #                       empty string, no text is displayed
        #                   'tooltips' - The text to display as tooltips for the button. Can be
        #                       plain text or pango markup text. If not specified, 'undef' or an
        #                       empty string, no tooltips are displayed
        #                   'align_x', 'align_y' - The Gtk2::Button's alignment, values in the
        #                       range 0-1. If not specified, 'align_x' is set to 0, 'align_y' is set
        #                       to 0.5. Ignored if 'text' is not specified
        #                   'select_flag' - If TRUE, the button is selected (checked) initially, if
        #                       FALSE (or not specified), it is not checked initially
        #                   'normal_flag' - If TRUE (or not specified), the button's state is
        #                       'normal'. If FALSE, the button's state is 'insensitive' (nothing can
        #                       interact with it)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'func'                      => undef,
            'id'                        => '',
            'text'                      => undef,
            'tooltips'                  => undef,
            'align_x'                   => 0,
            'align_y'                   => 0.5,
            'select_flag'               => FALSE,
            'normal_flag'               => TRUE,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'select_flag' || $key eq 'normal_flag') {

                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } elsif ($key eq 'id' && ! defined $initHash{$key}) {

                    $modHash{$key} = '';        # 'id' value must not be 'undef'

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'check_button',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value except 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            packingBox                  => undef,       # Gtk2::VBox or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::VBox


            # Other IVs
            # ---------

            # Widgets
            button                      => undef,       # Gtk2::CheckButton
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($funcRef, $funcID, $text, $tooltips, $alignX, $alignY, $selectFlag, $normalFlag);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $funcRef = $self->ivShow('initHash', 'func');
        $funcID = $self->ivShow('initHash', 'id');
        $text = $self->ivShow('initHash', 'text');
        $tooltips = $self->ivShow('initHash', 'tooltips');
        $alignX = $self->testAlign($self->ivShow('initHash', 'align_x'), 0);
        $alignY = $self->testAlign($self->ivShow('initHash', 'align_y'), 0.5);
        $selectFlag = $self->testFlag($self->ivShow('initHash', 'select_flag'));
        $normalFlag = $self->testFlag($self->ivShow('initHash', 'normal_flag'));

        # Create packing box(es)
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::VBox->new(FALSE, 0));

        # Create the Gtk2::CheckButton
        my $button;
        if (defined $text && $text ne '') {
            $button = Gtk2::CheckButton->new_with_mnemonic($text);
        } else {
            $button = Gtk2::CheckButton->new();
        }

        $packingBox2->pack_start($button, FALSE, FALSE, 0);

        if (defined $text && $text ne '') {

            $button->set_alignment($alignX, $alignY);
        }

        if (defined $tooltips && $tooltips ne '') {

            $button->set_tooltip_markup($tooltips);
        }

        $button->set_active($selectFlag);
        if (! $normalFlag) {

            $button->set_state('insensitive');
        }

        # Update IVs
        $self->ivPoke('funcRef', $funcRef);
        $self->ivPoke('funcID', $funcID);
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('button', $button);

        # Set up ->signal_connects
        $self->setToggledEvent();

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    sub setToggledEvent {

        # Called by $self->objEnable
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setToggledEvent', @_);
        }

        # ->signal_connect
        $self->button->signal_connect('toggled' => sub {

            my $currentFuncRef = $self->funcRef;

            if ($currentFuncRef) {

                if ($self->button->get_active()) {
                    &$currentFuncRef($self, $self->button, $self->funcID, TRUE);
                } else {
                    &$currentFuncRef($self, $self->button, $self->funcID, FALSE);
                }
            }
        });

        return 1;
    }

    # Other functions

    ##################
    # Accessors - set

    sub set_align {

        my ($self, $alignX, $alignY, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_align', @_);
        }

        $alignX = $self->testAlign($alignX, 0);
        $alignY = $self->testAlign($alignY, 0.5);

        $self->button->set_alignment($alignX, $alignY);

        return 1;
    }

#   sub set_func {}                 # Inherited from GA::Generic::Table

#   sub set_id {}                   # Inherited from GA::Generic::Table

    sub set_select {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_select', @_);
        }

        $self->button->set_active($self->testFlag($flag));

        return 1;
    }

    sub set_normal {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_normal', @_);
        }

        if (! $flag) {
            $self->button->set_state('insensitive');
        } else {
            $self->button->set_state('normal');
        }

        return 1;
    }

    sub set_text {

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_text', @_);
        }

        if (! defined $text) {

            $text = '';
        }

        $self->button->set_label($text);

        return 1;
    }

    sub set_tooltips {

        my ($self, $tooltips, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tooltips', @_);
        }

        if (! defined $tooltips || $tooltips eq '') {
            $self->button->set_tooltip_text(undef);
        } else {
            $self->button->set_tooltip_markup($tooltips);
        }

        return 1;
    }

    # (Get equivalents)

    sub get_align {

        # Returns list in form ($alignX, $alignY);

        my ($self, $alignX, $alignY, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_align', @_);
        }

        return $self->button->get_alignment();
    }

    sub get_normal {

        # Returns TRUE for 'normal', FALSE for 'insensitive' or any other value

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_normal', @_);
        }

        if ($self->button->get_state eq 'normal') {
            return TRUE;
        } else {
            return FALSE;
        }

        return 1;
    }

    sub get_select {

        # Returns TRUE or FALSE

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_select', @_);
        }

        if ($self->button->get_active()) {
            return TRUE;
        } else {
            return FALSE;
        }

        return 1;
    }

    sub get_text {

        # Returns string
        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_text', @_);
        }

        return $self->button->get_label();
    }

    sub get_tooltips {

        # Returns string

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_tooltips', @_);
        }

        return $self->button->get_tooltip_text();
    }

    ##################
    # Accessors - get

    sub button
        { $_[0]->{button} }
}

{ package Games::Axmud::Table::RadioButton;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::RadioButton, which contains a simple Gtk2::RadioButton
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'func' - Reference to a function to call when the button is clicked. If
        #                       not specified or 'undef', it's up to the calling code to create its
        #                       own ->signal_connect. To obtain a reference to an OOP method, you
        #                       can use the generic object function Games::Axmud->getMethodRef()
        #                   'id' - A value passed to the function which identifies the button. If
        #                       specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'text' - The text to display as a label next to the button. In In Gtk,
        #                       'text' is officially called a mnemonic, i.e. if any character is
        #                       preceded by an underline, that character is used as a keyboard
        #                       accelerator ('press' the button by pressing ALT + character). Must
        #                       be plain text, not pango markup. If not specified, 'undef' or an
        #                       empty string, no text is displayed
        #                   'tooltips' - The text to display as tooltips for the button. Can be
        #                       plain text or pango markup text. If not specified, 'undef' or an
        #                       empty string, no tooltips are displayed
        #                   'align_x', 'align_y' - The Gtk2::Button's alignment, values in the
        #                       range 0-1. If not specified, 'align_x' is set to 0, 'align_y' is set
        #                       to 0.5. Ignored if 'text' is not specified
        #                   'select_flag' - If TRUE, the button is selected initially, if FALSE (or
        #                       not specified), it is not selected initially
        #                   'normal_flag' - If TRUE (or not specified), the button's state is
        #                       'normal'. If FALSE, the button's state is 'insensitive' (nothing can
        #                       interact with it)
        #                   'group' - The radio button group from a previously-created
        #                       GA::Table::RadioButton object (and stored in its ->group IV). If
        #                       not specified or 'undef', this is the first radio button in its
        #                       group
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'func'                      => undef,
            'id'                        => '',
            'text'                      => undef,
            'tooltips'                  => undef,
            'align_x'                   => 0,
            'align_y'                   => 0.5,
            'select_flag'               => FALSE,
            'normal_flag'               => TRUE,
            'group'                     => undef,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'select_flag' || $key eq 'normal_flag') {

                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } elsif ($key eq 'id' && ! defined $initHash{$key}) {

                    $modHash{$key} = '';        # 'id' value must not be 'undef'

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'radio_button',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value except 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            packingBox                  => undef,       # Gtk2::VBox or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::VBox

            # Other IVs
            # ---------

            # Widgets
            button                      => undef,       # Gtk2::RadioButton
            group                       => undef,       # Reference to array of widget references
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $funcRef, $funcID, $text, $tooltips, $alignX, $alignY, $selectFlag, $normalFlag, $group,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $funcRef = $self->ivShow('initHash', 'func');
        $funcID = $self->ivShow('initHash', 'id');
        $text = $self->ivShow('initHash', 'text');
        $tooltips = $self->ivShow('initHash', 'tooltips');
        $alignX = $self->testAlign($self->ivShow('initHash', 'align_x'), 0);
        $alignY = $self->testAlign($self->ivShow('initHash', 'align_y'), 0.5);
        $selectFlag = $self->testFlag($self->ivShow('initHash', 'select_flag'));
        $normalFlag = $self->testFlag($self->ivShow('initHash', 'normal_flag'));
        $group = $self->ivShow('initHash', 'group');

        # Create packing box(es)
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::VBox->new(FALSE, 0));

        # Create the Gtk2::RadioButton
        my $button = Gtk2::RadioButton->new();
        $packingBox2->pack_start($button, FALSE, FALSE, 0);

        if (defined $text && $text ne '') {

            $button->set_label($text);
            $button->set_alignment($alignX, $alignY);
        }

        if (defined $tooltips && $tooltips ne '') {

            $button->set_tooltip_markup($tooltips);
        }

        if ($group) {

            $button->set_group($group);
        }

        $button->set_active($selectFlag);
        if (! $normalFlag) {

            $button->set_state('insensitive');
        }

        # Update IVs
        $self->ivPoke('funcRef', $funcRef);
        $self->ivPoke('funcID', $funcID);
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('button', $button);
        $self->ivPoke('group', $button->get_group());

        # Set up ->signal_connects
        $self->setToggledEvent();

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    sub setToggledEvent {

        # Called by $self->objEnable
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setToggledEvent', @_);
        }

        $self->button->signal_connect('toggled' => sub {

            my $currentFuncRef = $self->funcRef;

            # (Only call the function is the radio button is now active)
            if ($currentFuncRef && $self->button->get_active()) {

                &$currentFuncRef($self, $self->button, $self->funcID);
            }
        });

        return 1;
    }

    # Other functions

    ##################
    # Accessors - set

    sub set_align {

        my ($self, $alignX, $alignY, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_align', @_);
        }

        $alignX = $self->testAlign($alignX, 0);
        $alignY = $self->testAlign($alignY, 0.5);

        $self->button->set_alignment($alignX, $alignY);

        return 1;
    }

#   sub set_func {}                 # Inherited from GA::Generic::Table

#   sub set_id {}                   # Inherited from GA::Generic::Table

    sub set_normal {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_normal', @_);
        }

        if (! $flag) {
            $self->button->set_state('insensitive');
        } else {
            $self->button->set_state('normal');
        }

        return 1;
    }

    sub set_select {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_select', @_);
        }

        $self->button->set_active($self->testFlag($flag));

        return 1;
    }

    sub set_text {

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_text', @_);
        }

        if (! defined $text) {

            $text = '';
        }

        $self->button->set_label($text);

        return 1;
    }

    sub set_tooltips {

        my ($self, $tooltips, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tooltips', @_);
        }

        if (! defined $tooltips || $tooltips eq '') {
            $self->button->set_tooltip_text(undef);
        } else {
            $self->button->set_tooltip_markup($tooltips);
        }

        return 1;
    }

    # (Get equivalents)

    sub get_align {

        # Returns list in form ($alignX, $alignY);

        my ($self, $alignX, $alignY, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_align', @_);
        }

        return $self->button->get_alignment();
    }

    sub get_normal {

        # Returns TRUE for 'normal', FALSE for 'insensitive' or any other value

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_normal', @_);
        }

        if ($self->button->get_state eq 'normal') {
            return TRUE;
        } else {
            return FALSE;
        }

        return 1;
    }

    sub get_select {

        # Returns TRUE or FALSE

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_select', @_);
        }

        if ($self->button->get_active()) {
            return TRUE;
        } else {
            return FALSE;
        }

        return 1;
    }

    sub get_text {

        # Returns string
        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_text', @_);
        }

        return $self->button->get_label();
    }

    sub get_tooltips {

        # Returns string

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_tooltips', @_);
        }

        return $self->button->get_tooltip_text();
    }

    ##################
    # Accessors - get

    sub button
        { $_[0]->{button} }
    sub group
        { $_[0]->{group} }
}

{ package Games::Axmud::Table::Entry;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::Entry, which contains a simple Gtk2::Entry
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'func' - Reference to a function to call when the user types something
        #                       in the entry box and presses 'return'. If not specified or 'undef',
        #                       it's up to the calling code to create its own ->signal_connect. To
        #                       obtain a reference to an OOP method, you can use the generic object
        #                       function Games::Axmud->getMethodRef()
        #                   'id' - A value passed to the function which identifies the button. If
        #                       specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'text' - The initial contents of the entry. If an empty string or
        #                       'undef', the entry is initially empty
        #                   'width_chars' - The width of the entry, in characters. If not
        #                       specified, 0 or 'undef', a width is not applied to the entry
        #                   'max_chars' - The maximum number of characters the entry can contain.
        #                       If not specified, 0 or 'undef', no maximum is applied to the entry
        #                   'tooltips' - The text to display as tooltips for the entry. Can be
        #                       plain text or pango markup text. If not specified, 'undef' or an
        #                       empty string, no tooltips are displayed
        #                   'normal_flag' - If TRUE (or not specified), the entry's state is
        #                       'normal'. If FALSE, the button's state is 'insensitive' (nothing can
        #                       interact with it)
        #                   'expand_flag' - If TRUE (or unspecified), the entry box expands to the
        #                       full available length. If FALSE (or unspecified), it will be
        #                       whatever length Gtk gives it (which is, in turn, influenced by
        #                       'width_chars' and 'max_chars')
        #                   'check_flag' - If specified, the entry contains a stock icon which
        #                       indicates whether the entry's text is acceptable. The function
        #                       specified by 'func' will then only be called when the user presses
        #                       'return' AND the entry's text is acceptable
        #                   'check_yes' - The stock icon to use to show the entry's text is
        #                       acceptable. If not specified, 'gtk-yes' is used. (Ignored when
        #                       'check_flag' is not specified)
        #                   'check_no' - The stock icon to use to show the entry's text is not
        #                       acceptable. If not specified, 'gtk-no' is used. (Ignored when
        #                       'check_flag' is not specified)
        #                   'check_func' - Reference to a function which receives the entry's text
        #                       as an argument, and returns 1 if the text is acceptable, but 'undef'
        #                       if it's not acceptable. If not specified, 'check_type' is used to
        #                       judge acceptability instead. (Ignored when 'check_flag' is not
        #                       specified)
        #                   'check_type' - Set to 'int' (to be acceptable, the entry's text must be
        #                       an integer), 'odd' (the entry's text must be an odd-numbered
        #                       integer), 'even' (the entry's text must be an even-numbered
        #                       integer), 'float' (the entry's text must be an integer or floating
        #                       point number), 'string' (the entry's text can contain anything, even
        #                       an empty string). If not specified, 'string' is used as a default.
        #                       (Ignored when 'check_flag' is not specified or if 'check_func' is
        #                       specified)
        #                   'check_min', 'check_max' - For 'int'/'float', the minimum/maximum
        #                       values that are acceptable. For 'odd'/'even', the minimum/maximum
        #                       values that are acceptable; if the minimum value is less than 1 or 2
        #                       respectively, then 1 or 2 are used instead. For 'string', the
        #                       minimum/maximum length of the string. If either or both values are
        #                       not specified or 'undef', then no minimumx and/or maximum applies.
        #                       (Ignored when 'check_flag' is not specified or if 'check_func' is
        #                       specified)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'func'                      => undef,
            'id'                        => '',
            'text'                      => undef,
            'width_chars'               => 0,
            'max_chars'                 => 0,
            'tooltips'                  => undef,
            'normal_flag'               => TRUE,
            'expand_flag'               => TRUE,
            'check_flag'                => FALSE,
            'check_yes'                 => 'gtk-yes',
            'check_no'                  => 'gtk-no',
            'check_func'                => undef,
            'check_type'                => 'string',
            'check_min'                 => undef,
            'check_max'                 => undef,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'normal_flag' || $key eq 'expand_flag' || $key eq 'check_flag') {

                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } elsif ($key eq 'id' && ! defined $initHash{$key}) {

                    $modHash{$key} = '';        # 'id' value must not be 'undef'

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'entry',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value except 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            packingBox                  => undef,       # Gtk2::HBox or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::HBox

            # Other IVs
            # ---------

            # Widgets
            entry                       => undef,       # Gtk2::Entry

            # IVs set by $self->objEnable, using values from $self->initHash after checking they're
            #   valid (and using default values, if not)
            checkFlag                   => undef,
            checkYes                    => undef,
            checkNo                     => undef,
            checkFunc                   => undef,
            checkType                   => undef,
            checkMin                    => undef,
            checkMax                    => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $funcRef, $funcID, $text, $widthChars, $maxChars, $tooltips, $normalFlag, $expandFlag,
            $checkFlag, $checkYes, $checkNo, $checkFunc, $checkType, $checkMin, $checkMax,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $funcRef = $self->ivShow('initHash', 'func');
        $funcID = $self->ivShow('initHash', 'id');
        $text = $self->ivShow('initHash', 'text');
        $widthChars = $self->testInt($self->ivShow('initHash', 'width_chars'), 0, 0);
        $maxChars = $self->testInt($self->ivShow('initHash', 'max_chars'), 0, 0);
        $tooltips = $self->ivShow('initHash', 'tooltips');
        $normalFlag = $self->testFlag($self->ivShow('initHash', 'normal_flag'));
        $expandFlag = $self->testFlag($self->ivShow('initHash', 'expand_flag'));
        $checkFlag = $self->testFlag($self->ivShow('initHash', 'check_flag'));

        if ($checkFlag) {

            $checkYes = $self->testStock($self->ivShow('initHash', 'check_yes'), 'gtk-yes');
            $checkNo = $self->testStock($self->ivShow('initHash', 'check_no'), 'gtk-no');
            $checkFunc = $self->ivShow('initHash', 'check_func');
            $checkType = $self->ivShow('initHash', 'check_type');
            if (
                ! defined $checkType
                || (
                    $checkType ne 'int'
                    && $checkType ne 'even'
                    && $checkType ne 'odd'
                    && $checkType ne 'float'
                    && $checkType ne 'string'
                )
            ) {
                $checkType = 'string';
            }

            $checkMin = $self->testInt($self->ivShow('initHash', 'check_min'), undef, undef);
            $checkMax = $self->testInt($self->ivShow('initHash', 'check_max'), undef, undef);
            if (defined $checkMin && defined $checkMax && $checkMin > $checkMax) {

                $checkMin = undef;
                $checkMax = undef;
            }

            if (defined $checkType) {

                if ($checkType eq 'odd' && defined $checkMin && $checkMin < 1) {

                    $checkMin = 1;

                } elsif ($checkType eq 'even' && defined $checkMin && $checkMin < 2) {

                    $checkMin = 2;
                }

                if ($checkType eq 'string' && defined $checkMin && $checkMin < 0) {

                    $checkMin = 0;
                }

                if ($checkType eq 'string' && defined $checkMax && $checkMax < 0) {

                    $checkMax = 0;
                }
            }
        }

        # Create packing box(es)
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::HBox->new(FALSE, 0));

        # Create the Gtk2::Entry
        my $entry = Gtk2::Entry->new();
        $packingBox2->pack_start($entry, $expandFlag, $expandFlag, 0);
        if (defined $text && $text ne '') {

            $entry->set_text($text);
        }

        if ($checkFlag && ! $checkFunc) {

            if ($self->testIconValue($text, $checkType, $checkMax, $checkMin)) {
                $entry->set_icon_from_stock('secondary', $self->checkNo);
            } else {
                $entry->set_icon_from_stock('secondary', $self->checkYes);
            }
        }

        if ($widthChars) {

            $entry->set_width_chars($widthChars);
        }

        if ($maxChars) {

            $entry->set_max_length($maxChars);
        }

        if (defined $tooltips && $tooltips ne '') {

            $entry->set_tooltip_markup($tooltips);
        }

        if (! $normalFlag) {

            $entry->set_state('insensitive');
        }

        # Update IVs
        $self->ivPoke('funcRef', $funcRef);
        $self->ivPoke('funcID', $funcID);
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('entry', $entry);
        $self->ivPoke('checkFlag', $checkFlag);
        $self->ivPoke('checkYes', $checkYes);
        $self->ivPoke('checkNo', $checkNo);
        $self->ivPoke('checkFunc', $checkFunc);
        $self->ivPoke('checkType', $checkType);
        $self->ivPoke('checkMin', $checkMin);
        $self->ivPoke('checkMax', $checkMax);

        # Set up ->signal_connects
        $self->setChangedEvent();
        $self->setActivateEvent();

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    sub setChangedEvent {

        # Called by $self->objEnable
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setChangedEvent', @_);
        }

        $self->entry->signal_connect('changed' => sub {

            my ($value, $thisCheckFunc);

            $value = $self->entry->get_text();
            $thisCheckFunc = $self->checkFunc;

            if ($self->checkFlag) {

                if (! $thisCheckFunc) {

                    if (
                        ! $self->testIconValue(
                            $value,
                            $self->checkType,
                            $self->checkMin,
                            $self->checkMax,
                        )
                    ) {
                        $self->entry->set_icon_from_stock('secondary', $self->checkNo);
                    } else {
                        $self->entry->set_icon_from_stock('secondary', $self->checkYes);
                    }

                } else {

                    if (! &$thisCheckFunc($self, $self->entry, $self->funcID, $value)) {
                        $self->entry->set_icon_from_stock('secondary', $self->checkNo);
                    } else {
                        $self->entry->set_icon_from_stock('secondary', $self->checkYes);
                    }
                }
            }
        });

        return 1;
    }

    sub setActivateEvent {

        # Called by $self->objEnable
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setActivateEvent', @_);
        }

        $self->entry->signal_connect('activate' => sub {

            my ($value, $thisFuncRef);

            $value = $self->entry->get_text();
            $thisFuncRef = $self->funcRef;

            if (
                $thisFuncRef
                && (
                    ! $self->checkFlag || $self->testIconValue(
                        $value,
                        $self->checkType,
                        $self->checkMin,
                        $self->checkMax,
                    )
                )
            ) {
                &$thisFuncRef($self, $self->entry, $self->funcID, $value);
            }

            $self->entry->set_text('');
        });

        return 1;
    }

    # Other functions

    ##################
    # Accessors - set

    sub set_check_func {

        # If $funcRef is 'undef', $self->checkType is used to judge acceptability instead

        my ($self, $funcRef, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_check_func', @_);
        }

        if (! $self->checkFlag) {

            return undef;

        } else {

            $self->ivPoke('checkFunc', $funcRef);

            return 1;
        }
    }

    sub set_check_max {

        my ($self, $num, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_check_max', @_);
        }

        if (! $self->checkFlag) {

            return undef;

        } else {

            $self->ivPoke('checkMax', $self->testInt($num, undef, undef));

            return 1;
        }
    }

    sub set_check_min {

        my ($self, $num, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_check_min', @_);
        }

        if (! $self->checkFlag) {

            return undef;

        } else {

            $self->ivPoke('checkMin', $self->testInt($num, undef, undef));

            return 1;
        }
    }

    sub set_check_type {

        my ($self, $type, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_check_type', @_);
        }

        if (! $self->checkFlag) {

            return undef;
        }

        if (
            ! defined $type
            || (
                $type ne 'int'
                && $type ne 'even'
                && $type ne 'odd'
                && $type ne 'float'
                && $type ne 'string'
            )
        ) {
            $type = 'string';
        }

        $self->ivPoke('checkType', $type);

        return 1;
    }

#   sub set_func {}                 # Inherited from GA::Generic::Table

#   sub set_id {}                   # Inherited from GA::Generic::Table

    sub set_max_chars {

        my ($self, $num, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_max_chars', @_);
        }

        $self->entry->set_max_length($self->testInt($num, 0, 0));

        return 1;
    }

    sub set_normal {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_normal', @_);
        }

        if (! $flag) {
            $self->entry->set_state('insensitive');
        } else {
            $self->entry->set_state('normal');
        }

        return 1;
    }

    sub set_text {

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_text', @_);
        }

        if (! defined $text) {

            $text = '';
        }

        $self->entry->set_text($text);

        return 1;
    }

    sub set_tooltips {

        my ($self, $tooltips, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tooltips', @_);
        }

        if (! defined $tooltips || $tooltips eq '') {
            $self->entry->set_tooltip_text(undef);
        } else {
            $self->entry->set_tooltip_markup($tooltips);
        }

        return 1;
    }

    sub set_width_chars {

        my ($self, $num, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_width_chars', @_);
        }

        $self->entry->set_width_chars($self->testInt($num, 0, 0));

        return 1;
    }

    # (Get equivalents)

    sub get_max_chars {

        # Returns string
        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_max_chars', @_);
        }

        return $self->entry->get_max_length();
    }

    sub get_normal {

        # Returns TRUE for 'normal', FALSE for 'insensitive' or any other value

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_normal', @_);
        }

        if ($self->entry->get_state eq 'normal') {
            return TRUE;
        } else {
            return FALSE;
        }

        return 1;
    }

    sub get_text {

        # Returns string
        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_text', @_);
        }

        return $self->entry->get_text();
    }

    sub get_tooltips {

        # Returns string

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_tooltips', @_);
        }

        return $self->entry->get_tooltip_text();
    }

    sub get_width_chars {

        # Returns string
        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_width_chars', @_);
        }

        return $self->entry->get_width_chars();
    }

    ##################
    # Accessors - get

    sub entry
        { $_[0]->{entry} }

    sub checkFlag
        { $_[0]->{checkFlag} }
    sub checkYes
        { $_[0]->{checkYes} }
    sub checkNo
        { $_[0]->{checkNo} }
    sub checkFunc
        { $_[0]->{checkFunc} }
    sub checkType
        { $_[0]->{checkType} }
    sub checkMin
        { $_[0]->{checkMin} }
    sub checkMax
        { $_[0]->{checkMax} }
}

{ package Games::Axmud::Table::ComboBox;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::ComboBox, which contains a simple Gtk2::ComboBox
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'func' - Reference to a function to call when an item in the combobox
        #                       is selected. If not specified or 'undef', it's up to the calling
        #                       code to create its own ->signal_connect. To obtain a reference to an
        #                       OOP method, you can use the generic object function
        #                       Games::Axmud->getMethodRef()
        #                   'id' - A value passed to the function which identifies the button. If
        #                       specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'list_ref' - Reference to a list used to fill the combobox. If 'undef'
        #                       or if the referenced list is empty, the combobox is empty
        #                   'title' - A string to use as the combobox's title, e.g. 'Choose your
        #                       favourite cat'. If 'undef', a title isn't used
        #                   'tooltips' - The text to display as tooltips for the button. Can be
        #                       plain text or pango markup text. If not specified, 'undef' or an
        #                       empty string, no tooltips are displayed
        #                   'normal_flag' - If TRUE (or not specified), the button's state is
        #                       'normal'. If FALSE, the button's state is 'insensitive' (nothing can
        #                       interact with it)
        #                   'expand_flag' - If TRUE (or unspecified), the combobox expands to the
        #                       full available length. If FALSE (or unspecified), it will be
        #                       whatever length Gtk gives it (which is, in turn, influenced by
        #                       the title and items in the list)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'func'                      => undef,
            'id'                        => '',
            'list_ref'                  => undef,
            'title'                     => undef,
            'tooltips'                  => undef,
            'normal_flag'               => TRUE,
            'expand_flag'               => TRUE,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'normal_flag' || $key eq 'expand_flag') {

                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } elsif ($key eq 'id' && ! defined $initHash{$key}) {

                    $modHash{$key} = '';        # 'id' value must not be 'undef'

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'combo_box',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value except 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            packingBox                  => undef,       # Gtk2::HBox or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::HBox

            # Other IVs
            # ---------

            # Widgets
            comboBox                    => undef,       # Gtk2::ComboBox

            # Item in the combobox used as a title ('undef' if no title specified). Set by
            #   $self->objEnable from $self->initHash
            title                       => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($funcRef, $funcID, $listRef, $title, $tooltips, $normalFlag, $expandFlag);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $funcRef = $self->ivShow('initHash', 'func');
        $funcID = $self->ivShow('initHash', 'id');
        $listRef = $self->ivShow('initHash', 'list_ref');
        $title = $self->ivShow('initHash', 'title');
        $tooltips = $self->ivShow('initHash', 'tooltips');
        $normalFlag = $self->testFlag($self->ivShow('initHash', 'normal_flag'));
        $expandFlag = $self->testFlag($self->ivShow('initHash', 'expand_flag'));

        # Create packing box(es)
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::HBox->new(FALSE, 0));

        # Create the Gtk2::ComboBox
        my $comboBox = Gtk2::ComboBox->new_text();
        $packingBox2->pack_start($comboBox, $expandFlag, $expandFlag, 0);
        if (defined $title) {

            $comboBox->append_text($title);
        }

        foreach my $item (@$listRef) {

            $comboBox->append_text($item);
        }

        # The first item in the combobox is the first one selected
        $comboBox->set_active(0);

        if (defined $tooltips && $tooltips ne '') {

            $comboBox->set_tooltip_markup($tooltips);
        }

        if (! $normalFlag) {

            $comboBox->set_state('insensitive');
        }

        # Update IVs
        $self->ivPoke('funcRef', $funcRef);
        $self->ivPoke('funcID', $funcID);
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('comboBox', $comboBox);
        $self->ivPoke('title', $title);

        # Set up ->signal_connects
        $self->setChangedEvent();

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    sub setChangedEvent {

        # Called by $self->objEnable
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setChangedEvent', @_);
        }

        $self->comboBox->signal_connect('changed' => sub {

            my ($currentFuncRef, $value);

            $currentFuncRef = $self->funcRef;
            $value = $self->comboBox->get_active_text();

            # (If the user selects the title, ignore it)
            if ($currentFuncRef && (! defined $self->title || $value ne $self->title)) {

                &$currentFuncRef($self, $self->comboBox, $self->funcID, $value);
            }
        });

        return 1;
    }

    # Other functions

    sub resetCombo {

        # Can be called by anything
        # Resets the appearance of the combobox

        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetCombo', @_);
        }

        $self->comboBox->set_active(0);
        $self->comboBox->popdown();

        return 1;
    }

    ##################
    # Accessors - set

#   sub set_func {}                 # Inherited from GA::Generic::Table

#   sub set_id {}                   # Inherited from GA::Generic::Table

    sub set_list {

        my ($self, $title, @list) = @_;

        # Local variables
        my ($funcRef, $model);

        # (No improper arguments to check)

        # Temporarily resetting $self->funcRef prevents the ->signal_connect from calling that
        #   function while we're resetting the combobox
        $funcRef = $self->funcRef;
        $self->ivUndef('funcRef');

        # Empty the combobox...
        $model = $self->comboBox->get_model();
        $model->clear();

        # ...and refill it (if specified)
        if (defined $title) {

            $self->comboBox->append_text($title);
            $self->ivPoke('title', $title);

        } else {

            $self->ivUndef($title);
        }

        foreach my $item (@list) {

            $self->comboBox->append_text($item);
        }

        # The first item in the combobox is the first one selected
        $self->comboBox->set_active(0);
        $self->comboBox->popdown();

        # Restore the combobox to normal operations
        $self->ivPoke('funcRef', $funcRef);

        return 1;
    }

    sub set_normal {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_normal', @_);
        }

        if (! $flag) {
            $self->comboBox->set_state('insensitive');
        } else {
            $self->comboBox->set_state('normal');
        }

        return 1;
    }

    sub set_tooltips {

        my ($self, $tooltips, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tooltips', @_);
        }

        if (! defined $tooltips || $tooltips eq '') {
            $self->comboBox->set_tooltip_text(undef);
        } else {
            $self->comboBox->set_tooltip_markup($tooltips);
        }

        return 1;
    }

    # (Get equivalents)

    sub get_normal {

        # Returns TRUE for 'normal', FALSE for 'insensitive' or any other value

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_normal', @_);
        }

        if ($self->comboBox->get_state eq 'normal') {
            return TRUE;
        } else {
            return FALSE;
        }

        return 1;
    }

    sub get_text {

        # Returns 'undef' if the combobox's title is selected

        my ($self, $check) = @_;

        # Local variables
        my $text;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_text', @_);
        }

        $text = $self->comboBox->get_active_text();

        if (defined $self->title && $self->title eq $text) {
            return undef;
        } else {
            return $text;
        }
    }

    sub get_tooltips {

        # Returns string

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_tooltips', @_);
        }

        return $self->comboBox->get_tooltip_text();
    }

    ##################
    # Accessors - get

    sub comboBox
        { $_[0]->{comboBox} }
    sub title
        { $_[0]->{title} }
}

{ package Games::Axmud::Table::SimpleList;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::SimpleList, which contains a simple Gtk2::Ex::Simple::List
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'frame_title' - If specified, the table object is drawn inside a frame
        #                       with the specified title. If 'undef', an empty string or not
        #                       specified, the table object does not use a frame and title
        #                   'func' - Reference to a function to call when an item in the combobox
        #                       is selected. If not specified or 'undef', it's up to the calling
        #                       code to create its own ->signal_connect. To obtain a reference to an
        #                       OOP method, you can use the generic object function
        #                       Games::Axmud->getMethodRef()
        #                   'id' - A value passed to the function which identifies the button. If
        #                       specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'column_ref' - Reference to a list of column headings and types, in the
        #                       form ('heading', 'column_type', 'heading', 'column_type'...), where
        #                       'column_type' is one of the column types recognised by
        #                       Gtk2::Ex::Simple::List, i.e. 'text', 'markup', 'int', 'double',
        #                       'bool', 'scalar' or 'pixbuf'. If 'undef' or an empty list, a single
        #                       column of type 'text' is created. If the list contains an odd
        #                       number of items, the final one is discarded
        #                   'data_ref' - Reference to a list used to populate the
        #                       Gtk2::Ex::Simple::List. If there are 2 columns, a list in the form
        #                       (a, b, a, b...) is expected. If there are 3 columns, a list in the
        #                       form (a, b, c, a, b, c) is expected. If 'undef' or an empty list,
        #                       nothing is added to the simple list
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'frame_title'               => undef,
            'func'                      => undef,
            'id'                        => '',
            'column_ref'                => undef,
            'data_ref'                  => undef,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'id' && ! defined $initHash{$key}) {

                    $modHash{$key} = '';        # 'id' value must not be 'undef'

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'simple_list',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value except 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            packingBox                  => undef,       # Gtk2::ScrolledWindow or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::ScrolledWindow

            # Other IVs
            # ---------

            # Widgets
            slWidget                    => undef,       # Gtk2::Ex::Simple::List

            # The number of columns in the simple list (minimum 1)
            numColumns                  => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $funcRef, $funcID, $columnListRef, $dataListRef, $numColumns, $count,
            @columnList, @dataList,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $funcRef = $self->ivShow('initHash', 'func');
        $funcID = $self->ivShow('initHash', 'id');
        $columnListRef = $self->ivShow('initHash', 'column_ref');
        $dataListRef = $self->ivShow('initHash', 'data_ref');

        if (defined $columnListRef) {

            @columnList = @$columnListRef;
        }

        if (! (scalar @columnList) % 2) {

            # List should be in the form ('heading', 'column_type', 'heading', 'column_type'...) but
            #    a 'column_type' is missing; discard the unpaired 'heading'
            pop @columnList;
        }

        if (! @columnList) {

            # List contains no 'heading' or 'column_type', use default ones
            push (@columnList, 'Items', 'text');
        }

        if (defined $dataListRef) {

            @dataList = @$dataListRef;
        }

        # Create packing box(es)
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::ScrolledWindow->new());
        $packingBox2->set_policy('automatic', 'automatic');

        # Create the Gtk2::Ex::Simple::List
        my $slWidget = Gtk2::Ex::Simple::List->new(@columnList);
        $packingBox2->add_with_viewport($slWidget);

        # Make all columns of type 'bool' (which are composed of checkbuttons) non-activatable, so
        #   that the user can't click them on and off
        $numColumns = scalar (@columnList / 2);
        $count = -1;
        do {

            my ($heading, $type);

            $heading = shift @columnList;
            $type = shift @columnList;

            $count++;

            if ($type eq 'bool') {

                my ($cellRenderer) = $slWidget->get_column($count)->get_cell_renderers();
                $cellRenderer->set(activatable => FALSE);
            }

        } until (! @columnList);

        # Fill the simple list
        @{$slWidget->{data}} = @dataList;

        # Update IVs
        $self->ivPoke('funcRef', $funcRef);
        $self->ivPoke('funcID', $funcID);
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('slWidget', $slWidget);
        $self->ivPoke('numColumns', $numColumns);

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    sub set_cell {

        my ($self, $x, $y, $item, $check) = @_;

        # Local variables
        my $slWidget;

        # Check for improper arguments
        if (! defined $x || ! defined $y || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->set_cell', @_);
        }

        $slWidget = $self->slWidget;
        ${$slWidget->{data}}[$x][$y] = $item;

        return 1;
    }

#   sub set_func {}                 # Inherited from GA::Generic::Table

#   sub set_id {}                   # Inherited from GA::Generic::Table

    sub set_list {

        my ($self, @list) = @_;

        # Local variables
        my $slWidget;

        # (No improper arguments to check)

        $slWidget = $self->slWidget;
        @{$slWidget->{data}} = @list;

        return 1;
    }

    sub set_row {

        my ($self, $y, @list) = @_;

        # Local variables
        my $slWidget;

        # Check for improper arguments
        if (! defined $y) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->set_item', @_);
        }

        $slWidget = $self->slWidget;
        ${$slWidget->{data}}[$y] = \@list;

        return 1;
    }

    sub set_select {

        my ($self, $y, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->set_select', @_);
        }

        if (defined $y) {
            $self->slWidget->select($y);
        } else {
            $self->slWidget->unselect_all();
        }

        return 1;
    }

    # (Get equivalents)

    sub get_cell {

        my ($self, $x, $y, $check) = @_;

        # Local variables
        my $slWidget;

        # Check for improper arguments
        if (! defined $x || ! defined $y || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->get_cell', @_);
        }

        $slWidget = $self->slWidget;
        return ${$slWidget->{data}}[$x][$y];
    }

    sub get_row {

        my ($self, $y, $check) = @_;

        # Local variables
        my $slWidget;

        # Check for improper arguments
        if (! defined $y || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->set_item', @_);
        }

        $slWidget = $self->slWidget;
        return ${$slWidget->{data}}[$y];
    }

    sub get_select {

        my ($self, $check) = @_;

        # Local variables
        my $rowNum;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->get_select', @_);
        }

        ($rowNum) = $self->slWidget->get_selected_indices();

        return $rowNum;
    }

    ##################
    # Accessors - get

    sub slWidget
        { $_[0]->{slWidget} }

    sub numColumns
        { $_[0]->{numColumns} }
}

{ package Games::Axmud::Table::TextView;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::TextView, which contains a simple Gtk2::TextView
        # If all you want to do is to display some monochrome text in a scrolling textview (and
        #   optionally allow the user to edit it), use this table object
        # For anything more ambitious, use a GA::Table::Pane object
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'frame_title' - If specified, the table object is drawn inside a frame
        #                       with the specified title. If 'undef', an empty string or not
        #                       specified, the table object does not use a frame and title
        #                   'func' - Reference to a function to call when an the contents of the
        #                       textview is edited. If not specified or 'undef', it's up to the
        #                       calling code to create its own ->signal_connect. To obtain a
        #                       reference to an OOP method, you can use the generic object function
        #                       Games::Axmud->getMethodRef()
        #                   'id' - A value passed to the function which identifies the button. If
        #                       specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'text' - String containing text and newline characters. If 'undef' or
        #                       not specified, the textview is initially empty
        #                   'edit_flag' - If TRUE, the contents of the textview can be edited. If
        #                       FALSE (or not specified), the contents can't be edited
        #                   'system_flag' - If TRUE, the system's preferred colours/fonts are
        #                       used. If FALSE (or not specified), an Axmud colour scheme is used
        #                   'colour_scheme' - The name of the colour scheme to use (matches a key
        #                       in GA::Client->colourSchemeHash). If not specified or 'undef', the
        #                       parent window's colour scheme is used
        #                   'spacing' - The size (in pixels) of the gap between the textview itself
        #                       and its containing Gtk2::Frame. A value in the range 0-100. If
        #                       'undef', not specified or an invalid value, a value of 0 is used
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'frame_title'               => undef,
            'func'                      => undef,
            'id'                        => '',
            'text'                      => '',
            'edit_flag'                 => FALSE,
            'system_flag'               => FALSE,
            'colour_scheme'             => undef,
            'spacing'                   => 0,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if ($key eq 'edit_flag' || $key eq 'system_flag') {

                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } elsif ($key eq 'id' && ! defined $initHash{$key}) {

                    $modHash{$key} = '';        # 'id' value must not be 'undef'

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'text_view',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value except 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            packingBox                  => undef,       # Gtk2::VBox or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::VBox

            # Other IVs
            # ---------

            # Widgets
            frame                       => undef,       # Gtk2::Frame (may be 'undef')
            scroll                      => undef,       # Gtk2::ScrolledWindow
            textView                    => undef,       # Gtk2::TextView
            buffer                      => undef,       # Gtk2::TextBuffer
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($funcRef, $funcID, $text, $editFlag, $systemFlag, $colourScheme, $spacing, $winType);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $funcRef = $self->ivShow('initHash', 'func');
        $funcID = $self->ivShow('initHash', 'id');
        $text = $self->ivShow('initHash', 'text');
        if (! defined $text) {

            $text = '';
        }

        $editFlag = $self->testFlag($self->ivShow('initHash', 'edit_flag'));
        $systemFlag = $self->testFlag($self->ivShow('initHash', 'system_flag'));
        $colourScheme = $self->ivShow('initHash', 'colour_scheme');
        $spacing = $self->testInt($self->ivShow('initHash', 'spacing'), 0, 0);

        # Create packing box(es)
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::VBox->new(FALSE, 0));

        # Create the Gtk2::TextView inside a Gtk2::Frame and Gtk2::ScrolledWindow. However, if
        #   $packingBox is itself a Gtk2::Frame, don't create a second one
        my ($frame, $scroll);
        if (! $packingBox->isa('Gtk2::Frame')) {

            $frame = Gtk2::Frame->new(undef);
            # (Using TRUE, TRUE rather than the usual FALSE, FALSE forces the Gtk2::TextView to take
            #   up its full allocated size in the Gtk2::Table)
            $packingBox2->pack_start($frame, TRUE, TRUE, 0);
            $frame->set_border_width($spacing);

            $scroll = Gtk2::ScrolledWindow->new(undef, undef);
            $frame->add($scroll);

        } else {

            my $scroll = Gtk2::ScrolledWindow->new(undef, undef);
            $packingBox2->pack_start($scroll, TRUE, TRUE, 0);
        }

        $scroll->set_shadow_type('etched-out');
        $scroll->set_policy('automatic', 'automatic');
        $scroll->set_border_width($spacing);

        # Create a textview
        my $textView;
        if ($systemFlag) {

            # Using the sub-class preserves the system's preferred colours/fonts
            $textView = Games::Axmud::Widget::TextView::Gtk2->new();

        } else {

            # Use colours/fonts specified by an Axmud colour scheme
            if (
                defined $colourScheme
                && $axmud::CLIENT->ivExists('colourSchemeHash', $colourScheme)
            ) {
                $axmud::CLIENT->desktopObj->getTextViewStyle($colourScheme);
            } else {
                $axmud::CLIENT->desktopObj->getTextViewStyle($self->winObj->winType);
            }

            $textView = Gtk2::TextView->new();
        }

        $scroll->add($textView);
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);

        if (! $editFlag) {

            $textView->set_editable(FALSE);
            $textView->set_cursor_visible(FALSE);
            $textView->can_focus(FALSE);

        } else {

            $textView->set_editable(TRUE);
            $textView->set_cursor_visible(TRUE);
            $textView->can_focus(TRUE);
        }

        $textView->set_wrap_mode('word-char');      # Wrap words if possible, characters if not
        $textView->set_justification('left');
        $buffer->set_text($text);

        # Update IVs
        $self->ivPoke('funcRef', $funcRef);
        $self->ivPoke('funcID', $funcID);
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('frame', $frame);
        $self->ivPoke('scroll', $scroll);
        $self->ivPoke('textView', $textView);
        $self->ivPoke('buffer', $buffer);

        # Set up ->signal_connects
        $self->setChangedEvent();

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    sub setChangedEvent {

        # Called by $self->objEnable
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setChangedEvent', @_);
        }

        $self->buffer->signal_connect('changed' => sub {

            my $currentFuncRef = $self->funcRef;

            if ($currentFuncRef) {

                &$currentFuncRef(
                    $self,
                    $self->textView,
                    $self->buffer,
                    $self->funcID,
                    $axmud::CLIENT->desktopObj->bufferGetText($self->buffer),
                );
            }
        });

        return 1;
    }

    # Other functions

    ##################
    # Accessors - set

    sub set_editable {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_editable', @_);
        }

        if (! $flag) {

            $self->textView->set_editable(FALSE);
            $self->textView->set_cursor_visible(FALSE);
            $self->textView->can_focus(FALSE);

        } else {

            $self->textView->set_editable(TRUE);
            $self->textView->set_cursor_visible(TRUE);
            $self->textView->can_focus(TRUE);
        }

        return 1;
    }

#   sub set_func {}                 # Inherited from GA::Generic::Table

#   sub set_id {}                   # Inherited from GA::Generic::Table

    sub set_text {

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->set_text', @_);
        }

        if (! defined $text) {

            $text = '';
        }

        $self->buffer->set_text($text);

        return 1;
    }

    sub insert_text {

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->insert_text_at_cursor', @_);
        }

        if (! defined $text) {

            $text = '';
        }

        $self->buffer->insert_at_cursor ($text);

        return 1;
    }

    # (Get equivalents)

    sub get_editable {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->get_editable', @_);
        }

        if ($self->textView->get_editable()) {
            return TRUE;
        } else {
            return FALSE;
        }
    }

    sub get_text {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->get_text', @_);
        }

        return $axmud::CLIENT->desktopObj->bufferGetText($self->buffer);
    }

    ##################
    # Accessors - get

    sub frame
        { $_[0]->{frame} }
    sub scroll
        { $_[0]->{scroll} }
    sub textView
        { $_[0]->{textView} }
    sub buffer
        { $_[0]->{buffer} }
}

# Complex table objects

{ package Games::Axmud::Table::Pane;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::Pane, which contains one or more Gtk2::TextViews sharing a single
        #   Gtk2::TextBuffer
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'frame_title' - If specified, the table object is drawn inside a frame
        #                       with the specified title. If 'undef', an empty string or not
        #                       specified, the table object does not use a frame and title
        #                   'no_label_flag' - TRUE if a single tab should not have a tab label,
        #                       FALSE if it should have one (when there are multipled tabs, all tabs
        #                       have tab labels). If not specified at all, the value stored in
        #                       GA::Client->simpleTabFlag is used. Most of the time, this flag
        #                       should not be specified when creating a pane with a default tab (one
        #                       used by sessions to display most of the text received from the
        #                       world), but SHOULD be specified when creating any other pane
        #                   'entry_flag' - TRUE if a Gtk2::Entry should be drawn beneath the
        #                       textview(s), FALSE if not. Ignored if 'func' is not also specified
        #                   'func' - Reference to a function to call when the user types something
        #                       in the pane's own entry box and presses 'return'. If not specified
        #                       or 'undef', it's up to the calling code to create its own
        #                       ->signal_connect. Ignored if 'entry_flag' is FALSE. To obtain a
        #                       reference to an OOP method, you can use the generic object function
        #                       Games::Axmud->getMethodRef()
        #                   'id' - A value passed to the function which identifies this pane. If
        #                       specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'switch_func' - Reference to a function to call when a tab becomes the
        #                       visible one (including when it is created). Not required for
        #                       sessions using this pane object for their default tabs, as the
        #                       code checks for that separately
        #                   'switch_id' - A value passed to the function which identifies this
        #                       pane. If specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'split_mode' - 'single' if split screen mode is off, 'split' or 'hidden'
        #                       if split screen mode is on (for 'hidden', the divider is initially
        #                       positioned at the top of the screen). If not specified or an
        #                       unrecognised value, 'single' is used
        #                   'colour_scheme' - The name of a colour scheme to use in this pane's
        #                       textviews (if the colour scheme is updated, so are the colours and
        #                       fonts used in the textviews). If not specified or if the named
        #                       colour scheme doesn't exist, uses the colour scheme named after the
        #                       window type
        #                   'max_lines' - The maximum number of lines for the textview buffer. If
        #                       specified, must be 0 (meaning no maximum; not recommended) or a
        #                       positive integer between GA::Client->constMinBufferSize and
        #                       ->constMaxBufferSize (inclusive)
        #                   'new_line' - The default behaviour when a string is inserted into the
        #                       tab's textview: 'before' prepends a newline character to the string,
        #                       'after' prepends a newline character after the string, 'echo' does
        #                       not prepend/a newline character by default. If 'undef' or an
        #                       unrecognised value, 'after' is used
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj, $colourScheme,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        if (
            $number != -1
            && (! $colourScheme || ! $axmud::CLIENT->ivShow('colourSchemeHash', $colourScheme))
        ) {
            $colourScheme = $stripObj->winObj->winType;
        }

        %modHash = (
            'frame_title'               => undef,
            'no_label_flag'             => $axmud::CLIENT->simpleTabFlag,
            'entry_flag'                => FALSE,
            'func'                      => undef,
            'id'                        => '',
            'switch_func'               => undef,
            'switch_id'                 => '',
            'split_mode'                => 'single',
            'colour_scheme'             => $colourScheme,
            'max_lines'                 => $axmud::CLIENT->customTextBufferSize,
            'new_line'                  => 'after',
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                if (
                    $key eq 'no_label_flag'
                    || $key eq 'entry_flag'
                ) {
                    if ($initHash{$key}) {
                        $modHash{$key} = TRUE;
                    } else {
                        $modHash{$key} = FALSE;
                    }

                } elsif ($key eq 'max_lines') {

                    if (
                        $initHash{$key} == 0
                        || (
                            $initHash{$key} >= $axmud::CLIENT->constMinBufferSize
                            && $initHash{$key} <= $axmud::CLIENT->constMaxBufferSize
                        )
                    ) {
                        $modHash{$key} = $initHash{$key};
                    }

                } elsif (($key eq 'id' || $key eq 'switch_id') && ! defined $initHash{$key}) {

                    $modHash{$key} = '';        # 'id' value must not be 'undef'

                } elsif (
                    $key eq 'split_mode'
                    && (
                        $initHash{$key} eq 'single' || $initHash{$key} eq 'split'
                        || $initHash{$key} eq 'hidden'
                    )
                ) {
                    $modHash{$key} = $initHash{$key};

                } elsif (
                    $key eq 'new_line'
                    && defined $initHash{$key}
                    && ($initHash{$key} eq 'echo' || $initHash{$key} eq 'before')
                ) {
                    $modHash{$key} = $initHash{$key};

                } else {

                    $modHash{$key} = $initHash{$key};
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'pane',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value except 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            packingBox                  => undef,       # Gtk2::VBox or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::VBox

            # Other IVs
            # ---------

            # Widgets
            notebook                    => undef,       # Gtk2::Notebook
            hBox                        => undef,       # Gtk2::HBox
            entry                       => undef,       # Gtk2::Entry

            # The normal and modified border widths to apply to $self->packingBox2 when this pane is
            #   selected and unselected by the switcher button in
            #   GA::Strip::Entry->setSwitchSignals
            normalBorderWidth           => 0,
            selectBorderWidth           => 5,

            # Hashes of tabs and their corresponding tab objects (GA::Obj::Tab), which store the
            #   widgets required to create, modify or remove each tab
            # Every tab contains a single textview object (GA::Obj::TextView). A textview object
            #   handles either a single Gtk2::TextView, or two Gtk2::TextViews sharing a single
            #   Gtk2::TextBuffer (depending on whether split screen mode is off or on)
            # The tab object stores that textview object, the controlling session (GA::Session)
            #   and details of which Gtk2 widgets to pack/unpack when the appearance of the tab is
            #   modified
            #
            # When a Gtk2::Notebook is in use, the Gtk2 inheritance tree looks like this:
            #       Gtk2::VBox                                  ($self->packingBox, ->packingBox2)
            #           Gtk2::Notebook
            #               Gtk2::VBox                          ($tabObj->packableObj)
            #                   Gtk2::ScrolledWindow            ($tabObj->packedObj)
            #                       Gtk2::TextView              ($tabObj->textViewObj->textView)
            # ...or like this, when split screen mode is on:
            #       Gtk2::VBox                                  ($self->packingBox, ->packingBox2)
            #           Gtk2::Notebook
            #               Gtk2::VBox                          ($tabObj->packableObj)
            #                   Gtk2::VPaned                    ($tabObj->packedObj)
            #                       Gtk2::Scroll
            #                           Gtk2::TextView          ($tabObj->textViewObj->textView)
            #                       Gtk2::Scroll
            #                           Gtk2::TextView          ($tabObj->textViewObj->textView2)
            # ..and the hash in the form
            #       $tabObjHash{unique_number} = blessed_reference_to_tab_object
            #
            # When a Gtk2::Notebook is not in use, the comments in this table object describe a
            #   'simple tab'. In reality, the simplified inheritance tree looks like this:
            #       Gtk2::VBox                                  ($self->packingBox, ->packingBox2)
            #           Gtk2::ScrolledWindow                    ($tabObj->packedObj)
            #               Gtk2::TextView                      ($tabObj->textViewObj->textView)
            # ...or like this, when split screen mode is on:
            #       Gtk2::VBox                                  ($self->packingBox, ->packingBox2)
            #           Gtk2::VPaned                            ($tabObj->packedObj)
            #               Gtk2::ScrolledWindow
            #                   Gtk2::TextView                  ($tabObj->textViewObj->textView)
            #               Gtk2::ScrolledWindow
            #                   Gtk2::TextView                  ($tabObj->textViewObj->textView2)
            #   ...and the hash contains a single key-value pair, in the form
            #       $tabObjHash{0} = blessed_reference_to_tab_object
            #
            # NB If a 'frame_title' was specified by the calling function, $self->packingBox will
            #   be a Gtk2::Frame, and $self->packingBox2 will be a Gtk2::VBox. If not, both
            #   $self->packingBox and ->packingBox2 will be the same Gtk2::VBox widget
            tabObjHash                  => {},
            # Number of tab objects created since this pane object was created (used to give each
            #   tab object a unique number). When converting from a simple tab to (normal) tabs, or
            #   vice-versa, ->tabObjHash is emptied and ->tabObjCount is reset
            tabObjCount                 => 0,
            # The visible tab object; set by $self->respondVisibleTab when the visible tab actually
            #   changes
            currentTabObj               => undef,
            # Flag set to TRUE while $self->convertSimpleTab and ->convertTab are in progress, so
            #   that various ->signal_connects know not to take action
            tabConvertFlag              => FALSE,

            # Reference to a function to call when a tab becomes the visible one (including when it
            #   is created). Not required for sessions using this pane object for their default
            #   tabs, as the code checks for that separately
            switchFuncRef               => undef,
            # A value passed to the $self->switchFuncRef which identifies this pane. If specified,
            #   can be any value except 'undef'. It's up to the calling code to keep track of the
            #   widgets it has created and their corresponding 'id' values
            switchFuncID                => '',
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Create packing box(es)
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::VBox->new(FALSE, 0));
        $packingBox2->set_border_width($self->normalBorderWidth);

        # Draw a Gtk2::Notebook, with textviews on each tab, if required
        my $notebook;
        if (! $self->ivShow('initHash', 'no_label_flag')) {

            $notebook = $self->drawNotebook();
            if (! $notebook) {

                return undef;

            } else {

                $packingBox2->pack_start($notebook, TRUE, TRUE, 0);
            }
        }

        # Draw a Gtk2::Entry, if specified
        my ($hBox, $entry);
        if (
            $self->ivShow('initHash', 'entry_flag')
            && $self->ivShow('initHash', 'func')
        ) {
            $hBox = Gtk2::HBox->new(FALSE, 0);
            $packingBox2->pack_end($hBox, FALSE, FALSE, $axmud::CLIENT->constGridSpacingPixels);

            $entry = Gtk2::Entry->new();
            $hBox->pack_start($entry, TRUE, TRUE, $axmud::CLIENT->constGridSpacingPixels);
        }

        # Update IVs
        $self->ivPoke('funcRef', $self->ivShow('initHash', 'func'));
        $self->ivPoke('funcID', $self->ivShow('initHash', 'id'));
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('notebook', $notebook);
        $self->ivPoke('hBox', $hBox);
        $self->ivPoke('entry', $entry);
        $self->ivPoke('switchFuncRef', $self->ivShow('initHash', 'switch_func'));
        $self->ivPoke('switchFuncID', $self->ivShow('initHash', 'switch_id'));

        # Set up ->signal_connects
        if ($self->entry) {

            $self->setActivateEvent();
        }

        return 1;
    }

    sub objDestroy {

        # Called by GA::Strip::Table->objDestroy, just before that strip is removed from its parent
        #   window, to give this object a chance to do any necessary tidying up
        # Generic function that can be inherited by any table object that doesn't need to do any
        #   tidying up
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objDestroy', @_);
        }

        # Tidy up any textview objects
        foreach my $tabObj ($self->ivValues('tabObjHash')) {

            $tabObj->textViewObj->objDestroy();
        }

        return 1;
    }

#   sub setWidgetsIfSession {}

#   sub setWidgetsChangeSession {}

    sub setWidgetsOnResize {

        # Called by GA::Strip::Table->resizeTableObj
        # Allows this table object to update its widgets whenever the table object is resized on its
        #   Gtk2::Table
        #
        # Expected arguments
        #   $left, $right, $top, $bottom
        #       - The coordinates of the top-left ($left, $top) and bottom-right ($right, $bottom)
        #           corners of the table object on the table after the resize
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $left, $right, $top, $bottom, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $left || ! defined $right || ! defined $top || ! defined $bottom
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setWidgetsOnResize', @_);
        }

        # For some reason, resizing the table object makes the Gtk2::TextView use the most recent
        #   rc file, which messes up the colours; therefore, we have to re-apply the colour scheme
        #   for each tab
        $self->updateColourScheme();

        return 1;
    }

    # ->signal_connects

    sub setSwitchPageEvent {

        # Called by $self->drawNotebook
        #
        # Expected arguments
        #   $notebook   - The Gtk2::Notebook which emits the signal
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $notebook, $check) = @_;

        # Check for improper arguments
        if (! defined $notebook || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setSwitchPageEvent', @_);
        }

        # This callback is intended to detect when the user clicks on one of the notebook's tabs,
        #   making that tab visible
        $notebook->signal_connect('switch-page' => sub {

            my ($widget, $num, $page) = @_;

            my $tabObj = $self->findPage($page);
            if ($tabObj) {

                $self->respondVisibleTab($tabObj);
            }
        });

        return 1;
    }

    sub setButtonClicked {

        # Called by $self->addTab
        #
        # Expected arguments
        #   $button     - The Gtk2::Button which emits the signal
        #   $session    - The GA::Session for the tab containining the button
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $button, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $button || ! defined $session || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setButtonClicked', @_);
        }

        $button->signal_connect('clicked' => sub {

            my $choice;

            if ($session->status eq 'connected' && $axmud::CLIENT->confirmCloseTabFlag) {

                $choice = $self->winObj->showMsgDialogue(
                    'Close tab',
                    'question',
                    'This session is connected to a world. Are you sure you want to close it?',
                    'yes-no',
                );

                if ($choice && $choice eq 'yes') {

                    $axmud::CLIENT->stopSession($session);
                }

            } else {

                $axmud::CLIENT->stopSession($session);
            }
        });

        return 1;
    }

    sub setActivateEvent {

        # Called by $self->objEnable
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setActivateEvent', @_);
        }

        $self->entry->signal_connect('activate' => sub {

            my ($value, $thisFuncRef);

            $value = $self->entry->get_text();
            $thisFuncRef = $self->funcRef;

            if ($thisFuncRef) {

                &$thisFuncRef($self, $self->entry, $self->funcID, $value);
            }

            $self->entry->set_text('');
        });

        return 1;
    }

    # Other functions

    sub drawNotebook {

        # Called by $self->objEnable and $self->convertSimpleTab
        # Draws a Gtk2::Notebook whose tabs can each contain a Gtk2::TextView
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the widget can't be drawn
        #   Otherwise returns the Gtk2::Notebook

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawNotebook', @_);
        }

        # Create the notebook, stored in $self->notebook
        my $notebook = Gtk2::Notebook->new();
        $notebook->set_scrollable(TRUE);
        $notebook->can_focus(FALSE);
        $notebook->set_tab_border(0);

        # Set up ->signal_connects
        $self->setSwitchPageEvent($notebook);

        return $notebook;
    }

    sub addSimpleTab {

        # Called by GA::Session->setDefaultTab, $self->convertTab or any other code
        # Adds a simple tab (containing a standalone textview object, not a page in a notebook)
        #
        # Expected arguments
        #   $session        - The GA::Session that will control the tab (and the textview object
        #                       it contains)
        #
        # Optional arguments
        #   $sessionFlag    - Flag set to TRUE if this tab was called by
        #                       GA::Session->setDefaultTab, FALSE (or 'undef') if it was called by
        #                       anything else
        #   $defaultFlag    - Flag set to TRUE if this tab will be $session's default tab (where
        #                       text received from the world is usually displayed), FALSE (or
        #                       'undef') otherwise (might be TRUE even if $sessionFlag is FALSE)
        #   $labelText      - The text to use in the tab label, ignored if specified (exists for
        #                       compatibility with other functions in this group)
        #   $oldBuffer      - If a Gtk2::Notebook with a single tab is being replaced by a
        #                       standalone textview object, the old textview object's
        #                       Gtk2::TextBuffer, which is transferred to the new textview object
        #                       ('undef' otherwise)
        #
        # Return values
        #   'undef' on improper arguments or if the simple tab can't be drawn
        #   Otherwise returns the tab object (GA::Obj::Tab) created, which stores (among other
        #       things) the textview object created

        my ($self, $session, $sessionFlag, $defaultFlag, $labelText, $oldBuffer, $check) = @_;

        # Local variables
        my ($textViewObj, $packedObj, $tabObj);

        # Check for improper arguments
        if (! defined $session || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addSimpleTab', @_);
        }

        # If this pane object has drawn a notebook, not a simple container (a Gtk2::ScrolledWindow
        #   or Gtk2::VPaned), $self->addTab should have been called instead. Show a warning, then
        #   redirect the function call
        if ($self->notebook) {

            $self->winObj->session->writeWarning(
                'Tried to add a simple tab to a notebook; code should call ->addTab, not'
                . ' ->addSimpleTab',
                $self->_objClass . '->addSimpleTab',
            );

            return $self->addTab($session, $sessionFlag, $defaultFlag, $labelText, $oldBuffer);

        # If there is already a simple tab, don't create another one
        } elsif ($self->tabObjHash) {

            return $self->writeError(
                'Tried to add a simple tab, but one or more tabs already exist',
                $self->_objClass . '->addSimpleTab',
            );
        }

        # Create a new GA::Obj::Textview object to handle the Gtk2::Textview(s)
        $textViewObj = $axmud::CLIENT->desktopObj->add_textView(
            $session,
            $self->winObj,
            $self,
        );

        if (! $textViewObj) {

            return undef;
        }

        # Create the Gtk2::TextView(s) themselves. The function call returns a Gtk2::ScrolledWindow
        #   or a Gtk2::VPaned containing the textview(s)
        $packedObj = $textViewObj->objEnable(
            $self->ivShow('initHash', 'split_mode'),
            $self->ivShow('initHash', 'colour_scheme'),
            $self->ivShow('initHash', 'max_lines'),
            $self->ivShow('initHash', 'new_line'),
            $oldBuffer,
        );

        if (! $packedObj) {

            $textViewObj->objDestroy();
            return undef;
        }

        # Pack the Gtk2::ScrolledWindow/Gtk2::VPaned into our main Gtk2::VBox
        $self->packingBox2->pack_start($packedObj, TRUE, TRUE, 0);

        # Create a tab object to store details about the tab
        $tabObj = Games::Axmud::Obj::Tab->new(
            0,                          # ->number
            $self,
            $session,
            $defaultFlag,
            $textViewObj,
            $self->packingBox2,         # ->packableObj
            $packedObj,                 # ->packedObj
        );

        # Update IVs. The code above has already checked that $self->tabObjHash is empty
        $self->ivAdd('tabObjHash', $tabObj->number, $tabObj);
        $self->ivIncrement('tabObjCount');

        # Make the changes visible
        $self->winObj->winShowAll($self->_objClass . '->addSimpleTab');

        # The new tab is the visible tab
        $self->respondVisibleTab($tabObj, $sessionFlag);

        return $tabObj;
    }

    sub addTab {

        # Called by GA::Session->setDefaultTab, $self->convertSimpleTab or by any other code
        # Adds a (normal) tab to the Gtk2::Notebook
        #
        # Expected arguments
        #   $session        - The GA::Session that will control the tab (and the textview object
        #                       it contains)
        #
        # Optional arguments
        #   $sessionFlag    - Flag set to TRUE if this tab was called by
        #                       GA::Session->setDefaultTab, FALSE (or 'undef') if it was called by
        #                       anything else
        #   $defaultFlag    - Flag set to TRUE if this tab will be $session's default tab (where
        #                       text received from the world is usually displayed), FALSE (or
        #                       'undef') otherwise (might be TRUE even if $sessionFlag is FALSE)
        #   $labelText      - The text to use in the tab label (empty strings are acceptable). If
        #                       'undef', 'Tab #' is used
        #   $oldBuffer      - If a standalone textview object is being replaced by a Gtk2::Notebook
        #                       with a single tab, the old textview object's Gtk2::TextBuffer, which
        #                       is transferred to the new textview object ('undef' otherwise)
        #
        # Return values
        #   'undef' on improper arguments or if the tab can't be drawn
        #   Otherwise returns the tab object (GA::Obj::Tab) created, which stores (among other
        #       things) the textview object created

        my ($self, $session, $sessionFlag, $defaultFlag, $labelText, $oldBuffer, $check) = @_;

        # Local variables
        my ($textViewObj, $packedObj, $tabObj);

        # Check for improper arguments
        if (! defined $session || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addTab', @_);
        }

        # If this table object isn't using a notebook, but a simple container (a
        #   Gtk2::ScrolledWindow or a Gtk2::VPaned), convert from the latter to the former
        if (! $self->notebook && ! $self->convertSimpleTab()) {

            # (Error message displayed by called function)
            return undef;
        }

        # Create the tab

        # The tab contains a vertical packing box, which contains everything else
        my $vBox = Gtk2::VBox->new(FALSE, 0);
        $vBox->set_border_width(0);

        # A horizontal packing box is used as the tab's label (in place of a Gtk2::Label)
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        my $label = Gtk2::Label->new();
        $hBox->pack_start($label, FALSE, FALSE, 0);
        $label->show();

        # Add an 'X' button to close the tab, if needed
        my $button = Gtk2::Button->new();
        $hBox->pack_start($button, FALSE, FALSE, 0);
        $button->set_image(Gtk2::Image->new_from_stock('gtk-close', 'menu'));
        $button->set_relief('none');
        $button->show();

        # Create a new GA::Obj::Textview object to handle the Gtk2::Textview(s)
        $textViewObj = $axmud::CLIENT->desktopObj->add_textView(
            $session,
            $self->winObj,
            $self,
        );

        if (! $textViewObj) {

            return undef;
        }

        # Create the Gtk2::TextView(s) themselves. The function call returns a Gtk2::ScrolledWindow
        #   or a Gtk2::VPaned containing the textview(s)
        $packedObj = $textViewObj->objEnable(
            $self->ivShow('initHash', 'split_mode'),
            $self->ivShow('initHash', 'colour_scheme'),
            $self->ivShow('initHash', 'max_lines'),
            $self->ivShow('initHash', 'new_line'),
            $oldBuffer,
        );

        if (! $packedObj) {

            $textViewObj->objDestroy();
            return undef;
        }

        # Pack the Gtk2::ScrolledWindow/Gtk2::VPaned into this tab's Gtk2::VBox
        $vBox->pack_start($packedObj, TRUE, TRUE, 0);

        # From Gtk documentation: 'Note that due to historical reasons, GtkNotebook refuses to
        #   switch to a page unless the child widget is visible. Therefore, it is recommended to
        #   show child widgets before adding them to a notebook.'
        $vBox->show();
        $hBox->show();

        # Add the tab to the notebook
        my $tabNum = $self->notebook->append_page($vBox, $hBox);

        # Make the tab re-orderable
        my $tabWidget = $self->notebook->get_nth_page($tabNum);
        $self->notebook->set_tab_reorderable($tabWidget, TRUE);

        # If no label text was specified, use the default text
        if (! defined $labelText) {

            $labelText = 'Tab #' . $tabNum;
        }

        $label->set_markup($labelText);

        # Create a tab object to store details about the tab
        $tabObj = Games::Axmud::Obj::Tab->new(
            $self->tabObjCount,         # ->number
            $self,
            $session,
            $defaultFlag,
            $textViewObj,
            $vBox,                      # ->packableObj
            $packedObj,                 # ->packedObj
            $vBox,                      # ->tabWidget
            $label,                     # ->tabLabel
        );

        # Update IVs
        $self->ivAdd('tabObjHash', $tabObj->number, $tabObj);
        $self->ivIncrement('tabObjCount');

        # The new tab should be the visible (current) one
        # NB When replacing a standalone textview object with a Gtk2::Notebook, adding the old
        #   textview object's buffer to the new notebook's first tab, we don't set the first tab as
        #   the current page - because the calling function wants to set the (new) second tab as the
        #   current page
        if (! $oldBuffer) {

            $self->notebook->set_current_page($tabNum);
        }

        # After replacing a standalone textview object with a Gtk2::Notebook, the original session's
        #   textview(s) don't scroll to the bottom (as it should) without this code (and placing the
        #   code anywhere else doesn't work, either)
        if ($oldBuffer) {

            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->addTab');
        }

        # Set up ->signal_connects
        $self->setButtonClicked($button, $session);

        # Make the changes visible
        $self->winObj->winShowAll($self->_objClass . '->addTab');

        # The new tab is the visible tab. The call above to ->set_current_page ought to have
        #   caused a call to $self->respondVisibleTab, but if $sessionFlag is set, call it again,
        #   forcing it to call GA::Win::Internal->setVisibleSession at least once
        if ($sessionFlag) {

            $self->respondVisibleTab($tabObj, $sessionFlag);
        }

        return $tabObj;
    }

    sub removeTab {

        # Called by GA::Session->stop (only)
        # Removes the tab containing the default textview object for the calling session (if other
        #   parts of the code want to remove a non-default tab, they should call
        #   $self->removeTabNum)
        # After removing the tab, if there is then only a single session open, and if the
        #   initialisation setting demands that we use a simple tab rather than a Gtk2::Notebook
        #   tab, replace the notebook with a simple tab
        #
        # Expected arguments
        #   $session    - The GA::Session for the tab to be removed
        #
        # Return values
        #   'undef' on improper arguments, or if the tab widgets can't be removed or if the
        #       session's default tab can't be found
        #   1 on success

        my ($self, $session, $check) = @_;

        # Local variables
        my $tabObj;


        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeTab', @_);
        }

        if (! $self->notebook) {

            # A simple tab, containing a standalone textview object
            $tabObj = $self->ivShow('tabObjHash', 0);
            if (! $tabObj || ! $tabObj->defaultFlag || $tabObj->session ne $session) {

                # (Error message displayed by calling function)
                return undef;
            }

            # Remove the simple tab by removing everything from the main packing box
            $axmud::CLIENT->desktopObj->removeWidget($self->packingBox2, $tabObj->packedObj);
            # Inform the textview object (if any) of its demise
            if ($tabObj->textViewObj) {

                $tabObj->textViewObj->objDestroy();
            }

            # Update IVs
            $self->ivEmpty('tabObjHash');
            $self->ivPoke('tabObjCount', 0);

        } else {

            # A tab in a Gtk2::Notebook. Find which one corresponds to the session
            $tabObj = $self->findSession($session);
            if (! defined $tabObj) {

                # (Error message displayed by calling function)
                return undef;
            }

            # Remove the tab from its Gtk2::Notebook
            $self->notebook->remove_page($self->notebook->page_num($tabObj->tabWidget));
            # Inform the textview object (if any) of its demise
            if ($tabObj->textViewObj) {

                $tabObj->textViewObj->objDestroy();
            }

            # Update IVs
            $self->ivDelete('tabObjHash', $tabObj->number);

            # If there is only one tab left, and if the initialisation setting specifies that a
            #   single notebook tab should be replaced by a simple tab, perform the replacement
            #   operation
            if (
                $self->ivPairs('tabObjHash') == 1
                && $self->ivShow('initHash', 'no_label_flag')
            ) {
                if (! $self->convertTab()) {

                    # (Error message already displayed)
                    return undef;
                }
            }
        }

        # Make the changes visible
        $self->winObj->winShowAll($self->_objClass . '->removeTab');

        return 1;
    }

    sub convertSimpleTab {

        # Called by $self->addTab, when a simple tab is currently visible
        #
        # Converts the standalone textview object (a simple tab) into a new tab on a Gtk2::Notebook,
        #   preserving the Gtk2::TextBuffer
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($oldTabObj, $newTabObj, $notebook);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->convertSimpleTab', @_);
        }

        # Set a flag that various ->signal_connects can use to avoid responding when a tab
        #   conversion operation is in progress
        $self->ivPoke('tabConvertFlag', TRUE);

        # Get the single existing tab
        $oldTabObj = $self->ivShow('tabObjHash', 0);

        # Remove the standalone textview object
        $axmud::CLIENT->desktopObj->removeWidget($self->packingBox2, $oldTabObj->packedObj);

        # Add a Gtk2::Notebook in its place
        $notebook = $self->drawNotebook();
        if (! $notebook) {

            # Emergency fallback - put the old textview back, as if nothing had happened (but show a
            #   warning)
            $self->packingBox2->pack_start($oldTabObj->packedObj, TRUE, TRUE, 0);

            return $self->writeWarning(
                'General error converting simple tab',
                $self->_objClass . '->convertSimpleTab',
            );
        }

        # Gtk2::Notebook created
        $self->packingBox2->pack_start($notebook, TRUE, TRUE, 0);

        # Update IVs
        $self->ivPoke('notebook', $notebook);
        $self->ivEmpty('tabObjHash');
        $self->ivPoke('tabObjCount', 0);

        # Add a tab in its place, using the old textview object's buffer and the old session number
        $newTabObj = $self->addTab(
            $oldTabObj->session,
            undef,                          # Not called by GA::Session->setDefaultTab
            $oldTabObj->defaultFlag,
            $oldTabObj->session->getTabLabelText(),
            $oldTabObj->textViewObj->buffer,
        );

        # Restore the scroll lock, if it was enabled in the old single textview
        if ($oldTabObj->textViewObj->scrollLockFlag) {

            $newTabObj->textViewObj->toggleScrollLock();
        }

        # Restore the old single textview's split screen mode
        $newTabObj->textViewObj->setSplitScreenMode($oldTabObj->textViewObj->splitScreenMode);

        # Update the GA::Session's tab IVs, as required
        if (
            $oldTabObj->session->defaultTabObj
            && $oldTabObj->session->defaultTabObj eq $oldTabObj
        ) {
            $oldTabObj->session->set_defaultTabObj($newTabObj);
        }

        if (
            $oldTabObj->session->currentTabObj
            && $oldTabObj->session->currentTabObj eq $oldTabObj
        ) {
            $oldTabObj->session->set_currentTabObj($newTabObj);
        }

        # Operation compelte
        $self->ivPoke('tabConvertFlag', FALSE);

        return 1;
    }

    sub convertTab {

        # Called by $self->removeTab when there's only a single Gtk2::Notebook tab left, and the
        #   initialisation setting specifies that a tab label shouldn't be visible
        # Converts the Gtk2::Notebook containing a single remaining tab into a standalone textview
        #   object, preserving its Gtk2::TextBuffer (a simple tab)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my ($self, $tabObj, $check) = @_;

        # Local variables
        my ($oldTabObj, $scroll, $newTabObj);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->convertTab', @_);
        }

        # Set a flag that various ->signal_connects can use to avoid responding when a tab
        #   conversion operation is in progress
        $self->ivPoke('tabConvertFlag', TRUE);

        # Get the single remaining tab (the calling function has already checked there is only one)
        ($oldTabObj) = $self->ivValues('tabObjHash');
        if (! $oldTabObj) {

            return $self->writeWarning(
                'General error converting tab',
                $self->_objClass . '->convertTab',
            );
        }

        # Remove the Gtk2::Notebook
        $axmud::CLIENT->desktopObj->removeWidget($self->packingBox2, $self->notebook);

        # Add a standalone textview object in its place
        $axmud::CLIENT->desktopObj->removeWidget($oldTabObj->packableObj, $oldTabObj->packedObj);
        $self->packingBox2->pack_start($oldTabObj->packedObj, TRUE, TRUE, 0);

        # Update IVs
        $self->ivUndef('notebook');
        $self->ivEmpty('tabObjHash');
        $self->ivPoke('tabObjCount', 0);

        # Add a simple tab in its place, using the old tab's buffer and the old session
        $newTabObj = $self->addSimpleTab(
            $oldTabObj->session,
            undef,                          # Not called by GA::Session->setDefaultTab
            $oldTabObj->defaultFlag,
            $oldTabObj->session->getTabLabelText(),
            $oldTabObj->textViewObj->buffer,
        );

        # Restore the scroll lock, if it was enabled in the old single textview
        if ($oldTabObj->textViewObj->scrollLockFlag) {

            $newTabObj->textViewObj->toggleScrollLock();
        }

        # Restore the old single textview's split screen mode
        $newTabObj->textViewObj->setSplitScreenMode($oldTabObj->textViewObj->splitScreenMode);

        # Update the GA::Session's tab IVs, as required
        if (
            $oldTabObj->session->defaultTabObj
            && $oldTabObj->session->defaultTabObj eq $oldTabObj
        ) {
            $oldTabObj->session->set_defaultTabObj($newTabObj);
        }

        if (
            $oldTabObj->session->currentTabObj
            && $oldTabObj->session->currentTabObj eq $oldTabObj
        ) {
            $oldTabObj->session->set_currentTabObj($newTabObj);
        }

        # Operation compelte
        $self->ivPoke('tabConvertFlag', FALSE);

        return 1;
    }

    sub updateColourScheme {

        # Called by GA::Win::Internal->updateColourScheme (only)
        # When a colour scheme is modified, checks all textview objects in this pane object and
        #   updates any that use the modified colour scheme. Alternatively, when no colour scheme is
        #   specified, updates all textview objects
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $colourScheme   - The name of the modified colour scheme (matches a key in
        #                       GA::Client->colourSchemeHash; the calling function has already
        #                       checked it is valid). If 'undef', all pane objects are updated
        #   $noDrawFlag     - TRUE when the calling function was itself called by
        #                       GA::Win::Internal->redrawWidgets, which doesn't want this function
        #                       to call GA::Win::Generic->winShowAll or
        #                       GA::Obj::Desktop->updateWidgets as it normally would. FALSE (or
        #                       'undef') otherwise
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $colourScheme, $noDrawFlag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->updateColourScheme', @_);
        }

        # Update each tab in turn
        OUTER: foreach my $tabObj ($self->ivValues('tabObjHash')) {

            my $packedObj;

            if (! $colourScheme || $tabObj->textViewObj->colourScheme eq $colourScheme) {

                $packedObj = $tabObj->textViewObj->objUpdate($colourScheme);
                if (defined $packedObj) {

                    $axmud::CLIENT->desktopObj->removeWidget(
                        $tabObj->packableObj,
                        $tabObj->packedObj,
                    );

                    $tabObj->packableObj->pack_start($packedObj, TRUE, TRUE, 0);
                    $tabObj->ivPoke('packedObj', $packedObj);
                }
            }
        }

        if (! $noDrawFlag) {

            # (If we try to scroll the textviews before they've been packed, we get an uncomfortable
            #   flash, so the scrolling function is called last)
            $self->winObj->winShowAll($self->_objClass . '->updateColourScheme');
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->updateColourScheme');

            foreach my $tabObj ($self->ivValues('tabObjHash')) {

                $tabObj->textViewObj->scrollToLock();
            }
        }

        return 1;
    }

    sub applyColourScheme {

        # Can be called by anything to apply a new colour scheme to one or more of this pane
        #   object's tabs (in contrast to $self->updateColourScheme, which is only called by
        #   GA::Win::Internal->winUpdate and applies a modified colour scheme to any textview
        #   object that uses it)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $tabObj         - The tab object (GA::Obj::Tab) containing the textview object to which
        #                       the colour scheme must be applied. If 'undef', the colour scheme is
        #                       applied to all tabs in this pane object
        #   $colourScheme   - The name of the colour scheme to apply (matches a key in
        #                       GA::Client->colourSchemeHash). If unrecognised or 'undef', a default
        #                       colour scheme for the parent window is applied to the textview
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my ($self, $tabObj, $colourScheme, $check) = @_;

        # Local variables
        my @tabList;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->applyColourScheme', @_);
        }

        # Compile a list of tabs whose textview objects should be modified
        if ($tabObj) {
            push (@tabList, $tabObj);
        } else {
            push (@tabList, $self->ivValues('tabObjHash'));
        }

        # Set the colour scheme to use, if a valid one wasn't specified
        if (
            ! defined $colourScheme
            || ! $axmud::CLIENT->ivExists('colourSchemeHash', $colourScheme)
        ) {
            $colourScheme = $self->winObj->winType;
        }

        # Apply the colour scheme
        foreach my $thisTabObj (@tabList) {

            my $packedObj = $thisTabObj->textViewObj->objUpdate($colourScheme);
            if (defined $packedObj) {

                $axmud::CLIENT->desktopObj->removeWidget(
                    $thisTabObj->packableObj,
                    $thisTabObj->packedObj,
                );

                $thisTabObj->packableObj->pack_start($packedObj, TRUE, TRUE, 0);
                $thisTabObj->ivPoke('packedObj', $packedObj);
            }
        }

        # (If we try to scroll the textviews before they've been packed, we get an uncomfortable
        #   flash, so the scrolling function is called last)
        $self->winObj->winShowAll($self->_objClass . '->applyColourScheme');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->applyColourScheme');
        foreach my $tabObj (@tabList) {

            $tabObj->textViewObj->scrollToLock();
        }

        return 1;
    }

    sub applyMonochrome {

        # Can be called by anything to switch on monochrome mode for one or more of the tabs in this
        #   pane object (or, for any tabs already in monochrome mode, to change the colour used)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $tabObj - The tab object (GA::Obj::Tab) containing the textview object whose monochrome
        #               mode must be switched on.  If 'undef', monochrome mode is switched on for
        #               all tabs in this pane object
        #   $backgroundColour
        #           - The background colour to use (can be any Axmud colour tag, e.g 'red'). If it's
        #               an underlay tag like 'ul_red', the equivalent colour tag is used instead. If
        #               'undef', the tab's current colour scheme (set by a call to
        #               $self->applyColourScheme) is used to select a background colour
        #   $textColour
        #           - The text colour to use. Is normally 'undef', in which case this function will
        #               choose a suitable text colour to match the background. Should be specified
        #               if $backgroundColour is an Xterm or RGB colour tag, otherwise the text
        #               colour might not suit the background colour
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my ($self, $tabObj, $backgroundColour, $textColour, $check) = @_;

        # Local variables
        my (
            $mode,
            @tabList,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->applyMonochrome', @_);
        }

        # Compile a list of tabs whose textview objects should be modified
        if ($tabObj) {
            push (@tabList, $tabObj);
        } else {
            push (@tabList, $self->ivValues('tabObjHash'));
        }

        # If colours were specified, check they are valid
        if (defined $backgroundColour) {

            ($mode) = defined $axmud::CLIENT->checkColourTags($backgroundColour);
            if (! $mode) {

                return undef;
            }

        } elsif (defined $textColour) {

            ($mode) = defined $axmud::CLIENT->checkColourTags($textColour);
            if (! $mode) {

                return undef;
            }
        }

        # Switch on monochrome mode for the specified tab(s)
        foreach my $thisTabObj (@tabList) {

            my $packedObj
                = $thisTabObj->textViewObj->setMonochromeMode($backgroundColour, $textColour);

            if (defined $packedObj) {

                $axmud::CLIENT->desktopObj->removeWidget(
                    $thisTabObj->packableObj,
                    $thisTabObj->packedObj,
                );

                $thisTabObj->packableObj->pack_start($packedObj, TRUE, TRUE, 0);
                $thisTabObj->ivPoke('packedObj', $packedObj);
            }
        }

        # (If we try to scroll the textviews before they've been packed, we get an uncomfortable
        #   flash, so the scrolling function is called last)
        $self->winObj->winShowAll($self->_objClass . '->applyMonochrome');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->applyMonochrome');
        foreach my $tabObj (@tabList) {

            $tabObj->textViewObj->scrollToLock();
        }

        return 1;
    }

    sub removeMonochrome {

        # Can be called by anything to switch off monochrome mode for one or more of the tabs in
        #   this pane object
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $tabObj - The tab object (GA::Obj::Tab) containing the textview object whose monochrome
        #               mode must be switched off.  If 'undef', monochrome mode is switched off for
        #               all tabs in this pane object
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my ($self, $tabObj, $check) = @_;

        # Local variables
        my @tabList;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->removeMonochrome', @_);
        }

        # Compile a list of tabs whose textview objects should be modified
        if ($tabObj) {
            push (@tabList, $tabObj);
        } else {
            push (@tabList, $self->ivValues('tabObjHash'));
        }

        # Switch off monochrome mode for the specified tab(s)
        foreach my $thisTabObj (@tabList) {

            my $packedObj = $thisTabObj->textViewObj->resetMonochromeMode();
            if (defined $packedObj) {

                $axmud::CLIENT->desktopObj->removeWidget(
                    $thisTabObj->packableObj,
                    $thisTabObj->packedObj,
                );

                $thisTabObj->packableObj->pack_start($packedObj, TRUE, TRUE, 0);
                $thisTabObj->ivPoke('packedObj', $packedObj);
            }
        }

        # (If we try to scroll the textviews before they've been packed, we get an uncomfortable
        #   flash, so the scrolling function is called last)
        $self->winObj->winShowAll($self->_objClass . '->removeMonochrome');
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->removeMonochrome');
        foreach my $tabObj (@tabList) {

            $tabObj->textViewObj->scrollToLock();
        }

        return 1;
    }

    sub toggleScrollLock {

        # Called by GA::Cmd::ScrollLock->do or GA::Strip::Entry->setScrollSignals
        # Toggles the scroll lock in the active textview object
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the toggle operation fails
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($tabObj, $entryObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleScrollLock', @_);
        }

        # Get the visible tab's tab object
        if (! $self->notebook) {
            $tabObj = $self->ivShow('tabObjHash', 0);
        } else {
            $tabObj = $self->ivShow('tabObjHash', $self->notebook->get_current_page());
        }

        if (! $tabObj || ! $tabObj->textViewObj) {

            return undef;
        }

        # Toggle scroll lock
        $tabObj->textViewObj->toggleScrollLock();

        # Find the entry strip object (if it exists)
        $entryObj = $self->winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::Entry');
        if ($entryObj) {

            # Update the toolbutton icon for its scroll lock button
            $entryObj->updateScrollButton($tabObj->textViewObj->scrollLockFlag);
        }

        $self->winObj->winShowAll($self->_objClass . '->toggleScrollLock');

        return 1;
    }

    sub toggleSplitScreen {

        # Called by GA::Cmd::SplitScreen->do or GA::Strip::Entry->setSplitSignals
        # Toggles between split screen modes in the active textview object
        #
        # Before v1.0.905, textview objects had two split screen modes, 'on' and 'off'. Since then,
        #   textview objects have had three modes, but pane objects continue to distinguish only
        #   between 'on' and 'off'
        # The textview object modes 'single' and 'hidden' are considered 'off', and this function
        #   converts them to 'split'
        # The textview object mode 'split' is considered 'off', and this function converts it to
        #   'hidden'
        # In this way, for textview objects created by a pane object, split screen mode is only
        #   'single' when the textview object is created with that mode set. Once the mode is
        #   changed (by this function), it cannot be restored to 'single' (by this function)
        #
        # This change has been made because of Gtk2 performance issues, particularly with
        #   Gtk2::TextViews with large buffers. In general, any pane in which split screen mode
        #   might be turned 'on' should probably create the textview object using the mode 'hidden'
        #   rather than 'single'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the toggle operation fails
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($tabObj, $packedObj, $viewport, $entryObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleSplitScreen', @_);
        }

        # Get the visible tab's tab object
        if (! $self->notebook) {
            $tabObj = $self->ivShow('tabObjHash', 0);
        } else {
            $tabObj = $self->ivShow('tabObjHash', $self->notebook->get_current_page());
        }

        if (! $tabObj || ! $tabObj->textViewObj) {

            return undef;
        }

        # Get a new packable widget
        if (
            $tabObj->textViewObj->splitScreenMode eq 'single'
            || $tabObj->textViewObj->splitScreenMode eq 'hidden'
        ) {
            $packedObj = $tabObj->textViewObj->setSplitScreenMode('split');
        } else {
            $packedObj = $tabObj->textViewObj->setSplitScreenMode('hidden');
        }

        # If $packedObj is defined, it must be re-packed, replacing the old packable widget
        if ($packedObj) {

            $axmud::CLIENT->desktopObj->removeWidget($tabObj->packableObj, $tabObj->packedObj);
            $tabObj->packableObj->pack_start($packedObj, TRUE, TRUE, 0);
            $tabObj->ivPoke('packedObj', $packedObj);
        }

        # Find the entry strip object (if it exists)
        $entryObj = $self->winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::Entry');
        if ($entryObj) {

            # Update the toolbutton icon for its scroll lock button
            if ($tabObj->textViewObj->splitScreenMode eq 'split') {
                $entryObj->updateSplitButton(TRUE);
            } else {
                $entryObj->updateSplitButton(FALSE);
            }
        }

        if ($packedObj) {

            # (If we try to scroll the textviews before they've been re-packed, we get an
            #   uncomfortable flash, so the scrolling function is called last)
            $self->winObj->winShowAll($self->_objClass . '->toggleSplitScreen');
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->toggleSplitScreen');
            $tabObj->textViewObj->scrollToLock();
        }

        return 1;
    }

    sub findPage {

        # Can be called by anything
        # Finds the tab object (GA::Obj::Tab) corresponding to a specified page in the
        #   Gtk2::Notebook, when normal tabs (not simple tabs) are visible
        # If there is a simple tab visible and the specified page is 0, return it
        #
        # Expected arguments
        #   $page       - The tab's current page number in the notebook (0 for the first tab, 1
        #                   for the second, etc)
        #
        # Return values
        #   'undef' on improper arguments or if a matching tab object doesn't exist
        #   Otherwise, returns the tab object

        my ($self, $page, $check) = @_;

        # Check for improper arguments
        if (! defined $page || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->findPage', @_);
        }

        # If there is a simple tab visible and the specified page is 0, return it
        if (! $self->notebook) {

            if ($page == 0) {
                return $self->ivShow('tabObjHash', 0);
            } else {
                return undef;
            }
        }

        # Otherwise, check each tab in turn until we find the right page number
        foreach my $tabObj ($self->ivValues('tabObjHash')) {

            my $num = $self->notebook->page_num($tabObj->tabWidget);
            if ($num == $page) {

                return $tabObj;
            }
        }

        # Corresponding tab object not found
        return undef;
    }

    sub findSession {

        # Can be called by anything
        # Finds the tab object (GA::Obj::Tab) for the tab/simple tab which contains the specified
        #   session's default textview object (GA::Obj::TextView)
        #
        # Expected arguments
        #   $session    - The GA::Session whose tab we want to find
        #
        # Return values
        #   'undef' on improper arguments or if a matching tab object doesn't exist
        #   Otherwise, returns the tab object

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->findSession', @_);
        }

        # No session should have more than one tab. Nevertheless, search tabs in ascending order and
        #   return the first one matching the specified session
        foreach my $tabObj (sort {$a->number <=> $b->number} ($self->ivValues('tabObjHash'))) {

            if ($tabObj->defaultFlag && $tabObj->session && $tabObj->session eq $session) {

                return $tabObj;
            }
        }

        # No tab matching the specified session found
        return undef;
    }

    sub findTextView {

        # Can be called by anything
        # Finds the tab object (GA::Obj::Tab) for the tab/simple tab which uses the specified
        #   textview object
        #
        # Expected arguments
        #   $textViewObj    - The GA::Obj::Textview whose tab we want to find
        #
        # Return values
        #   'undef' on improper arguments or if no tab uses the specified textview object
        #   Otherwise, returns the tab object

        my ($self, $textViewObj, $check) = @_;

        # Check for improper arguments
        if (! defined $textViewObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->findTextView', @_);
        }

        # No textview object should be used by more than one tab. Nevertheless, search tabs in
        #   ascending order and return the first one matching the specified textview object
        foreach my $tabObj (sort {$a->number <=> $b->number} ($self->ivValues('tabObjHash'))) {

            if ($tabObj->textViewObj && $tabObj->textViewObj eq $textViewObj) {

                return $tabObj;
            }
        }

        # No tab matching using the specified textview object found
        return undef;
    }

    sub getVisibleTab {

        # Can be called by anything
        # Finds the visible tab and returns its corresponding GA::Obj::Tab object
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is no visible tab
        #   Otherwise returns the visible tab's tab object

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getVisibleTab', @_);
        }

        if (! $self->notebook) {

            return $self->ivShow('tabObjHash', 0);

        } else {

            return $self->findPage($self->notebook->get_current_page());
        }
    }

    sub setVisibleTab {

        # Can be called by anything
        # Sets the visible tab (unless the tab is already the visible one, in which case nothing
        #   happens)
        #
        # Expected arguments
        #   $tabObj         - The new visible tab's GA::Obj::Tab
        #
        # Return values
        #   'undef' on improper arguments or if the tab object doesn't exist
        #   Otherwise returns $tabObj to show the new visible tab

        my ($self, $tabObj, $check) = @_;

        # Check for improper arguments
        if (! defined $tabObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setVisibleTab', @_);
        }

        # Check the tab still exists
        if (! $self->ivShow('tabObjHash', $tabObj->number)) {

            return undef;
        }

        # If a simple tab exists, it is the only tab that exists, so it's already the visible one
        if ($self->notebook) {

            $self->notebook->set_current_page($self->notebook->page_num($tabObj->tabWidget));
        }

        return $tabObj;
    }

    sub switchVisibleTab {

        # Called by GA::Win::Internal->setKeyPressEvent when the user presses the 'tab' key
        # Switches to the next tab (moving from left to right). If we're already at the right-most
        #   tab, switches to the first tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   Otherwise, returns the tab object for the new tab

        my ($self, $check) = @_;

        # Local variables
        my ($currentPage, $tabCount, $nextPage);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->switchVisibleTab', @_);
        }

        # Deal with simple tabs first, for which the tab can't be switched
        if (! $self->notebook) {

            return $self->ivShow('tabObjHash', 0);
        }

        # Get the current visible tab
        $currentPage = $self->notebook->get_current_page();
        # Get the number of visible tabs
        $tabCount = $self->ivPairs('tabObjHash');

        if ($currentPage >= ($tabCount - 1)) {

            $nextPage = 0;

        } else {

            $nextPage = $currentPage + 1;
        }

        # Set the new visible tab
        $self->notebook->set_current_page($nextPage);

        return $self->findPage($nextPage);
    }

    sub respondVisibleTab {

        # Called by $self->setSwitchPageEvent, ->addSimpleTab and (either directly, or via a call
        #   from the ->signal_connect in $self->setSwitchPageEvent) ->addTab
        #
        # When a tab becomes the visible tab, inform any code that wants to know. A number of
        #   occurences can cause the ->signal_connect in $self->setSwitchPageEvent to be
        #   emitted. When called by ->setSwitchpageEvent, this function only takes action if the
        #   visible tab has actually changed
        # To artificially change the visible tab, call $self->switchVisibleTab or
        #   ->setVisibleTab
        #
        # Expected arguments
        #   $tabObj         - The new visible tab's GA::Obj::Tab
        #
        # Optional arguments
        #   $sessionFlag    - Set to TRUE when called by ->addSimpleTab/->addTab, which in turn
        #                       were called by GA::Session->setDefaultTab; FALSE (or 'undef')
        #                       otherwise
        #
        # Return values
        #   'undef' on improper arguments or if the tab hasn't finished setting up yet
        #   1 otherwise

        my ($self, $tabObj, $sessionFlag, $check) = @_;

        # Local variables
        my ($changeFlag, $winObj, $funcRef);

        # Check for improper arguments
        if (! defined $tabObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->respondVisibleTab', @_);
        }

        # Import the parent window (for convenience)
        $winObj = $self->winObj;

        # Update IVs
        if (! $self->currentTabObj || $self->currentTabObj ne $tabObj) {

            $self->ivPoke('currentTabObj', $tabObj);
            $changeFlag = TRUE;
        }

        # If this is a session's default tab, inform the parent window so it can update its visible
        #   visible session
        if (
            $sessionFlag
            || (
                $tabObj->session->defaultTabObj
                && $tabObj->session->defaultTabObj eq $tabObj
                && (
                    ! $winObj->visibleSession
                    || $winObj->visibleSession ne $tabObj->session
                )
            )
        ) {
            $winObj->setVisibleSession($tabObj->session);
        }

        # Inform any code that wants to be informed when the tab changes
        if (! $sessionFlag && $changeFlag && $self->switchFuncRef) {

            $funcRef = $self->switchFuncRef;
            &$funcRef($self, $tabObj, $self->switchFuncID);
        }

        return 1;
    }

    sub setTabLabel {

        # Called by GA::Session->spinTaskLoop and ->checkTabLabels to change a default tab's title
        #   to something like '*Deathmud (Gandalf)' to show that there are files that need to be
        #   saved, or to something like 'Deathmud (Gandalf)', to show there are no longer files that
        #   need to be saved
        #
        # Expected arguments
        #   $session    - The calling GA::Session which uses a default tab (or default simple tab)
        #   $string     - The string to use (resembles one of the strings described above). Empty
        #                   strings are acceptable, if some code wants to do that
        #
        # Optional arguments
        #   $flag       - If set to TRUE, show an asterisk. If set to FALSE (or 'undef'), don't show
        #                   an asterisk
        #
        # Return values
        #   'undef' on improper arguments or if the session's default tab doesn't exist
        #   1 otherwise

        my ($self, $session, $string, $flag, $check) = @_;

        # Local variables
        my $tabObj;

        # Check for improper arguments
        if (! defined $session || ! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setTabLabel', @_);
        }

        # Find the session's tab
        $tabObj = $self->findSession($session);
        if (! $tabObj) {

            return undef;
        }

        # Set the tab label, but don't modify a simple tab (which has no tab label)
        if ($self->notebook && $tabObj->tabLabel) {

            if ($flag) {

                $tabObj->tabLabel->set_markup('*' . $string);

            } else {

                $tabObj->tabLabel->set_markup($string);
            }
        }

        return 1;
    }

    sub getTabSize {

        # Called by GA::Obj::TextView->setupVPaned or by any other code
        # Returns the size of the area occupied by a tab in this pane object
        # If there is only a simple tab, it's the same size as the pane. If the pane object is
        #   using a Gtk2::Notebook, it's the size of the notebook page
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments or if there are no tabs open
        #   Otherwise, returns a list in the form ($width, $height)

        my ($self, $check) = @_;

        # Local variables
        my (
            $tabObj,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getTabSize', @_);
            return @emptyList;
        }

        # All tabs in this pane object have the same size, so use the first one
        $tabObj = $self->ivShow('tabObjHash', 0);
        if (! $tabObj) {

            # No tabs visible
            return @emptyList;

        } else {

            return (
                $tabObj->packableObj->allocation->width,
                $tabObj->packableObj->allocation->height,
            );
        }
    }

    ##################
    # Accessors - set

    sub set_borderWidth {

        # Called by $axmud::CLIENT->paneModifyBorder or ->paneRestoreBorder

        my ($self, $flag, $check) = @_;

        if (! $flag && $self->packingBox2->get_border_width() ne $self->normalBorderWidth) {

            # Restore border width
            $self->packingBox2->set_border_width($self->normalBorderWidth);

        } elsif ($flag && $self->packingBox2->get_border_width() ne $self->selectBorderWidth) {

            # Modify border width
            $self->packingBox2->set_border_width($self->selectBorderWidth);
        }

        return 1;
    }

    ##################
    # Accessors - get

    sub notebook
        { $_[0]->{notebook} }
    sub entry
        { $_[0]->{entry} }

    sub normalBorderWidth
        { $_[0]->{normalBorderWidth} }
    sub selectBorderWidth
        { $_[0]->{selectBorderWidth} }

    sub tabObjHash
        { my $self = shift; return %{$self->{tabObjHash}}; }
    sub tabObjCount
        { $_[0]->{tabObjCount} }
    sub currentTabObj
        { $_[0]->{currentTabObj} }
    sub tabConvertFlag
        { $_[0]->{tabConvertFlag} }

    sub switchFuncRef
        { $_[0]->{switchFuncRef} }
    sub switchFuncID
        { $_[0]->{switchFuncID} }
}

# 'Grid' window substitutes

{ package Games::Axmud::Table::PseudoWin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Creates the GA::Table::PseudoWin, which creates a container widget and a pseudo-window
        #   containing all the widgets normally drawn inside a separate 'grid' window object
        # NB Not all 'grid' windows can be used as a pseudo-window. 'main' and 'external' windows
        #   can never be used
        # Other types of window can be used, but the code handling them might need to be modified;
        #   for example, tasks tend to call functions in GA::Generic::Task rather than functions
        #   inherited from GA::Generic::Win
        # In general, the main problem is using the window object's ->winWidget and ->winBox IVs. In
        #   most windows, these IVs are set to the same value (the Gtk2::Window), but in
        #   pseudo-windows, ->winWidget is set to the parent window's Gtk2::Window, and ->winBox is
        #   set to this table object's ->packingBox, a Gtk2::VBox
        # When you wants to do something to the Gtk2::Window in its capacity as a window (such as
        #   minimise it or make it active), the code should use ->winWidget. When you want to do
        #   something to the Gtk2::Window in its capacity as a container (such as add or remove
        #   widgets), the code should use ->winBox
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary table
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary table objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'frame_title' - If specified, the table object is drawn inside a frame
        #                       with the specified title. If 'undef', an empty string or not
        #                       specified, the table object does not use a frame and title
        #                   'win_type' - The 'grid' window type, can be 'map', 'protocol', 'fixed'
        #                       or 'custom' (but not 'main' or 'external'). If 'undef' or not
        #                       specified, 'custom' is used. If an invalid value is specified, the
        #                       table object is not created
        #                   'win_name' - The window name. For 'protocol' windows, any string chosen
        #                       by the protocol code. If not specified, 'undef' or an mpty string,
        #                       'win_type' and 'win_name' have the same value
        #                   'package' - The perl package name for the window object. Only needs to
        #                       be specified for 'fixed' windows (e.g. GA::FixedWin::Something);
        #                       however, if a package is specified for any window object type, it is
        #                       used ('grid' windows only). For 'fixed' windows, if 'undef' or not
        #                       specified, the table object is not created
        #                   'owner' - The owner of the window object ('undef' or not specified if no
        #                       owner). Typically it's a GA::Session or a task (inheriting from
        #                       GA::Generic::Task); could also be GA::Client. It should not be
        #                       another window object (inheriting from GA::Generic::Win). The owner
        #                       should have its own ->del_winObj function which is called when the
        #                       window object's ->winDestroy is called
        #                   'session' - The owner's session. If $owner is a GA::Session, that
        #                       session. If it's something else (like a task), the task's session.
        #                       If $owner is 'undef' or not specified, so is 'session'
        #                   'winmap' - The name of the winmap to use in the pseudo-window. If
        #                       'undef', not specified or not a recognised winmap, a default winmap
        #                       is used
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my (
            $winObj,
            %modHash,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Deal with temporary table objects
        if ($stripObj eq 'temp') {
            $winObj = 'temp';
        } else {
            $winObj = $stripObj->winObj;
        }

        # Default initialisation settings
        %modHash = (
            'frame_title'               => undef,
            'win_type'                  => 'custom',
            'win_name'                  => 'custom',
            'package'                   => undef,
            'owner'                     => undef,
            'session'                   => undef,
            'winmap'                    => undef,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                $modHash{$key} = $initHash{$key};
            }
        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'internal',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be removed from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object; both IVs are always set to the same
            #   widget
            packingBox                  => undef,       # Gtk2::VBox
            packingBox2                 => undef,       # Gtk2::VBox

            # Other IVs
            # ---------

            # The pseudo-window's window object, an ordinary 'grid' window object whose ->number is
            #   -1 to mark it as a pseudo-window, created via a direct call to its ->new function
            #   rather than calling GA::Obj::Workspace->createGridWin as we normally would
            # Its ->winSetup and ->winEnable functions are never called; instead, the code in this
            #   table object sets up the window's widgets
            pseudoWinObj                => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Sets up the table object's widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the table object can't be created
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($winType, $winName, $package, $owner, $session, $winmap);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $winType = $self->ivShow('initHash', 'win_type');
        $winName = $self->ivShow('initHash', 'win_name');
        $package = $self->ivShow('initHash', 'package');
        $owner = $self->ivShow('initHash', 'owner');
        $session = $self->ivShow('initHash', 'session');
        $winmap = $self->ivShow('initHash', 'winmap');

        if (
            ! $winType
            || (
                $winType ne 'map' && $winType ne 'protocol' && $winType ne 'fixed'
                && $winType ne 'custom'
            ) || ($winType eq 'fixed' && ! $package)
        ) {
            return undef;
        }

        if (! $winName) {

            $winName = $winType;
        }

        # Create the packing box
        my ($packingBox, $packingBox2) = $self->setupPackingBoxes(Gtk2::VBox->new(FALSE, 0));

        # Set the package name (for 'fixed' windows, $package is definitely set)
        if (! $package) {

            if ($winType eq 'map') {
                $package = 'Games::Axmud::Win::Map';
            } else {
                $package = 'Games::Axmud::Win::Internal';
            }
        }

        # Create a pseudo-window object
        my $winObj = $package->new(
            -1,                 # Pseudo-window objects have the ->number -1
            $winType,
            $winName,
            $self->winObj->workspaceObj,
            $owner,             # May be 'undef'
            $session,           # May be 'undef'
            undef,              # No workspace grid
            undef,              # No area object
            $winmap,            # May be 'undef'
        );

        if (! $winObj) {

            return undef;
        }

        # Update IVs for the window object
        $winObj->ivPoke('pseudoWinTableObj', $self);

        if ($winType eq 'protocol' || $winType eq 'custom') {

            # Code to replace the pseudo-window object's ->winSetup
            $winObj->set_winWidget($self->winObj->winWidget);
            $winObj->set_winBox($packingBox2);
            $winObj->setKeyPressEvent();        # 'key-press-event'
            $winObj->setKeyReleaseEvent();      # 'key-release-event'
            $winObj->drawWidgets();

            # Code to replace the pseudo-window object's ->winEnable
            $winObj->set_enabledFlag(TRUE);
            $winObj->setCheckResizeEvent();     # 'check-resize'
            $winObj->setFocusInEvent();         # 'focus-in-event'
            $winObj->setFocusOutEvent();        # 'focus-out-event'

        } elsif ($winType eq 'map') {

            # Code to replace the pseudo-window object's ->winSetup
            $winObj->set_winWidget($self->winObj->winWidget);
            $winObj->set_winBox($packingBox2);
            $winObj->setFocusOutEvent();        # 'focus-out-event'
            $winObj->drawWidgets();

            # Code to replace the pseudo-window object's ->winEnable
            $winObj->set_enabledFlag(TRUE);
            if ($session) {

                $session->set_mapWin($winObj);
                $session->mapObj->set_trackAloneFlag(FALSE);
            }

        } elsif ($winType eq 'fixed') {

            # Code to replace the pseudo-window object's ->winSetup
            $winObj->set_winWidget($self->winObj->winWidget);
            $winObj->set_winBox($packingBox2);
            $winObj->drawWidgets();

            # Code to replace the pseudo-window object's ->winEnable
            $winObj->set_enabledFlag(TRUE);
        }

        # Update IVs for this table object
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('packingBox2', $packingBox2);
        $self->ivPoke('pseudoWinObj', $winObj);

        return 1;
    }

#   sub objDestroy {                # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    # (Get equivalents)

    ##################
    # Accessors - get

    sub pseudoWinObj
        { $_[0]->{pseudoWinObj} }
}

# Custom table objects

{ package Games::Axmud::Table::Custom;

    # Any user-written table objects should inherit from this object

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Table Games::Axmud);

    ##################
    # Constructors

#   sub new {}                      # Inherited from GA::Generic::Table

    ##################
    # Methods

    # Standard table object functions

#   sub objEnable {}                # Inherited from GA::Generic::Table

#   sub objDestroy {}               # Inherited from GA::Generic::Table

#   sub setWidgetsIfSession {}      # Inherited from GA::Generic::Table

#   sub setWidgetsChangeSession {}  # Inherited from GA::Generic::Table

#   sub setWidgetsOnResize {}       # Inherited from GA::Generic::Table

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

# Package must return true
1
