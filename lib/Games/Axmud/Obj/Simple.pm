# Copyright 2004 by the Gtk3-Perl team
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU
# Lesser Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser Public License for more details.
#
# You should have received a copy of the GNU Lesser Public License along with this program. If not,
# see <http://www.gnu.org/licenses/>.
#
#
# Games::Axmud::Obj::SimpleList, a modification of Gtk3::SimpleList (v0.18) by Thierry Vignaud
#
# Packaged along with Axmud, and renamed, so that MS Windows users can use it, and so that CPAN
#   doesn't complain about unauthorised packages
# List of changes (besides cosmetic ones):
#   - Added 'use warnings' as the lack of it causes Kwalitee errors
#   - Commented out $VERSION as it causes Kwalitee errors
#   - Added a hack to ->new_from_treeview to prevent Gtk auto-selecting the first row in the simple
#       list (sometimes, but not all the time)
#   - Modified ->new_from_treeview to set the arguments in Gtk3::ListStore->new() to a list
#       reference, rather than a straight list (as required by Gtk3, and without which we get Perl
#       errors)
#   - Modified ->text_cell_edited, ->new_from_treeview and GA::Obj::SimpleList::TiedRow->STORE to
#       transform the arguments in ->set($iter, $cols, $val) to ->set($iter, [$cols], [$val]), as
#       required by Gtk3, and without which we get Perl errors
#   - Commented out Data::Dumper usage in ->get_selected_indices because it creates useless Perl
#       warnings

package Games::Axmud::Obj::SimpleList;

use strict;
use warnings;
use Carp;
use Gtk3;

our @ISA = 'Gtk3::TreeView';

#our $VERSION = '0.18';

our %column_types = (
  'hidden' => {type=>'Glib::String',                                        attr=>'hidden'},
  'text'   => {type=>'Glib::String',  renderer=>'Gtk3::CellRendererText',   attr=>'text'},
  'markup' => {type=>'Glib::String',  renderer=>'Gtk3::CellRendererText',   attr=>'markup'},
  'int'    => {type=>'Glib::Int',     renderer=>'Gtk3::CellRendererText',   attr=>'text'},
  'double' => {type=>'Glib::Double',  renderer=>'Gtk3::CellRendererText',   attr=>'text'},
  'bool'   => {type=>'Glib::Boolean', renderer=>'Gtk3::CellRendererToggle', attr=>'active'},
  'scalar' => {type=>'Glib::Scalar',  renderer=>'Gtk3::CellRendererText',
      attr=> sub {
        my ($tree_column, $cell, $model, $iter, $i) = @_;
        my ($info) = $model->get ($iter, $i);
        $cell->set (text => $info || '' );
      } },
  'pixbuf' => {type=>'Gtk3::Gdk::Pixbuf', renderer=>'Gtk3::CellRendererPixbuf', attr=>'pixbuf'},
);

# this is some cool shit
sub add_column_type
{
    shift;  # don't want/need classname
    my $name = shift;
    $column_types{$name} = { @_ };
}

sub text_cell_edited {
    my ($cell_renderer, $text_path, $new_text, $slist) = @_;
    my $path = Gtk3::TreePath->new_from_string ($text_path);
    my $model = $slist->get_model;
    my $iter = $model->get_iter ($path);
#   $model->set ($iter, $cell_renderer->{column}, $new_text);
    $model->set ($iter, [$cell_renderer->{column}], [$new_text]);
}

sub new {
    croak "Usage: $_[0]\->new (title => type, ...)\n"
        . " expecting a list of column title and type name pairs.\n"
        . " can't create a SimpleList with no columns"
        unless @_ >= 3; # class, key1, val1
    return shift->new_from_treeview (Gtk3::TreeView->new (), @_);
}

