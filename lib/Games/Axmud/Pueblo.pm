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
# Games::Axmud::Pueblo::xxx
# Objects for use during Pueblo-enabled sessions

{ package Games::Axmud::Pueblo::List;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->processPuebloListElement
        # Creates a new instance of the Pueblo list object (which stores details for the current
        #   ordered or unordered list)
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $listType   - The type of list: 'ul' for an ordered list, 'ol' for an unordered list
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $listType, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $listType || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $listType,
            _objClass                   => $class,
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The type of list: 'ul' for an ordered list, 'ol' for an unordered list
            listType                    => $listType,

            # For unordered lists, the bullet type: 'disc', 'circle' or 'square' ('disc' and
            #   'circle' are the same'). 'undef' for ordered lists
            bulletType                  => 'disc',
            # For ordered lists, the item type, specifying how list items should be marked: 'A' for
            #   capital letters (A, B, C...), 'a' for small letters (a, b, c...), 'I' for large
            #   Roman numerals (I, II, III), 'i' for small Roman numerals (i, ii, iii), '1' for
            #   default numbers
            itemType                    => 1,
            # The number in the list of the next list item to add to it. The first list item added
            #   is 1, unless a different starting number is specified by the <OL> tag
            # (Only used in ordered lists)
            itemCount                   => 1,
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

    sub listType
        { $_[0]->{listType} }

    sub bulletType
        { $_[0]->{bulletType} }
    sub itemType
        { $_[0]->{itemType} }
    sub itemCount
        { $_[0]->{itemCount} }
}

# Package must return true
1
