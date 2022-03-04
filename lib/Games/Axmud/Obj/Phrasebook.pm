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
# Games::Axmud::Obj::Phrasebook
# Stores a basic list of words for converting parts of a dictionary object (Games::Axmud::Obj::Dict)
#   into another language

{ package Games::Axmud::Obj::Phrasebook;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->loadPhraseBooks
        # Creates a new instance of the phrasebook object
        #
        # Expected arguments
        #   $name       - Language name, rendered in lower-case English (e.g. 'francais')
        #   $targetName - Language name, rendered in the target language and capitalised
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $name, $targetName, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $name || ! defined $targetName || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # Language name, rendered in lower-case English (e.g. 'french')
            name                        => $name,
            # Language name, rendered in the target language and capitalised
            targetName                  => $targetName,
            # Noun position for this language:
            #   'noun_adj' - typical order is noun-adjective (e.g. French)
            #   'adj_noun' - typical order is adjective-noun (e.g. English)
            nounPosn                    => 'adj_noun',

            # List of primary directions, in a standard order. If directions are not known, retain
            #   the English words
            primaryDirList              => [
                'north',
                'northnortheast',
                'northeast',
                'eastnortheast',
                'east',
                'eastsoutheast',
                'southeast',
                'southsoutheast',
                'south',
                'southsouthwest',
                'southwest',
                'westsouthwest',
                'west',
                'westnorthwest',
                'northwest',
                'northnorthwest',
                'up',
                'down',
            ],
            # List of abbreviated primary directions, in a standard order. If directions are not
            #   known, retain the English words
            primaryAbbrevDirList        => [
                'n',
                'nne',
                'ne',
                'ene',
                'e',
                'ese',
                'se',
                'sse',
                's',
                'ssw',
                'sw',
                'wsw',
                'w',
                'wnw',
                'nw',
                'nnw',
                'u',
                'd',
            ],
            # List of definite articles (can be an empty list)
            definiteList                => [
                'the',
            ],
            # List of indefinite articles (can be an empty list)
            indefiniteList              => [
                'a',
                'an',
            ],
            # List of 'and' words (can be an empty list)
            andList                     => [
                'and',
                'also',
            ],
            # List of 'or' words (can be an empty list)
            orList                      => [
                'or',
            ],
            # Basic list of number words, from 1-10
            numberList                  => [
                'one',
                'two',
                'three',
                'four',
                'five',
                'six',
                'seven',
                'eight',
                'nine',
                'ten',
            ],
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
    sub targetName
        { $_[0]->{targetName} }
    sub nounPosn
        { $_[0]->{nounPosn} }

    sub primaryDirList
        { my $self = shift; return @{$self->{primaryDirList}}; }
    sub primaryAbbrevDirList
        { my $self = shift; return @{$self->{primaryAbbrevDirList}}; }
    sub definiteList
        { my $self = shift; return @{$self->{definiteList}}; }
    sub indefiniteList
        { my $self = shift; return @{$self->{indefiniteList}}; }
    sub andList
        { my $self = shift; return @{$self->{andList}}; }
    sub orList
        { my $self = shift; return @{$self->{orList}}; }
    sub numberList
        { my $self = shift; return @{$self->{numberList}}; }
}

# Package must return a true value
1
