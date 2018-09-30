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
# Games::Axmud::Obj::Plugin
# Handles Axmud plugins

{ package Games::Axmud::Obj::Plugin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->loadPlugin
        # Prepare a new instance of the Axmud plugin object which handles an Axmud plugin file that
        #   has been loaded
        #
        # Expected arguments
        #   $name           - Unique name for this plugin (also the package name used in the file's
        #                       header)
        #   $filePath       - The full path of the plugin file
        #   $version        - The version supplied by the plugin file's header
        #   $descrip        - The description supplied by the plugin file's header
        #   $enabledFlag    - Flag set to TRUE if the plugin starts marked enabled, FALSE if it
        #                       starts marked disabled
        #
        # Optional arguments
        #   $author         - The author string supplied by the plugin file's header ('undef' if
        #                       none supplied)
        #   $copyright      - The copyright string supplied by the plugin file's header ('undef' if
        #                       none supplied)
        #   $require        - The minimum Axmud version required to load the plugin; the initial
        #                       'v' should have been removed, if present ('undef' if none supplied)
        #   $init           - Whether the plugin should be enabled or disabled, when it is loaded;
        #                       value is the string 'enable' or 'disable' (already converted to
        #                       lower-case; 'undef' if none supplied, default is 'enable')
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $name, $filePath, $version, $descrip, $enabledFlag, $author, $copyright,
            $require, $init, $check,
        ) = @_;

        # Local variables
        my $matchFlag;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $name || ! defined $filePath || ! defined $version
            || ! defined $descrip || ! defined $enabledFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid and not already in use by another component
        if ($axmud::CLIENT->ivExists('constReservedHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
               );

        } elsif ($axmud::CLIENT->ivExists('pluginHash', $name)) {

               return $axmud::CLIENT->writeError(
                'Registry naming error: plugin \'' . $name . '\' already loaded',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file
            _parentWorld                => undef,       # No parent world
            _privFlag                   => TRUE,        # All IVs are private

            # Object IVs
            # ----------

            # Unique name for this plugin (also the package name used in the file's header)
            name                        => $name,
            # The version supplied by the plugin file's header
            version                     => $version,
            # The description supplied by the plugin file's header
            descrip                     => $descrip,
            # The author string supplied by the plugin file's header
            author                      => $author,
            # The copyright string supplied by the plugin file's header
            copyright                   => $copyright,
            # The minimum Axmud version required to load the plugin
            require                     => $require,
            # Whether the plugin should be enabled or disabled, when it is loaded; value is the
            #   string 'enable' or 'disable'
            init                        => $init,

            # The full path of the plugin file
            filePath                    => $filePath,
            # Flag set to TRUE if the plugin is marked enabled, FALSE if it is marked disabled
            enabledFlag                 => $enabledFlag,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    sub set_enabledFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_enabledFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('enabledFlag', TRUE);
        } else {
            $self->ivPoke('enabledFlag', FALSE);
        }

        return 1;
    }

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub version
        { $_[0]->{version} }
    sub descrip
        { $_[0]->{descrip} }
    sub author
        { $_[0]->{author} }
    sub copyright
        { $_[0]->{copyright} }
    sub require
        { $_[0]->{require} }
    sub init
        { $_[0]->{init} }

    sub filePath
        { $_[0]->{filePath} }
    sub enabledFlag
        { $_[0]->{enabledFlag} }
}

# Package must return a true value
1
