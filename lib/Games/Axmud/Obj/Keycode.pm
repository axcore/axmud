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
# Games::Axmud::Obj::Keycode
# The object that contains a collection of keycodes

{ package Games::Axmud::Obj::Keycode;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the keycode object
        #
        # Expected arguments
        #   $session    - The GA::Session which created this object (not stored as an IV)
        #   $name       - A unique string name for this keycode object (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid and not already in use by another keycode object
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );

        } elsif ($axmud::CLIENT->ivExists('keycodeObjHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: keycode object \'' . $name . '\' already exists',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'keycodes',
            _parentWorld                => undef,
            _privFlag                   => TRUE,       # All IVs are private

            # Keycode IVs
            # -----------

            name                        => $name,
            # Flag set to TRUE if any of the keycode values have been modified; FALSE if all values
            #   are still set to their defaults
            customisedFlag              => FALSE,
            # Hash of Axmud standard keycode values (initialised from GA::Client->constKeycodeHash).
            #   Hash in the form
            #       $keycodeHash{'standard_value'} = sytem_value
            # ...where 'standard_value' is a value used by Axmud to uniquely identify a key or key
            #   combination, and 'system_value_string' is the corresponding keycode returned by a
            #   system (when there is more than one corresponding keycode, they are in a single
            #   string, separated by a space)
            keycodeHash                 => {},      # Set below
            # The same hash, reversed. For standard keycodes whose value is a string containing
            #   two or more words (e.g. shift => 'Shift_L Shift_R'), two key-value pairs are added
            #   to the reverse hash (e.g. Shift_L => 'shift', Shift_R => 'shift')
            reverseKeycodeHash          => {},      # Set below
        };

        # Bless the object into existence
        bless $self, $class;

        # Set up IVs
        $self->{keycodeHash} = {$axmud::CLIENT->constKeycodeHash};
        $self->setReverseHash();        # Sets $self->reverseKeycodeHash

        return $self;
    }

    sub clone {

        # Creates a clone of an existing keycode object
        #
        # Expected arguments
        #   $session    - The GA::Session which created this object (not stored as an IV)
        #   $name       - A unique string name for this keycode object (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Check that $name is valid and not already in use by another keycode object
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                 $self->_objClass . '->clone',
            );

        } elsif ($axmud::CLIENT->ivExists('keycodeObjHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: keycode object \'' . $name . '\' already exists',
                 $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'keycodes',
            _parentWorld                => undef,
            _privFlag                   => FALSE,           # All IVs are public

            # Keycode IVs
            # -----------

            name                        => $name,
            customisedFlag              => $self->customisedFlag,
            keycodeHash                 => {$self->keycodeHash},
            reverseKeycodeHash          => {$self->reverseKeycodeHash},
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    sub setReverseHash {

        # Called by $self->new
        # Sets the value of $self->reverseKeycodeHash by reversing $self->keycodeHash
        #
        # The values in $self->keycodeHash are keycode strings, which contain one or more words
        #   separated by whitespace (e.g. shift => 'Shift_L Shift_R'). Each words gets its own
        #   entry in the reversed hash (e.g. Shift_L => 'shift', Shift_R => 'shift')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (%hash, %reverseHash);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setReverseHash', @_);
        }

        # Import the keycode hash
        %hash = $self->keycodeHash;

        # Reverse the hash
        OUTER: foreach my $type (keys %hash) {

            my (
                $value,
                @list,
            );

            $value = $hash{$type};
            @list = split(/\s+/, $value);

            INNER: foreach my $word (@list) {

                $reverseHash{$word} = $type;
            }
        }

        # Update IVs
        $self->ivPoke('reverseKeycodeHash', %reverseHash);

        return 1;
    }

    sub reset {

        # Called by GA::Cmd::ResetKeycodeObject
        # Resets this object's list of keycodes to the default list
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

        # Update IVs
        $self->ivPoke('keycodeHash', $axmud::CLIENT->constKeycodeHash);
        $self->ivPoke('customisedFlag', FALSE);

        $self->setReverseHash();        # Sets $self->reverseKeycodeHash

        return 1;
    }

    sub setValue {

        # Called by GA::Cmd::SetKeycode
        # Sets the value of an individual keycode
        #
        # Expected arguments
        #   $session    - The GA::Session which called the ';setkeycode' command
        #   $type       - The standard Axmud keycode type to reset (a key in $self->keycodeHash) or
        #                   an alternative version of this type (a key in
        #                   GA::Client->constAltKeycodeHash)
        #   $value      - The new corresponding value
        #
        # Return values
        #   'undef' on improper arguments or if $type is an invalid keycode type
        #   1 otherwise

        my ($self, $session, $type, $value, $check) = @_;

        # Local values
        my @list;

        # Check for improper arguments
        if (! defined $session || ! defined $type || ! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setValue', @_);
        }

        # If $standard is an alternative keycode type, translate it into the standard keycode type
        if ($axmud::CLIENT->ivExists('constAltKeycodeHash', $type)) {

            $type = $axmud::CLIENT->ivShow('constAltKeycodeHash', $type);

        # Otherwise, check that $type is a valid standard keycode type
        } elsif (! $self->ivExists('keycodeHash', $type)) {

            return $session->writeError(
                'The keycode type \'' . $type . '\' is invalid (try \'listkeycode\' for a list of'
                . ' keycode types)',
                $self->_objClass . '->setValue',
            );
        }

        # Update IVs
        $self->ivAdd('keycodeHash', $type, $value);
        $self->ivPoke('customisedFlag', TRUE);

        # $value is a string containing one or more words, separated by whitespace. Each of these
        #   words gets their own entry in $self->reverseKeycodeHash
        @list = split(/\s+/, $value);
        foreach my $item (@list) {

            $self->ivAdd('reverseKeycodeHash', $item, $type);
        }

        return 1;
    }

    sub resetValue {

        # Called by GA::Cmd::ResetKeycode
        # Resets an individual keycode to its default value
        #
        # Expected arguments
        #   $session    - The GA::Session which called the ';resetkeycode' command
        #   $type       - The standard Axmud keycode type to reset (a key in $self->keycodeHash) or
        #                   an alternative version of this type (a key in
        #                   GA::Client->constAltKeycodeHash)
        #
        # Return values
        #   'undef' on improper arguments or if $type is an invalid keycode type
        #   1 otherwise

        my ($self, $session, $type, $check) = @_;

        # Local variables
        my (
            $value,
            @list,
            %hash, %constKeycodeHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $type  || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetValue', @_);
        }

        # If $standard is an alternative keycode type, translate it into the standard keycode type
        if ($axmud::CLIENT->ivExists('constAltKeycodeHash', $type)) {

            $type = $axmud::CLIENT->ivShow('constAltKeycodeHash', $type);

        # Otherwise, check that $type is a valid standard keycode type
        } elsif (! $self->ivExists('keycodeHash', $type)) {

            return $session->writeError(
                'The keycode type \'' . $type . '\' is invalid (try \'listkeycode\' for a list of'
                . ' keycode types)',
                $self->_objClass . '->resetValue',
            );
        }

        # Update IVs
        $value = $axmud::CLIENT->ivShow('constKeycodeHash', $type);
        $self->ivAdd('keycodeHash', $type, $value);

        # $value is a string containing one or more words, separated by whitespace. Each of these
        #   words gets their own entry in $self->reverseKeycodeHash
        @list = split(/\s+/, $value);
        foreach my $item (@list) {

            $self->ivAdd('reverseKeycodeHash', $item, $type);
        }

        # Now, we need to check each keycode type against its default value. If they're all the
        #   same, the keycode object has now been reset to its default state (and a flag can be set)
        # Import IVs for quick lookup
        %hash = $self->keycodeHash;
        %constKeycodeHash = $axmud::CLIENT->constKeycodeHash;

        OUTER: foreach my $keycode (keys %hash) {

            if ($hash{$keycode} ne $constKeycodeHash{$keycode}) {

                # At least one keycode type isn't set to its default value
                $self->ivPoke('customisedFlag', TRUE);
                return 1;
            }
        }

        # All keycode types have been set to their default values
        $self->ivPoke('customisedFlag', FALSE);

        return 1;
    }

    sub getKeycode {

        # Called by anything
        # Given a specified standard keycode type, or one of the recognised alternative versions of
        #   this type, returns the corresponding keycode string (a string containing one or more
        #   keycodes, separated by spaces)
        #
        # Expected arguments
        #   $type       - The standard Axmud keycode type (a key in $self->keycodeHash) or the
        #                   alternative version of this type (a key in
        #                   GA::Client->constAltKeycodeHash)
        #
        # Return values
        #   'undef' on improper arguments or if $type is an invalid keycode type
        #   1 otherwise

        my ($self, $type, $check) = @_;

        # Check for improper arguments
        if (! defined $type  || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getKeycode', @_);
        }

        # If $standard is an alternative keycode type, translate it into the standard keycode type
        if ($axmud::CLIENT->ivExists('constAltKeycodeHash', $type)) {

            $type = $axmud::CLIENT->ivShow('constAltKeycodeHash', $type);

        # Otherwise, check that $type is a valid standard keycode type
        } elsif (! $self->ivExists('keycodeHash', $type)) {

            # (No error message displayed - just return 'undef')
            return undef;
        }

        # Return the keycode string
        return $self->ivShow('keycodeHash', $type);
    }

    sub reverseKeycode {

        # Called by anything
        # Converts a system keycode into the corresponding Axmud standard keycode type (e.g.
        #   converts 'Shift_L' into 'shift')
        #
        # Expected arguments
        #   $value       - The system keycode to convert
        #
        # Return values
        #   'undef' on improper arguments or if $value isn't a recognised system keycode
        #   1 otherwise

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $value  || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reverseKeycode', @_);
        }

        return $self->ivShow('reverseKeycodeHash', $value);
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub customisedFlag
        { $_[0]->{customisedFlag} }
    sub keycodeHash
        { my $self = shift; return %{$self->{keycodeHash}}; }
    sub reverseKeycodeHash
        { my $self = shift; return %{$self->{reverseKeycodeHash}}; }
}

# Package must return a true value
1