sub new_from_treeview {
    my $class = shift;
    my $view = shift;
    croak "treeview is not a Gtk3::TreeView"
        unless defined ($view)
           and UNIVERSAL::isa ($view, 'Gtk3::TreeView');
    croak "Usage: $class\->new_from_treeview (treeview, title => type, ...)\n"
        . " expecting a treeview reference and list of column title and type name pairs.\n"
        . " can't create a SimpleList with no columns"
        unless @_ >= 2; # key1, val1
    my @column_info = ();
    for (my $i = 0; $i < @_ ; $i+=2) {
        my $typekey = $_[$i+1];
        croak "expecting pairs of title=>type"
            unless $typekey;
        croak "unknown column type $typekey, use one of "
            . join(", ", keys %column_types)
            unless exists $column_types{$typekey};
        my $type = $column_types{$typekey}{type};
        if (not defined $type) {
            $type = 'Glib::String';
            carp "column type $typekey has no type field; did you"
               . " create a custom column type incorrectly?\n"
               . "limping along with $type";
        }
        push @column_info, {
            title => $_[$i],
            type => $type,
            rtype => $column_types{$_[$i+1]}{renderer},
            attr => $column_types{$_[$i+1]}{attr},
        };
    }
#   my $model = Gtk3::ListStore->new (map { $_->{type} } @column_info);
    my $model = Gtk3::ListStore->new ([map { $_->{type} } @column_info]);
    # just in case, 'cause i'm paranoid like that.
    map { $view->remove_column ($_) } $view->get_columns;
    $view->set_model ($model);
    for (my $i = 0; $i < @column_info ; $i++) {
        if( 'CODE' eq ref $column_info[$i]{attr} )
        {
            $view->insert_column_with_data_func (-1,
                $column_info[$i]{title},
                $column_info[$i]{rtype}->new,
                $column_info[$i]{attr}, $i);
        }
        elsif ('hidden' eq $column_info[$i]{attr})
        {
            # skip hidden column
        }
        else
        {
            my $column = Gtk3::TreeViewColumn->new_with_attributes (
                $column_info[$i]{title},
                $column_info[$i]{rtype}->new,
                $column_info[$i]{attr} => $i,
            );
            $view->append_column ($column);

            if ($column_info[$i]{attr} eq 'active') {
                # make boolean columns respond to editing.
                my $r = $column->get_cells;
                $r->set (activatable => 1);
                $r->{column_index} = $i;
                $r->signal_connect (toggled => sub {
                    my ($renderer, $row, $slist) = @_;
                    my $col = $renderer->{column_index};
                    my $model = $slist->get_model;
                    my $iter = $model->iter_nth_child (undef, $row);
                    my $val = $model->get ($iter, $col);
#                   $model->set ($iter, $col, !$val);
                    $model->set ($iter, [$col], [!$val]);
                    }, $view);

            } elsif ($column_info[$i]{attr} eq 'text') {
                # attach a decent 'edited' callback to any
                # columns using a text renderer.  we do NOT
                # turn on editing by default.
                my $r = $column->get_cells;
                $r->{column} = $i;
                $r->signal_connect
                    (edited => \&text_cell_edited, $view);
            }
        }
    }

    my @a;
    tie @a, 'Games::Axmud::Obj::SimpleList::TiedList', $model;

    $view->{data} = \@a;
#   return bless $view, $class;
    bless $view, $class;

    # In Axmud simple lists, the first item is sometimes automatically selected, and sometimes not.
    #   This is not what happened in Gtk2, so the Axmud code doesn't expect it
    # This down-and-dirty hack solves the problem by clearing a row that's auto-selected, while
    #   still allowing the user to select a row by clicking on it
    my $flag;
    $view->add_events(['pointer-motion-mask']);
    $view->signal_connect ('motion-notify-event' => sub { $flag = 1; });
    $view->signal_connect('cursor-changed' => sub {

        if (! $flag) {

            $view->get_selection->unselect_all();
            $flag = 1;
        }
    });

    return $view;
}

sub set_column_editable {
    my ($self, $index, $editable) = @_;
    my $column = $self->get_column ($index);
    croak "invalid column index $index"
        unless defined $column;
    my $cell_renderer = $column->get_cells;
    $cell_renderer->set (editable => $editable);
}

sub get_column_editable {
    my ($self, $index, $editable) = @_;
    my $column = $self->get_column ($index);
    croak "invalid column index $index"
        unless defined $column;
    my $cell_renderer = $column->get_cells;
    return $cell_renderer->get ('editable');
}

