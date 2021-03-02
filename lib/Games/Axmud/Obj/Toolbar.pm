# Copyright (C) 2011-2021 A S Lewis
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
# Games::Axmud::Obj::Toolbar
# Handles a 'main' window's toolbar button object

{ package Games::Axmud::Obj::Toolbar;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->initialiseToolbar or GA::PrefWin::Client->windows4Tab
        # Creates a new instance of the toolbar button object
        #
        # Expected arguments
        #   $name       - A unique string name for this toolbar button object (max 16 chars,
        #                   containing A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets
        #                   acceptable. Must not exist as a key in the global hash of reserved
        #                   names, $axmud::CLIENT->constReservedHash)
        #   $descrip    - A short description, e.g. 'Do something' (max 32 chars)
        #   $customFlag - Flag set to TRUE if this is a custom toolbar button (can be modified by
        #                   the user), set to FALSE if this is one of the default toolbar buttons
        #                   listed in GA::Client->constToolbarList (which can't be modified by the
        #                   user)
        #   $iconPath   - File path for the icon to use. If $customFlag is TRUE, an absolute path;
        #                   otherwise, the name of a file in /icons/main
        #   $instruct   - The instruction to execute, when the toolbar button is clicked
        #   $requireSessionFlag
        #               - Flag set to TRUE if the icon should only be sensitised when there's a
        #                   current session (set to FALSE otherwise)
        #   $requireConnectFlag
        #               - Flag set to TRUE if the icon should only be sensitised when connected to a
        #                   world (set to FALSE otherwise)
        #
        # Return values
        #   'undef' on improper arguments or if $number or $time are invalid
        #   Blessed reference to the newly-created object on success

        my (
            $class, $name, $descrip, $customFlag, $iconPath, $instruct, $requireSessionFlag,
            $requireConnectFlag, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $name || ! defined $descrip || ! defined $customFlag
            || ! defined $iconPath || ! defined $instruct || ! defined $requireSessionFlag
            || ! defined $requireConnectFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'toolbar',
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => FALSE,       # All IVs are public

            # IVs
            # ---

            # Unique name for the toolbar object (max 16 characters)
            name                        => $name,
            # A short description, e.g. 'Do something' (max 32 characters)
            descrip                     => $descrip,
            # Flag set to TRUE if this is a custom toolbar button (can be modified by the user), set
            #   to FALSE if this is one of the default toolbar buttons listed in
            #   GA::Client->constToolbarList (which can't be modified by the user)
            customFlag                  => $customFlag,
            # File path for the icon to use. If $customFlag is TRUE, an absolute path; otherwise,
            #   the name of a file in /icons/main
            iconPath                    => $iconPath,
            # The instruction to execute, when the toolbar button is clicked
            instruct                    => $instruct,
            # Flag set to TRUE if the icon should only be sensitised when there's a current session
            #   (set to FALSE otherwise)
            requireSessionFlag          => $requireSessionFlag,
            # Flag set to TRUE if the icon should only be sensitised when connected to a world (set
            #   to FALSE otherwise)
            requireConnectFlag          => $requireConnectFlag,
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
    sub descrip
        { $_[0]->{descrip} }
    sub customFlag
        { $_[0]->{customFlag} }
    sub iconPath
        { $_[0]->{iconPath} }
    sub instruct
        { $_[0]->{instruct} }
    sub requireSessionFlag
        { $_[0]->{requireSessionFlag} }
    sub requireConnectFlag
        { $_[0]->{requireConnectFlag} }
}

# Package must return a true value
1
