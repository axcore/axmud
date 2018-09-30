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
# Games::Axmud::Obj::MiniWorld
# A mini-world object used by the Connections window to temporarily store changes makde to a world
#   profile's settings in that window, until they can be stored in the profile itself

{ package Games::Axmud::Obj::MiniWorld;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::OtherWin::Connect->resetTreeView, ->resetTableWidgets,
        #   ->createWorldCallback and ->resetWorldCallback
        # Creates a new instance of the mini-world object - temporarily stores any changes made to a
        #   world profile's data in the Connections window; when the window is closed, the world
        #   profiles themselves can be updated
        # When the window is displaying the basic mudlist, not a list of world profiles, this
        #   mini-world object stores changes to the basic world object (GA::Obj::BasicWorld), which
        #   are later used to create a new world profile
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments (all set to 'undef' if this is a temporary mini-world that doesn't yet
        #       correspond to an existing world profile)
        #
        #   $worldObj   - The GA::Profile::World object that might be modified by this object's
        #                   stored data (can also be a GA::Obj::BasicWorld object, if a world
        #                   profile doesn't exist yet)
        #   $selectChar - The world profile's last connected character (->lastConnectChar), which
        #                   may be 'undef'
        #   $loginAccountMode
        #               - The world profile's login account mode (->loginAccountMode)
        #   $pwdHashRef - Reference to a hash copied from the profile object's ->passwordHash
        #   $accHashRef - Reference to a hash copied from the profile object's ->accountHash
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my (
            $class, $worldObj, $selectChar, $loginAccountMode, $pwdHashRef, $accHashRef, $check,
        ) = @_;

        # Local variables
        my (
            $name,
            %passwordHash, %accountHash,
        );

        # Check for improper arguments
        if (! defined $class || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if (! defined $worldObj) {
            $name = 'unnamed_mini_world';
        } else {
            $name = $worldObj->name;
        }

        if (! defined $loginAccountMode) {

            $loginAccountMode = 'unknown';
        }

        if (defined $pwdHashRef) {

            %passwordHash = %$pwdHashRef;
        }

        if (defined $accHashRef) {

            %accountHash = %$accHashRef;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file
            _parentWorld                => undef,       # No parent file
            _privFlag                   => FALSE,       # All IVs are public

            # IVs
            # ---

            # The GA::Profile::World object (or GA::Obj::BasicWorld) and its ->name
            name                        => $name,
            worldObj                    => $worldObj,
            # An IV initially set to the world profile's last connected character (might be set
            #   to 'undef'. When the user selects a character from the table's combobox, this IV is
            #   set to that value (or to 'undef' if the 'no character' item is selected)
            selectChar                  => $selectChar,
            # Login account mode - whether an account name is needed to login to this world, as well
            #   as the usual character name/password. Used only to set the label text in some of
            #   the Connections window's 'dialogue' windows; doesn't affect the automatic login
            #   process
            loginAccountMode            => $loginAccountMode,

            # Hash of IVs, in the form
            #   $propHash{iv_name} = scalar_value
            # If the user makes any changes to a world in the Connections window, those changes are
            #   stored in this hash. When it's time to update the world profile,
            #   $self->storeChangesCallback copies them into the corresponding world profile object
            # 'iv_name' can be any of 'name', 'host', 'port' or 'descrip'
            propHash                    => {},
            # The world profile's ->loginMode IV is not stored here; instead, we store the state of
            #   the 'Auto-login' checkbutton (TRUE or FALSE), and pass the result to
            #   GA::Client->startSession
            noAutoLoginFlag             => undef,
            # A hash of characters and passwords, in the same form as
            #   GA::Profile::World->passwordHash, i.e.
            #       $passwordHash{char_profile_name} = password
            #       $passwordHash{char_profile_name} = 'undef'      (if password not known)
            passwordHash                => \%passwordHash,
            # ->passwordHash is initially copied from the world profile's ->passwordHash. Any
            #   changes are also stored in this hash. (Changes include adding a new character,
            #   regardless of whether the new character's password is set, or not)
            newPasswordHash             => {},
            # A hash of characters and associated account names, in the same form as
            #   GA::Profile::World->accountHash, i.e.
            #       $charHash{char_profile_name} = account
            #       $charHash{char_profile_name} = 'undef'      (if no associated account)
            accountHash                 => \%accountHash,
            # ->accountHash is initially copied from the world profile's ->accountHash. Any changes
            #   are also stored in this hash. (Changes include adding a new character, regardless of
            #   whether the new character's password is set, or not)
            newAccountHash              => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub reset {

        # Called by GA::OtherWin::Connect->applyChangesCallback
        # Resets some of this objects IVs after they have been transferred to a world profile
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset', @_);
        }

        # Reset IVs
        $self->ivEmpty('propHash');
        $self->ivEmpty('newPasswordHash');
        $self->ivEmpty('newAccountHash');

        if (! $self->worldObj) {

            $self->ivEmpty('passwordHash');
            $self->ivEmpty('accountHash');
        }

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub worldObj
        { $_[0]->{worldObj} }
    sub selectChar
        { $_[0]->{selectChar} }
    sub loginAccountMode
        { $_[0]->{loginAccountMode} }

    sub propHash
        { my $self = shift; return %{$self->{propHash}}; }
    sub noAutoLoginFlag
        { $_[0]->{noAutoLoginFlag} }
    sub passwordHash
        { my $self = shift; return %{$self->{passwordHash}}; }
    sub newPasswordHash
        { my $self = shift; return %{$self->{newPasswordHash}}; }
    sub accountHash
        { my $self = shift; return %{$self->{accountHash}}; }
    sub newAccountHash
        { my $self = shift; return %{$self->{newAccountHash}}; }
}

# Package must return a true value
1
