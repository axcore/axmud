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
# Games::Axmud::Obj::Protect
# Handles protected objects

{ package Games::Axmud::Obj::Protect;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the protected model object (which enjoys semi-protection against
        #   being sold by Axmud tasks)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'protect_obj',
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,                       # All IVs are public

            # Object IVs (match IVs used by GA::Generic::ModelObj)
            # ----------------------------------------------------

            noun                        => undef,
            categoryList                => [],      # Equivalent of GA::Generic::ModelObj->category
            otherNounList               => [],
            adjList                     => [],
            pseudoAdjList               => [],
            unknownWordList             => [],
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

    sub noun
        { $_[0]->{noun} }
    sub categoryList
        { my $self = shift; return @{$self->{categoryList}}; }
    sub otherNounList
        { my $self = shift; return @{$self->{otherNounList}}; }
    sub adjList
        { my $self = shift; return @{$self->{adjList}}; }
    sub pseudoAdjList
        { my $self = shift; return @{$self->{pseudoAdjList}}; }
    sub unknownWordList
        { my $self = shift; return @{$self->{unknownWordList}}; }
}

# Package must return true
1
