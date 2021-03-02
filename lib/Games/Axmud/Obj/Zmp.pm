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
# Games::Axmud::Obj::ZMP
# Objects used to store ZMP packages

{ package Games::Axmud::Obj::Zmp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Can be called by anything. To create a new ZMP package object, just get your plugin to
        #   call this ->new function; the code handles everything else
        #
        # The package object created is available to every session that's connected to the specified
        #   world. If no world is specified, the package object is available to every world
        # This object is given an object name. If a world is specified, it's in the form
        #       PackageName@WorldName
        #   (...that is to say, two strings, neither containing an @ character, joined together with
        #       an @ character)
        # If no world is specified, the object name is in the form
        #       PackageName@
        #   (...that is to say, the package name with an @ appended to it)
        # NB When connected to a world called 'deathmud', 'mypackage@deathmud' is used instead of
        #   the generic package object, 'mypackage@', if both exist
        #
        # Duplicate object names are not allowed. It another plugin has already created a package
        #   object with the same object name, this object won't be created
        #
        # Expected arguments
        #   $packageName    - The ZMP package name, a string in the form 'Package[.SubPackages]'.
        #                       Must not be the string 'zmp'
        #
        # Optional arguments
        #   $world          - The name of a world profile. If specified, this package object is
        #                       available to all sessions using that world; if 'undef', this package
        #                       object is available to all sessions. This function doesn't check
        #                       that a rofile called $world actually exists
        #   @cmdList        - A list of package commands for this package. A list in groups of two,
        #                        in the form
        #                           (package_command, function_reference...)
        #                   - The 'function_reference' should be a reference to a function in the
        #                       plugin that called this function
        #                   - Duplicate commands are not acceptable, but duplicate function
        #                       references are fine (for example, if you want the same function to
        #                       be called for every command)
        #                   - If the list is empty, the package object is still created, but Axmud
        #                       regards it as being unsupported (and that's what it will tell the
        #                       server, if queried). The ZMP spec says that commands must not be
        #                       changed once a ZMP session has begun, so $self->cmdHash should not
        #                       be altered, once created; instead edit your plugin and then restart
        #                       Axmud (package objects are not saved to any file). You can prevent
        #                       Axmud from supporting the ZMP package 'example' by simply creating
        #                       empty package object called 'example'
        #
        # Return values
        #   'undef' on improper arguments, if $name is invalid, if @argList contains an odd number
        #       of items or if @argList contains a duplicate command
        #   Blessed reference to the newly-created object on success

        my ($class, $packageName, $world, @cmdList) = @_;

        # Local variables
        my (
            $objName,
            @compList,
            %cmdHash,
        );

        # Check for improper arguments
        if (! defined $class || ! defined $packageName) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid
        if (
            $packageName eq 'zmp'
            || ! ($packageName =~ m/^[\w\-]([\w\-\.]*[\w\-])?$/)
        ) {
            return undef;
        }

        # Split $packageName into its components
        @compList = split(m/\./, $packageName);

        # Set the object name
        $objName = $packageName . '@';
        if (defined $world) {

            $objName .= $world;
        }

        # Prepare the hash of commands (if any were specified)
        if (@cmdList) {

            do {

                my ($cmd, $funcRef);

                $cmd = shift @cmdList;
                $funcRef = shift @cmdList;

                if (! defined $funcRef) {

                    # @argList did not contain an even number of values
                    return undef;

                } elsif (exists $cmdHash{$cmd}) {

                    # @argList contains a duplicate command
                    return undef;

                } else {

                    $cmdHash{$cmd} = $funcRef;
                }

            } until (! @cmdList);
        }

        # Setup
        my $self = {
            _objName                    => $objName,
            _objClass                   => $class,
            _parentFile                 => undef,        # Object not saved even if $world specified
            _parentWorld                => undef,
            _privFlag                   => TRUE,         # All IVs are private

            # IVs
            # ---

            # The name of this object, in the form 'PackageName@WorldName' or 'PackageName@'
            name                        => $objName,
            # The ZMP package name, a string in the form 'Package[.SubPackages]'. Must not be the
            #   string 'zmp'
            packageName                 => $packageName,
            # $name, split into a list of its components
            compList                    => \@compList,

            # The name of a world profile. If specified, this package object is available to all
            #   sessions using that world; if 'undef', this package object is available to all
            #   sessions. This function doesn't check that a profile called $world actually exists
            world                       => $world,

            # A hash of commands recognised by this package. A hash in the form
            #   $cmdHash{command} = function_reference
            # where 'function_reference' is a reference to a function in the plugin that called this
            #   ->new function)
            # If the hash is empty, Axmud regards the package as unsupported. You can prevent Axmud
            #   from supporting the ZMP package 'example' by simply creating an empty package object
            #   called 'example'
            cmdHash                     => \%cmdHash,
        };

        # Bless the object into existence
        bless $self, $class;

        # Add it to the GA::Client hash. If a package object named $objName already exists, it is
        #   not replaced (and 'undef' is returned)
        return $axmud::CLIENT->add_zmpPackage($self);
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub packageName
        { $_[0]->{packageName} }
    sub compList
        { my $self = shift; return @{$self->{compList}}; }

    sub world
        { $_[0]->{world} }

    sub cmdHash
        { my $self = shift; return %{$self->{cmdHash}}; }
}

# Package must return a true value
1
