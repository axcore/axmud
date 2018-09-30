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
# Games::Axmud::Obj::BasicWorld
# Stores the basic mudlist (containing many more worlds than Axmud's list of pre-configured worlds)

{ package Games::Axmud::Obj::BasicWorld;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->loadBasicWorlds
        # Creates a new instance of the basic world object
        #
        # Expected arguments
        #   $name       - World's short name, matching GA::Profile::World->name (max 16 chars,
        #                   containing A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets
        #                   acceptable. Must not exist as a key in the global hash of reserved
        #                   names, $axmud::CLIENT->constReservedHash)
        #   $longName   - World's long name, matching GA::Profile::World->longName (suggested max
        #                   length of 32 chars)
        #   $host       - DNS or IP address
        #   $port       - Port
        #   $adultFlag  - Flag set to TRUE for worlds with primarily adult (sexual) content, FALSE
        #                   otherwise
        #   $language   - String representing the dictionary language (matching
        #                   GA::Obj::Dict->language, e.g. 'English', 'Francais', 'Deutsch')
        #
        # Return values
        #   'undef' on improper arguments or if any arguments are invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $name, $longName, $host, $port, $adultFlag, $language, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $name || ! defined $longName || ! defined $host
            || ! defined $port || ! defined $adultFlag || ! defined $language || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $shortName is valid
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );
        }

        # Flag must be TRUE or FALSE
        if (! $adultFlag) {
            $adultFlag = FALSE;
        } else {
            $adultFlag = TRUE;
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

            # World's short name, matching GA::Profile::World->name (max 16 chars, containing
            #   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable. Must not
            #   exist as a key in the global hash of reserved names,
            #   $axmud::CLIENT->constReservedHash)
            name                        => $name,
            # World's long name, matching GA::Profile::World->longName (suggested max length of 32
            #   chars)
            longName                    => $longName,
            # DNS or IP address
            host                        => $host,
            # Port
            port                        => $port,
            # Flag set to TRUE for worlds with primarily adult (sexual) content, FALSE otherwise
            adultFlag                   => $adultFlag,
            # String representing the dictionary language (matching GA::Obj::Dict->language, e.g.
            #   'English', 'Francais', 'Deutsch'
            language                    => $language,
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
    sub longName
        { $_[0]->{longName} }
    sub host
        { $_[0]->{host} }
    sub port
        { $_[0]->{port} }
    sub adultFlag
        { $_[0]->{adultFlag} }
    sub language
        { $_[0]->{language} }
}

# Package must return a true value
1