sub get_selected_indices {
    my $self = shift;
    my $selection = $self->get_selection;
    return () unless $selection;
    # warning: this assumes that the TreeModel is actually a ListStore.
    # if the model is a TreeStore, get_indices will return more than one
    # index, which tells you how to get all the way down into the tree,
    # but all the indices will be squashed into one array... so, ah,
    # don't use this for TreeStores!
    my ($indices) = $selection->get_selected_rows;
#   use Data::Dumper; warn Dumper $indices;
    map { $_->get_indices } @$indices;
}

sub select {
    my $self = shift;
    my $selection = $self->get_selection;
    my @inds = (@_ > 1 && $selection->get_mode ne 'multiple')
             ? $_[0]
         : @_;
    my $model = $self->get_model;
    foreach my $i (@inds) {
        my $iter = $model->iter_nth_child (undef, $i);
        next unless $iter;
        $selection->select_iter ($iter);
    }
}

sub unselect {
    my $self = shift;
    my $selection = $self->get_selection;
    my @inds = (@_ > 1 && $selection->get_mode ne 'multiple')
             ? $_[0]
         : @_;
    my $model = $self->get_model;
    foreach my $i (@inds) {
        my $iter = $model->iter_nth_child (undef, $i);
        next unless $iter;
        $selection->unselect_iter ($iter);
    }
}

sub set_data_array
{
    @{$_[0]->{data}} = @{$_[1]};
}

sub get_row_data_from_path
{
    my ($self, $path) = @_;

    # $path->get_depth always 1 for SimpleList
    # my $depth = $path->get_depth;

    # array has only one member for SimpleList
    my @indices = $path->get_indices;
    my $index = $indices[0];

    return $self->{data}->[$index];
}

##################################
package Games::Axmud::Obj::SimpleList::TiedRow;

use strict;
use Gtk3;
use Carp;

# TiedRow is the lowest-level tie, allowing you to treat a row as an array
# of column data.

sub TIEARRAY {
    my $class = shift;
    my $model = shift;
    my $iter = shift;

    croak "usage tie (\@ary, 'class', model, iter)"
        unless $model && UNIVERSAL::isa ($model, 'Gtk3::TreeModel');

    return bless {
        model => $model,
        iter => $iter,
    }, $class;
}

sub FETCH { # this, index
    return $_[0]->{model}->get ($_[0]->{iter}, $_[1]);
}

sub STORE { # this, index, value
#   return $_[0]->{model}->set ($_[0]->{iter}, $_[1], $_[2])
    return $_[0]->{model}->set ($_[0]->{iter}, [$_[1]], [$_[2]])
        if defined $_[2]; # allow 0, but not undef
}

sub FETCHSIZE { # this
    return $_[0]{model}->get_n_columns;
}

sub EXISTS {
    return( $_[1] < $_[0]{model}->get_n_columns );
}

sub EXTEND { } # can't change the length, ignore
sub CLEAR { } # can't change the length, ignore

sub new {
    my ($class, $model, $iter) = @_;
    my @a;
    tie @a, __PACKAGE__, $model, $iter;
    return \@a;
}

sub POP { croak "pop called on a TiedRow, but you can't change its size"; }
sub PUSH { croak "push called on a TiedRow, but you can't change its size"; }
sub SHIFT { croak "shift called on a TiedRow, but you can't change its size"; }
sub UNSHIFT { croak "unshift called on a TiedRow, but you can't change its size"; }
sub SPLICE { croak "splice called on a TiedRow, but you can't change its size"; }
#sub DELETE { croak "delete called on a TiedRow, but you can't change its size"; }
sub STORESIZE { carp "STORESIZE operation not supported"; }


###################################
package Games::Axmud::Obj::SimpleList::TiedList;

use strict;
use Gtk3;
use Carp;

# TiedList is an array in which each element is a row in the liststore.

sub TIEARRAY {
    my $class = shift;
    my $model = shift;

    croak "usage tie (\@ary, 'class', model)"
        unless $model && UNIVERSAL::isa ($model, 'Gtk3::TreeModel');

    return bless {
        model => $model,
    }, $class;
}

sub FETCH { # this, index
    my $iter = $_[0]->{model}->iter_nth_child (undef, $_[1]);
    return undef unless defined $iter;
    my @row;
    tie @row, 'Games::Axmud::Obj::SimpleList::TiedRow', $_[0]->{model}, $iter;
    return \@row;
}

sub STORE { # this, index, value
    my $iter = $_[0]->{model}->iter_nth_child (undef, $_[1]);
    $iter = $_[0]->{model}->insert ($_[1])
        if not defined $iter;
    my @row;
    tie @row, 'Games::Axmud::Obj::SimpleList::TiedRow', $_[0]->{model}, $iter;
    if ('ARRAY' eq ref $_[2]) {
        @row = @{$_[2]};
    } else {
        $row[0] = $_[2];
    }

    return $_[2];
}

sub FETCHSIZE { # this
    return $_[0]->{model}->iter_n_children (undef);
}

sub PUSH { # this, list
    my $model = shift()->{model};
    my $iter;
    foreach (@_)
    {
        $iter = $model->append;
        my @row;
        tie @row, 'Games::Axmud::Obj::SimpleList::TiedRow', $model, $iter;
        if ('ARRAY' eq ref $_) {
            @row = @$_;
        } else {
            $row[0] = $_;
        }
    }
    return $model->iter_n_children (undef);
}

sub POP { # this
    my $model = $_[0]->{model};
    my $index = $model->iter_n_children-1;
    my $iter = $model->iter_nth_child(undef, $index);
    return undef unless $iter;
    my $ret = [ $model->get ($iter) ];
    $model->remove($iter) if( $index >= 0 );
    return $ret;
}

sub SHIFT { # this
    my $model = $_[0]->{model};
    my $iter = $model->iter_nth_child(undef, 0);
    return undef unless $iter;
    my $ret = [ $model->get ($iter) ];
    $model->remove($iter) if( $model->iter_n_children );
    return $ret;
}

sub UNSHIFT { # this, list
    my $model = shift()->{model};
    my $iter;
    foreach (@_)
    {
        $iter = $model->prepend;
        my @row;
        tie @row, 'Games::Axmud::Obj::SimpleList::TiedRow', $model, $iter;
        if ('ARRAY' eq ref $_) {
            @row = @$_;
        } else {
            $row[0] = $_;
        }
    }
    return $model->iter_n_children (undef);
}

# note: really, arrays aren't supposed to support the delete operator this
#       way, but we don't want to break existing code.
sub DELETE { # this, key
    my $model = $_[0]->{model};
    my $ret;
    if ($_[1] < $model->iter_n_children (undef)) {
        my $iter = $model->iter_nth_child (undef, $_[1]);
        return undef unless $iter;
        $ret = [ $model->get ($iter) ];
        $model->remove ($iter);
    }
    return $ret;
}

sub CLEAR { # this
    $_[0]->{model}->clear;
}

# note: arrays aren't supposed to support exists, either.
sub EXISTS { # this, key
    return( $_[1] < $_[0]->{model}->iter_n_children );
}

# we can't really, reasonably, extend the tree store in one go, it will be
# extend as items are added
sub EXTEND {}

sub get_model {
    return $_[0]{model};
}

sub STORESIZE { carp "STORESIZE: operation not supported"; }

sub SPLICE { # this, offset, length, list
    my $self = shift;
    # get the model and the number of rows
    my $model = $self->{model};
    # get the offset
    my $offset = shift || 0;
    # if offset is neg, invert it
    $offset = $model->iter_n_children (undef) + $offset if ($offset < 0);
    # get the number of elements to remove
    my $length = shift;
    # if len was undef, not just false, calculate it
    $length = $self->FETCHSIZE() - $offset unless (defined ($length));
    # get any elements we need to insert into their place
    my @list = @_;

    # place to store any returns
    my @ret = ();

    # remove the desired elements
    my $ret;
    for (my $i = $offset; $i < $offset+$length; $i++)
    {
        # things will be shifting forward, so always delete at offset
        $ret = $self->DELETE ($offset);
        push @ret, $ret if defined $ret;
    }

    # insert the passed list at offset in reverse order, so the will
    # be in the correct order
    foreach (reverse @list)
    {
        # insert a new row
        $model->insert ($offset);
        # and put the data in it
        $self->STORE ($offset, $_);
    }

    # return deleted rows in array context, the last row otherwise
    # if nothing deleted return empty
    return (@ret ? (wantarray ? @ret : $ret[-1]) : ());
}

1;

