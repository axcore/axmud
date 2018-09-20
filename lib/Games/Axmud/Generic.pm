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
# Games::Axmud::Generic::Atcp
# Generic ATCP object, inherited by GA::Obj::Atcp and GA::Obj::Gmcp
#
# Games::Axmud::Generic::Cage
# The generic cage object. Cages store interfaces (triggers, alias, macros, timers and hooks) for a
#   particular profile object. When it's time to create active interfaces, the cage for each current
#   profile is checked in profile priority order. Interfaces in a cage are made active if no
#   interface with the same name (from a previously-checked cage) has already been made active. The
#   generic cage is inherited by GA::Cage::XXX
# Games::Axmud::Generic::InterfaceCage
# A generic cage object for interfaces cages, inheriting from the generic cage, and inherited by
#   GA::Cage::Trigger, etc
#
# Games::Axmud::Generic::CageMask
# The generic cage mask object. Cage masks are a way of initialising (or resetting) a task's IVs
#   depending on which profiles are current profiles. Cage masks are checked in the usual profile
#   priority order, and the task's IVs are only set by the first cage that wants to set them
# No part of the Axmud code uses a cage mask at present, but it might in the future
#
# Games::Axmud::Generic::Cmd
# Games::Axmud::Generic::Plugin::Cmd
# The generic command object, inherited by all client commands, and the generic private command
#   object, inherited by all client commands loaded from a plugin
#
# Games::Axmud::Generic::ConfigWin
# The generic 'config' window object, inherited by all 'edit' and 'pref' windows
#
# Games::Axmud::Generic::EditWin
# The generic 'edit' window, inherited by all 'edit' and 'pref' windows
#
# Games::Axmud::Generic::FixedWin
# The generic 'fixed' window object, inherited by all 'fixed' windows
#
# Games::Axmud::Generic::FreeWin
# The generic 'free' window object, inherited by all 'free' window objects except 'dialogue' windows
#
# Games::Axmud::Generic::GridWin
# The generic 'grid' window object, inherited by all 'grid' window objects
#
# Games::Axmud::Generic::Interface, Games::Axmud::Generic::InterfaceModel
# The generic interface object, inherited by all interface objects, and the generic interface model
#   object, inherited by all interface model objects
#
# Games::Axmud::Generic::MapWin
# The generic 'map' window object, inherited by all 'map' windows
#
# Games::Axmud::Generic::ModelObj
# The generic model object, inherited by all model objects
#
# Games::Axmud::Generic::OtherWin
# The generic 'other' window object, inherited by all 'other' windows
#
# Games::Axmud::Generic::Profile
# The generic profile object, inherited by GA::Profile::XXX
#
# Games::Axmud::Generic::Strip
# The generic strip object, inherited by all strip objects
#
# Games::Axmud::Generic::Table
# The generic table object, inherited by all table objects
#
# Games::Axmud::Generic::Task
# The generic task object, inherited by all tasks
#
# Games::Axmud::Generic::Win
# The generic window object, inherited by all window objects
#
# Games::Axmud::Generic::WizWin
# The generic 'wiz' window object, inherited by all 'wiz' (wizard) windows

{ package Games::Axmud::Generic::Atcp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->->processAtcpData processGmcpData
        # Creates a new instance of the ATCP/GMCP object (which stores ATCP/GMCP data structures)
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - The name of the ATCP/GMCP module, a string in the form
        #                   'Package[.SubPackages][.Message]'
        #   $origData   - The original data string, a scalar of undecoded JSON data, e.g.
        #                   '{ "zone": "town" }'
        #
        # Return values
        #   'undef' on improper arguments or if JSON conversion fails
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $origData, $check) = @_;

        # Local variables
        my (
            $msg, $data,
            @packageList,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $origData
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Split $name into its components
        @packageList = split(m/\./, $name);
        if ((scalar @packageList) > 1) {

            $msg = pop @packageList;
        }

        # Decode the JSON data. I'm still not sure what data format is allowed under ATCP (and
        #   neither is anyone else, apparently), so if ATCP isn't obviously in a JSON format, I'll
        #   enclose it in quotes to prevent GA::Client->decodeJson from throwing up an error
        if ($class eq 'Games::Axmud::Obj::Atcp') {

            if ($origData =~ m/^[^\{\}\[\]\:]*$/) {

                $origData = '"' . $origData . '"';
            }
        }

        $data = $axmud::CLIENT->decodeJson($origData);
        if (! defined $data) {

            return undef;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The name of the ATCP/GMCP module, a string in the form
            #   'Package[.SubPackages][.Message]'
            name                        => $name,
            # The components of $name - a list of package components, and the message (e.g.
            #   'Foo.Bar.Baz' produces a package component list of 2 items ('Foo', 'Bar') and a
            #   scalar message 'Baz'
            packageList                 => \@packageList,
            msg                         => $msg,

            # The ATCP/GMCP data itself. The original data string, a scalar of undecoded JSON data,
            #   e.g.  'comm.repop { "zone": "town" }'. This string is not updated when $self->data
            #   is updated
            origData                    => $origData,
            # The interpreted JSON data. The key's corresponding value can be a scalar, or a
            #   list/hash reference, with further list/hash references embedded within
            data                        => $data,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub update {

        # Called by GA::Session->processAtcpData and ->processGmcpData
        # Replaces the JSON data stored in $self->data with the new ATCP/GMCP package's data,
        #   merging embedded hashes but replacing embedded scalars and lists
        #
        # Expected arguments
        #   $jsonScalar -  A scalar of undecoded JSON data, e.g. '{ "zone": "town" }'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $jsonScalar, $check) = @_;

        # Local variables
        my $newData;

        # Check for improper arguments
        if (! defined $jsonScalar || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->update', @_);
        }

        # As described in ->new, ATCP must be handled with kid gloves
        if ($self->isa('Games::Axmud::Obj::Atcp')) {

            if ($jsonScalar =~ m/^[^\{\}\[\]\:]*$/) {

                $jsonScalar = '"' . $jsonScalar . '"';
            }
        }

        $newData = $axmud::CLIENT->decodeJson($jsonScalar);
        $self->{data} = $self->update_scalar($newData, $self->{data});

        return 1;
    }

    sub update_scalar {

        # Called by $self->update and by this function recursively
        # Replaces the JSON data stored in $self->data with the new ATCP/GMCP package's data,
        #   merging embedded hashes but replacing embedded scalars and lists
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $newScalar  - A scalar (might be a list/hash reference, might be embedded within other
        #                   list/hash references) from the recently-received ATCP/GMCP package's
        #                   data. If 'undef', the scalar was (probably) a JSON null value
        #   $oldScalar  - The corresponding scalar in the previously-received ATCP/GMCP package's
        #                   data. If 'undef', the scalar was (probably) a JSON null value
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $newScalar, $oldScalar, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->update_scalar', @_);
        }

        if (
            defined $newScalar
            && ref $newScalar eq 'HASH'
            && defined $oldScalar
            && ref $oldScalar eq 'HASH'
        ) {
            # (Merge the hashes, and return the combined hash
            foreach my $key (keys %$newScalar) {

                if (! exists $$oldScalar{$key}) {

                    $$oldScalar{$key} = $$newScalar{$key};

                } else {

                    $$oldScalar{$key} = $self->update_scalar($$newScalar{$key}, $$oldScalar{$key});
                }
            }

            return $oldScalar;

        } else {

            # (Scalar or list reference replaces the old scalar or list reference)
            return $newScalar;
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub packageList
        { my $self = shift; return @{$self->{packageList}}; }
    sub msg
        { $_[0]->{msg} }

    sub origData
        { $_[0]->{origData} }
    sub data
        { $_[0]->{data} }
}

{ package Games::Axmud::Generic::Cage;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    # All cages should inherit from this object
    # The generic object, Games::Axmud, provides generic accessor functions for accessing scalar /
    #   array / hash instance variables, analogous to Perl's functions for non-instance variables
    # This object replaces a few of those functions, allowing a cage to retrieve values from its own
    #   instance variables or, if they aren't set, find the value in its inferior cages
    # The relationship between a cage and its inferior is set by the GA::Session's
    #   ->cageInferiorHash; a hash in the form
    #       ->inferiorCageHash{cage_name} = blessed_reference_to_inferior_cage
    #       ->inferiorCageHash{cage_name} = undef (if there is no inferior cage)
    # If two sessions are connected to the same world, they will almost certainly have different
    #   current characters; both of those sessions will therefore have an identical ->cageHash,
    #   but a differnt ->inferiorCageHash
    #
    # Each of the functions can operate in two modes.
    # Normally, a cage accesses instance variables from itself if possible, or the equivalent
    #   instance variables in the inferior cages, if necessary
    # However, the functions can be made to behave like their equivalent functions in Games::Axmud
    #   if the calling GA::Session is omitted
    #
    #   ->ivGet($instVar, $session)
    #       - Get a scalar IV from this cage (if the IV is set to 'undef', consult the cage's
    #           inferiors, using the first defined value found)
    #   ->ivGet($instVar)
    #       - Get a scalar IV (from this cage only)
    #
    #   ->ivShow($instVar, $key, $session)
    #       - Retrieve the value matching $key in a hash IV (if the value is set to 'undef', consult
    #           the cage's inferiors, using the first defined value found)
    #   ->ivShow($instVar, $key)
    #       - Retrieve the value matching $key in a hash IV (from this cage only)

    ##################
    # Constructors

    ##################
    # Methods

    # IV accessor replacement methods

    sub ivGet {

        # Retrieve variable function for scalar instance variables
        #
        # Expected arguments
        #   $iv         - Which scalar instance variable to get
        #
        # Optional arguments
        #   $session    - If defined and if the IV is set to 'undef', consult the same IV in
        #                   inferior cages. Otherwise, only this cage is consulted
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist in this cage, or isn't a scalar, or
        #       improper arguments supplied)
        #
        #   If the instance variable exists in this cage and is not set to 'undef', returns it
        #   If the instance variable exists in this cage but is set to 'undef',
        #       - if $session is not defined or if there is no inferior cage, returns the value of
        #           the IV in this cage ('undef')
        #       - if $session is defined and there is an inferior cage, passes the arguments to the
        #           ->ivGet function in the inferior cage, and returns the value the inferior cage
        #           returns. (The inferior cage calls its own inferior cage recursively, if
        #           necessary)

        my ($self, $iv, $session, $check) = @_;

        # Local variables
        my ($refType, $inferior);

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivGet', @_);
        }

        # Check that the variable exists at all
        if (! exists $self->{$iv}) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar

            # Get the inferior cage (if any)
            if ($session) {

                $inferior = $session->ivShow('inferiorCageHash', $self->name);
                # If $session is defined but there is no inferior cage, we'll have to confine our
                #   search to this cage
                if (! $inferior) {

                    $session = undef;
                }
            }

            if ($session && ! defined $self->{$iv}) {

                # Consult the inferior cage
                return $inferior->ivGet($iv, $session);

            } else {

                # Return this cage's value, even if it is 'undef'
                return $self->{$iv};
            }

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivShow {

        # Function to retrieve the value of a key-value pair in hash instance variables
        #
        # Expected arguments
        #   $iv         - Which hash instance variable to test
        #   $key        - Which key-value pair to retrieve
        #
        # Optional arguments
        #   $session    - If defined and if the key's corresponding value is set to 'undef', consult
        #                   the same IV in inferior cages. Otherwise, only this cage is consulted
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist in this cage, or isn't a hash, or improper
        #       arguments supplied)
        #
        #   If the instance variable exists in this cage, but the key of the key-value pair doesn't
        #       exist, returns 'undef'
        #   If the instance variable exists in this cage and the value of the key-value pair is not
        #       'undef', returns the value
        #   If the instance variable exists in this cage but the value of the key-value pair is
        #       'undef',
        #       - if $session is not defined or if there is no inferior cage, returns the value of
        #           the key-value pair in this cage ('undef')
        #       - if $session is defined and there is an inferior cage, passes the arguments to the
        #           ->ivShow function in the inferior cage, and returns the value the inferior cage
        #           returns. (The inferior cage calls its own inferior cage recursively, if
        #           necessary)

        my ($self, $iv, $key, $session, $check) = @_;

        # Local variables
        my ($refType, $inferior);

        # Check for improper arguments
        if (! defined $iv || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivShow', @_);
        }

        # Check the variable exists at all
        if (! exists $self->{$iv}) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # This is a hash

            # Get the inferior cage (if any)
            if ($session) {

                $inferior = $session->ivShow('inferiorCageHash', $self->name);
                # If $session is defined but there is no inferior cage, we'll have to confine our
                #   search to this cage
                if (! $inferior) {

                    $session = undef;
                }
            }


            if (
                $session
                && (
                    ! exists  $self->{$iv}{$key}
                    || ! defined  $self->{$iv}{$key}
                )
            ) {
                # Consult the inferior cage
                return $inferior->ivShow($iv, $key, $session);

            } else {

                # Return this cage's value, even if it is 'undef'
                return $self->{$iv}{$key};
            }

        } else {

            # Not a hash
            return undef;
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub cageType
        { $_[0]->{cageType} }
    sub standardFlag
        { $_[0]->{standardFlag} }
    sub profName
        { $_[0]->{profName} }
    sub profCategory
        { $_[0]->{profCategory} }
}

{ package Games::Axmud::Generic::CageMask;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Cage Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Create a new instance of the generic cage mask with default instance variables
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session (not stored as an IV)
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #   $profCategory   - The profile's category (e.g. 'world', 'guild', 'faction' etc)
        #
        # Return values
        #   'undef' on improper arguments or if the cage already seems to exist
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $profName, $profCategory, $check) = @_;

        # Local variables
        my ($cageType, $name);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $profName || ! defined $profCategory || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # When you write your own cage masks, give them a cage type (max 8 chars)
        $cageType = 'genmask';
        # Compose the cage's unique name
        $name = $cageType . '_' . $profCategory . '_' . $profName;

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 42)) {

            return $session->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );

        } elsif ($session->ivExists('cageHash', $name)) {

            return $session->writeError(
                'Registry naming error: cage \'' . $name . '\' already exists',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',     # Set below for world profiles
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,           # All IVs are public

            # Standard cage IVs
            # -----------------

            name                        => $name,
            cageType                    => $cageType,
            standardFlag                => FALSE,           # This is a custom cage
            profName                    => $profName,
            profCategory                => $profCategory,

            # Generic cage mask IVs
            # ---------------------

            # These IVs are set by a call to $self->composeMask() (which should be modified for
            #   each cage mask you write), and applied to the task by a call to $self->applyMask()
            #   (which should not be modified)
            #
            # Hash of the task's IVs that can be changed using this mask (it's up to the calling
            #   code to ensure that the right cage mask is used with the right kind of task)
            # Each key in the hash is set to the name of a single task IV, and the corresponding
            #   values contain a reference to a scalar, list or hash (NOT a normal scalar, list
            #   reference or hash reference). The task's IV is set to the de-referenced scalar, list
            #   or hash
            # If the corresponding value is 'undef', lower-priority masks are consulted; the first
            #   one which returns something other than 'undef' is used to set the task's IV
            # If all of the lower-priority masks also return 'undef', the task's IV is not changed
            maskHash                    => {},
            # A list of keys from $self->maskHash, in a fixed order
            maskList                    => [],
        };

        # Bless the object into existence
        bless $self, $class;

        # Compose the mask, which sets the ->maskHash and ->maskList IVs
        $self->composeMask();

        return $self;
    }

    sub clone {

        # Creates a clone of an existing cage mask with 'undef' IVs
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session (not stored as an IV)
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #   $profCategory   - The profile's category (e.g. 'world', 'guild', 'faction' etc)
        #
        # Return values
        #   'undef' on improper arguments or if the cage already seems to exist
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $profName, $profCategory, $check) = @_;

        # Local variables
        my $name;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $profName || ! defined $profCategory
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Compose the cage's unique name
        $name = $self->cageType . '_' . $profCategory . '_' . $profName;

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 42)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($session->ivExists('cageHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: cage \'' . $name . '\' already exists',
                $self->_objClass . '->clone',
            );
        }

        # List/hash instance variables
        my (%originalHash, %copyHash);

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => undef,
            _privFlag                   => FALSE,               # All IVs are public

            # Standard cage IVs
            # -----------------

            name                        => $name,
            cageType                    => $self->cageType,
            standardFlag                => FALSE,               # This is a custom cage
            profName                    => $profName,
            profCategory                => $profCategory,


            # Generic cage mask IVs
            # ---------------------

            maskHash                    => {$self->maskHash},
            maskList                    => [$self->maskList],
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    sub composeMask {

        # Called by $self->new
        # Composes the mask by setting the IVs used to initialise the task
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            @list, @maskList,
            %maskHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->composeMask', @_);
        }

        # Compose the mask
        @list = (
            # The generic cage mask doesn't apply to any particular task and doesn't initialise or
            #   reset any task IVs
            # To write your own cage masks, fill in this list. The keys should be IVs in the task to
            #   be initialised or reset; the corresponding value should be 'undef'. The user is then
            #   free to change the 'undef' value to (a reference to) a scalar, list or hash for
            #   each copy of this cage mask, one for each current profile
            # It's possible to use cage masks to set task settings, but for the most part only task
            #   parameters should be set
            # A good idea is to list all of the task's parameter IVs here, and then to comment out
            #   any which aren't going to be initialised by the cage mask
#           someScalar                  => undef,
#           someList                    => undef,
#           someHash                    => undef,
        );

        # Compile @maskList and %maskHash
        while (@list) {

            my ($key, $value);

            $key = shift @list;
            $value = shift @list;

            $maskHash{$key} = $value;
            push (@maskList, $key);
        }

        # Update IVs
        $self->{maskHash} = \%maskHash;
        $self->{maskList} = \@maskList;

        return 1;
    }

    sub applyMask {

        # Can be called by anything
        # Applies the cage mask, changing some of the task's parameters, or none of them,
        #   depending on the contents of $self->maskHash
        # A good idea is to write a task with an ->activate function, that calls this cage mask
        #   function to initialise the task's IVs
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $taskObj    - Blessed reference of the task object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $taskObj, $check) = @_;

        # Local variables
        my ($ref, $refType);

        # Check for improper arguments
        if (! defined $session || ! defined $taskObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->applyMask', @_);
        }

        foreach my $iv ($self->ivKeys('maskHash')) {

            # Use $session as an argument to consult lower-priority masks, if necessary
            $ref = $self->ivShow('maskHash', $iv, $session);

            if (defined $ref) {

                # Is it a reference to a scalar, list or hash?
                $refType = ref $ref;

                # Set the task's IVs
                if ($refType eq 'ARRAY') {
                    $taskObj->ivPoke($iv, @$ref);
                } elsif ($refType eq 'HASH') {
                    $taskObj->ivPoke($iv, %$ref);
                } else {
                    $taskObj->ivPoke($iv, $$ref);
                }
            }
        }

        # Operation complete
        return 1;
    }

    ##################
    # Accessors

    # These methods set/return the cage's ACTUAL mask hash. To get/set values from this hash
    #   hash AND/OR its inferiors, use the generic cage's ->ivXXX functions
    sub maskHash
        { my $self = shift; return %{$self->{maskHash}}; }
    sub maskList
        { my $self = shift; return @{$self->{maskList}}; }
}

{ package Games::Axmud::Generic::Cmd;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the generic command, which contains all the code for a single
        #   client command
        #
        # Expected arguments
        #   $standardCmd    - The standard form of the command (in lower-case, e.g. 'about')
        #   $builtInFlag    - Flag set to TRUE if this is a built-in client command, FALSE if it has
        #                       been added by a modification to Axmud's code
        #   $disconnectFlag - Flag set to TRUE if this command can be used after disconnecting from
        #                       a world, FALSE otherwise
        #
        # Optional arguments
        #   $noBracketFlag  - Flag set to TRUE if brackets (..) and diamond brackets <..> should
        #                       be ignored when parsing the command into words
        #
        # Return values
        #   'undef' on improper arguments
        #   Reference to hash on success, which is blessed into existence by the calling function

        my ($class, $standardCmd, $builtInFlag, $disconnectFlag, $noBracketFlag, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $standardCmd || ! defined $builtInFlag
            || ! defined $disconnectFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that a command object with the same name hasn't already been created (this catches
        #   commands with duplicate names)
        # (Must use $axmud::CLIENT-> rather than $session->, because client commands are session
        #   -independent)
        # NB For client commands loaded from a plugin, whose $class is GA::Generic::Plugin::Cmd,
        #   we don't perform this check. If the new command has the same standard name as an
        #   existing one, the existing command is replaced
        if (! $class =~ m/plugin/) {

            if ($axmud::CLIENT->ivExists('clientCmdHash', $standardCmd)) {

                return $axmud::CLIENT->writeError(
                    'Duplicate client command \'' . $standardCmd . '\'',
                    $class . '->new',
                );
            }
        }

        # Check that the command name isn't longer than 32 characters
        if (length ($standardCmd) > 32) {

            return $axmud::CLIENT->writeError(
                'Client command \'' . $standardCmd . '\' is too long',
                $class . '->new',
            );
        }

        # $noBracketFlag must be either TRUE or FALSE
        if ($noBracketFlag) {
            $noBracketFlag = TRUE;
        } else {
            $noBracketFlag = FALSE;
        }

        # Setup
        my $self = {
            _objName                    => 'generic_cmd',
            _parentFile                 => undef,           # No parent file
            _parentWorld                => undef,           # No parent file
            _objClass                   => $class,
            _privFlag                   => TRUE,            # All IVs are private

            # Other IVs
            # ---------

            # The standard form of the command (in lower-case, e.g. 'about')
            standardCmd                 => $standardCmd,

            # Default list of user commands (user-defined abbreviations for this command)
            defaultUserCmdList          => [],
            # Current list of user commands (for this command)
            userCmdList                 => [],

            # A short description of the command
            descrip                     => undef,
            # Flag set to TRUE if this is a built-in client command, FALSE if it has been added by
            #   someone else's modifications to the Axmud code
            builtInFlag                 => $builtInFlag,
            # Flag set to TRUE if this command can be used after disconnecting from a world, FALSE
            #   otherwise
            disconnectFlag              => $disconnectFlag,
            # Flag set to TRUE if brackets (..) and diamond brackets <..> should be ignored when
            #   parsing the command into words
            noBracketFlag               => $noBracketFlag,

        };

        # (The object is blessed into existence by the calling function)
        return $self;
    }

    ##################
    # Methods

    sub do {

        # The generic command's ->do method should never be called. Returns 'undef'

        my ($self) = @_;

        return $axmud::CLIENT->writeError(
            'Forbidden call to generic command object\'s own ->do method',
            $self->_objClass . '->do',
        );
    }

    sub xyzzy {

        # Called by GA::Session->clientCmd
        # Special arrangements for experienced spelunkers
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return value
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $mode,
            @list,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->xyzzy', @_);
        }

        @list = (
            'Nothing happens.',
            'Almost nothing happens.',
            'Virtually nothing happens.',
            'Practically nothing happens.',
            'Very little is happening.',
            'Barely anything is happening.',
            'Nothing is happening, but something might start happening soon.',
            'Something is beginning to happen.',
            'Something is happening, no doubt about it.',
            'IT\'S HAPPENING!',
            'WHY DIDN\'T YOU STOP IT?',
            'YOU ONLY HAD TO LISTEN!',
        );

        $mode = $session->spelunkerMode;

        if ($mode < 9) {
            $session->writeText($list[$mode]);
        } elsif ($mode == 9) {
            $session->writeText($list[$mode], 'RED', 'ul_white', 'blink_fast');
        } elsif ($mode == 10) {
            $session->writeText($list[$mode], 'white', 'UL_RED', 'blink_fast');
        } else {
            $session->writeText($list[$mode], 'RED', 'ul_white', 'blink_slow');
        }

        $mode++;
        if ($mode > 11) {

            $mode = 0;
        }

        $session->set_spelunkerMode($mode);

        return 1;
    }

    # Methods

    sub extract {

        # Usually called by $self->do
        # Extracts a switch (and its arguments, if any) from a client command
        #
        # The calling function should make a call like this:
        #   ($switch, $arg1, $arg2, @inputWord) = $self->extract('e', 2, @inputWord);
        # This function removes the switch and its arguments from @inputWord - no matter where in
        #   the list they occur - and makes the switch and its arguments available in the return
        #   variables $switch, $arg1 and $arg2.
        # @inputWord is returned with the switch and its arguments removed, ready for more calls
        #   to this function, in order to remove other switches (and their arguments)
        # If the switch has no arguments, the call should look like this:
        #   ($switch, @inputWord) = $self->extract('e', 0 @inputWord);
        #
        # In client commands, switches are a word containing a hyphen followed by one or more
        #   letters, e.g. -e, -s, -a, -name, etc
        #
        # Examples
        # e.g. $switch = 'w', $numberArgs = 2,
        #   Original command: 'command arg1 -w arg2 arg3 arg4'
        #   @inputWord = ('command', 'arg1', '-w', 'arg2', 'arg3', 'arg4')
        #   @returnArray = ('w', 'arg2', 'arg3', 'command', 'arg1', 'arg4')
        #
        # e.g. $switch = 'w', $numberArgs = 2,
        #   Original command: 'command arg1 -w arg2 -e arg3 arg4'
        #   @inputWord = ('command', 'arg1', '-w', 'arg2', '-e', 'arg3', 'arg4')
        #   @returnArray = ('w', 'arg2', '', 'command', 'arg1', '-e', 'arg3', 'arg4')
        # (The switch -w gets exactly two arguments, regardless of how many were actually typed by
        #   the user)
        #
        #  e.g. $switch = 'x', $numberArgs = 2,
        #   Original command: 'command arg1 -w arg2 -e arg3 arg4'
        #   @inputWord = ('command', 'arg1', '-w', 'arg2', '-e', 'arg3', 'arg4')
        #   @returnArray = (undef, '', '', @inputWord)
        # (If the supplied switch -x doesn't exist in @inputWord, the first element of
        #   @returnArray is set to undef; that is followed by empty strings for the specified number
        #   of arguments (as usual), and finally @inputWord unaltered)
        #
        # Expected arguments
        #   $switch     - the switch to extract, e.g. 'f' or 'z', or even 'foobar' ($switch can
        #                   begin with a hyphen, as the user would type it; or the hyphen can be
        #                   omitted, so '-f' and 'f' are equivalent). Besides the optional initial
        #                   hyphen, $switch must contain only letters (a-z, A-Z)
        #   $numberArgs - the number of words (or groups of words) which belong to the switch. Set
        #                   to 0 if the switch has no arguments
        #   @inputWord  - a list of words (or groups of words) from which the switch and its
        #                   arguments should be extracted
        #
        # Return values
        #   Returns an empty list on improper arguments
        #
        #   Otherwise, @returnArray is now in the form
        #       ($switch, 'arg1', 'arg2', ... , 'argN')
        #   If the switch did prepend enough arguments, the missing arguments are returned as
        #       'undef'
        #   e.g. for the call $self->extract('e', 2, @inputWord);
        #       if $inputString is 'command -w arg1 -e arg2',
        #       @returnArray = ($switch, 'arg1', undef);
        #   If the $switch doesn't exist in @inputWord, @returnArray is an empty list
        #
        #   Returns @returnArray followed by anything left in @inputWord as a single list
        #   e.g. for the call $self->extract('e', 2, @inputWord);
        #       if $inputString is 'command -w arg1 -e arg2',
        #       the return list is ($switch, 'arg1', undef, '-e', 'arg1')

        my ($self, $switch, $numberArgs, @inputWord) = @_;

        # Local variables
        my (
            $count, $match, $failFlag,
            @emptyList, @returnArray,
        );

        # Check for improper arguments
        if (! defined $switch || ! defined $numberArgs) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->extract', @_);
            return @emptyList;
        }

        # If $switch doesn't begin with a hyphen (the default situation), add one
        if ((substr $switch, 0, 1) ne '-') {

            $switch = '-' . $switch;
        }

        # $switch must now be a single hyphen, followed by one or more letters
        if (! ($switch =~ m/^\-[a-zA-Z]+$/)) {

            # Invalid switch. @returnArray should be filled with 'undef' values
            #   i.e. return ($switch, $arg1, $arg2, @inputWord)
            #       >>> return (undef, undef, undef, @inputWord)
            push @returnArray, undef;
            if ($numberArgs) {

                for (my $a = 0; $a < $numberArgs; $a++) {

                    push (@returnArray, undef);
                }
            }

            return (@returnArray, @inputWord);
        }

        # Find out which array index contains the switch
        $count = -1;
        $match = -1;
        OUTER: foreach my $word (@inputWord) {

            $count++;
            if ($word eq $switch) {

                $match = $count;
                last OUTER;
            }
        }

        if ($match == -1) {

            # Switch doesn't exist. @returnArray should be filled with 'undef' values
            #   i.e. return ($switch, $arg1, $arg2, @inputWord)
            #       >>> return (undef, undef, undef, @inputWord)
            push @returnArray, undef;
            if ($numberArgs) {

                for (my $a = 0; $a < $numberArgs; $a++) {

                    push (@returnArray, undef);
                }
            }

            return (@returnArray, @inputWord);
        };

        # Remove the switch from @inputWord
        @returnArray = splice (@inputWord, $match, 1);

        # If the switch has arguments, separate them, too
        if ($numberArgs > 0) {

            for (my $a = 0; $a < $numberArgs; $a++) {

                my $word = $inputWord[$match];

                # Switch begins with a hyphen, followed by one or more letters
                if (! $failFlag && defined $word && ! ($word =~ m/^\-[a-zA-Z]+$/)) {

                    # Not a switch
                    push (@returnArray, splice (@inputWord, $match, 1));

                } else {

                    # It's a switch, or we found a switch on a previous iteration of the 'for' loop
                    push (@returnArray, undef);
                    # Don't check any more words, just add 'undef' to @returnArray for each
                    #   remaining iteration of the 'for' loop
                    $failFlag = TRUE;
                }
            }
        }

        # Return the data in the format described above
        return (@returnArray, @inputWord);
    }

    sub composeHelpLine {

        # Usually called by GA::Cmd::Help->do and SearchHelp->do
        # Composes a line of text for the standard form of a client command, showing the shortest
        #   corresponding user command, the standard form command, and a short description of the
        #   client command
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $standardCmd    - The command about which to show help, e.g. 'about'
        #
        # Optional arguments
        #   $disconnectFlag - If TRUE, adds an asterisk for commands which are available while the
        #                       the GA::Session's status is 'disconnected'. If FALSE (or 'undef'),
        #                       the asterisk is never added
        #
        # Return values
        #   'undef' on improper arguments or if $standardCmd isn't recognised
        #   Otherwise, a string in the format:
        #       '      ab / about   Shows information about Axmud'

        my ($self, $session, $standardCmd, $disconnectFlag, $check) = @_;

        # Local variables
        my ($obj, $column, $string);

        # Check for improper arguments
        if (! defined $session || ! defined $standardCmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->composeHelpLine', @_);
        }

        # Check the specified command exists
        if (! $axmud::CLIENT->ivExists('clientCmdHash', $standardCmd)) {

            return $session->writeError(
                'Could not find a client command whose standard form matches \'' . $standardCmd
                . '\'',
                $self->_objClass . '->composeHelpLine',
            );

        } else {

            $obj = $axmud::CLIENT->ivShow('clientCmdHash', $standardCmd);

            if ($disconnectFlag && $obj->disconnectFlag) {
                $column = '    * ';
            } else {
                $column = '      ';
            }

            # Compose the string and return it
            $string = $column . sprintf('%-30.30s', $obj->findShortestCmd() . ' / ' . $standardCmd)
                        . $obj->descrip();

            return $string;
        }
    }

    sub findShortestCmd {

        # Called by many command's ->do / ->help functions, e.g. GA::Cmd::About->help, etc
        # Also called by GA::Generic::Cmd->composeHelpLine
        # Returns the shortest possible user command for this command object (e.g. for the
        #   ';setworld' command, returns 'sw')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there are no user commands in $self->userCmdList
        #       (unlikeley)
        #   Otherwise returns the shortest user command

        my ($self, $check) = @_;

        # Local variables
        my $shortestCmd;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findShortestCommand', @_);
        }

        # Go through the user command list, looking for the shortest user command
        foreach my $cmd ($self->userCmdList) {

            if (! defined $shortestCmd || (length $cmd) < (length $shortestCmd)) {

                $shortestCmd = $cmd;
            }
        }

        # Return the shortest user command found - return 'undef' if none were found
        return $shortestCmd;
    }

    sub getSortedUserCmds {

        # Usually called by GA::Cmd::Help->do; also by $self->getHelpEnd
        # Gets all the user commands for this standard command, sorts them in ascending order of
        #   length, and returns the sorted list
        # e.g. for the ';listwindow' command, returns the list
        #   ('lw', 'listwin', 'listwindow')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments or if there are no user commands in
        #       $self->userCmdList (unlikely)
        #   Otherwise returns the sorted list

        my ($self, $check) = @_;

        # Local variables
        my (@list, @emptyList);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getSortedUserCmds', @_);
            return @emptyList;
        }

        @list = sort {length($a) <=> length($b)} $self->userCmdList;
        return @list;
    }

    sub convertTrueFalse {

        # Usually called by $self->do
        # Converts a specified value, $value, into the Boolean values TRUE or FALSE
        # The values 1, TRUE and any word beginning with 't' or 'T' are converted into TRUE
        # The values 0, FALSE and any word beginning with 'f' or 'F' are converted into FALSE
        #
        # Expected arguments
        #   $value   - a value to be converted
        #
        # Return values
        #   'undef' on improper arguments or if if $value isn't a recognisable Boolean value (e.g.
        #       'hello')
        #   Otherwise returns either TRUE or FALSE

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertTrueFalse', @_);
        }

        # Check for Boolean values
        if ($value eq '1' || $value =~ m/^t/i || $value eq TRUE) {

            return TRUE;

        } elsif ($value eq '0' || $value =~ m/^f/i || $value eq FALSE) {

            return FALSE;

        } else {

            # Not a recognisable Boolean value
            return undef;
        }
    }

    sub convertArrayTrueFalse {

        # Usually called by $self->do
        # Converts a list of values, @list, into a list of the Boolean values TRUE or FALSE
        #   (anything which is not a recognisable Boolean value is not modified)
        # The values 1, TRUE and any word beginning with 't' or 'T' are converted into TRUE
        # The values 0, FALSE and any word beginning with 'f' or 'F' are converted into FALSE
        #
        # Expected arguments
        #   @list  - the array to be checked
        #
        # Return values
        #   An empty list on improper arguments, or if the specified @list is empty
        #   Otherwise returns the modified array, @returnArray

        my ($self, @list) = @_;

        # Local variables
        my @returnArray;

        # (No improper arguments to check)

        foreach my $value (@list) {

            if ($value eq '1' || $value =~ m/^t/i || $value eq TRUE) {

                push (@returnArray, TRUE);

            } elsif ($value eq '0' || $value =~ m/^f/i || $value eq FALSE) {

                push (@returnArray, FALSE);

            } else {

                # Not a recognisable Boolean value
                push (@returnArray, $value);
            }
        }

        return @returnArray;
    }

    sub reverseHash {

        # Reverses a hash without losing keys belonging to non-unique values, since each new 'value'
        #   is a string containing all the original 'keys', separated by spaces
        # Designed for Axmud commands like ';listtasklabel', when all the information in a hash
        #   needs to be displayed in a comprehensible way
        #
        # e.g. When passed a hash like this...
        #       KEY         VALUE
        #       'fred'      'man'
        #       'wilma'     'woman'
        #       'barney'    'man'
        #       'betty'     'woman'
        #       'tony'      'man'
        # ...the function returns a hash that looks like this
        #       KEY         VALUE
        #       'man'       'fred barney tony'
        #       'woman'     'wilma betty'
        #
        # Expected arguments
        #   %hash       - The hash to reverse
        #
        # Return values
        #   %returnHash - The reversed hash

        my ($self, %hash) = @_;

        # Local variables
        my (
            $count,
            @keyList, @valueList,
            %returnHash,
        );

        # No improper arguments to check (if %hash is empty, so is %returnHash)

        # Convert the original %hash into flat lists of keys and values
        @keyList = keys (%hash);
        @valueList = values (%hash);

        for ($count = 0; $count < scalar @keyList; $count++) {

            my $returnValue;

            # For each key in @keyList, see if the corresponding value already exists as a key in
            #   %returnHash
            if (exists $returnHash{$valueList[$count]} ){

                # Tasklement the exiting key-value pair in %returnHash
                $returnValue = $returnHash{$valueList[$count]};
                $returnHash{$valueList[$count]} = $returnValue . ' ' . $keyList[$count];

            } else {

                # Create a new key-value pair in %returnHash
                $returnHash{$valueList[$count]} = $keyList[$count];
            }
        }

        return %returnHash;
    }

    # Methods called at end of $self->do

    sub complete {

        # Called by $self->do
        # Writes a standard message for when a command has achieved a successful result (unless
        #   command messages have been suppressed)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $standardCmd    - the standard form of the client command
        #   $msg            - a message describing the successful operation
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $standardCmd, $msg, $check) = @_;

        # Local variables
        my $string;

        # Check for improper arguments
        if (! defined $session || ! defined $standardCmd || ! defined $msg || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->complete', @_);
        }

        if ($session->cmdMode eq 'show_all' || $session->cmdMode eq 'win_error') {

            # In blind mode, say 'client command', otherwise, save space on the line by displaying
            #   just 'client'
            if ($axmud::BLIND_MODE_FLAG) {
                $string = 'Client command \'';
            } else {
                $string = 'Client \'';
            }

            return $session->writeText(
                $string . $axmud::CLIENT->constClientSigil . $standardCmd . '\' : ' . $msg,
            );

        } else {

            # Command messages have been suppressed
            return 1;
        }
    }

    sub error {

        # Called by $self->do
        # Writes a standard message for when a command fails to complete the intended operation
        #   (unless command error messages have been suppressed)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - A string containing the whole client command, e.g. 'setworld deathmud'
        #   $msg            - a message describing the failed operation
        #
        # Return values
        #   'undef'

        my ($self, $session, $inputString, $msg, $check) = @_;

        # Local variables
        my $standard;

        # Check for improper arguments
        if (! defined $session || ! defined $inputString || ! defined $msg || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->error', @_);
        }

        if ($session->cmdMode eq 'show_all' || $session->cmdMode eq 'hide_complete') {

            # Remove any leading/trailing whitespace, in case the user typed something like
            #   '; addchar'
            $inputString = $axmud::CLIENT->trimWhitespace($inputString);
            # Modify $inputString to replace a user command (e.g. 'ach') with the standard
            #   command (e.g. 'addchar')
            $standard = $self->standardCmd;
            $inputString =~ s/^\w+/$standard/i;

            # Display the error. (Deliberately don't add the name of this function as the second
            #   argument, to make the line less cluttered)
            return $session->writeError(
                '\'' . $axmud::CLIENT->constClientSigil . $inputString . '\' : ' . $msg,
            );

        } elsif ($session->cmdMode eq 'hide_system') {

            # Command error messages have been suppressed
            return undef;

        } elsif ($session->cmdMode eq 'win_error' || $session->cmdMode eq 'win_only') {

            # Show the error message in a 'dialogue' window
            $session->mainWin->showMsgDialogue(
                '\'' . $axmud::CLIENT->constClientSigil . $self->standardCmd . '\' error',
                'error',
                $msg,
                'ok',
            );

            return undef;
        }
    }

    sub improper {

        # Called by $self->do
        # Writes a standard message for when a command is supplied with a list of arguments that
        #   isn't allowed (unless command error messages have been suppressed)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - A string containing the whole client command, e.g. 'setworld deathmud'
        #                       (not including the client command sigil)
        #
        # Return values
        #   'undef'

        my ($self, $session, $inputString, $check) = @_;

        # Local variables
        my (
            $standardCmd,
            @list,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $inputString || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->improper', @_);
        }

        if ($session->cmdMode eq 'show_all' || $session->cmdMode eq 'hide_complete') {

            # Remove any leading/trailing whitespace, in case the user typed something like
            #   '; addchar'
            $inputString = $axmud::CLIENT->trimWhitespace($inputString);

            # Extract the actual user command typed (the first word in $inputString)
            @list = split(/ /, $inputString);
            $standardCmd = $axmud::CLIENT->ivShow('userCmdHash', $list[0]);

            # Display the error. (Deliberately don't add the name of this function as the second
            #   argument, to make the line less cluttered)
            return $session->writeError(
                'Bad or missing arguments in \';' . $inputString . '\' - try \';help '
                . $standardCmd . '\'',
            );

        } elsif ($session->cmdMode eq 'hide_system') {

            # Command error messages have been suppressed
            return undef;

        } elsif ($session->cmdMode eq 'win_error' || $session->cmdMode eq 'win_only') {

            # Show the error message in a 'dialogue' window
            $session->mainWin->showMsgDialogue(
                'Client command error',
                'error',
                "Improper or invalid arguments in the client command:\n$inputString",
                'ok',
            );

            return undef;
        }
    }

    # Methods inherited by more than one client command

    sub help {

        # Usually called by GA::Cmd::Help->do or GA::Cmd::HelpTest->do
        # Reads a data file corresponding to a specified client command. Returns each line from the
        #   file as a list of strings
        # First looks in /help/cmd, then in /plugins/help/cmd, then in /private/help/cmd (which
        #   doesn't exist in public releases of Axmud), then in the data directory's
        #   /plugins/help/cmd
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #
        # Optional arguments
        #   $literalFlag    - Set to TRUE when called by GA::Cmd::HelpTest->do; does not discard any
        #                       lines from the beginning/end of the file (otherwise set to FALSE or
        #                       'undef')
        #   $noPluginFlag    - Set to TRUE if we should only look in the usual help directory for
        #                       the help file. If FALSE (or 'undef'), look in the plugin help
        #                       directories as well
        #
        # Return values
        #   An empty list on improper arguments, if the file doesn't exist or if it can't be read
        #   Otherwise, returns the contents of the file as a list of strings

        my ($self, $session, $literalFlag, $noPluginFlag, $check) = @_;

        # Local variables
        my (
            $file, $fileHandle,
            @list, @emptyList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->help', @_);
            return @emptyList;
        }

        # Check the file exists
        if ($noPluginFlag) {

            $file = $axmud::SHARE_DIR . '/help/cmd/' . $self->standardCmd;

        } else {

            $file = $axmud::DATA_DIR . '/plugins/help/cmd/' . $self->standardCmd;
            if (! (-e $file)) {

                $file = $axmud::SHARE_DIR . '/plugins/help/cmd/' . $self->standardCmd;
                if (! (-e $file)) {

                    $file = $axmud::SHARE_DIR . '/private/help/cmd/' . $self->standardCmd;
                    if (! (-e $file)) {

                        $file = $axmud::SHARE_DIR . '/help/cmd/' . $self->standardCmd;

                    }
                }
            }
        }

        if (! (-e $file)) {

            $session->writeError(
                'Can\'t find help file for client command \'' . $self->standardCmd
                . '\'',
                $self->_objClass . '->help',
            );

            return @emptyList;
        }

        # Open the file for reading
        if (! open ($fileHandle, "<$file")) {

            $session->writeError(
                'Failed to open file for client command \'' . $self->standardCmd
                . '\'',
                $self->_objClass . '->help',
            );

            return @emptyList;
        }

        # Read the file
        while (1) {

            my $line = <$fileHandle>;

            if (! defined $line) {

                # File can't be read, or end of file

                if (! $literalFlag) {

                    # The next three lines of the file should contain the same text that's produced
                    #   by $self->getHelpStart, and the last three lines contains text produced by
                    #   $self->getHelpEnd, so we can ignore them
                    shift @list; shift @list; shift @list;
                    pop @list; pop @list; pop @list;
                }

                # Return the edited contents of the file
                return @list

            } else {

                chomp $line;
                push (@list, $line);
            }
        }
    }

    sub helpExists {

        # Usually called by GA::Cmd::HelpTest->do
        # Checks whether the data file corresponding to a specified client command exists, or not
        #
        # Expected arguments
        #   $standardCmd    - The standard form of the client command to check
        #
        # Return values
        #   'undef' on improper arguments or if the file doesn't exist
        #   1 if the file does exist

        my ($self, $standardCmd, $check) = @_;

        # Local variables
        my $file;

        # Check for improper arguments
        if (! defined $standardCmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->helpExists', @_);
        }

        # Check the file exists
        $file = $axmud::DATA_DIR . '/plugins/help/cmd/' . $standardCmd;
        if (! (-e $file)) {

            $file = $axmud::SHARE_DIR . '/plugins/help/cmd/' . $standardCmd;
            if (! (-e $file)) {

                $file = $axmud::SHARE_DIR . '/private/help/cmd/' . $standardCmd;
                if (! (-e $file)) {

                    $file = $axmud::SHARE_DIR . '/help/cmd/' . $standardCmd;
                }
            }
        }

        if (! (-e $file)) {
            return undef;
        } else {
            return 1;
        }
    }

    sub listHelpFiles{

        # Usually called by GA::Cmd::HelpTest->do
        # Gets a list of help files, ignoring any duplicates
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of help file names (matching the client commands they describe)

        my ($self, $check) = @_;

        # Local variables
        my (
            @emptyList, @dirList,
            %fileHash,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->listHelpFiles', @_);
            return @emptyList;
        }

        push (@dirList, $axmud::DATA_DIR . '/plugins/help/cmd/');
        push (@dirList, $axmud::SHARE_DIR . '/plugins/help/cmd/');
        push (@dirList, $axmud::SHARE_DIR . '/private/help/cmd/');
        push (@dirList, $axmud::SHARE_DIR . '/help/cmd/');

        foreach my $dir (@dirList) {

            foreach my $path (glob($dir . '*')) {

                # (Strip away the directory, and use only the command name matching the filename)
                if ($path =~ m/([A-Za-z0-9]*)$/) {

                    $fileHash{$1} = undef;
                }
            }
        }

        return (keys %fileHash);
    }

    sub getHelpStart {

        # Called by GA::Cmd::Help->do, HelpTestCmd->do and HelpAllCmd->do
        # Returns a list of strings which are displayed at the beginning of the help for this
        #   client command
        # (The list returned by $self->getHelpEnd is displayed at the end of it)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the list of strings to display

        my ($self, $check) = @_;

        # Local variables
        my (
            $shortestCmd,
            @list, @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getHelpStart', @_);
            return @emptyList;
        }

        # Get the shortest user command for this client command
        $shortestCmd = $self->findShortestCmd();

        # Compose the list and return it
        push (
            @list,
            sprintf(
                '%-30.30s', $shortestCmd . ' / ' . $self->standardCmd,
            ) . $self->descrip,
        );
        push (@list, ' ', '   Format:');

        return @list;
    }

    sub getHelpEnd {

        # Called by GA::Cmd::Help->do, HelpTest->do and HelpAll->do
        # Returns a list of strings which are displayed at the end of the help for each client
        #   command
        # (The list returned by $self->getHelpStart is displayed at the beginning of it)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the list of strings to display

        my ($self, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getHelpEnd', @_);
            return @emptyList;
        }

        # Compose the list and return it
        return (
            ' ',
            '   User commands:',
            '      ' . join(' / ', $self->getSortedUserCmds()),
        );
    }

    sub abHelp {

        # Usually called by GA::Cmd::AxbasicHelp->do
        # Reads a data file in /help/axbasic corresponding to a specified help topic
        # Returns each line from the file as a list of strings
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $topic          - The topic; can be a Axbasic keyword or intrinsic function
        #   $type           - The topic type - 'keyword' or 'func'
        #
        # Return values
        #   An empty list on improper arguments, if the file doesn't exist or if it can't be read
        #   Otherwise, returns the contents of the file as a list of strings

        my ($self, $session, $topic, $type, $check) = @_;

        # Local variables
        my (
            $file, $modTopic, $fileHandle,
            @list, @emptyList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $topic || ! defined $type || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->abHelp', @_);
            return @emptyList;
        }

        # Check the file exists
        if ($type eq 'keyword') {

            $file = $axmud::SHARE_DIR . '/help/axbasic/keyword/' . lc($topic);

        } else {

            # If the function ends with an $, the filename ends with an underline
            $modTopic = $topic;
            $modTopic =~ s/\$$/_/;

            $file = $axmud::SHARE_DIR . '/help/axbasic/func/' . lc($modTopic);
        }

        if (! (-e $file)) {

            $session->writeError(
                'Can\'t find ' . $axmud::BASIC_NAME . ' help file for \'' . $topic . '\'',
                $self->_objClass . '->abHelp',
            );

            return @emptyList;
        }

        # Open the file for reading
        if (! open ($fileHandle, "<$file")) {

            $session->writeError(
                'Failed to open ' . $axmud::BASIC_NAME . ' help file for \'' . $topic . '\'',
                $self->_objClass . '->abHelp',
            );

            return @emptyList;
        }

        # Read the file
        while (1) {

            my $line = <$fileHandle>;

            if (! defined $line) {

                # File can't be read, or end of file. Return the edited contents of the file
                return @list

            } else {

                chomp $line;
                push (@list, $line);
            }
        }
    }

    sub taskHelp {

        # Usually called by GA::Cmd::TaskHelp->do
        # Reads a data file corresponding to a specified task. Returns each line from the file as a
        #   list of strings
        # First looks in /help/task, then in /plugins/help/task, then in /private/help/task (which
        #   doesn't exist in public releases of Axmud), then in the data directory's
        #   /plugins/help/task
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $topic          - The task's 'pretty' name (e.g. 'Status', 'TaskList'); case insensitive
        #
        # Return values
        #   An empty list on improper arguments, if the file doesn't exist or if it can't be read
        #   Otherwise, returns the contents of the file as a list of strings

        my ($self, $session, $topic, $check) = @_;

        # Local variables
        my (
            $file, $fileHandle,
            @emptyList, @list,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $topic || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->taskHelp', @_);
            return @emptyList;
        }

        # Check the file exists
        $file = $axmud::SHARE_DIR . '/help/task/' . lc($topic);
        if (! (-e $file)) {

            $file = $axmud::SHARE_DIR . '/plugins/help/task/' . lc($topic);
            if (! (-e $file)) {

                $file = $axmud::SHARE_DIR . '/private/help/task/' . lc($topic);
                if (! (-e $file)) {

                    $file = $axmud::DATA_DIR . '/plugins/help/task/' . lc($topic);
                    if (! (-e $file)) {

                        $session->writeError(
                            'Can\'t find task help file for \'' . $topic . '\'',
                            $self->_objClass . '->taskHelp',
                        );

                        return @emptyList;
                    }
                }
            }
        }

        # Open the file for reading
        if (! open ($fileHandle, "<$file")) {

            $session->writeError(
                'Failed to open task help file for \'' . $topic . '\'',
                $self->_objClass . '->taskHelp',
            );

            return @emptyList;
        }

        # Read the file
        while (1) {

            my $line = <$fileHandle>;

            if (! defined $line) {

                # File can't be read, or end of file. Return the edited contents of the file
                return @list

            } else {

                chomp $line;
                push (@list, $line);
            }
        }
    }

    sub getAboutText {

        # Called by GA::Cmd::About->do (or by any other function)
        # Returns a list of strings which would be displayed in response to an ';about' command
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the list of strings to display

        my ($self, $check) = @_;

        # Local variables
        my (
            $string,
            @emptyList, @returnList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getAboutText', @_);
            return @emptyList;
        }

        # Compose a list of strings
        push (@returnList,
            $axmud::SCRIPT . ' v' . $axmud::VERSION . ' (' . $axmud::DATE . ') by '
            . $axmud::AUTHORS,
            $axmud::COPYRIGHT,
            'Website: ' . $axmud::URL,
            ' ', # Empty line
            @axmud::LICENSE_LIST,
        );

        if (@axmud::CREDIT_LIST) {

            push (@returnList,
                ' ', # Empty line
                'Credits:',
                @axmud::CREDIT_LIST,
            );
        }

        return @returnList;
    }

    sub findTask {

        # Called by GA::Cmd::HaltTask->do, KillTask->do, PauseTask->do, ResumeTask->do,
        #   ResetTask->do, OpenWindow->do and CloseWindow->do (or by any other code)
        # Searches for tasks in the current tasklist matching the string $taskName, and returns the
        #   blessed references of all matches in a list
        # $taskName can match a task label (stored in GA::Client->taskLabelHash), a task's formal
        #   name (stored in GA::Client->taskPackageHash), or the unique name of a task in the
        #   current tasklist (stored in GA::Session->currentTaskHash)
        # If $taskName is set to '-a', then all tasks in the current tasklist are returned
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $string     - The string to analyse (e.g. 'status'), or the switch '-a' to fetch all
        #                   current tasks
        #
        # Return values
        #   An empty list on improper arguments or if no matching tasks are found
        #   Otherwise returns a list of blessed references to matching tasks

        my ($self, $session, $string, $check) = @_;

        # Local variables
        my (
            $taskName,
            @emptyList, @returnArray,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $string || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findTask', @_);
            return @emptyList;
        }

        # e.g. ';halttask -a'
        if ($string eq '-a') {

            # Add every task in the current tasklist (if any)
            @returnArray = $session->ivValues('currentTaskHash');

        # e.g. ';halttask <task>'
        # Look for a task matching <task>. First check task labels...
        } elsif ($axmud::CLIENT->ivExists('taskLabelHash', $string)) {

            # <task> is a valid task label (e.g. 'status')

            # Get the task's formal name (e.g. 'status_task')
            $taskName = $axmud::CLIENT->ivShow('taskLabelHash', $string);
            # Add all running instances of this task
            foreach my $taskObj ($session->ivValues('currentTaskHash')) {

                if ($taskObj->name eq $taskName) {

                    push (@returnArray, $taskObj);
                }
            }

        # ...then check formal names...
        } elsif ($axmud::CLIENT->ivExists('taskPackageHash', $string)) {

            # <task> is a valid formal name (e.g. 'status_task')

            # Add all running instances of this task
            foreach my $taskObj ($session->ivValues('currentTaskHash')) {

                if ($taskObj->name eq $string) {

                    push (@returnArray, $taskObj);
                }
            }

        # ...finally, check unique names in the current tasklist
        } elsif ($session->ivExists('currentTaskHash', $string)) {

            # <task> is a task in the current tasklist
            push (@returnArray, $session->ivShow('currentTaskHash', $string));
        }

        # Return the list of matching tasks
        return @returnArray;
    }

    sub findGlobalInitialTask {

        # Called by GA::Cmd::Read->do, Switch->do, Alert->do (or by any other code)
        # Searches for tasks in the global initial tasklist matching the string $taskName, and
        #   returns the blessed references of all matches in a list
        # $taskName can match a task label (stored in GA::Client->taskLabelHash), a task's formal
        #   name (stored in GA::Client->taskPackageHash), or the unique name of a task in the
        #   current tasklist (stored in GA::Session->currentTaskHash)
        #
        # Expected arguments
        #   $string     - The string to analyse (e.g. 'status')
        #
        # Return values
        #   An empty list on improper arguments or if no matching tasks are found
        #   Otherwise returns a list of blessed references to matching tasks

        my ($self, $string, $check) = @_;

        # Local variables
        my (
            $taskName,
            @emptyList, @returnArray,
        );

        # Check for improper arguments
        if (! defined $string || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findGlobalInitialTask', @_);
            return @emptyList;
        }

        # Look for a task matching <task>. First check task labels...
        if ($axmud::CLIENT->ivExists('taskLabelHash', $string)) {

            # <task> is a valid task label (e.g. 'status')

            # Get the task's formal name (e.g. 'status_task')
            $taskName = $axmud::CLIENT->ivShow('taskLabelHash', $string);
            # Add all matching tasks in the global initial tasklist
            foreach my $taskObj ($axmud::CLIENT->ivValues('initTaskHash')) {

                if ($taskObj->name eq $taskName) {

                    push (@returnArray, $taskObj);
                }
            }

        # ..then check formal names...
        } elsif ($axmud::CLIENT->ivExists('taskPackageHash', $string)) {

            # <task> is a valid formal name (e.g. 'status_task')

            # Add all matching tasks in the global initial tasklist
            foreach my $taskObj ($axmud::CLIENT->ivValues('initTaskHash')) {

                if ($taskObj->name eq $string) {

                    push (@returnArray, $taskObj);
                }
            }

        # ...finally, check unique names in the global initial tasklist
        } elsif ($axmud::CLIENT->ivExists('initTaskHash', $string)) {

            # <task> is a task in the current tasklist
            push (@returnArray, $axmud::CLIENT->ivShow('initTaskHash', $string));
        }

        # Return the list of matching tasks
        return @returnArray;
    }

    sub findProfileInitialTask {

        # Called by GA::Cmd::WorldCompass->do (or by any other code)
        # An alternative to $self->findGlobalInitialTask, looking instead in a specified profile's
        #   initial tasklist for a task matching the string $taskName, and which returns the blessed
        #   references of all matches in a list
        # $taskName can match a task label (stored in GA::Client->taskLabelHash) or a task's formal
        #   name (stored in GA::Client->taskPackageHash)
        #
        # Expected arguments
        #   $string     - The string to analyse (e.g. 'status')
        #   $profObj    - Blessed reference of the profile object
        #
        # Return values
        #   An empty list on improper arguments or if no matching tasks are found
        #   Otherwise returns a list of blessed references to matching tasks

        my ($self, $string, $profObj, $check) = @_;

        # Local variables
        my (
            $taskName,
            @emptyList, @returnArray,
        );

        # Check for improper arguments
        if (! defined $string || ! defined $profObj || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findProfileInitialTask', @_);
            return @emptyList;
        }

        # Look for a task matching <task>. First check task labels...
        if ($axmud::CLIENT->ivExists('taskLabelHash', $string)) {

            # <task> is a valid task label (e.g. 'status')

            # Get the task's formal name (e.g. 'status_task')
            $taskName = $axmud::CLIENT->ivShow('taskLabelHash', $string);
            # Add all matching tasks in the world's initial tasklist
            foreach my $taskObj ($profObj->ivValues('initTaskHash')) {

                if ($taskObj->name eq $taskName) {

                    push (@returnArray, $taskObj);
                }
            }

        # ..then check formal names...
        } elsif ($axmud::CLIENT->ivExists('taskPackageHash', $string)) {

            # <task> is a valid formal name (e.g. 'status_task')

            # Add all matching tasks in the world's initial tasklist
            foreach my $taskObj ($profObj->ivValues('initTaskHash')) {

                if ($taskObj->name eq $string) {

                    push (@returnArray, $taskObj);
                }
            }
        }

        # Return the list of matching tasks
        return @returnArray;
    }

    sub findTaskPackageName {

        # Called by GA::Cmd::StartTask->do, AddInitTask->do or by any other function
        # Tries to find the package name for a task matching the specified string
        #
        # Tasks are matched in the following priority order:
        #   1. An exact match with one of the task labels in GA::Client->taskLabelHash
        #   2. An exact match with the task's formal name (e.g. 'locator_task', 'status_task')
        #   3. A match with the unique name of a currently running ('current') task
        #       (e.g. 'locator_task_56', 'status_task_57')
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $string     - The string to analyse (e.g. 'status')
        #
        # Return values
        #   'undef' on improper arguments or if a match can't be found
        #   Otherwise returns the package name, e.g. 'StatusTask', 'SocialTask'

        my ($self, $session, $string, $check) = @_;

        # Local variables
        my ($taskName, $taskObj);

        # Check for improper arguments
        if (! defined $session || ! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findTaskPackageName', @_);
        }

        # Check task labels
        if ($axmud::CLIENT->ivExists('taskLabelHash', $string)) {

            $taskName = $axmud::CLIENT->ivShow('taskLabelHash', $string);
            if ($axmud::CLIENT->ivExists('taskPackageHash', $taskName)) {

                return $axmud::CLIENT->ivShow('taskPackageHash', $taskName);
            }

        # Check standard/external task package names
        } elsif ($axmud::CLIENT->ivExists('taskPackageHash', $string)) {

            return $axmud::CLIENT->ivShow('taskPackageHash', $string);

        # Check current tasklist
        } elsif ($session->ivExists('currentTaskHash', $string)) {

            OUTER: foreach my $uniqueName ($session->ivKeys('currentTaskHash')) {

                if ($uniqueName eq $string) {

                    $taskObj = $session->ivShow('currentTaskHash', $uniqueName);
                    last OUTER;
                }
            }

            if ($taskObj) {

                $taskName = $taskObj->name;
                if ($axmud::CLIENT->ivExists('taskPackageHash', $taskName)) {

                    return $axmud::CLIENT->ivShow('taskPackageHash', $taskName);
                }
            }
        }

        # No match found
        return undef;
    }

    sub newTaskSettings {

        # Called by GA::Cmd::StartTask->do, AddInitTaskCommand->do and AddCustomTaskCommand->do
        # After a new task is created, the task's settings are set in the same way for each of the
        #   above commands
        #
        # Expected arguments
        #   $session            - The calling function's GA::Session
        #   $inputString        - What the user actually typed (e.g. ';st status -i');
        #   $standardCmd        - The standard version of the command, i.e. 'starttask'
        #   $newTask            - Blessed reference to the new task's object
        #
        # Optional arguments
        #   $otherTask          - Blessed reference to another task, for which $newTask may have to
        #                           wait
        #   $minutes, $runMinutes, $timer
        #                       - Time periods during which $newTask may have to wait
        #   $immediateFlag, $waitTaskExistFlag, $waitTaskNoExistFlag, $waitTaskStartStopFlag,
        #       $waitMinutesFlag, $unlimitedFlag, $runTaskForFlag, $runTaskUntilFlag, $noWindowFlag
        #                       - Various flags that control how $newTask is set up
        #
        # Notes
        #   Any or all of the optional arguments may have the value 'undef'
        #
        # Return values
        #   'undef' on improper arguments or if upon failure
        #   1 otherwise

        my (
            $self, $session, $inputString, $standardCmd, $newTask, $otherTask, $minutes,
            $runMinutes, $timer, $immediateFlag, $waitTaskExistFlag, $waitTaskNoExistFlag,
            $waitTaskStartStopFlag, $waitMinutesFlag, $unlimitedFlag, $runTaskForFlag,
            $runTaskUntilFlag, $noWindowFlag, $check
        ) = @_;

        # Local variables
        my $otherTaskName;

        # Check for improper arguments
        if (
            ! defined $inputString || ! defined $standardCmd || ! defined $newTask || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->newTaskSettings', @_);
        }

        # Set the task's settings, if necessary
        if ($immediateFlag) {

            # Insist that the task starts immediately (which it should be set up to do)
            $newTask->ivPoke('status', 'wait_init');
            $newTask->ivPoke('startTime', 0);

        } elsif ($waitTaskExistFlag || $waitTaskNoExistFlag || $waitTaskStartStopFlag) {

            if ($waitTaskExistFlag) {

                # Wait for a task to exist
                $newTask->ivPoke('status', 'wait_task_exist');
                $newTask->ivPoke('checkTime', $session->sessionTime);

            } elsif ($waitTaskNoExistFlag) {

                # Wait for a task to stop existing
                $newTask->ivPoke('status', 'wait_task_no_exist');
                $newTask->ivPoke('checkTime', $session->sessionTime);

            } elsif ($waitTaskStartStopFlag) {

                # Wait for a task to exist, then stop existing
                $newTask->ivPoke('status', 'wait_task_start_stop');
                $newTask->ivPoke('checkTime', $session->sessionTime);
            }

            # $otherTask can match GA::Generic::Task->name, a task label, or
            #   GA::Generic::Task->uniqueName
            if ($session->ivExists('currentTaskHash', $otherTask)) {

                # e.g. 'status_task_7'
                $otherTaskName = $session->ivShow('currentTaskHash', $otherTask);

            } elsif ($axmud::CLIENT->ivExists('taskLabelHash', $otherTask)) {

                # e.g. 'status'
                $otherTaskName = $axmud::CLIENT->ivShow('taskLabelHash', $otherTask);

            } else {

                # e.g. 'status_task'
                $otherTaskName = $otherTask;
            }

            if (! defined $otherTaskName) {

                return $self->error(
                    $session, $inputString,
                    'Unrecognised task \'' . $otherTask . '\'',
                );

            } else {

                $newTask->ivPoke('waitForTask', $otherTaskName);
            }

        } elsif ($waitMinutesFlag) {

            # Wait for some minutes
            $newTask->ivPoke('status', 'wait_init');
            $newTask->ivPoke('startTime', $session->sessionTime + ($minutes * 60));
        }

        if ($unlimitedFlag) {

            # Insist that the task runs for an unlimited period (which it should be set up to do)
            $newTask->ivPoke('endStatus', 'unlimited');

        } elsif ($runTaskForFlag) {

            # Run for some minutes
            $newTask->ivPoke('endStatus', 'run_for');
            $newTask->ivPoke('endTime', $runMinutes);

        } elsif ($runTaskUntilFlag) {

            # Run until GA::Session->sessionTime reaches a certain value
            $newTask->ivPoke('endStatus', 'run_until');
            $newTask->ivPoke('endTime', $timer);
        }

        if ($noWindowFlag && $newTask->allowWinFlag == TRUE) {

            $newTask->ivPoke('startWithWinFlag', FALSE);
        }

        return 1;
    }

    sub addProfile {

        # Called by GA::Cmd::AddGuild->do, AddRace->do, AddChar->do
        # Adds a guild/race/char profile
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'ag thief'
        #   $standardCmd    - Standard version of the client command, e.g. 'addguild'
        #   $name           - The new profile's name
        #   $category       - The category of profile - 'guild', 'race' or 'char'
        #
        # Optional arguments
        #   $pwd            - For character profiles only, the password to set. If 'undef', don't
        #                       set a password
        #   $account        - For character profiles, only, the associated account name to set. If
        #                       'undef', don't set an account name
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my (
            $self, $session, $inputString, $standardCmd, $name, $category, $pwd, $account, $check,
        ) = @_;

        # Local variables
        my ($obj, $package);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $name || ! defined $category || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addProfile', @_);
        }

        # Check that $name is a valid name
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $self->error(
                $session, $inputString,
                'Could not add ' . $category . ' profile \'' . $name . '\' - invalid name',
            );

        # Check the profile doesn't already exist
        } elsif ($session->ivExists('profHash', $name)) {

            return $self->error(
                $session, $inputString,
                'Could not add ' . $category . ' profile \'' . $name . '\' - profile already'
                . ' exists',
            );
        }

        # Create a new profile
        $package = 'Games::Axmud::Profile::' . ucfirst($category);
        $obj = $package->new($session, $name, $session->currentWorld->name);
        if (! $obj) {

            return $self->error(
                $session, $inputString,
                'Could not add ' . $category . ' profile \'' . $name . '\'',
            );
        }

        # Create its associated cages
        if (! $session->createCages($obj)) {

            return $self->error(
                $session, $inputString,
                'Could not add ' . $category .' profile \'' . $name . '\' - errors while creating'
                . ' cages',
            );
        }

        # Update IVs
        $session->add_prof($obj);
        # Tell the current world it's acquired a new associated definiton
        $session->currentWorld->ivAdd('profHash', $name, $category);
        # If it's a character profile, update more IVs
        if ($category eq 'char') {

            # (The password can be 'undef')
            $session->currentWorld->ivAdd('passwordHash', $name, $pwd);
            # (The account name can be 'undef')
            $session->currentWorld->ivAdd('accountHash', $name, $account);
        }

        # Operation complete
        if (! $pwd) {

            return $self->complete(
                $session, $standardCmd,
                'Added ' . $category . ' profile \'' . $name . '\'',
            );

        } else {

            # Obfuscate the password, using the same number of asterisk characters as elsewhere
            return $self->complete(
                $session, $standardCmd,
                'Added ' . $category . ' profile \'' . $name . '\' with the password \'********\'',
            );
        }
    }

    sub setProfile {

        # Called by GA::Cmd::SetGuild->do, SetRace->do, SetChar->do
        # Sets the current guild/race/char profile
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'sg thief'
        #   $standardCmd    - Standard version of the client command, e.g. 'setguild'
        #   $name           - The profile's name
        #   $category       - The category of profile - 'guild', 'race' or 'char'
        #
        # Optional arguments
        #   $pwd            - For character profiles only, the password to set. If the character
        #                       also exists, the password is updated. If 'undef', don't set or
        #                       update a password
        #   $account        - For character profiles, only, the associated account name to set. If
        #                       'undef', don't set an account name
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my (
            $self, $session, $inputString, $standardCmd, $name, $category, $pwd, $account, $check,
        ) = @_;

        # Local variables
        my (
            $iv, $currentObj, $obj, $package, $historyObj,
            %customProfHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $name || ! defined $category || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setProfile', @_);
        }

        # Check there are no 'free' windows open
        if ($axmud::CLIENT->desktopObj->listSessionFreeWins($session, TRUE)) {

            return $self->error(
                $session, $inputString,
                'Can\'t set a current profile while there are \'free\' windows (such as edit,'
                . ' preference and wizard windows) open - try closing them first',
            );
        }

        # If the profile already exists, check it isn't already a current profile
        if ($session->ivExists('currentProfHash', $category)) {

            $currentObj = $session->ivShow('currentProfHash', $category);
            if ($currentObj->name eq $name) {

                # Error message depends on whether it's the right kind of profile
                if ($currentObj->category eq $category) {

                    return $self->error(
                        $session, $inputString,
                        'The profile \'' . $name . '\' is already the current ' . $category
                        . ' profile',
                    );

                } else {

                    return $self->error(
                        $session, $inputString,
                        'The profile \'' . $name . '\' is the current ' . $currentObj->category
                        . ' profile',
                    );
                }
            }
        }

        # For character profiles, need to check that another session isn't already using the same
        #   profile. The TRUE flag means 'ignore sessions whose ->status is 'disconnected')
        if (
            $category eq 'char'
            && $axmud::CLIENT->testSessions($session->currentWorld->name, $name, TRUE)
        ) {
            return $self->error(
                $session, $inputString,
                'You are already using \'' . $name . '\' as the current character profile in'
                . ' another session',
            );
        }

        # If the profile exists, use it
        if ($session->ivExists('profHash', $name)) {

            $obj = $session->ivShow('profHash', $name);

            # Check it's the right category of profile
            if ($obj->category ne $category) {

                return $self->error(
                    $session, $inputString,
                    'The profile \'' . $name . '\' is a ' . $obj->category . ' profile',
                );
            }

            # If there was already a current profile of this category, remove its interfaces
            #   and any of its initial tasks/scripts which are now running in the current tasklist
            if ($currentObj) {

                $session->haltProfileTasks($currentObj->name);
                $session->resetProfileInterfaces($currentObj->name);
            }

            # Update IVs
            $session->add_currentProf($obj); # Also sets ->currentGuild etc, ->currentProfChangeFlag
            # Tell the current world it's acquired a new associated definiton
            $session->currentWorld->ivAdd('profHash', $name, $category);
            # If it's a character profile and a password/account name was specified, use it
            if ($category eq 'char') {

                if (defined $pwd) {

                    $session->currentWorld->ivAdd('passwordHash', $name, $pwd);
                }

                if (defined $account) {

                    $session->currentWorld->ivAdd('accountHash', $name, $account);
                }
            }

            # Set up cages for the new current profile
            $session->setCurrentCages($name, $category);

            # Guild/race profiles only - if there's a current character, inform it it's acquired a
            #   new guild/race
            if ($category eq 'guild' || $category eq 'race') {

                if ($session->currentChar) {

                    if ($category eq 'guild') {
                        $session->currentChar->ivPoke('guild', $name);
                    } elsif ($category eq 'race') {
                        $session->currentChar->ivPoke('race', $name);
                    }
                }

            # Character profiles only - if the character profile specifies a guild, race or custom
            #   profiles set, mark them as current profiles too (creating them, if necessary)
            # If the character profile doesn't specify a guild, race or other custom profile, unset
            #   the current profiles in those categories
            } elsif ($category eq 'char') {

                if ($obj->guild) {
                    $session->pseudoCmd('setguild ' . $obj->guild, 'hide_complete');
                } else {
                    $session->del_currentProf('guild');
                }

                if ($obj->race) {
                    $session->pseudoCmd('setrace ' . $obj->race, 'hide_complete');
                } else {
                    $session->del_currentProf('race');
                }

                %customProfHash = $obj->customProfHash;
                foreach my $customProf (keys %customProfHash) {

                    my $customCategory = $customProfHash{$customProf};

                    $session->pseudoCmd(
                        'setcustomprofile ' . $customCategory . ' ' . $customProf,
                        'hide_complete',
                    );
                }
            }

            # Set cage inferiors
            $session->setCageInferiors();
            # Add new interfaces for this profile's cages
            $session->setProfileInterfaces($name);

            # If the current profile has any initial tasks or initial scripts, clone them into
            #   the current tasklist. The FALSE argument means 'don't consult the global initial
            #   tasklist/scriptlist'
            $session->startInitTasks(FALSE, $obj);
            $session->startInitScripts(FALSE, $obj);

            # If the character profile has been set and the session's connection history object
            #   doesn't have a character marked, set it
            if ($category eq 'char' && $session->status eq 'connected') {

                $historyObj = $session->currentWorld->ivIndex(
                    'connectHistoryList',
                    $session->currentWorld->ivLast('connectHistoryList'),
                );

                if (
                    $historyObj
                    && $historyObj->_parentWorld eq $session->currentWorld->name
                    && ! defined $historyObj->char
                ) {
                    $historyObj->set_char($name);
                }
            }

            # If the Status task's counters are running, reset their values, and turn them off
            if ($session->statusTask) {

                $session->statusTask->update_profiles();
            }

            # Operation complete
            if (! $pwd) {

                return $self->complete(
                    $session, $standardCmd,
                    'Set \'' . $name . '\' as the current ' . $category . ' profile',
                );

            } else {

                return $self->complete(
                    $session, $standardCmd,
                    'Set \'' . $name . '\' as the current ' . $category . ' profile (and'
                    . ' changed the password to \'********\')',
                );
            }

        # Otherwise create a new profile, and make it the current one
        } else {

            # Check that $name is a valid name
            if (! $axmud::CLIENT->nameCheck($name, 16)) {

                return $self->error(
                    $session, $inputString,
                    'Could not add ' . $category . ' profile \'' . $name . '\' - invalid name',
                );
            }

            # If there was already a current profile of this category, remove its interfaces and any
            #   of its initial tasks/scripts which are now running in the current tasklist
            if ($currentObj) {

                $session->haltProfileTasks($currentObj->name);
                $session->resetProfileInterfaces($currentObj->name);
            }

            # Create a new profile
            $package = 'Games::Axmud::Profile::' . ucfirst($category);
            $obj = $package->new($session, $name, $session->currentWorld->name);
            if (! $obj) {

                return $self->error(
                    $session, $inputString,
                    'Could not add ' . $category . ' profile \'' . $name . '\'',
                );
            }

            # Update IVs now, because the call to ->createCages won't work without them
            $session->add_prof($obj);
            $session->add_currentProf($obj);    # Also sets ->currentGuild, ->currentProfChangeFlag
            # If it's a character profile, update more IVs
            if ($category eq 'char') {

                # Either of both of $pwd and $account can be 'undef'
                $session->currentWorld->ivAdd('passwordHash', $name, $pwd);
                $session->currentWorld->ivAdd('accountHash', $name, $account);

                # Reset any current profiles beside the current world, and the (new) current
                #   character
                foreach my $thisProf ($session->ivValues('currentProfHash')) {

                    if ($thisProf->category ne 'world' && $thisProf->category ne 'char') {

                        $session->del_currentProf($thisProf->category);
                    }
                }
            }

            # Create its associated cages
            if (! $session->createCages($obj, TRUE)) {

                # Some objects couldn't be created. Destroy any newly-created cages, if any (don't
                #   specify the TRUE flag because $obj isn't a current profile yet)
                $session->destroyCages($obj);

                # Unset the IVs set above
                $session->del_prof($obj);
                $session->del_currentProf($obj->category);

                return $self->error(
                    $session, $inputString,
                    'Could not add ' . $category .' profile \'' . $name . '\' - errors while'
                    . ' creating cages',
                );
            }

            # Tell the current world it's acquired a new associated definiton
            $session->currentWorld->ivAdd('profHash', $name, $category);
            # If there's a current character, inform it it's acquired a new guild/race
            if ($session->currentChar) {

                if ($category eq 'guild') {
                    $session->currentChar->ivPoke('guild', $name);
                } elsif ($category eq 'race') {
                    $session->currentChar->ivPoke('race', $name);
                }
            }

            # If the current profile has any initial tasks or initial scripts, clone them into the
            #   current tasklist. The FALSE argument means 'don't consult the global initial
            #   tasklist/scriptlist'
            $session->startInitTasks(FALSE, $obj);
            $session->startInitScripts(FALSE, $obj);

            # If the character profile has been set and the session's connection history object
            #   doesn't have a character marked, set it
            if ($category eq 'char' && $session->status eq 'connected') {

                $historyObj = $session->currentWorld->ivIndex(
                    'connectHistoryList',
                    $session->currentWorld->ivLast('connectHistoryList'),
                );

                if ($historyObj && ! defined $historyObj->char) {

                    $historyObj->set_char($name);
                }
            }

            # If the Status task's counters are running, reset their values, and turn them off
            if ($session->statusTask) {

                $session->statusTask->update_profiles();
            }

            # Operation complete
            if (! $pwd) {

                return $self->complete(
                    $session, $standardCmd,
                    'Added \'' . $name . '\' as the current ' . $category . ' profile',
                );

            } else {

                return $self->complete(
                    $session, $standardCmd,
                    'Added \'' . $name . '\' with the password \'********\' as the current '
                    . $category . ' profile',
                );
            }
        }
    }

    sub unsetProfile {

        # Called by GA::Cmd::UnsetGuild->do, UnsetRace->do, UnsetChar->do
        # Unsets the current guild/race/char profile (so that it's not a current profile
        #   any more)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'ug thief'
        #   $standardCmd    - Standard version of the client command, e.g. 'unsetguild'
        #   $category       - The category of profile - 'guild', 'race' or 'char'
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my ($self, $session, $inputString, $standardCmd, $category, $check) = @_;

        # Local variables
        my (
            $obj,
            %customProfHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $category || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->unsetProfile', @_);
        }

        # Check there are no 'free' windows open in any session
        if ($axmud::CLIENT->desktopObj->freeWinHash) {

            return $self->error(
                $session, $inputString,
                'Can\'t delete a profile while there are \'free\' windows (such as edit,'
                . ' preference and wizard windows) open in any session - try closing them first',
            );
        }

        # Check there is a current profile of the right category
        if (! $session->ivExists('currentProfHash', $category)) {

            return $self->error(
                $session, $inputString,
                'There is no current ' . $category . ' profile',
            );

        } else {

            $obj = $session->ivShow('currentProfHash', $category);
        }

        # Guild/race profiles only - if there's a current character, inform it it has lost its
        #   guild/race
        if ($category eq 'guild' || $category eq 'char') {

            if ($session->currentChar) {

                if ($category eq 'guild') {
                    $session->currentChar->ivUndef('guild');
                } elsif ($category eq 'race') {
                    $session->currentChar->ivUndef('race');
                }
            }

        # Character profiles only - if the character profile specifies a guild, race or custom
        #   profiles as current profile, unset them, too
        } elsif ($category eq 'char') {

            if ($obj->guild) {

                $obj->ivUndef('guild');
                $session->pseudoCmd('unsetguild', 'hide_complete');
            }

            if ($obj->race) {

                $obj->ivUndef('race');
                $session->pseudoCmd('unsetrace', 'hide_complete');
            }

            if ($obj->customProfHash) {

                %customProfHash = $obj->customProfHash;
                foreach my $customProf (keys %customProfHash) {

                    $session->pseudoCmd('unsetcustomprofile ' . $customProf, 'hide_complete');
                }

                $obj->ivEmpty('customProfHash');
            }
        }

        # Remove this profile's interfaces
        $session->resetProfileInterfaces($obj->name);
        # Unset any cages for this profile as current cages
        $session->unsetCurrentCages($obj->name, $category);
        # Unset the profile as a current defintitions
        $session->del_currentProf($category);

        # If the Status task's counters are running, reset their values, and turn them off
        if ($session->statusTask) {

            $session->statusTask->update_profiles();
        }

        return $self->complete(
            $session, $standardCmd,
            'The current ' . $category . ' profile has been unset as a current profile',
        );
    }

    sub cloneProfile {

        # Called by GA::Cmd::CloneGuild->do, CloneRace->do, CloneChar->do,
        #   CloneCustomProfile->do
        # Clones a guild/race/char or custom profile
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'cg thief assassin'
        #   $standardCmd    - Standard version of the client command, e.g. 'cloneguild'
        #   $original       - The existing profile's name
        #   $copy           - The new cloned profile's name
        #   $category       - The category of profile - 'guild', 'race' or 'char' or a custom
        #                       profile category
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my ($self, $session, $inputString, $standardCmd, $original, $copy, $category, $check) = @_;

        # Local variables
        my ($originalObj, $copyObj);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $original || ! defined $copy || ! defined $category || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->cloneProfile', @_);
        }

        # Check that the $original profile exists, and that the $copy doesn't yet exist
        if (! $session->ivExists('profHash', $original)) {

            return $self->error(
                $session, $inputString,
                'Could not clone the ' . $category . ' profile \'' . $original . '\' - the profile'
                . ' doesn\'t exist',
            );

        } elsif ($session->ivExists('profHash', $copy)) {

            return $self->error(
                $session, $inputString,
                'Could not clone the ' . $category . ' profile \'' . $original . '\' - a profile'
                . ' called \'' . $copy . '\' already exists',
            );

        } else {

            $originalObj = $session->ivShow('profHash', $original);
        }

        # Check that $originalObj is the right category of profile
        if ($originalObj->category ne $category) {

            return $self->error(
                $session, $inputString,
                'The profile \'' . $original . '\' is a ' . $originalObj->category . ' profile',
            );
        }

        # Check that $copy is a valid profile name
        if (! $axmud::CLIENT->nameCheck($copy, 16)) {

            return $self->error(
                $session, $inputString,
                'Could not create the cloned ' . $category . ' profile \'' . $copy
                . '\' - invalid name',
            );
        }

        # Create the cloned profile
        $copyObj = $originalObj->clone($session, $copy);
        if (! $copyObj) {

            return $self->error(
                $session, $inputString,
                'Could not create the cloned ' . $category . ' profile \'' . $copy . '\'',
            );
        }

        # Create its associated cages
        if (! $session->cloneCages($originalObj, $copyObj)) {

            # Some objects couldn't be created. Destroy any newly-created cages, if any (don't
            #   specify the TRUE flag because $obj isn't a current profile yet)
            $session->destroyCages($copyObj);

            return $self->error(
                $session, $inputString,
                'Could not create the cloned ' . $category .' profile \'' . $copy
                . '\' - errors while cloning cages',
            );

        } else {

            # Updates IVs
            $session->add_prof($copyObj);
            # Tell the current world it's acquired a new associated definiton
            $session->currentWorld->ivAdd('profHash', $copy, $category);
            # If it's a character profile, update more IVs
            if ($category eq 'char') {

                # Character's password and associated account names not yet known
                $session->currentWorld->ivAdd('passwordHash', $copy, undef);
                $session->currentWorld->ivAdd('accountHash', $copy, undef);
            }

            return $self->complete(
                $session, $standardCmd,
                'Created cloned ' . $category . ' profile \'' . $copy . '\'',
            );
        }
    }

    sub deleteProfile {

        # Called by GA::Cmd::DeleteGuild->do, DeleteRace->do, DeleteChar->do or
        #   DeleteCustomProfile->do
        # Deletes a guild/race/char or custom profile
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'ug thief'
        #   $standardCmd    - Standard version of the client command, e.g. 'unsetguild'
        #   $name           - The profile's name
        #   $category       - The category of profile - 'guild', 'race' or 'char' or a custom
        #                       profile category
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my ($self, $session, $inputString, $standardCmd, $name, $category, $check) = @_;

        # Local variables
        my (
            $obj,
            %customProfHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $name || ! defined $category || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteProfile', @_);
        }

        # Check there are no 'free' windows open in any session
        if ($axmud::CLIENT->desktopObj->freeWinHash) {

            return $self->error(
                $session, $inputString,
                'Can\'t delete a profile while there are \'free\' windows (such as edit,'
                . ' preference and wizard windows) open in any session - try closing them first',
            );
        }

        # Check the profile exists
        if (! $session->ivExists('profHash', $name)) {

            return $self->error(
                $session, $inputString,
                'The profile \'' . $name . '\' doesn\'t exist',
            );

        } else {

            $obj = $session->ivShow('profHash', $name);
        }

        # Check the profile is the right category
        if ($obj->category ne $category) {

            return $self->error(
                $session, $inputString,
                'The profile \'' . $name . '\' is a ' . $obj->category . ' profile',
            );
        }

        # Delete a current profile
        if (defined $session->currentGuild && $session->currentGuild eq $obj) {

            # Remove this profile's interfaces
            $session->resetProfileInterfaces($obj->name);
            # Destroy its cages
            $session->destroyCages($obj, TRUE);
            # Unset the profile as a current defintition
            $session->del_currentProf($category);
            # Remove the profile
            $session->del_prof($obj);

            # Guild/race profiles only - if there's a current character, inform it that it has lost
            #   its associated profile
            if ($category eq 'guild' || $category eq 'race') {

                if ($session->currentChar) {

                    if ($category eq 'guild') {
                        $session->currentChar->ivUndef('guild');
                    } elsif ($category eq 'race') {
                        $session->currentChar->ivUndef('race');
                    }
                }

            # Character profiles only - if the character profile specifies a guild, race or custom
            #   profiles as current profiles, unset them
            } elsif ($category eq 'char') {

                if ($obj->guild) {

                    $obj->ivUndef('guild');
                    $session->pseudoCmd('unsetguild', 'hide_complete');
                }

                if ($obj->race) {

                    $obj->ivUndef('race');
                    $session->pseudoCmd('unsetrace', 'hide_complete');
                }

                if ($obj->customProfHash) {

                    %customProfHash = $obj->customProfHash;
                    foreach my $customProf (keys %customProfHash) {

                        $session->pseudoCmd('unsetcustomprofile ' . $customProf, 'hide_complete');
                    }

                    $obj->ivEmpty('customProfHash');
                }
            }

            # If there is a current world, remove the profile from its hash
            if ($session->currentWorld) {

                $session->currentWorld->ivDelete('profHash', $name);
            }

            # If it's a character profile, update more IVs
            if ($category eq 'char') {

                $session->currentWorld->ivDelete('passwordHash', $name);
                $session->currentWorld->ivDelete('accountHash', $name);
            }

            return $self->complete(
                $session, $standardCmd,
                'Deleted the current ' . $category . ' profile \'' . $name . '\'',
            );

        # Delete a non-current profile
        } else {

            # Destroy its cages
            $session->destroyCages($obj, FALSE);
            # Remove the profile
            $session->del_prof($obj);

            # If there is a current world, remove the profile from its hash
            if ($session->currentWorld) {

                $session->currentWorld->ivDelete('profHash', $name);
            }

            # If it's a character profile, update more IVs
            if ($category eq 'char') {

                $session->currentWorld->ivDelete('passwordHash', $name);
                $session->currentWorld->ivDelete('accountHash', $name);
            }

            return $self->complete(
                $session, $standardCmd,
                'Deleted the ' . $category . ' profile \'' . $name . '\'',
            );
        }
    }

    sub listProfile {

        # Called by GA::Cmd::ListGuild->do, ListRace->do, ListChar->do
        # Lists guild/race/char profiles
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'ug thief'
        #   $standardCmd    - Standard version of the client command, e.g. 'unsetguild'
        #   $category       - The category of profile - 'guild', 'race' or 'char'
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my ($self, $session, $inputString, $standardCmd, $category, $check) = @_;

        # Local variables
        my (
            @profList, @sortedList,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $category || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->listProfile', @_);
        }

        # Get a list of profiles, and remove anything that's not the right category
        foreach my $obj ($session->ivValues('profHash')) {

            if ($obj->category eq $category) {

                push (@profList, $obj);
            }
        }

        # Sort the list
        @sortedList = sort {lc($a->name) cmp lc($b->name)} (@profList);
        if (! @sortedList) {

            return $self->complete(
                $session, $standardCmd,
                'The ' . $category . ' profile list is empty',
            );
        }

        # Display header
        $session->writeText(
            'List of ' . $category . ' profiles (* = current ' . $category . ')',
        );

        # Display list
        foreach my $obj (@sortedList) {

            my $column;

            if (
                $session->ivExists('currentProfHash', $category)
                && $session->ivShow('currentProfHash', $category) eq $obj
            ) {
                $column = ' * ';
            } else {
                $column = '   ';
            }

            $self->writeText($column . sprintf('%-16.16s', $obj->name));
        }

        # Display footer
        if (@sortedList == 1) {

            return $self->complete(
                $session, $standardCmd,
                'End of list (1 ' . $category . ' profile found)',
            );

        } else {

            return $self->complete(
                $session, $standardCmd,
                'End of list (' . scalar @sortedList . ' ' . $category . ' profiles found)',
            );
        }
    }

    sub addInterface {

        # Called by GA::Cmd::AddTrigger->do, AddAlias->do, AddMacro->do, AddTimer->do and
        #   AddHook->do
        # (For the whole of this function, 'trigger' is taken to mean any of 'trigger', 'alias',
        #   'macro', 'timer' or 'hook')
        #
        # This function adds an independent trigger to a trigger cage in response to the client
        #   command ';addtrigger'
        # Unless there is a superior cage with a trigger of the same name, also adds an active
        #   trigger interface to the GA::Session's registry of active interfaces. In that case, if
        #   there is an inferior cage with a trigger of the same name, the corresponding active
        #   interface (if any) is destroyed. As a result, there will be exactly one active trigger
        #   interface with this name
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'atr -p pattern -a action'
        #   $standardCmd    - Standard version of the client command, e.g. 'addtrigger'
        #   $category       - 'trigger', 'alias', 'macro', 'timer', 'hook'
        #   $categoryPlural - e.g. 'triggers'
        #   $modelObj       - The interface model object corresponding to $category
        #   @args           - The arguments specified by the user in the ';addtrigger' command
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my (
            $self, $session, $inputString, $standardCmd, $category, $categoryPlural, $modelObj,
            @args,
        ) = @_;

        # Local variables
        my (
            $switch, $name, $value, $attribCount, $matchCount, $failFlag, $result, $profCategory,
            $profName, $profCount, $newObj, $newObjName, $proposedName, $cage, $package, $dummyObj,
            $newStimulus, $newResponse, $exitFlag,
            @superiorList, @inferiorList,
            %attribHash, %optionalAttribHash, %beforeHash, %afterHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $category || ! defined $categoryPlural || ! defined $modelObj || ! @args
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addInterface', @_);
        }

        # Extract group 4 (optional) switch options
        do {

            $exitFlag = TRUE;

            ($switch, $name, @args) = $self->extract('-b', 1, @args);
            if (defined $switch) {

                $exitFlag = FALSE;          # Allow the loop to repeat, looking for more -b switches

                if (! defined $name) {

                    return $self->error(
                        $session, $inputString,
                        ucfirst($category) . ' interface not created - missing name',
                    );

                } elsif (! exists $afterHash{$name}) {

                    # If the user specifies the same interface name twice (or more), it's only used
                    #   once. If the same name is specified with the -b and -f flags, it's only
                    #   added to the 'after' hash
                    $beforeHash{$name} = undef;
                }
            }

            ($switch, $name, @args) = $self->extract('-f', 1, @args);
            if (defined $switch) {

                $exitFlag = FALSE;          # Allow the loop to repeat, looking for more -f switches

                if (! defined $name) {

                    return $self->error(
                        $session, $inputString,
                        ucfirst($category) . ' interface not created - missing name',
                    );

                } else {

                    # If the user specifies the same interface name twice (or more), it's only used
                    #   once
                    $afterHash{$name} = undef;
                }
            }

        # Continue loop no more group 4 switches are found
        } until ($exitFlag);

        # Extract group 3 (optional) switch options
        foreach my $attrib ($modelObj->ivKeys('optionalSwitchHash')) {

            ($switch, $value, @args) = $self->extract(
                $modelObj->ivShow('optionalSwitchHash', $attrib),
                1,
                @args,
            );

            if (defined $switch) {

                if (! exists $attribHash{$attrib}) {

                    $attribHash{$attrib} = $value;
                    if ($modelObj->ivExists('optionalAttribHash', $attrib)) {

                        $optionalAttribHash{$attrib} = $value;
                    }

                } else {

                    # Optional switch options can't be specified more than once
                    return $self->error(
                        $session, $inputString,
                        ucfirst($category) . ' interface not created - duplicate optional switch'
                        . ' patterns',
                    );
                }
            }
        }

        # Extract group 2 (compulsory) switch options
        $attribCount = 0;
        $matchCount = 0;
        $failFlag = 0;
        foreach my $attrib ($modelObj->ivKeys('compulsorySwitchHash')) {

            $attribCount++;
            ($switch, $value, @args) = $self->extract(
                $modelObj->ivShow('compulsorySwitchHash', $attrib),
                1,
                @args,
            );

            if (defined $switch) {

                if (! exists $attribHash{$attrib}) {

                    $matchCount++;
                    $attribHash{$attrib} = $value;
                    if ($modelObj->ivExists('optionalAttribHash', $attrib)) {

                        $optionalAttribHash{$attrib} = $value;
                    }

                } else {

                    # Compulsory switch options can't be specified more than once
                    $failFlag = TRUE;
                }
            }
        }

        # Check that all group 2 (compulsory) switch options were found exactly one once
        if ($attribCount != $matchCount || $failFlag) {

            return $self->error(
                $session, $inputString,
                ucfirst($category) . ' interface not created - missing or duplicate compulsory'
                . ' switch options',
            );
        }

        # Extract profile (group 1) switch options
        ($profCount, $profCategory, $profName, @args) = $self->extractProfileSwitches(
            $session,
            $inputString,
            $category,
            'add',
            @args,
        );

        if (! defined $profCount) {

            # Error in ->extractProfileSwitches - error message already displayed
            return undef;

        # 0 or 1 associated profiles can be specified, but no more
        } elsif ($profCount > 1) {

            return $self->error(
                $session, $inputString,
                'Can\'t create an interface associated with multiple profiles - choose one from'
                . ' -w, -g, -r, -c, -x, -d',
            );

        # If no associated profile specified, use the current world as the associated profile
        } elsif ($profCount == 0) {

            $profCount++;
            $profCategory = 'world';
            $profName = $session->currentWorld->name;
        }

        # @args should now be empty. If not, return an error message
        if (@args) {

            return $self->improper($session, $inputString);
        }

        # For macros, the stimulus can be one of Axmud's standard keycodes (like 'F5') or a keycode
        #   string (like 'shift f5').
        # Keycodes in a keycode string must be in a given order (i.e. 'ctrl shift f5', not
        #   'shift ctrl f5' or even 'f5 shift ctrl'). Change the order of words in the keycode
        #   string, if necessary
        if ($category eq 'macro') {

            $attribHash{'stimulus'} = $axmud::CLIENT->convertKeycodeString($attribHash{'stimulus'});
        }

        # %attribHash doesn't contain all possible attributes. Fill it in, using default values
        #   for any attributes that haven't yet been entered into it
        foreach my $attrib ($modelObj->ivKeys('optionalAttribHash')) {

            if (! exists $attribHash{$attrib}) {

                $attribHash{$attrib} = $modelObj->ivShow('optionalAttribHash', $attrib);
                $optionalAttribHash{$attrib}
                    = $modelObj->ivShow('optionalAttribHash', $attrib);
            }
        }

        # Decide what name to assign to the trigger
        if (defined $attribHash{'name'}) {

            # Use the name specified by the user, but only use the first 32 characters
            if (length $attribHash{'name'} > 32) {

                $attribHash{'name'} = substr($attribHash{'name'}, 0, 32);
            }

            $newObjName = $attribHash{'name'};

        } else {

            # Otherwise, use the ->stimulus as the name

            # We have a problem, for example in an alias with a stimulus (pattern) '^myalias$'
            # The user can't type ';deletealias ^myalias$' because doing that will cause the
            #   pattern to be replaced by its substitution, before Axmud can react to the command
            # The solution is to change the pattern a little, before using it as the name. If it
            #   contains any alphanumeric characters, remove them; otherwise introduce an
            #   underline at the beginning of the stimulus to distinguish it from its name
            $proposedName
                = $newObjName
                = $attribHash{'stimulus'};

            # Remove non-alphanumeric characters (first transforming whitespaces to underlines)
            $newObjName =~ s/\s/_/g;
            $newObjName =~ s/\W//g;
            # Remove any initial underline characters, and replace duplicate underline characters
            #   with a single one
            $newObjName =~ s/^\_+//;
            $newObjName =~ s/\_+/_/g;
            if ($proposedName eq $newObjName) {

                # The proposed name didn't include any non-alphanumeric characters, so give it a
                #   generic name
                $newObjName = $category . '_' . $proposedName;
            }

            # Don't allow the creation of automatic names which are very long
            if (length $newObjName > 32) {

                $newObjName = substr($newObjName, 0, 32);
            }

            $attribHash{'name'} = $newObjName;
        }

        # If the 'enabled' attribute wasn't specified in the client command, set it now
        if (! exists $attribHash{'enabled'}) {

            $attribHash{'enabled'} = TRUE;  # Interface enabled by default

        } else {

            # Convert values like '1', 't', 'True' to TRUE, and convert values like '0',
            #   'f', 'False' to FALSE
            $attribHash{'enabled'} = $self->convertTrueFalse($attribHash{'enabled'});
        }

        # Check the validity of the stimulus/response values. Create a dummy interface so that we
        #   can check its ->checkAttribValue method, which may modify the values (a little)
        $package = 'Games::Axmud::Interface::' . ucfirst($category);
        $dummyObj = $package->new($session, 'test', 'test', 'test', 1);

        $newStimulus = $dummyObj->checkAttribValue(
            $session,
            'stimulus',
            $attribHash{'stimulus'},
            $modelObj->ivShow('attribTypeHash', 'stimulus'),
        );

        if (! defined $newStimulus) {

            return $self->error(
                $session, $inputString,
                'Can\'t create interface - invalid stimulus \'' . $attribHash{'stimulus'}
                . '\' (should be type \'' . $modelObj->ivShow('attribTypeHash', 'stimulus')
                . '\')',
            );

        } else {

             $attribHash{'stimulus'} = $newStimulus;
        }

        $newResponse = $dummyObj->checkAttribValue(
            $session,
            'response',
            $attribHash{'response'},
            $modelObj->ivShow('attribTypeHash', 'response'),
        );

        if (! defined $newResponse) {

            return $self->error(
                $session, $inputString,
                'Can\'t create interface - invalid response \'' . $attribHash{'response'}
                . '\' (should be type \'' . $modelObj->ivShow('attribTypeHash', 'response')
                . '\')',
            );

        } else {

             $attribHash{'response'} = $newResponse;
        }

        # Find the cage matching the specified profile
        $cage = $session->findCage($category, $profName);
        if (! $cage) {

            return $self->error(
                $session, $inputString,
                'Can\'t create interface because the ' . $category . ' cage for \'' . $profName
                . '\' is missing',
            );
        }

        # Check that the cage doesn't already have a trigger with the same name
        if ($cage->ivExists('interfaceHash', $newObjName)) {

            return $self->error(
                $session, $inputString,
                'Can\'t create interface because the ' . $category . ' cage already has an'
                . ' interface with the name \'' . $newObjName .'\'',
            );
        }

        # Create the interface object
        $newObj = $package->new(
            $session,
            $attribHash{'name'},
            $attribHash{'stimulus'},
            $attribHash{'response'},
            $attribHash{'enabled'},
        );

        if (! $newObj) {

            return $self->error(
                $session, $inputString,
                'General error creating the interface object',
            );

        } else {

            # Set the interface object's attributes
            if (%optionalAttribHash) {

                $result = $newObj->set_attribHash($session, %optionalAttribHash);
                if (! $result) {

                    return $self->error(
                        $session, $inputString,
                        'Invalid attribute',
                    );
                }
            }

            # Set the interface object's before and after hashes
            if (%beforeHash || %afterHash) {

                $result = $newObj->set_beforeAfterHashes($session, \%beforeHash, \%afterHash);
                if (! $result) {

                    return $self->error(
                        $session, $inputString,
                        'Invalid before/after interfaces',
                    );
                }
            }
        }

        # Tell the trigger cage that it has received a new trigger
        $cage->ivAdd('interfaceHash', $newObj->name, $newObj);

        # Get a list of profiles with higher priority than this one
        @superiorList = $session->findSuperiorList($profCategory);
        # Get a list of profiles with lower priority than this one
        @inferiorList = $session->findInferiorList($profCategory);

        # Check whether there are any triggers with the same name, belonging to a cage associated
        #   with a superior profile to this cage's profile. If none, create an interface for the
        #   trigger
        # Also, if there is a trigger, with the same name but belonging to a cage associated with an
        #   inferior profile to this cage's profile, destroy its interface
        # As a result, there should be exactly one interface for a trigger with this name, no matter
        #   how many triggers with that name exist
        $result = $session->injectInterface(
            $newObj,
            $newObjName,
            $profName,
            \@superiorList,
            \@inferiorList,
        );

        if (! $result) {

            return $self->error(
                $session, $inputString,
                'General error creating ' . $category . ' \'' . $newObjName . '\'',
            );

        } elsif ($result == 1) {

            return $self->complete(
                $session, $standardCmd,
                'Active ' . $category . ' interface \'' . $newObjName . '\' created',
            );

        } else {

            return $self->complete(
                $session, $standardCmd,
                'Inactive ' . $category . ' interface \'' . $newObjName . '\' created',
            );
        }
    }

    sub modifyInterface {

        # Called by GA::Cmd::ModifyTrigger->do, ModifyAlias->do, ModifyMacro->do,
        #   ModifyTimer->do and ModifyHook->do
        # (For the whole of this function, 'trigger' is taken to mean any of 'trigger', 'alias',
        #   'macro', 'timer' or 'hook')
        #
        # This function modifies the attributes of an independent trigger stored in a trigger
        #   cage. If there's a corresponding active interface, it is also modified
        #
        # This function can also be called to modify an active interface directly, without
        #   changing the corresponding independent trigger stored in a trigger cage (if any)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'mtr -p pattern -a action'
        #   $standardCmd    - Standard version of the client command, e.g. 'modifytrigger'
        #   $category       - 'trigger', 'alias', 'macro', 'timer', 'hook'
        #   $categoryPlural - e.g. 'triggers'
        #   $modelObj       - The interface model object corresponding to $category
        #   @args           - The arguments specified by the user in the ';modifytrigger' command
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my (
            $self, $session, $inputString, $standardCmd, $category, $categoryPlural, $modelObj,
            @args,
        ) = @_;

        # Local variables
        my (
            $switch, $value, $attribCount, $profCount, $profCategory, $profName, $interface,
            $interfaceObj, $result, $currentObj, $currentObjName, $cage, $exitFlag, $name,
            %beforeHash, %afterHash, %beforeRemoveHash, %afterRemoveHash, %attribHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $category || ! defined $categoryPlural || ! defined $modelObj || ! @args
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->modifyInterface', @_);
        }

        # Extract group 4 (optional) switch options
        do {

            $exitFlag = TRUE;

            ($switch, $name, @args) = $self->extract('-b', 1, @args);
            if (defined $switch) {

                $exitFlag = FALSE;          # Allow the loop to repeat, looking for more -b switches

                if (! defined $name) {

                    return $self->error(
                        $session, $inputString,
                        ucfirst($category) . ' interface not created - missing name',
                    );

                } elsif (! exists $afterHash{$name}) {

                    # If the user specifies the same interface name twice (or more), it's only used
                    #   once. If the same name is specified with the -b and -f flags, it's only
                    #   added to the 'after' hash
                    $beforeHash{$name} = undef;
                }
            }

            ($switch, $name, @args) = $self->extract('-f', 1, @args);
            if (defined $switch) {

                $exitFlag = FALSE;          # Allow the loop to repeat, looking for more -f switches

                if (! defined $name) {

                    return $self->error(
                        $session, $inputString,
                        ucfirst($category) . ' interface not created - missing name',
                    );

                } else {

                    # If the user specifies the same interface name twice (or more), it's only used
                    #   once
                    $afterHash{$name} = undef;
                }
            }

            ($switch, $name, @args) = $self->extract('-y', 1, @args);
            if (defined $switch) {

                $exitFlag = FALSE;          # Allow the loop to repeat, looking for more -b switches

                if (! defined $name) {

                    return $self->error(
                        $session, $inputString,
                        ucfirst($category) . ' interface not created - missing name',
                    );

                } elsif (! exists $afterRemoveHash{$name}) {

                    # If the user specifies the same interface name twice (or more), it's only used
                    #   once. If the same name is specified with the -y and -z flags, it's only
                    #   added to the 'after' hash
                    $beforeRemoveHash{$name} = undef;
                }
            }

            ($switch, $name, @args) = $self->extract('-z', 1, @args);
            if (defined $switch) {

                $exitFlag = FALSE;          # Allow the loop to repeat, looking for more -f switches

                if (! defined $name) {

                    return $self->error(
                        $session, $inputString,
                        ucfirst($category) . ' interface not created - missing name',
                    );

                } else {

                    # If the user specifies the same interface name twice (or more), it's only used
                    #   once
                    $afterRemoveHash{$name} = undef;
                }
            }

        # Continue loop no more group 4 switches are found
        } until ($exitFlag);

        # Extract group 3 (optional) switch options
        foreach my $attrib ($modelObj->ivKeys('optionalSwitchHash')) {

            ($switch, $value, @args) = $self->extract(
                $modelObj->ivShow('optionalSwitchHash', $attrib),
                1,
                @args,
            );

            if (defined $switch) {

                if (! exists $attribHash{$attrib}) {

                    $attribCount++;
                    $attribHash{$attrib} = $value;

                } else {

                    # Optional switch patterns can't be specified more than once
                    return $self->error(
                        $session, $inputString,
                        ucfirst($category) . ' interface not modified - duplicate optional switch'
                        . ' patterns',
                    );
                }
            }
        }

        # Extract group 2 (compulsory) switch options
        foreach my $attrib ($modelObj->ivKeys('compulsorySwitchHash')) {

            ($switch, $value, @args) = $self->extract(
                $modelObj->ivShow('compulsorySwitchHash', $attrib),
                1,
                @args,
            );

            if (defined $switch) {

                if (! exists $attribHash{$attrib}) {

                    $attribCount++;
                    $attribHash{$attrib} = $value;

                } else {

                    # Compulsory switch options can't be specified more than once
                    return $self->error(
                        $session, $inputString,
                        ucfirst($category) . ' interface not modified - duplicate compulsory'
                        . ' switch options',
                    );
                }
            }
        }

        # Extract profile (group 1) switch options
        ($profCount, $profCategory, $profName, @args) = $self->extractProfileSwitches(
            $session,
            $inputString,
            $category,
            'modify',
            @args,
        );

        if (! defined $profCount) {

            # Error in ->extractProfileSwitches - error message already displayed
            return undef;
        }

        # Extract active interface (group 0) switch options
        ($switch, $interface, @args) = $self->extract('i', 1, @args);
        if (defined $switch) {

            if (! defined $interface) {

                return $self->error(
                    $session, $inputString,
                    'Missing switch arguments - use \'-i <name>\' or \'-i <number>\'',
                );

            } elsif (%beforeHash || %afterHash || %beforeRemoveHash || %afterRemoveHash) {

                return $self->error(
                    $session, $inputString,
                    'The switches -b, -y, -f and -z can\'t be used to modify active interfaces'
                    . ' (try \';moveactiveinterface\' instead)',
                );
            }
        }

        # At least one group 2 (compulsory) or group 3 (optional) switch options must be present
        if (! $attribCount) {

            return $self->error(
                $session, $inputString,
                'Can\'t modify ' . $category . ' interface - no attributes specified',
            );
        }

        # ;modifytrigger (etc) can't be used to modify the 'name' attribute
        if (exists $attribHash{'name'}) {

            return $self->error(
                $session, $inputString,
                'Can\'t modify active ' . $category . ' interface - the \'name\' attribute'
                . ' can\'t be modified',
            );
        }

        # For macros, the stimulus can be one of Axmud's standard keycodes (like 'F5') or a keycode
        #   string (like 'shift f5').
        # Keycodes in a keycode string must be in a given order (i.e. 'ctrl shift f5', not
        #   'shift ctrl f5' or even 'f5 shift ctrl'). Change the order of words in the keycode
        #   string, if necessary
        if ($category eq 'macro' && exists $attribHash{'stimulus'}) {

            $attribHash{'stimulus'} = $axmud::CLIENT->convertKeycodeString($attribHash{'stimulus'});
        }

        # Now, if the group 0 '-i' switch was specified, modify only the active interface - don't
        #   modify the corresponding parent interface (the one stored in a cage)
        if (defined $interface) {

            # @args should now be empty. If not, return an error message
            if (@args) {

                return $self->improper($session, $inputString);
            }

            # Group 0 and 1 switches can't be combined
            if ($profCount) {

                return $self->error(
                    $session, $inputString,
                    'Can\'t modify active ' . $category . ' interface - can\'t combine the -i'
                    . ' switch with -w, -g, -r, -c, -x or -d',
                );
            }

            # If the -i switch was specified, and the user also specified a trigger name using the
            #   -n switch, it's an error (this command mustn't be used to modify the interface name)
            if (exists $attribHash{'name'}) {

                return $self->error(
                    $session, $inputString,
                    'The ' . $category . ' interface\'s name can\'t be modified, once it is'
                    . ' made active',
                );
            }

            # Check that the specified interface exists
            if (
                ! $session->ivExists('interfaceHash', $interface)
                && ! $session->ivExists('interfaceNumHash', $interface)
            ) {
                return $self->error(
                    $session, $inputString,
                    'Unrecognised active ' . $category . ' interface \'' . $interface . '\'',
                );
            }

            # If $interface is a number, convert it into an interface name
            if ($session->ivExists('interfaceNumHash', $interface)) {

                $interface = $session->ivShow('interfaceNumHash', $interface)->name;
            }

            $interfaceObj = $session->ivShow('interfaceHash', $interface);

            # Modify the interface
            $result = $interfaceObj->modifyAttribs($session, %attribHash);
            if (! $result) {

                return $self->error(
                    $session, $inputString,
                    'General error modifying active ' . $category . ' interface \''
                    . $interface . '\'',
                );

            } else {

                return $self->complete(
                    $session, $standardCmd,
                    'Active ' . $category . ' interface \'' . $interface . '\' modified (but'
                    . ' the corresponding cage interface, if any, was not modified)',
                );
            }

        # Otherwise, if a group 1 switch was specified, modify the specified interface stored in the
        #   cage. If there's a corresponding active interface, modify that, too
        } else {

            # 0 or 1 associated profiles can be specified, but no more
            if ($profCount > 1) {

                return $self->error(
                    $session, $inputString,
                    'Can\'t modify an interface associated with multiple profiles - choose one from'
                    . ' -w, -g, -r, -c, -x, -d (or a named profile)',
                );

            # If no associatied profile specified, and the -i switch wasn't used, use the current
            #   world as the associated profile
            } elsif ($profCount == 0) {

                $profCount++;
                $profCategory = 'world';
                $profName = $session->currentWorld->name;
            }

            # @args should now contain a single element, <name>. Check it exists
            if (@args > 1) {

                return $self->improper($session, $inputString);

            } elsif (! @args) {

                return $self->error(
                    $session, $inputString,
                    'Please specify the name of the ' . $category . ' interface to modify (or'
                    . ' use \'-i <name>\' or \'-i <number>\'',
                );

            } else {

                $currentObjName = $args[0];
            }

            # Find the cage matching the specified profile
            $cage = $session->findCage($category, $profName);
            if (! $cage) {

                return $self->error(
                    $inputString,
                    'Can\'t modify ' . $category . ' interface because the ' . $category
                    . ' cage for \'' . $profName . '\' is missing',
                );
            }

            # Check that the cage has a trigger with this name
            if (! $cage->ivExists('interfaceHash', $currentObjName)) {

                if ($category eq 'alias') {

                    return $self->error(
                        $session, $inputString,
                        'Can\'t modify alias interface because the alias cage doesn\'t'
                        . 'have an alias with the name \'' . $currentObjName
                        . '\'',
                    );

                } else {

                    return $self->error(
                        $session, $inputString,
                        'Can\'t modify ' . $category . ' interface because the ' . $category
                        . ' cage doesn\'t have a ' . $category . ' with the name \''
                        . $currentObjName .'\'',
                    );
                }

            } else {

                # Get the blessed reference of the trigger object (but don't consult inferior cages)
                $currentObj = $cage->ivShow('interfaceHash', $currentObjName);
                if (! $currentObj) {

                    return $self->error(
                        $session, $inputString,
                        'General error modifying the ' . $category . ' interface object \''
                        . $currentObjName . '\'',
                    );
                }
            }

            # Modify any of the attributes that were specified
            if (%attribHash) {

                $result = $currentObj->modifyAttribs($session, %attribHash);
                if (! $result) {

                    return $self->complete(
                        $session, $inputString,
                        'Failed to modify the ' . $category . ' interface \''
                        . $currentObj->name . '\'',
                    );
                }
            }

            # Modify the before/after hashes, if specified
            if (%beforeHash || %afterHash || %beforeRemoveHash || %afterRemoveHash) {

                $result = $currentObj->set_beforeAfterHashes(
                    $session,
                    \%beforeHash, \%afterHash,
                    \%beforeRemoveHash, \%afterRemoveHash,
                );

                if (! $result) {

                    return $self->error(
                        $session, $inputString,
                        'Failed to modify the ' . $category . ' interface \''
                        . $currentObj->name . '\'',
                    );
                }
            }

            # If there's an active interface based upon this interface object, we need to update the
            #   active interface, too. We must do this in every session that shares the same world

            # Do the update in every affected session, except this one
            foreach my $otherSession ($axmud::CLIENT->listSessions()) {

                if (
                    $otherSession->currentWorld eq $session->currentWorld
                    && $otherSession ne $self
                ) {
                    $otherSession->updateInterfaces($currentObj, %attribHash);
                }
            }

            # Now apply to this session
            if (! $session->updateInterfaces($currentObj, %attribHash)) {

                return $self->complete(
                    $session, $standardCmd,
                    ucfirst($category) . ' interface \'' . $currentObj->name . '\' modified, but'
                    . ' but general error while modifying the corresponding active interface(s)',
                );

            } else {

                # There is no active interface based on this trigger (etc)
                return $self->complete(
                    $session, $standardCmd,
                    'Inactive ' . $category . ' interface \'' . $currentObjName . '\' modified',
                );
            }
        }
    }

    sub deleteInterface {

        # Called by GA::Cmd::DeleteTrigger->do, DeleteAlias->do, DeleteMacro->do,
        #   DeleteTimer->do and DeleteHook->do
        # (For the whole of this function, 'trigger' is taken to mean any of 'trigger', 'alias',
        #   'macro', 'timer' or 'hook')
        #
        # This function deletes an independent trigger stored in a trigger cage. If there's a
        #   corresponding active interface, it is also deleted
        #
        # This function can also be called to delete an active interface directly, without
        #   deleting the corresponding independent trigger stored in a trigger cage (if any)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'dtr mytrig'
        #   $standardCmd    - Standard version of the client command, e.g. 'deletetrigger'
        #   $category       - 'trigger', 'alias', 'macro', 'timer', 'hook'
        #   $categoryPlural - e.g. 'triggers'
        #   @args           - The arguments specified by the user in the ';deletetrigger' command
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my (
            $self, $session, $inputString, $standardCmd, $category, $categoryPlural,
            @args,
        ) = @_;

        # Local variables
        my (
            $profCount, $profCategory, $profName, $currentObj, $currentObjName, $cage, $result,
            @inferiorList
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $category || ! defined $categoryPlural || ! @args
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteInterface', @_);
        }

        # Extract profile (group 1) switch option
        ($profCount, $profCategory, $profName, @args) = $self->extractProfileSwitches(
            $session,
            $inputString,
            $category,
            'delete',
            @args,
        );

        if (! defined $profCount) {

            # Error in ->extractProfileSwitches()
            return undef;

        # 0 or 1 associated profiles can be specified, but no more
        } elsif ($profCount > 1) {

            return $self->error(
                $session, $inputString,
                'Can\'t delete an interface associated with multiple profiles - choose one from'
                . ' -w, -g, -r, -c, -x, -d (or a named profile)',
            );

        # If no associatied profile specified, use the current world as the associated profile
        } elsif ($profCount == 0) {

            $profCount++;
            $profCategory = 'world';
            $profName = $session->currentWorld->name;
        }

        # @args should now contain a single element, <name>. Check it exists
        if (@args > 1) {

            return $self->improper($session, $inputString);

        } elsif (! @args) {

            return $self->error(
                $session, $inputString,
                'Please specify the name of the ' . $category . ' interface to delete',
            );

        } else {

            $currentObjName = $args[0];
        }

        # Find the cage matching the specified profile
        $cage = $session->findCage($category, $profName);
        if (! $cage) {

            return $self->error(
                $inputString,
                'Can\'t delete ' . $category . ' interface because the ' . $category
                . ' cage for \'' . $profName . '\' is missing',
            );
        }

        # Check that the cage has a trigger with this name
        if (! $cage->ivExists('interfaceHash', $currentObjName)) {

            if ($category eq 'alias') {

                return $self->error(
                    $session, $inputString,
                    'Can\'t delete alias interface because the alias cage doesn\'t have an alias'
                    . ' with the name \'' . $currentObjName . '\'',
                );

            } else {

                return $self->error(
                    $session, $inputString,
                    'Can\'t delete ' . $category . ' interface because the ' . $category
                    . ' cage doesn\'t have a ' . $category . ' with the name \'' . $currentObjName
                    . '\'',
                );
            }

        } else {

            # Get the blessed reference of the trigger object (but don't consult inferior cages)
            $currentObj = $cage->ivShow('interfaceHash', $currentObjName);
            if (! $currentObj) {

                return $self->error(
                    $session, $inputString,
                    'General error deleting the ' . $category . ' interface object \''
                    . $currentObjName . '\'',
                );
            }
        }

        # Delete the interface object
        $cage->ivDelete('interfaceHash', $currentObjName);

        # Get a list of profiles with lower priority than this one
        @inferiorList = $session->findInferiorList($profCategory);

        # If there's an active interface based on this trigger object, delete it also. At the
        #   same time, if there's a trigger with the same name, belonging to an inferior
        #   cage, create an interface for it to make it active
        $result = $session->recallInterface($currentObj, $currentObjName, \@inferiorList);

        if (! $result || $result == 1) {

            return $self->error(
                $session, $inputString,
                'General error deleting ' . $category . ' interface',
            );

        } elsif ($result == 2) {

            return $self->error(
                $session, $inputString,
                'Deleted ' . $category . ' interface, but couldn\'t create interface for a '
                . $category . ' belonging to an inferior profile',
            );

        } elsif ($result == 3) {

            return $self->complete(
                $session, $standardCmd,
                'Active ' . $category . ' interface \'' . $currentObjName . '\' deleted and'
                . ' interface created for a ' . $category . ' belonging to an inferior profile',
            );

        } elsif ($result == 4) {

            return $self->complete(
                $session, $standardCmd,
                'Active ' . $category . ' interface \'' . $currentObjName . '\' deleted (and'
                . ' no other interface created to replace it)',
            );
        }
    }

    sub listInterface {

        # Called by GA::Cmd::ListTrigger->do, ListAlias->do, ListMacro->do, ListTimer->do and
        #   ListHook->do
        # (For the whole of this function, 'trigger' is taken to mean any of 'trigger', 'alias',
        #   'macro', 'timer' or 'hook')
        #
        # Lists triggers stored in a trigger cage, or lists active triggers
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - The command actually typed, e.g. 'ltr -w'
        #   $standardCmd    - Standard version of the client command, e.g. 'listtrigger'
        #   $category       - 'trigger', 'alias', 'macro', 'timer', 'hook'
        #   $categoryPlural - e.g. 'triggers'
        #
        # Optional arguments
        #   @args           - The arguments specified by the user in the ';listtrigger' command
        #                       (an empty list if none specified)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 on success

        my (
            $self, $session, $inputString, $standardCmd, $category, $categoryPlural,
            @args,
        ) = @_;

        # Local variables
        my (
            $switch, $arg, $profObj, $owner, $cage, $string,
            @list,
            %hash, %modifiedHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $category || ! defined $categoryPlural
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->listInterface', @_);
        }

        # Extract the optional switch and argument
        $switch = shift @args;
        $arg = shift @args;
        # There should be no arguments left
        if (
            @args
            || (
                defined $switch && $switch ne '-w' && $switch ne '-g' && $switch ne '-r'
                && $switch ne '-c' && $switch ne '-x' && $switch ne '-d' && $switch ne '-i'
            )
        ) {
            return $self->improper($session, $inputString);
        }

        # ;ltr
        # ;ltr -w , ;ltr -g , ;ltr -r , ;ltr -c
        # ;ltr -x <category>
        # ;ltr -d <profile>
        #   (etc)
        if (! defined $switch || $switch ne '-i') {

            # ;ltr
            # ;ltr -w
            if (! $switch || $switch eq '-w') {

                $owner = $session->currentWorld->name;
                $cage = $session->findCurrentCage($category, 'world');

            } elsif ($switch eq '-g') {

                if (! defined $session->currentGuild) {

                    return $self->error(
                        $session, $inputString,
                        'Can\'t list ' . $categoryPlural . ' for the current guild - no current'
                        . ' guild set',
                    );

                } else {

                    $owner = $session->currentGuild->name;
                    $cage = $session->findCurrentCage($category, 'guild');
                }

            } elsif ($switch eq '-r') {

                if (! defined $session->currentRace) {

                    return $self->error(
                        $session, $inputString,
                        'Can\'t list ' . $categoryPlural . ' for the current race - no current'
                        . ' race set',
                    );

                } else {

                    $owner = $session->currentRace->name;
                    $cage = $session->findCurrentCage($category, 'race');
                }

            } elsif ($switch eq '-c') {

                if (! defined $session->currentChar) {

                    return $self->error(
                        $session, $inputString,
                        'Can\'t list ' . $categoryPlural . ' for the current character - no current'
                        . ' character set',
                    );

                } else {

                    $owner = $session->currentChar->name;
                    $cage = $session->findCurrentCage($category, 'char');
                }

            } elsif ($switch eq '-x') {

                if (! defined $arg) {

                    return $self->error(
                        $session, $inputString,
                        'List ' . $categoryPlural . ' for which category of custom profile?',
                    );

                } elsif (! $session->ivExists('templateHash', $arg)) {

                    return $self->error(
                        $session, $inputString,
                        'Unrecognised custom profile category \'' . $arg . '\'',
                    );

                } elsif (! $session->ivExists('currentProfHash', $arg)) {

                    return $self->error(
                        $session, $inputString,
                        'Can\'t list ' . $categoryPlural . ' for the current ' . $arg
                        . ' custom profile - no current profile set',
                    );

                } else {

                    $profObj = $session->ivShow('currentProfHash', $arg);
                    $owner = $profObj->name;
                    $cage = $session->findCurrentCage($category, $owner);
                }

            } elsif ($switch eq '-d') {

                if (! defined $arg) {

                    return $self->error(
                        $session, $inputString,
                        'List ' . $categoryPlural . ' for which profile?',
                    );

                } elsif (! $session->ivExists('profHash', $arg)) {

                    return $self->error(
                        $session, $inputString,
                        'Unrecognised profile \'' . $arg . '\'',
                    );

                } else {

                    $owner = $arg;
                    $cage = $session->findCage($category, $owner);
                }
            }

            if ($cage) {

                # Import the cage's hash of interface objects
                %hash = $cage->interfaceHash;
            }

            # Check there is something to display
            @list = sort {lc($hash{$a}) cmp lc($hash{$b})} (keys %hash);
            if (! @list) {

                return $self->complete($session, $standardCmd, 'The specified list is empty');
            }

            # Display header
            $session->writeText(
                'Independent ' . $category . ' list for \'' . $owner . '\' (* = Active'
                . ' E = Enabled)',
            );

                $string = 'Stimulus (pattern)       Response (action)';


            if ($category eq 'trigger') {
                $string = 'Stimulus (pattern)       Response (instruction, rewriter: substitution)';
            } elsif ($category eq 'alias') {
                $string = 'Stimulus (pattern)       Response (substitution)';
            } elsif ($category eq 'macro') {
                $string = 'Stimulus (key)           Response (instruction)';
            } elsif ($category eq 'timer') {
                $string = 'Stimulus (interval)      Response (instruction)';
            } elsif ($category eq 'hook') {
                $string = 'Stimulus (hook event)    Response (instruction)';
            }

            $session->writeText('   Name                             ' . $string);

            # Display list
            foreach my $name (@list) {

                my ($obj, $column);

                $obj = $hash{$name};

                if (
                    $session->ivExists('interfaceHash', $name)
                    && $session->ivShow('interfaceHash', $name) eq $obj
                ) {
                    $column = '*';      # Active trigger (etc)
                } else {
                    $column = '*';      # Inactive trigger (etc)
                }

                if ($obj->enabledFlag) {
                    $column .= 'E ';    # Enabled
                } else {
                    $column .= '  ';    # Disabled
                }

                $session->writeText(
                    $column . sprintf(
                        '%-32.32s %-24.24s %-24.24s',
                        $name,
                        $obj->stimulus,     # Shortened to fit
                        $obj->response,     # Shortened to fit
                    )
                );
            }

        # ;ltr -i
        #   (etc)
        } else {

            # Import the interface registry for the session
            %hash = $session->interfaceHash;

            # Compile a hash of active trigger (etc) interfaces
            foreach my $name (keys %hash) {

                my $obj = $hash{$name};

                if ($obj->category eq $category) {

                    $modifiedHash{$name} = $obj;
                }
            }

            # Display header
            $session->writeText(
                'Active ' . $category . ' interface list (I = independent, D = dependent)',
            );

            # Display list
            @list = sort {lc($modifiedHash{$a}) cmp lc($modifiedHash{$b})} (keys %modifiedHash);
            foreach my $name (@list) {

                my ($obj, $column);

                $obj = $modifiedHash{$name};

                if ($obj->indepFlag) {
                    $column = ' I ';   # Independent trigger (etc)
                } else {
                    $column = ' D ';   # Dependent trigger (etc)
                }

                $session->writeText(
                    $column . sprintf('Name: %-32.32s', $name) . ' (# ' . $obj->number . ')',
                );

                if (length ($obj->stimulus) > 64) {
                    $session->writeText(sprintf ('      Stimulus: %-64.64s...', $obj->stimulus));
                } else {
                    $session->writeText('      Stimulus: ' . $obj->stimulus);
                }

                if (length ($obj->response) > 64) {
                    $session->writeText(sprintf ('      Response: %-64.64s...', $obj->response));
                } else {
                    $session->writeText('      Response: ' . $obj->response);
                }

                if (! $obj->indepFlag) {

                    $string = ref($obj->callClass) . '->' . $obj->callMethod;
                    if (length $string > 64) {
                        $session->writeText(sprintf ('      Method:   %-64.64s...', $string));
                    } else {
                        $session->writeText('      Method:   ' . $string);
                    }
                }
            }
        }

        # Display footer
        if (@list == 1) {

            return $self->complete(
                $session, $standardCmd,
                   'End of list (1 ' . $category . ' interface found)',
            );

        } else {

            return $self->complete(
                $session, $standardCmd,
                'End of list (' . scalar @list . ' ' . $category . ' interfaces found)',
            );
        }
    }

    sub addRecordingString {

        # Called by GA::Cmd::WorldCommand->do, ClientCommand->do, Comment->do, Break->do
        # Adds a new string to the current recording
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $string     - The string to add
        #
        # Return values
        #   'undef' on improper arguments or if there is no current recording for the specified
        #       session
        #   1 otherwise

        my ($self, $session, $string, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRecordingString', @_);
        }

        # Check there is a current recording (should already have been checked, but let's be
        #   thorough)
        if (! $session->recordingFlag) {

            return undef;
        }

        # If there's a defined insertion point, insert the string there
        if (
            defined $session->recordingPosn
            && $session->recordingPosn <= scalar $session->recordingList
        ) {
            # Insert the command at the insertion point
            $session->ivSplice(
                'recordingList',
                $session->recordingPosn,
                0,
                $string,
            );

            # The new insertion point is the line after this one
            $session->ivIncrement('recordingPosn');

        } else {

            # No insertion point specified, or the insertion point is at a line number that's bigger
            #   than the size of the recording, so $string must be added to the end of the
            #   recording
            $session->ivPush('recordingList', $string);
            # In case $self->recordingPosn was outside the list, make sure future commands are
            #   just added to the end of the list
            $session->ivUndef('recordingPosn');
        }

        return 1;
    }

    sub useRoute {

        # Called by GA::Cmd::Drive->do, Road->do and Quick->do
        # Moves between one tagged room and another using pre-defined routes
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString, $standardCmd
        #                   - Standard arguments for a call to a GA::Cmd::XXX->do
        #   $start          - The room tag of the initial room
        #   $stop           - The room tag of the target room
        #   $routeType      - Which kind of routes to use - 'road', 'quick' or 'both'
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 otherwise

        my ($self, $session, $inputString, $standardCmd, $start, $stop, $routeType, $check) = @_;

        # Local variables
        my ($routeString, $routeObj, $cmdListRef, $cmdSequence, $cmdCount);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $start || ! defined $stop || ! defined $routeType || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->useRoute', @_);
        }

        # Use this string for messages including the route type
        if ($routeType eq 'road' || $routeType eq 'quick') {
            $routeString = ' ' . $routeType;
        } else {
            $routeString = '';
        }

        # Look for a route object between the two tagged rooms. Start searching in the highest-
        #   priority route cage
        OUTER: foreach my $category ($session->profPriorityList) {

            my $cage = $session->findCurrentCage('route', $category);
            if ($cage) {

                # Route objects are stored in the route cage's ->routeHash IV. Keys are in the form
                #   r_start-room-tag@@@stop-room-tag (for road routes)
                #   q_start-room-tag@@@stop-room-tag (for quick routes)

                # Find the route from this cage, or from inferior cages (if necessary). If the
                #   calling function specified both road routes and quick routes, find road routes
                #   first
                if ($routeType ne 'quick') {

                    $routeObj = $cage->ivShow(
                        'routeHash',
                        'r_' . $start . '@@@' . $stop,
                        $session,                           # Consult inferior cages
                    );
                }

                if (! $routeObj) {

                    $routeObj = $cage->ivShow(
                        'routeHash',
                        'q_' . $start . '@@@' . $stop,
                        $session,                           # Consult inferior cages
                    );
                }

                last OUTER;
            }
        }

        # If there is no pre-defined route between <start> and <stop>...
        if (! $routeObj) {

            # Try to work out the shortest path between the two rooms, using only the network of
            #   interlinked GA::Obj::Route objects
            $cmdListRef = $session->worldModelObj->findRoutePath(
                $session,
                $start,
                $stop,
                $routeType,
            );

            if (! defined $cmdListRef || ! @$cmdListRef) {

                return $self->error(
                    $session, $inputString,
                    'No' . $routeString . ' route between \'' . $start . '\' and \'' . $stop
                    . '\' found',
                );

            } else {

                # Use this route
                $cmdSequence = join($axmud::CLIENT->cmdSep, @$cmdListRef);
                $cmdCount = scalar @$cmdListRef;
            }

        } else {

            # Use the pre-defined route
            $cmdSequence = $routeObj->route;
            $cmdCount = $routeObj->stepCount;
        }

        # Final check that we really have found a route
        if (! $cmdSequence) {

            return $self->error(
                $session, $inputString,
                   'General error processing the route between \'' . $start . '\' and \'' . $stop
                   . '\'',
            );
        }

        # If the Locator task is running, tell it about the target room's tag
        if ($session->locatorTask) {

            $session->locatorTask->set_arrivalTag($stop);
        }

        # Take the route
        $session->worldCmd($cmdSequence);

        if ($cmdCount == 1) {

            return $self->complete(
                $session, $standardCmd,
                'Taking' . $routeString . ' route from \'' . $start . '\' to \'' . $stop
                . '\' (in 1 step)',
            );

        } else {

            return $self->complete(
                $session, $standardCmd,
                'Taking' . $routeString . ' route from \'' . $start . '\' to \'' . $stop . '\' (in '
                . $cmdCount . ' steps)',
            );
        }
     }

    sub autoQuit {

        # Called by GA::Cmd::Quit->do, QQuit->do and QuitAll->do
        # Sends a standard 'quit' world command, sends a sequence of world commands, runs a task,
        #   runs an Axbasic script or starts a mission, depending on the value of
        #   GA::Profile::World->autoQuitMode
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString, $standardCmd
        #                   - Standard arguments for a call to a GA::Cmd::XXX->do
        #   $simpleMsg      - Success message to use in auto-quit mode 'normal'
        #   $initiateMsg    - Success message to use in all other auto-quit modes
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 otherwise

        my ($self, $session, $inputString, $standardCmd, $simpleMsg, $initiateMsg, $check) = @_;

        # Local variables
        my (
            $name, $initFailMsg, $result, $failMsg, $packageName, $rawScriptObj, $path, $taskObj,
            $missionObj, $scriptObj,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $simpleMsg || ! defined $initiateMsg || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->autoQuit', @_);
        }

        # Import one IV for convenience
        $name =  $session->currentWorld->autoQuitObjName;
        # Standard failure message
        $initFailMsg = 'Could not initiate auto-quit sequence - ';

        # Mode 'world_cmd' - Send a sequence of world commands
        if (
            $session->currentWorld->autoQuitMode eq 'world_cmd'
            && $session->currentWorld->autoQuitCmdList
        ) {
            $result = $self->complete($session, $standardCmd, $initiateMsg);

            foreach my $cmd ($session->currentWorld->autoQuitCmdList) {

                $session->worldCmd($cmd);
            }

            return $result;

        # Mode 'task' - Run a task (the task is responsible for sending a 'quit' world command)
        } elsif ($session->currentWorld->autoQuitMode eq 'task' && $name) {

            # $self->findTaskPackageName recognises unique names of currently running tasks (e.g.
            #   'status_task_57'), so before we consult it, check that $name isn't already running
            if ($session->ivExists('currentTaskHash', $name)) {

                $failMsg
                    = $initFailMsg . '\'' . $name . '\' isn\'t a valid task name or task label';

            } else {

                # Get the task's package name (e.g. 'Games::Axmud::Task::Status')
                $packageName = Games::Axmud::Generic::Cmd->findTaskPackageName($session, $name);
                if (! $packageName) {

                    $failMsg = $initFailMsg . 'could not start the task \'' . $name . '\'';

                } else {

                    # Create the task object
                    $packageName->new($session, 'current');
                }
            }

            if ($failMsg) {
                return $self->error($session, $inputString, $failMsg);
            } else {
                return $self->complete($session, $standardCmd, $initiateMsg);
            }

        # Mode 'task_script' - Run an Axbasic script from within a task (the script is responsible
        #   for sending a 'quit' world command)
        } elsif ($session->currentWorld->autoQuitMode eq 'task_script' && $name) {

            # We need to check that the file containing the script exists, because the Script task
            #   won't pass us a convenient error return value. Create a dummy raw script to do it
            $rawScriptObj = Language::Axbasic::RawScript->new($session, $name);
            if (! $rawScriptObj) {

                $failMsg = $initFailMsg . 'could not run the ' . $axmud::BASIC_NAME . ' script \''
                            . $name . '\'';

            } else {

                # Load the script into the raw script object
                $path = $axmud::DATA_DIR . '/scripts/' . $name . '.bas';
                if (! $rawScriptObj->loadFile($path)) {

                    $failMsg = $initFailMsg . 'could not load the ' . $axmud::BASIC_NAME
                                    . ' script \'' . $name . '\'';

                } else {

                    # Create the task object
                    $taskObj = Games::Axmud::Task::Script->new($session, 'current');
                    if (! $taskObj) {

                        $failMsg = $initFailMsg . 'could not start a Script task running the'
                                        . ' ' . $axmud::BASIC_NAME . ' script \'' . $name . '\'';

                    } else {

                        # Tell it which script to execute
                        $taskObj->ivPoke('scriptName', $name);
                    }
                }
            }

            if ($failMsg) {
                return $self->error($session, $inputString, $failMsg);
            } else {
                return $self->complete($session, $standardCmd, $initiateMsg);
            }

        # Mode 'script' - Run an Axbasic script (the script is responsible for sending a 'quit'
        #   world command)
        } elsif ($session->currentWorld->autoQuitMode eq 'script' && $name) {

            # Create the raw script object
            $rawScriptObj = Language::Axbasic::RawScript->new($session, $name);
            if (! $rawScriptObj) {

                $failMsg = $initFailMsg . 'could not run the ' . $axmud::BASIC_NAME . ' script \''
                            . $name . '\'';

            } else {

                # Load the script into the raw script object
                $path = $axmud::DATA_DIR . '/scripts/' . $name . '.bas';
                if (! $rawScriptObj->loadFile($path)) {

                    $failMsg = $initFailMsg . 'could not load the ' . $axmud::BASIC_NAME
                                    . ' script \'' . $name . '\'';

                } else {

                    # Create a script object, which processes the raw script, removing extraneous
                    #   whitespace, empty lines, comments, etc
                    $scriptObj = Language::Axbasic::Script->new($session, $rawScriptObj);
                    if (! $scriptObj) {

                        $failMsg = $initFailMsg . 'could not run the ' . $axmud::BASIC_NAME
                                        . ' script \'' . $name . '\'';

                    } else {

                        # Execute the script
                        $scriptObj->implement();
                    }
                }
            }

            if ($failMsg) {
                return $self->error($session, $inputString, $failMsg);
            } else {
                return $self->complete($session, $standardCmd, $initiateMsg);
            }

        # Mode 'mission' - Start a mission (the mission is responsible for sending a 'quit' world
        #   command)
        } elsif ($session->currentWorld->autoQuitMode eq 'mission' && $name) {

            # If the mission exists...
            if (! $session->currentWorld->ivExists('missionHash', $name)) {

                $failMsg = $initFailMsg . 'the mission \'' . $name . '\' doesn\'t exist';

            } else {

                $missionObj = $session->currentWorld->ivShow('missionHash', $name);

                # If the world profile's ->loginSpecialList is set, make a local copy of the list
                $session->set_loginSpecialList($session->currentWorld->loginSpecialList);

                # Start the mission. The TRUE flag means to refrain from displaying confirmation
                #   messages
                if (! $missionObj->startMission(TRUE)) {

                    $failMsg = $initFailMsg . 'Could not start the mission \'' . $name . '\'';

                } else {

                    # Automatically send the first group of commands (as if ';mission' had been
                    #   typed by the user
                    $missionObj->continueMission($session);
                }
            }

            if ($failMsg) {
                return $self->error($session, $inputString, $failMsg);
            } else {
                return $self->complete($session, $standardCmd, $initiateMsg);
            }

        # Mode 0 - Send the standard 'quit' world command, as defined by the current
        #   highest-priority command cage
        # Modes 1-5 (if ->autoQuitCmdList or ->autoQuitObjName are required, but not set)
        } else {

            # Send the 'quit' command for this world
            $session->sendModCmd('quit');

            return $self->complete($session, $standardCmd, $simpleMsg);
        }
     }

    sub sortAttributes {

        # Called by GA::Cmd::Read->do, Switch->do and Alert->do (and also PermRead->do,
        #   PermSwitch->do, PermAlert->do
        # Returns a string containing a list of text-to-speech attributes, sorted by task
        #
        # Expected arguments
        #   $iv     - The GA::Client IV that stores the attributes to sort (e.g. ->ttsAttribHash)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the string

        my ($self, $iv, $check) = @_;

        # Local variables
        my (
            $string,
            %taskHash,
        );

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sortAttributes', @_);
        }

        foreach my $attrib ($axmud::CLIENT->ivKeys($iv)) {

            my ($task, $listRef);

            $task = $axmud::CLIENT->ivShow($iv, $attrib);

            if (! exists $taskHash{$task}) {

                $taskHash{$task} = [$attrib];

            } else {

                $listRef = $taskHash{$task};
                push (@$listRef, $attrib);
            }
        }

        foreach my $task (sort {lc($a) cmp lc($b)} (keys %taskHash)) {

            my ($listRef, $prettyTask);

            $listRef = $taskHash{$task};

            # (Convert 'locator_task' to 'Locator task')
            $prettyTask = ucfirst($task);
            $prettyTask =~ s/\_/ /;

            $string .= $prettyTask . ': ' . join(', ', sort {lc($a) cmp lc($b)} (@$listRef)) . '. ';
        }

        return $string;
     }

    sub getKeypadHashes {

        # Called by GA::Cmd::Compass->do, PermCompass->do
        # Defines two hashes, one of keypad keycodes that the Compass task allows the user to
        #   customise, and another of the keypad keycodes that the Compass task won't customise.
        #   Returns the hashes as hash references
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns two hash references

        my ($self, $check) = @_;

        # Local variables
        my (%hash, %otherHash);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getKeypadHashes', @_);
        }

        # Hash to convert all the <key>s that the Compass task allows us to customise
        %hash = (
            0               => 'kp_0',
            'zero'          => 'kp_0',
            'kp_0'          => 'kp_0',

            5               => 'kp_5',
            'five'          => 'kp_5',
            'kp_5'          => 'kp_5',

            '*'             => 'kp_multiply',
            'times'         => 'kp_multiply',
            'multiply'      => 'kp_multiply',
            'kp_multiply'   => 'kp_multiply',

            '/'             => 'kp_divide',
            'slash'         => 'kp_divide',
            'divide'        => 'kp_divide',
            'kp_divide'     => 'kp_divide',

            '.'             => 'kp_full_stop',
            'dot'           => 'kp_full_stop',
            'fullstop'      => 'kp_full_stop',
            'period'        => 'kp_full_stop',
            'kp_full_stop'  => 'kp_full_stop',

            'enter'         => 'kp_enter',
            'return'        => 'kp_enter',
            'kp_enter'      => 'kp_enter',
        );

        # Hash of other keypad <key>s that the Compass task doesn't allow us to customise
        %otherHash = (
            1               => '1',
            2               => '2',
            3               => '3',
            4               => '4',
            6               => '6',
            7               => '7',
            8               => '8',
            9               => '9',

            'one'           => '1',
            'two'           => '2',
            'three'         => '3',
            'four'          => '4',
            'six'           => '6',
            'seven'         => '7',
            'eight'         => '8',
            'nine'          => '9',

            'kp_1'          => '1',
            'kp_2'          => '2',
            'kp_3'          => '3',
            'kp_4'          => '4',
            'kp_6'          => '6',
            'kp_7'          => '7',
            'kp_8'          => '8',
            'kp_9'          => '9',

            '+'             => 'add',
            'plus'          => 'add',
            'add'           => 'add',
            'kp_add'        => 'add',

            '-'             => 'subtract',
            'minus'         => 'subtract',
            'subtract'      => 'subtract',
            'kp_subtract'   => 'subtract',
        );

        return (\%hash, \%otherHash);
     }

    sub updateCompass {

        # Called by GA::Cmd::PermCompass->do and WorldCompass->do
        # Applies changes to the IVs for a global initial task or the current world's initial task
        #
        # Expected arguments
        #   $session, $inputString, $standardCmd
        #                   - Standard arguments to a command's ->do function
        #   $argListRef     - Reference to the list of arguments supplied to the client command
        #                       (unmodified). The calling function has already checked there is at
        #                       least one argument
        #   $currentListRef - Reference to a list of current tasklist tasks (should contain 0 or 1
        #                       items)
        #   $initListRef    - Reference to a list of initial tasks (can contain any number of items,
        #                       including 0)
        #
        # Return values
        #   'undef' on improper arguments or failure
        #   1 on success

        my (
            $self, $session, $inputString, $standardCmd, $argListRef, $currentListRef, $initListRef,
            $check,
        ) = @_;

        # Local variables
        my (
            $hashRef, $otherHashRef, $count, $errorCount, $key, $keycode, $cmd,
            @args, @taskList, @initTaskList,
            %hash, %otherHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $argListRef || ! defined $currentListRef || ! defined $initListRef
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->updateCompass',
                @_,
            );
        }

        # Dereference the args
        @args = @$argListRef;
        @taskList = @$currentListRef;
        @initTaskList = @$initListRef;

        # %hash to convert all the <key>s that the Compass task allows us to customise
        # %otherHash of other keypad <key>s that the Compass task doesn't allow us to customise
        ($hashRef, $otherHashRef) = $self->getKeypadHashes();
        %hash = %$hashRef;
        %otherHash = %$otherHashRef;

        # Count successes and errors, to show in confirmation messages
        $count = 0;
        $errorCount = 0;

        # ;pcm on
        # ;pcm -o
        if ($args[0] eq 'on' || $args[0] eq '-o') {

            # (For the benefit of visually-impaired users, ignore everything after the first
            #   argument)
            foreach my $taskObj (@taskList) {

                if (! $taskObj->enable()) {
                    $errorCount++;
                } else {
                    $count++;
                }
            }

            foreach my $taskObj (@initTaskList) {

                $count++;
                $taskObj->set_enabledFlag(TRUE);
            }

            return $self->complete(
                $session, $standardCmd,
                'Compass tasks set to \'enabled\'. (Found tasks: ' . ($count + $errorCount)
                . ', errors: ' . $errorCount . ').',
            )

        # ;pcm off
        # ;pcm -f
        } elsif ($args[0] eq 'off' || $args[0] eq '-f') {

            foreach my $taskObj (@taskList) {

                if (! $taskObj->disable()) {
                    $errorCount++;
                } else {
                    $count++;
                }
            }

            foreach my $taskObj (@initTaskList) {

                $count++;
                $taskObj->set_enabledFlag(FALSE);
            }

            return $self->complete(
                $session, $standardCmd,
                'Compass tasks set to \'disabled\'. (Found tasks: ' . ($count + $errorCount)
                . ', errors: ' . $errorCount . ').',
            );

        # ;pcm <key> <command>
        # ;pcm <key>
        } elsif ($args[0]) {

            # Get the Axmud standard keycode
            $key = shift @args;
            if (! exists $hash{$key} && ! exists $otherHash{$key}) {

                return $self->error(
                    $session, $inputString,
                    'Unrecognised keypad key (try \';help compass\' for a list of recognised keys)',
                );

            } elsif (exists $otherHash{$key}) {

                return $self->error(
                    $session, $inputString,
                    'The Compass task doesn\'t allow us to customise the \'' . $otherHash{$key}
                    . '\' key',
                );

            } else {

                $keycode = $hash{$key};
            }

            # Set the corresponding world <command> (if one was specified)
            if (@args) {

                $cmd = join (' ', @args);
            }

            # Update the task(s)
            foreach my $taskObj (@taskList, @initTaskList) {

                if (! $taskObj->set_key($keycode, $cmd)) {
                    $errorCount++;
                } else {
                    $count++;
                }
            }

            return $self->complete(
                $session, $standardCmd,
                'Set a world command for the keypad key \'' . $key . '\'. (Found tasks: '
                . ($count + $errorCount) . ', errors: ' . $errorCount . ').',
            );
        }
    }

    sub killLimitedTargets {

        # Called by GA::Cmd::Kill->do and Kkill->do
        # Attacks a list of targets limited to the given arguments, e.g. ('orc') or ('orcs',
        #   'troll', 'bears'), but doesn't attack players
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - What the player actually typed (e.g. ';k orcs');
        #   $standardCmd    - The standard version of the command (i.e. 'kill')
        #   $multipleFlag   - Flag set to FALSE when called by ';kill' (e.g. attack a single orc),
        #                       set to TRUE when called by ';kkill' (e.g. attack all orcs at current
        #                       location)
        #   @targetList     - A list of target strings specified by the user, e.g. ('orcs', 'wolf')
        #
        # Return values
        #   'undef' on improper arguments or failure
        #   1 on success

        my ($self, $session, $inputString, $standardCmd, $multipleFlag, @targetList) = @_;

        # Local variables
        my @objList;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $multipleFlag
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->killLimitedTargets', @_);
        }

        # This command requires the Locator task to know the current location
        if (! $session->locatorTask) {

            return $self->error(
                $session, $inputString,
                'Cannot kill - Locator task isn\'t running',
            );

        } elsif (! $session->locatorTask->roomObj) {

            return $self->error(
                $session, $inputString,
                'Cannot kill - Locator task doesn\'t know the current location',
            );
        }

        if (! @targetList) {

            # Get the first target from the Locator's list of things in the current room
            @objList = $session->locatorTask->roomObj->tempObjList;
            if (! @objList) {

                return $self->complete(
                    $session, $standardCmd,
                    'Cannot kill - current location is empty',
                );

            } else {

                # Choose the first minion, sentient or creature in @objList
                OUTER: foreach my $obj (@objList) {

                    if (
                        $obj->aliveFlag
                        && (
                            ($obj->category eq 'minion' && ! $obj->ownMinionFlag)
                            || $obj->category eq 'sentient'
                            || $obj->category eq 'creature'
                        )
                    ) {
                        push (@targetList, $obj->noun);
                        last OUTER;
                    }
                }
            }

            # If no suitable objects were found, don't attack
            if (! @targetList) {

                return $self->complete(
                    $session, $standardCmd,
                    'Cannot kill - no enemy minions, sentients or creatures at the current'
                    . ' location',
                );
            }
        }

        # Attack the targets
        foreach my $target (@targetList) {

            $session->sendModCmd('kill', 'victim', $target);
        }

        if (scalar @targetList == 1) {

            return $self->complete($session, $standardCmd, 'Attacking 1 target');

        } else {

            return $self->complete(
                $session, $standardCmd,
                'Attacking ' . scalar @targetList . ' targets',
            );
        }
    }

    sub killUnlimitedTargets {

        # Called by GA::Cmd::KillAll->do and KillMall->do
        # Attacks all targets (or all non-player targets) at current location
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - What the player actually typed (e.g. ';ka');
        #   $standardCmd    - The standard version of the command (i.e. 'killall')
        #   $playerFlag     - Set to TRUE if player targets should be attacked too; FALSE if only
        #                       non-player targets should be attacked
        #
        # Return values
        #   'undef' on improper arguments or failure
        #   1 on success

        my ($self, $session, $inputString, $standardCmd, $playerFlag, $check) = @_;

        # Local variables
        my (@objList, @targetList);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $playerFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->killUnlimitedTargets', @_);
        }

        # This command requires the Locator task to know the current location
        if (! $session->locatorTask) {

            return $self->error(
                $session, $inputString,
                'Cannot kill - Locator task isn\'t running',
            );

        } elsif (! $session->locatorTask->roomObj) {

            return $self->error(
                $session, $inputString,
                'Cannot kill - Locator task doesn\'t know the current location',
            );
        }

        # Get a list of attackable targets from the Locator's list of things in the current room
        @objList = $session->locatorTask->roomObj->tempObjList;
        if (! @objList) {

            return $self->complete(
                $session, $standardCmd,
                'Cannot kill - current location is empty',
            );

        } else {

            foreach my $obj (@objList) {

                if (
                    $obj->aliveFlag
                    && (
                        ($playerFlag && $obj->category eq 'char')
                        || ($obj->category eq 'minion' && ! $obj->ownMinionFlag)
                        || $obj->category eq 'sentient'
                        || $obj->category eq 'creature'
                    )
                ) {
                    push (@targetList, $obj->noun);
                }
            }
        }

        # Attack the targets
        foreach my $target (@targetList) {

            $session->sendModCmd('kill', 'victim', $target);
        }

        if (scalar @targetList == 1) {

            return $self->complete($session, $standardCmd, 'Attacking 1 target');

        } else {

            return $self->complete(
                $session, $standardCmd,
                'Attacking ' . scalar @targetList . ' targets',
            );
        }
    }

    sub interactLimitedTargets {

        # Called by GA::Cmd::Kill->do and Kkill->do
        # Attacks a list of targets limited to the given arguments, e.g. ('orc') or ('orcs',
        #   'troll', 'bears'), but doesn't attack players
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - What the player actually typed (e.g. ';k orcs');
        #   $standardCmd    - The standard version of the command (i.e. 'kill')
        #   $multipleFlag   - Flag set to FALSE when called by ';interact' (e.g. attack a single
        #                       orc), set to TRUE when called by ';iinteract' (e.g. attack all orcs
        #                       at current location)
        #   @targetList     - A list of target strings specified by the user, e.g. ('orcs', 'wolf')
        #
        # Return values
        #   'undef' on improper arguments or failure
        #   1 on success

        my ($self, $session, $inputString, $standardCmd, $multipleFlag, @targetList) = @_;

        # Local variables
        my @objList;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $multipleFlag
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->interactLimitedTargets', @_);
        }

        # This command requires the Locator task to know the current location
        if (! $session->locatorTask) {

            return $self->error(
                $session, $inputString,
                'Cannot interact - Locator task isn\'t running',
            );

        } elsif (! $session->locatorTask->roomObj) {

            return $self->error(
                $session, $inputString,
                'Cannot interact - Locator task doesn\'t know the current location',
            );
        }

        if (! @targetList) {

            # Get the first target from the Locator's list of things in the current room
            @objList = $session->locatorTask->roomObj->tempObjList;
            if (! @objList) {

                return $self->complete(
                    $session, $standardCmd,
                    'Cannot interact - current location is empty',
                );

            } else {

                # Choose the first minion, sentient or creature in @objList
                OUTER: foreach my $obj (@objList) {

                    if (
                        $obj->aliveFlag
                        && (
                            ($obj->category eq 'minion' && ! $obj->ownMinionFlag)
                            || $obj->category eq 'sentient'
                            || $obj->category eq 'creature'
                        )
                    ) {
                        push (@targetList, $obj->noun);
                        last OUTER;
                    }
                }
            }

            # If no suitable objects were found, don't attack
            if (! @targetList) {

                return $self->complete(
                    $session, $standardCmd,
                    'Cannot interact - no enemy minions, sentients or creatures at the current'
                    . ' location',
                );
            }
        }

        # Attack the targets
        foreach my $target (@targetList) {

            $session->sendModCmd('interact', 'victim', $target);
        }

        if (scalar @targetList == 1) {

            return $self->complete($session, $standardCmd, 'Interacting with 1 target');

        } else {

            return $self->complete(
                $session, $standardCmd,
                'Interacting with ' . scalar @targetList . ' targets',
            );
        }
    }

    sub interactUnlimitedTargets {

        # Called by GA::Cmd::KillAll->do and KillMall->do
        # Attacks all targets (or all non-player targets) at current location
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - What the player actually typed (e.g. ';ia');
        #   $standardCmd    - The standard version of the command (i.e. 'interactall')
        #   $playerFlag     - Set to TRUE if player targets should be attacked too; FALSE if only
        #                       non-player targets should be attacked
        #
        # Return values
        #   'undef' on improper arguments or failure
        #   1 on success

        my ($self, $session, $inputString, $standardCmd, $playerFlag, $check) = @_;

        # Local variables
        my (@objList, @targetList);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $standardCmd
            || ! defined $playerFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->interactUnlimitedTargets',
                @_,
            );
        }

        # This command requires the Locator task to know the current location
        if (! $session->locatorTask) {

            return $self->error(
                $session, $inputString,
                'Cannot kill - Locator task isn\'t running',
            );

        } elsif (! $session->locatorTask->roomObj) {

            return $self->error(
                $session, $inputString,
                'Cannot kill - Locator task doesn\'t know the current location',
            );
        }

        # Get a list of attackable targets from the Locator's list of things in the current room
        @objList = $session->locatorTask->roomObj->tempObjList;
        if (! @objList) {

            return $self->complete(
                $session, $standardCmd,
                'Cannot kill - current location is empty',
            );

        } else {

            foreach my $obj (@objList) {

                if (
                    $obj->aliveFlag
                    && (
                        ($playerFlag && $obj->category eq 'char')
                        || ($obj->category eq 'minion' && ! $obj->ownMinionFlag)
                        || $obj->category eq 'sentient'
                        || $obj->category eq 'creature'
                    )
                ) {
                    push (@targetList, $obj->noun);
                }
            }
        }

        # Attack the targets
        foreach my $target (@targetList) {

            $session->sendModCmd('interact', 'victim', $target);
        }

        if (scalar @targetList == 1) {

            return $self->complete($session, $standardCmd, 'Interacting 1 target');

        } else {

            return $self->complete(
                $session, $standardCmd,
                'Interacting with ' . scalar @targetList . ' targets',
            );
        }
    }

    # Extract switches

    sub extractProfileSwitches {

        # Called by $self->addInterface, ->modifyInterface, ->deleteInterface
        # Extracts the group 1 switch options for the commands ';addtrigger', ';modifytrigger' and
        #   ';deletetrigger' (etc), namely -w, -r, -g, -c, -x <category>, -d <profile>
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $inputString    - what the user originally typed
        #   $category       - 'trigger', 'alias', 'macro', 'timer' or 'hook'
        #   $action         - what is to be done with the interface: 'add', 'modify' or 'delete'
        #
        # Optional arguments
        #   @args           - List of group 1 switch options arguments extracted from $inputString
        #                       (maybe be an empty list)
        #
        # Return values
        #   Returns an empty list on improper arguments or on failure
        #   Otherwise, returns a list in the form...
        #       ($profCount, $profCategory, $profName, @args)
        #   ...where $profCount is set to 0, if no profiles were found, and @args now contains fewer
        #       (or the same arguments), depending on how many switch options were removed

        my ($self, $session, $inputString, $category, $action, @args) = @_;

        # Local variables
        my (
            $switch, $profCount, $profCategory, $profName, $tempCategory, $specificProf,
            $profObj,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $inputString || ! defined $category || ! defined $action
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->extractProfileSwitches',
                @_,
            );
        }

        # Extract group 1 switches
        $profCount = 0;
        ($switch, @args) = $self->extract('w', 0, @args);
        if (defined $switch) {

            $profCount++;
            $profCategory = 'world';
            $profName = $session->currentWorld->name;
        }

        ($switch, @args) = $self->extract('g', 0, @args);
        if (defined $switch) {

            if (! $session->currentGuild) {

                return $self->error(
                    $session, $inputString,
                    'Can\'t ' . $action . ' ' . $category . ' interface associated with current'
                    . ' guild - no current guild set',
                );

            } else {

                $profCount++;
                $profCategory = 'guild';
                $profName = $session->currentGuild->name;
            }
        }

        ($switch, @args) = $self->extract('r', 0, @args);
        if (defined $switch) {

            if (! $session->currentRace) {

                return $self->error(
                    $session, $inputString,
                    'Can\'t ' . $action . ' ' . $category . ' interface associated with current'
                    . ' race - no current race set',
                );

            } else {

                $profCount++;
                $profCategory = 'race';
                $profName = $session->currentRace->name;
            }
        }

        ($switch, @args) = $self->extract('c', 0, @args);
        if (defined $switch) {

            if (! $session->currentChar) {

                return $self->error(
                    $session, $inputString,
                    'Can\'t ' . $action . ' ' . $category . ' interface associated with current'
                    . ' character - no current character set',
                );

            } else {

                $profCount++;
                $profCategory = 'char';
                $profName = $session->currentChar->name;
            }
        }

        ($switch, $tempCategory, @args) = $self->extract('x', 1, @args);
        if (defined $switch) {

            if (! $session->ivExists('templateHash', $profCategory)) {

                return $self->error(
                    $session, $inputString,
                    'Unrecognised custom profile category \'' . $profCategory . '\'',
                );

            } elsif (! $session->ivExists('currentProfHash', $profCategory)) {

                return $self->error(
                    $session, $inputString,
                    'Can\'t ' . $action . ' ' . $category . ' interface associated with '
                    . 'current custom \'' . $profCategory . '\' profile - no '
                    . 'current ' . $profCategory . ' profile set',
                );

            } else {

                $profObj = $session->ivShow('currentProfHash', $profCategory);

                $profCount++;
                $profCategory = $tempCategory;
                $profName = $profObj->name;
            }
        }

        ($switch, $specificProf, @args) = $self->extract('d', 1, @args);
        if (defined $switch) {

            if (! $session->ivExists('profHash', $specificProf)) {

                return $self->error(
                    $session, $inputString,
                    'Unrecognised profile \'' . $specificProf . '\'',
                );

            } else {

                $profObj = $session->ivShow('profHash', $specificProf);

                $profCount++;
                $profCategory = $profObj->category;
                $profName = $profObj->name;
            }
        }

        # Extraction complete
        return ($profCount, $profCategory, $profName, @args);
    }

    sub extractTaskSwitches {

        # Called by GA::Cmd::StartTask->do, AddInitTask->do and AddCustomTask->do
        # Also called by GA::Cmd::RunScriptTask->do
        # Extracts the switch options these commands have in common
        #
        # Expected arguments
        #   $session            - The calling function's GA::Session
        #   $inputString        - What the user actually typed (e.g. ';st status -i');
        #   $standardCmd        - The standard version of the user command, i.e. 'starttask'
        #
        # Return values
        #   An empty list on improper arguments or on failure
        #   Otherwise, returns a list of values in the form:
        #       (TRUE, $groupCount, $otherTask, $minutes, $runMinutes, $timer, $immediateFlag,
        #       $waitTaskExistFlag, $waitTaskNoExistFlag, $waitTaskStartStopFlag, $waitMinutesFlag,
        #       $unlimitedFlag, $runTaskForFlag, $runTaskUntilFlag, $noWindowFlag, @args)
        #   The first argument, TRUE, is the flag to signal success of this function
        #   The final argument, @args, contain any remaining arguments after the switch options
        #       have been extracted

        my ($self, $session, $inputString, $standardCmd, @args) = @_;

        # Local variables
        my (
            $groupCount, $switch, $otherTask, $minutes, $runMinutes, $timer, $immediateFlag,
            $waitTaskExistFlag, $waitTaskNoExistFlag, $waitTaskStartStopFlag, $waitMinutesFlag,
            $unlimitedFlag, $runTaskForFlag, $runTaskUntilFlag, $noWindowFlag, $string,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $inputString || ! defined $standardCmd || ! @args) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->extractTaskSwitches', @_);
            return @emptyList;
        }

        # Extract group 1 switches
        #   -i                  - Start <task> immediately (default setting)
        #   -e <other_task>     - Wait for <other_task> to exist, before starting <task>
        #   -n <other_task>     - Wait for <other_task> to not exist, before starting <task>
        #   -s <other_task>     - Wait for <other_task> to start, then stop, before starting <task>
        #   -t <minutes>        - Start <task> <minutes> from now
        $groupCount = 0;

        ($switch, @args) = $self->extract('i', 0, @args);
        if (defined $switch) {

            $immediateFlag = TRUE;
            $groupCount++;
        }

        ($switch, $string, @args) = $self->extract('e', 1, @args);
        if (defined $switch) {

            $waitTaskExistFlag = TRUE;
            $otherTask = $string;
            $groupCount++;
        }

        ($switch, $string, @args) = $self->extract('n', 1, @args);
        if (defined $switch) {

            $waitTaskNoExistFlag = TRUE;
            $otherTask = $string;
            $groupCount++;
        }

        ($switch, $string, @args) = $self->extract('s', 1, @args);
        if (defined $switch) {

            $waitTaskStartStopFlag = TRUE;
            $otherTask = $string;
            $groupCount++;
        }

        ($switch, $string, @args) = $self->extract('t', 1, @args);
        if (defined $switch) {

            $waitMinutesFlag = TRUE;
            $minutes = $string;
            $groupCount++;
        }

        if ($groupCount > 1) {

            return $self->error(
                $session, $inputString,
                'Invalid switch arguments - switches -i/-e/-n/-s/-t can\'t be combined',
            );
        }

        # Extract group 2 switches
        #   -d              - Run <task> for an unlimited amount of time (default)
        #   -f <minutes>    - Run the task for <minutes>
        #   -u <timer>      - Run the task until the Axmud timer reaches <timer> (seconds since the
        #                       script began)
        $groupCount = 0;
        ($switch, @args) = $self->extract('d', 0, @args);
        if (defined $switch) {

            $unlimitedFlag = TRUE;
            $groupCount++;
        }

        ($switch, $runMinutes, @args) = $self->extract('f', 1, @args);
        if (defined $switch) {

            $runTaskForFlag = TRUE;
            $groupCount++;
        }

        ($switch, $timer, @args) = $self->extract('u', 1, @args);
        if (defined $switch) {

            $runTaskUntilFlag = TRUE;
            $groupCount++;
        }

        if ($groupCount > 1) {

            return $self->error(
                $session, $inputString,
                'Invalid switch arguments - switches -d/-f/-u can\'t be combined',
            );
        }

        # Extract group 3 switches
        #   -w      - Run the task without opening its own window (if it usually does)
        ($switch, @args) = $self->extract('w', 0, @args);
        if (defined $switch) {

            $noWindowFlag = TRUE;
        }

        # Return list of flags. The 1st argument is the flag to signal success
        return (
            TRUE,
            $groupCount, $otherTask, $minutes, $runMinutes, $timer, $immediateFlag,
            $waitTaskExistFlag, $waitTaskNoExistFlag, $waitTaskStartStopFlag, $waitMinutesFlag,
            $unlimitedFlag, $runTaskForFlag, $runTaskUntilFlag, $noWindowFlag,
            @args
        );
    }

    sub extractWinzoneSwitches {

        # Called by GA::Cmd::AddWinzone->do and ModifyWinzone->do
        # Extracts the switch options these commands have in common
        # Checks that each pattern found is valid, and that the compulsory switch options are
        #   present
        #
        # Expected arguments
        #   $session            - The calling function's GA::Session
        #   $inputString        - What the user actually typed (e.g.
        #                           ';awz -p 10 10 -s 10 10 -n MyPackage');
        #   $standardCmd        - The standard version of the command, i.e. 'addwinzone'
        #   @args               - A list of arguments specified by the calling command,
        #                           e.g. ('-p', 10, 10, '-s', 10, 10, '-n', 'MyPackage')
        #
        # Return values
        #   Returns 'undef' on improper arguments or on failure
        #   Otherwise returns a list of arguments in the form
        #       (
        #           TRUE,
        #           $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $packageName, $objName,
        #           $positionFlag, $sizeFlag, $packageNameFlag, $objNameFlag,
        #           \%initHash, \%removeHash,
        #           @args,
        #       )
        #   The first argument, TRUE, is the flag to signal success of this function
        #   The final argument, @args, contain any remaining arguments after the switch options
        #       have been extracted

        my ($self, $session, $inputString, $standardCmd, @args) = @_;

        # Local variables
        my (
            $switch, $exitFlag,
            $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $packageName, $objName,
            $positionFlag, $sizeFlag, $packageNameFlag, $objNameFlag,
            %initHash, %removeHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $inputString || ! defined $standardCmd) {

            return $self->improper($session, $inputString);
        }

        # Extract compulsory switches (optional for ;modifywinzone)
        ($switch, $xPosBlocks, $yPosBlocks, @args) = $self->extract('-p', 2, @args);
        if (defined $switch) {

            $positionFlag = TRUE;
        }

        ($switch, $widthBlocks, $heightBlocks, @args) = $self->extract('-s', 2, @args);
        if (defined $switch) {

            $sizeFlag = TRUE;
        }

        ($switch, $packageName, @args) = $self->extract('-n', 1, @args);
        if (defined $switch) {

            $packageNameFlag = TRUE;

            if (! ($packageName =~ m/\:\:/)) {

                $packageName = 'Games::Axmud::Strip::' . $packageName;
            }
        }

        # Extract optional switches
        ($switch, $objName, @args) = $self->extract('-o', 1, @args);
        if (defined $switch) {

            $objNameFlag = TRUE;
        }

        do {

            my ($key, $value, $key2);

            $exitFlag = TRUE;

            ($switch, $key, $value, @args) = $self->extract('-i', 2, @args);
            if (defined $switch) {

                $exitFlag = FALSE;
                $initHash{$key} = $value;
            }

            ($switch, $key2, @args) = $self->extract('-r', 1, @args);
            if (defined $switch) {

                $exitFlag = FALSE;
                $removeHash{$key} = undef;
            }

        } until ($exitFlag);

        # Check compulsory switch options (optional for ;modifywinzone)
        if (
            $standardCmd eq 'addwinzone'
            && (
                ! defined $positionFlag || ! defined $sizeFlag || ! $packageNameFlag
                || ! defined $xPosBlocks || ! defined $yPosBlocks || ! defined $widthBlocks
                || ! defined $heightBlocks || ! defined $packageName
            )
        ) {
            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a winzone: missing compulsory switch options',
            );

        } elsif (
            $standardCmd eq 'modifywinzone'
            && (
                (
                    $positionFlag && (! defined $xPosBlocks || ! defined $yPosBlocks)
                ) || (
                    $sizeFlag && (! defined $widthBlocks || ! defined $heightBlocks)
                ) || (
                    $packageNameFlag && ! defined $packageName
                ) || %removeHash
            )
        ) {
            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a winzone: incomplete optional switch options',
            );

        }

        # Return list of arguments. The 1st argument is the flag to signal success
        return (
            TRUE,
            $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $packageName, $objName,
            $positionFlag, $sizeFlag, $packageNameFlag, $objNameFlag,
            \%initHash, \%removeHash,
            @args
        );
    }

    sub extractZoneModelSwitches {

        # Called by GA::Cmd::AddZoneModel->do and ModifyZoneModel->do
        # Extracts the switch options these commands have in common
        # Checks that each pattern found is valid, and that the compulsory switch options are
        #   present
        #
        # Expected arguments
        #   $session            - The calling function's GA::Session
        #   $inputString        - What the user actually typed (e.g.
        #                           ';azl -p 10 10 -s 10 10');
        #   $standardCmd        - The standard version of the command, i.e. 'addzonemodel'
        #   @args               - A list of arguments specified by the calling command,
        #                           e.g. ('-p', 10, 10, '-s', 10, 10)
        #
        # Return values
        #   Returns 'undef' on improper arguments or on failure
        #   Otherwise returns a list of arguments in the form
        #       (
        #           TRUE,
        #           $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $startCorner,
        #           $orientation, $maxWindows, $maxVisibleWindows, $defaultWidthBlocks,
        #           $defaultHeightBlocks, $ownerID, $enabledWinmap, $disabledWinmap, $gridWinmap,
        #           $positionFlag, $sizeFlag, $singleLayerFlag, startCornerFlag,
        #           $orientationFlag, $maxWindowFlag, $maxVisibleWindowFlag, $defaultWidthFlag,
        #           $defaultHeightFlag, $ownerIDFlag, $enabledWinmapFlag, $disabledWinmapFlag,
        #           $gridWinmapFlag,
        #           @args,
        #       )
        #   The first argument, TRUE, is the flag to signal success of this function
        #   The final argument, @args, contain any remaining arguments after the switch options
        #       have been extracted

        my ($self, $session, $inputString, $standardCmd, @args) = @_;

        # Local variables
        my (
            $switch, $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $startCorner,
            $orientation, $maxWindows, $maxVisibleWindows, $defaultWidthBlocks,
            $defaultHeightBlocks, $ownerID, $enabledWinmap, $disabledWinmap, $gridWinmap,
            $positionFlag, $sizeFlag, $singleLayerFlag, $startCornerFlag, $orientationFlag,
            $maxWindowFlag, $maxVisibleWindowFlag, $defaultWidthFlag, $defaultHeightFlag,
            $ownerIDFlag, $enabledWinmapFlag, $disabledWinmapFlag, $gridWinmapFlag,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $inputString || ! defined $standardCmd) {

            return $self->improper($session, $inputString);
        }

        # Extract compulsory switches (optional for ;modifyzonemodel)
        ($switch, $xPosBlocks, $yPosBlocks, @args) = $self->extract('-p', 2, @args);
        if (defined $switch) {

            $positionFlag = TRUE;
        }

        ($switch, $widthBlocks, $heightBlocks, @args) = $self->extract('-s', 2, @args);
        if (defined $switch) {

            $sizeFlag = TRUE;
        }

        # Extract optional switches
        ($switch, @args) = $self->extract('-l', 0, @args);
        if (defined $switch) {

            $singleLayerFlag = TRUE;
        }

        ($switch, $startCorner, @args) = $self->extract('-c', 1, @args);
        if (defined $switch) {

            $startCornerFlag = TRUE;
        }

        ($switch, $orientation, @args) = $self->extract('-o', 1, @args);
        if (defined $switch) {

            $orientationFlag = TRUE;
        }

        ($switch, $maxWindows, @args) = $self->extract('-m', 1, @args);
        if (defined $switch) {

            $maxWindowFlag = TRUE;
        }

        ($switch, $maxVisibleWindows, @args) = $self->extract('-v', 1, @args);
        if (defined $switch) {

            $maxVisibleWindowFlag = TRUE;
        }

        ($switch, $defaultWidthBlocks, @args) = $self->extract('-w', 1, @args);
        if (defined $switch) {

            $defaultWidthFlag = TRUE;
        }

        ($switch, $defaultHeightBlocks, @args) = $self->extract('-h', 1, @args);
        if (defined $switch) {

            $defaultHeightFlag = TRUE;
        }

        ($switch, $ownerID, @args) = $self->extract('-i', 1, @args);
        if (defined $switch) {

            $ownerIDFlag = TRUE;
        }

        ($switch, $enabledWinmap, @args) = $self->extract('-a', 1, @args);
        if (defined $switch) {

            $enabledWinmapFlag = TRUE;
        }

        ($switch, $disabledWinmap, @args) = $self->extract('-d', 1, @args);
        if (defined $switch) {

            $disabledWinmapFlag = TRUE;
        }

        ($switch, $gridWinmap, @args) = $self->extract('-g', 1, @args);
        if (defined $switch) {

            $gridWinmapFlag = TRUE;
        }

        # Check compulsory switch options (optional for ;modifyzonemodel)
        if (
            $standardCmd eq 'addzonemodel'
            && (
                ! $positionFlag || ! $sizeFlag || ! defined $xPosBlocks || ! defined $yPosBlocks
                || ! defined $widthBlocks || ! defined $heightBlocks
            )
        ) {
            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a zone model: missing compulsory switch options',
            );

        } elsif (
            $standardCmd eq 'modifyzonemodel'
            && (
                (
                    $positionFlag && (! defined $xPosBlocks || ! defined $yPosBlocks)
                ) || (
                    $sizeFlag && (! defined $widthBlocks || ! defined $heightBlocks)
                )
            )
        ) {
            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a zone model: incomplete optional switch options',
            );

        # Check optional switch options
        } elsif (

            $startCornerFlag
            && (
                ! defined $startCorner
                || (
                    $startCorner ne 'top_left' && $startCorner ne 'top_right'
                    && $startCorner ne 'bottom_left' && $startCorner ne 'bottom_right'
                )
            )
        ) {
            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a zone model: invalid start corner settings',
            );

        } elsif (

            $orientationFlag
            && (
                ! defined $orientation
                || (
                    $orientation ne 'horizontal' && $orientation ne 'vertical'
                )
            )
        ) {
            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a zone model: invalid orientation settings',
            );

        } elsif (defined $maxWindowFlag && (!($maxWindows =~  /\D/) || $maxWindows < 0)) {

            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a zone model: invalid max window settings',
            );

        } elsif (

            $maxVisibleWindowFlag
            && (! ($maxVisibleWindows =~ /\D/))
        ) {
            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a zone model: invalid max visible window settings',
            );

        } elsif (

            $defaultWidthFlag
            && (
                ! ($defaultWidthBlocks =~ /\D/)
                || $defaultWidthBlocks > 60
            )
        ) {
            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a zone model: invalid default width settings',
            );

        } elsif (
            $defaultHeightFlag
            && (
                ! ($defaultHeightBlocks =~ /\D/)
                || $defaultHeightBlocks > 60
            )
        ) {
            return $self->error(
                $session, $inputString,
                'Can\'t add/modify a zone model: invalid default height settings',
            );
        }

        # Return list of arguments. The 1st argument is the flag to signal success
        return (
            TRUE,
            $xPosBlocks, $yPosBlocks, $widthBlocks, $heightBlocks, $startCorner, $orientation,
            $maxWindows, $maxVisibleWindows, $defaultWidthBlocks, $defaultHeightBlocks,
            $ownerID, $enabledWinmap, $disabledWinmap, $gridWinmap,
            $positionFlag, $sizeFlag, $singleLayerFlag, $startCornerFlag, $orientationFlag,
            $maxWindowFlag, $maxVisibleWindowFlag, $defaultWidthFlag, $defaultHeightFlag,
            $ownerIDFlag, $enabledWinmapFlag, $disabledWinmapFlag, $gridWinmapFlag,
            @args
        );
    }

    ##################
    # Accessors - set

    sub add_userCmd {

        my ($self, $cmd, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_userCmd', @_);
        }

        @list = ($self->userCmdList, $cmd);

        # Sort in order of size
        @list = sort {
            if (length($a) == length($b)) {
                return (lc($a) cmp lc($b));
            } else {
                return length($a) <=> length($b);
            }
        } (@list);

        $self->ivPoke('userCmdList', @list);

        return 1;
    }

    sub del_userCmd {

        my ($self, $cmd, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_userCmd', @_);
        }

        if ($cmd eq $self->standardCmd) {

            # Can't delete the corresponding user command
            return undef;

        } else {

            foreach my $item ($self->userCmdList) {

                if ($item ne $cmd) {

                    push (@list, $item);
                }
            }

            $self->ivPoke('userCmdList', @list);

            return 1;
        }
    }

    sub reset_userCmd {

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_userCmd', @_);
        }

        # Reset the list
        $self->ivPoke('usrCmdList', $self->defaultUserCmdList);

        return 1;
    }

    ##################
    # Accessors - get

    sub standardCmd
        { $_[0]->{standardCmd} }

    sub defaultUserCmdList
        { my $self = shift; return @{$self->{defaultUserCmdList}}; }
    sub userCmdList
        { my $self = shift; return @{$self->{userCmdList}}; }

    sub descrip
        { $_[0]->{descrip} }
    sub builtInFlag
        { $_[0]->{builtInFlag} }
    sub disconnectFlag
        { $_[0]->{disconnectFlag} }
    sub noBracketFlag
        { $_[0]->{noBracketFlag} }
}

{ package Games::Axmud::Generic::ConfigWin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of a 'config' window (any 'free' window object inheriting from this
        #   object, namely 'edit' windows and 'pref' windows)
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - A string to use as the window title. If 'undef', a generic title is
        #                       used
        #   $editObj        - The object to be edited in the window (for 'edit' windows only;
        #                       should be 'undef' for 'pref' windows)
        #   $tempFlag       - Flag set to TRUE if $editObj is either temporary, or has not yet been
        #                       added to any registry (usually because the user needs to name it
        #                       first). Set to FALSE (or 'undef') otherwise. Ignored if $editObj is
        #                       not specified
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'config' window; for example, for example,
        #                       GA::PrefWin::TaskStart uses it to specify a task name and type.
        #                       Set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Local variables
        my ($winType, $winName);

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Set the values to use for some standard window IVs
        if ($editObj) {

            $winType = 'edit';
            $winName = 'edit';
            if (! defined $title) {

                $title = 'Edit window';
            }

        } else {

            $winType = 'pref';
            $winName = 'pref';
            if (! defined $title) {

                $title = 'Preference window';
            }
        }

        # Setup
        my $self = {
            _objName                    => $winType . '_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => $winType,
            # A name for the window (for 'config' windows, the same as the window type)
            winName                     => $winName,
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,       # Gtk2::VBox

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $axmud::CLIENT->constFreeWinWidth,
            heightPixels                => $axmud::CLIENT->constFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $title,
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # Standard IVs for 'config' windows

            # Widgets
            notebook                    => undef,       # Gtk2::Notebook
            hBox                        => undef,       # Gtk2::HBox
            tooltips                    => undef,       # Gtk2::Tooltips
            okButton                    => undef,       # Gtk2::Button
            cancelButton                => undef,       # Gtk2::Button
            resetButton                 => undef,       # Gtk2::Button
            saveButton                  => undef,       # Gtk2::Button

            # The standard table size for the notebook (any 'edit'/'pref' window can use a different
            #   size, if it wants)
            tableSize                   => 12,

            # The object to be edited in the window (for 'edit' windows only; should be 'undef' for
            #   'pref' windows)
            editObj                     => $editObj,
            # Flag set to TRUE if $editObj is either temporary, or has not yet been added to any
            #   registry (usually because the user needs to name it first). Set to FALSE
            #   (or 'undef') otherwise. Ignored if $editObj is not specified
            tempFlag                    => $tempFlag,
            # Flag that can be set to TRUE (usually by $self->setupNotebook or ->expandNotebook) if
            #   $editObj is a current object (e.g. if it is a current profile); set to FALSE at all
            #   other times
            currentFlag                 => FALSE,
            # For 'edit' windows, a hash of IVs in $editObj that should be changed. If no changes
            #   have been made in the 'edit' window, the hash is empty; otherwise the hash contains
            #   the new values for each IV to be modified
            # Hash in the form:
            #   ->editHash{iv_name} = scalar;
            #   ->editHash{iv_name} = list_reference;
            #   ->editHash{iv_name} = hash_reference;
            # For 'pref' windows, a hash of key-value pairs set by the window's widgets;
            #   $self->enableButtons can access this hash to perform any necessary actions
            #   ('pref' windows don't make a call to ->saveChanges)
            editHash                    => {},
            # Hash containing any number of key-value pairs needed for this particular
            #   'edit'/'pref' window; for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            editConfigHash              => \%configHash,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}             # Inherited from GA::Generic::FreeWin

    sub winEnable {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->winSetup
        # After the Gtk2::Window has been setup and moved into position, makes it visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if $self->editObj is the wrong type of object
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # For 'edit' windows, check that $self->editObj is of the right type. For 'pref' windows,
        #   $self->editObj is not set, so the check always succeeds
        if (! $self->checkEditObj()) {

            return undef;
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

        return 1;
    }

#   sub winDesengage {}         # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}           # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}           # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the 'edit'/'pref' window with its standard widgets
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # Add a notebook at the top
        my $notebook = Gtk2::Notebook->new();
        $packingBox->pack_start($notebook, TRUE, TRUE, 0);
        $notebook->set_scrollable(TRUE);

        # Add a button strip at the bottom, in a horizontal packing box
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_end($hBox, FALSE, FALSE, $self->spacingPixels);

        # Create a Gtk2::Tooltips object, to be used by buttons on all tabs in this window
        my $tooltips = Gtk2::Tooltips->new();

        # Create Reset/Save/Cancel/OK buttons
        my ($okButton, $cancelButton, $resetButton, $saveButton)
            = $self->enableButtons($hBox, $tooltips);

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('notebook', $notebook);
        $self->ivPoke('hBox', $hBox);
        $self->ivPoke('tooltips', $tooltips);
        $self->ivPoke('okButton', $okButton);
        $self->ivPoke('cancelButton', $cancelButton);
        $self->ivPoke('resetButton', $resetButton);
        $self->ivPoke('saveButton', $saveButton);

        # Set up the notebook with its tabs
        $self->setupNotebook();

        return 1;
    }

#   sub redrawWidgets {}        # Inherited from GA::Generic::Win

    # ->signal_connects

    sub setDeleteEvent {

        # Called by $self->winSetup
        # Set up a ->signal_connect to watch out for the user manually closing the 'config' window
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setDeleteEvent', @_);
        }

        $self->winBox->signal_connect('delete-event' => sub {

            # Prevent Gtk2 from taking action directly. Instead redirect the request to
            #   $self->winDestroy
            return $self->winDestroy();
        });

        return 1;
    }

    # Other functions

    sub checkEditObj {

        # Called by $self->winEnable
        # For 'edit' windows, checks that the object stored in $self->editObj is the correct class
        #   of object. For 'pref' windows, the check always succeeds (because 'pref' windows don't
        #   have an ->editObj)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the check fails
        #   1 if the check succeeds

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkEditObj', @_);
        }

        # (Everything inherits from Games::Axmud, so in this generic function the check always
        #   succeeds)
        if ($self->editObj && ! $self->editObj->isa('Games::Axmud')) {
            return undef;
        } else {
            return 1;
        }
    }

    sub enableButtons {

        # Called by $self->drawWidgets
        # Creates the OK/Cancel/Save/Reset buttons at the bottom of the window
        # Individual 'edit'/'pref' windows almost always inherit the generic ->winEnable method,
        #   but can use their own $self->enableButtons (rather than inherit this one) if they don't
        #   need all four buttons
        #
        # Expected arguments
        #   $hBox       - The horizontal packing box in which the buttons live (not yet stored as
        #                   an IV)
        #   $tooltips   - A Gtk2::Tooltips object for the buttons (not yet stored as an IV)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, a list containing the four Gtk::Button objects created

        my ($self, $hBox, $tooltips, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (! defined $hBox || ! defined $tooltips || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->enableButtons', @_);
            return @emptyList;
        }

        # Create the OK button, desensitised if $self->tempFlag is TRUE
        my $okButton = Gtk2::Button->new('OK');
        $hBox->pack_end($okButton, FALSE, FALSE, $self->borderPixels);
        $okButton->get_child->set_width_chars(10);
        $okButton->signal_connect('clicked' => sub {

            $self->buttonOK();
        });
        $tooltips->set_tip($okButton, 'Accept changes');
        if ($self->tempFlag) {

            $okButton->set_state('insensitive');
        }

        # Create the Cancel button (never desensitised)
        my $cancelButton = Gtk2::Button->new('Cancel');
        $hBox->pack_end($cancelButton, FALSE, FALSE, $self->spacingPixels);
        $cancelButton->get_child->set_width_chars(10);
        $cancelButton->signal_connect('clicked' => sub {

            $self->buttonCancel();
        });
        $tooltips->set_tip($cancelButton, 'Cancel changes');

        # Create the Reset button, desensitised if $self->tempFlag is TRUE
        my $resetButton = Gtk2::Button->new('Reset');
        $hBox->pack_start($resetButton, FALSE, FALSE, $self->borderPixels);
        $resetButton->get_child->set_width_chars(10);
        $resetButton->signal_connect('clicked' => sub {

            $self->buttonReset();
        });
        $tooltips->set_tip($resetButton, 'Reset changes without closing the window');
        if ($self->tempFlag) {

            $resetButton->set_state('insensitive');
        }

        # Create the Save button, desensitised if $self->tempFlag is TRUE
        my $saveButton = Gtk2::Button->new('Save');
        $hBox->pack_start($saveButton, FALSE, FALSE, $self->borderPixels);
        $saveButton->get_child->set_width_chars(10);
        $saveButton->signal_connect('clicked' => sub {

            $self->buttonSave();
        });
        $tooltips->set_tip($saveButton, 'Save changes without closing the window');
        if ($self->tempFlag) {

            $saveButton->set_state('insensitive');
        }

        return ($okButton, $cancelButton, $resetButton, $saveButton);
    }

    sub enableSingleButton {

        # Called by $self->enableButtons when only a single 'OK' button is required (rather than
        #   the usual four)
        # Creates the OK button at the bottom of the window
        #
        # Expected arguments
        #   $hBox       - The horizontal packing box in which the buttons live
        #   $tooltips   - A Gtk2::Tooltips object for the buttons
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, a list containing the Gtk::Button object created

        my ($self, $hBox, $tooltips, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (! defined $hBox || ! defined $tooltips || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->enableSingleButton', @_);
            return @emptyList;
        }

        # Create the OK button
        my $okButton = Gtk2::Button->new('OK');
        $okButton->signal_connect('clicked' => sub {

            $self->buttonOK();
        });
        $tooltips->set_tip($okButton, 'Close window');
        $hBox->pack_end($okButton, 0, 0, $self->borderPixels);

        # This object doesn't edit anything, so we don't need Cancel/Reset/Edit buttons
        return ($okButton);
    }

    sub setupNotebook {

        # Called by $self->winEnable
        # Creates the first tab for the notebook. The remaining tabs are created by
        #   $self->expandNotebook
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupNotebook', @_);
        }

        # Tab setup, using the standard table size
        my ($vBox, $table) = $self->addTab('_Name', $self->notebook);

        # Set up the rest of the tab
        $self->nameTab($table);

        # Set up the remaining tabs
        $self->expandNotebook();

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub expandNotebook {

        # Called by $self->setupNotebook
        # Set up additional tabs for the notebook, depending on which type of object is being edited
        # Because this is the generic function, no additional tabs are actually set up here. This
        #   generic function is usually only called for 'edit'/'pref' windows which have a single
        #   tab (such as GA::EditWin::Interface::Active)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->expandNotebook', @_);
        }

#       $self->additionalTab();

        return 1;
    }

    sub saveChanges {

        # Called by $self->buttonOK and $self->buttonSave (usually for 'edit' windows only, not
        #   'pref' windows)
        # Saves any changes made to data stored by the edit object
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->saveChanges', @_);
        }

        if ($self->editHash) {

            # Store the changes the user has made
            foreach my $key ($self->ivKeys('editHash')) {

                $self->editObj->{$key} = $self->ivShow('editHash', $key);
            }

            # The changes can now be cleared
            $self->ivEmpty('editHash');

            # Mark the object's corresponding file object as needing to be saved, if it exists
            if ($self->editObj->_parentFile) {

                $self->editObj->doModify('saveChanges');
            }

            # Update the current session's object viewer window, if it is open
            if ($self->session->viewerWin) {

                $self->session->viewerWin->updateNotebook();
            }
        }

        return 1;
    }

    # Add widgets

    sub addTab {

        # Adds a tab to the notebook, creating a scroller, a vertical packing box and a table, all
        #   with standardised sizes
        #
        # Expected arguments
        #   $tabName    - A mnemonic string, e.g. 'N_ame'
        #   $notebook   - The Gtk2::Notebook object to which this tab will be added
        #
        # Optional arguments
        #   $tableWidth, $tableHeight
        #               - The size of the table. If either or both is set to 'undef', the default
        #                   size is used (currently 12, stored in $self->tableSize)
        #   $columnSpaceWidth, $columnSpaceHeight
        #               - The spacing between columns/rows, in pixels. If either of both is set to
        #                   'undef', the default size is used ($self->spacingPixels)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise a list containing two of the Gtk2 objects created:
        #       (Gtk2::Vbox, Gtk2::Table)

        my (
            $self, $tabName, $notebook, $tableWidth, $tableHeight, $columnSpaceWidth,
            $columnSpaceHeight, $check
        ) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (! defined $tabName || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->addTab', @_);
            return @emptyList;
        }

        # Set default sizes
        if (! defined $tableWidth) {

            $tableWidth = $self->tableSize;
        }

        if (! defined $tableHeight) {

            $tableHeight = $self->tableSize;
        }

        if (! defined $columnSpaceWidth) {

            $columnSpaceWidth = $self->spacingPixels;
        }

        if (! defined $columnSpaceHeight) {

            $columnSpaceHeight = $self->spacingPixels;
        }

        # Tab setup
        my $vBox = Gtk2::VBox->new(FALSE, 0);
        $vBox->set_border_width($self->borderPixels);

        my $scroller = Gtk2::ScrolledWindow->new();
        $scroller->set_policy('automatic', 'automatic');
        $scroller->add_with_viewport($vBox);    # Need ->add_with_viewport, not ->add, here

        my $tab = Gtk2::Label->new_with_mnemonic($tabName);
        $notebook->append_page($scroller, $tab);

        my $table = Gtk2::Table->new($tableHeight, $tableWidth, FALSE);
        $table->set_col_spacings($columnSpaceWidth);
        $table->set_row_spacings($columnSpaceHeight);

        return ($vBox, $table);
    }

    sub addInnerNotebookTab {

        # Adds a tab to the notebook containing an inner notebook, so that we get a second row of
        #   tabs immediately beneath the first one
        #
        # Expected arguments
        #   $tabName    - A mnemonic string, e.g. 'N_ame'
        #   $notebook   - The Gtk2::Notebook object to which this tab will be added
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise a list containing two of the Gtk2 objects created:
        #       (Gtk2::Vbox, Gtk2::Notebook)

        my ($self, $tabName, $notebook, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->addInnerNotebookTab', @_);
            return @emptyList;
        }

        # Tab setup
        my $vBox = Gtk2::VBox->new(FALSE, 0);
        $vBox->set_border_width(0);

        my $innerNotebook = Gtk2::Notebook->new();
        $innerNotebook->set_scrollable(TRUE);
        $vBox->pack_start($innerNotebook, 1, 1, 0);

        my $tab = Gtk2::Label->new_with_mnemonic($tabName);
        $notebook->append_page($vBox, $tab);

        # Tab complete
        return ($vBox, $innerNotebook);
    }

    sub addLabel {

        # Adds a Gtk2::Label at the specified position in the tab's Gtk2::Table
        #
        # Example calls:
        #   my $label = $self->addLabel($table, 'Some plain text',
        #       0, 6, 0, 1);
        #   my $label = $self->addLabel($table, '<b>Some pango markup text</b>',
        #       0, 6, 0, 1,
        #       0, 0.5);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $text       - The text to display (plain text or pango markup text)
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the label in the table
        #
        # Optional arguments
        #   $alignLeft, $alignRight
        #               - Used in the call to ->set_alignment; two values in the range 0-1
        #               - If not specified, $alignLeft is set to 0, $alignRight to 0.5
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Label created

        my (
            $self, $table, $text, $leftAttach, $rightAttach, $topAttach, $bottomAttach, $alignLeft,
            $alignRight, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $text || ! defined $leftAttach || ! defined $rightAttach
            || ! defined $topAttach || ! defined $bottomAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addLabel', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Set default alignment, if none specified
        if (! defined $alignLeft) {

            $alignLeft = 0;
        }

        if (! defined $alignRight) {

            $alignRight = 0.5;
        }

        # Create the label
        my $label = Gtk2::Label->new();
        $label->set_markup($text);

        # Set its alignment
        $label->set_alignment($alignLeft, $alignRight);

        # Add it to the table
        $table->attach_defaults($label, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $label;
    }

    sub addLabelFrame {

        # Adds a Gtk2::Label within a Gtk2::Frame (giving the appearance of text in a box) at the
        #   specified position in the tab's Gtk2::Table
        #
        # Example calls:
        #   my $label = $self->addLabel($table, 'Some plain text',
        #       0, 6, 0, 1);
        #   my $label = $self->addLabel($table, '<b>Some pango markup text</b>',
        #       0, 6, 0, 1,
        #       0, 0.5);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $text       - The text to display (plain text or pango markup text)
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the label in the table
        #
        # Optional arguments
        #   $alignLeft, $alignRight
        #               - Used in the call to ->set_alignment; two values in the range 0-1
        #               - If not specified, $alignLeft is set to 0, $alignRight to 0.5
        #
        # Return values
        #   An empty list of improper arguments or if the widget's position in the Gtk2::Table is
        #       invalid
        #   Otherwise, a list in the form
        #       (gtk_frame, gtk_label)

        my (
            $self, $table, $text, $leftAttach, $rightAttach, $topAttach, $bottomAttach, $alignLeft,
            $alignRight, $check
        ) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $text || ! defined $leftAttach || ! defined $rightAttach
            || ! defined $topAttach || ! defined $bottomAttach || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->addLabel', @_);
            return @emptyList;
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return @emptyList;
        }

        # Set default alignment, if none specified
        if (! defined $alignLeft) {

            $alignLeft = 0;
        }

        if (! defined $alignRight) {

            $alignRight = 0.5;
        }

        # Create the frame
        my $frame = Gtk2::Frame->new(undef);
        $frame->set_border_width($self->borderPixels);

        # Create the label
        my $label = Gtk2::Label->new();
        $frame->add($label);
        $label->set_markup($text);

        # Set its alignment
        $label->set_alignment($alignLeft, $alignRight);

        # Add the frame to the table
        $table->attach_defaults($frame, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return ($frame, $label);
    }

    sub addButton {

        # Adds a Gtk2::Button at the specified position in the tab's Gtk2::Table
        #
        # Example calls:
        #   my $button = $self->addButton($table, 'button_name', 'tooltips', \&buttonClicked,
        #       0, 6, 0, 1);
        #   my $button = $self->addButton($table, 'button_name', 'tooltips', undef,
        #       0, 6, 0, 1);
        #   my $button = $self->addButton($table, 'button_name', '', \&buttonClicked,
        #       0, 6, 0, 1);
        #
        # The referenced function (if specified) receives an argument list in the form:
        #   ($self, button_widget)
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $name       - The name displayed on the button
        #   $tooltips   - Tooltips to use for the button; empty strings are not used
        #   $funcRef    - Reference to the function to call when the button is clicked. If 'undef',
        #                   it's up to the calling function to create a ->signal_connect method
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the button in the table
        #
        # Optional arguments
        #   $flag       - If set to TRUE, the button is marked with an image (namely
        #                   /icons/system/irreversible.png), which shows an action which can't
        #                   easily be reversed (e.g. by clicking on the main 'Cancel' button)
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Button created

        my (
            $self, $table, $name, $tooltips, $funcRef, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $flag, $check
        ) = @_;

        # Local variables
        my $current;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $name || ! defined $tooltips || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addButton', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # If $flag was specified, but GA::Client->irreversibleIconFlag is FALSE, we can't draw an
        #   icon to show the irreversible action; instead, add an asterisk to the button label
        if ($flag && ! $axmud::CLIENT->irreversibleIconFlag) {

            $name = '(*) ' . $name;
        }

        # Create the button
        my $button = Gtk2::Button->new($name);

        # If a callback function was specified, use it
        if ($funcRef) {

            $button->signal_connect('clicked' => sub {

                &$funcRef($self, $button);
            });
        }

        # Use tooltips, if any were specified
        if ($tooltips) {

            $self->tooltips->set_tip($button, $tooltips);
        }

        # Use the 'irreversible' icon, if it was specified
        if ($flag && $axmud::CLIENT->irreversibleIconFlag) {

            my $image = Gtk2::Image->new_from_file(
                $axmud::SHARE_DIR . '/icons/system/irreversible.png',
            );

            $button->set_image($image);
        }

        # Add the button to the table
        $table->attach_defaults($button, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $button;
    }

    sub addCheckButton {

        # Adds a Gtk2::CheckButton at the specified position in the window's Gtk2::Table
        #
        # Example calls:
        #   my $checkButton = $self->addCheckButton($table, 'some_IV', TRUE,
        #       0, 6, 0, 1);
        #   my $checkButton = $self->addCheckButton($table, 'some_IV', FALSE,
        #       0, 6, 0, 1, 0, 0.5);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $iv         - A string naming the IV set when the check button is toggled. If 'undef',
        #                   nothing happens when the user toggles the checkbutton; it's up to the
        #                   calling function to check the button's state
        #   $stateFlag  - Flag set to FALSE if the checkbutton's state should be 'insensitive',
        #                   TRUE if it should be 'normal'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the checkbutton in the table
        #
        # Optional arguments
        #   $alignX, $alignY
        #               - Used in the call to ->set_alignment; two values in the range 0-1
        #               - If not specified, $alignX is set to 0, $alignY to 0.5
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::CheckButton created

        my (
            $self, $table, $iv, $stateFlag, $leftAttach, $rightAttach, $topAttach, $bottomAttach,
            $alignX, $alignY, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $stateFlag || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addCheckButton', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Set default alignment, if none specified
        if (! defined $alignX) {

            $alignX = 0;
        }

        if (! defined $alignY) {

            $alignY = 0.5;
        }

        # Create the checkbutton
        my $checkButton = Gtk2::CheckButton->new();
        if ($iv) {

            # Display the existing value of the IV
            $checkButton->set_active($self->editObj->$iv);

            $checkButton->signal_connect('toggled' => sub {

                $self->ivAdd('editHash', $iv, $checkButton->get_active());
            });
        }

        # Make the checkbutton insensitive, if $stateFlag is FALSE
        if (! $stateFlag) {

            $checkButton->set_state('insensitive');
        }

        # Set its alignment
        $checkButton->set_alignment($alignX, $alignY);

        # Add the checkbutton to the table
        $table->attach_defaults($checkButton, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $checkButton;
    }

    sub addRadioButton {

        # Adds a Gtk2::RadioButton at the specified position in the tab's Gtk2::Table
        #
        # Example calls:
        #   my ($group, $button) = $self->addRadioButton(
        #       $table, undef, $name, 'some_IV', $value, TRUE,
        #       0, 6, 0, 1);
        #   my ($group2, $button2) = $self->addRadioButton(
        #       $table, $group, $name, 'some_IV', $value, TRUE,
        #       0, 6, 0, 1, 0, 0.5);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $group      - Reference to the radio button group created, when the first button in the
        #                   group was added (if set to 'undef', this is the first button, and a
        #                   group will be created for it)
        #   $name       - A 'name' for the radio button (displayed next to the button); if 'undef',
        #                   no name is displayed
        #   $iv         - A string naming the IV set when the radio button is toggled. If 'undef',
        #                   nothing happens when the user toggles the radiobutton; it's up to the
        #                   calling function to check the button's state
        #   $value      - The value to which the IV is set, when the radio button is selected
        #                   (ignored if $iv is 'undef')
        #   $stateFlag  - Flag set to FALSE if the radiobutton's state should be 'insensitive',
        #                   TRUE if it should be 'normal'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the radiobutton in the table
        #
        # Optional arguments
        #   $alignLeft, $alignRight
        #               - Used in the call to ->set_alignment; two values in the range 0-1
        #               - If not specified, $alignLeft is set to 0, $alignRight to 0.5
        #
        # Return values
        #   An empty list on improper arguments or if the widget's position in the Gtk2::Table is
        #       invalid
        #   Otherwise a list containing two elements: the radio button $group and the
        #       Gtk2::RadioButton created

        my (
            $self, $table, $group, $name, $iv, $value, $stateFlag, $leftAttach, $rightAttach,
            $topAttach, $bottomAttach, $alignLeft, $alignRight, $check
        ) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $stateFlag || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->addRadioButton', @_);
            return @emptyList;
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return @emptyList;
        }

        # Set default alignment, if none specified
        if (! defined $alignLeft) {

            $alignLeft = 0;
        }

        if (! defined $alignRight) {

            $alignRight = 0.5;
        }

        # Create the radio button
        my $radioButton = Gtk2::RadioButton->new();
        # Add it to the existing group, if one was specified
        if (defined $group) {

            $radioButton->set_group($group);
        }

        if ($iv) {

            # If $value is the one currently stored in $self->editObj, mark this radio button
            #   as active
            if (
                defined $value
                && defined $self->editObj->$iv
                && $value eq $self->editObj->$iv
            ) {
                $radioButton->set_active(TRUE);
            }

            $radioButton->signal_connect('toggled' => sub {

                # Set the IV only if this radiobutton has been selected
                if ($radioButton->get_active()) {

                    $self->ivAdd('editHash', $iv, $value);
                }
            });
        }

        # Give the radio button a name, if one was specified
        if ($name) {

            $radioButton->set_label($name);
        }

        # Make the radio button insensitive, if $stateFlag is FALSE
        if (! $stateFlag) {

            $radioButton->set_state('insensitive');
        }

        # Set radio button's alignment
        $radioButton->set_alignment($alignLeft, $alignRight);

        # Add the radio button to the table
        $table->attach_defaults($radioButton, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return ($radioButton->get_group(), $radioButton);
    }

    sub addEntry {

        # Adds a Gtk2::Entry at the specified position in the tab's Gtk2::Table
        #
        # Example calls:
        #   my $entry = $self->addEntry($table, 'some_IV', TRUE,
        #       0, 6, 0, 1);
        #   my $entry = $self->addEntry($table, 'some_IV', FALSE,
        #       0, 6, 0, 1, 16, 16);
        #   my $entry = $self->addEntry($table, undef, TRUE,
        #       0, 6, 0, 1);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $iv         - A string naming the IV set when the user modifies the text in the entry
        #                   box. If 'undef', nothing happens when the user modifies the text; it's
        #                   up to the calling function to check the entry box's state
        #   $stateFlag  - Flag set to FALSE if the entry box's state should be 'insensitive', TRUE
        #                   if it should be 'normal'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the entry box in the table
        #
        # Optional arguments
        #   $widthChars - The width of the box, in chars ('undef' if maximum not needed)
        #   $maxChars   - The maximum no. chars allowed in the box ('undef' if maximum not needed)
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Entry created

        my (
            $self, $table, $iv, $stateFlag, $leftAttach, $rightAttach, $topAttach, $bottomAttach,
            $widthChars, $maxChars, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $stateFlag || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addEntry', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Create the entry
        my $entry = Gtk2::Entry->new();

        # Display the existing value of the IV
        if (defined $iv && defined $self->editObj->$iv) {

            $entry->append_text($self->editObj->$iv);
        }

        # Set the width, if specified
        if (defined $widthChars) {

            $entry->set_width_chars($widthChars);
        }

        # Set the maximum number of characters, if specified
        if (defined $maxChars) {

            $entry->set_max_length($maxChars);
        }

        # Signal connect
        if (defined $iv) {

            $entry->signal_connect('changed' => sub {

                my $text = $entry->get_text();

                $self->ivAdd('editHash', $iv, $text);
            });
        }

        # Make the entry insensitive, if $stateFlag is FALSE
        if (! $stateFlag) {

            $entry->set_state('insensitive');
        }

        # Add the entry to the table
        $table->attach_defaults($entry, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $entry;
    }

    sub addEntryWithButton {

        # Adds a Gtk2::Entry at the specified position in the tab's Gtk2::Table. The entry is
        #   displayed alongside a button that simultaneously shows whether the IV's value is 'undef'
        #   and allows the user to set the IV to 'undef'
        #
        # Example calls:
        #   my $entry = $self->addEntryWithButton($table, 'some_IV', TRUE,
        #       0, 6, 0, 1);
        #   my $entry = $self->addEntryWithButton($table, 'some_IV', FALSE,
        #       0, 6, 0, 1, 16, 16);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $iv         - A string naming the IV set when the user modifies the text in the entry
        #                   box. Unlike most of these functions, the $iv must be specified
        #   $stateFlag  - Flag set to FALSE if the entry box's state should be 'insensitive', TRUE
        #                   if it should be 'normal'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the entry in the table
        #
        # Optional arguments
        #   $widthChars - The width of the box, in chars ('undef' if maximum not needed)
        #   $maxChars   - The maximum no. chars allowed in the box ('undef' if maximum not needed)
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Entry created

        my (
            $self, $table, $iv, $stateFlag, $leftAttach, $rightAttach, $topAttach, $bottomAttach,
            $widthChars, $maxChars, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $iv || ! defined $stateFlag || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addEntryWithButton', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }
        # Call $self->addEntry to create the entry as normal, reserving one square in the table for
        #   the button (we don't pass $iv to $self->addEntry because we're going to create our own
        #   ->signal_connect)
        my $entry = $self->addEntry(
            $table, undef, $stateFlag, $leftAttach, ($rightAttach - 1), $topAttach, $bottomAttach,
            $widthChars, $maxChars,
        );

        # Set the contents of the entry
        if (defined $iv && defined $self->editObj->$iv) {

            $entry->append_text($self->editObj->$iv);
        }

        # Create a button
        my $button = Gtk2::Button->new();

        # Set the icon to display on the button, depending on whether the IV is set to 'undef',
        #   or not
        my $image;
        if (defined $iv && defined $self->editObj->$iv) {

            # Use the Gtk2 'clear' icon - clicking on the button sets the IV to undef
            $image = Gtk2::Image->new_from_stock('gtk-clear', 'menu');
            # Give the button a tooltip
            $self->tooltips->set_tip($button, 'Click to set this IV to \'undef\'');

        } else {

            # Use the Gtk2 'remove' icon - IV is already 'undef'; clicking on the button does
            #   nothing
            $image = Gtk2::Image->new_from_stock('gtk-remove', 'menu');
            # Give the button a tooltip
            $self->tooltips->set_tip($button, 'This IV is already set to \'undef\'');
        }

        $button->set_image($image);

        # Make the button clickable
        $button->signal_connect('clicked' => sub {

            # Empty the entry to remove any text entered into it
            $entry->set_text('');

            # Set the IV to undef
            $self->ivAdd('editHash', $iv, undef);

            # Change the button's image to mark this IV as being set to undef
            my $image2 = Gtk2::Image->new_from_stock('gtk-remove', 'menu');
            $button->set_image($image2);
            # Give the button a new tooltip
            $self->tooltips->set_tip($button, 'This IV is already set to \'undef\'');
        });

        # Respond when the user types something in the box
        $entry->signal_connect('changed' => sub {

            my $text = $entry->get_text();
            $self->ivAdd('editHash', $iv, $text);

            # Contents of the entry can't possibly be 'undef' any more
            my $image3 = Gtk2::Image->new_from_stock('gtk-clear', 'menu');
            $button->set_image($image3);
            # Give the button a new tooltip
            $self->tooltips->set_tip($button, 'Click to set this IV to \'undef\'');
        });

        # Add the button to the table (the entry has already been added)
        $table->attach_defaults(
            $button,
            ($rightAttach - 1), $rightAttach, $topAttach, $bottomAttach,
        );

        return $entry;
    }

    sub addEntryWithIcon {

        # Adds a Gtk2::Entry at the specified position in the tab's Gtk2::Table. The entry contains
        #   a stock icon to show whether the current contents of the entry is permissible
        # The stock icons used are 'gtk-yes' (for an acceptable value) and 'gtk-no' (for a
        #   forbidden value)
        #
        # Example calls:
        #   my $entry = $self->addEntryWithIcon($table, 'some_IV', 'int', 0, 1000,
        #       0, 6, 0, 1);
        #   my $entry = $self->addEntryWithIcon($table, 'some_IV', 'odd', 1, 1001,
        #       0, 6, 0, 1);
        #   my $entry = $self->addEntryWithIcon($table, 'some_IV', 'even', 0, 1000,
        #       0, 6, 0, 1);
        #   my $entry = $self->addEntryWithIcon($table, 'some_IV', 'float', 0, 1000000,
        #       0, 6, 0, 1);
        #   my $entry = $self->addEntryWithIcon($table, 'some_IV', 'string', 3, 16,
        #       0, 6, 0, 1);
        #   my $entry = $self->addEntryWithIcon($table, 'some_IV', \&checkFunction, undef, undef,
        #       0, 6, 0, 1);
        #
        #   my $entry = $self->addEntryWithIcon($table, 'some_IV', 'int', 0, 1000,
        #       0, 6, 0, 1, 16, 16);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $iv         - A string naming the IV set when the user modifies the text in the entry
        #                   box. If 'undef', nothing happens when the user modifies the text (except
        #                   that the icon is updated); it's up to the calling function to check the
        #                   entry box's state
        #   $mode       - Set to 'int', 'odd', 'even', 'float', 'string' or a reference to a
        #                   function
        #               - If 'int', an integer is expected with the specified min/max values
        #               - If 'odd', an odd-numbered integer with the specified min/max value is
        #                   expected. If the minimum value is less than 1, 1 is used instead
        #               - If 'even', an even-numbered integer with the specified min/max value is
        #                   expected. If the minimum value is less than 0, 0 is used instead
        #               - If 'float', a floating point number is expected with the specified min/max
        #                   values
        #               - If 'string', a string is expected (which might be a number) with the
        #                   specified min/max length
        #               - If a function reference, a function is called which should return 'undef'
        #                   or 1, depending on the value of the entry; the icon is set accordingly
        #   $min, $max  - The values described above (ignored when $mode is a function reference).
        #                   If $min is 'undef', there is no minimum; if $max is 'undef', there is no
        #                   maximum
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the entry in the table
        #
        # Optional arguments
        #   $widthChars - The width of the box, in chars ('undef' if maximum not needed)
        #   $maxChars   - The maximum no. chars allowed in the box ('undef' if maximum not needed)
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Entry created

        my (
            $self, $table, $iv, $mode, $min, $max, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $widthChars, $maxChars, $check
        ) = @_;

        # Local variables
        my $msg;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $mode || ! defined $leftAttach || ! defined $rightAttach
            || ! defined $topAttach || ! defined $bottomAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addEntryWithIcon', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Check that the minimum/maximum values specified are valid and, if not, fix them
        if (defined $min && defined $max && $min > $max) {

            # Use no maximum value...
            $max = undef;
            # ...and show a warning, because this shouldn't happen
            if ($iv) {
                $msg = 'Minimum greater than maximum for IV \'' . $iv . '\'';
            } else {
                $msg = 'Minimum greater than maximum (min: ' . $min . ' max: ' . $max . ')';
            }

            $self->session->writeWarning(
                $msg,
                $self->_objClass . '->addEntryWithIcon',
            );
        }

        if ($mode eq 'odd' && defined $min && $min < 1) {

            # Lowest value of $min (if specified) is 1
            $min = 1;

        } elsif ($mode eq 'even' && defined $min && $min < 0) {

            # Lowest value of $min (if specified) is 0
            $min = 0;
        }

        # Create the entry
        my $entry = Gtk2::Entry->new();

        # Display the existing value of the IV
        if (defined $iv && defined $self->editObj->$iv) {

            $entry->append_text($self->editObj->$iv);

            if (! $self->checkEntry($self->editObj->$iv, $mode, $min, $max)) {
                $entry->set_icon_from_stock('secondary', 'gtk-no');
            } else {
                $entry->set_icon_from_stock('secondary', 'gtk-yes');
            }

        } else {

            # We still need to set the icon for an empty box
            if ($mode eq 'string') {

                # Empty strings might be acceptable
                if (! $self->checkEntry('', $mode, $min, $max)) {
                    $entry->set_icon_from_stock('secondary', 'gtk-no');
                } else {
                    $entry->set_icon_from_stock('secondary', 'gtk-yes');
                }

            } else {

                # Box is empty, so any $self->checkEntry test will fail
                # When $mode is set to a function reference, we'll have to assume that an empty
                #   entry box is not an acceptable value. If it is acceptable, you can call
                #   $self->setEntryIcon immediately after calling this function
                $entry->set_icon_from_stock('secondary', 'gtk-no');
            }
        }

        # Customise the entry
        $entry->signal_connect('changed' => sub {

            my $value = $entry->get_text();
            # Check whether $value is a valid value, or not
            if (! $self->checkEntry($value, $mode, $min, $max)) {

                # Can't use this value
                if (defined $iv) {

                    $self->ivDelete('editHash', $iv);
                }

                $entry->set_icon_from_stock('secondary', 'gtk-no');

            } else {

                # This is a valid value, so use it
                if (defined $iv) {

                    $self->ivAdd('editHash', $iv, $value);
                }

                $entry->set_icon_from_stock('secondary', 'gtk-yes');
            }
        });

        # Set the width, if specified
        if (defined $widthChars) {

            $entry->set_width_chars($widthChars);
        }

        # Set the maximum number of characters, if specified
        if (defined $maxChars) {

            $entry->set_max_length($maxChars);
        }

        # Add the entry to the table
        $table->attach_defaults($entry, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $entry;
    }

    sub addEntryWithIconButton {

        # A combination of ->addEntryWithButton and ->addEntryWithIcon, using the same arguments
        #   as ->addEntryWithIcon
        # An IV value of 'undef' counts as acceptable, in addition to the usual conditions
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $iv         - A string naming the IV set when the user modifies the text in the entry
        #                   box. Unlike most of these functions, the $iv must be specified
        #   $mode       - Set to 'int', 'odd', 'even', 'float', 'string' or a reference to a
        #                   function
        #               - If 'int', an integer is expected with the specified min/max values
        #               - If 'odd', an odd-numbered integer with the specified min/max value is
        #                   expected. If the minimum value is less than 1, 1 is used instead
        #               - If 'even', an even-numbered integer with the specified min/max value is
        #                   expected. If the minimum value is less than 0, 0 is used instead
        #               - If 'float', a floating point number is expected with the specified min/max
        #                   values
        #               - If 'string', a string is expected (which might be a number) with the
        #                   specified min/max length
        #               - If a function reference, a function is called which should return 'undef'
        #                   or 1, depending on the value of the entry; the icon is set accordingly
        #   $min, $max  - The values described above (ignored when $mode is a function reference).
        #                   If $min is 'undef', there is no minimum; if $max is 'undef', there is no
        #                   maximum
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the entry in the table
        #
        # Optional arguments
        #   $widthChars - The width of the box, in chars ('undef' if maximum not needed)
        #   $maxChars   - The maximum no. chars allowed in the box ('undef' if maximum not needed)
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Entry created

        my (
            $self, $table, $iv, $mode, $min, $max, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $widthChars, $maxChars, $check
        ) = @_;

        # Local variables
        my $msg;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $iv || ! defined $mode || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addEntryWithIconButton', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Call $self->addEntryWithIcon to create the entry as normal, reserving one square in the
        #   table for the button (we don't pass $iv to $self->addEntryWithIcon because we're going
        #   to create our own ->signal_connect)
        my $entry = $self->addEntryWithIcon(
            $table, undef, $mode, $min, $max, $leftAttach, ($rightAttach - 1), $topAttach,
            $bottomAttach, $widthChars, $maxChars,
        );

        # Set the contents of the entry
        if (defined $self->editObj->$iv) {

            $entry->append_text($self->editObj->$iv);

        } else {

            # An empty box represents 'undef', which is an acceptable value
            # We must set the icon manually, as calling $entry->set_text('') doesn't emit the
            #   'changed' signals which checks the validity of the value
            $entry->set_icon_from_stock('secondary', 'gtk-yes');
        }

        # Create a button
        my $button = Gtk2::Button->new();

        # Set the icon to display on the button, depending on whether the IV is set to 'undef',
        #   or not
        my $image;
        if (defined $iv && defined $self->editObj->$iv) {

            # Use the Gtk2 'clear' icon - clicking on the button sets the IV to undef
            $image = Gtk2::Image->new_from_stock('gtk-clear', 'menu');
            # Give the button a tooltip
            $self->tooltips->set_tip($button, 'Click to set this IV to \'undef\'');

        } else {

            # Use the Gtk2 'remove' icon - IV is already 'undef'; clicking on the button does
            #   nothing
            $image = Gtk2::Image->new_from_stock('gtk-remove', 'menu');
            # Give the button a tooltip
            $self->tooltips->set_tip($button, 'This IV is already set to \'undef\'');
        }

        $button->set_image($image);

        # Make the button clickable
        $button->signal_connect('clicked' => sub {

            # Set the IV to undef
            $self->ivAdd('editHash', $iv, undef);

            # Empty the entry to remove any text entered into it, and update its icon
            $entry->set_text('');
            $entry->set_icon_from_stock('secondary', 'gtk-yes');

            # Change the button's image to mark this IV as being set to undef
            my $image2 = Gtk2::Image->new_from_stock('gtk-remove', 'menu');
            $button->set_image($image2);
            # Give the button a new tooltip
            $self->tooltips->set_tip($button, 'This IV is already set to \'undef\'');
        });

        # Respond when the user types something in the box
        $entry->signal_connect('changed' => sub {

            my $text = $entry->get_text();
            $self->ivAdd('editHash', $iv, $text);

            if ($self->checkEntry($text, $mode, $min, $max)) {
                $entry->set_icon_from_stock('secondary', 'gtk-yes');
            } else {
                $entry->set_icon_from_stock('secondary', 'gtk-no');
            }

            # Contents of the entry can't possibly be 'undef' any more
            my $image3 = Gtk2::Image->new_from_stock('gtk-clear', 'menu');
            $button->set_image($image3);
            # Give the button a new tooltip
            $self->tooltips->set_tip($button, 'Click to set this IV to \'undef\'');
        });

        # Add the button to the table (the entry has already been added)
        $table->attach_defaults(
            $button,
            ($rightAttach - 1), $rightAttach, $topAttach, $bottomAttach,
        );

        return $entry;
    }

    sub addComboBox {

        # Adds a Gtk2::ComboBox at the specified position in the window's Gtk2::Table
        #
        # Example calls:
        #   my $comboBox = $self->addComboBox($table, 'some_IV', \@comboList, 'some_title', TRUE,
        #       0, 6, 0, 1);
        #   my $comboBox = $self->addComboBox($table, 'some_IV', \@comboList, '', FALSE,
        #       0, 6, 0, 1);
        #
        # Expected arguments
        #   $table          - The tab's Gtk2::Table object
        #   $iv             - A string naming the IV set when the user chooses an item in the combo
        #                       box. If 'undef', nothing happens when the user chooses an item in
        #                       the box; it's up to the calling function to check the box's state
        #   $listRef        - Reference to a list with initial values (can be an empty list)
        #   $title          - A string used as a title, e.g. 'Choose your favourite colour' - if an
        #                       empty string, the item at the top of the combobox list is the
        #                       current value of the IV
        #   $noUndefFlag    - If set to TRUE, the combo is populated only with the items in
        #                       $listRef. If set to FALSE (or 'undef'), the first item in the combo
        #                       is an empty value used to set the IV to 'undef'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #                   - The position of the combo box in the table
        #
        # Optional arguments
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::ComboBox created

        my (
            $self, $table, $iv, $listRef, $title, $noUndefFlag, $leftAttach, $rightAttach,
            $topAttach, $bottomAttach, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $listRef || ! defined $title || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addComboBox', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Create the combobox
        my $comboBox = Gtk2::ComboBox->new_text();

        # Populate the combobox
        if ($title) {

            # The first item in the combobox list is a title
            $comboBox->append_text($title);
            $comboBox->set_active(0);

        } elsif ($iv) {

            if ($noUndefFlag) {

                if (defined $self->editObj->$iv) {

                    # The first item is the current value of the IV, if there is one
                    $comboBox->append_text($self->editObj->$iv);
                    # Make this the active item
                    $comboBox->set_active(0);
                }

            } else {

                # The first item is an empty line, for setting the IV to 'undef'
                $comboBox->append_text('');

                if (defined $self->editObj->$iv) {

                    # The second item is the current value of the IV, if there is one
                    $comboBox->append_text($self->editObj->$iv);
                    # Make this the active item
                    $comboBox->set_active(1);

                } else {

                    # Make the 'undef' option the active item
                    $comboBox->set_active(0);
                }
            }

        } elsif (! $noUndefFlag) {

            # The first item is an empty line, for setting the IV to 'undef'
            $comboBox->append_text('');
            # Make the 'undef' option the active item
            $comboBox->set_active(0);
        }

        foreach my $item (@$listRef) {

            # Don't show the current value of the IV twice
            if (
                ! $iv
                || ! defined $self->editObj->$iv
                || $item ne $self->editObj->$iv
            ) {
                $comboBox->append_text($item);
            }
        }

        if (! $iv && $noUndefFlag) {

            # The active item hasn't been set yet
            $comboBox->set_active(0);
        }

        if ($iv) {

            $comboBox->signal_connect('changed' => sub {

                my $text = $comboBox->get_active_text();

                # If the user has selected the title, ignore it
                if (! $title || $text ne $title) {

                    # If the user has selected the empty line at the top, set the IV to 'undef'
                    if (! $text) {

                        $self->ivAdd('editHash', $iv, undef);

                    # Otherwise set the IV to the specified value
                    } else {

                        $self->ivAdd('editHash', $iv, $text);
                    }
                }
            });
        }

        # Add the combobox to the table
        $table->attach_defaults($comboBox, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $comboBox;
    }

    sub addTextView {

        # Adds a Gtk2::TextView at the specified position in the window's Gtk2::Table
        #
        # Example calls:
        #   my $textView = $self->addTextView($table, 'some_IV', TRUE,
        #       0, 6, 0, 1);
        #   my $textView = $self->addTextView($table, 'some_IV', FALSE,
        #       0, 6, 0, 1,
        #       TRUE, FALSE, TRUE,
        #       -1, 120);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $iv         - A string naming the IV set when the user modifies the contents of the
        #                   textview. If 'undef', nothing happens when the user modifies the
        #                   contents; it's up to the calling function to check the textview's state
        #   $editableFlag
        #               - Flag set to TRUE if the textView should be editable, FALSE if it shouldn't
        #                   be editable
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the textview in the table
        #
        # Optional arguments
        #   $listFlag   - Flag set to TRUE if the contents of the textview should be treated as a
        #                   list, FALSE (or 'undef') if it should be treated as a single string
        #                   containing newline characters. Default value is TRUE (treat as a list)
        #   $removeEmptyFlag
        #               - Flag set to TRUE if empty lines should be removed when the IV is set,
        #                   FALSE (or 'undef') if they should be retained. Default value is TRUE
        #                   (remove lines)
        #   $removeSpaceFlag
        #               - Flag set to TRUE if lines should have leading/trailing whitespace removed
        #                   when the IV is set, FALSE (or 'undef') if not. Default value is TRUE
        #                   (remove leading/trailing whitespace)
        #   $noScrollFlag
        #               - Flag set to TRUE if word-wrap mode should be turned on, preventing a
        #                   horizontal scrollbar, FALSE (or 'undef') if the textview should scroll
        #                   in both dimensions. Default value is FALSE (scroll in both dimensions)
        #   $width, $height
        #               - The width and height (in pixels) of the frame containing the list. If
        #                   specified, values of -1 mean 'don't set this value'. The default values
        #                   are (-1, 120) - we use a fixed height, because Gtk2 on some operating
        #                   systems will draw a textview barely one line high (in a vertical
        #                   packing box)
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::TextView created (inside a Gtk::ScrolledWindow)

        my (
            $self, $table, $iv, $editableFlag, $leftAttach, $rightAttach, $topAttach, $bottomAttach,
            $listFlag, $removeEmptyFlag, $removeSpaceFlag, $noScrollFlag, $width, $height, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $editableFlag || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addTextView', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Set defaults
        if (! defined $listFlag) {

            $listFlag = TRUE;
        }

        if (! defined $removeEmptyFlag) {

            $removeEmptyFlag = TRUE;
        }

        if (! defined $removeSpaceFlag) {

            $removeSpaceFlag = TRUE;
        }

        if (! defined $width) {

            $width = -1;    # Let Gtk2 set the width
        }

        if (! defined $height) {

            $height = 120;
        }

        # Creating a containing Gtk2::Frame and Gtk2::ScrolledWindow
        my $scroll = Gtk2::ScrolledWindow->new(undef, undef);
        $scroll->set_shadow_type('etched-out');
        $scroll->set_policy('automatic', 'automatic');
        $scroll->set_size_request($width, $height);
        $scroll->set_border_width($self->spacingPixels);

        # Create a textview with default colours/fonts
        $axmud::CLIENT->desktopObj->getTextViewStyle($self->winType);
        my $textView = Gtk2::TextView->new();
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);
        if ($noScrollFlag) {

            $textView->set_wrap_mode('word-char');  # Wrap words if possible, characters if not
            $textView->set_justification('left');
        }

        if ($iv) {

            # Display the existing value of the IV (the call to $buffer->set_text requires a
            #   defined value, so don't try to display 'undef')
            if ($self->editObj->$iv) {

                if ($listFlag) {

                    # The call to ->ivPeek returns the contents of the IV as a flat list
                    $buffer->set_text(join("\n", $self->editObj->ivPeek($iv)));

                } else {

                    $buffer->set_text($self->editObj->$iv);
                }
            }

            $buffer->signal_connect('changed' => sub {

                my (
                    $text,
                    @list, @finalList,
                );

                $text = $axmud::CLIENT->desktopObj->bufferGetText($buffer);

                if ($listFlag) {

                    # Split the contents of the textview into a list of lines, separated by
                    #   newline characters
                    @list = split("\n", $text);
                    # Remove any empty lines and leading/trailing whitespace, if allowed
                    foreach my $line (@list) {

                        if ($line && $removeSpaceFlag) {

                            $line =~ s/^\s+//;  # Remove leading whitespace
                            $line =~ s/\s+$//;  # Remove trailing whitespace
                        }

                        if ($line || ! $removeEmptyFlag) {

                            push (@finalList, $line);
                        }
                    }

                    # Set the IV
                    $self->ivAdd('editHash', $iv, \@finalList);

                } else {

                    # Treat the contents of the IV as a single string
                    $self->ivAdd('editHash', $iv, $text);
                }
            });
        }

        # Make the textview editable or not editable
        $textView->set_editable($editableFlag);

        # Add the textview to the table
        $scroll->add($textView);
        $table->attach_defaults($scroll, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $textView;
    }

    sub addSimpleList {

        # Adds a GA::Gtk::Simple::List at the specified position in the window's Gtk2::Table
        #
        # Example calls:
        #   my $slWidget = $self->addSimpleList($table, 'some_IV', \@columnList,
        #       0, 6, 0, 1);
        #
        # Expected arguments
        #   $table          - The tab's Gtk2::Table object
        #   $iv             - The IV in $self->editObj containing the data being edited. If 'undef',
        #                       the list is not populated with data; it's up to the calling function
        #                       to do it
        #   $columnListRef  - Reference to a list of column headings and types, in the form
        #                       ('heading', 'column_type', 'heading', 'column_type'...)
        #                   - 'column_type' is one of the column types specified by
        #                       GA::Gtk::Simple::List, e.g. 'scalar', 'int'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #                   - The position of the simple list in the table
        #
        # Optional arguments
        #   $width, $height - The width and height (in pixels) of the scroller containing the list.
        #                       If specified, values of -1 mean 'don't set this value'. The default
        #                       values are (-1, 180)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise the GA::Gtk::Simple::List created

        my (
            $self, $table, $iv, $columnListRef, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $width, $height, $check,
        ) = @_;

        # Local variables
        my (
            $refType, $count,
            @columnList,
        );

        # Check for improper arguments
        if (
            ! defined $table || ! defined $columnListRef || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addSimpleList', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Set defaults
        if (! defined $width) {

            $width = -1;    # Let Gtk2 set the width
        }

        if (! defined $height) {

            $height = 180;
        }

        # Dereference the list of columns
        @columnList = @$columnListRef;

        # Add a simple list
        my $frame = Gtk2::Frame->new(undef);
        $frame->set_border_width(0);

        my $scroller = Gtk2::ScrolledWindow->new();
        $frame->add($scroller);
        $scroller->set_shadow_type('none');
        $scroller->set_policy('automatic', 'automatic');
        $scroller->set_border_width(0);
        $scroller->set_size_request($width, $height);

        my $slWidget = Games::Axmud::Gtk::Simple::List->new(@columnList);
        $scroller->add($slWidget);

        # Make the simple list scrollable

        # Fill the columns with data
        if ($iv) {

            $refType = ref $self->editObj->{$iv};

            if ($refType eq 'HASH') {

                # Sort the hash by key, before adding it to the simple list
                $self->resetSortListData($slWidget, [$self->editObj->$iv]);

            } else {

                # Assume that the list/hash IV can be displayed in its current order
                $self->resetListData($slWidget, [$self->editObj->$iv], (scalar @columnList / 2));
            }
        }

        # Make all columns of type 'bool' (which are composed of checkbuttons) non-activatable, so
        #   that the user can't click them on and off
        $count = -1;
        do {

            my $title = shift @columnList;
            my $type = shift @columnList;

            $count++;

            if ($type eq 'bool') {

                my ($cellRenderer) = $slWidget->get_column($count)->get_cell_renderers();
                $cellRenderer->set(activatable => FALSE);
            }

        } until (! @columnList);

        # Add the simple list to the table
        $table->attach_defaults($frame, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $slWidget;
    }

    # Add widgets - special functions for GA::EditWin::Generic::Interface and
    #   GA::EditWin::Interface::Active

    sub useCheckButton {

        # Adapted from $self->addCheckButton
        # Adds a Gtk2::CheckButton at the specified position in the window's Gtk2::Table. Instead of
        #   setting an IV in $self->editHash, sets a key-value pair in $self->attribHash
        #
        # Example calls:
        #   my $checkButton = $self->useCheckButton($table, 'some_attribute', TRUE,
        #       0, 6, 0, 1);
        #   my $checkButton = $self->useCheckButton($table, 'some_attribute', FALSE,
        #       0, 6, 0, 1, 0, 0.5);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $attrib     - The name of the attribute set when the check button is toggled (matches
        #                   a key in $self->attribHash and GA::Interface::Trigger->attribHash)
        #   $stateFlag  - Flag set to FALSE if the checkbutton's state should be 'insensitive',
        #                   TRUE if it should be 'normal'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the checkbutton in the table
        #
        # Optional arguments
        #   $alignX, $alignY
        #               - Used in the call to ->set_alignment; two values in the range 0-1
        #               - If not specified, $alignX is set to 0, $alignY to 0.5
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::CheckButton created

        my (
            $self, $table, $attrib, $stateFlag, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $alignX, $alignY, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $attrib || ! defined $stateFlag || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->useCheckButton', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Set default alignment, if none specified
        if (! defined $alignX) {

            $alignX = 0;
        }

        if (! defined $alignY) {

            $alignY = 0.5;
        }

        # Create the checkbutton
        my $checkButton = Gtk2::CheckButton->new();
        $checkButton->set_active($self->editObj->ivShow('attribHash', $attrib));
        $checkButton->signal_connect('toggled' => sub {

            $self->ivAdd('attribHash', $attrib, $checkButton->get_active());
        });

        # Make the checkbutton insensitive, if $stateFlag is FALSE
        if (! $stateFlag) {

            $checkButton->set_state('insensitive');
        }

        # Set its alignment
        $checkButton->set_alignment($alignX, $alignY);

        # Add the checkbutton to the table
        $table->attach_defaults($checkButton, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $checkButton;
    }

    sub useRadioButton {

        # Adapted from $self->addRadioButton
        # Adds a Gtk2::RadioButton at the specified position in the tab's Gtk2::Table. Instead of
        #   setting an IV in $self->editHash, sets a key-value pair in $self->attribHash
        #
        # Example calls:
        #   my ($group, $button) = $self->useRadioButton(
        #       $table, undef, $name, 'some_attribute', $value, TRUE,
        #       0, 6, 0, 1);
        #   my ($group2, $button2) = $self->useRadioButton(
        #       $table, $group, $name, 'some_attribute', $value, TRUE,
        #       0, 6, 0, 1, 0, 0.5);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $group      - Reference to the radio button group created, when the first button in the
        #                   group was added (if set to 'undef', this is the first button, and a
        #                   group will be created for it)
        #   $name       - A 'name' for the radio button (displayed next to the button); if 'undef',
        #                   no name is displayed
        #   $attrib     - The name of the attribute set when the radio button is toggled (matches
        #                   a key in $self->attribHash and GA::Interface::Trigger->attribHash)
        #   $value      - The value to which the attribute is set, when the radio button is selected
        #   $stateFlag  - Flag set to FALSE if the radiobutton's state should be 'insensitive',
        #                   TRUE if it should be 'normal'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the radiobutton in the table
        #
        # Optional arguments
        #   $alignLeft, $alignRight
        #               - Used in the call to ->set_alignment; two values in the range 0-1
        #               - If not specified, $alignLeft is set to 0, $alignRight to 0.5
        #
        # Return values
        #   An empty list on improper arguments or if the widget's position in the Gtk2::Table is
        #       invalid
        #   Otherwise a list containing two elements: the radio button $group and the
        #       Gtk2::RadioButton created

        my (
            $self, $table, $group, $name, $attrib, $value, $stateFlag, $leftAttach, $rightAttach,
            $topAttach, $bottomAttach, $alignLeft, $alignRight, $check
        ) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $attrib || ! defined $stateFlag || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->useRadioButton', @_);
            return @emptyList;
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return @emptyList;
        }

        # Set default alignment, if none specified
        if (! defined $alignLeft) {

            $alignLeft = 0;
        }

        if (! defined $alignRight) {

            $alignRight = 0.5;
        }

        # Create the radio button
        my $radioButton = Gtk2::RadioButton->new();
        # Add it to the existing group, if one was specified
        if (defined $group) {

            $radioButton->set_group($group);
        }

        # If $value is the one currently stored in $self->editObj->attribHash, mark this radio
        #   button as active
        if (defined $value && $value eq $self->editObj->ivShow('attribHash', $attrib)) {

            $radioButton->set_active(TRUE);
        }

        $radioButton->signal_connect('toggled' => sub {

            # Set the attribute only if this radiobutton has been selected
            if ($radioButton->get_active()) {

                $self->ivAdd('attribHash', $attrib, $value);
            }
        });

        # Give the radio button a name, if one was specified
        if ($name) {

            $radioButton->set_label($name);
        }

        # Make the radio button insensitive, if $stateFlag is FALSE
        if (! $stateFlag) {

            $radioButton->set_state('insensitive');
        }

        # Set radio button's alignment
        $radioButton->set_alignment($alignLeft, $alignRight);

        # Add the radio button to the table
        $table->attach_defaults($radioButton, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return ($radioButton->get_group(), $radioButton);
    }

    sub useEntryWithIcon {

        # Adapted from $self->addEntryWithIcon
        # Adds a Gtk2::Entry at the specified position in the tab's Gtk2::Table. The entry contains
        #   a stock icon to show whether the current contents of the entry is permissible
        # The stock icons used are 'gtk-yes' (for an acceptable value) and 'gtk-no' (for a
        #   forbidden value)
        # Instead of setting an IV in $self->editHash, sets a key-value pair in $self->attribHash
        #
        # Example calls:
        #   my $entry = $self->useEntryWithIcon($table, 'some_attribute', 'int', 0, 1000,
        #       0, 6, 0, 1);
        #   my $entry = $self->useEntryWithIcon($table, 'some_attribute', 'odd', 1, 1001,
        #       0, 6, 0, 1);
        #   my $entry = $self->useEntryWithIcon($table, 'some_attribute', 'even', 0, 1000,
        #       0, 6, 0, 1);
        #   my $entry = $self->useEntryWithIcon($table, 'some_attribute', 'float', 0, 1000000,
        #       0, 6, 0, 1);
        #   my $entry = $self->useEntryWithIcon($table, 'some_attribute', 'string', 3, 16,
        #       0, 6, 0, 1);
        #   my $entry = $self->useEntryWithIcon(
        #       $table, 'some_attribute', \&checkFunction, undef, undef,
        #       0, 6, 0, 1);
        #
        #   my $entry = $self->useEntryWithIcon($table, 'some_attribute', 'int', 0, 1000,
        #       0, 6, 0, 1, 16, 16);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $attrib     - The name of the attribute set when the user modifies the text in the entry
        #                   box
        #   $mode       - Set to 'int', 'odd', 'even', 'float', 'string' or a reference to a
        #                   function
        #               - If 'int', an integer is expected with the specified min/max values
        #               - If 'odd', an odd-numbered integer with the specified min/max value is
        #                   expected. If the minimum value is less than 1, 1 is used instead
        #               - If 'even', an even-numbered integer with the specified min/max value is
        #                   expected. If the minimum value is less than 0, 0 is used instead
        #               - If 'float', a floating point number is expected with the specified min/max
        #                   values
        #               - If 'string', a string is expected (which might be a number) with the
        #                   specified min/max length
        #               - If a function reference, a function is called which should return 'undef'
        #                   or 1, depending on the value of the entry; the icon is set accordingly
        #   $min, $max  - The values described above (ignored when $mode is a function reference).
        #                   If $min is 'undef', there is no minimum; if $max is 'undef', there is no
        #                   maximum
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the entry in the table
        #
        # Optional arguments
        #   $widthChars - The width of the box, in chars ('undef' if maximum not needed)
        #   $maxChars   - The maximum no. chars allowed in the box ('undef' if maximum not needed)
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Entry created

        my (
            $self, $table, $attrib, $mode, $min, $max, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $widthChars, $maxChars, $check
        ) = @_;

        # Local variables
        my $current;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $attrib || ! defined $mode || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->useEntryWithIcon', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Check that the minimum/maximum values specified are valid and, if not, fix them
        if (defined $min && defined $max && $min > $max) {

            # Use no maximum value...
            $max = undef;
            # ...and show a warning, because this shouldn't happen
            $self->session->writeWarning(
                'Minimum greater than maximum for attribute \'' . $attrib . '\'',
                $self->_objClass . '->addEntryWithIcon',
            );
        }

        if ($mode eq 'odd' && defined $min && $min < 1) {

            # Lowest value of $min (if specified) is 1
            $min = 1;

        } elsif ($mode eq 'even' && defined $min && $min < 0) {

            # Lowest value of $min (if specified) is 0
            $min = 0;
        }

        # Create the entry
        my $entry = Gtk2::Entry->new();

        # Display the existing value of the attribute
        $current = $self->editObj->ivShow('attribHash', $attrib);
        if (defined $current) {

            $entry->append_text($current);

            if (! $self->checkEntry($current, $mode, $min, $max)) {
                $entry->set_icon_from_stock('secondary', 'gtk-no');
            } else {
                $entry->set_icon_from_stock('secondary', 'gtk-yes');
            }

        } else {

            # We still need to set the icon for an empty box
            if ($mode eq 'string') {

                # Empty strings might be acceptable
                if (! $self->checkEntry('', $mode, $min, $max)) {
                    $entry->set_icon_from_stock('secondary', 'gtk-no');
                } else {
                    $entry->set_icon_from_stock('secondary', 'gtk-yes');
                }

            } else {

                # Box is empty, so any $self->checkEntry test will fail (for $mode
                #   set to a function reference, we'll have to assume that)
                $entry->set_icon_from_stock('secondary', 'gtk-no');
            }
        }

        # Customise the entry
        $entry->signal_connect('changed' => sub {

            my $value = $entry->get_text();
            # Check whether $value is a valid value, or not
            if (! $self->checkEntry($value, $mode, $min, $max)) {

                # Can't use this value
                $self->ivDelete('attribHash', $attrib);
                $entry->set_icon_from_stock('secondary', 'gtk-no');

            } else {

                # This is a valid value, so use it
                $self->ivAdd('attribHash', $attrib, $value);
                $entry->set_icon_from_stock('secondary', 'gtk-yes');
            }
        });

        # Set the width, if specified
        if (defined $widthChars) {

            $entry->set_width_chars($widthChars);
        }

        # Set the maximum number of characters, if specified
        if (defined $maxChars) {

            $entry->set_max_length($maxChars);
        }

        # Add the entry to the table
        $table->attach_defaults($entry, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $entry;
    }

    sub useComboBox {

        # Adapted from $self->addComboBoxs
        # Adds a Gtk2::ComboBox at the specified position in the window's Gtk2::Table. Instead of
        #   setting an IV in $self->editHash, sets a key-value pair in $self->attribHash
        #
        # Example calls:
        #   my $comboBox = $self->useComboBox($table, 'some_attribute', \@comboList, 'some_title',
        #       0, 6, 0, 1);
        #   my $comboBox = $self->useComboBox($table, 'some_attribute', \@comboList, '',
        #       0, 6, 0, 1);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $attrib     - The name of the attribute set when the check button is toggled (matches
        #                   a key in $self->attribHash and GA::Interface::Trigger->attribHash)
        #   $listRef    - Reference to a list with initial values (can be an empty list)
        #   $title      - A string used as a title, e.g. 'Choose your favourite colour' - if an
        #                   empty string, the item at the top of the combobox list is the current
        #                   value of the attribute
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the combo box in the table
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::ComboBox created

        my (
            $self, $table, $attrib, $listRef, $title, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $check
        ) = @_;

        # Local variables
        my $current;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $attrib || ! defined $listRef || ! defined $title
            || ! defined $leftAttach || ! defined $rightAttach || ! defined $topAttach
            || ! defined $bottomAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->useComboBox', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Create the combobox
        my $comboBox = Gtk2::ComboBox->new_text();

        # Populate the combobox
        if ($title) {

            # The first item in the combobox list is a title
            $comboBox->append_text($title);
            $comboBox->set_active(0);

        } else {

            $current = $self->editObj->ivShow('attribHash', $attrib);
            if ($current) {

                # The first item is the current value of the IV, if there is one
                $comboBox->append_text($current);
                # Make this the active item
                $comboBox->set_active(0);
            }
        }

        foreach my $item (@$listRef) {

            # Don't show the current value of the IV twice
            if (! $current || $item ne $current) {

                $comboBox->append_text($item);
            }
        }

        $comboBox->signal_connect('changed' => sub {

            my $text = $comboBox->get_active_text();

            # If the user has selected the title, ignore it
            if (! $title || $text ne $title) {

                # If the user has selected the empty line at the top, set the attribute to an
                #   empty string
                if (! $text) {

                    $self->ivAdd('attribHash', $attrib, '');

                # Otherwise set the attribute to the specified value
                } else {

                    $self->ivAdd('attribHash', $attrib, $text);
                }
            }
        });

        # Add the combobox to the table
        $table->attach_defaults($comboBox, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $comboBox;
    }

    # Add widget support functions

    sub checkEntry {

        # Called by $self->addEntryWithIcon
        # Check whether the text entered in an entry box is a valid value for the IV, or not
        #
        # Expected arguments
        #   $value      - The value currently in the entry box
        #   $mode       - Set to 'int', 'odd', 'even', 'float', 'string' or a reference to a
        #                   function
        #               - If 'int', an integer is expected with the specified min/max values
        #               - If 'odd', an odd-numbered integer with the specified min/max value is
        #                   expected. If the minimum value is less than 1, 1 is used instead
        #               - If 'even', an even-numbered integer with the specified min/max value is
        #                   expected. If the minimum value is less than 0, 0 is used instead
        #               - If 'float', a floating point number is expected with the specified min/max
        #                   values
        #               - If 'string', a string is expected (which might be a number) with the
        #                   specified min/max length
        #               - If a function reference, a function is called which should return 'undef'
        #                   or 1, depending on the value of the entry; the icon is set accordingly
        #   $min, $max  - The values described above (ignored when $mode is a function reference).
        #                   If $min is 'undef', there is no minimum; if $max is 'undef', there is no
        #                   maximum
        #
        # Return values
        #   'undef' on improper arguments or if $value is an invalid value for the IV
        #   1 if $value is a valid value for the IV

        my ($self, $value, $mode, $min, $max, $check) = @_;

        # Local variables
        my $result;

        # Check for improper arguments
        if (! defined $value || ! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkEntry', @_);
        }

        # 'int' mode
        if ($mode eq 'int') {

            if (
                ! defined $value
                || $value eq ''     # Required for $entry->set_text('');
                || ! ($value =~ m/^\-?\d+$/)
                || (defined $min && $value < $min)
                || (defined $max && $value > $max)
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }

        # 'odd' mode
        } elsif ($mode eq 'odd') {

            if (
                ! defined $value
                || $value eq ''     # Required for $entry->set_text('');
                || ! ($value =~ m/^\-?\d+$/)
                || (defined $min && $value < $min)
                || (defined $max && $value > $max)
                || ! ($value % 2)   # Number is even
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }

        # 'even' mode
        } elsif ($mode eq 'even') {

            if (
                ! defined $value
                || $value eq ''     # Required for $entry->set_text('');
                || ! ($value =~ m/^\-?\d+$/)
                || (defined $min && $value < $min)
                || (defined $max && $value > $max)
                || ! ($value % 2)   # Number is even
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }

        # 'float' mode
        } elsif ($mode eq 'float') {

            if (
                ! defined $value
                || $value eq ''     # Required for $entry->set_text('');
                || ! ($value =~ /^[+-]?\d+\.?\d*$/)
                || (defined $min && $value < $min)
                || (defined $max && $value > $max)
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }

        # 'string' mode
        } elsif ($mode eq 'string') {

            if (
                ! defined $value
                || (defined $min && length($value) < $min)
                || (defined $max && length($value) > $max)
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }

        # $mode must be a function reference. Call the function so it can check $value and
        #   return 'undef' or 1
        } else {

            return &$mode($self, $value);
        }
    }

    sub checkEntryIcon {

        # Called by the same function that called $self->addEntryWithIcon
        # When it's time to do something with the data entered, instead of having to call
        #   $self->checkEntry for every entry box, we can just look at the icon
        # This function checks a list of Gtk2::Entry boxes and returns 1 if they are all showing the
        #   'gtk-ok' icon (meaning the values entered are acceptable)
        #
        # Expected arguments
        #   @list   - List of Gtk2::Entry boxes
        #
        # Return values
        #   'undef' on improper arguments, or if any of the entry boxes are using the 'gtk-no' icon
        #       (meaning the value entered isn't acceptable) or if anything in @list is 'undef'
        #   1 if all the entry boxes are using the 'gtk-yes' icon (meaning the values entered are
        #       all acceptable)

        my ($self, @list) = @_;

        # Check for improper arguments
        if (! @list) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkEntryIcon', @_);
        }

        foreach my $entry (@list) {

            # Check that the calling function didn't specify $entry4 when it meant to specify
            #   $entry3
            if (! defined $entry) {

                return $self->writeError(
                    'Undefined entry box',
                    $self->_objClass . '->checkEntryIcon',
                );

            } elsif ($entry->get_icon_stock('secondary') ne 'gtk-yes') {

                return undef;
            }
        }

        # All values acceptable for this IV
        return 1;
    }

    sub setEntryIcon {

        # Called by the same function that called $self->addEntryWithIcon
        # If we need to manually change the entry's icon for some reason, this function can be
        #   called
        # For example, if ->addEntryWithIcon is called with a function reference which sets the icon
        #   every time the entry's text is changed, no IV is specified but we want an empty entry
        #   box to be an acceptable value, this function can take care of it
        #
        # Expected arguments
        #   $entry      - The Gtk2::Entry whose icon should be modified
        #   $flag       - TRUE to use 'gtk-yes' (representing an acceptable value), FALSE to use
        #                   'gtk-no' (representing an unacceptable value)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $entry, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $entry || ! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setEntryIcon', @_);
        }

        if (! $flag) {
            $entry->set_icon_from_stock('secondary', 'gtk-no');
        } else {
            $entry->set_icon_from_stock('secondary', 'gtk-yes');
        }

        return 1;
    }

    sub resetEntryBoxes {

        # Empties the contents of any entry boxes appearing in a list of Gtk2 widgets, ignoring any
        #   other widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @list   - List of Gtk2 widgets (can be an empty list)
        #
        # Return values
        #   'undef' on improper arguments or if anything in @list is 'undef'
        #   1 otherwise

        my ($self, @list) = @_;

        # (No improper arguments to check)

        foreach my $widget (@list) {

            # Check that the calling function didn't specify $entry4 when it meant to specify
            #   $entry3
            if (! defined $widget) {

                return $self->writeError(
                    'Undefined widget',
                    $self->_objClass . '->resetEntryBoxes',
                );

            } elsif ($widget->isa('Gtk2::Entry')) {

                $widget->set_text('');
            }
        }

        return 1;
    }

    sub addSimpleListButtons_listIV {

        # Adds four standard buttons used with GA::Gtk::Simple::List widgets, when they're
        #   displaying a list IV. The buttons are 'Add', 'Delete', 'Reset' and 'Clear'
        # NB The ->signal_connect method for the 'Add' button must be specified by the calling
        #   function
        #
        # Example calls:
        #   my $addButton = $self->addSimpleListButtons_listIV($table, $slWidget, 'some_IV', 10);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $slWidget   - The GA::Gtk::Simple::List object on which the buttons will act
        #   $iv         - The list IV in $self->editObj storing the data being edited
        #   $rowNumber  - On the current tab's table, the row on which the buttons are put
        #   $columns    - The number of columns. For a straightforward list, 1, but many IVs
        #                   (particularly in profiles) have list IVs with data in groups of two,
        #                   three or more
        #
        # Optional arguments
        #   @widgetList - List of Gtk2 widgets (entry boxes or combos) that are reset when the
        #                   'Delete', 'Reset' and 'Clear' buttons are used. If the list is empty, no
        #                   widgets are reset
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the Gtk::Button labelled 'Add', so the calling function can add a
        #       ->signal_connect to it

        my ($self, $table, $slWidget, $iv, $rowNumber, $columns, @widgetList) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $slWidget || ! defined $iv || ! defined $rowNumber
            || ! defined $columns
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->addSimpleListButtons_listIV',
                @_,
            );
        }

        # 'Add' button
        my $button = Gtk2::Button->new('Add');
        $self->tooltips->set_tip($button, 'Add new value(s)');
        $table->attach_defaults($button, 1, 3, $rowNumber, ($rowNumber + 1));

        # NB The signal_connect method for the 'Add' button must be specified by the callling
        #   function. Here is some example code:
        #
        #   $button->signal_connect('clicked' => sub {
        #
        #       my ($pattern, $backRef);
        #
        #       $pattern = $entry->get_text();
        #       $backRef = $entry2->get_text();
        #
        #       if ($self->checkEntryIcon($entry, $entry2)) {
        #
        #           # Add new values to (the end of) the list IV
        #           $self->addEditHash_listIV('myListIV',
        #               undef, FALSE,
        #               $pattern, $backRef,
        #           );
        #
        #           # Refresh the simple list and reset entry boxes
        #           $self->refreshList_listIV(
        #               $slWidget,
        #               scalar (@columnList / 2),
        #               'myListIV',
        #           );
        #
        #           $self->resetEntryBoxes($entry, $entry2);
        #       }
        #   });

        # 'Delete' button
        my $button2 = Gtk2::Button->new('Delete');
        $button2->signal_connect('clicked' => sub {

            # Get the selected row
            my ($index) = $slWidget->get_selected_indices();
            if (defined $index) {

                # Delete the value (or values) on this row
                $self->deleteEditHash_listIV($iv, ($index * $columns), $columns);

                # Refresh the simple list and reset entry boxes
                $self->refreshList_listIV($slWidget, $columns, $iv);
                $self->resetEntryBoxes(@widgetList);
            }
        });
        $self->tooltips->set_tip($button2, 'Delete the selected value(s)');
        $table->attach_defaults($button2, 6, 8, $rowNumber, ($rowNumber + 1));

        # 'Reset' button
        my $button3 = Gtk2::Button->new('Reset');
        $button3->signal_connect('clicked' => sub {

            # Remove this IV from $self->editHash, so that the IV in $self->editObj takes over
            $self->ivDelete('editHash', $iv);

            # Refresh the simple list and reset entry boxes
            $self->refreshList_listIV($slWidget, $columns, $iv);
            $self->resetEntryBoxes(@widgetList);
        });
        $self->tooltips->set_tip($button3, 'Reset the list');
        $table->attach_defaults($button3, 8, 10, $rowNumber, ($rowNumber + 1));

        # 'Clear' button
        my $button4 = Gtk2::Button->new('Clear');
        $button4->signal_connect('clicked' => sub {

            # Add an empty list to $self->editHash
            $self->ivAdd('editHash', $iv, []);

            # Refresh the simple list and reset entry boxes
            $self->refreshList_listIV($slWidget, $columns, $iv);
            $self->resetEntryBoxes(@widgetList);
        });
        $self->tooltips->set_tip($button4, 'Clear the list of values');
        $table->attach_defaults($button4, 10, 12, $rowNumber, ($rowNumber + 1));

        return $button;
    }

    sub addSimpleListButtons_hashIV {

        # Adds four standard buttons used with GA::Gtk::Simple::List widgets, when they're
        #   displaying a hash IV. The buttons are 'Add', 'Delete', 'Reset' and 'Clear'
        # NB The ->signal_connect method for the 'Add' button must be specified by the calling
        #   function
        #
        # Example calls:
        #   my $addButton = $self->addSimpleListButton_hashIV($table, $slWidget, 'someIV', 10);
        #
        # Expected arguments
        #   $table      - The tab's Gtk2::Table object
        #   $slWidget   - The GA::Gtk::Simple::List object on which the buttons will act
        #   $iv         - The hash IV in $self->editObj storing the data being edited
        #   $rowNumber  - On the current tab's table, the row on which the buttons are put
        #
        # Optional arguments
        #   @widgetList - List of Gtk2 widgets (entry boxes or combos) that are reset when the
        #                   'Delete', 'Reset' and 'Clear' buttons are used. If the list is empty, no
        #                   widgets are reset
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise the Gtk::Button labelled 'Add', so the calling function can add a
        #       ->signal_connect to it

        my ($self, $table, $slWidget, $iv, $rowNumber, @widgetList) = @_;

        # Check for improper arguments
        if (! defined $table || ! defined $slWidget || ! defined $iv || ! defined $rowNumber) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->addSimpleListButtons_hashIV',
                @_,
            );
        }

        # 'Add' button
        my $button = Gtk2::Button->new('Add');
        $self->tooltips->set_tip($button, 'Add a new key/value pair');
        $table->attach_defaults($button, 1, 3, $rowNumber, ($rowNumber + 1));

        # NB The signal_connect method for the 'Add' button must be specified by the callling
        #   function. Here is some example code:
        #   $button->signal_connect('clicked' => sub {
        #
        #       my ($key, $value);
        #
        #       $key = $entry->get_text();
        #       $value = $entry2->get_text();
        #
        #       if ($self->checkEntryIcon($entry, $entry2)) {
        #
        #           # Add a new key-value pair
        #           $self->modifyEditHash_hashIV('myHashIV', $key, $value);
        #
        #           # Refresh the simple list and reset entry boxes
        #           $self->refreshList_hashIV($slWidget, scalar (@columnList / 2), 'myHashIV');
        #           $self->resetEntryBoxes($entry, $entry2);
        #       }
        #   });

        # 'Delete' button
        my $button2 = Gtk2::Button->new('Delete');
        $button2->signal_connect('clicked' => sub {

            my ($key) = $self->getSimpleListData($slWidget, 0);
            if (defined $key) {

                # Delete the key-value pair from the hash
                $self->modifyEditHash_hashIV($iv, $key, undef, TRUE);

                # Refresh the simple list and reset entry boxes
                $self->refreshList_hashIV($slWidget, 2, $iv);
                $self->resetEntryBoxes(@widgetList);
            }
        });
        $self->tooltips->set_tip($button2, 'Delete the selected key/value pair');
        $table->attach_defaults($button2, 6, 8, $rowNumber, ($rowNumber + 1));

        # 'Reset' button
        my $button3 = Gtk2::Button->new('Reset');
        $button3->signal_connect('clicked' => sub {

            # Remove this IV from $self->editHash, so that the IV in $self->editObj takes over
            $self->ivDelete('editHash', $iv);

            # Refresh the simple list and reset entry boxes
            $self->refreshList_hashIV($slWidget, 2, $iv);
            $self->resetEntryBoxes(@widgetList);
        });
        $self->tooltips->set_tip($button3, 'Reset the hash of key/value pairs');
        $table->attach_defaults($button3, 8, 10, $rowNumber, ($rowNumber + 1));

        # 'Clear' button
        my $button4 = Gtk2::Button->new('Clear');
        $button4->signal_connect('clicked' => sub {

            # Add an empty hash to $self->editHash
            $self->ivAdd('editHash', $iv, {});

            # Refresh the simple list and reset entry boxes
            $self->refreshList_hashIV($slWidget, 2, $iv);
            $self->resetEntryBoxes(@widgetList);
        });
        $self->tooltips->set_tip($button4, 'Clear the hash of key/value pairs');
        $table->attach_defaults($button4, 10, 12, $rowNumber, ($rowNumber + 1));

        return $button;
    }

    sub refreshList_listIV {

        # Standard function for refreshing (or initialising) GA::Gtk::Simple::List widgets when they
        #   are displaying a list in two columns
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List
        #   $columns    - The number of columns. Should be 2; this argument is retained for
        #                   consistency with other functions
        #   $iv         - The IV being displayed in the simple list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $iv, $check) = @_;

        # Local variables
        my (
            $listRef, $row, $column,
            @ivList, @newList, @sortedList, @dataList,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || ! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->refreshList_listIV', @_);
        }

        # Import the list being displayed
        if (defined $self->ivShow('editHash', $iv)) {

            # Use the current hash
            $listRef = $self->ivShow('editHash', $iv);
            @ivList = @$listRef;

        } else {

            # Use the original hash
            @ivList = $self->editObj->ivPeek($iv);
        }

        # Sort the list. If there is only one column, it's a straightforward sort; otherwise, we
        #   have to convert @ivList into a two-dimensional list, in the form
        #   $newList[row_number][column_number], and sort by columns
        if ($columns == 1) {

            # Straightforward sort
            @dataList = sort {lc($a) cmp lc($b)} (@ivList);

        } else {

            # Don't bother sorting, if there's only one row, if there are more than 2 columns or if
            #   the IV name doesn't end in 'Hash'
            if (scalar @ivList > $columns && $columns == 2 && (substr($iv, -4) eq 'Hash')) {

                # Convert @ivList into a 2-dimensional list
                $row = -1;
                do {

                    $row++;
                    $newList[$row] = [splice (@ivList, 0, $columns)];

                } until (! @ivList);

                # Sort by the first column
                @sortedList = sort {lc($$a[0]) cmp lc($$b[0])} (@newList);

                # Flatten @newList into a 1-dimensional list, row by row
                foreach my $rowRef (@sortedList) {

                    push (@dataList, @$rowRef);
                }

            } else {

                # Only one row, or too many columns to sort
                push (@dataList, @ivList);
            }
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub refreshList_hashIV {

        # Standard function for refreshing (or initialising) GA::Gtk::Simple::List widgets, when
        #   they're displaying a hash in two columns
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List
        #   $columns    - The number of columns. Should be 2; this argument is retained for
        #                   consistency with other functions
        #   $iv         - The IV being displayed in the simple list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $iv, $check) = @_;

        # Local variables
        my (
            $hashRef,
            @sortedList, @dataList,
            %ivHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || ! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->refreshList_hashIV', @_);
        }

        # Import the hash being displayed
        if (defined $self->ivShow('editHash', $iv)) {

            # Use the current hash
            $hashRef = $self->ivShow('editHash', $iv);
            %ivHash = %$hashRef;

        } else {

            # Use the original hash
            %ivHash = $self->editObj->ivPeek($iv);
        }

        # Get a sorted list of keys, so they can be displayed in alphabetical order
        @sortedList = sort {lc($a) cmp lc($b)} (keys %ivHash);

        # Compile the simple list data
        foreach my $key (@sortedList) {

            push (@dataList, $key, $ivHash{$key});
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub checkPosn {

        # Called by functions like $self->addEntry, etc
        # Checks the position of a widget in the tab's table, to make sure the coordinates make
        #   sense (that the right coordinate isn't lower than the left coordinate, for example)
        #
        # Expected arguments
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #       - The coordinates of the object in the tab's table
        #
        # Return values
        #   'undef' on improper arguments or if the coordinates don't make sense
        #   1 otherwise

        my ($self, $leftAttach, $rightAttach, $topAttach, $bottomAttach, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $leftAttach || ! defined $rightAttach || ! defined $topAttach
            || ! defined $bottomAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkPosn', @_);
        }

        # Check coordinates
        if (
            $leftAttach < 0 || $topAttach < 0
            || $rightAttach <= $leftAttach || $bottomAttach <= $topAttach
        ) {
            return $self->writeWarning(
                'Bad table coordinates in \'' . $self->winType . '\' window: '
                . $leftAttach . ' '
                . $rightAttach . ' '
                . $topAttach . ' '
                . $bottomAttach,
                $self->_objClass . '->checkPosn',
            );

        } else {

            return 1;
        }
    }

    sub resetComboBox {

        # Can be called by anything
        # Resets the contents of a combo box
        #
        # Expected arguments
        #   $combo      - The combo box to reset
        #
        # Optional arguments
        #   @comboList  - List of items to add to the combo box. If the list is empty, the combo
        #                   box is emptied
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $combo, @comboList) = @_;

        # Check for improper arguments
        if (! defined $combo) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetComboBox', @_);
        }

        # Empty the combobox
        my $treeModel = $combo->get_model();
        $treeModel->clear();

        # Fill it with the new list of items
        if (@comboList) {

            foreach my $item (@comboList) {

                $combo->append_text($item);
            }

            $combo->set_active(0);
        }

        return 1;
    }

    # Data accessors

    sub resetListData {

        # Replaces the data stored in a GA::Gtk::Simple::List with the data stored in the specified
        #   list
        #
        # Expected arguments
        #   $slWidget   - Reference to a GA::Gtk::Simple::List
        #   $listRef    - Reference to a list which contains the replacement data
        #   $number     - The list is split into groups (e.g. the elements of
        #                   GA::Profile::World->barPatternList are split into groups of 6); $number
        #                   is the size of the group (6 in that example)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $listRef, $number, $check) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $listRef || ! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetListData_listIV', @_);
        }

        if (@$listRef) {

            # Insert the replacement data
            do {

                my @groupList;

                for (my $count = 0; $count < $number; $count++) {

                    push (@groupList, shift @$listRef);
                }

                push (@dataList, \@groupList);

            } until (! @$listRef);

            @{$slWidget->{data}} = @dataList;

        } else {

            # Replacement data list is empty
            @{$slWidget->{data}} = ();
        }

        return 1;
    }

    sub resetSortListData {

        # Replaces the data stored in a GA::Gtk::Simple::List with the data stored in the specified
        #   list which we assume represents a hash in the form (key, value, key, value...)
        #
        # Expected arguments
        #   $slWidget   - Reference to a GA::Gtk::Simple::List
        #   $listRef    - Reference to a list which contains the replacement data
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $listRef, $check) = @_;

        # Local variables
        my (
            @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $listRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetSortListData', @_);
        }

        if (@$listRef) {

            # Assuming the contents of the list reference contains a hash flattened into a list,
            #   convert that data to a hash
            %hash = @$listRef;

            # Insert the replacement data
            foreach my $key (sort {lc($a) cmp lc($b)} (keys %hash)) {

                push (@dataList, [$key, $hash{$key}]);
            }

            @{$slWidget->{data}} = @dataList;

        } else {

            # Replacement data list is empty
            @{$slWidget->{data}} = ();
        }

        return 1;
    }

    sub getSimpleListData {

        # Get items of data from specified cells in the currently selected row of a simple list
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List
        #   @columnList - A list of column numbers on the simple list, e.g. the list (0, 2, 3)
        #                   represents the first, third and fourth columns.
        #
        # Return values
        #   An empty list on improper arguments or if no row in the simple list is currently
        #       selected
        #   Otherwise, returns a list containing the items of data on the selected row, in the
        #       specified columns

        my ($self, $slWidget, @columnList) = @_;

        # Local variables
        my (
            $index, $rowRef,
            @emptyList, @dataList,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! @columnList) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getSimpleListData', @_);
            return @emptyList;
        }

        # Get the currently selected row's number (if any)
        ($index) = $slWidget->get_selected_indices();
        if (defined $index) {

            # Get the selected row itself
            $rowRef = ${$slWidget->{data}}[$index];

            # Get items of data from this row
            foreach my $column (@columnList) {

                push (@dataList, $$rowRef[$column]);
            }
        }

        return @dataList;
    }

    sub getEditHash_scalarIV {

        # Can be called by anything
        # $self->editHash can contain scalar values, in the form
        #   $hash{'name_of_iv'} = scalar_value
        # This function can be called to return the scalar value. However, if the IV hasn't yet been
        #   added to $self->editHash, this function returns the contents of the IV in
        #   $self->editObj, instead
        #
        # Expected arguments
        #   $iv - The IV to be checked; a key in $self->editHash or an IV in $self->editObj
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns a scalar value (may be 'undef'

        my ($self, $iv, $check) = @_;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getEditHash_listIV', @_);
        }

        # Check the specified IV actually exists in $self->editHash
        if (! $self->ivExists('editHash', $iv)) {

            # It doesn't, so return the contents of the list IV, instead
            return $self->editObj->$iv;

        } else {

            return $self->ivShow('editHash', $iv);
        }
    }

    sub getEditHash_listIV {

        # Can be called by anything
        # $self->editHash can contain lists, in the form
        #   $hash{'name_of_iv'} = reference_to_anonymous_list
        # This function can be called to return the contents of the dereferenced list. However, if
        #   the IV hasn't yet been added to $self->editHash, this function returns the contents of
        #   the IV in $self->editObj, instead
        #
        # Expected arguments
        #   $iv - The IV to be checked; a key in $self->editHash or an IV in $self->editObj
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list of values (might be empty)

        my ($self, $iv, $check) = @_;

        # Local variables
        my (
            $listRef,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getEditHash_listIV', @_);
            return @emptyList;
        }

        # Check the specified IV actually exists in $self->editHash
        if (! $self->ivExists('editHash', $iv)) {

            # It doesn't, so return the contents of the list IV, instead
            return $self->editObj->$iv;

        } else {

            $listRef = $self->ivShow('editHash', $iv);
            return @$listRef;
        }
    }

    sub getEditHash_hashIV {

        # Can be called by anything
        # $self->editHash can contain hashes, in the form
        #   $hash{'name_of_iv'} = reference_to_anonymous_hash
        # This function can be called to return the contents of the dereferenced hash as a list.
        #   However, if the IV hasn't yet been added to $self->editHash, this function returns the
        #   contents of the IV in $self->editObj, instead
        #
        # Expected arguments
        #   $iv - The IV to be checked; a key in $self->editHash or an IV in $self->editObj
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a hash of values (as a flat list, which might be empty)

        my ($self, $iv, $check) = @_;

        # Local variables
        my (
            $hashRef,
            @list, @emptyList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getEditHash_hashIV', @_);
            return @emptyList;
        }

        # Check the specified IV actually exists in $self->editHash
        if (! $self->ivExists('editHash', $iv)) {

            # It doesn't, so return the contents of the hash IV, instead
            return $self->editObj->$iv;

        } else {

            $hashRef = $self->ivShow('editHash', $iv);
            return %$hashRef;
        }
    }

    sub addEditHash_listIV {

        # Can be called by anything
        # Adds a value (or group of values) to a list IV, and saves the whole list IV
        # If this IV hasn't been modified yet - i.e., if it is stored in $self->editObj but not in
        #   $self->editHash, the list is copied from $self->editObj, modified, then saved to
        #   $self->editHash
        #
        # Expected arguments
        #   $iv         - The IV to be checked; a key in $self->editHash or an IV in $self->editObj
        #   $index      - The index at which to insert the value (or group of values). If 0, the
        #                   value(s) are inserted at the the start of the list (equivalent to
        #                   'unshift'). If 'undef', the value(s) are inserted at the end of the
        #                   list (equivalent to 'push')
        #   $replaceFlag
        #               - If set to TRUE, the value(s) at $index (and onwards) are replaced. If set
        #                   to FALSE, the value(s) are inserted at this point
        #   @valueList  - The value(s) to add to the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $index, $replaceFlag, @valueList) = @_;

        # Local variables
        my @ivList;

        # Check for improper arguments
        if (! defined $iv || ! defined $replaceFlag || ! @valueList) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addEditHash_listIV', @_);
        }

        # Import the list from $self->editHash if it's there, or the original list from
        #   $self->editObj otherwise
        @ivList = $self->getEditHash_listIV($iv);

        if ($replaceFlag && defined $index) {

            # Replace existing values
            for (my $count = $index; $count < ($index + scalar @valueList); $count++) {

                $ivList[$count] = shift @valueList;
            }

        } elsif (! $replaceFlag && defined $index) {

            # Add value(s) at the insertion point
            splice(@ivList, $index, 0, @valueList);

        } else {

            # ($index not defined)
            # Add values to the end of the list
            push (@ivList, @valueList);
        }

        # Save the modified list
        $self->ivAdd('editHash', $iv, \@ivList);

        return 1;
    }

    sub deleteEditHash_listIV {

        # Can be called by anything
        # Deletes a value (or group of values) from a list IV, and saves the whole list IV
        # If this IV hasn't been modified yet - i.e., if it is stored in $self->editObj but not in
        #   $self->editHash, the list is copied from $self->editObj, modified, then saved to
        #   $self->editHash
        #
        # Expected arguments
        #   $iv     - The IV to be checked; a key in $self->editHash or an IV in $self->editObj
        #   $index  - The index at which to remove the value (or group of values). If 0, the
        #               value(s) are deleted from the the start of the list (equivalent to 'shift').
        #               If 'undef', the value(s) are deleted the end of the list (roughly equivalent
        #               to 'pop').
        #   $number - The number of values to delete (usually 1)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $index, $number, $check) = @_;

        # Local variables
        my @ivList;

        # Check for improper arguments
        if (! defined $iv || ! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteEditHash_listIV', @_);
        }

        # Import the list from $self->editHash if it's there, or the original list from
        #   $self->editObj otherwise
        @ivList = $self->getEditHash_listIV($iv);

        if (defined $index) {

            splice(@ivList, $index, $number);

        } else {

            # Delete values from the end of a list
            splice(@ivList, ($index * -1), $number);
        }

        # Save the modified list
        $self->ivAdd('editHash', $iv, \@ivList);

        return 1;
    }

    sub modifyEditHash_hashIV {

        # Can be called by anything
        # Adds (or replaces) a single key-value pair in a hash IV, and saves the whole hash IV
        # If this IV hasn't been modified yet - i.e., if it is stored in $self->editObj but not in
        #   $self->editHash, the hash is copied from $self->editObj, modified, then saved to
        #   $self->editHash
        #
        # Expected arguments
        #   $iv             - The IV to be checked; a key in $self->editHash or an IV in
        #                       $self->editObj
        #   $key, $value    - The key/value pair to replace ($value can be 'undef')
        #
        # Optional arguments
        #   $deleteFlag     - If set to TRUE, the key-value pair is deleted from the hash ($value is
        #                       ignored, and should be set to 'undef')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $key, $value, $deleteFlag, $check) = @_;

        # Local variables
        my %ivHash;

        # Check for improper arguments
        if (! defined $iv || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->modifyEditHash_hashIV', @_);
        }

        # Import the hash from $self->editHash if it's there, or the original hash from
        #   $self->editObj otherwise
        if ($self->ivExists('editHash', $iv)) {
            %ivHash = $self->getEditHash_hashIV($iv);
        } else {
            %ivHash = $self->editObj->$iv;
        }

        if ($deleteFlag) {

            # Delete the key-value pair
            if (exists $ivHash{$key}) {

                delete $ivHash{$key};
            }

        } else {

            # Add the key-value pair
            $ivHash{$key} = $value;
        }

        # Save the modified hash
        $self->ivAdd('editHash', $iv, \%ivHash);

        return 1;
    }

    sub updateListDataWithKey {

        # Can be called by any tab function to update the data in a GA::Gtk::Simple::List when it is
        #   storing data in two columns representing the contents of a hash
        # The first column is the key, the second column its corresponding value
        # If the key already exists in the list, it is replaced; otherwise a new key-value pair is
        #   added to the simple list
        # If the key is not defined or an empty string, it isn't added to the simple list
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List to modify
        #   $key        - The key to add to the list, which will eventually be stored as a hash
        #   $value      - Its corresponding value
        #
        # Return values
        #   'undef' on improper arguments, or if $key is 'undef' or an empty string
        #   1 otherwise

        my ($self, $slWidget, $key, $value, $check) = @_;

        # Local variables
        my (
            @list,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateListDataWithKey', @_);
        }

        # If $key is 'undef' or an empty string, do nothing
        if (! $key) {

            return undef;
        }

        # Convert the data stored in the GA::Gtk::Simple::List into a hash
        %hash = $self->convertListDataToHash($slWidget);

        # Add the key-value pair
        $hash{$key} = $value;

        # Get a list of keys in the hash, so we can sort it alphabetically
        @list = sort {lc($a) cmp lc($b)} (keys %hash);

        # Reset the GA::Gtk::Simple::List
        @{$slWidget->{data}} = ();

        foreach my $sortedKey (@list) {

            push (@{$slWidget->{data}}, [$sortedKey, $hash{$sortedKey}]);
        }

        return 1;
    }

    sub findKeyInListData {

        # Can be called by any tab function to check the data in a GA::Gtk::Simple::List when it is
        #   storing data in two columns representing the contents of a hash
        # The first column is the key, the second column its corresponding value
        # Checks whether the specified key exists in list's data
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List to modify
        #   $key        - The key to add to the list's data
        #
        # Return values
        #   undef on improper arguments, if $key is 'undef' or an empty string or if the key doesn't
        #       exist in the list's data
        #   1 if the key would exist in the hash, if the list's data were converted to a hash right
        #       now

        my ($self, $slWidget, $key, $check) = @_;

        # Local variables
        my (
            @list,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findKeyInListData', @_);
        }

        # If $key is 'undef' or an empty string, do nothing
        if (! $key) {

            return undef;
        }

        # Convert the data stored in the GA::Gtk::Simple::List into a hash
        %hash = $self->convertListDataToHash($slWidget);

        # See whether the key exists
        if (exists $hash{$key}) {
            return 1;
        } else {
            return undef;
        }
    }

    sub convertListDataToHash {

        # Can be called by any tab function to convert the data in a GA::Gtk::Simple::List (in which
        #   data is stored in two columns) into a hash
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List to use
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise, returns the hash

        my ($self, $slWidget, $check) = @_;

        # Local variables
        my (
            @listRefList,
            %emptyHash, %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->convertListDataToHash', @_);
            return %emptyHash;       # Returns an empty hash
        }

        @listRefList = @{$slWidget->{data}};
        foreach my $listRef (@listRefList) {

            $hash{$$listRef[0]} = $$listRef[1];
        }

        return %hash;
    }

    sub storeListData {

        # Can be called by any tab function to store the data in a GA::Gtk::Simple::List in
        #   $self->editHash
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List to use
        #   $iv         - The name of the instance variable in $self->editHash where the list is
        #                   stored
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $iv, $check) = @_;

        # Local variables
        my (@storeList, @listOfRefs);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeListData', @_);
        }

        @listOfRefs = @{$slWidget->{data}};
        foreach my $ref (@listOfRefs) {

            push (@storeList, @$ref);
        }

        $self->ivAdd('editHash', $iv, \@storeList);

        return 1;
    }

    sub storeListColumnInList {

        # Can be called by any tab function to store the data from a single column in a
        #   GA::Gtk::Simple::List as a list in $self->editHash
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List to use
        #   $iv         - The name of the instance variable in $self->editHash in which the column's
        #                   data is stored
        #   $column     - The number of the chosen column
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $iv, $column, $check) = @_;

        # Local variables
        my (
            @listOfRefs, @dataList, @saveList,
            %storeHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $iv || ! defined $column || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeListColumnInList', @_);
        }

        @listOfRefs = @{$slWidget->{data}};
        foreach my $ref (@listOfRefs) {

            @dataList = @$ref;
            push (@saveList, $dataList[$column]);
        }

        $self->ivAdd('editHash', $iv, \@saveList);

        return 1;
    }

    sub storeListDataInHash {

        # Can be called by any tab function to store the data in a GA::Gtk::Simple::List in
        #   $self->editHash
        # This is a companion function to $self->storeListData (which stores the data as a list);
        #   this function stores the data as a hash
        #
        # Expected arguments
        #   $slWidget   - Reference to a GA::Gtk::Simple::List
        #   $iv         - The name of the instance variable in $self->editHash where the hash is
        #                   stored
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $iv, $check) = @_;

        # Local variables
        my (
            @listOfRefs, @dataList,
            %storeHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeListDataInHash', @_);
        }

        @listOfRefs = @{$slWidget->{data}};
        foreach my $ref (@listOfRefs) {

            @dataList = @$ref;
            $storeHash{$dataList[0]} = $dataList[1];
        }

        $self->ivAdd('editHash', $iv, \%storeHash);

        return 1;
    }

    # Standard tabs

    sub privateDataTab {

        # Standard private data tab - stores data in a single hash IV, such as the ->privateHash in
        #   all profiles. The contents of the hash is displayed in a simple list. Each key's value
        #   can itself be a scalar, list or hash, each of which can be edited from the tab
        # Currently used by the 'edit' windows for profiles, world model objects, exit model
        #   objects and quests
        #
        # Expected arguments
        #   $hashIV     - The hash IV to be edited
        #   $tabName    - A name to display on the tab, with one letter highlighted as a keyboard
        #                   shortcut (e.g. '_Private')
        #   $titleLabel - The main label to display at the top of the tab, e.g. 'Private data hash'
        #                   (displayed in bold)
        #   $minorLabel - The label to display just below the main label (displayed in italics)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $hashIV, $tabName, $titleLabel, $minorLabel, $check) = @_;

        # Local variables
        my (@columnList, @comboList);

        # Check for improper arguments
        if (
            ! defined $hashIV || ! defined $tabName || ! defined $titleLabel
            || ! defined $minorLabel || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->privateDataTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab($tabName, $self->notebook, 12, 10);

        # Private settings hash
        $self->addLabel($table, '<b>' . $titleLabel . '</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>' . $minorLabel . '</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Key', 'text',
            'Type', 'text',
            'Value(s)', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the simple list
        $self->privateDataTab_refreshList($slWidget, scalar (@columnList / 2), $hashIV);

        # Add an entry for adding new data to the private hash
        $self->addLabel($table, 'Key',
            1, 3, 10, 11);
        # Show an icon for when something is entered; however the icon isn't checked (as would
        #   normally happen)
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            3, 6, 10, 11);

        # The $key's corresponding value is either a scalar, a reference to a list or a reference to
        #   a hash
        # Add three buttons to allow the user to add one of these three types of value
        my $button = $self->addButton($table, 'Add scalar...', 'Add a scalar value', undef,
            6, 8, 10, 11);
        $button->signal_connect('clicked' => sub {

            my (
                $key,
                %ivHash,
            );

            $key = $entry->get_text();

            # Check the key hasn't already been created
            %ivHash = $self->getEditHash_hashIV($hashIV);
            if (! exists $ivHash{$key}) {

                # Prompt the user for a scalar value
                $self->promptScalar(
                    $hashIV,
                    $key,               # Mode 2
                    FALSE,
                    undef,
                    FALSE,
                    'privateDataTab_refreshList',
                    $slWidget,
                    scalar (@columnList / 2),
                    $hashIV,
                );

                # Reset the entry box
                $entry->set_text('');
            }
        });

        my $button2 = $self->addButton($table, 'Add list...', 'Add a list value', undef,
            8, 10, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my (
                $key,
                %ivHash,
            );

            $key = $entry->get_text();

            # Check the key hasn't already been created
            %ivHash = $self->getEditHash_hashIV($hashIV);
            if (! exists $ivHash{$key}) {

                # Prompt the user for a list value
                $self->promptList(
                    $hashIV,
                    $key,               # Mode 2
                    undef,
                    FALSE,
                    'privateDataTab_refreshList',
                    $slWidget,
                    scalar (@columnList / 2),
                    $hashIV,
                );

                # Reset the entry box
                $entry->set_text('');
            }
        });

        my $button3 = $self->addButton($table, 'Add hash...', 'Add a hash value', undef,
            10, 12, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my (
                $key,
                %ivHash,
            );

            $key = $entry->get_text();

            # Check the key hasn't already been created
            %ivHash = $self->getEditHash_hashIV($hashIV);
            if (! exists $ivHash{$key}) {

                # Prompt the user for a hash value
                $self->promptHash(
                    $hashIV,
                    $key,               # Mode 2
                    undef,
                    FALSE,
                    'privateDataTab_refreshList',
                    $slWidget,
                    scalar (@columnList / 2),
                    $hashIV,
                );

                # Reset the entry box
                $entry->set_text('');
            }
        });

        # Add the standard editing button
        my $button4 = Gtk2::Button->new('Edit');
        $button4->signal_connect('clicked' => sub {

            my (
                $key, $type,
                %ivHash,
            );

            ($key) = $self->getSimpleListData($slWidget, 0);
            %ivHash = $self->getEditHash_hashIV($hashIV);
            if (defined $key && exists $ivHash{$key}) {

                $type = ref $ivHash{$key};

                # Call ->promptScalar, ->promptList and ->promptHash
                if ($type eq 'ARRAY') {

                    $self->promptList(
                        $hashIV,
                        $key,               # Mode 2
                        undef,
                        FALSE,
                        'privateDataTab_refreshList',
                        $slWidget,
                        scalar (@columnList / 2),
                        $hashIV,
                    );

                } elsif ($type eq 'HASH') {

                    $self->promptHash(
                        $hashIV,
                        $key,               # Mode 2
                        undef,
                        FALSE,
                        'privateDataTab_refreshList',
                        $slWidget,
                        scalar (@columnList / 2),
                        $hashIV,
                    );

                } else {

                    # Prompt the user for a scalar value
                    $self->promptScalar(
                        $hashIV,
                        $key,               # Mode 2
                        FALSE,
                        undef,
                        FALSE,
                        'privateDataTab_refreshList',
                        $slWidget,
                        scalar (@columnList / 2),
                        $hashIV,
                    );
                }
            }
        });
        $self->tooltips->set_tip($button4, 'Edit the selected key');
        $table->attach_defaults($button4, 1, 4, 11, 12);

        my $button5 = Gtk2::Button->new('Delete');
        $button5->signal_connect('clicked' => sub {

            my ($key) = $self->getSimpleListData($slWidget, 0);
            if (defined $key) {

                # Delete the key-value pair from the hash
                $self->modifyEditHash_hashIV($hashIV, $key, undef, TRUE);

                # Update the simple list
                $self->privateDataTab_refreshList($slWidget, scalar (@columnList / 2), $hashIV);
            }
        });
        $self->tooltips->set_tip($button5, 'Delete the selected key');
        $table->attach_defaults($button5, 6, 8, 11, 12);

        my $button6 = Gtk2::Button->new('Reset');
        $button6->signal_connect('clicked' => sub {

            # Remove this IV from $self->editHash, so that the IV in $self->editObj takes over
            $self->ivDelete('editHash', $hashIV);

            # Update the simple list
            $self->privateDataTab_refreshList($slWidget, scalar (@columnList / 2), $hashIV);
        });
        $self->tooltips->set_tip($button6, 'Reset the list of keys');
        $table->attach_defaults($button6, 8, 10, 11, 12);

        my $button7 = Gtk2::Button->new('Clear');
        $button7->signal_connect('clicked' => sub {

            # Add an empty hash to $self->editHash
            $self->ivAdd('editHash', $hashIV, {});

            # Update the simple list
            $self->privateDataTab_refreshList($slWidget, scalar (@columnList / 2), $hashIV);
        });
        $self->tooltips->set_tip($button7, 'Clear the list of keys');
        $table->attach_defaults($button7, 10, 12, 11, 12);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub privateDataTab_refreshList {

        # Called by $self->privateDataTab to refresh the simple list
        #
        # Expected arguments
        #   $slWidget       - The GA::Gtk::Simple::List
        #   $columns        - The number of columns
        #   $hashIV         - The hash IV being edited
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $hashIV, $check) = @_;

        # Local variables
        my (
            @dataList,
            %ivHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || ! defined $hashIV || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->privateDataTab_refreshList',
                @_,
            );
        }

        # Import the IV (for convenience)
        %ivHash = $self->getEditHash_hashIV($hashIV);

        # Compile the simple list data
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %ivHash)) {

            my (
                $value, $typeString, $valueString, $type,
                %hash,
            );

            $value = $ivHash{$key};

            if (! defined $value) {

                $typeString = 'scalar';
                $valueString = '<undef>';

            } else {

                $type = ref $value;
                if ($type eq 'ARRAY') {

                    $typeString = 'list';
                    foreach my $item (@$value) {

                        if (! defined $valueString) {
                            $valueString = $item;
                        } else {
                            $valueString .= ', ' . $item;
                        }
                    }

                } elsif ($type eq 'HASH') {

                    $typeString = 'hash';
                    foreach my $thisKey (sort {lc($a) cmp lc($b)} (keys %$value)) {

                        my $thisValue = $$value{$thisKey};
                        if (! defined $thisValue) {

                            $thisValue = '<undef>';
                        }

                        if (! defined $valueString) {
                            $valueString = $thisKey . ':' . $thisValue;
                        } else {
                            $valueString .= ', ' . $thisKey . ':' . $thisValue;
                        }
                    }

                } else {

                    $typeString = 'scalar';
                    $valueString = $value;
                }
            }

            push (@dataList,
                $key,
                $typeString,
                $valueString,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    # Shared tabs (shared by GA::EditWin::Profile::Char and GA::EditWin::Task)

    sub objects1Tab {

        # Objects1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $page, $charObj,
            @columnList,
            %objHash,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->objects1Tab', @_);
        }

        # Tab setup. This tab is used in the task 'pref' window, and an identical copy used in the
        #   character profile 'edit' window
        if ($self->_objClass eq 'Games::Axmud::EditWin::Task') {
            $page = 'Page _3';
        } else {
            $page = 'Page _1';
        }

        my ($vBox, $table) = $self->addTab($page, $innerNotebook);

        # Decide which character profile we're using
        if ($self->_objClass eq 'Games::Axmud::EditWin::Task') {
            $charObj = $self->session->currentChar;
        } else {
            $charObj = $self->editObj;
        }

        # Protected objects
        $self->addLabel($table, '<b>Protected objects</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of objects which enjoy semi-protection against being sold and dropped</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Categories', 'text',       # ->categoryList
            'Main noun', 'text',        # ->noun
            'Other nouns', 'text',      # ->otherNounList
            'Adjs', 'text',             # ->adjList
            'Pseudo adjs', 'text',      # ->pseudoAdjList
            'Unknowns', 'text',         # ->unknownWordList
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 9,
            -1, 200);       # Fixed height

        # Create a hash to link lines in the simple list to objects in the protected objects list,
        #   in the form
        #       $objHash{line_number} = blessed_reference_of_protected_object
        # Each time the simple list is refreshed, the hash is updated
        %objHash = $self->objects1Tab_refreshList($slWidget, scalar (@columnList / 2), $charObj);

        # Add buttons
        my $button = $self->addButton($table,
            'Unprotect',
            'Delete the selected protected object',
            undef,
            1, 3, 9, 10,
            TRUE);          # Irreversible
        $button->signal_connect('clicked' => sub {

            my ($index, $lineRef, $obj, $cmd, $match, $count);

            ($index) = $slWidget->get_selected_indices();
            if (defined $index) {

                $obj = $objHash{$index};

                if ($charObj) {        # Check there is a current character profile

                    # Find the object's position in the protected objects list maintained by the
                    #   character profile (which may possibly have changed, since the simple list
                    #   was last updated)
                    $count = -1;
                    foreach my $element ($charObj->protectObjList) {

                        $count++;

                        if ($element eq $obj) {

                            $match = $count;
                        }
                    }

                    if (defined $match) {

                        # Unprotect the object. The ';unprotectobject' command lists objects
                        #   starting from 1, not 0 (so we must add 1 to $match)
                        $self->session->pseudoCmd(
                            'unprotectobject ' . ($match + 1),
                            $self->pseudoCmdMode,
                        );

                        %objHash = $self->objects1Tab_refreshList(
                            $slWidget,
                            scalar (@columnList / 2),
                            $charObj,
                        );
                    }
                }
            }
        });

        my $button2 = $self->addButton($table, 'Edit...', 'Edit the protected object', undef,
            3, 5, 9, 10);
        $button2->signal_connect('clicked' => sub {

            my ($index, $obj, $childWinObj);

            ($index) = $slWidget->get_selected_indices();
            if (defined $index && exists $objHash{$index}) {

                $obj = $objHash{$index};

                # Open an 'edit' window for the protected object
                $childWinObj = $self->createFreeWin(
                    'Games::Axmud::EditWin::Protect',
                    $self,
                    $self->session,
                    'Edit protected object \'' . $obj->noun . '\'',
                    $obj,
                    FALSE,                          # Not temporary
                );

                if ($childWinObj) {

                    # When the 'edit' window closes, update the simple list
                    $self->add_childDestroy(
                        $childWinObj,
                        'objects1Tab_refreshList',
                        [$slWidget, (scalar @columnList / 2), $charObj],
                    );
                }
            }
        });

        my $button3 = $self->addButton($table,
            'Dump list',
            'Display the list of protected objects in the \'main\' window',
            undef,
            8, 10, 9, 10);
        $button3->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('listprotectobject', $self->pseudoCmdMode);

            %objHash
                = $self->objects1Tab_refreshList($slWidget, scalar (@columnList / 2), $charObj);
        });

        my $button4 = $self->addButton($table,
            'Refresh list',
            'Refresh the list of protected objects',
            undef,
            10, 12, 9, 10);
        $button4->signal_connect('clicked' => sub {

            # Refresh the simple list
            %objHash
                = $self->objects1Tab_refreshList($slWidget, scalar (@columnList / 2), $charObj);

            # If there is no current character profile (and we need one), the buttons (except for
            #   the 'refresh list' button) must be insensitive
            if ($charObj) {
                $self->sensitiseWidgets($button, $button2);
            } else {
                $self->desensitiseWidgets($button, $button2);
            }
        });

        my $button5 = $self->addButton($table,
            'Protect objects matching:',
            'Protect objects matching this list of words',
            undef,
            1, 4, 10, 11,
            TRUE);              # Irreversible
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            4, 12, 10, 11);
        $button5->signal_connect('clicked' => sub {

            my $wordString = $entry->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Protect objects matching these words
                $self->session->pseudoCmd(
                    'protectobject ' . $wordString,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset the entry boxes
                %objHash = $self->objects1Tab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    $charObj,
                );
                $self->resetEntryBoxes($entry);
            }
        });

        my $button6 = $self->addButton($table,
            'Monitor objects matching:',
            'Monitor objects matching this list of words',
            undef,
            1, 4, 11, 12,
            TRUE);              # Irreversible
        my $entry2 = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            4, 12, 11, 12);
        $button6->signal_connect('clicked' => sub {

            my $wordString = $entry2->get_text();

            if ($self->checkEntryIcon($entry2)) {

                # Monitor objects matching these words
                $self->session->pseudoCmd(
                    'monitorobject ' . $wordString,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset the entry boxes
                %objHash = $self->objects1Tab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    $charObj,
                );
                $self->resetEntryBoxes($entry2);
            }
        });

        # Widgets can't be manipulated when this isn't a current profile (or a current task)
        if (! $self->currentFlag) {

            $button->set_sensitive(FALSE);
            $button2->set_sensitive(FALSE);
            $button3->set_sensitive(FALSE);
            $button4->set_sensitive(FALSE);
            $button5->set_sensitive(FALSE);
            $button6->set_sensitive(FALSE);
            $entry->set_sensitive(FALSE);
            $entry2->set_sensitive(FALSE);
        }

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub objects1Tab_refreshList {

        # Called by $self->objects1Tab to reset the GA::Gtk::Simple::List
        #
        # Expected arguments
        #   $slWidget       - The GA::Gtk::Simple::List
        #   $columns        - The number of columns in the list
        #
        # Optional arguments
        #   $charObj       - The character profile whose list of protected objects we're showing.
        #                       If set to 'undef', it's because there is no current character and,
        #                       because we need one, we therefore show an empty list
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise, a hash which links lines in the simple list to the objects it contains
        #       - which replaces the hash %objHash in $self->objects1Tab

        my ($self, $slWidget, $columns, $charObj, $check) = @_;

        # Local variables
        my (
            $count,
            @objList, @dataList,
            %emptyHash, %objHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->objects1Tab_refreshList', @_);
            return %emptyHash;
        }

        # Don't display anything if there is no specified character profile
        if (! $charObj) {

            $self->resetListData($slWidget, [], $columns);

        } else {

            # Import the list of protected objects
            @objList = $charObj->protectObjList;

            # Refresh the simple list, and create a new hash of objects linked to the line they
            #   appear on
            $count = -1;

            # Compile the simple list data
            foreach my $obj (@objList) {

                $count++;

                push (@dataList,
                    join(' ', $obj->categoryList),
                    $obj->noun,
                    join(' ', $obj->otherNounList),
                    join(' ', $obj->adjList),
                    join(' ', $obj->pseudoAdjList),
                    join(' ', $obj->unknownWordList),
                );

                $objHash{$count} = $obj;
            }

            # Reset the simple list
            $self->resetListData($slWidget, [@dataList], $columns);
        }

        return %objHash;
    }

    sub objects2Tab {

        # Objects2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $page, $charObj,
            @columnList,
            %objHash,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->objects2Tab', @_);
        }

        # Tab setup. This tab is used in the task 'pref' window, and an identical copy used in the
        #   character profile 'edit' window
        if ($self->_objClass eq 'Games::Axmud::EditWin::Task') {
            $page = 'Page _4';
        } else {
            $page = 'Page _2';
        }

        my ($vBox, $table) = $self->addTab($page, $innerNotebook);

        # Decide which character profile we're using
        if ($self->_objClass eq 'Games::Axmud::EditWin::Task') {
            $charObj = $self->session->currentChar;
        } else {
            $charObj = $self->editObj;
        }

        # Monitored objects
        $self->addLabel($table, '<b>Monitored objects</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of objects whose condition is monitored by the Condition task</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Categories', 'text',       # ->categoryList
            'Main noun', 'text',        # ->noun
            'Other nouns', 'text',      # ->otherNounList
            'Adjs', 'text',             # ->adjList
            'Pseudo adjs', 'text',      # ->pseudoAdjList
            'Unknowns', 'text',         # ->unknownWordList
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 9,
            -1, 200);       # Fixed height

        # Create a hash to link lines in the simple list to objects in the monitored objects list,
        #   in the form
        #       $objHash{line_number} = blessed_reference_of_monitored_object
        # Each time the simple list is refreshed, the hash is updated
        %objHash = $self->objects2Tab_refreshList($slWidget, scalar (@columnList / 2), $charObj);

        # Add buttons
        my $button = $self->addButton($table,
            'Unmonitor',
            'Delete the selected monitored object',
            undef,
            1, 3, 9, 10,
            TRUE);              # Irreversible
        $button->signal_connect('clicked' => sub {

            my ($index, $lineRef, $obj, $cmd, $match, $count);

            ($index) = $slWidget->get_selected_indices();
            if (defined $index) {

                $obj = $objHash{$index};

                if ($charObj) {        # Check there is a current character profile

                    # Find the object's position in the monitored objects list maintained by the
                    #   character profile (which may possibly have changed, since the simple list
                    #   was last updated)
                    $count = -1;
                    foreach my $element ($charObj->monitorObjList) {

                        $count++;

                        if ($element eq $obj) {

                            $match = $count;
                        }
                    }

                    if (defined $match) {

                        # Unmonitor the object. The ';unmonitortobject' command lists objects
                        #   starting from 1, not 0 (so we must add 1 to $match)
                        $self->session->pseudoCmd(
                            'unmonitorobject ' . ($match + 1),
                            $self->pseudoCmdMode,
                        );

                        %objHash = $self->objects2Tab_refreshList(
                            $slWidget,
                            scalar (@columnList / 2),
                            $charObj,
                        );
                    }
                }
            }
        });

        my $button2 = $self->addButton($table, 'Edit...', 'Edit the monitored object', undef,
            3, 5, 9, 10);
        $button2->signal_connect('clicked' => sub {

            my ($index, $obj, $childWinObj);

            ($index) = $slWidget->get_selected_indices();
            if (defined $index) {

                $obj = $objHash{$index};

                # Open an 'edit' window for the monitored object (the same 'edit' window is used for
                #   both protected and monitored objects, at the moment)
                $childWinObj = $self->createFreeWin(
                    'Games::Axmud::EditWin::Protect',
                    $self,
                    $self->session,
                    'Edit monitored object \'' . $obj->noun . '\'',
                    $obj,
                    FALSE,                          # Not temporary
                );

                if ($childWinObj) {

                    # When the 'edit' window closes, update the simple list
                    $self->add_childDestroy(
                        $childWinObj,
                        'objects2Tab_refreshList',
                        [$slWidget, (scalar @columnList / 2), $charObj],
                    );
                }
            }
        });

        my $button3 = $self->addButton($table,
            'Dump list',
            'Display the list of monitored objects in the \'main\' window',
            undef,
            8, 10, 9, 10);
        $button3->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('listmonitorobject', $self->pseudoCmdMode);

            %objHash
                = $self->objects2Tab_refreshList($slWidget, scalar (@columnList / 2), $charObj);
        });

        my $button4 = $self->addButton($table,
            'Refresh list',
            'Refresh the list of monitored objects',
            undef,
            10, 12, 9, 10);
        $button4->signal_connect('clicked' => sub {

            # Refresh the simple list
            %objHash
                = $self->objects2Tab_refreshList($slWidget, scalar (@columnList / 2), $charObj);

            # If there is no current character profile (and we need one), the buttons (except for
            #   the 'refresh list' button) must be insensitive
            if ($charObj) {
                $self->sensitiseWidgets($button, $button2);
            } else {
                $self->desensitiseWidgets($button, $button2);
            }
        });

        my $button5 = $self->addButton($table,
            'Protect objects matching:',
            'Protect objects matching this list of words',
            undef,
            1, 4, 10, 11,
            TRUE);              # Irreversible

        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            4, 12, 10, 11);

        $button5->signal_connect('clicked' => sub {

            my $wordString = $entry->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Protect objects matching these words
                $self->session->pseudoCmd(
                    'protectobject ' . $wordString,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset the entry boxes
                %objHash = $self->objects2Tab_refreshList(
                    $slWidget,
                    scalar(@columnList / 2),
                    $charObj,
                );

                $self->resetEntryBoxes($entry);
            }
        });

        my $button6 = $self->addButton($table,
            'Monitor objects matching:',
            'Monitor objects matching this list of words',
            undef,
            1, 4, 11, 12,
            TRUE);              # Irreversible
        my $entry2 = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            4, 12, 11, 12);
        $button6->signal_connect('clicked' => sub {

            my $wordString = $entry2->get_text();

            if ($self->checkEntryIcon($entry2)) {

                # Monitor objects matching these words
                $self->session->pseudoCmd(
                    'monitorobject ' . $wordString,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset the entry boxes
                %objHash = $self->objects2Tab_refreshList(
                    $slWidget,
                    scalar(@columnList / 2),
                    $charObj,
                );

                $self->resetEntryBoxes($entry2);
            }
        });

        # Widgets can't be manipulated when this isn't a current profile (or a current task)
        if (! $self->currentFlag) {

            $button->set_sensitive(FALSE);
            $button2->set_sensitive(FALSE);
            $button3->set_sensitive(FALSE);
            $button4->set_sensitive(FALSE);
            $button5->set_sensitive(FALSE);
            $button6->set_sensitive(FALSE);
            $entry->set_sensitive(FALSE);
            $entry2->set_sensitive(FALSE);
        }

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub objects2Tab_refreshList {

        # Called by $self->objects2Tab to reset the GA::Gtk::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Optional arguments
        #   $charObj       - The character profile whose list of monitored objects we're showing.
        #                       If set to 'undef', it's because there is no current character and,
        #                       because we need one, we therefore show an empty list
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise, a hash which links lines in the simple list to the objects it contains
        #       - which replaces the hash %objHash in $self->objects2Tab

        my ($self, $slWidget, $columns, $charObj, $check) = @_;

        # Local variables
        my (
            $count,
            @objList, @dataList,
            %emptyHash, %objHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->objects2Tab_refreshList', @_);
            return %emptyHash;
        }

        # Don't display anything if there is no specified character profile
        if (! $charObj) {

            $self->resetListData($slWidget, [], $columns);

        } else {

            # Import the list of monitored objects
            @objList = $charObj->monitorObjList;

            # Refresh the simple list, and create a new hash of objects linked to the line they
            #   appear on
            $count = -1;

            # Compile the simple list data
            foreach my $obj (@objList) {

                $count++;
                push (@dataList,
                    join(' ', $obj->categoryList),
                    $obj->noun,
                    join(' ', $obj->otherNounList),
                    join(' ', $obj->adjList),
                    join(' ', $obj->pseudoAdjList),
                    join(' ', $obj->unknownWordList),
                );

                $objHash{$count} = $obj;
            }

            # Reset the simple list
            $self->resetListData($slWidget, [@dataList], $columns);
        }

        return %objHash;
    }

    # Shared tabs (shared by GA::EditWin::Generic::ModelObj and GA::PrefWin::Search)

    sub openChildEditWin {

        # Opens an 'edit' window for a different world model object (e.g. after clicking the 'Edit'
        #   button on one of the 'Family' tabs)
        #
        # Expected arguments
        #   $number     - The number of the world model object for which to open an 'edit' window
        #
        # Return values
        #   'undef' on improper arguments or if the model object doesn't seem to exist
        #   1 otherwise

        my ($self, $number, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->openChildEditWin', @_);
        }

        # Check that the object really exists
        if (! $self->session->worldModelObj->ivExists('modelHash', $number)) {

            return undef;

        } else {

            $obj = $self->session->worldModelObj->ivShow('modelHash', $number);
        }

        # Open up an 'edit' window to edit the object
        $self->createFreeWin(
            'Games::Axmud::EditWin::ModelObj::' . ucfirst($obj->category),
            $self,
            $self->session,
            'Edit ' . $obj->category . ' model object #' . $obj->number,
            $obj,
            FALSE,                          # Not temporary,
        );

        return 1;
    }

    # Shared tabs (shared by GA::EditWin::Interface::Active and GA::EditWin::Interface::Trigger,
    #   etc

    sub triggerAttributesTab {

        # TriggerAttributes tab
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->triggerAttributesTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Attributes', $self->notebook);

        # Add tabs to the inner notebook
        $self->triggerAttributes1Tab($innerNotebook);
        $self->triggerAttributes2Tab($innerNotebook);

        return 1;
    }

    sub triggerAttributes1Tab {

        # TriggerAttributes1Tab tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->triggerAttributes1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Trigger attributes
        $self->addLabel($table, '<b>Trigger attributes</b>',
            0, 12, 0, 1);

        # Left column
        $self->addLabel($table, 'Splitter trigger',
            1, 5, 1, 2);
        $self->useCheckButton($table, 'splitter', TRUE,
            5, 6, 1, 2, 1, 0.5);
        $self->addLabel($table, 'Split after matching pattern, not before',
            1, 5, 2, 3);
        $self->useCheckButton($table, 'split_after', TRUE,
            5, 6, 2, 3, 1, 0.5);
        $self->addLabel($table, 'Split line multiple times, if multiple matches',
            1, 5, 3, 4);
        $self->useCheckButton($table, 'keep_splitting', TRUE,
            5, 6, 3, 4, 1, 0.5);
        $self->addLabel($table, 'Rewriter trigger',
            1, 5, 4, 5);
        $self->useCheckButton($table, 'rewriter', TRUE,
            5, 6, 4, 5, 1, 0.5);
        $self->addLabel($table, 'Rewrite every matching part of line',
            1, 5, 5, 6);
        $self->useCheckButton($table, 'rewrite_global', TRUE,
            5, 6, 5, 6, 1, 0.5);
        $self->addLabel($table, 'Ignore case',
            1, 5, 6, 7);
        $self->useCheckButton($table, 'ignore_case', TRUE,
            5, 6, 6, 7, 1, 0.5);
        $self->addLabel($table, 'Only fire in session\'s default pane',
            1, 5, 7, 8);
        my $checkButton = $self->useCheckButton($table, 'default_pane', TRUE,
            5, 6, 7, 8, 1, 0.5);
        $self->addLabel($table, 'Fire in named pane',
            1, 3, 8, 9);
        my $entry = $self->addEntry($table, undef, TRUE,
            3, 6, 8, 9);
        $entry->set_text($self->editObj->ivShow('attribHash', 'pane_name'));
        if ($entry->get_text()) {

            $checkButton->set_sensitive(FALSE);
        }

        $entry->signal_connect('changed' => sub {

            my $text = $entry->get_text();

            # If the user has emptied the entry box, set the attribute to an empty string
            if (! $text) {

                $self->ivAdd('attribHash', 'pane_name', '');
                $checkButton->set_sensitive(TRUE);

            # Otherwise set the attribute to the specified value
            } else {

                $self->ivAdd('attribHash', 'pane_name', $text);
                $checkButton->set_active(FALSE);
                $checkButton->set_sensitive(FALSE);
            }
        });

        # Right column
        $self->addLabel($table, 'Require a prompt to fire',
            7, 11, 1, 2);
        $self->useCheckButton($table, 'need_prompt', TRUE,
            11, 12, 1, 2, 1, 0.5);
        $self->addLabel($table, 'Require a login to fire',
            7, 11, 2, 3);
        $self->useCheckButton($table, 'need_login', TRUE,
            11, 12, 2, 3, 1, 0.5);
        $self->addLabel($table, 'Omit (gag) from output',
            7, 11, 3, 4);
        $self->useCheckButton($table, 'gag', TRUE,
            11, 12, 3, 4, 1, 0.5);
        $self->addLabel($table, 'Omit (gag) from logfile',
            7, 11, 4, 5);
        $self->useCheckButton($table, 'gag_log', TRUE,
            11, 12, 4, 5, 1, 0.5);
        $self->addLabel($table, 'Keep checking triggers after a match',
            7, 11, 5, 6);
        $self->useCheckButton($table, 'keep_checking', TRUE,
            11, 12, 5, 6, 1, 0.5);
        $self->addLabel($table, 'Temporary trigger',
            7, 11, 6, 7);
        $self->useCheckButton($table, 'temporary', TRUE,
            11, 12, 6, 7, 1, 0.5);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub triggerAttributes2Tab {

        # TriggerAttributes2Tab tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (@backRefList, @comboList, @comboList2);

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->triggerAttributes2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Trigger styles
        $self->addLabel($table, '<b>Trigger attributes (cont.)</b>',
            0, 12, 0, 1);

        # Top left
        my ($group, $radioButton) = $self->useRadioButton(
            $table, undef,
            'Mode 0',               # Radio button name
            'style_mode',           # Attribute to set
            0,                      # Attribute set to this value when toggled
            TRUE,                   # Sensitive widget
            1, 2, 1, 2);
        $self->addLabel($table, 'Don\'t apply styles',
            2, 6, 1, 2);

        ($group, $radioButton) = $self->useRadioButton(
            $table, $group, 'Mode -1', 'style_mode', -1, TRUE,
            1, 2, 2, 3);
        $self->addLabel($table, 'Apply style to whole line',
            2, 6, 2, 3);

        ($group, $radioButton) = $self->useRadioButton(
            $table, $group, 'Mode -2', 'style_mode', -2, TRUE,
            1, 2, 3, 4);
        $self->addLabel($table, 'Apply style to matched text',
            2, 6, 3, 4);

        # Top right
        my ($group2, $radioButton2) = $self->useRadioButton(
            $table, $group,
            'Mode n',
            'style_mode',
            -3,                 # Non-standard value; set to correct value by $self->saveChanges
            TRUE,
            7, 8, 1, 2);
        $self->addLabel($table, 'Apply style to matched backref #:',
            8, 12, 1, 2);
        @backRefList = (1, 2, 3, 4, 5, 6, 7, 8, 9);
        my $combo = $self->useComboBox(
            $table,
            '_substr_num',
            \@backRefList,
            'Select backref:',
            8, 10, 2, 3);

        if (
            $self->editObj->ivShow('attribHash', 'style_mode')
            && $self->editObj->ivShow('attribHash', 'style_mode') > 0
        ) {
            # Style mode is 1 or more, which corresponds to the radio button on the top-right
            $radioButton2->set_active(TRUE);
            $combo->set_active($self->editObj->ivShow('attribHash', 'style_mode'));
        }

        # Bottom left
        $self->addLabel($table, '<u>Trigger style to apply:</u>',
            1, 12, 4, 5);

        push (@comboList, '');
        push (@comboList2, '');
        foreach my $tag ($axmud::CLIENT->constColourTagList) {

            push (@comboList, $tag);
            push (@comboList2, 'ul_' . $tag);
        }

        foreach my $tag ($axmud::CLIENT->constBoldColourTagList) {

            push (@comboList, $tag);
            push (@comboList2, 'UL_' . $tag);
        }

        $self->triggerAttributesTab_setColours(
            $table,
            'Text colour',
            'style_text',
            \@comboList,
            5,
        );

        $self->triggerAttributesTab_setColours(
            $table,
            'Underlay colour',
            'style_underlay',
            \@comboList2,
            9,
        );

        # Right column
        $self->triggerAttributesTab_addRadioButtons($table, 'Italics', 'style_italics', 5);
        $self->triggerAttributesTab_addRadioButtons($table, 'Underline', 'style_underline', 6);
        $self->triggerAttributesTab_addRadioButtons($table, 'Slow blink', 'style_blink_slow', 7);
        $self->triggerAttributesTab_addRadioButtons($table, 'Fast blink', 'style_blink_fast', 8);
        $self->triggerAttributesTab_addRadioButtons($table, 'Strike-through', 'style_strike', 9);
        $self->triggerAttributesTab_addRadioButtons($table, 'Link', 'style_link', 10);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub triggerAttributesTab_setColours {

        # Called by $self->triggerAttributes2Tab to add radio buttons for setting a colour attribute
        #
        # Expected arguments
        #   $table          - The Gtk2::Table
        #   $labelText      - The label text to use (e.g. 'Text colour')
        #   $attrib         - The attibute to set (e.g. 'style_text')
        #   $comboListRef   - Reference to a list of standard colour tags to display in a combobox
        #   $row            - The Gtk2::Table row on which the radio buttons are drawn
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $labelText, $attrib, $comboListRef, $row, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $labelText || ! defined $attrib || ! defined $row
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->triggerAttributesTab_setColours',
                @_,
            );
        }

        $self->addLabel($table, $labelText,
            1, 3, $row, ($row + 1));
        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, $row, ($row + 1));
        $entry->set_text($self->editObj->ivShow('attribHash', $attrib));

        my $comboBox = $self->addComboBox($table, undef, $comboListRef, '',
            TRUE,               # No 'undef' value used
            1, 4, ($row + 1), ($row + 2));

        my $button = $self->addButton(
            $table,
            'Set',
            'Set this standard colour tag as the ' . lc($labelText),
            undef,
            4, 6, ($row + 1), ($row + 2));
        $button->signal_connect('clicked' => sub {

            my $text = $comboBox->get_active_text();

            # If the user has selected the empty line at the top, set the attribute to an empty
            #   string
            if (! $text) {

                $self->ivAdd('attribHash', $attrib, '');

            # Otherwise set the attribute to the specified value
            } else {

                $self->ivAdd('attribHash', $attrib, $text);
                $comboBox->set_active(0);
            }

            $entry->set_text($self->ivShow('attribHash', $attrib));
        });

        $self->addLabel($table, 'xterm tag',
            1, 2, ($row + 2), ($row + 3));
        my $entry2 = $self->addEntryWithIcon($table, undef, \&triggerAttributesTab_checkXTerm, 0, 0,
            2, 4, ($row + 2), ($row + 3));
        $entry2->set_icon_from_stock('secondary', 'gtk-yes');   # (Empty box is valid)
        my $button2 = $self->addButton(
            $table,
            'Set',
            'Set this xterm tag as the ' . lc($labelText),
            undef,
            4, 6, ($row + 2), ($row + 3));
        $button2->signal_connect('clicked' => sub {

            my $text;

            if ($self->checkEntryIcon($entry2)) {

                $text = $entry2->get_text();

                # If the user has emptied the entry box, set the attribute to an empty string
                if (! $text) {

                    $self->ivAdd('attribHash', $attrib, '');

                # Otherwise set the attribute to the specified value
                } else {

                    $self->ivAdd('attribHash', $attrib, $text);
                }

                $entry->set_text($self->ivShow('attribHash', $attrib));
                $entry2->set_text('');
            }
        });

        $self->addLabel($table, 'RGB tag',
            1, 2, ($row + 3), ($row + 4));
        my $entry3 = $self->addEntryWithIcon($table, undef, \&triggerAttributesTab_checkRGB, 0, 0,
            2, 4, ($row + 3), ($row + 4));
        $entry3->set_icon_from_stock('secondary', 'gtk-yes');   # (Empty box is valid)
        my $button3 = $self->addButton(
            $table,
            'Set',
            'Set this RGB tag as the ' . lc($labelText),
            undef,
            4, 6, ($row + 3), ($row + 4));
        $button3->signal_connect('clicked' => sub {

            my $text;

            if ($self->checkEntryIcon($entry3)) {

                $text = $entry3->get_text();

                # If the user has emptied the entry box, set the attribute to an empty string
                if (! $text) {

                    $self->ivAdd('attribHash', $attrib, '');

                # Otherwise set the attribute to the specified value
                } else {

                    $self->ivAdd('attribHash', $attrib, $text);
                }

                $entry->set_text($self->ivShow('attribHash', $attrib));
                $entry3->set_text('');
            }
        });

        return 1;
    }

    sub triggerAttributesTab_checkXTerm {

        # Called by $self->triggerAttributes2Tab to check the text in the Gtk2::Entry
        #
        # Expected arguments
        #   $text       - The contents of the Gtk2::Entry
        #
        # Return values
        #   'undef' on improper arguments or if $text is invalid
        #   1 if $text is valid

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->triggerAttributesTab_checkXTerm',
                @_,
            );
        }

        # $text can be an xterm colour tag (in the range 'x0' to 'x255', or 'ux0' to 'ux255'; xterm
        #   tags are case-insensitive
        # An empty entry box is also a valid value
        if (! $text) {

            return 1;

        } elsif ($text =~ m/^u?x([0-9]+)$/i) {

            # (Don't permit 'x000005', but do permit 'x005' or 'x5')
            if ($1 >= 0 && $1 <= 255 && length ($1) <= 3) {
                return 1;
            } else {
                return undef;
            }

        } else {

            return undef;
        }
    }

    sub triggerAttributesTab_checkRGB {

        # Called by $self->triggerAttributes2Tab to check the text in the Gtk2::Entry
        #
        # Expected arguments
        #   $text       - The contents of the Gtk2::Entry
        #
        # Return values
        #   'undef' on improper arguments or if $text is invalid
        #   1 if $text is valid

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->triggerAttributesTab_checkRGB',
                @_,
            );
        }

        # $text can be an RGB colour tag (in the form '#xxxxxx' or '#uxxxxxx' where x is any
        #   character in the range A-F, a-f, 0-9; RGB tags are case-insensitive
        # An empty entry box is also a valid value
        if (! $text) {

            return 1;

        } elsif ($text =~ m/^u?\#[A-F0-9]{6}$/i) {

            return 1;

        } else {

            return undef;
        }
    }

    sub triggerAttributesTab_addRadioButtons {

        # Called by $self->triggerAttributes2Tab to add radio buttons for setting an attribute
        #
        # Expected arguments
        #   $table      - The Gtk2::Table
        #   $labelText  - The label text to use (e.g. 'Italics')
        #   $attrib     - The attibute to set (e.g. 'style_italics')
        #   $row        - The Gtk2::Table row on which the radio buttons are drawn
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $labelText, $attrib, $row, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $labelText || ! defined $attrib || ! defined $row
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->triggerAttributesTab_addRadioButtons',
                @_,
            );
        }

        $self->addLabel($table, $labelText,
            7, 8, $row, ($row + 1));
        my ($group, $radioButton) = $self->useRadioButton(
            $table, undef,
            'Do not change',        # Radio button name
            $attrib,                # Attribute to set
            0,                      # Attribute set to this value when toggled
            TRUE,                   # Sensitive widget
            8, 10, $row, ($row + 1));

        ($group, $radioButton) = $self->useRadioButton(
            $table, $group, 'Yes', $attrib, 1, TRUE,
            10, 11, $row, ($row + 1));

        ($group, $radioButton) = $self->useRadioButton(
            $table, $group, 'No', $attrib, 2, TRUE,
            11, 12, $row, ($row + 1));

        return 1;
    }

    sub aliasAttributesTab {

        # AliasAttributes tab
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->aliasAttributesTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Attributes', $self->notebook);

        # Alias attributes
        $self->addLabel($table, '<b>Alias attributes</b>',
            0, 12, 0, 1);

        # Left column
        $self->addLabel($table, 'Ignore case',
            1, 5, 1, 2);
        $self->useCheckButton($table, 'ignore_case', TRUE,
            5, 6, 1, 2, 1, 0.5);
        $self->addLabel($table, 'Keep checking aliases after a match',
            1, 5, 2, 3);
        $self->useCheckButton($table, 'keep_checking', TRUE,
            5, 6, 2, 3, 1, 0.5);

        # Right column
        $self->addLabel($table, 'Temporary alias',
            7, 11, 1, 2);
        $self->useCheckButton($table, 'temporary', TRUE,
            11, 12, 1, 2, 1, 0.5);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub macroAttributesTab {

        # MacroAttributes tab
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->macroAttributesTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Attributes', $self->notebook);

        # Macro attributes
        $self->addLabel($table, '<b>Macro attributes</b>',
            0, 12, 0, 1);
        $self->addLabel($table, 'Temporary macro',
            1, 11, 1, 2);
        $self->useCheckButton($table, 'temporary', TRUE,
            11, 12, 1, 2, 1, 0.5);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub timerAttributesTab {

        # TimerAttributes tab
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->timerAttributesTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Timers', $self->notebook);

        # Timer attributes
        $self->addLabel($table, '<b>Timer attributes</b>',
            0, 12, 0, 1);

        # Left column
        $self->addLabel($table, 'Repeat count (-1 unlimited)',
            1, 4, 1, 2);
        $self->useEntryWithIcon($table, 'count', 'int', -1, undef,
            4, 6, 1, 2);
        $self->addLabel($table, 'Initial delay (0 for no delay)',
            1, 4, 2, 3);
        $self->useEntryWithIcon($table, 'initial_delay', 'float', 0, undef,
            4, 6, 2, 3);
        $self->addLabel($table, 'Random delays',
            1, 5, 3, 4);
        $self->useCheckButton($table, 'random_delay', TRUE,
            5, 6, 3, 4, 1, 0.5);

        # Right column
        $self->addLabel($table, 'Minimum random delay',
            7, 10, 1, 2);
        $self->useEntryWithIcon($table, 'random_min', 'float', 0, undef,
            10, 12, 1, 2);
        $self->addLabel($table, 'Start after login',
            7, 11, 2, 3);
        $self->useCheckButton($table, 'wait_login', TRUE,
            11, 12, 2, 3, 1, 0.5);
        $self->addLabel($table, 'Temporary timer',
            7, 11, 3, 4);
        $self->useCheckButton($table, 'temporary', TRUE,
            11, 12, 3, 4, 1, 0.5);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub hookAttributesTab {

        # HookAttributes tab
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->hookAttributesTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Attributes', $self->notebook);

        # Hook attributes
        $self->addLabel($table, '<b>Hook attributes</b>',
            0, 12, 0, 1);
        $self->addLabel($table, 'Temporary hook',
            1, 11, 1, 2);
        $self->useCheckButton($table, 'temporary', TRUE,
            11, 12, 1, 2, 1, 0.5);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    # 'dialogue' windows for simple scalars, lists and hashes

    sub promptScalar {

        # Creates a 'dialogue' window to prompt the user to view, enter (or edit) a scalar value
        # If the user supplies a value, sets the IV then closes the window
        #
        # Operates in two modes
        #   Mode 1  - the supplied IV is a scalar, i.e.
        #               $self->editObj->$iv = 'some_scalar_value'
        #               $self->editHash->$iv = 'some_scalar_value'
        #           - the value supplied by the user is saved in place of 'some_scalar_value'
        #
        #   Mode 2  - the supplied IV is a hash, i.e.
        #               $self->editObj->$iv = {some_hash}
        #               $self->editHash->$iv = {some_hash}
        #           - the calling function also supplies a key in {some_hash}
        #           - the value supplied by the user is saved as the key's corresponding value
        #
        # Expected arguments
        #   $iv     - The IV to set in $self->editHash
        #
        # Optional arguments
        #   $key    - In mode 1, 'undef'; in mode 2, a key in {some_hash}
        #   $deRefFlag
        #           - In mode 1, 'undef'; in mode 2, TRUE if the key's corresponding value in
        #               {some_hash} is stored as a scalar reference (only cage masks do this); FALSE
        #               (or 'undef') if it's stored as a simple scalar
        #   $slWidget
        #           - In mode 1, 'undef'; in mode 2, 'undef' or the  Gt2::Ex::Simple::List in which
        #               the IV's data is being displayed (if specified, the simple list is updated
        #               when this window is closed)
        #   $readOnlyFlag
        #           - If set to TRUE, the scalar is read-only (so can't be edited); otherwise set
        #               to FALSE (or 'undef')
        #   $callFunc
        #           - If specified, $self->$funcName is called when the IV is updated instead of the
        #               usual call to $self->updateListDataWithKey (useful if we don't want the
        #               simple list sorted alphabetically, as normally happens); otherwise set to
        #               'undef'
        #   @callFuncArgs
        #           - Optional list of args to be passed if $callFunc is called; otherwise an empty
        #               list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $key, $deRefFlag, $slWidget, $readOnlyFlag, $callFunc, @callFuncArgs) = @_;

        # Local variables
        my (
            $title, $labelText, $outerHashRef, $value, $response,
            %outerHash,
        );

        # Check for improper arguments
        if (! defined $iv) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->promptScalar', @_);
        }

        # Set the window title
        if ($readOnlyFlag) {
            $title = 'View Scalar';
        } else {
            $title = 'Edit Scalar';
        }

        # Show the 'dialogue' window
        my $dialogueWin;
        if (! $readOnlyFlag) {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-cancel' => 'reject',
                'gtk-ok'     => 'accept',
            );

        } else {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-ok'     => 'accept',
            );
        }

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            # (In case TTS is being used and another 'dialogue' window is about to open, make sure
            #   the window is visibly closed)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->promptScalar');
        });

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        # Create a label, which will shortly show which IV is being edited (a second label,
        #   $undefLabel, is sometimes used immediately below it)
        my $label = Gtk2::Label->new();
        $label->set_alignment(0, 0.5);

        # Create an entry, in which the user supplies a new value
        my $entry = Gtk2::Entry->new;
        if ($readOnlyFlag) {

            $entry->set_state('insensitive');
        }

        # Set the contents of the entry box, and prepare the label text
        if (! defined $key) {

            # Mode 1 - edit the value of $self->editObj->$iv or $self->editHash->$iv
            $labelText = 'Value of IV \'' . $iv . '\'';

            # If the IV hasn't yet been edited, use the original value
            if (! $self->ivExists('editHash', $iv)) {

                if (defined $self->editObj->{$iv}) {

                    # Put the current value in the entry box
                    $entry->append_text($self->editObj->{$iv});

                } else {

                    # Add more text to the label, to show that the value is 'undef'
                    $labelText .= ' <i>(currently \'undef\')</i>';
                }

            # If the IV has been edited, use the edited value
            } else {

                # Use an edited value
                if (defined $self->ivShow('editHash', $iv)) {

                    $entry->append_text($self->ivShow('editHash', $iv));

                } else {

                    # Add more text to the label, to show that the value is 'undef'
                    $labelText .= ' <i>(currently \'undef\')</i>';
                }
            }

        } else {

            # Mode 2 - edit the scalar stored in a key-value pair; the pair is in the hash
            #   stored as $self->editObj->$iv or $self->editHash->$iv
            $labelText = 'Value of key \'' . $key . '\' stored in IV \'' . $iv . '\'';

            # Get a copy of the hash being edited
            if (! $self->ivExists('editHash', $iv)) {

                %outerHash = $self->editObj->$iv;

            # If the IV has been edited, use the edited hash
            } else {

                $outerHashRef = $self->ivShow('editHash', $iv);
                %outerHash = %$outerHashRef;
            }

            if (exists $outerHash{$key}) {

                if (defined $outerHash{$key}) {

                    # Put the current value of the key-value pair in the entry box
                    $value = $outerHash{$key};
                    if ($deRefFlag) {

                        # Cage masks: $value is a scalar reference
                        $entry->append_text($$value);

                    } else {

                        # Everything else: $value is a normal scalar
                        $entry->append_text($value);
                    }

                } else {

                    # Add more text to the label, to show that the value is 'undef'
                    $labelText .= ' <i>(currently \'undef\')</i>';
                }
            }
        }

        # Set the label text
        $label->set_markup($labelText);

        # Pack the label and entry box
        $vBox2->pack_start($label, TRUE, TRUE, $self->spacingPixels);
        $vBox2->pack_start($entry, TRUE, TRUE, $self->spacingPixels);

        # Optionally add a button strip in the lower area, containing a single button
        if (! $readOnlyFlag) {

            my $hBox = Gtk2::HBox->new(FALSE, 0);
            $vBox2->pack_start($hBox, TRUE, TRUE, $self->spacingPixels);

            # Create the 'use undef' button
            my $button3 = Gtk2::Button->new('Use \'undef\' value');
            $hBox->pack_end($button3, FALSE, FALSE, $self->spacingPixels);

            $button3->signal_connect('clicked' => sub {

                # Store an 'undef' scalar value

                # Mode 1 - edit the scalar stored in $self->editObj->$iv or $self->editHash->$iv
                if (! defined $key) {

                    $self->ivAdd('editHash', $iv, undef);

                    # Update the simple list displayed in the parent window, if a list was specified
                    if ($slWidget) {

                        $self->updateListDataWithKey($slWidget, $iv, undef);
                    }

                # Mode 2 - edit the scalar stored in a key-value pair; the pair is in the hash
                #   stored as $self->editObj->$iv or $self->editHash->$iv
                } else {

                    # Update the hash stored in the IV with a new key-value pair. The key is $key,
                    #   the corresponding value is the new scalar
                    $outerHash{$key} = undef;

                    # Store the modified outer hash as the IV
                    $self->ivAdd('editHash', $iv, \%outerHash);

                    # Update the simple list displayed in the parent window, if a list was specified
                    if ($slWidget) {

                        $self->updateListDataWithKey($slWidget, $key, undef);
                    }
                }

                # Call a function to re-display the simple list in the parent window, if a function
                #   was specified
                if ($callFunc) {

                    $self->$callFunc(@callFuncArgs);
                }

                # Close the window and return success value
                $dialogueWin->destroy();
                $self->restoreFocus();

                # (In case TTS is being used and another 'dialogue' window is about to open, make
                #   sure the window is visibly closed)
                $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->promptScalar');

                return 1;
            });
        }

        # Widget drawing complete
        $vBox->show_all();

        # Get the response
        $response = $dialogueWin->run();
        if ($response eq 'accept') {

            my $scalar;

            # Don't save anything for read-only values
            if (! $readOnlyFlag) {

                $scalar = $entry->get_text();

                # Mode 1 - edit the value stored in of $self->editObj->$iv or $self->editHash->$iv
                if (! defined $key) {

                    # Store the edited scalar
                    $self->ivAdd('editHash', $iv, $scalar);

                    # Update the simple list displayed in the parent window, if a list was specified
                    if ($slWidget) {

                        $self->updateListDataWithKey($slWidget, $iv, $scalar);
                    }

                # Mode 2 - edit the scalar stored in a key-value pair; the pair is in the hash
                #   stored as $self->editObj->$iv or $self->editHash->$iv
                } else {

                    # Update the hash stored in the IV with a new key-value pair. The key is $key,
                    #   the corresponding value is the new scalar
                    if ($deRefFlag) {

                        # Cage masks: $value is a scalar reference
                        $value = \$scalar;

                    } else {

                        # Everything else: $value is a normal scalar
                        $value = $scalar;
                    }

                    $outerHash{$key} = $value;

                    # Store the modified outer hash as the IV
                    $self->ivAdd('editHash', $iv, \%outerHash);

                    # Update the simple list displayed in the parent window, if a list was specified
                    if ($slWidget) {

                        $self->updateListDataWithKey($slWidget, $key, $value);
                    }
                }

                # Call a function to re-display the simple list in the parent window, if a function
                #   was specified
                if ($callFunc) {

                    $self->$callFunc(@callFuncArgs);
                }
            }
        }

        # Destroy the window
        $dialogueWin->destroy();
        $self->restoreFocus();

        # (In case TTS is being used and another 'dialogue' window is about to open, make sure the
        #   window is visibly closed)
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->promptScalar');

        # Operation complete
        return 1;
    }

    sub promptList {

        # Creates a 'dialogue' window to prompt the user to view, enter (or edit) a list of values
        # If the user supplies any values, sets the IV then closes the window
        #
        # Operates in two modes
        #   Mode 1  - the supplied IV is a list, i.e.
        #               $self->editObj->$iv = [some_list]
        #               $self->editHash->$iv = [some_list]
        #           - the values supplied by the user are saved in place of [some_list]
        #
        #   Mode 2  - the supplied IV is a hash, i.e.
        #               $self->editObj->$iv = {some_hash}
        #               $self->editHash->$iv = {some_hash}
        #           - the calling function also supplies a key in {some_hash}
        #           - a reference to the list supplied by the user is saved as the key's
        #               corresponding value
        #
        # Expected arguments
        #   $iv - The IV to set in $self->editHash
        #
        # Optional arguments
        #   $key    - In mode 1, 'undef'; in mode 2, a key in {some_hash}
        #   $slWidget
        #           - In mode 1, 'undef'; in mode 2, 'undef' or the Gt2::Ex::Simple::List in which
        #               the IV's data is being displayed (if specified, the simple list is updated
        #               when this window is closed)
        #   $readOnlyFlag
        #           - If set to TRUE, the list is read-only (so can't be edited); otherwise set
        #               to FALSE (or 'undef')
        #   $callFunc
        #           - If specified, $self->$funcName is called when the IV is updated instead of the
        #               usual call to $self->updateListDataWithKey (useful if we don't want the
        #               simple list sorted alphabetically, as normally happens); otherwise set to
        #               'undef'
        #   @callFuncArgs
        #           - Optional list of args to be passed if $callFunc is called; otherwise an empty
        #               list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $key, $slWidget, $readOnlyFlag, $callFunc, @callFuncArgs) = @_;

        # Local variables
        my (
            $title, $replaceListRef, $outerHashRef, $response,
            %outerHash,
        );

        # Check for improper arguments
        if (! defined $iv) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->promptList', @_);
        }

        # Set the window title
        if ($readOnlyFlag) {
            $title = 'View List';
        } else {
            $title = 'Edit List';
        }

        # Show the 'dialogue' window
        my $dialogueWin;
        if (! $readOnlyFlag) {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-cancel' => 'reject',
                'gtk-ok'     => 'accept',
            );

        } else {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-ok'     => 'accept',
            );
        }

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            # (In case TTS is being used and another 'dialogue' window is about to open, make sure
            #   the window is visibly closed)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->promptList');
        });

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        # Create a label, which will shortly show which IV is being edited
        my $label = Gtk2::Label->new();
        $vBox2->pack_start($label, TRUE, TRUE, $self->spacingPixels);
        $label->set_alignment(0, 0.5);

        # Create a textview, in which the user supplies a list of values
        my $scroll = Gtk2::ScrolledWindow->new(undef, undef);
        $vBox2->pack_start($scroll, TRUE, TRUE, $self->spacingPixels);
        $scroll->set_shadow_type('etched-out');
        $scroll->set_policy('automatic', 'automatic');
        $scroll->set_size_request(200, 150);            # Minimum size
        $scroll->set_border_width($self->spacingPixels);

        # Create a textview with default colours/fonts
        $axmud::CLIENT->desktopObj->getTextViewStyle($self->winType);
        my $textView = Gtk2::TextView->new();
        $scroll->add($textView);

        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);

        if ($readOnlyFlag) {
            $textView->set_editable(FALSE);
        } else {
            $textView->set_editable(TRUE);
        }

        # Set the contents of the label and the textview
        if (! defined $key) {

            # Mode 1 - edit the list stored in $self->editObj->$iv or $self->editHash->$iv
            $label->set_markup('List stored in IV \'' . $iv . '\'');

            # If the IV hasn't yet been edited, use the original stored list
            if (! $self->ivExists('editHash', $iv)) {

                $replaceListRef = $self->editObj->{$iv};    # (Profile templates have no accessors)
                $buffer->set_text(join("\n", @$replaceListRef));

            # If the IV has been edited, use the edited list
            } else {

                $replaceListRef = $self->ivShow('editHash', $iv);
                $buffer->set_text(join("\n", @$replaceListRef));
            }

        } else {

            # Mode 2 - edit the list stored in a key-value pair; the pair is in the hash
            #   stored as $self->editObj->$iv or $self->editHash->$iv
            $label->set_markup('List stored in key \'' . $key . '\' in IV \'' . $iv . '\'');

            # Get a copy of the hash being edited
            if (! $self->ivExists('editHash', $iv)) {

                $outerHashRef = $self->editObj->{$iv};      # (Profile templates have no accessors)
                %outerHash = %$outerHashRef;

            } else {

                $outerHashRef = $self->ivShow('editHash', $iv);
                %outerHash = %$outerHashRef;
            }

            # Put the current contents of the list in the textview
            if (exists $outerHash{$key} && defined $outerHash{$key}) {

                $replaceListRef = $outerHash{$key};
                $buffer->set_text(join("\n", @$replaceListRef));
            }
        }

        # Widget drawing complete
        $vBox->show_all();

        # Get the response
        $response = $dialogueWin->run();
        if ($response eq 'accept') {

            my (
                $text,
                @dataList,
            );

            # Don't save anything for read-only values
            if (! $readOnlyFlag) {

                $text = $axmud::CLIENT->desktopObj->bufferGetText($buffer);

                # Split the contents of the textview into a list of lines, separated by
                #   newline characters
                @dataList = split("\n", $text);

                # Mode 1 - edit the list stored in of $self->editObj->$iv or $self->editHash->$iv
                if (! defined $key) {

                    # Store the list we've been editing
                    $self->ivAdd('editHash', $iv, \@dataList);

                    # Update the simple list displayed in the parent window, if a list was specified
                    if ($slWidget) {

                        $self->updateListDataWithKey($slWidget, $iv, \@dataList);
                    }

                # Mode 2 - edit the list stored in a key-value pair; the pair is in the hash
                #   stored as $self->editObj->$iv or $self->editHash->$iv
                } else {

                    # Update the hash stored in the IV with a new key-value pair. The key is
                    #   $key, the corresponding value is a reference to the list we've
                    #   been editing, @dataList
                    $outerHash{$key} = \@dataList;

                    # Store the modified outer hash as the IV
                    $self->ivAdd('editHash', $iv, \%outerHash);

                    # Update the simple list displayed in the parent window, if a list was specified
                    if ($slWidget) {

                        $self->updateListDataWithKey($slWidget, $key, \@dataList);
                    }
                }

                # Call a function to re-display the simple list in the parent window, if a function
                #   was specified
                if ($callFunc) {

                    $self->$callFunc(@callFuncArgs);
                }
            }
        }

        # Destroy the window
        $dialogueWin->destroy();
        $self->restoreFocus();

        # (In case TTS is being used and another 'dialogue' window is about to open, make sure the
        #   window is visibly closed)
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->promptList');

        # Operation complete
        return 1;
    }

    sub promptHash {

        # Creates a 'dialogue' window to prompt the user to view, enter (or edit) a hash of
        #   key-value pairs
        # If the user supplies any pairs, sets the IV then closes the window
        #
        # Operates in two modes
        #   Mode 1  - the supplied IV is a hash, i.e.
        #               $self->editObj->$iv = {some_hash}
        #               $self->editHash->$iv = {some_hash}
        #           - the key-value pairs supplied by the user are saved in place of {some_hash}
        #
        #   Mode 2  - the supplied IV is a hash, i.e.
        #               $self->editObj->$iv = {some_hash}
        #               $self->editHash->$iv = {some_hash}
        #           - the calling function also supplies a key in {some_hash}
        #           - a reference to the hash supplied by the user is saved as the key's
        #               corresponding value
        #
        # Expected arguments
        #   $iv     - The IV to set in $self->editObj
        #
        # Optional arguments
        #   $key    - In mode 1, 'undef'; in mode 2, a key in {some_hash}
        #   $slWidget
        #           - In mode 1, 'undef'; in mode 2, 'undef' or the Gt2::Ex::Simple::List in which
        #               the IV's data is being displayed (if specified, the simple list is updated
        #               when this window is closed)
        #   $readOnlyFlag
        #           - If set to TRUE, the scalar is read-only (so can't be edited); otherwise set to
        #               FALSE (or 'undef')
        #   $callFunc
        #           - If specified, $self->$funcName is called when the IV is updated instead of the
        #               usual call to $self->updateListDataWithKey (useful if we don't want the
        #               simple list sorted alphabetically, as normally happens); otherwise set to
        #               'undef'
        #   @callFuncArgs
        #           - Optional list of args to be passed if $callFunc is called; otherwise an empty
        #               list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $key, $slWidget, $readOnlyFlag, $callFunc, @callFuncArgs) = @_;

        # Local variables
        my (
            $title, $response, $outerHashRef,
            %outerHash, %replaceHash, %innerHash,
        );

        # Check for improper arguments
        if (! defined $iv) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->promptHash', @_);
        }

        # Set the window title
        if ($readOnlyFlag) {
            $title = 'View Hash';
        } else {
            $title = 'Edit Hash';
        }

        # Show the 'dialogue' window
        my $dialogueWin;
        if (! $readOnlyFlag) {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-cancel' => 'reject',
                'gtk-ok'     => 'accept',
            );

        } else {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-ok'     => 'accept',
            );
        }

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            # (In case TTS is being used and another 'dialogue' window is about to open, make sure
            #   the window is visibly closed)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->promptHash');
        });

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        # Create a label, which will shortly show which IV is being edited
        my $label = Gtk2::Label->new();
        $vBox2->pack_start($label, TRUE, TRUE, $self->spacingPixels);
        $label->set_alignment(0, 0.5);

        # Create a scroller
        my $scroller = Gtk2::ScrolledWindow->new;
        $vBox2->pack_start($scroller, TRUE, TRUE, $self->spacingPixels);
        $scroller->set_policy('automatic', 'automatic');
        $scroller->set_size_request(200, 150);          # Minimum size

        # Create a simple list with two columns representing a hash, for which the user
        #   supplies key-value pairs
        my $slWidget2 = Games::Axmud::Gtk::Simple::List->new(
            # Give the first column a minimum width; don't want the columns moving around too
            #   much when the user enter new key-value pairs
            'Key           ' => 'text',
            'Value'          => 'text',
        );
        $scroller->add($slWidget2);

        # Set the contents of the label and the simple list. We don't want to overwrite the hash
        #   until the user clicks the 'ok' button, so we'll edit a copy of the hash
        if (! defined $key) {

            # Mode 1 - edit the hash stored in $self->editObj->$iv or $self->editHash->$iv
            $label->set_markup('Hash stored in IV \'' . $iv . '\'');
            %outerHash = $self->promptHash_displayDataMode1($slWidget2, $iv);
            # Edit a copy, so that we can revert to the original copy if we want to
            %replaceHash = %outerHash;

        } else {

            # Mode 2 - edit the hash stored in a key-value pair; the pair is in the hash
            #   stored as $self->editObj->$iv or $self->editHash->$iv
            $label->set_markup('Hash stored in key \'' . $key . '\' in IV \'' . $iv . '\'');
            %innerHash = $self->promptHash_displayDataMode2($slWidget2, $iv, $key);
            # Edit a copy, so that we can revert to the original copy if we want to
            %replaceHash = %innerHash;
        }

        # If the hash is editable, we have a lot more widgets to add
        if (! $readOnlyFlag) {

            # Add a table containing entry boxes for new key-value pairs. The table ensures that
            #   the two entry boxes are aligned with each other
            my $table = Gtk2::Table->new(2, 2, FALSE);
            $vBox2->pack_start($table, TRUE, TRUE, $self->spacingPixels);

            my $label2 = Gtk2::Label->new();
            $label2->set_alignment(0, 0.5);
            $label2->set_markup('Key');
            $table->attach_defaults($label2, 0, 1, 0, 1);

            my $entry = Gtk2::Entry->new();
            $table->attach_defaults($entry, 1, 2, 0, 1);

            my $label3 = Gtk2::Label->new();
            $label3->set_alignment(0, 0.5);
            $label3->set_markup('Value');
            $table->attach_defaults($label3, 0, 1, 1, 2);

            my $entry2 = Gtk2::Entry->new();
            $table->attach_defaults($entry2, 1, 2, 1, 2);

            # Add a button strip containing editing buttons
            my $tooltips = Gtk2::Tooltips->new();
            my $hBox = Gtk2::HBox->new(FALSE, 0);
            $vBox2->pack_start($hBox, TRUE, TRUE, $self->spacingPixels);

            # 'Add' button
            my $button = Gtk2::Button->new('Add');
            $hBox->pack_start($button, FALSE, FALSE, $self->spacingPixels);
            $tooltips->set_tip($button, 'Add a key-value pair');
            $button->signal_connect('clicked' => sub {

                my ($thisKey, $thisValue);

                $thisKey = $entry->get_text();
                $thisValue = $entry2->get_text();

                # Update the hash we're editing...
                $replaceHash{$thisKey} = $thisValue;
                # ...and update the displayed simple list
                $self->updateListDataWithKey($slWidget2, $thisKey, $thisValue);

                # Empty the entry boxes
                $self->resetEntryBoxes($entry, $entry2);
            });

            # 'Undef' button
            my $button2 = Gtk2::Button->new('Undef');
            $hBox->pack_start($button2, FALSE, FALSE, $self->spacingPixels);
            $tooltips->set_tip($button2, 'Add a key-value pair, with the value set to \'undef\'');
            $button2->signal_connect('clicked' => sub {

                my $thisKey = $entry->get_text();

                # Update the hash we're editing...
                $replaceHash{$thisKey} = undef;
                # ...and update the displayed simple list
                $self->updateListDataWithKey($slWidget2, $thisKey, undef);

                # Empty the entry boxes
                $self->resetEntryBoxes($entry, $entry2);
            });

            # 'Delete' button
            my $button3 = Gtk2::Button->new('Delete');
            $hBox->pack_start($button3, FALSE, FALSE, $self->spacingPixels);
            $tooltips->set_tip($button3, 'Delete the selected key-value pair');
            $button3->signal_connect('clicked' => sub {

                my (
                    $thisKey,
                    @selectList,
                );

                # Update the hash we're editing...
                ($thisKey) = $self->getSimpleListData($slWidget2, 0, 1);
                if (defined $thisKey) {


                    delete $replaceHash{$thisKey};
                    # ...and update the displayed simple list
                    @selectList = $slWidget2->get_selected_indices();
                    splice(@{$slWidget2->{data}}, $selectList[0], 1);
                }
            });

            # 'Reset' button
            my $button4 = Gtk2::Button->new('Reset');
            $hBox->pack_start($button4, FALSE, FALSE, $self->spacingPixels);
            $tooltips->set_tip($button4, 'Undo changes to the hash');
            $button4->signal_connect('clicked' => sub {

                # Update the hash we're editing...
                if (! defined $key) {

                    # Mode 1
                    $self->promptHash_displayDataMode1($slWidget2, $iv);
                    %replaceHash = %outerHash;

                } else {

                    # Mode 2
                    $self->promptHash_displayDataMode2($slWidget2, $iv, $key);
                    %replaceHash = %innerHash;
                }

                # ...and update the displayed simple list
                @{$slWidget2->{data}} = ();

                if (! defined $key) {
                    $self->promptHash_displayDataMode1($slWidget2, $iv);
                } else {
                    $self->promptHash_displayDataMode2($slWidget2, $iv, $key);
                }
            });

            # 'Clear' button
            my $button5 = Gtk2::Button->new('Clear');
            $hBox->pack_start($button5, FALSE, FALSE, $self->spacingPixels);
            $tooltips->set_tip($button5, 'Clear the hash');
            $button5->signal_connect('clicked' => sub {

                # Update the hash we're editing...
                %replaceHash = ();
                # ...and update the displayed simple list
                @{$slWidget2->{data}} = ();
            });
        }

        # Widget drawing complete
        $vBox->show_all();

        # Get the response
        $response = $dialogueWin->run();
        if ($response eq 'accept') {

            # Don't save anything for read-only values
            if (! $readOnlyFlag) {

                # Mode 1 - edit the hash stored in $self->editObj->$iv or $self->editHash->$iv
                if (! defined $key) {

                    # Store the hash we've been editing
                    $self->ivAdd('editHash', $iv, \%replaceHash);

                    # Update the simple list displayed in the parent window, if a list was specified
                    if ($slWidget) {

                        $self->updateListDataWithKey($slWidget, $iv, \%replaceHash);
                    }

                # Mode 2 - edit the hash stored in a key-value pair; the pair is in the hash stored
                #   as $self->editObj->$iv or $self->editHash->$iv
                } else {

                    # Get a copy of the hash stored in the IV
                    if (! $self->ivExists('editHash', $iv)) {

                        %outerHash = $self->editObj->$iv;

                    # If the IV has been edited, use the edited hash
                    } else {

                        $outerHashRef = $self->ivShow('editHash', $iv);
                        %outerHash = %$outerHashRef;
                    }

                    # Now update that hash with a new key-value pair. The key is $key, the
                    #   corresponding value is a reference to the hash we've been editing,
                    #   %replaceHash
                    $outerHash{$key} = \%replaceHash;

                    # Store the modified outer hash as the IV
                    $self->ivAdd('editHash', $iv, \%outerHash);

                    # Update the displayed list, if one was specified
                    if ($slWidget) {

                        $self->updateListDataWithKey($slWidget, $key, \%replaceHash);
                    }
                }

                # Call a function to re-display the simple list, if one was specified
                if ($callFunc) {

                    $self->$callFunc(@callFuncArgs);
                }
            }
        }

        # Destroy the window
        $dialogueWin->destroy();
        $self->restoreFocus();

        # (In case TTS is being used and another 'dialogue' window is about to open, make sure the
        #   window is visibly closed)
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->promptHash');

        # Operation complete
        return 1;
    }

    sub promptHash_displayDataMode1 {

        # Called by $self->promptHash when we want to edit a hash IV in $self->editObj or
        #   $self->editHash
        # The calling function had created a GA::Gtk::Simple::List; this function's job is to fill
        #   it with data
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List where the IV's data is displayed
        #   $iv         - The IV being edited
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise returns a copy of the hash being edited

        my ($self, $slWidget, $iv, $check) = @_;

        # Local variables
        my (
            $hashRef,
            %emptyHash, %dataHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $iv || defined $check) {

            $axmud::CLIENT->writeImproper(
                $self->_objClass . '->promptHash_displayDataMode1',
                @_,
            );

            return %emptyHash;
        }

        # If the IV hasn't yet been edited, use the original stored hash
        if (! $self->ivExists('editHash', $iv)) {

            $hashRef = $self->editObj->{$iv};        # (Profile templates have no accessors)
            %dataHash = %$hashRef;

        # If the IV has been edited, use the edited hash
        } else {

            $hashRef = $self->ivShow('editHash', $iv);
            %dataHash = %$hashRef;
        }

        # Update the GA::Gtk::Simple::List (which currently stores no data)
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %dataHash)) {

            push (
                @{$slWidget->{data}},
                [$key, $dataHash{$key}],
            );
        }

        return %dataHash;
    }

    sub promptHash_displayDataMode2 {

        # Called by $self->promptHash when we want to edit a hash, stored as a reference in an IV of
        #   $self->editObj or $self->editHash
        #
        # i.e.  SomeObject->{myHash} = {
        #               iv1     => value,
        #               iv2     => value,
        #               iv3     => hash_reference_to_edit,
        #       }
        #
        # The calling function had created a GA::Gtk::Simple::List to display
        #   hash_reference_to_edit; this function's job is to fill it with data
        #
        # Expected arguments
        #   $slWidget   - The GA::Gtk::Simple::List where the IV's data is displayed
        #   $iv         - The IV being edited ('myHash' in the example above)
        #   $key        - The IV is a hash. $key is a key in that hash; $key's corresponding value
        #                   is the reference to the hash which we display in the simple list ('iv3'
        #                   in the example above)
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise returns a copy of the hash being edited

        my ($self, $slWidget, $iv, $key, $check) = @_;

        # Local variables
        my (
            $hashRef, $dataHashRef,
            %emptyHash, %hash, %dataHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $iv || ! defined $key || defined $check) {

            $axmud::CLIENT->writeImproper(
                $self->_objClass . '->promptHash_displayDataMode2',
                @_,
            );

            return %emptyHash;
        }

        # If the IV hasn't yet been edited, use the original stored hash
        if (! $self->ivExists('editHash', $iv)) {

            $hashRef = $self->editObj->{$iv};        # (Profile templates have no accessors)
            %hash = %$hashRef;

        # If the IV has been edited, use the edited hash
        } else {

            $hashRef = $self->ivShow('editHash', $iv);
            %hash = %$hashRef;
        }

        # Update the GA::Gtk::Simple::List (which currently stores no data)
        if (exists $hash{$key} && defined $hash{$key}) {

            $dataHashRef = $hash{$key};
            %dataHash = %$dataHashRef;

            foreach my $key (sort {lc($a) cmp lc($b)} (keys %dataHash)) {

                push (
                    @{$slWidget->{data}},
                    [$key, $dataHash{$key}],
                );
            }
        }

        return %dataHash;
    }

    # General support functions

    sub sensitiseWidgets {

        # Sensitises a list of Gtk2 widgets
        #
        # Expected arguments
        #   @list   - The list of widgets to sensitise
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, @list) = @_;

        # Check for improper arguments
        if (! @list) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sensitiseWidgets', @_);
        }

        foreach my $widget (@list) {

            $widget->set_sensitive(TRUE);
        }

        return 1;
    }

    sub desensitiseWidgets {

        # Desensitises a list of Gtk2 widgets
        #
        # Expected arguments
        #   @list   - The list of widgets to desensitise
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, @list) = @_;

        # Check for improper arguments
        if (! @list) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->desensitiseWidgets', @_);
        }

        foreach my $widget (@list) {

            $widget->set_sensitive(FALSE);
        }

        return 1;
    }

    # Standard callbacks

    sub buttonCancel {

        # 'Cancel' button callback
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonCancel', @_);
        }

        # Close the window
        $self->winDestroy();

        return 1;
    }

    sub buttonOK {

        # 'OK' button callback
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonOK', @_);
        }

        # Save changes
        $self->saveChanges();

        # Close the window
        $self->winDestroy();

        return 1;
    }

    sub buttonReset {

        # 'Reset' button callback
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $number;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonReset', @_);
        }

        # Remove all the existing tabs from the notebook
        $number = $self->notebook->get_n_pages();
        if ($number) {

            for (my $count = 0; $count < $number; $count++) {

                $self->notebook->remove_page(0);
            }
        }

        # Empty $self->editHash, destroying all the changes
        $self->ivEmpty('editHash');

        # Re-draw all the tabs
        $self->setupNotebook();
        # Render the changes
        $self->winShowAll($self->_objClass . '->buttonReset');

        return 1;
    }

    sub buttonSave {

        # 'Save' button callback
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $number;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonSave', @_);
        }

        # Save changes
        $self->saveChanges();

        # Reset the hash of functions to call when a child window is closed, ready for it to be
        #   refilled
        $self->ivEmpty('childDestroyHash');

        # Remove all the tabs
        $number = $self->notebook->get_n_pages();
        if ($number) {

            for (my $count = 0; $count < $number; $count++) {

                $self->notebook->remove_page(0);
            }
        }

        # Re-draw all the tabs
        $self->setupNotebook();
        # Render the changes
        $self->winShowAll($self->_objClass . '->buttonSave');

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub notebook
        { $_[0]->{notebook} }
    sub hBox
        { $_[0]->{hBox} }
    sub tooltips
        { $_[0]->{tooltips} }
    sub okButton
        { $_[0]->{okButton} }
    sub cancelButton
        { $_[0]->{cancelButton} }
    sub resetButton
        { $_[0]->{resetButton} }
    sub saveButton
        { $_[0]->{saveButton} }

    sub tableSize
        { $_[0]->{tableSize} }

    sub editObj
        { $_[0]->{editObj} }
    sub tempFlag
        { $_[0]->{tempFlag} }
    sub currentFlag
        { $_[0]->{currentFlag} }
    sub editHash
        { my $self = shift; return %{$self->{editHash}}; }
    sub editConfigHash
        { my $self = shift; return %{$self->{editConfigHash}}; }
}

{ package Games::Axmud::Generic::EditWin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::ConfigWin Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win
        Games::Axmud
    );

    ##################
    # Constructors

#   sub new {}              # Inherited from GA::Generic::ConfigWin

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::ConfigWin

#   sub winEnable {}        # Inherited from GA::Generic::ConfigWin

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}       # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}       # Inherited from GA::Generic::Win

#   sub drawWidgets {}      # Inherited from GA::Generic::ConfigWin

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Generic::FixedWin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::GridWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Workspace->createGridWin and ->createSimpleGridWin
        # Generic function to create a 'fixed' window
        #
        # Expected arguments
        #   $number     - Unique number for this window object
        #   $winType    - The window type, must be 'fixed'
        #   $winName    - The window name, must be 'fixed'
        #   $workspaceObj
        #               - The GA::Obj::Workspace object for the workspace in which this window is
        #                   created
        #
        # Optional arguments
        #   $owner      - The owner, if known ('undef' if not). Typically it's a GA::Session or a
        #                   task (inheriting from GA::Generic::Task); could also be GA::Client.
        #                   It should not be another window object
        #                   (inheriting from GA::Generic::Win). The owner should have its own
        #                   ->del_winObj function which is called when $self->winDestroy is
        #                   called
        #   $session    - The owner's session. If $owner is a GA::Session, that session. If
        #                   it's something else (like a task), the task's session. If $owner is
        #                   'undef', so is $session
        #   $workspaceGridObj
        #               - The GA::Obj::WorkspaceGrid object into whose grid this window has been
        #                   placed. 'undef' in $workspaceObj->gridEnableFlag = FALSE
        #   $areaObj    - The GA::Obj::Area (a region of a workspace grid zone) which handles this
        #                   window. 'undef' in $workspaceObj->gridEnableFlag = FALSE
        #   $winmap     - Ignored if set
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $winType, $winName, $workspaceObj, $owner, $session, $workspaceGridObj,
            $areaObj, $winmap, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $winType || ! defined $winName
            || ! defined $workspaceObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that the $winType is valid
        if ($winType ne 'fixed') {

            return $axmud::CLIENT->writeError(
                'Internal window error: invalid \'fixed\' window type \'' . $winType . '\'',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => 'fixed_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'grid',
            # The window type, must be 'fixed'
            winType                     => $winType,
            # The window name, must be 'fixed'
            winName                     => $winName,
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner, if known ('undef' if not). Typically it's a GA::Session or a task
            #   (inheriting from GA::Generic::Task); could also be GA::Client. It should not be
            #   another window object (inheriting from GA::Generic::Win). The owner must have its
            #   own ->del_winObj function which is called when $self->winDestroy is called
            owner                       => $owner,
            # The owner's session ('undef' if not). If ->owner is a GA::Session, that session. If
            #   it's something else (like a task), the task's sesssion. If ->owner is 'undef', so is
            #   ->session
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,

            # Standard IVs for 'grid' windows

            # The GA::Obj::WorkspaceGrid object into whose grid this window has been placed. 'undef'
            #   in $workspaceObj->gridEnableFlag = FALSE
            workspaceGridObj            => $workspaceGridObj,
            # The GA::Obj::Area object for this window. An area object is a part of a zone's
            #   internal grid, handling a single window (this one). Set to 'undef' in
            #   $workspaceObj->gridEnableFlag = FALSE
            areaObj                     => $areaObj,
            # For pseudo-windows (in which a window object is created, but its widgets are drawn
            #   inside a GA::Table::PseudoWin table object), the table object created. 'undef' if
            #   this window object is a real 'grid' window
            pseudoWinTableObj           => undef,
            # The name of the GA::Obj::Winmap object (not used for 'map' windows)
            winmap                      => undef,

            # Standard IVs for 'fixed' windows
            #   ...
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::GridWin

#   sub winEnable {}        # Inherited from GA::Generic::GridWin

#   sub winDisengage {}     # Defined in window objects which inherit this one

#   sub winDestroy {}       # Defined in window objects which inherit this one

#   sub winShowAll {}       # Inherited from GA::Generic::Win

#   sub drawWidgets {}      # Inherited from GA::Generic::Win

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Generic::FreeWin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Win Games::Axmud);

    ##################
    # Constructors

#   sub new {}              # Defined in window objects which inherit this one

    ##################
    # Methods

    # Standard window object functions

    sub winSetup {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->new
        # Creates the Gtk2::Window itself
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be opened
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winSetup', @_);
        }

        # Create the Gtk2::Window
        my $winWidget = Gtk2::Window->new('toplevel');
        if (! $winWidget) {

            return undef;

        } else {

            # Store the IV now, as subsequent code needs it
            $self->ivPoke('winWidget', $winWidget);
            $self->ivPoke('winBox', $winWidget);
        }

        # Set up ->signal_connects
        $self->setDeleteEvent();            # 'delete-event'

        # Set the window title
        $winWidget->set_title($self->title);

        # Set the window's default size and position
        $winWidget->set_default_size($self->widthPixels, $self->heightPixels);
        $winWidget->set_border_width($self->borderPixels);
        $winWidget->set_position('center');

        # Set the icon list for this window
        $iv = $self->winType . 'WinIconList';
        $winWidget->set_icon_list($axmud::CLIENT->desktopObj->$iv);

        # Draw the widgets used by this window
        if (! $self->drawWidgets()) {

            return undef;
        }

        # The calling function can now call $self->winEnable to make the window visible
        return 1;
    }

    sub winEnable {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->winSetup
        # After the Gtk2::Window has been setup and moved into position, makes it visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

        return 1;
    }

    sub winDisengage {

        # Should not be called, in general (provides compatibility with other types of windows,
        #   whose window objects can be destroyed without closing the windows themselves)
        # If called, this function just calls $self->winDestroy and returns the result
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be disengaged
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDisengage', @_);
        }

        return $self->winDestroy();
    }

    sub winDestroy {

        # Can be called by anything
        # Updates IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the window can't be destroyed or if it has already
        #       been destroyed
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDestroy', @_);
        }

        if (! $self->winBox) {

            # Window already destroyed in a previous call to this function
            return undef;
        }

        # Close any 'free' windows for which this window is a parent
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Destroy the Gtk2::Window
        eval { $self->winBox->destroy(); };
        if ($@) {

            # Window can't be destroyed
            return undef;

        } else {

            $self->ivUndef('winWidget');
            $self->ivUndef('winBox');
        }

        # Inform the owner and the desktop object of this 'free' window's demise
        $axmud::CLIENT->desktopObj->del_freeWin($self);
        if ($self->owner) {

            $self->owner->del_childFreeWin($self);
        }

        return 1;
    }

#   sub winShowAll {}       # Inherited from GA::Generic::Win

#   sub drawWidgets {}      # Inherited from GA::Generic::Win

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    sub setDeleteEvent {

        # Called by $self->winSetup
        # Set up a ->signal_connect to watch out for the user manually closing the 'free' window
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setDeleteEvent', @_);
        }

        $self->winBox->signal_connect('delete-event' => sub {

            # Prevent Gtk2 from taking action directly. Instead redirect the request to
            #   $self->winDestroy
            return $self->winDestroy();
        });

        return 1;
    }

    # Other functions

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub widthPixels
        { $_[0]->{widthPixels} }
    sub heightPixels
        { $_[0]->{heightPixels} }
    sub borderPixels
        { $_[0]->{borderPixels} }
    sub spacingPixels
        { $_[0]->{spacingPixels} }

    sub title
        { $_[0]->{title} }
    sub configHash
        { my $self = shift; return %{$self->{configHash}}; }
    sub packingBox
        { $_[0]->{packingBox} }
}

{ package Games::Axmud::Generic::GridWin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Win Games::Axmud);

    ##################
    # Constructors

#   sub new {}                  # Defined in window objects which inherit this one

    ##################
    # Methods

    # Standard window object functions

    sub winSetup {

        # Called by GA::Obj::Workspace->createGridWin or ->createSimpleGridWin
        # This generic function merely creates a Gtk2::Window
        # Your own window object code should either create a function based on
        #   GA::Win::Internal->winSetup, or your code should inherit that function directly
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $title      - The window title or 'undef'. Ignored in this generic function
        #   $listRef    - Reference to a list of functions to call, just after the Gtk2::Window is
        #                   created (can be used to set up further ->signal_connects, if this
        #                   window needs them)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be opened
        #   1 on success

        my ($self, $title, $listRef, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winSetup', @_);
        }

        # Don't create a new window, if it already exists
        if ($self->enabledFlag) {

            return undef;
        }

        # Create the Gtk2::Window
        my $winWidget = Gtk2::Window->new('toplevel');
        if (! $winWidget) {

            return undef;

        } else {

            # Store the IV now, as everything needs it
            $self->ivPoke('winWidget', $winWidget);
            $self->ivPoke('winBox', $winWidget);
        }

        # Set up ->signal_connects specified by the calling function, if any
        if ($listRef) {

            foreach my $func (@$listRef) {

                $self->$func();
            }
        }

        # Set the icon list for this window
        $iv = $self->winType . 'WinIconList';
        $winWidget->set_icon_list($axmud::CLIENT->desktopObj->$iv);

        # Draw the widgets used by this window
        if (! $self->drawWidgets($winWidget)) {

            return undef;
        }

        # The calling function can now move the window into position, before calling
        #   $self->winEnable to make it visible, and to set up any more ->signal_connects()
        return 1;
    }

    sub winEnable {

        # Called by GA::Obj::Workspace->createGridWin or ->createSimpleGridWin
        # This generic function merely makes the Gtk2::Window visible
        # Your own window object code should either create a function based on
        #   GA::Win::Internal->winEnable, or your code should inherit that function directly
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $listRef    - Reference to a list of functions to call, just after the Gtk2::Window is
        #                   created (can be used to set up further ->signal_connects, if this
        #                   window needs them)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $title, $listRef, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

        # For windows about to be placed on a grid, briefly minimise the window so it doesn't
        #   appear in the centre of the desktop before being moved to its correct workspace, size
        #   and position
        if ($self->workspaceGridObj && $self->winWidget eq $self->winBox) {

            $self->winWidget->iconify();
        }

        # Set up ->signal_connects specified by the calling function, if any
        if ($listRef) {

            foreach my $func (@$listRef) {

                $self->$func();
            }
        }

        return 1;
    }

#   sub winDisengage {}         # Defined in window objects which inherit this one

#   sub winDestroy {}           # Defined in window objects which inherit this one

#   sub winShowAll {}           # Inherited from GA::Win::Generic

#   sub drawWidgets {}          # Inherited from GA::Win::Generic

#   sub redrawWidgets {}        # Inherited from GA::Win::Generic

    # ->signal_connects

    sub setDeleteEvent {

        # Called by GA::Obj::Workspace->createGridWin (for 'external' windows only)
        # Called by $self->winSetup (for other 'grid' windows)
        # This generic function doesn't actually create any ->signal_connects
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setDeleteEvent', @_);
        }

        # (Do nothing)

        return 1;
    }

    sub setKeyPressEvent {

        # Called by $self->winSetup
        # This generic function doesn't actually create any ->signal_connects
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setKeyPressEvent', @_);
        }

        # (Do nothing)

        return 1;
    }

    sub setKeyReleaseEvent {

        # Called by $self->winSetup
        # This generic function doesn't actually create any ->signal_connects
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setKeyReleaseEvent', @_);
        }

        # (Do nothing)

        return 1;
    }

    sub setCheckResizeEvent {

        # Called by $self->winEnable
        # This generic function doesn't actually create any ->signal_connects
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setCheckResizeEvent', @_);
        }

        # (Do nothing)

        return 1;
    }

    sub setWindowStateEvent {

        # Called by $self->winEnable
        # This generic function doesn't actually create any ->signal_connects
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setCheckResizeEvent', @_);
        }

        # (Do nothing)

        return 1;
    }

    sub setWindowClosedEvent {

        # Called by GA::Obj::Workspace->createGridWin (for 'external' windows only)
        # This generic function doesn't actually create any ->signal_connects
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setWindowClosedEvent', @_);
        }

        # (Do nothing)

        return 1;
    }

    # Other functions

    ##################
    # Accessors - set

    sub set_areaObj {

        my ($self, $areaObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_areaObj', @_);
        }

        $self->ivPoke('areaObj', $areaObj);

        return 1;
    }

    sub set_workspaceGridObj {

        my ($self, $workspaceGridObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_workspaceGridObj', @_);
        }

        $self->ivPoke('workspaceGridObj', $workspaceGridObj);

        return 1;
    }

    ##################
    # Accessors - get

    sub workspaceGridObj
        { $_[0]->{workspaceGridObj} }
    sub areaObj
        { $_[0]->{areaObj} }
    sub pseudoWinTableObj
        { $_[0]->{pseudoWinTableObj} }
    sub winmap
        { $_[0]->{winmap} }
}

{ package Games::Axmud::Generic::Interface;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    ##################
    # Methods

    sub modifyAttribs {

        # Called by GA::Generic::Cmd->modifyInterface (caused by ';modifytrigger', etc)
        # Modifies this object's IVs (the calling function modifies attributes on the corresponding
        #   inactive interface)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   %attribHash     - A hash of attributes, in the form
        #                       (attribute, value, attribute, value...)
        #                   - The keys can match any of the keys in $self->attribHash, or the
        #                       standard attributes 'name', 'stimulus', 'response', 'enabled'
        #
        # Return values
        #   'undef' on improper arguments or if any of the keys in %attribHash are unrecognised
        #       attributes
        #   1 otherwise

        my ($self, $session, %attribHash) = @_;

        # Local variables
        my $modelObj;

        # Check for improper arguments
        if (! defined $session) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->modifyAttribs', @_);
        }

        # If an empty hash was supplied, then of course we do nothing (but still show 1 for success)
        if (! %attribHash) {

            return 1;
        }

        # Get the corresponding interface model object
        $modelObj = $axmud::CLIENT->ivShow('interfaceModelHash', $self->category);

        # Check that every key in %attribHash is valid, before we start modifying any values
        foreach my $attrib (keys %attribHash) {

            my ($type, $value);

            if (
                $attrib ne 'name' && $attrib ne 'stimulus' && $attrib ne 'response'
                && $attrib ne 'enabled'
                && ! $self->ivExists('attribHash', $attrib)
            ) {
                return $self->writeError(
                    'Unrecognised attribute \'' . $attrib . '\' for interface category \''
                    . $self->category . '\'',
                    $self->_objClass . '->modifyAttribs',
                );
            }

            # Check the value is valid
            $type = $modelObj->ivShow('attribTypeHash', $attrib);
            $value = $self->checkAttribValue($session, $attrib, $attribHash{$attrib}, $type);
            if (! defined $value) {

                # Error message already displayed
                return undef;

            } else {

                # ->checkAttribValue modifies some $values (e.g. converts booleans to TRUE or FALSE)
                $attribHash{$attrib} = $value;
            }
        }

        # Modify stored attributes
        foreach my $key (keys %attribHash) {

            my $value = $attribHash{$key};

            # Standard attributes
            if ($key eq 'name') {

                $self->ivPoke('name', $value);

            } elsif ($key eq 'stimulus') {

                $self->ivPoke('stimulus', $value);

            } elsif ($key eq 'response') {

                $self->ivPoke('response', $value);

            } elsif ($key eq 'enabled') {

                if ($value) {
                    $self->ivPoke('enabledFlag', TRUE);
                } else {
                    $self->ivPoke('enabledFlag', FALSE);
                }

            # Category-dependent attributes
            } else {

                $self->ivAdd('attribHash', $key, $value);
            }
        }

        return 1;
    }

    sub checkAttribValue {

        # Called by GA::Generic::Interface->set_attribHash
        # Called by GA::Interface::Active->modifyAttributes
        # Called by GA::Generic::Cmd->addInterface
        #
        # Given an interface attribute, its corresponding value and the attribute type, checks that
        #   the value is valid. Also modifies the value in some circumstances (e.g. for the
        #   'boolean' type, converts it to TRUE or FALSE)
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $attrib     - The name of the attribute
        #   $value      - The corresponding value
        #   $type       - The attribute type, one of 'boolean', 'colour', 'hook_event',
        #                   'instruction', 'interval', 'keycode', 'mode', 'number', 'pattern',
        #                   'repeat_count', 'string', 'style', 'substitution' or 'underlay'
        #
        # Return values
        #   'undef' on improper arguments, if $value isn't valid or if $type is unrecognised
        #   Otherwise, returns $value (possibly after being modified)

        my ($self, $session, $attrib, $value, $type, $check) = @_;

        # Local variables
        my ($char, $modelObj);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $attrib || ! defined $value || ! defined $type
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkAttribValue', @_);
        }

        if ($type eq 'boolean') {

            # Convert $value to TRUE of FALSE
            $char = substr ($value, 0, 1);

            if (
                ! $value                            # zero (or an empty string)
                || $char eq 'f' || $char eq 'F'     # any word beginning with 'f'/'F'
            ) {
                return FALSE;

            } elsif (
                $value eq '1'                       # one
                || $char eq 't' || $char eq 'T'     # any word beginning with 't'/'T'
            ) {
                return TRUE;

            } else {

                return $session->writeWarning(
                    'Invalid attribute value for \'' . $attrib . '\' (not a TRUE/FALSE value)',
                    $self->_objClass . '->checkAttribValue',
                );
            }

        } elsif ($type eq 'colour' || $type eq 'underlay') {

            # Must check it's a valid Axmud colour tag (standard, xterm or RGB), or an empty string
            if ($value eq '') {

                # $value is valid
                return $value;

            } elsif ($value eq '0') {

                # ;addtrigger and ;modifytrigger use 0 in place of an empty string
                return '';

            } else {

                if ($type eq 'colour' && ! $axmud::CLIENT->checkTextTags($value)) {

                    return $session->writeWarning(
                        'Invalid attribute value for \'' . $attrib . '\' (not a valid standard or'
                        . ' xterm text colour tag)',
                        $self->_objClass . '->checkAttribValue',
                    );

                } elsif (
                    $type eq 'underlay'
                    && ! $axmud::CLIENT->checkUnderlayTags($value)
                ) {
                    return $session->writeWarning(
                        'Invalid attribute value for \'' . $attrib . '\' (not a valid standard or'
                        . ' xterm underlay colour tag)',
                        $self->_objClass . '->checkAttribValue',
                    );

                } else {

                    # $value is valid
                    return $value;
                }
            }

        } elsif ($type eq 'hook_event') {

            # Must check it's a valid hook event. Get the hook interface model
            $modelObj = $axmud::CLIENT->ivShow('interfaceModelHash', 'hook');
            # Check the hook event exists
            if (! $modelObj->ivExists('hookEventHash', $value)) {

                return $session->writeWarning(
                    'Invalid attribute value for \'' . $attrib . '\' (not a hook event)',
                    $self->_objClass . '->checkAttribValue',
                );

            } else {

                # $value is valid
                return $value;
            }

        } elsif ($type eq 'interval') {

            # Check it's a positive number
            if (! $axmud::CLIENT->floatCheck($value, 0) || $value == 0) {

                return $session->writeWarning(
                    'Invalid attribute value for \'' . $attrib . '\' (not an interval above 0)',
                    $self->_objClass . '->checkAttribValue',
                );

            } else {

                # $value is valid
                return $value;
            }

        } elsif ($type eq 'keycode') {

            # Must check it's a valid keycode
            if (! $axmud::CLIENT->currentKeycodeObj->ivExists('keycodeHash', $value)) {

                return $session->writeWarning(
                    'Invalid attribute value for \'' . $attrib . '\' (not ' . $axmud::NAME_ARTICLE
                    . ' standard keycode)',
                    $self->_objClass . '->checkAttribValue',
                );

            } else {

                # $value is valid
                return $value;
            }

        } elsif ($type eq 'mode') {

            # Must check it's a valid trigger style mode: -2, -1, 0 or a positive integer
            if (! $axmud::CLIENT->intCheck($value, -2)) {

                return $session->writeWarning(
                    'Invalid attribute value for \'' . $attrib . '\' (not a trigger style mode)',
                    $self->_objClass . '->checkAttribValue',
                );

            } else {

                # $value is valid
                return $value;
            }

        } elsif ($type eq 'number') {

            # Check it's a positive number or 0
            if (! $axmud::CLIENT->floatCheck($value, 0)) {

                return $session->writeWarning(
                    'Invalid attribute value for \'' . $attrib . '\' (not a number, 0 or above)',
                    $self->_objClass . '->checkAttribValue',
                );

            } else {

                # $value is valid
                return $value;
            }

        } elsif ($type eq 'repeat_count') {

            # Check it's a real positive integer, or the value -1
            if (! $axmud::CLIENT->intCheck($value, -1) || $value == 0) {

                return $session->writeWarning(
                    'Invalid attribute value for \'' . $attrib . '\' (not a repeat count)',
                    $self->_objClass . '->checkAttribValue',
                );

            } else {

                # $value is valid
                return $value;
            }

        } elsif ($type eq 'style') {

            # Must check it's a valid trigger style: 0, 1 or 2
            if ($value ne '0' && $value ne '1' && $value ne '2') {

                return $session->writeWarning(
                    'Invalid attribute value for \'' . $attrib . '\' (not a trigger style)',
                    $self->_objClass . '->checkAttribValue',
                );

            } else {

                # $value is valid
                return $value;
            }

        } elsif (
            $type eq 'instruction' || $type eq 'pattern' || $type eq 'string'
            || $type eq 'substitution'
        ) {
            # All values of $value are valid
            return $value;

        } else {

            # Unrecognised $type
            return $session->writeWarning(
                'Invalid attribute type \'' . $type . '\'',
                $self->_objClass . '->checkAttribValue',
            );
        }
    }

    ##################
    # Accessors - set

    sub set_attribHash {

        # Called by GA::Generic::Cmd->addInterface
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, @list) = @_;

        # Local variables
        my (
            $modelObj,
            %attribHash,
        );

        # Check for improper arguments
        if (! defined $session || ! @list) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_attribHash', @_);
        }

        # Get the corresponding interface model object
        $modelObj = $axmud::CLIENT->ivShow('interfaceModelHash', $self->category);

        # @list is in the form (attribute, value, attribute, value...)
        do {

            my ($attrib, $value, $type, $checkValue);

            $attrib = shift @list;
            $value = shift @list;

            # Check that the attribute exists for this category of interface
            if ($modelObj->ivExists('attribTypeHash', $attrib)) {

                # It exists. Check that $value is the right kind of value
                $type = $modelObj->ivShow('attribTypeHash', $attrib);
                $checkValue = $self->checkAttribValue($session, $attrib, $value, $type);
                if (! defined $checkValue) {

                    # Error message already displayed
                    return undef;

                } else {

                    # The value may have been modified (e.g. 1 becomes TRUE)
                    $attribHash{$attrib} = $checkValue;
                }
            }

        } until (! @list);

        # Add key-value pairs to $self->attribHash, one at a time
        foreach my $key (keys %attribHash) {

            $self->ivAdd('attribHash', $key, $attribHash{$key});
        }

        return 1;
    }

    sub set_beforeAfterHashes {

        # Called by GA::Generic::Cmd->addInterface, ->modifyInterface
        #
        # Expected arguments
        #   $session             - The calling function's GA::Session
        #   $beforeHashRef       - Reference to a hash, whose key-value pairs should be added to
        #                              $self->beforeHash
        #   $afterHashRef        - Reference to a hash, whose key-value pairs should be added to
        #                              $self->afterHash
        #
        # Optional arguments (when called by ->modifyInterface)
        #   $beforeRemoveHashRef - Reference to a hash, whose key-value pairs should be added to
        #                              $self->beforeHash
        #   $afterRemoveHashRef  - Reference to a hash, whose key-value pairs should be added to
        #                              $self->afterHash
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $session, $beforeHashRef, $afterHashRef,
            $beforeRemoveHashRef, $afterRemoveHashRef,
            $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $beforeHashRef || ! defined $afterHashRef
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_beforeAfterHashes', @_);
        }

        foreach my $name (keys %$beforeHashRef) {

            $self->ivAdd('beforeHash', $name, undef);
        }

        foreach my $name (keys %$afterHashRef) {

            $self->ivAdd('afterHash', $name, undef);
        }

        if ($beforeRemoveHashRef) {

            foreach my $name (keys %$beforeRemoveHashRef) {

                if ($self->ivExists('beforeHash', $name)) {

                    $self->ivDelete('beforeHash', $name);
                }
            }
        }

        if ($afterRemoveHashRef) {

            foreach my $name (keys %$afterRemoveHashRef) {

                if ($self->ivExists('afterHash', $name)) {

                    $self->ivDelete('afterHash', $name);
                }
            }
        }

        return 1;
    }

    ##################
    # Accessors - get
}

{ package Games::Axmud::Generic::InterfaceCage;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Cage Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Inherited by GA::Cage::Trigger->new, etc
        # Creates a new instance of a trigger, alias, macro, timer or hook cage
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session (not stored as an IV)
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #   $profCategory   - The profile's category (e.g. 'world', 'guild', 'faction' etc)
        #
        # Return values
        #   'undef' on improper arguments or if the cage already seems to exist
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $profName, $profCategory, $check) = @_;

        # Local variables
        my (
            $cageType, $name,
            @typeList,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $profName || ! defined $profCategory
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Is this a trigger, alias, macro, timer or hook cage?
        @typeList = ('Trigger', 'Alias', 'Macro', 'Timer', 'Hook');
        OUTER: foreach my $item (@typeList) {

            if (index ($class, $item) > -1) {

                $cageType = lc($item);
                last OUTER;
            }
        }

        # Compose the cage's unique name
        $name = $cageType . '_' . $profCategory . '_' . $profName;

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 42)) {

            return $session->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );

        } elsif ($session->ivExists('cageHash', $name)) {

            return $session->writeError(
                'Registry naming error: cage \'' . $name . '\' already exists',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,           # All IVs are public

            # Standard cage IVs
            # -----------------

            name                        => $name,
            cageType                    => $cageType,
            standardFlag                => TRUE,            # This is a built-in Axmud cage
            profName                    => $profName,
            profCategory                => $profCategory,

            # Interface cage IVs
            # ------------------

            # Hash of interfaces in the form
            #   $interfaceHash{interface_name} = blessed_reference_to_interface_object
            interfaceHash               => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an trigger, alias, macro, timer or hook cage
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session (not stored as an IV)
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #   $profCategory   - The profile's category (e.g. 'world', 'guild', 'faction' etc)
        #
        # Return values
        #   'undef' on improper arguments or if the cage already seems to exist
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $profName, $profCategory, $check) = @_;

        # Local variables
        my (
            $name,
            %hash, %cloneHash,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $profName || ! defined $profCategory
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Compose the cage's unique name
        $name = $self->cageType . '_' . $profCategory . '_' . $profName;

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 42)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($session->ivExists('cageHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: cage \'' . $name . '\' already exists',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => undef,
            _privFlag                   => FALSE,                   # All IVs are public

            # Standard cage IVs
            # -----------------

            name                        => $name,
            cageType                    => $self->cageType,
            standardFlag                => TRUE,                    # This is a built-in Axmud cage
            profName                    => $profName,
            profCategory                => $profCategory,

            # Command cage IVs
            # ----------------

            interfaceHash               => {$self->interfaceHash},  # Set below
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;

        # $self->interfaceHash contains a collection of blessed references to trigger/alias/macro/
        #   timer/hook objects, each of which must be cloned, too
        %hash = $self->interfaceHash;
        if (%hash) {

            foreach my $interfaceName (keys %hash) {

                my ($interfaceObj, $newObj);

                $interfaceObj = $hash{$interfaceName};
                $newObj = $interfaceObj->clone();
                if (! $newObj) {

                    $session->writeWarning(
                        'Error cloning the ' . $self->cageType . ' interface object while cloning'
                        . ' the ' . $self->cageType . ' cage for the profile \'' . $profName . '\'',
                        $self->_objClass . '->clone',
                    );

                } else {

                    $cloneHash{$newObj->name} = $newObj;
                }
            }

            if (%cloneHash) {

                # Set this object's IV
                $self->{interfaceHash} = \%cloneHash;
            }
        }

        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # NB These methods set/return the cage's ACTUAL interface hash. To get/set values from this hash
    #   AND/OR its inferiors, use the generic cage's ->ivXXX functions
    sub interfaceHash
        { my $self = shift; return %{$self->{interfaceHash}}; }
}

{ package Games::Axmud::Generic::InterfaceModel;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub category
        { $_[0]->{category} }

    sub stimulusName
        { $_[0]->{stimulusName} }
    sub responseName
        { $_[0]->{responseName} }

    sub optionalAttribHash
        { my $self = shift; return %{$self->{optionalAttribHash}}; }
    sub attribTypeHash
        { my $self = shift; return %{$self->{attribTypeHash}}; }
    sub compulsorySwitchHash
        { my $self = shift; return %{$self->{compulsorySwitchHash}}; }
    sub optionalSwitchHash
        { my $self = shift; return %{$self->{optionalSwitchHash}}; }
}

{ package Games::Axmud::Generic::MapWin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::GridWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

#   sub new {}              # Defined in window objects which inherit this one

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::GridWin

#   sub winEnable {}        # Inherited from GA::Generic::GridWin

#   sub winDisengage {}     # Defined in window objects which inherit this one

#   sub winDestroy {}       # Defined in window objects which inherit this one

#   sub winShowAll {}       # Inherited from GA::Generic::Win

#   sub drawWidgets {}      # Inherited from GA::Generic::Win

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # Standard 'map' window object functions

#   sub winReset {}         # Defined in window objects which inherit this one

#   sub winUpdate {}        # Defined in window objects which inherit this one

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Generic::ModelObj;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the generic model object (which is never blessed into existence)
        # NB Exit model objects don't inherit from this object
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $name       - A name for the object. For room objects, this is the same as the room's
        #                   brief description. For regions, ->name is the only place $name is
        #                   stored. For everything else, ->noun is also set to ->name
        #               - (NB If $name is longer than 32 characters, it is shortened)
        #   $category   - 'region', 'room', 'weapon', 'armour', 'garment', 'char', 'minion',
        #                   'sentient', 'creature', 'portable', 'decoration' or 'custom'
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns $self, a hash that will be blessed into existence by the inheriting
        #       object

        my ($class, $session, $name, $category, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $category
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $category is valid
        if (! $axmud::CLIENT->ivExists('constModelTypeHash', $category)) {

            return $axmud::CLIENT->writeError(
                'Invalid model object category \'' . $category . '\'',
                $class . '->new',
            );
        }

        # If $name is longer than 32 characters, shorten it (and add an ellipsis)
        if (length ($name) > 32) {

            $name = substr($name, 0, 29) . '...';
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => undef,        # Set by the calling function
            _parentWorld                => undef,        # Set by the calling function
            _privFlag                   => FALSE,        # All IVs are public

            # NB If any of these IVs are changed, GA::Generic::ModelObj->convertCategory must be
            #   changed, too

            # Group 1 IVs (all objects)
            # -------------------------

            # The object's actual name, e.g. 'orc' (can include spaces)
            name                        => $name,
            # What kind of object this is ('char', 'portable', 'custom' etc)
            category                    => $category,
            # Flag set to TRUE if this object is in $session's world model (in which case, the
            #   object is a 'model object')
            # Flag set to FALSE if this object is not in $session's world model (in which case, the
            #   object is a 'non-model object')
            # All objects which call this function have their ->modelFlag set to FALSE, initially
            modelFlag                   => FALSE,
            # For model objects, a unique number ('undef' for non-model objects)
            number                      => undef,
            # Number of the model object of the room where this object is found, the shop where this
            #   object is bought, the NPC from which this object is liberated, or the region in
            #   which this object wanders ('undef' for non-model objects, or if there is nothing
            #   resembling a parent)
            parent                      => undef,
            # Hash of numbers of model objects for which this is the ->parent. Hash in the form
            #   $childHash{number} = 'undef'
            childHash                   => {},

            # These variables are the same for each kind of object (the same for all weapons, the
            #   same for all decorations, etc)

            # Flag set to FALSE if this object is an abstract concept ('region' and 'room', possibly
            #   'custom'), TRUE if this object is a concrete thing (everything else, possibly
            #   including 'custom')
            concreteFlag                => FALSE,
            # Flag set to TRUE if this object is alive, FALSE if not
            aliveFlag                   => FALSE,
            # Flag set to TRUE if this object is sentient (capable of speech, in theory), FALSE if
            #   not
            sentientFlag                => FALSE,
            # Flag set to TRUE if the object can be carried (in theory), FALSE if not
            portableFlag                => FALSE,
            # Flag set to TRUE if the object can be bought and sold (in theory), FALSE if not
            saleableFlag                => FALSE,

            # Private properties for this object, in a customisable hash
            privateHash                 => {},

            # If the world's source code is available on the user's computer (i.e. the world model
            #   object's ->mudlibPath IV is set), and if the file matching this object is known,
            #   the path to that file (relative to the directory stored in ->mudLibPath)
            sourceCodePath              => undef,
            # Notes on this object, if the user wants to add them. Each value in the list is a
            #   separate line for display
            notesList                   => [],
        };

        # Group 2 IVs (all objects except 'region' and 'room')
        # ----------------------------------------------------

        if ($category ne 'region' && $category ne 'room') {

            # A word string most likely to be the main noun (usually a single word, e.g. 'sword')
            $self->{noun}               = undef,
            # A possible description of the object. For example, with 'a huge hairy orc', possible
            #   noun tags include 'orc', 'hairy orc', 'huge hairy orc' and 'huge hairy orc'
            # Is set as required; the default setting is the same as $self->noun
            $self->{nounTag}            = undef,
            # List of other words which are known to be nouns for this object
            $self->{otherNounList}      = [],
            # List of other words which are known to be adjectives describing this object
            $self->{adjList}            = [],
            # List of pseudo-adjectives (single words like 'suspicious' reduced from a longer string
            #   like 'slightly suspicious-looking') describing this object
            $self->{pseudoAdjList}      = [],
            # List of root adjectives describing this object (for languages that use declined
            #   adjectives; English isn't one of them)
            $self->{rootAdjList}        = [],
            # Words describing the object which aren't known nouns or adjectives
            $self->{unknownWordList}    = [],
            # A number representing how many there of this object there are; usually set to 1
            $self->{multiple}           = 1,
            # How the object appears in verbose room descriptions, minus any initial articles
            $self->{baseString}         = undef,
            # Description for the object, if known (e.g. 'A magnificent gleaming sword, perfect for
            #   chopping up trolls')
            $self->{descrip}            = undef,

            # Two IVs for non-model objects used with the Inventory task (set to 'undef' when used
            #   by anything else)

            # If this object is contained in another one, the model number of the container
            $self->{container}          = undef,
            # How this object is possessed ('wield', 'hold', 'wear', 'carry', 'sack', 'misc')
            $self->{inventoryType}      = undef,
        }

        # Group 3 IVs ('character', 'minion', 'sentient', 'creature' and optionally 'custom')
        # -----------------------------------------------------------------------------------

        # (Group 3 IVs are for available for use in any code you write to handle attacks)
        if (
            $category eq 'character' || $category eq 'minion' || $category eq 'sentient'
            || $category eq 'creature' || $category eq 'custom'
        ) {
            # The current status of the fight with this object:
            #   'waiting'   - the fight hasn't started yet (but will soon)
            #   'alive'     - the target is alive
            #   'kill'      - the target is dead
            #   'flee'      - the target has run away in a direction that can be followed
            #   'escape'    - the target has run away, and can't be pursued for some reason
            # The current status of the interaction with this object:
            #   'waiting'   - the interaction hasn't started yet (but will soon)
            #   'interact'  - the target is interacting (and alive)
            #   'finish'    - the interaction has finished
            #   'flee'      - the target has run away in a direction that can be followed
            #   'escape'    - the target has run away, and can't be pursued for some reason
            $self->{targetStatus}       = undef;
            # What kind of attack this attack: 'fight' for a fight, and 'interaction' for an
            #   interaction
            $self->{targetType}         = undef;
            # For targets who move after a fight starts. The path from the original location to the
            #   target's presumed current location, e.g. 'n;nw;w'
            $self->{targetPath}         = undef;
            # For targets who move after a fight starts. The target's presumed location in the
            #   world (the world model number of a room). Set to 'undef' if unknown
            $self->{targetRoomNum}      = undef;

            # Is the object listed separately when the user types a look/glance command, or is it
            #   only apparent that the object exists from a description of something else? (Group 4
            #   IV for inanimate objects)
            # Flag set to TRUE if the object is listed separately, FALSE if not
            $self->{explicitFlag}       = TRUE;

            # Flag that can be set to TRUE, if your code needs to remember which objects in a room
            #   have been attacked
            $self->{alreadyAttackedFlag}
                                        = FALSE;
        }

        # Group 4 IVs ('weapon', 'armour', 'garment', 'portable', 'decoration', optionally 'custom')
        # ------------------------------------------------------------------------------------------

        if (
            $category eq 'weapon' || $category eq 'armour' || $category eq 'garment'
            || $category eq 'portable' || $category eq 'decoration' || $category eq 'custom'
        ) {
            # Is the object listed separately when the user types a look/glance command, or is it
            #   only apparent that the object exists from a description of something else? (Group 3
            #   IV for living beings)
            # Flag set to TRUE if the object is listed separately, FALSE if not
            $self->{explicitFlag}       = TRUE;

            # Object's weight (if known)
            $self->{weight}             = undef;
            # Character's stat bonuses or penalties when using this object
            $self->{bonusHash}          = {};

            # Condition of the object (a number in the range 0-100; 'undef' if unknown, or if not
            #   used in this world)
            $self->{condition}          = undef;
            # The Condition task uses this flag to help it set an object's current condition
            $self->{conditionChangeFlag}
                                        = FALSE;
            # Flag set to TRUE if this object is fixable/repairable), FALSE if not (or if unknown)
            $self->{fixableFlag}        = FALSE;

            # Flag set to TRUE if sellable, FALSE if not (or if unknown). This flag tells you
            #   whether this particular object can be sold; $self->saleableFlag, a group 1 IV, tells
            #   you whether objects of this ->category can be sold, or not)
            $self->{sellableFlag}       = FALSE;
            # The highest value of the object that's been noticed when buying it ('undef' if value
            #   unknown)
            $self->{buyValue}           = undef;
            # The highest value of the object that's been noticed when selling it ('undef' if value
            #   unknown)
            $self->{sellValue}          = undef;

            # Flag set to TRUE if this object can only be used by certain guilds, races or indeed
            #   characters
            $self->{exclusiveFlag}      = FALSE;
            # A hash of guilds, races, named chars etc allowed to use this object. Hash in the form
            #   ->exclusionHash{profile_name) = undef
            $self->{exclusiveHash}      = {};
        }

        # The generic model object is never actually blessed into existence
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # Group 1 IVs (all objects)
    sub name
        { $_[0]->{name} }
    sub category
        { $_[0]->{category} }
    sub modelFlag
        { $_[0]->{modelFlag} }
    sub number
        { $_[0]->{number} }
    sub parent
        { $_[0]->{parent} }
    sub childHash
        { my $self = shift; return %{$self->{childHash}}; }

    sub concreteFlag
        { $_[0]->{concreteFlag} }
    sub aliveFlag
        { $_[0]->{aliveFlag} }
    sub sentientFlag
        { $_[0]->{sentientFlag} }
    sub portableFlag
        { $_[0]->{portableFlag} }
    sub saleableFlag
        { $_[0]->{saleableFlag} }

    sub privateHash
        { my $self = shift; return %{$self->{privateHash}}; }

    sub sourceCodePath
        { $_[0]->{sourceCodePath} }
    sub notesList
        { my $self = shift; return @{$self->{notesList}}; }

    # Group 2 IVs (all objects except 'region' and 'room')
    sub noun
        { $_[0]->{noun} }
    sub nounTag
        { $_[0]->{nounTag} }
    sub otherNounList
        { my $self = shift; return @{$self->{otherNounList}}; }
    sub adjList
        { my $self = shift; return @{$self->{adjList}}; }
    sub pseudoAdjList
        { my $self = shift; return @{$self->{pseudoAdjList}}; }
    sub rootAdjList
        { my $self = shift; return @{$self->{rootAdjList}}; }
    sub unknownWordList
        { my $self = shift; return @{$self->{unknownWordList}}; }
    sub multiple
        { $_[0]->{multiple} }
    sub baseString
        { $_[0]->{baseString} }
    sub descrip
        { $_[0]->{descrip} }

    sub container
        { $_[0]->{container} }
    sub inventoryType
        { $_[0]->{inventoryType} }

    # Group 3 IVs ('character', 'minion', 'sentient', 'creature' and optionally 'custom')
    sub targetStatus
        { $_[0]->{targetStatus} }
    sub targetType
        { $_[0]->{targetType} }
    sub targetPath
        { $_[0]->{targetPath} }
    sub targetRoomNum
        { $_[0]->{targetRoomNum} }

    sub explicitFlag
        { $_[0]->{explicitFlag} }       # Also a group 4 IV

    sub alreadyAttackedFlag
        { $_[0]->{alreadyAttackedFlag} }

    # Group 4 IVs ('weapon', 'armour', 'garment', 'portable', 'decoration', optionally 'custom')
#   sub explicitFlag
#       { $_[0]->{explicitFlag} }       # Also a group 3 IV
    sub weight
        { $_[0]->{weight} }
    sub bonusHash
        { my $self = shift; return %{$self->{bonusHash}}; }

    sub condition
        { $_[0]->{condition} }
    sub conditionChangeFlag
        { $_[0]->{conditionChangeFlag} }
    sub fixableFlag
        { $_[0]->{fixableFlag} }

    sub sellableFlag
        { $_[0]->{sellableFlag} }
    sub buyValue
        { $_[0]->{buyValue} }
    sub sellValue
        { $_[0]->{sellValue} }

    sub exclusiveFlag
        { $_[0]->{exclusiveFlag} }
    sub exclusiveHash
        { my $self = shift; return %{$self->{exclusiveHash}}; }
}

{ package Games::Axmud::Generic::OtherWin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of an 'other' window (most window objects inheriting from this
        #   generic object share the same ->new function, with only standard IVs)
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - Ignored if set (all 'other' windows define their own title)
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'other' window; set to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'other_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'other',
            # A name for the window (can be unique to this type of window object, or can be the
            #   same as ->winType)
            winName                     => 'other',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $axmud::CLIENT->constFreeWinWidth,
            heightPixels                => $axmud::CLIENT->constFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title
            title                       => $axmud::SCRIPT . ' window',
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

#   sub winEnable {}        # Inherited from GA::Generic::FreeWin

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}       # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}       # Inherited from GA::Generic::Win

#   sub drawWidgets {}      # Inherited from GA::Generic::Win

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Generic::Plugin::Cmd;

    # NB Plugin client commands can have the same name as existing client commands. When the
    #   plugin is loaded, the existing command is replaced for as long as the plugin is enabled.

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Cmd Games::Axmud);

    ##################
    # Constructors

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Generic::Profile;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    ##################
    # Methods

    sub cloneInitTaskList {

        # Called by $self->clone immediately after cloning this profile from another
        # Clones task objects in the original profile's initial tasklist
        #
        # Expected arguments
        #   $original   - The original profile object, from which this object was cloned
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $original, $check) = @_;

        # Local variables
        my (
            @taskList,
            %taskHash,
        );

        # Check for improper arguments
        if (! defined $original || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->new', @_);
        }

        # Import the original profile's initial tasklist
        foreach my $name ($original->initTaskOrderList) {

            my ($oldObj, $newObj);

            $oldObj = $original->ivShow('initTaskHash', $name);
            $newObj = $oldObj->clone('initial', $self->name, $self->category);
            if ($newObj) {

                push (@taskList, $newObj);
                $taskHash{$newObj->uniqueName} = $newObj;
            }
        }

        # Update IVs
        if (@taskList) {

            $self->ivPoke('initTaskHash', %taskHash);
            $self->ivPoke('initTaskOrderList', @taskList);
        }

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub category
        { $_[0]->{category} }
    sub parentWorld
        { $_[0]->{parentWorld} }

    sub initTaskHash
        { my $self = shift; return %{$self->{initTaskHash}}; }
    sub initTaskOrderList
        { my $self = shift; return @{$self->{initTaskOrderList}}; }
    sub initTaskTotal
        { $_[0]->{initTaskTotal} }
    sub initScriptHash
        { my $self = shift; return %{$self->{initScriptHash}}; }
    sub initScriptOrderList
        { my $self = shift; return @{$self->{initScriptOrderList}}; }
    sub initMission
        { $_[0]->{initMission} }
    sub initCmdList
        { my $self = shift; return @{$self->{initCmdList}}; }

    sub setupCompleteFlag
        { $_[0]->{setupCompleteFlag} }
    sub notepadList
        { my $self = shift; return @{$self->{notepadList}}; }
    sub privateHash
        { my $self = shift; return %{$self->{privateHash}}; }
}

{ package Games::Axmud::Generic::Strip;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Generic function to create this strip object (most objects inheriting from this one will
        #   use their own ->new function)
        #
        # Expected arguments
        #   $number     - The strip object's number within the parent window (matches
        #                   GA::Win::Internal->stripCount, or -1 for a temporary strip object
        #                   created to access its default IVs)
        #   $winObj     - The parent window object (GA::Win::Internal). 'temp' for temporary strip
        #                   objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the strip object's
        #                   initialisation settings. The strip object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of strip object recognises these initialisation settings:
        #
        #                   'some_string'   - 'some_value'
        #                   'some_string_2' - 'some_value'
        #                   ...             - ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $winObj, %initHash) = @_;

        # Local variables
        my %modHash;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $winObj) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

#        # Default initialisation settings
#        %modHash = (
#            'some_string'      => 'some_value',
#            'some_string_2'    => 'some_value',
#        );
#
#        # Interpret the initialisation settings in %initHash, if any
#        foreach my $key (keys %modHash) {
#
#            if (exists $initHash{$key}) {
#
#                if ($key eq 'some_flag_set_to_TRUE_or_FALSE') {
#
#                    if ($initHash{$key}) {
#                        $modHash{$key} = TRUE;
#                    } else {
#                        $modHash{$key} = FALSE;
#                    }
#
#                } else {
#
#                    $modHash{$key} = $initHash{$key};
#                }
#            }
#        }

        # Setup
        my $self = {
            _objName                    => 'strip_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard strip object IVs
            # -------------------------

            # The strip object's number within the parent window (matches
            #   GA::Win::Internal->stripCount, or -1 for a temporary strip object created to access
            #   its default IVs)
            number                      => $number,
            # The type of strip object (custom strip objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in strip objects)
            type                        => 'generic',
            # The parent window object (GA::Win::Internal). 'temp' for temporary strip objects
            winObj                      => $winObj,

            # Flag set to TRUE if the strip object is visible (has actually drawn widgets in the
            #   window), set to FALSE if it is not visible (has drawn no widgets in the window, but
            #   still exists in GA::Win::Internal->stripHash, etc)
            # The flag might be set to FALSE in strip objects like GA::Strip::GaugeBox, which
            #   might have gauges to draw, or not, depending on current conditions. (Most strip
            #   objects have this flag set to TRUE all the time)
            # If FALSE, GA::Win::Internal->drawWidgets and ->addStripObj don't draw any widgets when
            #   called by this object's functions
            # NB Strip objects are created with this flag set to TRUE or FALSE, but once created,
            #   the flag's value shouldn't be modified by anything other than
            #   GA::Win::Internal->hideStripObj and ->revealStripObj (which in turn call
            #   $self->set_visibleFlag)
            visibleFlag                 => TRUE,
            # Flag set to TRUE is the strip object should be given its share of any extra space
            #   within the packing box (the extra space is divided equally between all children of
            #   the box whose ->expandFlag is TRUE)
            expandFlag                  => FALSE,
            # Flag set to TRUE if any space given to the strip object by the 'expand' option is
            #   actually allocated within the strip object, FALSE if it is used as padding outside
            #   it (on both sides)
            fillFlag                    => FALSE,
            # Flag set to TRUE if the strip object should be packed into its window with a small
            #   gap between strip objects to either side; FALSE if not (can be set to FALSE if the
            #   the strip object's widgets are drawn in a way, such that a gap is not necessary,
            #   for example in the toolbar strip object)
            spacingFlag                 => TRUE,
            # Flag set to TRUE if only one instance of this strip object should be added to the
            #   parent window, set to FALSE if any number of instances can be added
            jealousyFlag                => TRUE,
            # Flag set to TRUE if this strip object can be added when $axmud::BLIND_MODE_FLAG is
            #   TRUE, FALSE if it can't be added (because it's not useful for visually-impaired
            #   users)
            blindFlag                   => FALSE,
            # Flag set to TRUE if the main container widget, stored in $self->packingBox, should be
            #   allowed to accept the focus, FALSE if not. The restriction is applied during the
            #   call to GA::Win::Internal->drawWidgets and ->addStripObj. Even if FALSE, widgets in
            #   the container widget can be set to accept the focus (e.g. the Gtk2::Entry in
            #   GA::Strip::MenuBar)
            allowFocusFlag              => FALSE,

            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of strip object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this strip object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => undef,

            # The container widget for this strip object (usually a Gtk2::HBox or Gtk2::VBox). This
            #   widget is the one added to the window's main Gtk2::HBox or Gtk2::VBox
            packingBox                  => undef,

            # Other IVs
            # ---------

            # Widgets
#           button                      => undef,       # Gtk2::Button

            # Everything else

            # ...
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard strip object functions

    sub objEnable {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Generic function for setting up the strip object's widgets (which isn't actually called by
        #   anything)
        # Copy this function into your own strip object code and add your own widgets
        #
        # Expected arguments
        #   $winmapObj  - The winmap object (GA::Obj::Winmap) that specifies the layout of the
        #                   parent window
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $winmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Create a Gtk2::VBox (or a Gtk2::HBox) to contain one or more Gtk2 widgets
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $packingBox->set_border_width(0);

        # Add a widget
#        my $button = Gtk2::Button->new($name);
#        $packingBox->pack_start($button, FALSE, FALSE, 0);

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
#        $self->ivPoke('button', $button);          # Optional

        return 1;
    }

    sub objDestroy {

        # Called by GA::Win::Internal->removeStripObj, just before the strip is removed from its
        #   parent window, and also by ->winDestroy and ->resetWinmap, to give this object a chance
        #   to do any necessary tidying up
        # Generic function that can be inherited by any strip object that doesn't need to do any
        #   tidying up
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objDestroy', @_);
        }

        # (No tidying up required for this type of strip object)

        return 1;
    }

    sub setWidgetsIfSession {

        # Called by GA::Win::Internal->setWidgetsIfSession
        # Allows this strip object to sensitise or desensitise its widgets, depending on whether
        #   the parent window has a ->visibleSession at the moment
        # (NB Only 'main' windows have a ->visibleSession; for other 'grid' windows, the flag
        #   argument will be FALSE)
        #
        # Expected arguments
        #   $flag   - TRUE if the parent window has a visible session, FALSE if not
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setWidgetsIfSession', @_);
        }

        # (nothing to do for this strip object)

        return 1;
    }

    sub setWidgetsChangeSession {

        # Called by GA::Win::Internal->setWidgetsChangeSession
        # Allows this strip object to update its widgets whenever the visible session in any 'main'
        #   window changes
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

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->setWidgetsChangeSession',
                @_,
            );
        }

        # (nothing to do for this strip object)

        return 1;
    }

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    sub notify_addStripObj {

        # Called by GA::Win::Internal->drawWidgets and ->addStripObj whenever a strip object is
        #   added to the window

        my ($self, $stripObj, $check) = @_;

        # Check for improper arguments
        if (! defined $stripObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notify_addStripObj', @_);
        }

        # (This generic function does nothing with the notification)

        return 1;
    }

    sub notify_removeStripObj {

        # Called by GA::Win::Internal->removeStripObj whenever a strip object is removed from the
        #   window

        my ($self, $stripObj, $check) = @_;

        # Check for improper arguments
        if (! defined $stripObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notify_removeStripObj', @_);
        }

        # (This generic function does nothing with the notification)

        return 1;
    }

    sub notify_addTableObj {

        # Called by GA::Strip::Table->addTableObj whenever a table object is added to the window's
        #   Gtk2::Table

        my ($self, $tableObj, $check) = @_;

        # Check for improper arguments
        if (! defined $tableObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notify_addTableObj', @_);
        }

        # (This generic function does nothing with the notification)

        return 1;
    }

    sub notify_removeTableObj {

        # Called by GA::Strip::Table->removeTableObj whenever a table object is removed from the
        #   window's Gtk2::Table

        my ($self, $tableObj, $check) = @_;

        # Check for improper arguments
        if (! defined $tableObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notify_removeTableObj', @_);
        }

        # (This generic function does nothing with the notification)

        return 1;
    }

    sub set_func {

        my ($self, $funcRef, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_func', @_);
        }

        $self->ivPoke('funcRef', $funcRef);

        return 1;
    }

    sub set_id {

        my ($self, $funcID, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_id', @_);
        }

        $self->ivPoke('funcID', $funcID);

        return 1;
    }

    sub set_visibleFlag {

        # Should only be called by GA::Win::Internal->hideStripObj and ->revealStripObj

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_visibleFlag', @_);
        }

        if (! $flag) {
            $self->ivPoke('visibleFlag', FALSE);
        } else {
            $self->ivPoke('visibleFlag', TRUE);
        }

        return 1;
    }

    ##################
    # Accessors - get

    sub number
        { $_[0]->{number} }
    sub type
        { $_[0]->{type} }
    sub winObj
        { $_[0]->{winObj} }

    sub visibleFlag
        { $_[0]->{visibleFlag} }
    sub expandFlag
        { $_[0]->{expandFlag} }
    sub fillFlag
        { $_[0]->{fillFlag} }
    sub spacingFlag
        { $_[0]->{spacingFlag} }
    sub jealousyFlag
        { $_[0]->{jealousyFlag} }
    sub blindFlag
        { $_[0]->{blindFlag} }
    sub allowFocusFlag
        { $_[0]->{allowFocusFlag} }

    sub initHash
        { my $self = shift; return %{$self->{initHash}}; }
    sub funcRef
        { $_[0]->{funcRef} }
    sub funcID
        { $_[0]->{funcID} }

    sub packingBox
        { $_[0]->{packingBox} }
}

{ package Games::Axmud::Generic::Table;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Strip::Table->addTableObj
        # Generic function for creating table objects (which isn't actually called by anything)
        # Copy this function into your own table object code and add your own IVs to $self = {}
        #
        # Expected arguments
        #   $number     - The table object's number within the parent strip object (matches
        #                   GA::Strip::Table->tableObjCount, or -1 for a temporary table object
        #                   created to access its default IVs)
        #   $name       - A name for the table object. Can be any string or, if no name was
        #                   specified in the call to the calling function, $name is the same as
        #                   $number. (No part of the code checks that table object names are unique;
        #                   if two or more table objects share the same ->name, usually the one with
        #                   the lowest ->number 'wins'. 'temp' for temporary table objects. Max 16
        #                   chars)
        #   $stripObj   - The parent strip object (GA::Strip::Table). 'temp' for temporary strip
        #                   objects
        #   $zoneObj    - The tablezone object (GA::Obj::Tablezone) which marks out an area of the
        #                   parent strip object's Gtk2::Table for use exclusively by this table
        #                   object. 'temp' for temporary strip objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the table object's
        #                   initialisation settings. The table object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of table object recognises these initialisation settings:
        #
        #                   'some_string'   - 'some_value'
        #                   'some_string_2' - 'some_value'
        #                   ...             - ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $name, $stripObj, $zoneObj, %initHash) = @_;

        # Local variables
        my %modHash;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $name || ! defined $stripObj
            || ! defined $zoneObj
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

#        # Default initialisation settings
#        %modHash = (
#            'some_string'      => 'some_value',
#            'some_string_2'    => 'some_value',
#        );
#
#        # Interpret the initialisation settings in %initHash, if any
#        foreach my $key (keys %modHash) {
#
#            if (exists $initHash{$key}) {
#
#                if ($key eq 'some_flag_set_to_TRUE_or_FALSE') {
#
#                    if ($initHash{$key}) {
#                        $modHash{$key} = TRUE;
#                    } else {
#                        $modHash{$key} = FALSE;
#                    }
#
#                } else {
#
#                    $modHash{$key} = $initHash{$key};
#                }
#            }
#        }

        # Setup
        my $self = {
            _objName                    => 'table_obj_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard table object IVs
            # -------------------------

            # The table object's number within the parent strip object (matches
            #   GA::Strip::Table->tableObjCount, or -1 for a temporary table object created to
            #   access its default IVs)
            number                      => $number,
            # A name for the table object. Can be any string or, if no name was specified in the
            #   call to the calling function, $name is the same as $number. (No part of the code
            #   checks that table object names are unique; if two or more table objects share the
            #   same ->name, usually the one with the lowest ->number 'wins'. 'temp' for temporary
            #   table objects. Max 16 chars)
            name                        => $name,
            # The type of table object (custom table objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in table objects)
            type                        => 'generic',
            # The parent strip object (GA::Strip::Table)
            stripObj                    => $stripObj,
            # The parent strip object's window object (inheriting from GA::Generic::Win). 'temp' for
            #   temporary table objects
            winObj                      => $stripObj->winObj,
            # The tablezone object (GA::Obj::Tablezone) which marks out an area of the parent strip
            #   object's Gtk2::Table for use exclusively by this table object. 'temp' for temporary
            #   table objects
            zoneObj                     => $zoneObj,

            # Flag set to TRUE if this table object can be deleted from the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be deleted (except in a few circumstances, such as
            #   when a connection to a world terminates)
            allowRemoveFlag             => TRUE,
            # Flag set to TRUE if this table object can be resized on the Gtk2::Table, once it is
            #   created. Set to FALSE if it can't be resized
            allowResizeFlag             => TRUE,
            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of table object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this table object and
            #   its widget(s). Can be any value except 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => '',

            # The container widget(s) for this table object
            # If a frame title is not required, both IVs are set to the same container widget
            #   (usually a Gtk2::HBox or Gtk2::VBox)
            # If a frame title is required, ->packingBox is set to a Gtk2::Frame, ->packingBox2 is
            #   set to a different container widget (a Gtk2::HBox, etc). ->packingBox is packed into
            #   the parent strip object's Gtk2::Table. ->packingBox2 contains all the other widgets
            #   for this table object. ->packingBox2 is packed inside ->packingBox
            packingBox                  => undef,       # Gtk2::HBox (etc) or Gtk2::Frame
            packingBox2                 => undef,       # Gtk2::HBox (etc)

            # Other IVs
            # ---------

            # Widgets
#           button                      => undef,       # Gtk2::Button

            # Everything else

            # ...
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard table object functions

    sub objEnable {

        # Called by GA::Strip::Table->addTableObj
        # Generic function for setting up the table object's widgets (which isn't actually called by
        #   anything)
        # Copy this function into your own table object code and add your own widgets
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Create a packing box; it is this object which is placed onto the Gtk2::Table
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $packingBox->set_border_width(0);

        # Add a widget
#        my $button = Gtk2::Button->new($name);
#        $packingBox->pack_start($button, FALSE, FALSE, 0);

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);   # Compulsory
#        $self->ivPoke('button', $button);          # Optional

        return 1;
    }

    sub objDestroy {

        # Called by GA::Strip::Table->objDestroy, just before that strip is removed from its
        #   parent window, to give this object a chance to do any necessary tidying up
        # Generic function that can be inherited by any table object that doesn't need to do any
        #   tidying up
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objDestroy', @_);
        }

        # (No tidying up required for this type of table object)

        return 1;
    }

    sub setWidgetsIfSession {

        # Called by GA::Strip::Table->setWidgetsIfSession
        # Allows this table object to sensitise or desensitise its widgets, depending on whether
        #   the parent window has a ->visibleSession at the moment
        # (NB Only 'main' windows have a ->visibleSession; for other 'grid' windows, the flag
        #   argument will be FALSE)
        #
        # Expected arguments
        #   $flag   - TRUE if the parent window has a visible session, FALSE if not
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setWidgetsIfSession', @_);
        }

        # (nothing to do for this table object)

        return 1;
    }

    sub setWidgetsChangeSession {

        # Called by GA::Strip::Table->setWidgetsChangeSession
        # Allows this table object to update its widgets whenever the visible session in any 'main'
        #   window changes
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

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->setWidgetsChangeSession',
                @_,
            );
        }

        # (nothing to do for this table object)

        return 1;
    }

    sub setWidgetsOnResize {

        # Called by GA::Strip::Table->resizeTableObj
        # Allows this table object to update its widgets whenever the table object is resized on its
        #   Gtk2::Table
        #
        # Expected arguments
        #   $left, $right, $top, $bottom
        #       - The coordinates of the top-left ($left, $top) and bottom-right ($right, $bottom)
        #           corners of the table object on the table after the resize
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $left, $right, $top, $bottom, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $left || ! defined $right || ! defined $top || ! defined $bottom
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setWidgetsOnResize', @_);
        }

        # (nothing to do for this table object)

        return 1;
    }

    # ->signal_connects

    # Other functions

    sub setupPackingBoxes {

        # Called by $self->objEnable
        # If a frame title is required, we need two packing boxes, rather than the usual one. The
        #   Gtk2::Frame (stored in $self->packingBox) is added to the parent strip object's
        #   Gtk2::Table, but this object's widgets are packed into the usual container widget
        #   (stored in $self->packingBox2)
        # If a frame title is not required, $self->packingBox and ->packingBox2 refer to the same
        #   widget - the one passed to this function as an argument
        #
        # Expected arguments
        #   $container  - The container widget created by the calling function (usually a
        #                   Gtk2::HBox or Gtk2::VBox)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form
        #       (packingBox, packingBox2)

        my ($self, $container, $check) = @_;

        # Local variables
        my (
            $packingBox, $packingBox2,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $container || defined $check) {

             $axmud::CLIENT->writeImproper($self->_objClass . '->setupPackingBoxes', @_);
             return @emptyList;
        }

        if ($self->ivShow('initHash', 'frame_title')) {

            $packingBox = Gtk2::Frame->new($self->ivShow('initHash', 'frame_title'));
            $packingBox->set_border_width(0);

            $packingBox2 = $container;
            $packingBox->add($packingBox2);

        } else {

            $packingBox = $packingBox2 = $container;
        }

        return ($packingBox, $packingBox2);
    }

    sub testFlag {

        # Can be called by anything
        # Convert any boolean value into a literal Glib TRUE or FALSE. If no value is specified,
        #   uses the specified default value. If neither a value nor a default value are
        #   specified, returns FALSE
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag           - Any boolean value; 'undef' is treated as FALSE
        #   $defaultFlag    - The default value to use, should be either a literal Glib TRUE or
        #                       FALSE, or 'undef'
        #
        # Return values
        #   TRUE or FALSE

        my ($self, $flag, $defaultFlag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             $axmud::CLIENT->writeImproper($self->_objClass . '->testFlag', @_);
             return FALSE;
        }

        if (! defined $flag) {

            $flag = $defaultFlag;
        }

        if (! $flag) {
            return FALSE;
        } else {
            return TRUE;
        }
    }

    sub testJustify {

        # Can be called by anything
        # Converts a value into a Gtk2::Justification. The specified value is case-insensitive.
        #   If no value is specified, converts the specified default value. If neither a value
        #   nor a default value are specified, returns 'GTK_JUSTIFY_LEFT'. If the value (or default
        #   value, if required) is not valid, returns 'GTK_JUSTIFY_LEFT'
        #
        # The conversion table is:
        #   'left', 'GTK_JUSTIFY_LEFT'                  > 'GTK_JUSTIFY_LEFT'
        #   'right', 'GTK_JUSTIFY_RIGHT'                > 'GTK_JUSTIFY_RIGHT'
        #   'centre', 'center', 'GTK_JUSTIFY_CENTER'    > 'GTK_JUSTIFY_CENTER'
        #   'fill', 'GTK_JUSTIFY_FILL'                  > 'GTK_JUSTIFY_FILL'
        #   <invalid value>                             > 'GTK_JUSTIFY_LEFT'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $value          - One of the values described above, or 'undef'
        #   $defaultValue   - The default value to use, should be either a Gtk2::Justification or
        #                       'undef'
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a Gtk2::Justification

        my ($self, $value, $defaultValue, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->testJustify', @_);
        }

        if (! defined $value) {

            if (! defined $defaultValue) {
                return 'GTK_JUSTIFY_LEFT';
            } else {
                $value = $defaultValue;
            }
        }

        $value = lc($value);

        if ($value eq 'left' || $value eq 'gtk_justify_left') {
            return 'GTK_JUSTIFY_LEFT';
        } elsif ($value eq 'right' || $value eq 'gtk_justify_right') {
            return 'GTK_JUSTIFY_RIGHT';
        } elsif ($value eq 'centre' || $value eq 'center' || $value eq 'gtk_justify_center') {
            return 'GTK_JUSTIFY_CENTER';
        } elsif ($value eq 'fill' || $value eq 'gtk_justify_fill') {
            return 'GTK_JUSTIFY_FILL';
        } else {
            return 'GTK_JUSTIFY_LEFT';
        }
    }

    sub testAlign {

        # Can be called by anything
        # Converts a value into an alignment used by several Gtk2 widgets, a fractional value in the
        #   range 0-1. If no value is specified, converts the specified default value. If neither a
        #   value nor a default value are specified, returns 0. If the value (or default value, if
        #   required) is not valid, returns 0
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $value          - One of the values described above, or 'undef'
        #   $defaultVAlue   - The default value to use, should be a fractional number in the range
        #                       0-1 or 'undef'
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a value in the range 0-1

        my ($self, $value, $defaultValue, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->testJustify', @_);
        }

        if (! defined $value) {

            if (! defined $defaultValue) {
                return 0;
            } else {
                $value = $defaultValue;
            }
        }

        if (! $axmud::CLIENT->floatCheck($value, 0, 1)) {
            return 0;
        } else {
            return $value;
        }
    }

    sub testStock {

        # Can be called by anything
        # Checks a Gtk2::Stock like 'gtk-yes' or 'gtk-save' (case-insensitive). If it's valid,
        #   returns it (converted to all lower-case); if it's not valid, returns 'undef'. If no
        #   Gtk2::Stock is specified, returns 'undef'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $stock          - A Gtk2::Stock, or 'undef'
        #
        # Return values
        #   'undef' on improper arguments, if $stock is invalid or if $stock is 'undef'
        #   Otherwise returns a Gtk2::Stock

        my ($self, $stock, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->testStock', @_);
        }

        if (! defined $stock) {

            return undef;
        }

        @list = Gtk2::Stock->list_ids();
        foreach my $item (@list) {

            if (lc($stock) eq $item) {

                return $item;
            }
        }

        return undef;
    }

    sub testInt {

        # Can be called by anything
        # Checks that a value is an integer. Optionally checks that the value is some minimum
        #   value. If the check succeeds, returns the value. If the check fails or no value is
        #   specified, returns a default value (but returns 'undef' if no default value is
        #   specified)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $value          - A value to check, or 'undef'
        #   $minValue       - The minimum value, or 'undef'
        #   $defaultValue   - The default value, or 'undef'
        #
        # Return values
        #   'undef' on improper arguments or if the check fails and no default value is specified
        #   Otherwise returns an integer value

        my ($self, $value, $minValue, $defaultValue, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->testInt', @_);
        }

        if (
            ! defined $value
            || ! $axmud::CLIENT->intCheck($value)
            || (defined $minValue && $value < $minValue)
        ) {
            return $defaultValue;

        } else {

            return $value;
        }
    }

    sub testIconValue {

        # Can be called by anything, but probably called by GA::Table::Entry->objEnable to set the
        #   Gtk2::Entry icon
        # Checks whether some value is an acceptable value, given a specified value type, value
        #   minimum and/or value maximum
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $value      - A value to check. If 'undef', no check is carried out
        #   $type       - Set to 'int' (to be acceptable, the value must be an integer), 'odd' (the
        #                   value must be an odd-numbered integer), 'even' (the value must be an
        #                   even-numbered integer), 'float' (the value must be an integer or
        #                   floating point number), 'string' (the value can be anything, even an
        #                   empty string). If 'undef', no check is carried out
        #   $min, $max  - For 'int'/'float', the minimum/maximum values that are acceptable. For
        #                   'odd'/'even', the minimum/maximum values that are acceptable. For
        #                   'string', the minimum/maximum length of the string. If either or both
        #                   values are 'undef', then no minimumx and/or maximum applies. This
        #                   function assumes the calling function has checked that $min and $max
        #                   are sane values
        #
        # Return values
        #   'undef' on improper arguments, if $value and/or $type were not specified, if $type was
        #       not recognised or if the $value is not acceptable
        #   1 if $value is acceptable

        my ($self, $value, $type, $min, $max, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->testIconValue', @_);
        }

        # Some combinations of argument can't be checked
        if (
            ! defined $value
            || ! defined $type
            || (
                $type ne 'int' && $type ne 'float' && $type ne 'odd' && $type ne 'even'
                && $type ne 'string'
            )
        ) {
            return undef;
        }

        # Perform the check
        if ($type eq 'int') {

            if (
                ! $axmud::CLIENT->intCheck($value)
                || (defined $min && $value < $min)
                || (defined $max && $value > $max)
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }

        } elsif ($type eq 'odd') {

            if (
                ! $axmud::CLIENT->intCheck($value)
                || (defined $min && $value < $min)
                || (defined $max && $value > $max)
                # Number is even
                || ! ($value % 2)
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }

        } elsif ($type eq 'even') {

            if (
                ! $axmud::CLIENT->intCheck($value)
                || (defined $min && $value < $min)
                || (defined $max && $value > $max)
                # Number is odd
                || ($value % 2)
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }

        } elsif ($type eq 'float') {

            if (
                ! $axmud::CLIENT->floatCheck($value)
                || (defined $min && $value < $min)
                || (defined $max && $value > $max)
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }

        } elsif ($type eq 'string') {

            if (
                (defined $min && length($value) < $min)
                || (defined $max && length($value) > $max)
            ) {
                # Invalid value
                return undef;

            } else {

                # Valid value
                return 1;
            }
        }
    }

    ##################
    # Accessors - set

    sub notify_addTableObj {

        # Called by GA::Strip::Table->addTableObj whenever a table object is added to the window's
        #   Gtk2::Table

        my ($self, $tableObj, $check) = @_;

        # Check for improper arguments
        if (! defined $tableObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notify_addTableObj', @_);
        }

        # (This generic function does nothing with the notification)

        return 1;
    }

    sub notify_removeTableObj {

        # Called by GA::Strip::Table->removeTableObj whenever a table object is removed from the
        #   window's Gtk2::Table

        my ($self, $tableObj, $check) = @_;

        # Check for improper arguments
        if (! defined $tableObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notify_removeTableObj', @_);
        }

        # (This generic function does nothing with the notification)

        return 1;
    }

    sub set_allowRemoveFlag {

        # Must only be called by the code which created the table object

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_allowRemoveFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('allowRemoveFlag', TRUE);
        } else {
            $self->ivPoke('allowRemoveFlag', FALSE);
        }

        return 1;
    }

    sub set_allowResizeFlag {

        # Must only be called by the code which created the table object

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_allowResizeFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('allowResizeFlag', TRUE);
        } else {
            $self->ivPoke('allowResizeFlag', FALSE);
        }

        return 1;
    }

    sub set_func {

        my ($self, $funcRef, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_func', @_);
        }

        $self->ivPoke('funcRef', $funcRef);

        return 1;
    }

    sub set_frameTitle {

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_frameTitle', @_);
        }

        if (! defined $text) {

            $text = '';
        }

        if ($self->packingBox->isa('Gtk2::Frame')) {

            $self->packingBox->set_label($text);
        }

        return 1;
    }

    sub set_id {

        my ($self, $funcID, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_id', @_);
        }

        $self->ivPoke('funcID', $funcID);

        return 1;
    }

    sub set_zoneObj {

        my ($self, $zoneObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_zoneObj', @_);
        }

        $self->ivPoke('zoneObj', $zoneObj);

        return 1;
    }

    ##################
    # Accessors - get

    sub number
        { $_[0]->{number} }
    sub name
        { $_[0]->{name} }
    sub type
        { $_[0]->{type} }
    sub stripObj
        { $_[0]->{stripObj} }
    sub winObj
        { $_[0]->{winObj} }
    sub zoneObj
        { $_[0]->{zoneObj} }

    sub allowRemoveFlag
        { $_[0]->{allowRemoveFlag} }
    sub allowResizeFlag
        { $_[0]->{allowResizeFlag} }
    sub initHash
        { my $self = shift; return %{$self->{initHash}}; }
    sub funcRef
        { $_[0]->{funcRef} }
    sub funcID
        { $_[0]->{funcID} }

    sub packingBox
        { $_[0]->{packingBox} }
    sub packingBox2
        { $_[0]->{packingBox2} }
}

{ package Games::Axmud::Generic::Task;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the generic task (although the generic task is never actually
        #   blessed into existence)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not set as an IV by this function - set by
        #                   $self->updateTaskLists for current tasks)
        #
        # Optional arguments
        #   $taskType   - Which tasklist this task is being created into - 'current' for the current
        #                   tasklist (tasks which are actually running now), 'initial' (tasks which
        #                   should be run when the user connects to the world), 'custom' (tasks with
        #                   customised initial parameters, which are run when the user demands). If
        #                   set to 'undef', this is a temporary task, created in order to access the
        #                   default values stored in IVs, that will not be added to any tasklist
        #   $profName   - ($taskType = 'current') name of the profile from whose initial tasklist
        #                   this task was created ('undef' if none)
        #               - ($taskType = 'initial') name of the profile in whose initial tasklist
        #                   this task will be. If 'undef', the global initial tasklist is used
        #               - ($taskType = 'custom') 'undef'
        #   $profCategory
        #               - ($taskType = 'current', 'initial') which category the profile falls undef
        #                   (i.e. 'world', 'race', 'char', etc, or 'undef' if no profile)
        #               - ($taskType = 'custom') 'undef'
        #   $customName
        #               - ($taskType = 'current', 'initial') 'undef'
        #               - ($taskType = 'custom') the custom task name, matching a key in
        #                   GA::Session->customTaskHash
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns $self, a hash that will be blessed into existence by the inheriting
        #       object

        my ($class, $session, $taskType, $profName, $profCategory, $customName, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # For 'initial' tasks, check that the profile $profName exists (for 'current' tasks, if
        #   $profName is defined, we can safely assume that it already exists)
        if (
            $taskType
            && $taskType eq 'initial'
            && defined $profName
            && ! $session->ivExists('profHash', $profName)
        ) {
            return $axmud::CLIENT->writeError(
                'Can\'t create new initial task because profile ' . $profName . ' doesn\'t exist',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => 'generic_task',
            _objClass                   => $class,
            # Parent file object IVs set by ->setParentFileObj
            _parentFile                 => undef,
            _parentWorld                => undef,
            _privFlag                   => TRUE,            # All IVs are private

            # Perl object components
            # ----------------------

            # The parent GA::Session object (for current tasks) - set by $self->updateTaskLists
            session                     => undef,

            # Task settings
            # -------------

            # The generic task has 'task settings' (IVs which are used with every kind of task), but
            #   no 'task parameters' (IVs which are unique to each kind of task)

            # What type of task this is, e.g. 'locator_task', 'attack_bot_task' etc (max 16
            #   characters, A-Z, a-z, underline, numbers (not on first char), non-Latin alphabets
            #   acceptable)
            name                        => 'generic_task',

            # Capitalised form of $self->name, used for (e.g.) task window titles (max 32 chars)
            prettyName                  => 'Generic Task',
            # Each instance of the generic task is given a unique name, just before being blessed
            #   into existence (based on ->name, so assumed to be no more than 24 characters)
            uniqueName                  =>  undef,
            # Very short name (probably just two letters) for display in the Status task's
            #   own window
            shortName                   => 'Gn',
            # For custom tasks, the custom task name (matches a key in GA::Client->customTaskHash,
            #   max 16 chars); set to 'undef' for current and initial tasks
            customName                  => $customName,

            # What category of task, 'process' or 'activity'
            category                    => 'process',
            # Description of the task (any length permitted)
            descrip                     => 'A generic task',
            # 'current', 'initial' or 'custom' (or 'undef' for a temporary task)
            taskType                    => $taskType,
            # ($taskType = 'current') name of the profile from whose initial tasklist this task was
            #   created ('undef' if none)
            # ($taskType = 'initial') name of the profile in whose initial tasklisk this task will
            #   be
            # ($taskType = 'custom') 'undef'
            profName                    => $profName,
            # ($taskType = 'initial') the category of the profile with which this initial task is
            #   associated ('world', 'race', 'guild', 'char', etc)
            # ($taskType = 'current', 'initial') which category the profile falls under (i.e.
            #   'world', 'race', 'char', etc, or 'undef' if no profile)
            # ($taskType = 'custom') 'undef'
            profCategory                => $profCategory,
            # A reference to the GA::Session IV for this task, if there is one (e.g.
            #   GA::Session->locatorTask for the current Locator task). We need it so that, if the
            #   task is destroyed with the ';killtask' command, that IV can be set to 'undef'
            # Set for all built-in tasks that have their ->jealousyFlag set to TRUE; at the
            #   moment, that's all built-in tasks except the Frame and Script tasks. In addition,
            #   only the lead (first) Chat task has its ->shortCutIV set
            # For private tasks, usually set to 'undef'; however, if you write a replacement for
            #   (say) the built-in Attack task, it's possible to set this IV to 'attackTask' - in
            #   which case, when your private task is running and other parts of the Axmud code
            #   consult the current Attack task, they'll consult your private task instead
            shortCutIV                  => undef,

            # Whether multiple instances of this bot can run concurrently
            #   FALSE - any number of concurrent instances can run
            #   TRUE  - only one instance can run
            # (Activity tasks are almost always jealous. Process tasks are often jealous.)
            jealousyFlag                => TRUE,
            # Whether this task requires the Locator task to be running
            #   FALSE - this task doesn't need the Locator task
            #   TRUE  - this task can't run without the Locator task (and will shut down if the
            #       Locator task shuts down)
            requireLocatorFlag          => TRUE,
            # Whether the task should reset itself, if any of the current profiles are changed
            #   (because many tasks depend on data in current profiles; if they suddenly change,
            #   the tasks will at best be relying on obsolete data, and at worst could corrupt the
            #   new current profiles)
            #   FALSE - this task doesn't care if any of the current profiles are changed
            #   TRUE  - this task must reset itself if any of the current profiles are changed
            profSensitivityFlag         => TRUE,
            # Whether this task can be stored as an initial/custom task
            #   FALSE - this task isn't storable (can't be started with ';starttask' under normal
            #               circumstances - e.g. the Advance task, which should be started with
            #               ';advance', and the Chat task, which should be started with ';listen')
            #   TRUE  - this task is storable (can be used as an initial/custom task)
            storableFlag                => TRUE,

            # When the task will start/started - matches GA::Session->sessionTime (in seconds)
            #   [ ->status = 'wait_init' ] the time at which to start
            #   [ ->status = 'running', 'paused'] the time the task actually started
            startTime                   => 0,
            # The next time the task's status should be checked - matches
            #   GA::Session->sessionTime (in seconds)
            #   [ Status = 'wait_task_*] the next time to check (usually after 60 seconds)
            #   [ Status = 'paused'] the time to unpause
            checkTime                   => 0,
            # How the task should stop running
            #   'unlimited' run indefinitely, using the task's code to decide when to shut down
            #   'run_for' run for some time after the task has become active
            #   'run_until' run until a certain time
            endStatus                   => 'unlimited',
            # When the task should stop running (default value is 0 for 'run forever')
            #   [ ->status = 'wait_* ][ ->endStatus = 'run_for' ]
            #       - run for this many minutes
            #   [ ->status = 'wait_* ][ ->endStatus = 'run_until' ]
            #       - run until this system time (matches GA::Session->sessionTime, in seconds)
            #   [ ->status = 'running', 'paused' ][ ->endStatus = 'run_*' ]
            #       - stop at this system time (matches GA::Session->sessionTime, in seconds)
            #   [ ->status = 'finished' ]
            #       - the system time at which the task actually finished (not the time it's due to
            #           finish) (matches GA::Session->sessionTime, in seconds)
            endTime                     => 0,
            # Wait for another task to do something
            #   [ ->status = 'wait_task_*' ]
            #       - the task for which to wait - can match either Task->name or Task->uniqueName
            waitForTask                 => undef,
            # How often the task loop should call this task, in seconds (e.g. 1, call once a second,
            #   0.2, call five times a second)
            # If 0, the task is called once per task loop. The task will never be called more
            #   than once per task loop, so if this IV is set to 0.1 and the task loop is running
            #   once a second, this task will still only be called once a second
            # Set to 0 for all activity tasks
            delayTime                   => 0,

            # Set to TRUE if the task should shut down gracefully, FALSE otherwise
            shutdownFlag                => FALSE,
            # Flag set to TRUE if the task has ever been reset, FALSE if it's never been reset (so
            #   that functions like $self->doFirstStage and ->doInit don't, for example, try to add
            #   widgets to a task window that was created by the pre-reset task, and therefore
            #   already contains widgets)
            hasResetFlag                => FALSE,
            # The task's status
            #   'no_exist' task doesn't exist
            #   'wait_init' waiting to initialise
            #   'wait_task_exist' waiting for a task to exist, before initialising
            #   'wait_task_no_exist' waiting for a task to not exist, before initialising
            #   'wait_task_start_stop' waiting for a task to exist, and then finish, before
            #       initialising
            #   'running' task is active
            #   'paused' task is paused
            #   'finished' task is finished
            #   'reset' task must be reset
            status                      => 'no_exist',
            # The task's resumption status
            #   [->status = 'paused']
            #       - when the task resumes, what its status should be (default is 'running')
            resumeStatus                => undef,
            # For some tasks it's useful to have a functionality of running in an 'active' mode
            #   (actively doing things) or in a 'disactivated' mode (waiting for something to
            #   happen). This IV provides that functionality.
            # If the task is 'active' (or if the functionality isn't needed), the flag is set to
            #   TRUE, if the task is 'disactivated', the variable is set to FALSE. Tasks that don't
            #   need to distinguish between 'active' and 'disactivated' should have this flag set
            #   to TRUE.
            activeFlag                  => TRUE,
            # The task stage (which chunk of the task should be performed on the next task loop).
            #   Should be a number; integers are preferred, but if you use decimals like 1.1 or 1.2,
            #   don't make the stage longer than 5 characters (i.e. don't use 1.1510)
            #   [ ->category = 'process']
            #       - set to 0 until task starts, thereafter any value (usually a number)
            #   [ ->category = 'activity']
            #       - always set to 0 (and should be ignored by the task code)
            stage                       => 0,

            # Task windows can take one of three forms: a 'grid' window (separate from the session's
            #   'main' window), or a table object inside the session's 'main' window,
            #   GA::Table::Pane or GA::Table::PseudoWin
            # GA::Table::Pane creates a simple pane object inside the session's 'main' window.
            #   This task interacts with the pane object and its textview(s) mostly by accessing
            #   $self->defaultTabObj IVs
            # GA::Table::PseudoWin creates a pseudo-window - a window object inheriting from
            #   GA::Generic::GridWin, but which does not open a separate window; instead, the
            #   pseudo-window's widgets are drawn inside the table object
            #
            # There are no built-in tasks which use more than one task window. If you write your own
            #   tasks, the code is free to open additional task windows, and to store those task
            #   windows in its own IVs
            #
            # Is the task allowed to open task windows at all?
            allowWinFlag                => FALSE,
            # Is the task required to have a task window open? (TRUE - the task can't run if a task
            #   window can't be opened and must halt if the window is closed, FALSE - the task can
            #   run without a task window)
            # (Ignored if ->allowWinFlag is FALSE)
            requireWinFlag              => FALSE,
            # Should the task open a task window when it starts? (Ignored if ->allowWinFlag or
            #   ->requireWinFlag are FALSE)
            startWithWinFlag            => FALSE,
            #
            # The comments for the remaining IVs assume the task opens only one task window (if any)
            #
            # What kind of task window this task prefers to open (see the comments just above) - an
            #   ordered list of strings, containing any of the following:
            #   'grid'      - open a 'grid' window
            #   'pane'      - open a pane object inside the session's 'main' window
            #   'entry'     - open a pane object using an entry box inside the session's 'main'
            #                   window
            #   'pseudo'    - opens a pseudo-window inside the session's 'main' window
            # When $self->openWin is called, it will act on each item on the list, from first to
            #   last, until it succeeds in opening a task window (that is to say, if the first item
            #   is 'win' and the code successfully opens a 'grid' window, it ignores the rest of the
            #   list)
            # If it's an empty list, then of course no task window is opened
            winPreferList               => [],
            # For 'grid' and 'pseudo', the blessed reference of the window object
            #   (GA::Win::Internal), if one is open; set to 'undef' otherwise
            winObj                      => undef,
            # For 'pane', 'entry' and 'pseudo', the blessed reference of the table object inside the
            #   session's 'main' window; set to 'undef' otherwise
            # NB For 'pseudo', both ->winObj and ->tableObj are set
            tableObj                    => undef,
            # For all task window types, flag set to TRUE if there is a task window open (i.e.
            #   either ->winObj or ->tableObj are set), set to FALSE if there is no task window open
            #   (both ->winObj and ->tableObj are not set)
            taskWinFlag                 => FALSE,
            # For all task window types, flag set to TRUE if there is a task window open that's
            #   using an entry box; set to FALSE otherwise
            taskWinEntryFlag            => FALSE,
            # For 'grid' and 'pseudo', the winmap to use in the window object, if one is open
            #   (matches a key in GA::Client->winmapHash). If set to 'undef' and a window object is
            #   created, the 'basic_empty' winmap is used
            winmap                      => undef,
            # For all task window types, when the client command ';opentaskwindow' is used to open a
            #   task window some time after the task has started, a function within the task to call
            #   which fills the window with strip objects and table objects, or which initialises
            #   the contents of a pane object, or anything else required (e.g. 'createWidgets',
            #   which would call $self->createWidgets() - a literal function name, not a reference
            #   to a function)
            # If 'undef', no function is called
            winUpdateFunc               => undef,
            # For all task window types, if the task has created a task window that includes a pane
            #   object, the tab object (GA::Obj::Tab) corresponding to the first tab in that pane
            #   object (otherwise set to 'undef')
            # Set automatically if the winmap specified by $self->winmap contains a pane object; can
            #   be set manually otherwise
            defaultTabObj               => undef,
            # For any task window using a pane object, which kind of tab to add to the pane when the
            #   task window opens - 'simple' to create a simple tab (one with no label), 'multi' to
            #   create a tab with a label, and 'empty' to create no tabs at first, leaving an empty
            #   an empty pane
            # For task windows that don't use a pane object, this IV is ignored, so the value should
            #   remain set to 'undef'
            # If set to 'multi' or 'empty', simple tabs are never added; the first tab is always a
            #   normal tab
            tabMode                     => undef,
            # For any task window using a pane object, flag set to TRUE if that pane object uses a
            #   monochrome colour scheme (a specified background colour with a suitable text
            #   colour), which is set by the task itself (for example, the Status task changes
            #   colour when the current' characters hit points change)
            # Flag set to FALSE if the default colour scheme for 'custom' windows should apply (or
            #   if there is no pane object at all)
            monochromeFlag              => FALSE,
            # For any task using a pane object, the colour scheme applied is specified thus:
            #   1. If the following IV is set, that colour scheme is applied
            #   2. Otherwise, if a colour scheme exists with the same name as the task (matching
            #       $self->name, e.g. 'locator_task', or that name with the '_task' removed, e.g.
            #       'locator'), then that colour scheme is applied
            #   3. Otherwise, the colour scheme applied is the same as the window's ->winType (for
            #       all task windows, 'custom')
            colourScheme                => undef,
            # For any task window using a pane object, flag set to TRUE if that pane objecct's
            #   vertical scroll bar, if any, should remain at the top, leaving the first lines in
            #   view; set FALSE if it should scroll to the bottom (as normal)
            noScrollFlag                => FALSE,

            # Flag set to TRUE if this task is capable of doing text-to-speech (TTS), FALSE
            #   otherwise
            ttsFlag                     => FALSE,
            # For tasks that can do TTS, the name of the TTS configuration object to use. If set to
            #   'undef', the default configuration for tasks is used
            ttsConfig                   => undef,
            # TTS attributes and flag attributes.
            # The user can use the client commands ';read', ';switch' and ';alert' to interact with
            #   individual tasks to customise the way they use TTS
            # ';read' is used with TTS attributes, which typically get the task to read out
            #   information (e.g. the Status task can read out current health points).
            # ';switch' is used with TTS flag attributes, which typically tell the task to
            #   automatically read out information (e.g. the Locator task can be told to read out
            #   room titles automatically, as they are received; or not)
            # ';alert' is used with TTS alert attributes, which typically read out a message when
            #   some statistic reaches a certain level (e.g. the Status task can be told to read
            #   out an alert when health points fall below or recover to a certain percentage)
            # A hash of all attributes used by built-in tasks is stored in
            #   GA::Client->constTtsAttribHash, ->constTtsFlagAttribHash and
            #   ->constTtsAlertAttribHash
            # Each GA::Session stores a custom list of attributes, initially set to the same
            #   values, but modified as any user-written tasks start/stop. If a user-written task
            #   wants to use an attribute like 'title', the ';read', ';switch' and ';alert' commands
            #   work with the user-written task, rather than the built-in one. (When the user-
            #   written task halts, the built-in task's attributes are restored)
            # A hash of all TTS (normal) attributes used by this task, in the form
            #   $ttsAttribHash{attribute} = optional_value_or_undef
            # ...where 'attribute' is a string unique to this hash, preferably a single word in all
            #   lower-case letters
            # When the ';read' command calls this task's ->ttsReadAttrib() function, that function
            #   decides how to respond. If it wants to store a value in this hash, it can do so. If
            #   it stores a value, it might be a value specified by the ';read' command, or not.
            #   Otherwise the attribute's corresponding value is 'undef'. The hash should only be
            #   modified by calls to ->ttsReadAttrib()
            ttsAttribHash               => {},
            # A hash of all TTS flag attributes used by this task, in the form
            #   $ttsFlagAttribHash{flag_attribute} = TRUE_or_FALSE_value
            # ...where 'flag_attribute' is a string unique to this hash, preferably a single word in
            #   all lower-case letters
            # When the ';switch' command calls this task's ->ttsSwitchFlagAttrib() function, that
            #   function decides how to respond. Almost always, the TRUE or FALSE value stored in
            #   this hash is toggled, but that's not compulsory. The hash should only be modified
            #   by calls to ->ttsSwitchFlagAttrib()
            ttsFlagAttribHash           => {},
            # A hash of all TTS alert attributes used by this task, in the form
            #   $ttsAlertAttribHash{alert_attribute} = optional_value_or_undef
            # ...where 'alert_attribute' is a string unique to this hash, preferably a single word
            #   in all lower-case letters
            # When the ';alert' command calls this task's ->ttsSetAlertAttrib() function, that
            #   function decides how to respond. If it wants to store a value in this hash, it can
            #   do so. If it stores a value, it might be a value specified by the ';alert' command,
            #   or not. Otherwise the attribute's corresponding value is 'undef'. The hash should
            #   only be modified by calls to ->ttsSetAlertAttrib()
            ttsAlertAttribHash          => {},
        };

        # The generic task is never actually blessed into existence
        return $self;
    }

    sub clone {

        # Create a clone of an existing task
        # Usually used upon connection to a world, when every task in the initial tasklists must
        #   be cloned into a new object, representing a task in the current tasklist
        # (Also used when cloning a profile object, since all the tasks in its initial tasklist must
        #   also be cloned)
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $taskType   - Which tasklist this task is being created into - 'current' for the current
        #                   tasklist (tasks which are actually running now), 'initial' (tasks which
        #                   should be run when the user connects to the world). Custom tasks aren't
        #                   cloned (at the moment)
        #
        # Optional arguments
        #   $profName   - ($taskType = 'initial') name of the profile in whose initial tasklist the
        #                   existing task is stored
        #   $profCategory
        #               - ($taskType = 'initial') which category the profile falls under (i.e.
        #                   'world', 'race', 'char', etc)
        #
        # Return values
        #   'undef' on improper arguments or if the task can't be cloned
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $taskType, $profName, $profCategory, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $taskType || defined $check
            || ($taskType ne 'current' && $taskType ne 'initial')
            || ($taskType eq 'initial' && (! defined $profName || ! defined $profCategory))
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # For initial tasks, check that $profName exists
        if (
            $taskType eq 'initial'
            && defined $profName
            && ! $session->ivExists('profHash', $profName)
        ) {
            return $axmud::CLIENT->writeError(
                'Can\'t create cloned task because \'' . $profName . '\' profile doesn\'t exist',
                $self->_objClass . '->clone',
            );
        }

        # Check that the task doesn't belong to a disabled plugin (in which case, it can't be
        #   cloned)
        if (! $self->checkPlugins()) {

            return undef;
        }

        # Create the new task, using default settings and parameters
        my $clone = $self->_objClass->new($session, $taskType, $profName, $profCategory);

        # Most of the cloned task's settings have default values, but a few are copied from the
        #   original
        $self->cloneTaskSettings($clone);

        # Give the new (cloned) task the same initial parameters as the original one
        # (no parameters to preserve)

        # Cloning complete
        return $clone;
    }

    ##################
    # Methods

    # Constructor support functions

    sub cloneTaskSettings {

        # Called by $self->clone (and nothing else)
        # Most task settings are not copied from the original task to a clone (most of the clone's
        #   task settings continue to have default values), however there are a few task settings
        #   which must be copied from the clone. This function handles it.
        #
        # Expected arguments
        #   $self       - The original task
        #   $clone      - The cloned task
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $clone, $check) = @_;

        # Check for improper arguments
        if (! defined $clone || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->cloneTaskSettings', @_);
        }

        $clone->{_objName}              = $self->{_objName};
        # ->_parentFile / ->_parentWorld has already been set (by ->updateTaskLists)
        $clone->{_objClass}             = $self->{_objClass};
        $clone->{_privFlag}             = TRUE,        # All IVs are private

        # Text-to-speech (TTS) task settings must be copied from the original, so that settings in
        #   tasks stored in the global initial tasklist are transferred to a current task, when it
        #   starts
        $clone->{ttsFlag}               = $self->ttsFlag;
        $clone->{ttsConfig}             = $self->ttsConfig;
        $clone->{ttsAttribHash}         = {$self->ttsAttribHash};
        $clone->{ttsFlagAttribHash}     = {$self->ttsFlagAttribHash};
        $clone->{ttsAlertAttribHash}    = {$self->ttsAlertAttribHash};
        # Same applies to the IV that sets whether a window is opened, when the task starts (for the
        #   benefit of tasks which can do either)
        $clone->{startWithWinFlag}      = $self->startWithWinFlag;
        # Same applies to the preferred colour scheme
        $clone->{colourScheme}          = $self->colourScheme;

        return 1;
    }

    sub preserve {

        # Called by $self->main whenever this task is reset, in order to preserve some if its task
        #   parameters (but not necessarily all of them)
        #
        # Expected arguments
        #   $newTask    - The new task which has been created, to which some of this task's instance
        #                   variables might have to be transferred
        #
        # Return values
        #   'undef' on improper arguments, or if $newTask isn't in the GA::Session's current
        #       tasklist
        #   1 on success

        my ($self, $newTask, $check) = @_;

        # Check for improper arguments
        if (! defined $newTask || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->preserve', @_);
        }

        # Check the task is in the current tasklist
        if (! $self->session->ivExists('currentTaskHash', $newTask->uniqueName)) {

            return $self->writeWarning(
                '\'' . $self->uniqueName . '\' task missing from the current tasklist',
                $self->_objClass . '->preserve',
            );
        }

        # Preserve some task parameters (the others are left with their default settings, some of
        #   which will be re-initialised in stage 2)

        # (no parameters to preserve)

        return 1;
    }

    sub checkPlugins {

        # Called by a task's ->new function (but not by the generic task itself))
        # Checks that this task wasn't created by a plugin which is currently disabled, or not
        #   loaded (in which case, the task can't be added to a current, initial or custom tasklist)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if this task was created by a plugin which is
        #       currently disabled, or not loaded
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($plugin, $pluginObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkPlugins', @_);
        }

        # Was this task created by a plugin?
        if ($axmud::CLIENT->ivExists('pluginTaskHash', $self->name)) {

            $plugin = $axmud::CLIENT->ivShow('pluginTaskHash', $self->name);
            $pluginObj = $axmud::CLIENT->ivShow('pluginHash', $plugin);

            if (! $pluginObj) {

                # This task can't be added to a current, initial or custom tasklist
                return $self->error(
                    'The \'' . $self->name . '\' task was created by a plugin which has not been'
                    . ' loaded',
                );

            } elsif (! $pluginObj->enabledFlag) {

                return $self->error(
                    'The \'' . $self->name . '\' task was created by a plugin which has been'
                    . ' disabled',
                );
            }
        }

        # Otherwise, the task can be added to a current, initial or custom tasklist
        return 1;
    }

    sub setParentFileObj {

        # Called by a task's ->new function (but not by the generic task itself))
        # Sets the standard IVs ->_parentFile and ->_parentWorld, if required
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $taskType       - Which tasklist this task is being created into - 'current', 'initial'
        #                       or 'custom'
        #
        # Optional arguments
        #   $profName       - Name of the profile in whose initial tasklist this task will be (or
        #                       'undef')
        #   $profCategory   - That profile's category (or 'undef')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $taskType, $profName, $profCategory, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $taskType || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setParentFileObj', @_);
        }

        # Initial task in a profile's initial tasklist
        if ($taskType eq 'initial' && defined $profName) {

            if ($profCategory eq 'world') {

                $self->{_parentFile} = $profName;

            } else {

                $self->{_parentFile} = 'otherprof';
                $self->{_parentWorld} = $session->currentWorld->name;
            }

        # Task in the global initial/custom tasklists
        } elsif ($taskType eq 'initial' || $taskType eq 'custom') {

            $self->{_parentFile} = 'tasks';
        }

        return 1;
    }

    sub updateTaskLists {

        # Called by a task's ->new function (but not by the generic task itself))
        # Also called by GA::Obj::File->extractData when importing an initial/custom task
        #
        # Updates the current, global initial, custom or profile initial tasklists with the newly-
        #   created task, as appropriate. Also sets $self->uniqueName
        # NB We use $self->{...} to set the value of IVs, rather than $self->ivPoke(...), to avoid
        #   setting the ->modifyFlag IV of parent GA::Obj::File (stored in $self->_parentFile)
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session (set as an IV for current tasks only)
        #
        # Return values
        #   'undef' on improper arguments or if we try to add a non-storable task to an initial or
        #       custom tasklist
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my $profile;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateTaskLists', @_);
        }

        if ($self->taskType eq 'current') {

            # Give task a unique name within the current tasklist
            $self->{uniqueName} = $self->{name} . '_' . $axmud::CLIENT->inc_taskTotal();
            # Set the session to which this current task will belong
            $self->{session} = $session;
            # Create an entry in the session's current tasklist
            $session->add_task($self);

        } else {

            # If ->storableFlag is not set, the task can't be added to any initial/custom tasklist
            if (! $self->storableFlag) {

                return $self->writeError(
                    '\'' . $self->prettyName . '\' task cannot be added as an initial/custom task',
                    $self->_objClass . '->updateTaskLists',
                );

            } elsif ($self->taskType eq 'initial') {

                if (! defined $self->profName) {

                    # Give task a unique name within the global initial tasklist
                    $self->{uniqueName}
                        = $self->{name} . '_' . $axmud::CLIENT->inc_initTaskTotal();
                    # Create an entry in the global initial tasklist
                    $axmud::CLIENT->add_initTask($self);

                } else {

                    # Give task a unique name within the associated profile's initial tasklist
                    $profile = $session->ivShow('profHash', $self->profName);
                    $self->{uniqueName}
                        = $self->{name} . '_' . $profile->ivIncrement('initTaskTotal');

                    # Inform the associated profile it has acquired a new initial task
                    $profile->ivAdd('initTaskHash', $self->uniqueName, $self);
                    $profile->ivPush('initTaskOrderList', $self->uniqueName);
                }

            } elsif ($self->taskType eq 'custom') {

                # Create an entry in the custom tasklist registry (the ->uniqueName IV isn't set;
                #   the task already has a ->customName)
                $axmud::CLIENT->add_customTask($self);
            }

            # The parent file object should be marked as having had its data modified
            $session->setModifyFlag(
                $self->_parentFile,
                TRUE,
                $self->_objClass . '->updateTaskLists',
            );
        }

        return 1;
    }

    # Code for 'process' tasks

    sub main {

        # All process tasks must have their own main() function which resembles this generic one
        # $self->main() is called by GA::Session->taskLoop() every time the task loop spins
        #
        # Activity tasks should not have a main() function. They inherit their main() function from
        #   this generic task, and an error is displayed if anything tries to call it
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if there is an error, if the task is shutting down or if
        #       the task is reset
        #   Otherwise, we normally return the new value of $self->stage

        my ($self, $check) = @_;

        # Local variables
        my $newTaskObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->main', @_);
        }

        if ($self->category eq 'activity') {

            # Issue a warning - activity tasks should not have their own main function, and it
            #   should not be called
            return $self->writeError(
                '\'' . $self->uniqueName . '\' task is an activity task, but its ->main() function'
                . ' was called',
                $self->_objClass . '->main',
            );

        } elsif ($self->shutdownFlag) {

            # There are two ways to stop a task - by setting its status to 'finished' (in which case
            #   it stops immediately), or by setting its ->shutdownFlag to TRUE
            # Task is shutting down. Close the task window, if it is open
            if ($self->taskWinFlag) {

                $self->closeWin();
            }

            # For built-in jealous tasks, inform the GA::Session that a built-in task has stopped
            #   running
            if ($self->shortCutIV) {

                $self->session->del_standardTask($self);
            }

            # If the Status task is running, tell it to update its display of active tasks (unless
            #   this task is the Status task, of course)
            if ($self->name ne 'status_task') {

                $self->session->update_statusTask();
            }

            # Execute any other code (each task can define their own ->doShutdown() function)
            $self->doShutdown();

            # This task can stop immediately
            $self->ivPoke('status', 'finished');
            return undef;

        } elsif ($self->status eq 'reset') {

            # The task is resetting
            # Create a new copy of this task, preserving some of its task parameters, but setting
            #   other task parameters to their default states
            $newTaskObj = $self->_objClass->new($self->session, 'current');
            if (! $newTaskObj) {

                # Reset failed; halt this task instead
                $self->ivPoke('status', 'finished');

                return $self->writeError(
                    'Failed to reset \'' . $self->uniqueName . '\' task - halting task instead',
                    $self->_objClass . '->main',
                );
            }

            # Also preserve a few task settings. The new task has the same ->endStatus, ->endTime
            #   and TTS settings as this one
            $newTaskObj->set_endStatus($self->endStatus);
            $newTaskObj->set_endTime($self->endTime);
            $newTaskObj->set_hasResetFlag(TRUE);
            $newTaskObj->set_ttsConfig($self->ttsConfig);
            $newTaskObj->set_ttsHash($self);
            # New task should be 'running', and start at stage 2 on the next task loop
            $newTaskObj->set_status('running');
            $newTaskObj->set_stage(2);

            # Copy some of this task's parameters to the new task
            $self->preserve($newTaskObj);

            # For built-in jealous tasks, inform the GA::Session that an old built-in task has
            #   stopped running, and that a new one has started running
            if ($self->shortCutIV) {

                $self->session->del_standardTask($self);
            }

            if ($newTaskObj->shortCutIV) {

                $self->session->add_standardTask($newTaskObj);
            }

            # If the Status task is running, tell it to update its display of active tasks (unless
            #   this task is the Status task, of course)
            if ($self->name ne 'status_task') {

                $self->session->update_statusTask();
            }

            # If there is a task window open, transfer it to the new task
            $self->transferWin($newTaskObj);

            # Execute any other code (each task can define their own ->doReset() function)
            $self->doReset($newTaskObj);

            # This task must stop immediately, to be replaced by $newTaskObj on the next task loop
            $self->ivPoke('status', 'finished');
            return undef;

        } elsif ($self->stage == 1) {

            # Create a new task window (if possible)
            if (
                ! $self->taskWinFlag
                && $self->allowWinFlag
                && ($self->requireWinFlag || $self->startWithWinFlag)
            ) {
                # Create a new task window
                if (! $self->openWin($self->winmap) && $self->requireWinFlag) {

                    # The window was not opened, but the task requires a window in order to run, so
                    #   it must be halted
                    $self->writeWarning(
                        '\'' . $self->uniqueName . '\' task couldn\'t open its own window'
                        . ' - aborting task',
                        $self->_objClass . '->main',
                    );

                    $self->ivPoke('status', 'finished');
                    return undef;
                }
            }

            # Set the global variable to tell any interested parties that this built-in task is
            #   running
            $self->session->add_standardTask($self);
            # If the Status task is running, tell it to update its display of active tasks (unless
            #   this task is the Status task, of course)
            if ($self->name ne 'status_task') {

                $self->session->update_statusTask();
            }

            # Execute any other code (each task can define their own ->doFirstStage() function)
            $self->doFirstStage();

            return $self->ivPoke('stage', 2);

        } else {

            # Process stages 2+
            return $self->doStage();
        }
    }

    sub doFirstStage {

        # Called by $self->main, just before the task completes the first stage ($self->stage)
        # This function does nothing, so tasks that need to do something special during the first
        #   stage should have their own ->doFirstStage function
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->doFirstStage', @_);
        }

        # (This generic ->doFirstStage function does nothing)

        return 1;
    }

    sub doStage {

        # Called by $self->main to process all stages (except stage 1)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if this function sets that task's ->status IV to
        #       'finished' or sets its ->shutdownFlag to TRUE
        #   Otherwise, we normally return the new value of $self->stage

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->doStage', @_);
        }

        if ($self->stage == 2) {

            # (This generic ->doFirstStage function does nothing at stage 2, which repeats
            #   indefinitely)
            return $self->ivPoke('stage', 2);

        } else {

            # The task stage has somehow been set to an invalid value
            return $self->invalidStage();
        }
    }

    sub invalidStage {

        # Called by $self->doStage when $self->stage has been set to an unrecognised value
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef'

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->invalidStage', @_);
        }

        # If $self->stage has been set to an unrecognised value, we can't continue
        $self->ivPoke('status', 'finished');

        return $self->writeError(
            '\'' . $self->uniqueName . '\' task : undefined task stage \'' . $self->stage . '\'',
            $self->_objClass . '->invalidStage',
        );
    }

    # Code for 'activity' tasks

    sub init {

        # All activity tasks must have their own init() function which resembles this generic one
        # $self->init() is called by GA::Session->taskLoop() once, when the task is added to the
        #   current tasklist
        #
        # Process tasks should not have an init() function. They inherit their init() function from
        #   this generic task, and an error is displayed if anything tries to call it
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if there is an error, if the task is shutting down or if
        #       the task is reset
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        #   ...

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->init', @_);
        }

        if ($self->category eq 'process') {

            # Issue a warning - process tasks should not have their own init function, and it should
            #   not be called
            return $self->writeError(
                '\'' . $self->uniqueName . '\' task is a process task, but its ->init() function'
                . ' was called',
                $self->_objClass . '->init',
            );
        }

        # Create a new task window (if possible)
        if (
            ! $self->taskWinFlag
            && $self->allowWinFlag
            && ($self->requireWinFlag || $self->startWithWinFlag)
        ) {
            # Create a new task window
            if (! $self->openWin($self->winmap) && $self->requireWinFlag) {

                # The window was not opened, but the task requires a window in order to run, so it
                #   must be halted
                $self->writeWarning(
                    '\'' . $self->uniqueName . '\' task couldn\'t open its own window'
                    . ' - aborting task',
                    $self->_objClass . '->main',
                );

                $self->ivPoke('status', 'finished');
                return undef;
            }
        }

        # For built-in jealous tasks, inform the GA::Session that a built-in task has started
        #   running
        if ($self->shortCutIV) {

            $self->session->add_standardTask($self);
        }

        # If the Status task is running, tell it to update its display of active tasks (unless
        #   this task is the Status task, of course)
        if ($self->name ne 'status_task') {

            $self->session->update_statusTask();
        }

        # Execute any other code (each task can define their own ->doInit() function)
        $self->doInit();

        # Setup complete
        return 1;
    }

    sub doInit {

        # Called by $self->init, just before the task completes its setup ($self->init)
        # This function does nothing, so tasks that need to do something special during a reset
        #   should have their own ->doInit function
        # NB If this function modifies the task window - for example, if it should add table objects
        #   to the window - the function should first check $self->hasResetFlag, and refrain from
        #   creating new table objects for a window that already contains them (some example code
        #   appears below)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->doInit', @_);
        }

        # (This generic ->doInit function does nothing)

        # If the task creates a window with various table objects, it might be easier to remove
        #   them all, rather than writing code to update them all when the task resets. You can use
        #   this example code in that case
#        if ($self->hasResetFlag) {
#
#           if (! defined $self->winObj->tableStripObj->removeAllTableObjs()) {
#
#               # Operation failed; task must close
#               $self->ivPoke('shutdownFlag', TRUE);
#               return 1;
#           }
#       }

        return 1;
    }

    sub shutdown {

        # All activity tasks must have their own shutdown() function to allow the task to shut down
        #   gracefully
        # $self->shutdown is called by GA::Session->taskLoop() once, when its ->shutdownFlag is
        #   set to TRUE
        # Also called by GA::Session->stop, should the session have to stop suddenly (makes sure
        #   any task windows are closed)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->shutdown', @_);
        }

        # Task is shutting down. Close the task window, if it is open
        if ($self->taskWinFlag) {

            $self->closeWin();
        }

        # For built-in jealous tasks, inform the GA::Session that a built-in task has stopped
        #   running
        if ($self->shortCutIV) {

            $self->session->del_standardTask($self);
        }

        # If the Status task is running, tell it to update its display of active tasks (unless this
        #   task is the Status task, of course)
        if ($self->name ne 'status_task') {

            $self->session->update_statusTask();
        }

        # Execute any other code (each task can define their own ->doShutdown() function)
        $self->doShutdown();

        # Task can stop immediately
        $self->ivPoke('status', 'finished');
        return undef;
    }

    sub reset {

        # All activity tasks must have their own reset() function to allow the task to reset
        #   properly
        # $self->reset is called by GA::Session->taskLoop() once, when its ->status is set to
        #   'reset'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef'

        my ($self, $check) = @_;

        # Local variables
        my $newTaskObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset', @_);
        }

        # The task is resetting
        # Create a new copy of this task, preserving some of its task parameters, but setting other
        #   task parameters to their default states
        $newTaskObj = $self->_objClass->new($self->session, 'current');
        if (! $newTaskObj) {

            # Reset failed; halt this task instead
            $self->ivPoke('status', 'finished');

            return $self->writeError(
                'Failed to reset \'' . $self->uniqueName . '\' task - halting task instead',
                $self->_objClass . '->reset',
            );
        }

        # Also preserve a few task settings. The new task has the same ->endStatus, ->endTime and
        #   TTS settings as this one
        $newTaskObj->set_endStatus($self->endStatus);
        $newTaskObj->set_endTime($self->endTime);
        $newTaskObj->set_hasResetFlag(TRUE);
        $newTaskObj->set_ttsConfig($self->ttsConfig);
        $newTaskObj->set_ttsHash($self);
        # New task's status should be left as 'wait_init', so that its ->init function will be
        #   called on the next task loop
        $newTaskObj->set_status('wait_init');

        # Copy some of this task's parameters to the new task
        $self->preserve($newTaskObj);

        # For built-in jealous tasks, inform the GA::Session that an old built-in task has stopped
        #   running, and that a new one has started running
        if ($self->shortCutIV) {

            $self->session->del_standardTask($self);
        }

        if ($newTaskObj->shortCutIV) {

            $self->session->add_standardTask($newTaskObj);
        }

        # If the Status task is running, tell it to update its display of active tasks (unless this
        #   task is the Status task, of course)
        if ($self->name ne 'status_task') {

            $self->session->update_statusTask();
        }

        # If there is a task window open, transfer it to the new task
        $self->transferWin($newTaskObj);

        # Execute any other code (each task can define their own ->doReset() function)
        $self->doReset($newTaskObj);

        # This task must stop immediately, to be replaced by $newTaskObj on the next task loop
        $self->ivPoke('status', 'finished');
        return undef;
    }

    # Code for both 'process' and 'activity' functions

    sub doShutdown {

        # Called just before the task completes a shutdown
        # For process tasks, called by $self->main. For activity tasks, called by $self->shutdown
        #
        # This function does nothing, so tasks that need to do something special during a shutdown
        #   should have their own ->doShutdown function
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->doShutdown', @_);
        }

        # (This generic ->doShutdown function does nothing)

        return 1;
    }

    sub doReset {

        # Called just before the task completes a reset
        # For process tasks, called by $self->main. For activity tasks, called by $self->reset
        #
        # This function does nothing, so tasks that need to do something special during a reset
        #   should have their own ->doReset function
        #
        # Expected arguments
        #   $newTaskObj     - The replacement task object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $newTaskObj, $check) = @_;

        # Check for improper arguments
        if (! defined $newTaskObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->doReset', @_);
        }

        # (This generic ->doReset function does nothing)

        return 1;
    }

    # Task window functions

    sub toggleWin {

        # Called by GA::Cmd::OpenTaskWindow->do and CloseTaskWindow->do
        # Decides what to do if the user tries to open or close a task window for this task
        # Should usually display a message informing the user of what it decided to do
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the task isn't able to open a task window
        #   1 if the window is opened/closed

        my ($self, $check) = @_;

        # Local variables
        my $func;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleWin', @_);
        }

        if (! $self->allowWinFlag) {

            # This task isn't allowed to open a window
            return $self->writeError(
                'Windows not available for this task',
                $self->_objClass . '->toggleWin',
            );

        } elsif ($self->taskWinFlag) {

            # A window is open, so close it
            $self->closeWin();

            if ($self->requireWinFlag) {

                # The task should shut down when its window is closed
                $self->ivPoke('shutdownFlag', TRUE);
                $self->writeText(
                    'Window for \'' . $self->prettyName . '\' task closed (task will also halt)',
                );

            } else {

                # The task can continue without a window
                $self->writeText(
                    'Window for \'' . $self->prettyName . '\' task closed',
                );
            }

            # Window closing complete
            return 1;

        } else {

            # A window is not currently open, so open it
            $self->openWin($self->winmap);

            if (! $self->taskWinFlag) {

                if ($self->requireWinFlag) {

                    # The task cannot run without a window
                    $self->ivPoke('shutdownFlag', TRUE);
                    $self->writeText(
                        'Window for \'' . $self->prettyName . '\' task could not be opened (task'
                        . ' will be halted)',
                    );

                } else {

                    # The task can continue without a window
                    $self->writeText(
                        'Window for \'' . $self->prettyName . '\' task could not be opened',
                    );
                }

            } else {

                $self->writeText(
                    'Window for \'' . $self->prettyName . '\' task opened',
                );

                # If the task defines a function to call, in order to set up the window after being
                #   opened, call the function now
                $func = $self->winUpdateFunc;
                if ($func) {

                    $self->$func();
                }
            }

            # Window opening complete
            return 1;
        }
    }

    sub openWin {

        # Called by the task's ->main method or by its ->toggleWin method, or by any other code
        # Tries to open each type of task window in $self->winPreferList, halting at the first
        #   successful attempt (or when all attempts fail)
        #
        # Expected arguments
        #   (none besides self)
        #
        # Optional arguments
        #   $winmap     - The winmap to use in a 'grid' window or a pseudo-window (matches a key in
        #                   GA::Client->winmapHash). If 'undef', $self->winmap is used
        #   @preferList - The types of task window to try to open. If not an empty list, this list
        #                   is used rather than $self->winPreferList
        #
        # Return values
        #   'undef' on improper arguments, if $winmap doesn't exist (when specified, checked even if
        #       a 'grid' window isn't opened) or if a task window is not opened
        #   1 if a window is opened

        my ($self, $winmap, @preferList) = @_;

        # Local variables
        my ($winmapObj, $result);

        # (No improper arguments to check)

        # Don't open a task window if it's not allowed, or if there's already one open
        # Additionally, in Axmud 'blind' mode, don't open a task window unless it's required (the
        #   task won't run without a window)
        if (
            ! $self->allowWinFlag
            || ! $self->winPreferList
            || $self->taskWinFlag
            || ($axmud::BLIND_MODE_FLAG && ! $self->requireWinFlag)
        ) {
            return undef;
        }

        # If $winmap wasn't specified, use the winmap specified by the IV or a default winmap, if
        #   necessary
        if (! $winmap) {

            if ($self->winmap) {
                $winmap = $self->winmap;
            } else {
                $winmap = 'basic_empty';
            }
        }

        # Check the winmap exists
        $winmapObj = $axmud::CLIENT->ivShow('winmapHash', $winmap);
        if (! $winmapObj) {

            return undef;
        }

        # Open a task window, giving up after the first successful attempt
        if (! @preferList) {

            @preferList = $self->winPreferList;
        }

        OUTER: foreach my $item (@preferList) {

            if ($item eq 'grid') {
                $result = $self->openGridWin($winmapObj);
            } elsif ($item eq 'pane') {
                $result = $self->openPaneWin($winmapObj, FALSE);
            } elsif ($item eq 'entry') {
                $result = $self->openPaneWin($winmapObj, TRUE);
            } elsif ($item eq 'pseudo') {
                $result = $self->openPseudoWin($winmapObj);
            }

            if ($result) {

                last OUTER;
            }
        }

        return $result;
    }

    sub openGridWin {

        # Called by the $self->openWin (only)
        # Tries to open a task window as a 'grid' window (in response to 'grid' in
        #   $self->winPreferList)
        #
        # Expected arguments
        #   $winmapObj  - The winmap object to use in the task window (matches a value in
        #                   GA::Client->winmapHash)
        #
        # Return values
        #   'undef' on improper arguments or if a 'grid' window is not opened
        #   1 if a 'grid' window is opened

        my ($self, $winmapObj, $check) = @_;

        # Local variables
        my (
            $winObj,
            @workspaceList,
        );

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->openGridWin', @_);
        }

        # Compile a list of workspaces, with the workspace containing the parent session's 'main'
        #   window first
        @workspaceList
            = $axmud::CLIENT->desktopObj->listWorkspaces($self->session->mainWin->workspaceObj);

        OUTER: foreach my $workspaceObj (@workspaceList) {

            $winObj = $workspaceObj->createGridWin(
                'custom',                   # All task windows are 'custom' windows
                $self->name,                # Window name is the same as the task name
                $self->prettyName,          # Window title
                $winmapObj->name,
                'Games::Axmud::Win::Internal',
                                            # Package name
                undef,                      # No windows exists yet
                undef,                      # Ditto
                $self,                      # Owner
                $self->session,
                $workspaceObj->findWorkspaceGrid($self->session),
                                            # Session's workspace grid object
            );

            if ($winObj) {

                last OUTER;
            }
        }

        if (! $winObj) {

            # Window not opened
            return undef;

        } else {

            # Window created and enabled
            $self->ivPoke('winObj', $winObj);
            $self->ivPoke('taskWinFlag', TRUE);
            # Set its title
            $self->setTaskWinTitle();

            # In Axmud 'blind' mode, make sure the session's 'main' window is not obscured by the
            #   newly-opend task window
            if ($axmud::BLIND_MODE_FLAG) {

                $self->session->mainWin->restoreFocus();
            }
        }

        # Add a tab, if required. The TRUE argument indicates window setup
        $self->addTab(undef, TRUE);
        # Set up the entry box, if present
        $self->setupEntry();

        return 1;
    }

    sub openPaneWin {

        # Called by the $self->openWin (only)
        # Tries to open a task window as a pane object (GA::Table::Pane) inside the session's 'main'
        #   window (in response to 'pane' or 'entry' in $self->winPreferList)
        #
        # Expected arguments
        #   $winmapObj  - The winmap object that would be used if a 'grid' window were opened
        #                   instead. This function sometimes uses it to work out with the pane
        #                   object should have an entry box, or not; in that situation, it chooses
        #                   no entry box if this value is 'undef'
        #
        # Optional arguments
        #   $entryFlag  - TRUE if the pane object should have its own entry box, FALSE (or 'undef')
        #                   if not
        #
        # Return values
        #   'undef' on improper arguments or if a pane object is not created
        #   1 if a pane object is created

        my ($self, $winmapObj, $entryFlag, $check) = @_;

        # Local variables
        my ($stripObj, $entryFunc, $left, $right, $top, $bottom, $tableObj, $tabObj);

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->openPaneWin', @_);
        }

        # Tasks can't create pane objects inside 'main' windows if it's a 'main' window shared
        #   between sessions
        if ($axmud::CLIENT->shareMainWinFlag) {

            return undef;
        }

        # If there's an entry box, set the callback function
        if ($entryFlag) {

            $entryFunc = $self->getMethodRef('entryCallback');
        }

        # Ask the session's 'main' window for the size and position of another table object, using
        #   the winmap's default winzone size, and check whether space exists for another table
        #   object
        $stripObj = $self->session->mainWin->tableStripObj;
        ($left, $right, $top, $bottom) = $stripObj->findPosn();
        if (! defined $left) {

            # No room for another table object
            return undef;
        }

        # Create a pane object at the specified size and position
        $tableObj = $stripObj->addTableObj(
            'Games::Axmud::Table::Pane',
            $left,
            $right,
            $top,
            $bottom,
            undef,          # No ->objName
            # ->initHash
            'frame_title'       => $self->prettyName,
            'entry_flag'        => $entryFlag,
            'func'              => $entryFunc,
            'id'                => $self->uniqueName,
            'new_line'          => 'before',
        );

        if (! $tableObj) {

            return undef;
        }

        # Pane object created and enabled
        $self->ivPoke('tableObj', $tableObj);
        $self->ivPoke('taskWinFlag', TRUE);
        $self->ivPoke('taskWinEntryFlag', $entryFlag);

        # Add a tab, if required. The TRUE argument indicates window setup
        $self->addTab(undef, TRUE);

        # Operatin complete
        return 1;
    }

    sub openPseudoWin {

        # Called by the $self->openWin (only)
        # Tries to open a task window as a pseudo-window inside the session's 'main' window, the
        #   pseudo-window being handled by the table object GA::Table::PseudoWin (in response to
        #   'pseudo' in $self->winPreferList)
        #
        # Expected arguments
        #   $winmapObj  - The winmap object to use in the task window (matches a value in
        #                   GA::Client->winmapHash)
        #
        # Return values
        #   'undef' on improper arguments or if the pseudo-window is not opened
        #   1 if a pane object is created

        my ($self, $winmapObj, $entryFlag, $check) = @_;

        # Local variables
        my ($stripObj, $tableObj, $left, $right, $top, $bottom, $paneObj, $tabObj, $entryObj);

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->openPseudoWin', @_);
        }

        # Tasks can't create boxes inside 'main' windows if it's a 'main' window shared between
        #   sessions
        if ($axmud::CLIENT->shareMainWinFlag) {

            return undef;
        }

        # If there are any holders (GA::Table::Holder) with a suitable ->id, we can use the space
        #   they occupy, rather than looking for a new space
        # Try (for example) 'status_task' first, then 'task'
        $stripObj = $self->session->mainWin->tableStripObj;
        $tableObj = $stripObj->replaceHolder(
            $self->name,
            'Games::Axmud::Table::PseudoWin',
            undef,          # No ->objName
            # ->initHash
            'frame_title'       => $self->prettyName,
            'win_type'          => 'custom',
            'win_name'          => $self->prettyName,
            'owner'             => $self,
            'session'           => $self->session,
            'winmap'            => $winmapObj->name,
        );

        if (! $tableObj) {

            $stripObj->replaceHolder(
                'task',
                'Games::Axmud::Table::PseudoWin',
                undef,          # No ->objName
                # ->initHash
                'frame_title'       => $self->prettyName,
                'win_type'          => 'custom',
                'win_name'          => $self->prettyName,
                'owner'             => $self,
                'session'           => $self->session,
                'winmap'            => $winmapObj->name,
            );
        }

        if (! $tableObj) {

            # Ask the session's 'main' window for the size and position of another table object,
            #   using the winmap's default winzone size, and check whether space exists for another
            #   table object
            ($left, $right, $top, $bottom) = $stripObj->findPosn();
            if (! defined $left) {

                # No room for another table object
                return undef;
            }

            # Create the GA::Table::PseudoWin object at the specified size and position
            $tableObj = $stripObj->addTableObj(
                'Games::Axmud::Table::PseudoWin',
                $left,
                $right,
                $top,
                $bottom,
                undef,          # No ->objName
                # ->initHash
                'frame_title'       => $self->prettyName,
                'win_type'          => 'custom',
                'win_name'          => $self->prettyName,
                'owner'             => $self,
                'session'           => $self->session,
                'winmap'            => $winmapObj->name,
            );
        }

        if (! $tableObj) {

            return undef;
        }

        # Table object created and enabled
        $self->ivPoke('tableObj', $tableObj);
        $self->ivPoke('winObj', $tableObj->pseudoWinObj);
        $self->ivPoke('taskWinFlag', TRUE);
        $self->ivPoke('taskWinEntryFlag', $entryFlag);

        # Add a tab, if required. The TRUE argument indicates window setup
        $self->addTab(undef, TRUE);
        # Set up the entry box, if present
        $self->setupEntry();

        return 1;
    }

    sub closeWin {

        # Called by the task's ->main method or by its ->toggleWin method, or by any other code
        # Close the task window for this task, if it is open
        #
        # Expected arguments
        #   (none besides self)
        #
        # Return values
        #   'undef' on improper arguments or if the window was not closed
        #   1 if the window was closed

        my ($self, $check) = @_;

        # Local variables
        my $result;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->closeWin', @_);
        }

        if ($self->tableObj) {

            # Remove a pseudo-window or a pane object inside this session's 'main' window
            $result = $self->session->mainWin->tableStripObj->removeTableObj($self->tableObj);
            $self->ivUndef('tableObj');
            $self->ivUndef('winObj');

        } elsif ($self->winObj) {

            # Remove a 'grid' window
            $result = $self->winObj->winDestroy();
            $self->ivUndef('winObj');
        }

        $self->ivPoke('taskWinFlag', FALSE);
        $self->ivPoke('taskWinEntryFlag', FALSE);
        $self->ivUndef('defaultTabObj');

        # If the task window could not be closed, or wasn't open in the first place, return 'undef';
        #   otherwise return 1
        return $result;
    }

    sub transferWin {

        # Called by the task's ->main and ->reset functions
        # Transfers the task window to a new task
        #
        # Expected arguments
        #   $newTaskObj     - The new task
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $newTaskObj, $check) = @_;

        # Check for improper arguments
        if (! defined $newTaskObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->transferWin', @_);
        }

        if ($self->winObj && $self->tableObj) {

            # Transfer a pseudo-window inside this session's 'main' window
            $newTaskObj->set_winObj($self->winObj);
            $newTaskObj->set_tableObj($self->tableObj);
            $newTaskObj->set_taskWinFlag($self->taskWinFlag);
            $newTaskObj->set_taskWinEntryFlag($self->taskWinEntryFlag);
            if ($self->defaultTabObj) {

                $newTaskObj->set_defaultTabObj($self->defaultTabObj);
            }

            $newTaskObj->setTaskWinTitle();
            $newTaskObj->insertText('<task reset>', 'empty');
            $newTaskObj->winObj->set_owner($newTaskObj);

        } elsif ($self->winObj) {

            # Transfer a 'grid' window
            $newTaskObj->set_winObj($self->winObj);
            $newTaskObj->set_taskWinFlag($self->taskWinFlag);
            $newTaskObj->set_taskWinEntryFlag($self->taskWinEntryFlag);
            if ($self->defaultTabObj) {

                $newTaskObj->set_defaultTabObj($self->defaultTabObj);
            }

            $newTaskObj->setTaskWinTitle();
            $newTaskObj->insertText('<task reset>', 'empty');
            $newTaskObj->winObj->set_owner($newTaskObj);
            $newTaskObj->winObj->resetUrgent(TRUE);

        } elsif ($self->tableObj) {

            # Remove a pane object inside this session's 'main' window
            $newTaskObj->set_tableObj($self->tableObj);
            $newTaskObj->set_taskWinFlag($self->taskWinFlag);
            $newTaskObj->set_taskWinEntryFlag($self->taskWinEntryFlag);
            if ($self->defaultTabObj) {

                $newTaskObj->set_defaultTabObj($self->defaultTabObj);
            }

            $newTaskObj->setTaskWinTitle();
            $newTaskObj->insertText('<task reset>', 'empty');
        }

        return 1;
    }

    sub addTab {

        # Can be called by any code. During window setup, called by $self->openGridWin,
        #   ->openPaneWin and ->openPseudoWin
        # Adds a tab to the task window's pane object, and updates IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $labelText  - If defined, the tab label text to use. Ignored when a simple tab is
        #                   created
        #   $openFlag   - Set to TRUE when called during window setup, in which case a tab is not
        #                   opened if $self->tabMode is 'empty'. Set to FALSE (or 'undef') when
        #                   called by anything else, in which case this function treats values of
        #                   $self->tabMode 'empty and 'multi' the same, in other words, for all
        #                   defined values of $self->tabMode, we try to open a tab
        #
        # Return values
        #   'undef' on improper arguments or if no tab is added to the pane object
        #   Otherwise returns the tab object (GA::Obj::Tab) created

        my ($self, $labelText, $openFlag, $check) = @_;

        # Local variables
        my ($paneObj, $tabObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addTab', @_);
        }

        # Check the window is actually open
        if (! $self->winObj) {

            return undef;
        }

        # Find the pane object (GA::Table::Pane), if one was created
        $paneObj = $self->winObj->findTableObj('pane');

        # The type of tab created depends on the value of $self->tabMode
        if (
            # No pane object exists
            ! $paneObj
            # Can't create tabs at all, if ->tabMode not set
            || ! defined $self->tabMode
            # Can't create a simple tab, if one already exists
            || ($self->tabMode eq 'simple' && $self->defaultTabObj)
        ) {
            return undef;
        }

        if ($self->tabMode eq 'simple') {

            $tabObj = $paneObj->addSimpleTab(
                $self->session,
                $self->getColourScheme(),
            );

        } elsif (
            ($openFlag && $self->tabMode eq 'multi')
            || ! $openFlag
        ) {
            $tabObj = $paneObj->addTab(
                $self->session,
                $self->getColourScheme(),
                undef,
                undef,
                $labelText,
            );
        }

        if (! $tabObj) {

            return undef;
        }

        if (! $self->defaultTabObj) {

            # The first tab added is the default one
            $self->ivPoke('defaultTabObj', $tabObj);
        }

        # The default newline behaviour for task windows is to insert a newline character before
        #   each string displayed, rather than inserting one afterwards (as usual)
        $tabObj->textViewObj->set_newLineDefault('before');

        # Mark the pane's textview object as monochrome, if required
        if ($self->monochromeFlag) {

            $tabObj->paneObj->applyMonochrome($tabObj);
        }

        # Prevent the pane's textview from scrolling downwards
        if ($tabObj && $self->noScrollFlag) {

            $tabObj->textViewObj->set_scrollLockType('top');
            $tabObj->textViewObj->toggleScrollLock();
        }

        # Call a task function when the visible tab changes
        $paneObj->set_switchFunc($self->getMethodRef('switchTabCallback'));
        $paneObj->set_switchID($self->name);

        # Operation complete
        return $tabObj;
    }

    sub removeTab {

        # Can be called by any code
        # The task window's set up functions add a first tab (or not) to the window, and then other
        #   parts of the task code are free to call $self->addTab to add more tabs, in which case
        #   this function can be called to remove them again
        # When the task window closes, it's not necessary to call this function at all
        #
        # Expected arguments
        #   $arg    - So that tasks have flexibility over the way they store the tabs they create,
        #               $arg can be the tab object (GA::Obj::Tab) or the tab object's ->number
        #
        # Return values
        #   'undef' on improper arguments, if the specified tab no longer exists in the task
        #       window's pane object (GA::Table::Pane) or if the close operation fails
        #   1 if the close operation succeeds

        my ($self, $arg, $check) = @_;

        # Local variables
        my ($paneObj, $result);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupEntry', @_);
        }

        # Check the task window is actually open
        if (! $self->winObj) {

            return undef;
        }

        # Find the pane object (GA::Table::Pane)
        $paneObj = $self->winObj->findTableObj('pane');

        if ($axmud::CLIENT->intCheck($arg, 0)) {

            $arg = $paneObj->ivShow('tabObjHash', $arg);
            if (! defined $arg) {

                # Tab has already been removed
                return undef;
            }

        } elsif (
            ! $paneObj->ivExists('tabObjHash', $arg->number)
            || $paneObj->ivShow('tabObjHash', $arg->number) ne $arg
        ) {
            # Tab has already been removed
            return undef;
        }

        # Remove the tab
        $result = $paneObj->removeTab($arg);

        # Update standard IVs
        if ($self->defaultTabObj && $self->defaultTabObj eq $arg) {

            $self->ivUndef('defaultTabObj');
        }

        # Operation complete
        return $result;
    }

    sub setupEntry {

        # Called by $self->openGridWin, ->openPaneWin and ->openPseudoWin (only)
        # Sets up the task window's entry box, if it exists
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if no entry box exists
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $entryObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupEntry', @_);
        }

        if (! $self->winObj) {

            return undef;
        }

        # Find the entry for this window, if one was created, and set its callback function. The
        #   entry box may have been created by a strip object (GA::Strip::Entry) or a table object
        #   (GA::Table::Entry)
        $entryObj = $self->winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::Entry');
        if (! $entryObj) {

            $entryObj = $self->winObj->findTableObj('entry');
        }

        if (! $entryObj) {

            $self->ivPoke('taskWinEntryFlag', FALSE);

            return undef;

        } else {

            $self->ivPoke('taskWinEntryFlag', TRUE);
            $entryObj->set_func($self->getMethodRef('entryCallback'));
            $entryObj->set_id($self->uniqueName);

            return 1;
        }
    }

    sub setTaskWinTitle {

        # Can be called by any code to set or restore the text in the task window label: the title
        #   bar for a 'grid' window, or the frame title for a pane object in the session's 'main'
        #   window
        #
        # Expected arguments
        #   (none besides self)
        #
        # Optional arguments
        #   $string     - A string to add the title bar (if 'undef', the default title is used)
        #   $flag       - If TRUE, $string is added to the usual text; otherwise string replaces
        #                   the usual text
        #
        # Return values
        #   'undef' on improper arguments or if the task window is not open
        #   1 if the window was closed

        my ($self, $string, $flag, $check) = @_;

        # Local variables
        my $text;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setTaskWinTitle', @_);
        }

        # Set the default title bar text for task windows
        $text = $self->prettyName;

        # If $string was specified, append it to $text (or overwrite $text)
        if (defined $string) {

            if ($flag) {
                $text .= ' ' . $string;
            } else {
                $text = $string;
            }
        }

        # Update the label
        if ($self->tableObj) {

            # Set the frame title (calling a function in GA::Generic::Table)
            $self->tableObj->set_frameTitle($text);
            return 1;

        } elsif ($self->winObj) {

            # Set the title bar (calling a function in GA::Win::Internal)
            $self->winObj->setWinTitle($text);
            return 1;

        } else {

            # Task window not open
            return undef;
        }
    }

    # Shortcuts to GA::Obj::TextView for the task's default tab

    sub clearBuffer {

        my ($self, @args) = @_;

        if ($self->defaultTabObj) {
            return $self->defaultTabObj->textViewObj->clearBuffer(@args);
        } else {
            return undef;
        }
    }

    sub insertText {

        my ($self, @args) = @_;

        if ($self->defaultTabObj) {
            return $self->defaultTabObj->textViewObj->insertText(@args);
        } else {
            return undef;
        }
    }

    sub insertWithLinks {

        my ($self, @args) = @_;

        if ($self->defaultTabObj) {
            return $self->defaultTabObj->textViewObj->insertWithLinks(@args);
        } else {
            return undef;
        }
    }

    sub insertQuick {

        my ($self, @args) = @_;

        if ($self->defaultTabObj) {
            return $self->defaultTabObj->textViewObj->insertQuick(@args);
        } else {
            return undef;
        }
    }

    sub showImage {

        my ($self, @args) = @_;

        if ($self->defaultTabObj) {
            return $self->defaultTabObj->textViewObj->showImage(@args);
        } else {
            return undef;
        }
    }

    # Callbacks

    sub entryCallback {

        # Usually called by a ->signal_connect in GA::Strip::Entry->setEntrySignals or in
        #   GA::Table::Entry->setActivateEvent, when the user types something in the strip/table
        #   object's Gtk2::Entry and presses RETURN
        # This generic function just displays the typed text in the task window's default tab;
        #   other tasks can write their own ->entryCallback as required
        #
        # Expected arguments
        #   $obj        - The strip or table object whose Gtk2::Entry was used
        #   $entry      - The Gtk2::Entry itself
        #
        # Optional arguments
        #   $id         - A value passed to the table object that identifies the particular
        #                   Gtk2::Entry used (in case the table object uses multiple entries). By
        #                   default, $self->openWin sets $id to the same as $self->uniqueName;
        #                   could be an 'undef' value otherwise
        #   $text       - The text typed in the entry by the user (should not be 'undef')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $obj, $entry, $id, $text, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || ! defined $entry || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->entryCallback', @_);
        }

        if ($self->taskWinFlag && $self->defaultTabObj && $self->defaultTabObj->textViewObj) {

            $self->defaultTabObj->textViewObj->insertText($text, 'after');
        }

        return 1;
    }

    sub switchTabCallback {

        # Usually called GA::Table::Pane->respondVisibleTab whenever the visible tab in the task
        #   window changes
        # This generic function does nothing; other tasks can write their own ->switchTabCallback
        #   as required
        #
        # Expected arguments
        #   $paneObj    - The GA::Table::Pane object for the task window
        #   $tabObj     - The GA::Obj::Tab for the newly-visible tab
        #
        # Optional arguments
        #   $id         - A value passed by the pane object; for tasks, set to this task's ->name
        #                   (in general, might be 'undef')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $paneObj, $tabObj, $id, $check) = @_;

        # Check for improper arguments
        if (! defined $paneObj || ! defined $tabObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->switchTabCallback', @_);
        }

        # (This generic function does nothing)

        return 1;
    }

    sub closeTabCallback {

        # Usually called GA::Table::Pane->removeTab whenever a tab in the task window is manually
        #   closed by the user
        # This generic function simpy checks that the closed tab isn't the same one stored in
        #   $self->defaultTabObj, and resets that IV, if so
        #
        # Expected arguments
        #   $paneObj    - The GA::Table::Pane object for the task window
        #   $tabObj     - The GA::Obj::Tab for the closed tab
        #
        # Optional arguments
        #   $id         - A value passed by the pane object; for tasks, set to this task's ->name
        #                   (in general, might be 'undef')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $paneObj, $tabObj, $id, $check) = @_;

        # Check for improper arguments
        if (! defined $paneObj || ! defined $tabObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->closeTabCallback', @_);
        }

        if ($self->defaultTabObj && $self->defaultTabObj eq $tabObj) {

            $self->ivUndef('defaultTabObj');
        }

        return 1;
    }

    # Text-to-speech functions

    sub ttsReadAttrib {

        # Called by GA::Cmd::Read->do and PermRead->do
        # Users can use the client command ';read' to interact with individual tasks, typically
        #   getting them to read out information (e.g. the Status task can read out current health
        #   points)
        # The ';read' command is in the form ';read <attribute>' or ';read <attribute> <value>'.
        #   The ';read' command looks up the <attribute> in GA::Client->ttsAttribHash, which tells
        #   it which task to call
        # Tasks that don't use text-to-speech (TTS) will inherit this generic function. Tasks that
        #   do use TTS should include a modified form of this function that decides what to do
        #   with each <attribute>. If a <value> was also specified, the task can decide whether to
        #   use it, store it or ignore it
        #
        # Expected arguments
        #   $attrib     - The TTS attribute specified by the calling function. Must be one of the
        #                   keys in $self->ttsAttribHash
        #
        # Optional arguments
        #   $value      - The value specified by the calling function (or 'undef' if none was
        #                   specified)
        #   $noSpecialFlag
        #               - Set to TRUE when called by GA::Cmd::PermRead->do, in which case only
        #                   this task's hash of attributes is updated. If set to FALSE (or 'undef'),
        #                   something is usually read aloud, too
        #
        # Return values
        #   'undef' on improper arguments or if the $attrib doesn't exist in this task's
        #       ->ttsAttribHash
        #   1 otherwise

        my ($self, $attrib, $value, $noSpecialFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $attrib || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsReadAttrib', @_);
        }

        # TTS attributes are case-insensitive
        $attrib = lc($attrib);

        # Check that the specified attribute is actually used by this task (';read' or ';permread'
        #   should carry out this check, but better safe than sorry)
        if (! $self->ivExists('ttsAttribHash', $attrib)) {

            return undef;

        } elsif ($noSpecialFlag) {

            # When called by GA::Cmd::PermRead->do, don't read out anything, just update the hash
            #   of attributes (when appropriate)
            # This generic function doesn't update $self->ttsAttribHash, but other tasks'
            #   ->ttsReadAttrib should decide which attributes (if any) to update)

            # (no attributes require an update)

            return 1;

        } else {

            # The generic function doesn't have any TTS attributes, but other tasks' ->ttsReadAttrib
            #   functions should decide what to do here, and return 1

            # (no attributes require a response)

            return 1;
        }
    }

    sub ttsSwitchFlagAttrib {

        # Called by GA::Cmd::Switch->do and PermSwitch->do
        # Users can use the client command ';switch' to interact with individual tasks, typically
        #   telling them to turn on/off the automatic reading out of information (e.g. the Locator
        #   task can be told to start or stop reading out room titles as they are received from
        #   the world)
        # The ';switch' command is in the form ';switch <flag_attribute>'. The ';switch' command
        #   looks up the <flag_attribute> (which is a string, not a TRUE/FALSE value) in
        #   GA::Session->ttsFlagAttribHash, which tells it which task to call
        # Tasks that don't use text-to-speech (TTS) will inherit this generic function. Tasks that
        #   do use TTS can either inherit this generic function (if all they want to do is toggle
        #   the TRUE/FALSE values stored in a key-value pair in $self->ttsFlagAttribHash), or else
        #   they must include a modified form of this function that does something different
        #
        # Expected arguments
        #   $flagAttrib - The TTS flag attribute specified by the calling function. Must be one of
        #                   the keys in $self->ttsFlagAttribHash
        #
        # Optional arguments
        #   $noSpecialFlag
        #               - Set to TRUE when called by GA::Cmd::PermSwitch->do, in which case only
        #                   this task's hash of flag attributes is updated. Otherwise set to FALSE
        #                   (or 'undef'), in which case other things can happen when a flag
        #                   attribute is switched. For all built-in tasks, there is no difference
        #                   in behaviour
        #
        # Return values
        #   'undef' on improper arguments or if the $flagAttrib doesn't exist in this task's
        #       ->ttsFlagAttribHash
        #   Otherwise returns a confirmation message for the calling function to display

        my ($self, $flagAttrib, $noSpecialFlag, $check) = @_;

        # Local variables
        my $msg;

        # Check for improper arguments
        if (! defined $flagAttrib || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsSwitchFlagAttrib', @_);
        }

        # TTS flag attributes are case-insensitive
        $flagAttrib = lc($flagAttrib);

        # Check that the specified flag attribute is actually used by this task (';switch' or
        #   ';permswitch' should carry out this check, but better safe than sorry)
        if (! $self->ivExists('ttsFlagAttribHash', $flagAttrib)) {

            return undef;

        } else {

            # If a current task performs some kind of action, when a flag attribute is switched,
            #   the code for the action should be placed here. (Tasks in the global initial
            #   tasklist can't perform an action, of course.)
            if (! $noSpecialFlag) {

                # (no actions to perform)
            }

            # The generic task doesn't have any TTS flag attributes, but other tasks'
            #   ->ttsSwitchFlagAttrib functions should decide what to do here, and return a
            #   confirmation message
            # Usually, that means toggling the TRUE/FALSE values stored in $self->ttsFlagAttribHash
            $msg = '\'' . $self->prettyName . '\' flag attribute \'' . $flagAttrib
                            . '\' switched to ';

            if ($self->ivShow('ttsFlagAttribHash', $flagAttrib)) {

                $self->ivAdd('ttsFlagAttribHash', $flagAttrib, FALSE);
                $msg .= 'OFF';

            } else {

                $self->ivAdd('ttsFlagAttribHash', $flagAttrib, TRUE);
                $msg .= 'ON';
            }

            return $msg;
        }
    }

    sub ttsSetAlertAttrib {

        # Called by GA::Cmd::Alert->do and PermAlert->do
        # Users can use the client command ';alert' to interact with individual tasks, typically
        #   instructing them to read out information some time later (e.g. the Status task can read
        #   out an alert when health points drop below a certain level or recover to a certain
        #   level)
        # The ';alert' command is in the form ';alert <alert_attribute>' or
        #   ';alert <alert_attribute> <value>'. The ';alert' command looks up the <alert_attribute>
        #   in GA::Session->ttsAlertAttribHash, which tells it which task to call
        # Tasks that don't use text-to-speech (TTS) will inherit this generic function. Tasks that
        #   do use TTS should include a modified form of this function that decides what to do
        #   with each <alert_attribute>. If a <value> was also specified, the task can decide
        #   whether to use it, store it or ignore it
        #
        # Expected arguments
        #   $alertAttrib    - The TTS attribute specified by the calling function. Must be one of
        #                       the keys in $self->ttsAttribHash
        #
        # Optional arguments
        #   $value          - The value specified by the calling function (or 'undef' if none was
        #                       specified)
        #   $noSpecialFlag  - Set to TRUE when called by GA::Cmd::PermAlert->do, in which case only
        #                       this task's hash of alert attributes is updated. Otherwise set to
        #                       FALSE (or 'undef'), in which case other things can happen when an
        #                       alert is set. For all built-in tasks, there is no difference in
        #                       behaviour
        #
        # Return values
        #   'undef' on improper arguments or if the $attrib doesn't exist in this task's
        #       ->ttsAlertAttribHash
        #   Otherwise returns a confirmation message for the calling function to display

        my ($self, $alertAttrib, $value, $noSpecialFlag, $check) = @_;

        # Local variables
        my $msg;

        # Check for improper arguments
        if (! defined $alertAttrib || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsSetAlertAttrib', @_);
        }

        # TTS attributes are case-insensitive
        $alertAttrib = lc($alertAttrib);

        # Check that the specified attribute is actually used by this task (';alert' or ';permalert'
        #   should carry out this check, but better safe than sorry)
        if (! $self->ivExists('ttsAlertAttribHash', $alertAttrib)) {

            return undef;

        } else {

            # If a current task performs some kind of action, when an alert attribute is set, the
            #   code for the action should be placed here. (Tasks in the global initial tasklist
            #   can't perform an action, of course.)
            if (! $noSpecialFlag) {

                # (no actions to perform)
            }

            # The generic task doesn't have any TTS alert attributes, but other tasks'
            #   ->ttsSetAlertAttrib functions should decide what to do here, and return a
            #   confirmation message
            $msg = 'The generic task can\'t process alert attributes';

            return $msg;
        }
    }

    sub ttsQuick {

        # Perform a quick call to GA::Client->tts, using this task's TTS settings
        # By using this function, rather than calling GA::Client->tts directly, we can use one
        #   line of code, rather than several
        #
        # Expected arguments
        #   $text   - The text to read out
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsQuick', @_);
        }

        $axmud::CLIENT->tts(
            $text,                  # This varies...
            'task',                 # ...but these are always the same
            $self->ttsConfig,
            $self->session,
        );

        return 1;
    }

    # Misc functions

    sub getColourScheme {

        # Called by $self->openPaneWin and ->configureWin
        # Returns the name of the colour scheme that should be used in a tab in the task window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the default colour scheme for task windows
        #       ('custom') should be used
        #   Otherwise, returns the name of the colour scheme to use

        my ($self, $check) = @_;

        # Local variables
        my ($colourScheme, $name);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getColourScheme', @_);
        }

        if (
            $self->colourScheme
            && $axmud::CLIENT->ivExists('colourSchemeHash', $self->colourScheme)
        ) {
            return $self->colourScheme;

        } else {

            # If a colour scheme exists with the same name as this task, use it; otherwise use the
            #   default colour scheme for 'custom' windows (by leaving $colourScheme as 'undef')
            # For the convenience of the user, check for both 'locator_task' and 'locator'
            $name = $self->name;
            if ($axmud::CLIENT->ivExists('colourSchemeHash', $name)) {

                return $name;

            } else {

                $name =~ s/_task//;
                if ($axmud::CLIENT->ivExists('colourSchemeHash', $name)) {

                    return $name;
                }
            }
        }

        # Use the default colour scheme
        return undef;
    }

    sub returnParameterHash {

        # Can be called by anything
        # Returns all of the task's parameters and their values as a hash - thereby stripping all
        #   task settings and the IVs ->_objName, ->_objClass, ->_parentFile, ->_parentWorld and
        #   ->_privFlag - for any code that needs it
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise the hash of task parameters (might be empty if the task has no parameters)

        my ($self, $check) = @_;

        # Local variables
        my (
            @ivList,
            %taskHash, %emptyHash,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->returnParameterHash', @_);
            return %emptyHash;
        }

        # Compile a list of parameters to show. First import the list of IVs
        @ivList = $self->ivList();

        # Convert that list into a hash, preserving both the IV and its value
        foreach my $iv (@ivList) {

            $taskHash{$iv} = $self->{$iv};
        }

        # Remove all the task settings from %taskHash
        foreach my $iv ($axmud::CLIENT->ivKeys('constTaskSettingsHash')) {

            delete $taskHash{$iv};
        }

        # Remove the special IVs present in all Axmud Perl objects, leaving only IVs that are
        #   task parameters
        foreach my $iv ($axmud::CLIENT->ivKeys('constIVHash')) {

            delete $taskHash{$iv};
        }

        return %taskHash;
    }

    ##################
    # Accessors - set

    sub set_colourScheme {

        my ($self, $colourScheme, $check) = @_;

        # Local variables
        my $paneObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_colourScheme', @_);
        }

        $self->ivPoke('colourScheme', $colourScheme);       # Can be 'undef'

        if ($self->defaultTabObj && $self->defaultTabObj->paneObj) {

            $self->defaultTabObj->paneObj->applyColourScheme(undef, $self->colourScheme);
        }

        return 1;
    }

    sub set_defaultTabObj {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_defaultTabObj', @_);
        }

        $self->ivPoke('defaultTabObj', $obj);

        return 1;
    }

    sub set_endStatus {

        my ($self, $endStatus, $check) = @_;

        # Check for improper arguments
        if (! defined $endStatus || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_endStatus', @_);
        }

        $self->ivPoke('endStatus', $endStatus);

        return 1;
    }

    sub set_endTime {

        my ($self, $endTime, $check) = @_;

        # Check for improper arguments
        if (! defined $endTime || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_endTime', @_);
        }

        $self->ivPoke('endTime', $endTime);

        return 1;
    }

    sub set_hasResetFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_hasResetFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('hasResetFlag', TRUE);
        } else {
            $self->ivPoke('hasResetFlag', FALSE);
        }

        return 1;
    }

    sub set_resumeStatus {

        my ($self, $status, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_resumeStatus', @_);
        }

        if (defined $status) {

            if ($axmud::CLIENT->ivExists('constTaskStatusHash', $status)) {

                $self->ivPoke('resumeStatus', $status);

            } else {

                # Invalid status
                return undef;
            }

        } else {

            $self->ivUndef('resumeStatus');
        }

        return 1;
    }

    sub set_requireWinFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_requireWinFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('requireWinFlag', TRUE);
        } else {
            $self->ivPoke('requireWinFlag', FALSE);
        }

        return 1;
    }

    sub set_shutdownFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_status', @_);
        }

        if ($flag) {
            $self->ivPoke('shutdownFlag', TRUE);
        } else {
            $self->ivPoke('shutdownFlag', FALSE);
        }

        return 1;
    }

    sub set_stage {

        my ($self, $stage, $check) = @_;

        # Check for improper arguments
        if (! defined $stage || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_stage', @_);
        }

        $self->ivPoke('stage', $stage);

        return 1;
    }

    sub set_startTime {

        my ($self, $startTime, $check) = @_;

        # Check for improper arguments
        if (! defined $startTime || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_startTime', @_);
        }

        $self->ivPoke('startTime', $startTime);

        return 1;
    }

    sub set_startWithWinFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_startWithWinFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('startWithWinFlag', TRUE);
        } else {
            $self->ivPoke('startWithWinFlag', FALSE);
        }

        return 1;
    }

    sub set_status {

        my ($self, $status, $check) = @_;

        # Check for improper arguments
        if (! defined $status || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_status', @_);
        }

        if ($axmud::CLIENT->ivExists('constTaskStatusHash', $status)) {

            $self->ivPoke('status', $status);
        }


        return 1;
    }

    sub set_tableObj {

        my ($self, $tableObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tableObj', @_);
        }

        $self->ivPoke('tableObj', $tableObj);

        return 1;
    }

    sub set_taskWinEntryFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_taskWinEntryFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('taskWinEntryFlag', TRUE);
        } else {
            $self->ivPoke('taskWinEntryFlag', FALSE);
        }

        return 1;
    }

    sub set_taskWinFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_taskWinFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('taskWinFlag', TRUE);
        } else {
            $self->ivPoke('taskWinFlag', FALSE);
        }

        return 1;
    }

    sub set_ttsConfig {

        my ($self, $configuration, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_ttsConfig', @_);
        }

        $self->ivPoke('ttsConfig', $configuration);

        return 1;
    }

    sub set_ttsHash {

        my ($self, $taskObj, $check) = @_;

        # Check for improper arguments
        if (! defined $taskObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_ttsHash', @_);
        }

        $self->ivPoke('ttsAttribHash', $taskObj->ttsAttribHash);
        $self->ivPoke('ttsFlagAttribHash', $taskObj->ttsFlagAttribHash);
        $self->ivPoke('ttsAlertAttribHash', $taskObj->ttsAlertAttribHash);

        return 1;
    }

    sub set_waitForTask {

        my ($self, $waitForTask, $check) = @_;

        # Check for improper arguments
        if (! defined $waitForTask || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_waitForTask', @_);
        }

        $self->ivPoke('waitForTask', $waitForTask);

        return 1;
    }

    sub set_winObj {

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_winObj', @_);
        }

        $self->ivPoke('winObj', $winObj);

        return 1;
    }

    sub del_winObj {

        # Called by GA::Win::Generic->winDestroy

        my ($self, $winObj, $check) = @_;

        # Local variables
        my $stripObj;

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_winObj', @_);
        }

        # Do nothing if the task already knows the window is closed, or if the task is shutting down
        #   anyway
        if ($self->winObj && $self->winObj eq $winObj && ! $self->shutdownFlag) {

            # Mark the window as closed
            $self->ivUndef('winObj');
            $self->ivPoke('taskWinFlag', FALSE);
            $self->ivPoke('taskWinEntryFlag', FALSE);
            $self->ivUndef('defaultTabObj');

            # For pseudo-windows, this function should probably not be called; nevertheless, if the
            #   parent table object is still open, close it
            if ($winObj->pseudoWinTableObj) {

                $stripObj = $winObj->pseudoWinTableObj->stripObj;
                if ($stripObj->ivExists('tableObjHash', $winObj->pseudoWinTableObj->number)) {

                    $stripObj->removeTableObj($winObj->pseudoWinTableObj);
                }
            }

            if ($self->requireWinFlag) {

                # The task should shut down when its window is closed
                $self->ivPoke('shutdownFlag', TRUE);
                $self->writeText(
                    'Window for \'' . $self->prettyName . '\' task closed (task will also halt)',
                );

            } else {

                # The task can continue without a window
                $self->writeText(
                    'Window for \'' . $self->prettyName . '\' task closed (task will continue)',
                );
            }
        }

        return 1;
    }

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }

    sub name
        { $_[0]->{name} }

    sub prettyName
        { $_[0]->{prettyName} }
    sub uniqueName
        { $_[0]->{uniqueName} }
    sub shortName
        { $_[0]->{shortName} }
    sub customName
        { $_[0]->{customName} }

    sub category
        { $_[0]->{category} }
    sub descrip
        { $_[0]->{descrip} }
    sub taskType
        { $_[0]->{taskType} }
    sub profName
        { $_[0]->{profName} }
    sub profCategory
        { $_[0]->{profCategory} }
    sub shortCutIV
        { $_[0]->{shortCutIV} }

    sub jealousyFlag
        { $_[0]->{jealousyFlag} }
    sub requireLocatorFlag
        { $_[0]->{requireLocatorFlag} }
    sub profSensitivityFlag
        { $_[0]->{profSensitivityFlag} }
    sub storableFlag
        { $_[0]->{storableFlag} }

    sub startTime
        { $_[0]->{startTime} }
    sub checkTime
        { $_[0]->{checkTime} }
    sub endStatus
        { $_[0]->{endStatus} }
    sub endTime
        { $_[0]->{endTime} }
    sub waitForTask
        { $_[0]->{waitForTask} }
    sub delayTime
        { $_[0]->{delayTime} }

    sub shutdownFlag
        { $_[0]->{shutdownFlag} }
    sub hasResetFlag
        { $_[0]->{hasResetFlag} }
    sub status
        { $_[0]->{status} }
    sub resumeStatus
        { $_[0]->{resumeStatus} }
    sub activeFlag
        { $_[0]->{activeFlag} }
    sub stage
        { $_[0]->{stage} }

    sub allowWinFlag
        { $_[0]->{allowWinFlag} }
    sub requireWinFlag
        { $_[0]->{requireWinFlag} }
    sub startWithWinFlag
        { $_[0]->{startWithWinFlag} }
    sub winPreferList
        { my $self = shift; return @{$self->{winPreferList}}; }
    sub winObj
        { $_[0]->{winObj} }
    sub tableObj
        { $_[0]->{tableObj} }
    sub taskWinFlag
        { $_[0]->{taskWinFlag} }
    sub taskWinEntryFlag
        { $_[0]->{taskWinEntryFlag} }
    sub winmap
        { $_[0]->{winmap} }
    sub winUpdateFunc
        { $_[0]->{winUpdateFunc} }
    sub defaultTabObj
        { $_[0]->{defaultTabObj} }
    sub tabMode
        { $_[0]->{tabMode} }
    sub monochromeFlag
        { $_[0]->{monochromeFlag} }
    sub colourScheme
        { $_[0]->{colourScheme} }
    sub noScrollFlag
        { $_[0]->{noScrollFlag} }

    sub ttsFlag
        { $_[0]->{ttsFlag} }
    sub ttsConfig
        { $_[0]->{ttsConfig} }
    sub ttsAttribHash
        { my $self = shift; return %{$self->{ttsAttribHash}}; }
    sub ttsFlagAttribHash
        { my $self = shift; return %{$self->{ttsFlagAttribHash}}; }
    sub ttsAlertAttribHash
        { my $self = shift; return %{$self->{ttsAlertAttribHash}}; }
}

{ package Games::Axmud::Generic::Win;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

#   sub new {}                  # Defined in window objects which inherit this one

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}             # Defined in window objects which inherit this one

#   sub winEnable {}            # Defined in window objects which inherit this one

#   sub winDisengage {}         # Defined in window objects which inherit this one

#   sub winDestroy {}           # Defined in window objects which inherit this one

    sub winShowAll {

        # Generic function to update the window itself to make any changes visible
        # If some code has called $self->setInvisible, then nothing happens (and the window
        #   remains invisible)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $string    - For debugging purposes. Describes the calling function, e.g.
        #                   ->winShowAll($self->_objClass . '->callingFunction');
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $string, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winShowAll', @_);
        }

        if ($self->winWidget && $self->visibleFlag) {

            $self->winWidget->show_all();

            # Optionally, write information about the calling function to the terminal (for
            #   debugging)
#           if ($string) {
#
#               print "->winShowAll() call from " . $string . " at " . $axmud::CLIENT->getTime()
#                       . "\n";
#
#           } else {
#
#               print "->winShowAll() call from unspecified function at "
#                       . $axmud::CLIENT->getTime() . "\n";
#           }
        }

        return 1;
    }

    sub drawWidgets {

        # Generic function to draw widgets within the window, usually called by $self->winSetup or
        #   $self->winEnable
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # (Do nothing)

        return 1;
    }

    sub redrawWidgets {

        # Generic function to redraw widgets within the window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->redrawWidgets', @_);
        }

        # (Do nothing)

        return 1;
    }

    # ->signal_connects

    # Other functions

    sub setTitle {

        # Can be called by anything
        # Sets the text on this window's title bar
        #
        # Expected arguments
        #   $title  - The string to use as the window's title
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $title, $check) = @_;

        # Check for improper arguments
        if (! defined $title || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setTitle', @_);
        }

        # (Don't use this function to set titles for pseudo-windows)
        if ($self->winWidget eq $self->winBox) {

            $self->winWidget->set_title($title);
        }

        return 1;
    }

    sub getTitle {

        # Can be called by anything
        # Gets the text on this window's title bar
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the title bar text

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->getTitle', @_);
        }

        return $self->winWidget->get_title();

        return 1;
    }

    sub setUrgent {

        # Sets this window's urgency hint
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag   - If set to TRUE, this window's urgency hint is only set, if Gtk2 reports that
        #               it is not currently set. If set to FALSE (or 'undef'), this function sets
        #               the window's urgency hint regardless
        #
        # Return values
        #   'undef' on improper arguments or if the window's urgency hint is not set
        #   1 if the window's urgency hint is set

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setUrgent', @_);
        }

        if (
            $self->winWidget eq $self->winBox
            && (! $flag || ! $self->winWidget->get_urgency_hint())
        ) {
            $self->winWidget->set_urgency_hint(TRUE);

            return 1;

        } else {

            # Hint not set
            return undef;
        }
    }

    sub resetUrgent {

        # Resets this window's urgency hint
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag   - If set to TRUE, this window's urgency hint is only reset, if Gtk2 reports that
        #               it is currently set. If set to FALSE (or 'undef'), this function resets
        #               the window's urgency hint regardless
        #
        # Return values
        #   'undef' on improper arguments or if the window's urgency hint is not reset
        #   1 if the window's urgency hint is reset

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->resetUrgent', @_);
        }

        if (
            $self->winWidget eq $self->winBox
            && (! $flag || $self->winWidget->get_urgency_hint())
        ) {
            $self->winWidget->set_urgency_hint(FALSE);
            # The line above doesn't work (in Linux Mint with Cinnamon), so we'll do it the brutal
            #   way, too
            $self->restoreFocus();
            if ($self->session) {

                $self->session->mainWin->restoreFocus();
            }

            return 1;

        } else {

            # Hint not reset
            return undef;
        }
    }

    sub restoreFocus {

        # Can be called by any function (often after creating a 'dialogue' window or after
        #   re-stacking 'grid' windows)
        # Activates this window object's Gtk2::Window, if it is known. For 'internal' windows,
        #   returns the focus to the entry box in the 'Games::Axmud::Strip::Entry' strip object, if
        #   there is one
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or $self->winWidget is not set
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $stripObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restoreFocus', @_);
        }

        # Activate the Gtk2::Window, if it is known (for pseudo-windows, activate the parent window)
        if (! $self->winWidget) {

            return undef;

        } else {

            $self->winWidget->present();
        }

        # For 'internal' windows, returns the focus to the entry box in the
        #   'Games::Axmud::Strip::Entry' strip object, if there is one
        if (
            $self->winType eq 'main'
            || $self->winType eq 'protocol'
            || $self->winType eq 'custom'
        ) {
            $stripObj = $self->ivShow('firstStripHash', 'Games::Axmud::Strip::Entry');
            if ($stripObj) {

                $stripObj->entry->grab_focus();
            }
        }

        return 1;
    }

    sub setVisible {

        # Can be called by any function
        # Makes the Gtk2::Window itself visible, and sets a flag so that calls to $self->winShowAll
        #   are carried out
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or $self->winWidget is not set
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setVisible', @_);
        }

        if (! $self->winWidget) {

            return undef;

        } else {

            $self->winWidget->set_visible(TRUE);
            $self->ivPoke('visibleFlag', TRUE);

            return 1;
        }
    }

    sub setInvisible {

        # Can be called by any function
        # Makes the Gtk2::Window itself invisible, and sets a flag so that calls to
        #   $self->winShowAll are ignored until the window is made visible again (via a call to
        #   $self->setVisible)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or $self->winWidget is not set
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setInvisible', @_);
        }

        if (! $self->winWidget) {

            return undef;

        } else {

            $self->winWidget->set_visible(FALSE);
            $self->ivPoke('visibleFlag', FALSE);

            return 1;
        }
    }

    sub getBorder {

        # Can be called by anything except 'dialogue' window code, which accesses this function
        #   throught its parent 'grid' or 'free' window
        # Gets the correct border size for this window type
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the spacing size in pixels

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getBorder', @_);
        }

        if ($self->winCategory eq 'free') {
            return $axmud::CLIENT->constFreeBorderPixels;
        } elsif ($self->winType eq 'main') {
            return $axmud::CLIENT->constMainBorderPixels;
        } else {
            return $axmud::CLIENT->constGridBorderPixels;
        }
    }

    sub getSpacing {

        # Can be called by anything except 'dialogue' window code, which accesses this function
        #   throught its parent 'grid' or 'free' window
        # Gets the correct spacing size for this window type
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the spacing size in pixels

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getSpacing', @_);
        }

        if ($self->winCategory eq 'free') {
            return $axmud::CLIENT->constFreeSpacingPixels;
        } elsif ($self->winType eq 'main') {
            return $axmud::CLIENT->constMainSpacingPixels;
        } else {
            return $axmud::CLIENT->constGridSpacingPixels;
        }
    }

    # 'free' windows

    sub createFreeWin {

        # All 'free' windows must have an owner, and the owner must be another window object (which
        #   can be a 'grid' or a 'free' window object)
        # 'dialogue' windows should be created via a call to one of the functions in this generic
        #   window object (e.g. $self->showMsgDialogue, $self->showComboDialogue, etc)
        # All other types of 'free' window should be created via a call to $self->createFreeWin or
        #   $self->quickFreeWin
        #
        # Expected arguments
        #   $packageName    - The Perl object for the child 'free' window
        #
        # Optional arguments
        #   $owner          - The owner. A 'grid' window object (but not an 'external' window) or a
        #                       'free' window object (but not any other kind of object). If 'undef',
        #                       then this window object is the owner
        #   $session        - The GA::Session from which this function was called. If 'undef',
        #                       the new window's ->session is the same as $owner's session (which
        #                       might be 'undef', too)
        #   $title          - A string to use as the child window's title. If 'undef', a generic
        #                       title is used
        #   $editObj        - The object to be edited in the child window (for 'edit' windows only;
        #                       should be 'undef' for other types of 'free' window)
        #   $tempFlag       - Flag set to TRUE if $editObj is either temporary, or has not yet been
        #                       added to any registry (usually because the user needs to name it
        #                       first). Set to FALSE (or 'undef') otherwise. Ignored if $editObj is
        #                       not specified
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'free' window; for example, for example,
        #                       GA::PrefWin::TaskStart uses it to specify a task name and type.
        #                       Set to an empty hash if not required
        #
        # Return values
        #   'undef' on improper arguments or if the child 'free' window can't be created
        #   Otherwise returns the blessed reference to the child window

        my ($self, $packageName, $owner, $session, $title, $editObj, $tempFlag, %configHash) = @_;

        # Local variables
        my ($pluginName, $pluginObj, $class, $winObj);

        # Check for improper arguments
        if (! defined $packageName) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createFreeWin', @_);
        }

        # All windows except 'external' and 'dialogue' windows can have a child 'free' window
        if ($self->winType eq 'external' || $self->winType eq 'dialogue') {

            return undef;
        }

        # If the window package was added by a plugin and the plugin is disabled, don't create the
        #   window
        $pluginName = $axmud::CLIENT->ivShow('pluginFreeWinHash', $packageName);
        if ($pluginName) {

            $pluginObj = $axmud::CLIENT->ivShow('pluginHash', $pluginName);
            if ($pluginObj && ! $pluginObj->enabledFlag) {

                return undef;
            }
        }

        # If no owner is specified, it's this window
        if (! $owner) {

            $owner = $self;

        # If an owner is specified, it must be a window object (inheriting from GA::Generic::Win)
        } elsif (! $owner->isa('Games::Axmud::Generic::Win')) {

            return undef;
        }

        # If no session is specified, it's the owner's session
        if (! $session) {

            $session = $owner->session;
        }

        # Create the 'free' window object
        $winObj = $packageName->new(
            $axmud::CLIENT->desktopObj->freeWinCount,
            $self->workspaceObj,
            $owner,
            $session,
            $title,
            $editObj,
            $tempFlag,
            %configHash,
        );

        # Check it's any 'free' window besides a 'dialogue' window
        if (! $winObj || $winObj->winCategory ne 'free' || $winObj->winType eq 'dialogue') {

            return undef;
        }

        # Make the window visible
        if (! $winObj->winSetup()) {

            return undef;
        }

        if (! $winObj->winEnable()) {

            return undef;
        }

        # Update IVs
        $axmud::CLIENT->desktopObj->add_freeWin($winObj);
        $self->add_childFreeWin($winObj);

        return $winObj;
    }

    sub quickFreeWin {

        # Shortcut to $self->createFreeWin, allowing the calling code to specify only the bare
        #   minimum of arguments
        #
        # Expected arguments
        #   $packageName    - The Perl object for the child 'free' window
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. If 'undef',
        #                       the new window's ->session is the same as this window's session
        #                       (which might be 'undef', too)
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'free' window; for example, for example,
        #                       GA::PrefWin::TaskStart uses it to specify a task name and type.
        #                       Set to an empty hash if not required
        #
        # Return values
        #   'undef' on improper arguments or if the child 'free' window can't be created
        #   Otherwise returns the blessed reference to the child window

        my ($self, $packageName, $session, %configHash) = @_;

        # Check for improper arguments
        if (! defined $packageName) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->quickFreeWin', @_);
        }

        return $self->createFreeWin(
            $packageName,       # Compulsory
            undef,
            $session,           # May be 'undef'
            undef,
            undef,
            undef,
            %configHash,
        );
    }

    # 'dialogue' windows

    sub closeDialogueWin {

        # Can be called by anything to close a 'dialogue' window early (especially one that won't
        #   close itself)
        # For example, called by GA::Client->start and GA::Session->setupProfiles after an earlier
        #   call to the 'dialogue' window created by $self->showBusyWin
        #
        # Expected arguments
        #   $dialogueWin    - The 'dialogue' window to close
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $dialogueWin, $check) = @_;

        # Check for improper arguments
        if (! defined $dialogueWin || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->closeDialogueWin', @_);
        }

        # Close the window
        $dialogueWin->destroy();

        # For a 'dialogue' window created by $self->showBusyWin, we need to update a GA::Client IV
        if ($axmud::CLIENT->busyWin && $axmud::CLIENT->busyWin eq $dialogueWin) {

            $axmud::CLIENT->set_busyWin();
        }

        return 1;
    }

    sub addDialogueIcon {

        # Called by many of the following functions that open some kind of Gtk2::Dialogue
        # Takes the 'dialogue' window's main Gtk2::VBox, and splits it (using a Gtk2::HBox) into
        #   two, with a standard icon on the left, and a new Gtk2::VBox on the right
        # Makes a simple 'dialogue' window look a lot nicer (see $self->showEntryDialogue for an
        #   example of how it works)
        #
        # Expected arguments
        #   $vBox   - The 'dialogue' window's main Gtk2::VBox
        #
        # Optional arguments
        #   $path   - Full filepath to an image file to use; if 'undef' or the file doesn't exist,
        #               the standard icon is used
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the new VBox, contained within the existing main one

        my ($self, $vBox, $path, $check) = @_;

        # Local variables
        my $spacing;

        # Check for improper arguments
        if (! defined $vBox || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDialogueIcon', @_);
        }

        # Set the correct spacing size for 'dialogue' windows
        $spacing = $axmud::CLIENT->constFreeSpacingPixels;

        # Draw widgets
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $vBox->pack_start($hBox, TRUE, TRUE, 0);

        my $vBox2 = Gtk2::VBox->new(FALSE, 0);
        $hBox->pack_start($vBox2, TRUE, TRUE, $spacing);

        my $vBox3 = Gtk2::VBox->new(FALSE, 0);
        $hBox->pack_start($vBox3, TRUE, TRUE, $spacing);

        my $frame = Gtk2::Frame->new(undef);
        $vBox2->pack_start($frame, FALSE, FALSE, $spacing);
        $frame->set_size_request(64, 64);
        $frame->set_shadow_type('etched-in');

        if (! $path || ! -e $path) {

            $path = $axmud::CLIENT->getDialogueIcon();
        }

        my $image = Gtk2::Image->new_from_file($path);
        $frame->add($image);

        return $vBox3;
    }

    sub showMsgDialogue {

        # Can be called by any function
        # Creates a standard Gtk2::MessageDialog and returns the response (if any)
        #
        # Expected arguments
        #   $title          - The title to display, e.g. 'File Save'
        #   $icon           - 'info', 'warning', 'error', 'question'
        #   $text           - The message to display. Can be pango markup text, or just plain text
        #   $buttonType     - 'none', 'ok', 'close', 'cancel', 'yes-no', 'ok-cancel'
        #
        # Optional arguments
        #   $defaultResponse
        #                   - If defined, the default button ('yes', 'no', etc)
        #
        # Return values
        #   'undef' on improper arguments, or if unrecognised values for $icon and/or $buttonType
        #       are specified
        #   Otherwise returns the user response (e.g. returns 'yes' if the user clicks on the 'yes'
        #       button)

        my ($self, $title, $icon, $text, $buttonType, $defaultResponse, $check) = @_;

        # Local variables
        my (
            $response,
            @list,
            %buttonHash,
        );

        # Check for improper arguments
        if (
            ! defined $title || ! defined $icon || ! defined $text || ! defined $buttonType
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->showMsgDialogue', @_);
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Check that $icon and $buttonType are valid values
        if (
            $icon ne 'info' && $icon ne 'warning' && $icon ne 'error' && $icon ne 'question'
        ) {
            return $axmud::CLIENT->writeError(
                'Unrecognised value \'' . $icon . '\' for icon argument',
                $self->_objClass . '->showMsgDialogue',
            );

        } elsif (
            $buttonType ne 'none' && $buttonType ne 'ok' && $buttonType ne 'close'
            && $buttonType ne 'cancel' && $buttonType ne 'yes-no' && $buttonType ne 'ok-cancel'
        ) {
            return $axmud::CLIENT->writeError(
                'Unrecognised value \'' . $icon . '\' for button type argument',
                $self->_objClass . '->showMsgDialogue',
            );
        }

        # Show the 'dialogue' window
        my $dialogueWin = Gtk2::MessageDialog->new_with_markup(
            $self->winWidget,
            [qw/destroy-with-parent/],
            $icon,
            $buttonType,
            Glib::Markup::escape_text($text),   # In case $text contains < or > characters, etc
        );

        # For the benefit of visually-impaired users who are using the 'tab' key to switch buttons,
        #   don't allow the label to receive focus
        foreach my $label ($dialogueWin->get_message_area->get_children()) {

            $label->can_focus(FALSE);
        }

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_title($title);
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        if (defined $defaultResponse) {

            $dialogueWin->set_default_response($defaultResponse);
        }

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            # (In case TTS is being used and another 'dialogue' window is about to open, make sure
            #   the window is visibly closed)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showMsgDialogue');
        });

        # Display the 'dialogue' window. Without this combination of Gtk calls, the window is not
        #   consistently active (don't know why this works; it just does)
        $dialogueWin->show_all();
        $dialogueWin->present();
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showComboDialogue');

        # Prepare text-to-speech (TTS) code. Get a hash of possible response buttons, in the form
        #   $buttonHash{'response'} = Gtk2::Button (if the button is used), or 'undef' (if not)
        %buttonHash = (
            'ok', $dialogueWin->get_widget_for_response('ok'),
            'close', $dialogueWin->get_widget_for_response('close'),
            'cancel', $dialogueWin->get_widget_for_response('cancel'),
            'yes', $dialogueWin->get_widget_for_response('yes'),
            'no', $dialogueWin->get_widget_for_response('no'),
        );

        if ($axmud::CLIENT->systemAllowTTSFlag && $axmud::CLIENT->ttsDialogueFlag) {

            $axmud::CLIENT->tts($title, 'dialogue', 'dialogue', undef);
            $axmud::CLIENT->tts($text, 'dialogue', 'dialogue', undef);

            foreach my $response (keys %buttonHash) {

                my $button = $buttonHash{$response};

                if (defined $button) {

                    # Handy of responses that are available in this dialogue
                    push (@list, 'button ' . $response);

                    $button->signal_connect('grab-focus' => sub {

                        my $label = $button->get_label();

                        # $label is in the form 'gtk-yes', 'gtk-no' etc
                        $axmud::CLIENT->tts(
                            'Button: ' . substr($label, 4),
                            'dialogue',
                            'dialogue',
                            undef,
                        );
                    });
                }
            }

            # (No need to read this message, if there's only one button)
            if (scalar @list > 1) {

                $axmud::CLIENT->tts(
                    'Select ' . join (', or, ', @list),
                    'dialogue',
                    'dialogue',
                    undef,
                );
            }
        }
        # (end of TTS code)

        # Get the response
        $response = $dialogueWin->run();

        # Destroy the window and return the response
        $dialogueWin->destroy();
        $self->restoreFocus();

        # (In case TTS is being used and another 'dialogue' window is about to open, make sure the
        #   window is visibly closed)
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showMsgDialogue');

        # Use TTS to announce the decision, if TTS enabled
        if ($axmud::CLIENT->systemAllowTTSFlag && $axmud::CLIENT->ttsDialogueFlag) {

            if ($response && exists $buttonHash{$response}) {

                $axmud::CLIENT->tts(
                    'Selected button: ' . $response,
                    'dialogue',
                    'dialogue',
                    undef,
                );

            } else {

                # $response is 'undef' or 'delete-event'
                $axmud::CLIENT->tts(
                    'Cancelled',
                    'dialogue',
                    'dialogue',
                    undef,
                );
            }
        }

        return $response;
    }

    sub showKeycodeDialogue {

        # Called by GA::Cmd::GetKeycode->do
        # Allows the user to test system keycodes, and store them in the current keycode object (if
        #   desired)
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #
        # Return values
        #   'undef' on improper arguments, if the user closes the 'dialogue' window or if no changes
        #       to the current keycode object are made
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $spacing, $keycodeObj, $response, $keycode,
            %addHash, %replaceHash,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showKeycodeDialogue', @_);
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Set the correct spacing size for 'dialogue' windows
        $spacing = $axmud::CLIENT->constFreeSpacingPixels;
        # Import the current keycode object (for convenience)
        $keycodeObj = $axmud::CLIENT->currentKeycodeObj;

        # Show the 'dialogue' window
        my $dialogueWin = Gtk2::Dialog->new(
            'Get keycodes',
            $self->winWidget,
            [qw/modal destroy-with-parent/],
            'gtk-cancel' => 'reject',
            'gtk-ok'     => 'accept',
        );

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        # 'Dialogue' window signals
        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            # Return 'undef' to show no changes were made to the current keycode object
            return undef;
        });

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        my $table = Gtk2::Table->new(5, 3, FALSE);
        $vBox2->pack_start($table, 0, 0, $spacing);
        $table->set_row_spacings($spacing);

        my $label = Gtk2::Label->new;
        $table->attach_defaults($label, 0, 3, 0, 1);
        $label->set_alignment(0, 0);
        $label->set_markup("<i>Press any key to get a system keycode</i>");

        my $label2 = Gtk2::Label->new;
        $table->attach_defaults($label2, 0, 3, 1, 2);
        $label2->set_alignment(0.5, 0);     # Centred

        my $label3 = Gtk2::Label->new;
        $table->attach_defaults($label3, 0, 3, 2, 3);
        $label3->set_alignment(0, 0);
        $label3->set_markup(
            "<i>(Optional) Select the equivalent " . $axmud::SCRIPT . " keycode and click\n"
            . "'Add' / 'Replace' to update the current keycode object</i>",
        );

        my $comboBox = Gtk2::ComboBox->new_text();
        $table->attach_defaults($comboBox, 0, 1, 3, 4);
        # Fill the combobox with standard keycodes
        foreach my $item ($axmud::CLIENT->constKeycodeList) {

            $comboBox->append_text($item);
        }
        $comboBox->set_active(FALSE);     # Make firstcode visible
        $comboBox->set_sensitive(FALSE);  # Combo starts insensitive

        my $button = Gtk2::Button->new('Add');
        $table->attach_defaults($button, 1, 2, 3, 4);
        $button->set_sensitive(FALSE);    # Button starts insensitive

        my $button2 = Gtk2::Button->new('Replace');
        $table->attach_defaults($button2, 2, 3, 3, 4);
        $button2->set_sensitive(FALSE);   # Button starts insensitive

        my $label4 = Gtk2::Label->new;
        $table->attach_defaults($label4, 0, 3, 4, 5);
        $label4->set_alignment(0, 0);
        $label4->set_markup("<i>(No changes made yet)</i>");

        # Signal connects
        $dialogueWin->signal_connect('key-press-event' => sub {

            my ($widget, $event) = @_;

            $keycode = Gtk2::Gdk->keyval_name($event->keyval);
            $label2->set_markup("<b>$keycode</b>");

            # Make the combobox and the 'Add'/'Replace' buttons clickable
            $comboBox->set_sensitive(TRUE);
            $button->set_sensitive(TRUE);
            $button2->set_sensitive(TRUE);
        });

        $button->signal_connect('clicked' => sub {

            # 'Add' button
            my $standard = $comboBox->get_active_text();

            $addHash{$standard} = $keycode;

            # Add text to the bottom label
            $label4->set_markup("<i>Click 'Cancel' to discard changes, or 'OK' to keep them</i>");
        });

        $button2->signal_connect('clicked' => sub {

            # 'Replace' button
            my $standard = $comboBox->get_active_text();

            $replaceHash{$standard} = $keycode;

            # Add text to the bottom label
            $label4->set_markup("<i>Click 'Cancel' to discard changes, or 'OK' to keep them</i>");
        });

        # Display the dialogue
        $vBox->show_all();

        # If the user clicked 'cancel', $response will be 'reject'
        # Otherwise, user clicked 'ok', and we might have to modify the current keycode object
        $response = $dialogueWin->run();
        if ($response eq 'accept' && (%addHash || %replaceHash)) {

            # Apply changes from the 'Replace' button
            foreach my $standard (keys %replaceHash) {

                my $keycode = $replaceHash{$standard};

                # Replace the existing system keycode
                $keycodeObj->setValue($session, $standard, $keycode);
                # We ignore the same keycode modified with the 'Add' button
                if (exists $addHash{$standard}) {

                    delete $addHash{$standard};
                }
            }

            # Apply changes from the 'Add' button
            foreach my $standard (keys %addHash) {

                my ($keycode, $already);

                $keycode = $addHash{$standard};

                # Add another system keycode to those already stored
                $already = $keycodeObj->getKeycode($standard);
                $keycodeObj->setValue($session, $standard, $already . ' ' . $keycode);
            }

            $dialogueWin->destroy();
            $self->restoreFocus();

            # Return 1 to show changes were made to the current keycode object
            return 1;

        } else {

            $dialogueWin->destroy();
            $self->restoreFocus();

            # Return 'undef' to show no changes were made to the current keycode object
            return undef;
        }
    }

    sub showFileChooser {

        # Can be called by any function
        # Creates a standard Gtk2::FileChooserDialog and returns the response (if any)
        #
        # Expected arguments
        #   $title          - The title of the window, e.g. 'Select file to load'
        #   $type           - 'open', 'save', 'select-folder', 'create-folder'
        #
        # Optional arguments
        #   $arg            - If $type = 'open', set the current folder (this behaviour is
        #                       discouraged, but it's sometimes appropriate for Axmud code). If
        #                       $type = 'save', suggest a filename using $arg. Ignored if 'undef' or
        #                       if $type is not 'open' or 'save'
        #
        # Return values
        #   'undef' on improper arguments, if $type is invalid, if the file chooser window can't be
        #       opened or if no file is selected
        #   Otherwise returns a path to the selected file

        my ($self, $title, $type, $arg, $check) = @_;

        # Local variables
        my $fileName;

        # Check for improper arguments
        if (! defined $title || ! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showFileChooser', @_);
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Check that $type is a valid type
        if (
            $type ne 'open' && $type ne 'save' && $type ne 'select-folder'
            && $type ne 'create-folder'
        ) {
            return $self->writeError(
                'Unrecognised file choose type \'' . $type . '\'',
                $self->_objClass . '->showFileChooser',
            );
        }

        # Open the file chooser window
        my $dialogueWin = Gtk2::FileChooserDialog->new(
            $title,
            $self->winWidget,
            $type,
            'gtk-cancel' => 'cancel',
            'gtk-ok' => 'ok'
        );

        if (! $dialogueWin) {

            return undef;
        }

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();
        });

        if (defined $arg) {

            # If loading a file, set the current folder
            if ($type eq 'open') {

                $dialogueWin->set_current_folder($arg);

            # If saving a file, suggest a filename
            } elsif ($type eq 'save' && defined $arg) {

                $dialogueWin->set_current_name($arg);
            }
        }

        # Get the file
        if ($dialogueWin->run eq 'ok') {

            $fileName = $dialogueWin->get_filename();
        }

        # Close the window
        $dialogueWin->destroy();
        $self->restoreFocus();

        # For saving, show a confirmation message
        if (defined $fileName){

            if (-f $fileName && $type eq 'save') {

                my $choice = $self->showMsgDialogue(
                    'Replace existing file',
                    'question',
                    'Overwrite existing file ' . $fileName . ' ?',
                    'yes-no',
                );

                # If the user selects 'no', return false
                if ($choice eq 'no') {

                    return undef;
                }
            }

            # Return the path of the selected file
            return $fileName;

        } else {

            # No file selected
            return undef;
        }
    }

    sub showEntryDialogue {

        # Can be called by any function
        # Prompts the user to enter some text into the entry box; returns the response if the 'ok'
        #   button is pressed, but 'undef' if either the cancel button is pressed or the window is
        #   closed
        #
        # Expected arguments
        #   $title          - The title to display, e.g. 'File Save'
        #   $text           - The message to display. Can be pango markup text, or just plain text
        #
        # Optional arguments
        #   $maxChars       - The maximum number of chars allowed in the entry box (if 'undef', no
        #                       maximum)
        #   $entryText      - The initial text to put in the entry box (if 'undef', no initial text)
        #   $obscureMode    - If set to TRUE, text in the entry box is obscured. If set to FALSE (or
        #                       'undef'), text is visible
        #   $bareFlag       - The value of $text is normally modified to remove any '<' and '>'
        #                       characters which might cause a pango error. If this flag is set to
        #                       TRUE, they are not removed, on the understanding that the calling
        #                       function wants to display bold/italics tags (<b> and </i>, etc). If
        #                       set to FALSE (or 'undef'), the '<' and '>' characters are removed as
        #                       normal
        #   $singleFlag     - Set when called by GA::CLIENT->connectBlind (or by any other code that
        #                       might want to remove the 'Cancel' button). If TRUE, only an 'OK'
        #                       button is used. If FALSE (or 'undef'), both an 'OK' and 'Cancel'
        #                       buttons are used
        #
        # Return values
        #   'undef' on improper arguments or if the user doesn't enter some text
        #   Otherwise returns the user response (the contents of the entry box)

        my (
            $self, $title, $text, $maxChars, $entryText, $obscureMode, $bareFlag,
            $singleFlag, $check,
        ) = @_;

        # Local variables
        my (
            $spacing, $starText, $lastThing, $response, $responseText, $confirmMsg,
            %buttonHash,
        );

        # Check for improper arguments
        if (! defined $title || ! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showEntryDialogue', @_);
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Set the correct spacing size for 'dialogue' windows
        $spacing = $axmud::CLIENT->constFreeSpacingPixels;

        # Show the dialogue window
        my $dialogueWin;
        if ($singleFlag) {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-ok'     => 'accept',
            );

        } else {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-cancel' => 'reject',
                'gtk-ok'     => 'accept',
            );
        }

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            # (In case TTS is being used and another 'dialogue' window is about to open, make sure
            #   the window is visibly closed)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showEntryDialogue');
        });

        # For the benefit of Pango, replace any diamond bracket (< or >) characters with normal
        #   brackets
        if (! $bareFlag) {

            $text =~ s/\</(/g;
            $text =~ s/\>/)/g;
        }

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        my $label = Gtk2::Label->new();
        $vBox2->pack_start($label, FALSE, FALSE, $spacing);
        $label->set_alignment(0, 0);
        $label->set_markup($text);

        my $entry;
        if (defined $maxChars && $axmud::CLIENT->intCheck($maxChars, 1)) {
            $entry = Gtk2::Entry->new_with_max_length($maxChars);
        } else {
            $entry = Gtk2::Entry->new();
        }
        $vBox2->pack_start($entry, FALSE, FALSE, $spacing);

        if ($obscureMode) {

            $entry->set_visibility(FALSE);

            if ($entryText) {

                # Set the string to be used to disguise the number of characters in $entryText
                $starText = '********';
                # Just in case $entryText happens to be the same string, use a different string!
                if ($entryText eq $starText) {

                    $starText = 'xxxxxxxx';
                }

                $entry->set_text($starText);

            } else {

                # (Don't hide the fact that $entryText is an empty string, if it is so)
                $starText = '';
            }

        } elsif ($entryText) {

            # $obscureMode is not set, so display $entryText
            $entry->set_text($entryText);
        }

        $entry->signal_connect('button_press_event' => sub {

            # In obscure mode, user can change the entry box's text in two ways - clicking on the
            #   box itself, in which case this event occurs (and we need to empty the box), or by
            #   tabbing focus through widgets, until the focus falls onto the box, in which case
            #   the box is emptied and replaced with the first keypress
            if ($obscureMode && defined $starText) {

                $entry->set_text('');
                # When this function returns a value (below), we need to know whether the
                #   obscured text has been modified. Only need to do this once
                $starText = undef;
            }
        });

        $entry->signal_connect('changed' => sub {

            # If the text in the entry box has been modified, then we reset $starText (for the
            #   reasons described just above)
            $starText = undef;
        });

        $entry->signal_connect('activate' => sub {

            # Get the entry's text, because the code at the bottom of this function won't be
            #   able to retrieve it...
            $responseText = $entry->get_text();
            # ...after we destroy the 'dialogue' window
            $dialogueWin->destroy();
            $self->restoreFocus();
        });

        # Display the 'dialogue' window. Without this combination of Gtk calls, the window is not
        #   consistently active (don't know why this works; it just does)
        $dialogueWin->show_all();
        $dialogueWin->present();
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showEntryDialogue');

        # Prepare text-to-speech (TTS) code. Get a hash of the response buttons, in the form
        #   $buttonHash{'response'} = Gtk2::Button
        $buttonHash{'ok'} =  $dialogueWin->get_widget_for_response('accept');
        if (! $singleFlag) {

            $buttonHash{'cancel'} =  $dialogueWin->get_widget_for_response('reject');
        }

        if ($axmud::CLIENT->systemAllowTTSFlag && $axmud::CLIENT->ttsDialogueFlag) {

            $axmud::CLIENT->tts($title, 'dialogue', 'dialogue', undef);
            $axmud::CLIENT->tts($text, 'dialogue', 'dialogue', undef);

            # Read out buttons, when in focus
            foreach my $response (keys %buttonHash) {

                my $button = $buttonHash{$response};

                $button->signal_connect('grab-focus' => sub {

                    my $label = $button->get_label();

                    if (! defined $lastThing || $lastThing ne $button) {

                        $axmud::CLIENT->tts(
                            # ($label is in the form 'gtk-yes', 'gtk-no' etc)
                            'Button: ' . substr($label, 4),
                            'dialogue',
                            'dialogue',
                            undef,
                        );
                    }

                    # Don't use TTS to read out the same widget consecutively
                    $lastThing = $button;
                });
            }

            $entry->signal_connect('grab-focus' => sub {

                # (Don't read anything out the first time, but if the user cycles through the keys
                #   and returns to the entry, using the tab key, read out something)
                if ($lastThing) {

                    if (! $entry->get_text()) {

                        $axmud::CLIENT->tts(
                            'Type something here',
                            'dialogue',
                            'dialogue',
                            undef,
                        );

                    } else {

                        $axmud::CLIENT->tts(
                            'Entered: ' . $entry->get_text(),
                            'dialogue',
                            'dialogue',
                            undef,
                        );
                    }
                }

                # Don't use TTS to read out the same widget consecutively
                $lastThing = $entry;
            });
        }

        # Get the response
        $response = $dialogueWin->run();
        if ($response eq 'accept' || $response eq 'none') {

            # If the user pressed the ENTER key, the entry's ->signal_connect for 'activate' stored
            #   the entry's text in $responseText, before destroying the window
            if (! $responseText) {

                $responseText = $entry->get_text();
            }

            if ($axmud::CLIENT->systemAllowTTSFlag && $axmud::CLIENT->ttsDialogueFlag) {
                if ($obscureMode) {

                    $axmud::CLIENT->tts('Text accepted', 'dialogue', 'dialogue', undef);

                } else {

                    $axmud::CLIENT->tts(
                        'Entered: ' . $responseText,
                        'dialogue',
                        'dialogue',
                        undef,
                    );
                }
            }

        } else {

            if ($axmud::CLIENT->systemAllowTTSFlag && $axmud::CLIENT->ttsDialogueFlag) {

                $axmud::CLIENT->tts('Cancelled', 'dialogue', 'dialogue', undef);
            }
        }

        # Destroy the window
        $dialogueWin->destroy();
        $self->restoreFocus();

        # (In case TTS is being used and another 'dialogue' window is about to open, make sure the
        #   window is visibly closed)
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showEntryDialogue');

        # Return the response
        if ($obscureMode && defined $starText) {

            # The obscured '********' text has not been modified, so we can return the original
            #   unmodified $entryText
            return $entryText;

        } else {

            # Otherwise, return the contents of the entry box
            return $responseText;
        }
    }

    sub showDoubleEntryDialogue {

        # Can be called by any function
        # Similar to $self->showEntryDialogue, but contains two entry boxes; returns the contents of
        #   both boxes
        #
        # Expected arguments
        #   $title          - The title to display, e.g. 'File Save'
        #   $labelText      - The label above the first entry box. Can be pango markup text, or just
        #                       plain text
        #
        # Optional arguments
        #   $labelText2     - The label above the second entry box. If 'undef', no second label is
        #                       used (but the second entry box is still used)
        #   $maxChars       - The maximum number of chars allowed in both entry boxes (if 'undef',
        #                       no maximum)
        #   $obscureMode    - Sets which of the entry boxes has its text obscured
        #                       - 'default' (or 'undef') - no text is obscured
        #                       - 'first'                - first box is obscured
        #                       - 'second'               - second box is obscured
        #                       - 'both'                 - both boxes are obscured
        #   $bareFlag       - The contents of $labelText, $labelText2 and $labelText3 are normally
        #                       modified to remove any '<' and '>' characters which might cause a
        #                       pango error. If this flag is set to TRUE, they are not removed, on
        #                       the understanding that the calling function wants to display bold/
        #                       italics tags (<b> and </i>, etc). If set to FALSE (or 'undef'),
        #                       the '<' and '>' characters are removed as normal
        #
        # Return values
        #   An empty list on improper arguments or if the user doesn't enter some text in either
        #       entry box
        #   Otherwise a list of two elements, containing the text in both entry boxes

        my (
            $self, $title, $labelText, $labelText2, $maxChars, $obscureMode,
            $bareFlag, $check,
        ) = @_;

        # Local variables
        my (
            $spacing, $response, $responseText, $responseText2,
            @emptyList,
        );

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Set the correct spacing size for 'dialogue' windows
        $spacing = $axmud::CLIENT->constFreeSpacingPixels;

        # Check for improper arguments
        if (! defined $title || ! defined $labelText || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->showDoubleEntryDialogue', @_);
            return @emptyList;
        }

        # Show the 'dialogue' window
        my $dialogueWin = Gtk2::Dialog->new(
            $title,
            $self->winWidget,
            [qw/modal destroy-with-parent/],
            'gtk-cancel' => 'reject',
            'gtk-ok'     => 'accept',
        );

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            return @emptyList;
        });

        # For the benefit of Pango, replace any diamond bracket (< or >) characters with normal
        #   brackets
        if (! $bareFlag) {

            $labelText =~ s/\</(/g;
            $labelText =~ s/\>/)/g;

            if ($labelText2) {

                $labelText2 =~ s/\</(/g;
                $labelText2 =~ s/\>/)/g;
            }
        }

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        # First label and entry
        my $label = Gtk2::Label->new();
        $vBox2->pack_start($label, FALSE, FALSE, $spacing);
        $label->set_alignment(0, 0);
        $label->set_markup($labelText);

        my $entry;
        if (defined $maxChars && $axmud::CLIENT->intCheck($maxChars, 1)) {
            $entry = Gtk2::Entry->new_with_max_length($maxChars);
        } else {
            $entry = Gtk2::Entry->new();
        }
        $vBox2->pack_start($entry, FALSE, FALSE, $spacing);

        # Second label and entry
        if ($labelText2) {

            my $label2 = Gtk2::Label->new();
            $vBox2->pack_start($label2, FALSE, FALSE, $spacing);
            $label2->set_alignment(0, 0);
            $label2->set_markup($labelText2);
        }

        my $entry2;
        if (defined $maxChars && $axmud::CLIENT->intCheck($maxChars, 1)) {
            $entry2 = Gtk2::Entry->new_with_max_length($maxChars);
        } else {
            $entry2 = Gtk2::Entry->new();
        }
        $vBox2->pack_start($entry2, FALSE, FALSE, $spacing);

        # Obscure text in the entry boxes, if necessary
        if ($obscureMode && $obscureMode ne 'default') {

            if ($obscureMode eq 'first' || $obscureMode eq 'both') {

                $entry->set_visibility(FALSE);
            }

            if ($obscureMode eq 'second' || $obscureMode eq 'both') {

                $entry2->set_visibility(FALSE);
            }
        }

        # Display the 'dialogue' window. Without this combination of Gtk calls, the window is not
        #   consistently active (don't know why this works; it just does)
        $dialogueWin->show_all();
        $dialogueWin->present();
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showDoubleEntryDialogue');

        # Get the response. If the user clicked 'cancel', $response will be 'reject'
        # Otherwise, user clicked 'ok', and we need to get the contents of the two boxes
        $response = $dialogueWin->run();
        if ($response eq 'accept') {

            $responseText = $entry->get_text();
            $responseText2 = $entry2->get_text();

            # Destroy the window
            $dialogueWin->destroy();
            $self->restoreFocus();

            # Return the response
            return ($responseText, $responseText2);

        } else {

            # Destroy the window
            $dialogueWin->destroy();
            $self->restoreFocus();

            # Return the response
            return @emptyList;
        }
    }

    sub showTripleEntryDialogue {

        # Can be called by any function
        # Similar to $self->showEntryDialogue, but contains three entry boxes; returns the contents
        #   of all three boxes
        #
        # Expected arguments
        #   $title          - The title to display, e.g. 'File Save'
        #   $labelText      - The label above the first entry box. Can be pango markup text, or just
        #                       plain text
        #
        # Optional arguments
        #   $labelText2     - The label above the second entry box. If 'undef', no second label is
        #                       used (but the second entry box is still used)
        #   $labelText3     - The label above the third entry box. If 'undef', no third label is
        #                       used (but the third entry box is still used)
        #   $maxChars       - The maximum number of chars allowed in all entry boxes (if 'undef',
        #                       no maximum)
        #   $obscureMode    - Sets which of the entry boxes has its text obscured
        #                       - 0 (or 'undef')    - no text is obscured (000)
        #                       - 1                 - first box is obscured (001)
        #                       - 2                 - second box is obscured (010)
        #                       - 3                 - first/second boxes are obscured (011)
        #                       - 4                 - third box is obscured (100)
        #                       - 5                 - first/third boxes are obscured (101)
        #                       - 6                 - second/third boxes are obscured (110)
        #                       - 7                 - all boxes are obscured (111)
        #   $bareFlag       - The contents of $labelText, $labelText2 and $labelText3 are normally
        #                       modified to remove any '<' and '>' characters which might cause a
        #                       pango error. If this flag is set to TRUE, they are not removed, on
        #                       the understanding that the calling function wants to display bold/
        #                       italics tags (<b> and </i>, etc). If set to FALSE (or 'undef'),
        #                       the '<' and '>' characters are removed as normal
        #
        # Return values
        #   An empty list on improper arguments or if the user doesn't enter some text in either
        #       entry box
        #   Otherwise a list of three elements, containing the text in both entry boxes

        my (
            $self, $title, $labelText, $labelText2, $labelText3, $maxChars, $obscureMode, $bareFlag,
            $check,
        ) = @_;

        # Local variables
        my (
            $spacing, $response, $responseText, $responseText2, $responseText3,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $title || ! defined $labelText || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->showTripleEntryDialogue', @_);
            return @emptyList;
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Set the correct spacing size for 'dialogue' windows
        $spacing = $axmud::CLIENT->constFreeSpacingPixels;

        # Show the 'dialogue' window
        my $dialogueWin = Gtk2::Dialog->new(
            $title,
            $self->winWidget,
            [qw/modal destroy-with-parent/],
            'gtk-cancel' => 'reject',
            'gtk-ok'     => 'accept',
        );

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            return @emptyList;
        });

        # For the benefit of Pango, replace any diamond bracket (< or >) characters with normal
        #   brackets
        if (! $bareFlag) {

            $labelText =~ s/\</(/g;
            $labelText =~ s/\>/)/g;

            if ($labelText2) {

                $labelText2 =~ s/\</(/g;
                $labelText2 =~ s/\>/)/g;
            }

            if ($labelText3) {

                $labelText3 =~ s/\</(/g;
                $labelText3 =~ s/\>/)/g;
            }
        }

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        # First label and entry
        my $label = Gtk2::Label->new();
        $vBox2->pack_start($label, FALSE, FALSE, $spacing);
        $label->set_alignment(0, 0);
        $label->set_markup($labelText);

        my $entry;
        if (defined $maxChars && $axmud::CLIENT->intCheck($maxChars, 1)) {
            $entry = Gtk2::Entry->new_with_max_length($maxChars);
        } else {
            $entry = Gtk2::Entry->new();
        }
        $vBox2->pack_start($entry, FALSE, FALSE, $spacing);

        # Second label and entry
        if ($labelText2) {

            my $label2 = Gtk2::Label->new();
            $vBox2->pack_start($label2, FALSE, FALSE, $spacing);
            $label2->set_alignment(0, 0);
            $label2->set_markup($labelText2);
        }

        my $entry2;
        if (defined $maxChars && $axmud::CLIENT->intCheck($maxChars, 1)) {
            $entry2 = Gtk2::Entry->new_with_max_length($maxChars);
        } else {
            $entry2 = Gtk2::Entry->new();
        }
        $vBox2->pack_start($entry2, FALSE, FALSE, $spacing);

        # Third label and entry
        if ($labelText3) {

            my $label3 = Gtk2::Label->new();
            $vBox2->pack_start($label3, FALSE, FALSE, $spacing);
            $label3->set_alignment(0, 0);
            $label3->set_markup($labelText3);
        }

        my $entry3;
        if (defined $maxChars && $axmud::CLIENT->intCheck($maxChars, 1)) {
            $entry3 = Gtk2::Entry->new_with_max_length($maxChars);
        } else {
            $entry3 = Gtk2::Entry->new();
        }
        $vBox2->pack_start($entry3, FALSE, FALSE, $spacing);

        # Obscure text in the entry boxes, if necessary
        if ($obscureMode) {

            if ($obscureMode == 1 || $obscureMode == 3 || $obscureMode == 5 || $obscureMode == 7) {

                $entry->set_visibility(FALSE);
            }

            if ($obscureMode == 2 || $obscureMode == 3 || $obscureMode >= 6) {

                $entry2->set_visibility(FALSE);
            }

            if ($obscureMode >= 4) {

                $entry3->set_visibility(FALSE);
            }
        }

        # Display the 'dialogue' window. Without this combination of Gtk calls, the window is not
        #   consistently active (don't know why this works; it just does)
        $dialogueWin->show_all();
        $dialogueWin->present();
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showTripleComboDialogue');

        # Get the responses. If the user clicked 'cancel', $response will be 'reject'
        # Otherwise, user clicked 'ok', and we need to get the contents of the two boxes
        $response = $dialogueWin->run();
        if ($response eq 'accept') {

            $responseText = $entry->get_text();
            $responseText2 = $entry2->get_text();
            $responseText3 = $entry3->get_text();

            # Destroy the window
            $dialogueWin->destroy();
            $self->restoreFocus();

            # Return the response
            return ($responseText, $responseText2, $responseText3);

        } else {

            # Destroy the window
            $dialogueWin->destroy();
            $self->restoreFocus();

            # Return the response
            return @emptyList;
        }
    }

    sub showComboDialogue {

        # Can be called by any function
        # Shows a short message in a 'dialogue' window with the buttons 'ok' and 'cancel'
        # Prompts the user to choose a line from a combobox; returns the chosen line if the 'ok'
        #   button is pressed, but 'undef' if either the cancel button is pressed or the window is
        #   closed
        #
        # Expected arguments
        #   $title          - The title to display, e.g. 'File Save'
        #   $text           - The message to display. Can be pango markup text, or just plain text
        #
        # Optional arguments
        #   $singleFlag     - Set when called by GA::CLIENT->connectBlind (or by any other code that
        #                       might want to remove the 'Cancel' button). If TRUE, only an 'OK'
        #                       button is used. If FALSE (or 'undef'), both an 'OK' and 'Cancel'
        #                       buttons are used
        #   $listRef        - Reference to a list of scalars to be used in the combo box. If
        #                       'undef', the combo box will be empty
        #
        # Return values
        #   'undef' on improper arguments, if the user doesn't choose a line or if @lineList is
        #       empty
        #   Otherwise returns the user response (the text of the selected line)

        my ($self, $title, $text, $singleFlag, $listRef, $check) = @_;

        # Local variables
        my (
            $spacing, $lastThing, $response, $responseText,
            %buttonHash,
        );

        # Check for improper arguments
        if (! defined $title || ! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showComboDialogue', @_);
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Set the correct spacing size for 'dialogue' windows
        $spacing = $axmud::CLIENT->constFreeSpacingPixels;

        # If $listRef was not specified, use an empty list
        if (! defined $listRef) {

            @$listRef = ();
        }

        # Show the 'dialogue' window. If $listRef is empty, don't show a 'cancel' button
        my $dialogueWin;
        if (! @$listRef || $singleFlag) {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-ok'     => 'accept',
            );

        } else {

            $dialogueWin = Gtk2::Dialog->new(
                $title,
                $self->winWidget,
                [qw/modal destroy-with-parent/],
                'gtk-cancel' => 'reject',
                'gtk-ok'     => 'accept',
            );
        }

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            # (In case TTS is being used and another 'dialogue' window is about to open, make sure
            #   the window is visibly closed)
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showComboDialogue');
        });

        # For the benefit of Pango, replace any diamond bracket (< or >) characters with normal
        #   brackets
        $text =~ s/\</(/g;
        $text =~ s/\>/)/g;

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        my $label = Gtk2::Label->new();
        $vBox2->pack_start($label, FALSE, FALSE, $spacing);
        $label->set_alignment(0, 0);
        $label->set_markup($text);

        my $comboBox = Gtk2::ComboBox->new_text();
        $vBox2->pack_start($comboBox, FALSE, FALSE, $spacing);
        # Fill the combobox with the specified lines, and display the first line
        foreach my $line (@$listRef) {

            $comboBox->append_text($line);
        }
        $comboBox->set_active(FALSE);

        # Display the 'dialogue' window. Without this combination of Gtk calls, the window is not
        #   consistently active (don't know why this works; it just does)
        $dialogueWin->show_all();
        $dialogueWin->present();
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showComboDialogue');

        # Prepare text-to-speech (TTS) code. Get a hash of the response buttons, in the form
        #   $buttonHash{'response'} = Gtk2::Button
        $buttonHash{'ok'} = $dialogueWin->get_widget_for_response('accept');
        if (@$listRef && ! $singleFlag) {

            $buttonHash{'cancel'} = $dialogueWin->get_widget_for_response('reject');
        }

        if ($axmud::CLIENT->systemAllowTTSFlag && $axmud::CLIENT->ttsDialogueFlag) {

            $axmud::CLIENT->tts($title, 'dialogue', 'dialogue', undef);
            $axmud::CLIENT->tts($text, 'dialogue', 'dialogue', undef);

            # Read out buttons, when in focus
            foreach my $response (keys %buttonHash) {

                my $button = $buttonHash{$response};

                $button->signal_connect('grab-focus' => sub {

                    my $label = $button->get_label();

                    if (! defined $lastThing || $lastThing ne $button) {

                        $axmud::CLIENT->tts(
                            # ($label is in the form 'gtk-yes', 'gtk-no' etc)
                            'Button: ' . substr($label, 4),
                            'dialogue',
                            'dialogue',
                            undef,
                        );
                    }

                    # Don't use TTS to read out the same button label consecutively
                    $lastThing = $button;
                });
            }

            # Read out selected items
            $comboBox->signal_connect('key-release-event' => sub {

                my $text = $comboBox->get_active_text();

                # (Use tab/cursor keys to nagivate the widgets)
                if (! defined $lastThing || $lastThing ne $text) {

                    $axmud::CLIENT->tts(
                        'Selected: ' . $text,
                        'dialogue',
                        'dialogue',
                        undef,
                    );
                }

                # Don't use TTS to read out the same combo item consecutively
                $lastThing = $text;

                return undef;
            });

            $comboBox->signal_connect('changed' => sub {

                my $text = $comboBox->get_active_text();

                # (Use the mouse to focus on the combobox)
                if (! defined $lastThing || $lastThing ne $text) {

                    $axmud::CLIENT->tts(
                        'Selected: ' . $text,
                        'dialogue',
                        'dialogue',
                        undef,
                    );
                }

                # Don't use TTS to read out the same combo item consecutively
                $lastThing = $text;

                return undef;
            });

            # Make sure that the first item in the combobox has been read out
            if (! defined $lastThing || (@$listRef && $lastThing ne $$listRef[0])) {

                if (@$listRef) {

                    $axmud::CLIENT->tts(
                        'Selected: ' . $$listRef[0],
                        'dialogue',
                        'dialogue',
                        undef,
                    );

                } else {

                    $axmud::CLIENT->tts(
                        'There is nothing to select',
                        'dialogue',
                        'dialogue',
                        undef,
                    );
                }
            }

            # Don't use TTS to read out the same combo item consecutively
            if (@$listRef) {

                $lastThing = $$listRef[0];
            }
        }

        # Get the response
        $response = $dialogueWin->run();
        if ($response eq 'accept') {

            $responseText = $comboBox->get_active_text();

            if ($axmud::CLIENT->systemAllowTTSFlag && $axmud::CLIENT->ttsDialogueFlag) {

                $axmud::CLIENT->tts(
                    'Entered: ' . $responseText,
                    'dialogue',
                    'dialogue',
                    undef,
                );
            }

        } else {

            if ($axmud::CLIENT->systemAllowTTSFlag && $axmud::CLIENT->ttsDialogueFlag) {

                $axmud::CLIENT->tts('Cancelled', 'dialogue', 'dialogue', undef);
            }
        }

        # Destroy the window
        $dialogueWin->destroy();
        $self->restoreFocus();

        # (In case TTS is being used and another 'dialogue' window is about to open, make sure the
        #   window is visibly closed)
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showComboDialogue');

        return $responseText;
    }

    sub showDoubleComboDialogue {

        # Can be called by any function
        # Similar to $self->showDoubleEntryDialogue, but contains an entry box above a combo box;
        #   returns the contents of both boxes
        # Optionally displays a combo above an entry box, but note that the order of the arguments
        #   remains unchanged
        #
        # Expected arguments
        #   $title          - The title to display, e.g. 'File Save'
        #
        # Optional arguments
        #   $labelText      - The label above the entry box. Can be pango markup text, or just plain
        #                       text. If 'undef', no first label is used (but the entry box is still
        #                       used)
        #   $labelText2     - The label above the combo box. If 'undef', no second label is used
        #                       (but the combo box is still used)
        #   $listRef        - Reference to a list of scalars to be used in the combo box. If
        #                       'undef', the combo box will be empty
        #   $maxChars       - The maximum number of chars allowed in the entry box (if 'undef', no
        #                       maximum)
        #   $reverseFlag    - If set to TRUE, shows a combo above an entry box; if set to FALSE (or
        #                       'undef'), shows an entry above a combo box
        #
        # Return values
        #   An empty list on improper arguments or if the user doesn't enter some text in the entry
        #       box
        #   Otherwise a list of two elements, containing the contents of the entry box and the
        #       active contents of the combo box

        my ($self, $title, $labelText, $labelText2, $listRef, $maxChars, $reverseFlag, $check) = @_;

        # Local variables
        my (
            $spacing, $response, $responseText, $responseText2,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $title || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->showDoubleComboDialogue', @_);
            return @emptyList;
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Set the correct spacing size for 'dialogue' windows
        $spacing = $axmud::CLIENT->constFreeSpacingPixels;

        # If $listRef was not specified, use an empty list
        if (! defined $listRef) {

            @$listRef = ();
        }

        # Show the 'dialogue' window
        my $dialogueWin = Gtk2::Dialog->new(
            $title,
            $self->winWidget,
            [qw/modal destroy-with-parent/],
            'gtk-cancel' => 'reject',
            'gtk-ok'     => 'accept',
        );

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            return @emptyList;
        });

        # For the benefit of Pango, replace any diamond bracket (< or >) characters with normal
        #   brackets
        if ($labelText) {

            $labelText =~ s/\</(/g;
            $labelText =~ s/\>/)/g;
        }

        if ($labelText2) {

            $labelText =~ s/\</(/g;
            $labelText =~ s/\>/)/g;
        }

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        # First label (optional) and entry (not optional)
        my $label;
        if ($labelText) {

            $label = Gtk2::Label->new();
            $label->set_alignment(0, 0);
            $label->set_markup($labelText);
        }

        my $entry;
        if (defined $maxChars && $axmud::CLIENT->intCheck($maxChars, 1)) {
            $entry = Gtk2::Entry->new_with_max_length($maxChars);
        } else {
            $entry = Gtk2::Entry->new();
        }

        # Second label (optional) and combo (not optional)
        my $label2;
        if ($labelText2) {

            $label2 = Gtk2::Label->new();
            $label2->set_alignment(0, 0);
            $label2->set_markup($labelText2);
        }

        my $combo = Gtk2::ComboBox->new_text();
        # Fill the combo box with the specified lines, and display the first line
        if (@$listRef) {

            foreach my $line (@$listRef) {

                $combo->append_text($line);
            }

            $combo->set_active(FALSE);
        }

        # Arrange the entry and combo in the specified order
        if (! $reverseFlag) {

            if ($labelText) {

                $vBox2->pack_start($label, FALSE, FALSE, $spacing);
            }

            $vBox2->pack_start($entry, FALSE, FALSE, $spacing);

            if ($labelText2) {

                $vBox2->pack_start($label2, FALSE, FALSE, $spacing);
            }

            $vBox2->pack_start($combo, FALSE, FALSE, $spacing);

        } else {

            if ($labelText2) {

                $vBox2->pack_start($label2, FALSE, FALSE, $spacing);
            }

            $vBox2->pack_start($combo, FALSE, FALSE, $spacing);

            if ($labelText) {

                $vBox2->pack_start($label, FALSE, FALSE, $spacing);
            }

            $vBox2->pack_start($entry, FALSE, FALSE, $spacing);
        }

        # Display the 'dialogue' window. Without this combination of Gtk calls, the window is not
        #   consistently active (don't know why this works; it just does)
        $dialogueWin->show_all();
        $dialogueWin->present();
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showDoubleComboDialogue');

        # Get the response. If the user clicked 'cancel', $response will be 'reject'
        # Otherwise, user clicked 'ok', and we need to get the contents of the two boxes
        $response = $dialogueWin->run();
        if ($response eq 'accept') {

            $responseText = $entry->get_text();
            $responseText2 = $combo->get_active_text();

            # Destroy the window
            $dialogueWin->destroy();
            $self->restoreFocus();

            # Return the response
            return ($responseText, $responseText2);

        } else {

            # Destroy the window
            $dialogueWin->destroy();
            $self->restoreFocus();

            # Return the response
            return @emptyList;
        }
    }

    sub showColourSelectionDialogue {

        # Can be called by any function
        # Creates a standard Gtk2::ColorSelectionDialog and returns the response (if any)
        #
        # Expected arguments
        #   $title          - The title to display, e.g. 'Select colour'
        #
        # Optional arguments
        #   $initialColour  - The initial colour to use, in the form '#FFFFFF'. If not specified,
        #                       the dialogue's default colour ('#FFFFFF') is used
        #
        # Return values
        #   'undef' on expected arguments or if the user doesn't close the 'dialogue' window by
        #       clicking the 'ok' button
        #   Otherwise, returns the colour selected, in the form '#FFFFFF'

        my ($self, $title, $initialColour, $check) = @_;

        # Local variables
        my ($colorSelectionObj, $red, $green, $blue, $colorObj, $response, $hex);

        # Check for improper arguments
        if (! defined $title || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->showColourSelectionDialogue',
                @_,
            );
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Show the 'dialogue' window
        my $dialogueWin = Gtk2::ColorSelectionDialog->new($title);

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $colorSelectionObj = $dialogueWin->get_color_selection();

        if ($initialColour) {

            # Split a string like '#FFFFFF' into three seperate colours (red, green and blue),
            #   convert them to decimals (in the range 0-255), and then convert that to a range of
            #   0-65535 - which is what Gtk2::Gdk::Color expects
            $red = hex(substr($initialColour, 1, 2)) * 257;
            $green = hex(substr($initialColour, 3, 2)) * 257;
            $blue = hex(substr($initialColour, 5, 2)) * 257;

            $colorObj = Gtk2::Gdk::Color->new($red, $green, $blue, 0);

            # Tell the Gtk2::ColorSelectionDialog to use this colour, initially
            $colorSelectionObj->set_current_color($colorObj);
        }

        # Get the response
        $response = $dialogueWin->run();
        if ($response eq 'ok') {

            # This is probably not the best way of converting #ffff25812581 to #FF2525, but it will
            #   have to do, for now
            $hex = '#' . uc(
                sprintf('%02x', int($colorSelectionObj->get_current_color->red() / 256))
                . sprintf('%02x', int($colorSelectionObj->get_current_color->green() / 256))
                . sprintf('%02x', int($colorSelectionObj->get_current_color->blue() / 256))
            );
        }

        # Destroy the window
        $dialogueWin->destroy();

        # Return the colour (or 'undef' if no colour was selected)
        return $hex;
    }

    sub showFontSelectionDialogue {

        # Can be called by any function
        # Creates a standard Gtk2::FontSelectionDialog and returns the response (if any)
        #
        # Expected arguments
        #   $title          - The title to display, e.g. 'Select font'
        #
        # Optional arguments
        #   $initialFont    - The initial font and size to use, a string in the form 'Monospace 10'
        #
        # Return values
        #   'undef' on expected arguments or if the user doesn't close the 'dialogue' window by
        #       clicking the 'ok' button
        #   Otherwise, returns the font selected as a string in the form 'Monospace 10'

        my ($self, $title, $initialFont, $check) = @_;

        # Local variables
        my ($response, $newFont);

        # Check for improper arguments
        if (! defined $title || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->showFontSelectionDialogue',
                @_,
            );
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Show the 'dialogue' window
        my $dialogueWin = Gtk2::FontSelectionDialog->new($title);
        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        if ($initialFont) {

            $dialogueWin->set_font_name($initialFont);
        }

        # Get the response
        $response = $dialogueWin->run();
        if ($response eq 'ok') {

            # Get the selected font
            $newFont = $dialogueWin->get_font_name();
        }

        # Close the 'dialogue' window
        $dialogueWin->destroy();

        # Return the font (or 'undef' if no font was selected)
        return $newFont;
    }

    sub promptRoomFlag {

        # Called by GA::EditWin::WorldModel->roomFlags1Tab
        # Prompts the user for the attributes of a new custom room flag
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments or if the user closes the window without clicking
        #       the 'OK' button
        #   Otherwise returns a list in the form
        #       (name, short_name, descrip, colour)
        #   ...roughly corresponding to IVs in the new GA::Obj::RoomFlag object

        my ($self, $check) = @_;

        # Local variables
        my (
            $colour, $response,
            @emptyList, @returnList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->promptRoomFlag', @_);
            return @emptyList;
        }

        # Show the 'dialogue' window
        my $dialogueWin = Gtk2::Dialog->new(
            'Add custom room flag',
            $self->winWidget,
            [qw/modal destroy-with-parent/],
            'gtk-cancel' => 'reject',
            'gtk-ok'     => 'accept',
        );

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            return @emptyList;
        });

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        # Need a table as it's the quicket way to draw the room flag colour
        my $table = Gtk2::Table->new(3, 7, FALSE);
        $vBox2->pack_start($table, TRUE, TRUE, $axmud::CLIENT->constFreeSpacingPixels);
        $table->set_row_spacings($axmud::CLIENT->constFreeSpacingPixels);
        $table->set_col_spacings($axmud::CLIENT->constFreeSpacingPixels);

        # Name
        my $label = Gtk2::Label->new();
        $table->attach_defaults($label, 0, 3, 0, 1);
        $label->set_alignment(0, 0);
        $label->set_markup('Room flag name (max 16 chars)');

        my $entry = Gtk2::Entry->new();
        $table->attach_defaults($entry, 0, 3, 1, 2);
        $entry->set_width_chars(16);
        $entry->set_max_length(16);

        # Short name
        my $label2 = Gtk2::Label->new();
        $table->attach_defaults($label2, 0, 3, 2, 3);
        $label2->set_alignment(0, 0);
        $label2->set_markup('Short name (max 2 chars)');

        my $entry2 = Gtk2::Entry->new();
        $table->attach_defaults($entry2, 0, 3, 3, 4);
        $entry2->set_width_chars(2);
        $entry2->set_max_length(2);

        # Description
        my $label3 = Gtk2::Label->new();
        $table->attach_defaults($label3, 0, 3, 4, 5);
        $label3->set_alignment(0, 0);
        $label3->set_markup('Description');

        my $entry3 = Gtk2::Entry->new();
        $table->attach_defaults($entry3, 0, 3, 5, 6);

        # Colour
        $colour = '#FFFFFF';            # Default new colour is white

        my $label4 = Gtk2::Label->new();
        $table->attach_defaults($label4, 0, 1, 6, 7);
        $label4->set_markup('Use colour');
        $label4->set_alignment(0, 0.5);

        my ($frame, $canvas, $canvasObj) = $self->addSimpleCanvas($table,
            $colour,
            undef,                  # No neutral colour
            1, 2, 6, 7,
        );

        my $button = Gtk2::Button->new('Set');
        $table->attach_defaults($button, 2, 3, 6, 7);
        $button->signal_connect('clicked' => sub {

            my $choice = $self->showColourSelectionDialogue(
                'Colour',
                $colour,
            );

            if ($choice) {

                $colour = $choice;
                $canvasObj = $self->fillSimpleCanvas($canvas, $canvasObj, $colour);
            }
        });

        # Display the dialogue window
        $vBox->show_all();

        # If the user clicked 'cancel', $response will be 'reject'
        $response = $dialogueWin->run();

        if ($response ne 'accept') {

            $dialogueWin->destroy();
            $self->restoreFocus();

            return @emptyList;

        # Otherwise, user clicked 'ok'
        } else {

            @returnList = ($entry->get_text(), $entry2->get_text(), $entry3->get_text(), $colour);

            $dialogueWin->destroy();
            $self->restoreFocus();

            return @returnList;
        }
    }

    sub showIrreversibleTest {

        # Called by GA::Cmd::ToggleIrreversible->do
        # Shows a 'dialogue' window with a non-functional button that contains both an icon and
        #   some text, to test whether the user's system allows both (some systems will show only
        #   the text)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the user closes the 'dialogue' window
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showIrreversibleTest', @_);
        }

        # If an earlier call to $self->showBusyWin created a popup window, close it (otherwise it'll
        #   be visible above the new dialogue window)
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Show the 'dialogue' window
        my $dialogueWin = Gtk2::Dialog->new(
            'Irreversible icon test',
            $self->winWidget,
            [qw/modal destroy-with-parent/],
            'gtk-ok'     => 'accept',
        );

        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $self->restoreFocus();

            return undef;
        });

        # Add widgets to the 'dialogue' window
        my $vBox = $dialogueWin->vbox;
        # The call to ->addDialogueIcon splits $vBox in two, with an icon on the left, and a new
        #   Gtk2::VBox on the right, into which we put everything
        my $vBox2 = $self->addDialogueIcon($vBox);

        my $label = Gtk2::Label->new();
        $vBox2->pack_start($label, FALSE, FALSE, $axmud::CLIENT->constFreeSpacingPixels);
        $label->set_alignment(0, 0);
        $label->set_markup(
            "<i>If button icons are available on your\nsystem, the button below contains\nboth an"
            . " icon and some text</i>"
        );

        my $button = Gtk2::Button->new('Hello world!');
        $vBox2->pack_start($button, FALSE, FALSE, $axmud::CLIENT->constFreeSpacingPixels);

        my $image = Gtk2::Image->new_from_file(
            $axmud::SHARE_DIR . '/icons/system/irreversible.png',
        );

        $button->set_image($image);

        my $label2 = Gtk2::Label->new();
        $vBox2->pack_start($label2, FALSE, FALSE, $axmud::CLIENT->constFreeSpacingPixels);
        $label2->set_alignment(0, 0);
        $label2->set_markup(
            "<i>Click 'OK' to end the test</i>"
        );

        # Display the 'dialogue' window. Without this combination of Gtk calls, the window is not
        #   consistently active (don't know why this works; it just does)
        $dialogueWin->show_all();
        $dialogueWin->present();
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showIrreversibleTest');

        # If the user clicked 'cancel', $response will be 'reject'
        # Otherwise, user clicked 'ok', and we might need to add initial tasks
        $dialogueWin->run();
        $dialogueWin->destroy();
        $self->restoreFocus();

        return 1;
    }

    sub showBusyWin {

        # Displays a temporary popup window (still an Axmud 'dialogue' window)
        # By default, displays the Axmud icon and the caption 'Loading...', but the calling function
        #   can specify a different logo and caption, if required
        # The popup window must be closed by the calling function, when no longer required (via a
        #   call to $self->closeDialogueWin)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $path       - Path of the file containing the image to show as an icon. If not
        #                   specified, the standard Axmud icon
        #   $caption    - A short piece of text to show next to the image. If not specified, the
        #                   caption 'Loading...' is used
        #
        # Return values
        #   'undef' on improper arguments or if the window is not opened
        #   1 otherwise

        my ($self, $path, $caption, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showBusyWin', @_);
        }

        # Don't show the popup window at all, if not allowed
        if (! $axmud::CLIENT->allowBusyWinFlag) {

            return undef;
        }

        # Only one of these temporary popup windows can exist at a time. If one already exists,
        #   close it
        if ($axmud::CLIENT->busyWin) {

            $self->closeDialogueWin($axmud::CLIENT->busyWin);
        }

        # Set the file path and caption text, if not specified
        if (! defined $path || ! (-e $path)) {

            $path = $axmud::CLIENT->getDialogueIcon(TRUE);
        }

        if (! $caption) {

            $caption = 'Loading...';
        }

        # Show the window widget
        my $dialogueWin = Gtk2::Window->new('popup');
        $dialogueWin->set_position('center-always');
        $dialogueWin->set_icon_list($axmud::CLIENT->desktopObj->dialogueWinIconList);
        $dialogueWin->set_title($axmud::SCRIPT);
        $dialogueWin->set_border_width(0);
        $dialogueWin->set_transient_for($self->winWidget);

        $dialogueWin->signal_connect('delete-event' => sub {

            $dialogueWin->destroy();
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showBusyWin');
        });

        # Add widgets to the 'dialogue' window
        my $frame = Gtk2::Frame->new();
        $dialogueWin->add($frame);

        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $frame->add($hBox);
        $hBox->set_border_width(10);

        my $image = Gtk2::Image->new_from_file($path);
        $hBox->pack_start($image, FALSE, FALSE, 5);

        my $label = Gtk2::Label->new();
        $hBox->pack_start($label, FALSE, FALSE, 5);
        $label->set_markup('<i><big>' . $caption . '</big></i>');
        $label->set_alignment(0.5, 0.5);

        $dialogueWin->show_all();

        # For some reason, during certain operations the icon and text are not shown in the
        #   window; the following lines make them appear
        $dialogueWin->present();
        # Update Gtk2's events queue
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showBusyWin');
        # Update the Client IV
        $axmud::CLIENT->set_busyWin($dialogueWin);

        return $dialogueWin;
    }

    # Functions to add widgets to a Gtk2::Table

    sub addLabel {

        # Adds a Gtk2::Label at the specified position in a Gtk2::Table
        #
        # Example calls:
        #   my $label = $self->addLabel($table, 'Some plain text',
        #       0, 6, 0, 1);
        #   my $label = $self->addLabel($table, '<b>Some pango markup text</b>',
        #       0, 6, 0, 1,
        #       0, 0.5);
        #
        # Expected arguments
        #   $table      - The Gtk2::Table itself
        #   $text       - The text to display (plain text or pango markup text)
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the label in the table
        #
        # Optional arguments
        #   $alignLeft, $alignRight
        #               - Used in the call to ->set_alignment; two values in the range 0-1
        #               - If not specified, $alignLeft is set to 0, $alignRight to 0.5
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Label created

        my (
            $self, $table, $text, $leftAttach, $rightAttach, $topAttach, $bottomAttach, $alignLeft,
            $alignRight, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $text || ! defined $leftAttach || ! defined $rightAttach
            || ! defined $topAttach || ! defined $bottomAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addLabel', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Set default alignment, if none specified
        if (! defined $alignLeft) {

            $alignLeft = 0;
        }

        if (! defined $alignRight) {

            $alignRight = 0.5;
        }

        # Create the label
        my $label = Gtk2::Label->new();
        $label->set_markup($text);

        # Set its alignment
        $label->set_alignment($alignLeft, $alignRight);

        # Add the label to the table
        $table->attach_defaults($label, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $label;
    }

    sub addButton {

        # Adds a Gtk2::Button at the specified position in a Gtk2::Table
        # NB This function does not contain a ->signal_connect method - the calling function must
        #   specify its own one
        #
        # Example calls:
        #   my $button = $self->addButton($table, \&buttonClicked, 'button_label', 'tooltips',
        #       0, 6, 0, 1);
        #   my $button = $self->addButton($table, undef, 'button_label', 'tooltips',
        #       0, 6, 0, 1);
        #   my $button = $self->addButton($table, \&buttonClicked, 'button_label', '',
        #       0, 6, 0, 1);
        #
        # The referenced function (if specified) receives an argument list in the form:
        #   ($self, button_widget)
        #
        # Expected arguments
        #   $table      - The Gtk2::Table itself
        #   $funcRef    - Reference to the function to call when the button is clicked. If 'undef',
        #                   it's up to the calling function to create a ->signal_connect method
        #   $label      - The label text displayed on the button
        #   $tooltips   - Tooltips to use for the button; empty strings are not used
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the button in the table
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Button created

        my (
            $self, $table, $funcRef, $label, $tooltips, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $check,
        ) = @_;

        # Local variables
        my $current;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $label || ! defined $tooltips || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addButton', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Create the button
        my $button = Gtk2::Button->new($label);

        # Use tooltips, if any were specified
        if ($tooltips) {

            $self->tooltips->set_tip($button, $tooltips);
        }

        # If a callback function was specified, apply it
        if ($funcRef) {

            $button->signal_connect('clicked' => sub {

                &$funcRef($self, $button);
            });
        }

        # Add the button to the table
        $table->attach_defaults(
            $button,
            $leftAttach,
            $rightAttach,
            $topAttach,
            $bottomAttach,
        );

        return $button;
    }

    sub addCheckButton {

        # Adds a Gtk2::CheckButton at the specified position in a Gtk2::Table
        # NB This function does not contain a ->signal_connect method - the calling function must
        #   specify its own one
        #
        # Example calls:
        #   my $checkButton = $self->addCheckButton($table, \&buttonClicked, TRUE, TRUE,
        #       0, 6, 0, 1);
        #   my $checkButton = $self->addCheckButton($table, undef, FALSE, TRUE,
        #       0, 6, 0, 1, 0, 0.5);
        #
        # The referenced function (if specified) receives an argument list in the form:
        #   ($self, button_widget, button_selected_flag)
        #
        # Expected arguments
        #   $table      - The Gtk2::Table itself
        #   $funcRef    - Reference to the function to call when the button is toggled. If 'undef',
        #                   it's up to the calling function to create a ->signal_connect method
        #   $selectFlag - Flag set to FALSE if the checkbutton shouldn't be selected initially, TRUE
        #                   if it should be selected initially
        #   $stateFlag  - Flag set to FALSE if the checkbutton's state should be 'insensitive',
        #                   TRUE if it should be 'normal'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the checkbutton in the table
        #
        # Optional arguments
        #   $alignX, $alignY
        #               - Used in the call to ->set_alignment; two values in the range 0-1
        #               - If not specified, $alignX is set to 0, $alignY to 0.5
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::CheckButton created

        my (
            $self, $table, $funcRef, $selectFlag, $stateFlag, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $alignX, $alignY, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $selectFlag || ! defined $stateFlag
            || ! defined $leftAttach || ! defined $rightAttach || ! defined $topAttach
            || ! defined $bottomAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addCheckButton', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Set default alignment, if none specified
        if (! defined $alignX) {

            $alignX = 0;
        }

        if (! defined $alignY) {

            $alignY = 0.5;
        }

        # Create the check button
        my $checkButton = Gtk2::CheckButton->new();

        # Set the checkbutton's initial value
        $checkButton->set_active($selectFlag);

        # Make the checkbutton insensitive, if $stateFlag is FALSE
        if (! $stateFlag) {

            $checkButton->set_state('insensitive');
        }

        # Set its alignment
        $checkButton->set_alignment($alignX, $alignY);

        # If a callback function was specified, apply it
        if ($funcRef) {

            $checkButton->signal_connect('toggled' => sub {

                &$funcRef($self, $checkButton, $checkButton->get_active());
            });
        }

        # Add it to the table
        $table->attach_defaults(
            $checkButton,
            $leftAttach,
            $rightAttach,
            $topAttach,
            $bottomAttach,
        );

        return $checkButton;
    }

    sub addRadioButton {

        # Adds a Gtk2::RadioButton at the specified position in a Gtk2::Table
        # NB This function does not contain a ->signal_connect method - the calling function must
        #   specify its own one
        #
        # Example calls:
        #   my ($group, $button) = $self->addRadioButton(
        #       $table, \&buttonClicked, undef, $name,
        #       TRUE, TRUE,
        #       0, 6, 0, 1);
        #   my ($group2, $button2) = $self->addRadioButton(
        #       $table, undef, $group, $name,
        #       FALSE, TRUE,
        #       0, 6, 0, 1, 0, 0.5);
        #
        # The referenced function (if specified) receives an argument list in the form:
        #   ($self, button_widget)
        #
        # Expected arguments
        #   $table      - The Gtk2::Table itself
        #   $funcRef    - Reference to the function to call when the button becomes active
        #                   (selected). If 'undef', it's up to the calling function to create a
        #                   ->signal_connect method
        #   $group      - Reference to the radio button group created, when the first button in the
        #                   group was added (if set to 'undef', this is the first button, and a
        #                   group will be created for it)
        #   $name       - A 'name' for the radio button (displayed next to the button); if 'undef',
        #                   no name is displayed
        #   $selectFlag - Flag set to FALSE if the radio button shouldn't be selected initially,
        #                   TRUE if it should be selected initially
        #   $stateFlag  - Flag set to FALSE if the radiobutton's state should be 'insensitive',
        #                   TRUE if it should be 'normal'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the radiobutton in the table
        #
        # Optional arguments
        #   $alignLeft, $alignRight
        #               - Used in the call to ->set_alignment; two values in the range 0-1
        #               - If not specified, $alignLeft is set to 0, $alignRight to 0.5
        #
        # Return values
        #   An empty list on improper arguments or if the widget's position in the Gtk2::Table is
        #       invalid
        #   Otherwise a list containing two elements: the radio button $group and the
        #       Gtk2::RadioButton created

        my (
            $self, $table, $funcRef, $group, $name, $selectFlag, $stateFlag, $leftAttach,
            $rightAttach, $topAttach, $bottomAttach, $alignLeft, $alignRight, $check,
        ) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $selectFlag || ! defined $stateFlag
            || ! defined $leftAttach || ! defined $rightAttach || ! defined $topAttach
            || ! defined $bottomAttach || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->addRadioButton', @_);
            return @emptyList;
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return @emptyList;
        }

        # Set default alignment, if none specified
        if (! defined $alignLeft) {

            $alignLeft = 0;
        }
        if (! defined $alignRight) {

            $alignRight = 0.5;
        }

        # Create the radio button
        my $radioButton = Gtk2::RadioButton->new();
        # Add it to the existing group, if one was specified
        if (defined $group) {

            $radioButton->set_group($group);
        }

        # Set the radiobutton's initial value
        $radioButton->set_active($selectFlag);

        # Give the radio button a name, if one was specified
        if ($name) {

            $radioButton->set_label($name);
        }

        # Make the radiobutton insensitive, if $stateFlag is FALSE
        if (! $stateFlag) {

            $radioButton->set_state('insensitive');
        }

        # Set radiobutton's alignment
        $radioButton->set_alignment($alignLeft, $alignRight);

        # If a callback function was specified, apply it
        if ($funcRef) {

            $radioButton->signal_connect('toggled' => sub {

                # Only call the function if this radio button has been selected
                if ($radioButton->get_active()) {

                    &$funcRef($self, $radioButton);
                }
            });
        }

        # Add it to the table
        $table->attach_defaults(
            $radioButton,
            $leftAttach,
            $rightAttach,
            $topAttach,
            $bottomAttach,
        );

        return ($radioButton->get_group(), $radioButton);
    }

    sub addEntry {

        # Adds a Gtk2::Entry at the specified position in a Gtk2::Table
        # NB This function does not contain a ->signal_connect method - the calling function must
        #   specify its own one
        #
        # Example calls:
        #   my $entry = $self->addEntry($table, \&returnPressed, $value, TRUE,
        #       0, 6, 0, 1);
        #   my $entry = $self->addEntry($table, undef, $value, FALSE,
        #       0, 6, 0, 1, 16, 16);
        #
        # The referenced function (if specified) receives an argument list in the form:
        #   ($self, entry_widget, entry_text)
        #
        # Expected arguments
        #   $table      - The Gtk2::Table itself
        #   $funcRef    - Reference to the function to call when the user types something in the
        #                   entry and presses 'return'. If 'undef', it's up to the calling function
        #                   to create a ->signal_connect method
        #   $value      - The initial contents of the entry box. Set to 'undef' if you want it to be
        #                   empty
        #   $stateFlag  - Flag set to FALSE if the entry box's state should be 'insensitive', TRUE
        #                   if it should be 'normal'
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the entry box in the table
        #
        # Optional arguments
        #   $widthChars - The width of the box, in chars ('undef' if maximum not needed)
        #   $maxChars   - The maximum no. chars allowed in the box ('undef' if maximum not needed)
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::Entry created

        my (
            $self, $table, $funcRef, $value, $stateFlag, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $widthChars, $maxChars, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $stateFlag || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addEntry', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Create the entry
        my $entry = Gtk2::Entry->new();

        # Set the entry's value
        if ($value) {

            $entry->set_text($value);
        }

        # Make the entry insensitive, if $stateFlag is FALSE
        if (! $stateFlag) {

            $entry->set_state('insensitive');
        }

        # Set the width, if specified
        if (defined $widthChars) {

            $entry->set_width_chars($widthChars);
        }

        # Set the maximum number of characters, if specified
        if (defined $maxChars) {

            $entry->set_max_length($maxChars);
        }

        # If a callback function was specified, apply it
        if ($funcRef) {

            $entry->signal_connect('activate' => sub {

                &$funcRef($self, $entry, $entry->get_text());
            });
        }

        # Add the entry to the table
        $table->attach_defaults($entry, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        return $entry;
    }

    sub addComboBox {

        # Adds a Gtk2::ComboBox at the specified position in a Gtk2::Table
        # NB This function does not contain a ->signal_connect method - the calling function must
        #   specify its own one
        #
        # Example calls:
        #   my $comboBox = $self->addComboBox(
        #       $table, \&itemSelected, \@comboList, 'some_title', TRUE,
        #       0, 6, 0, 1);
        #   my $comboBox = $self->addComboBox(
        #       $table, undef, \@comboList, '', FALSE,
        #       0, 6, 0, 1);
        #
        # The referenced function (if specified) receives an argument list in the form:
        #   ($self, combo_box_widget, selected_text)
        #
        # Expected arguments
        #   $table          - The Gtk2::Table itself
        #   $funcRef        - Reference to the function to call when the user selects something in
        #                       the combobox. If 'undef', it's up to the calling function to create
        #                       a ->signal_connect method
        #   $listRef        - Reference to a list with initial values (can be an empty list)
        #   $title          - A string used as a title, e.g. 'Choose your favourite colour' - if
        #                       'undef', a title isn't used (use an empty string for an initially-
        #                       empty combobox)
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #                   - The position of the combo box in the table
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::ComboBox created

        my (
            $self, $table, $funcRef, $listRef, $title, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $listRef || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addComboBox', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Create the combobox
        my $comboBox = Gtk2::ComboBox->new_text();

        # Populate the combobox
        if (defined $title) {

            # The first item in the combobox list is a title
            $comboBox->append_text($title);
        }

        foreach my $item (@$listRef) {

            $comboBox->append_text($item);
        }

        $comboBox->set_active(0);

        # If a callback function was specified, apply it
        if ($funcRef) {

            $comboBox->signal_connect('changed' => sub {

                my $text = $comboBox->get_active_text();

                # If the user has selected the title, ignore it
                if (! defined $title || $text ne $title) {

                    &$funcRef($self, $comboBox, $text);
                }
            });
        }

        # Add the combobox to the table
        $table->attach_defaults(
            $comboBox,
            $leftAttach,
            $rightAttach,
            $topAttach,
            $bottomAttach,
        );

        return $comboBox;
    }

    sub addTextView {

        # Adds a Gtk2::TextView at the specified position in a Gtk2::Table
        # NB This function does not contain a ->signal_connect method - the calling function must
        #   specify its own one
        #
        # Example calls:
        #   my $textView = $self->addTextView($table, $self->winType, undef, undef, TRUE,
        #       0, 6, 0, 1);
        #   my $textView = $self->addTextView($table, undef, undef, "Hello\nworld", FALSE,
        #       0, 6, 0, 1,
        #       -1, 120);
        #
        # The referenced function (if specified) receives an argument list in the form:
        #   ($self, textview_widget, buffer_widget, buffer_text)
        # ...where 'buffer_text' is a string containing one or more lines, separated by newline
        #   characters
        #
        # Expected arguments
        #   $table          - The Gtk2::Table itself
        #   $colourScheme   - The name of the colour scheme to use (matches a key in
        #                       GA::Client->colourSchemeHash; you should normally use the window
        #                       type, as in the example above). If 'undef', the system's
        #                       preferred colours/fonts are used. If the specified colour scheme
        #                       doesn't exist, the colour scheme matching the window type is used
        #   $funcRef        - Reference to the function to call when the user edits the contents of
        #                       the textview. If 'undef', it's up to the calling function to create
        #                       a ->signal_connect method
        #   $string         - String composed of one or lines separated by newline characters. If
        #                       'undef', the textview is initially empty
        #   $editableFlag
        #                   - Flag set to TRUE if the textView should be editable, FALSE if it
        #                       shouldn't be editable
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #                   - The position of the textview in the table
        #
        # Optional arguments
        #   $width, $height
        #               - The width and height (in pixels) of the frame containing the list. If
        #                   specified, values of -1 mean 'don't set this value'. The default values
        #                   are (-1, 120) - we use a fixed height, because Gtk2 on some operating
        #                   systems will draw a textview barely one line high (in a vertical
        #                   packing box)
        #
        # Return values
        #   'undef' on improper arguments or if the widget's position in the Gtk2::Table is invalid
        #   Otherwise the Gtk2::TextView created (inside a Gtk::ScrolledWindow)

        my (
            $self, $table, $colourScheme, $funcRef, $string, $editableFlag, $leftAttach,
            $rightAttach, $topAttach, $bottomAttach, $width, $height, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $editableFlag || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addTextView', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Set defaults
        if (! defined $width) {

            $width = -1;    # Let Gtk2 set the width
        }

        if (! defined $height) {

            $height = 120;
        }

        # Creating a containing Gtk2::ScrolledWindow
        my $scroll = Gtk2::ScrolledWindow->new(undef, undef);
        $scroll->set_shadow_type('etched-out');
        $scroll->set_policy('automatic', 'automatic');
        $scroll->set_size_request($width, $height);
        $scroll->set_border_width($self->spacingPixels);

        # Create a textview
        my $textView;
        if (defined $colourScheme) {

            # Use colours/fonts specified by an Axmud colour scheme
            if ($axmud::CLIENT->ivExists('colourSchemeHash', $colourScheme)) {
                $axmud::CLIENT->desktopObj->getTextViewStyle($colourScheme);
            } else {
                $axmud::CLIENT->desktopObj->getTextViewStyle($self->winType);
            }

            $textView = Gtk2::TextView->new();

        } else {

            # Using the sub-class preserves the system's preferred colours/fonts
            $textView = Games::Axmud::Widget::TextView::Gtk2->new();
        }

        $scroll->add($textView);
        my $buffer = Gtk2::TextBuffer->new();
        $textView->set_buffer($buffer);
        $textView->set_cursor_visible(FALSE);

        if ($string) {

            $buffer->set_text(join("\n", $string));
        }

        # Make the textview editable or not editable
        $textView->set_editable($editableFlag);

        # If a callback function was specified, apply it
        if ($funcRef) {

            $buffer->signal_connect('changed' => sub {

                &$funcRef(
                    $self,
                    $textView,
                    $buffer,
                    $axmud::CLIENT->desktopObj->bufferGetText($buffer),
                );
            });
        }

        # Add the textview to the table
        $table->attach_defaults(
            $scroll,
            $leftAttach,
            $rightAttach,
            $topAttach,
            $bottomAttach,
        );

        return $textView;
    }

    sub addImage {

        # Adds a Gtk2::Image from a specified file, inside a frame (optionally using scrollbars) at
        #   the specified position in a Gtk2::Table
        #
        # Example calls:
        #   my ($image, $frame, $viewPort) = $self->addImage($table, $filePath, $pixBuffer, TRUE,
        #       128, 128,
        #       0, 12, 1, 12);
        #   my ($image, $frame) = $self->addImage($table, undef, undef, FALSE,
        #       128, 128,
        #       0, 12, 1, 12);
        #
        # Expected arguments
        #   $table      - The Gtk2::Table itself
        #   $filePath       - Full path to the file containing the image to be displayed (or 'undef'
        #                       if not using a file)
        #   $pixBuffer      - A Gtk2::Gdk::Pixbuf  containing the image to be displayed (or 'undef'
        #                       if not using a pixbuf)
        #   $scrollFlag     - Flag set to TRUE if the image's viewport should use scrollbars,
        #                       FALSE if not
        #   $width, $height - The size of the frame in which the image is shown (in pixels)
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #                   - The position of the frame in the table
        #
        # Return values
        #   An empty list on improper arguments or if a $filePath is specified which doesn't exist
        #   Otherwise returns a list in the form
        #       (gtk2_image, gtk2_frame, gtk2_viewport)
        #   NB If neither $filePath nor $pixBuffer are specified, or if the Gtk2::Image can't be
        #       created, the 'gtk2_image' return value will be set to 'undef'
        #   NB If $scrollFlag is FALSE, the 'gtk2_viewport' return value will be set to 'undef'

        my (
            $self, $table, $filePath, $pixBuffer, $scrollFlag, $width, $height, $leftAttach,
            $rightAttach, $topAttach, $bottomAttach, $check,
        ) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $scrollFlag || ! defined $width || ! defined $height
            || ! defined $leftAttach || ! defined $rightAttach || ! defined $topAttach
            || ! defined $bottomAttach || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->addImage', @_);
            return @emptyList;
        }

        # Check that the position in the table makes sense, and that filename (if specified) exists
        if (
            ! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)
            || (defined $filePath && ! -e $filePath)
        ) {
            return @emptyList;
        }

        # Create a frame
        my $frame = Gtk2::Frame->new(undef);
        $frame->set_border_width(3);
        $frame->set_size_request($width, $height);

        # Create the Gtk2::Image
        my $image;
        if ($filePath) {
            $image = Gtk2::Image->new_from_file($filePath);
        } elsif ($pixBuffer) {
            $image = Gtk2::Image->new_from_pixbuf($pixBuffer);
        }

        my $viewPort;
        if ($scrollFlag) {

            # Create a scrolled window
            my $scroller = Gtk2::ScrolledWindow->new();
            $scroller->set_border_width(3);

            # Create a viewport
            my $viewPort = Gtk2::Viewport->new(undef, undef);

            # If a Gtk2::Image was created, add it to the viewport
            if ($image) {

                $viewPort->add($image);
            }

            # Add the viewport to the scrolled window
            $scroller->add($viewPort);
            # Add the scrolled window to the frame
            $frame->add($scroller);

        } else {

            # If a Gtk2::Image was created, add it to the frame
            if ($image) {

                $frame->add($image);
            }
        }

        # Add the frame to the table (even if a Gtk2::Image wasn't created)
        $table->attach_defaults(
            $frame,
            $leftAttach,
            $rightAttach,
            $topAttach,
            $bottomAttach,
        );

        return ($image, $frame, $viewPort);
    }

    sub changeImage {

        # Changes the image shown as the result of a call to $self->addImage
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $viewPort   - The Gtk2::Viewport which contains the image ('undef' if no scrolling
        #                   viewport was used)
        #   $frame      - The Gtk2::Frame which contains the image ('undef' if a scrolling
        #                   viewport was used; ignored if $viewPort is defined)
        #   $oldImage   - The Gtk2::Image it currently contains. If it contains no image, set to
        #                   'undef'
        #   $filePath   - Full path to the file containing the image to be displayed (or 'undef' if
        #                   not using a file)
        #   $pixBuffer  - A Gtk2::Gdk::Pixbuf  containing the image to be displayed (or 'undef'
        #                   if not using a pixbuf)
        #
        # Return values
        #   'undef' on improper arguments, if the specified file doesn't exist or if a Gtk2::Image
        #       can't be created
        #   Otherwise returns the Gtk2::Image created, or 'undef' if none is created

        my ($self, $viewPort, $frame, $oldImage, $filePath, $pixBuffer, $check) = @_;

        # Check for improper arguments
        if ((! defined $viewPort && ! defined $frame) || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->changeImage', @_);
        }

        # Create a new Gtk2::Image
        my $newImage;
        if ($filePath) {
            $newImage = Gtk2::Image->new_from_file($filePath);
        } elsif ($pixBuffer) {
            $newImage = Gtk2::Image->new_from_pixbuf($pixBuffer);
        }

        if ($viewPort) {

            # Remove the old image from its viewport, if an old image was specified
            if ($oldImage) {

                $axmud::CLIENT->desktopObj->removeWidget($viewPort, $oldImage);
            }

            # Add the new image to the viewport, if a new image was created
            if ($newImage) {

                $viewPort->add($newImage);
            }

        } else {

            # Remove the old image from its frame, if an old image was specified
            if ($oldImage) {

                $axmud::CLIENT->desktopObj->removeWidget($frame, $oldImage);
            }

            # Add the new image to the frame, if a new image was created
            if ($newImage) {

                $frame->add($newImage);
            }
        }

        # Update the window to show the changes
        $self->winShowAll($self->_objClass . '->changeImage');

        return $newImage;       # May be 'undef'
    }

    sub addSimpleImage {

        # Adds a Gtk2::Image from a specified file at the specified position in a Gtk2::Table (but
        #   not inside a frame: call ->addImage to do that)
        #
        # Example calls:
        #   my $image = $self->addImage($table, $filePath, $pixBuffer,
        #       0, 12, 1, 12);
        #   my $image = $self->addImage($table, undef, undef,
        #       0, 12, 1, 12);
        #
        # Expected arguments
        #   $table          - The Gtk2::Table itself
        #   $filePath       - Full path to the file containing the image to be displayed (or 'undef'
        #                       if not using a file)
        #   $pixBuffer      - A Gtk2::Gdk::Pixbuf  containing the image to be displayed (or 'undef'
        #                       if not using a pixbuf)
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #                   - The position of the frame in the table
        #
        # Return values
        #   'undef' on improper arguments or if a $filePath is specified which doesn't exist
        #   Otherwise the Gtk2::Image created

        my (
            $self, $table, $filePath, $pixBuffer, $leftAttach, $rightAttach, $topAttach,
            $bottomAttach, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $leftAttach || ! defined $rightAttach
            || ! defined $topAttach || ! defined $bottomAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addSimpleImage', @_);
        }

        # Check that the position in the table makes sense, and that filename (if specified) exists
        if (
            ! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)
            || (defined $filePath && ! -e $filePath)
        ) {
            return undef;
        }

        # Create the Gtk2::Image
        my $image;
        if ($filePath) {
            $image = Gtk2::Image->new_from_file($filePath);
        } elsif ($pixBuffer) {
            $image = Gtk2::Image->new_from_pixbuf($pixBuffer);
        }

        if ($image) {

            # Add the image to the table
            $table->attach_defaults(
                $image,
                $leftAttach,
                $rightAttach,
                $topAttach,
                $bottomAttach,
            );
        }

        return $image;
    }

    sub addDrawingArea {

        # Creates a GA::Obj::DrawingArea to handle a Gtk2::DrawingArea of a specified size for
        #   drawing
        #
        # Example calls:
        #   $self->addDrawingArea($table, '',
        #       undef, undef, undef,
        #       FALSE, FALSE,,
        #       0, 12, 1, 12);
        #   $self->addDrawingArea($table, 'black_gc',
        #       'configureFunc', 'motionFunc', 'clickFunc',
        #       TRUE, TRUE,
        #       0, 12, 1, 12,
        #       300, 200);
        #
        # Expected arguments
        #   $table          - The tab's Gtk2::Table object
        #   $colour         - Background colour - 'white_gc', 'black_gc', etc (if an empty string,
        #                       'white_gc' is used)
        #   $initialFunc    - A function to call during setup, in order to do any initial drawing.
        #                       If 'undef', no function is called
        #   $clickFunc      - A function to call whenever the user clicks on the drawing area (which
        #                       emits the 'button-press-event' signal). If 'undef', the signal is
        #                       ignored
        #   $motionFunc     - A function to call whenever mouse motion over the drawing area is
        #                       detected (due to the motion-notify-event signal). If 'undef', the
        #                       signal is ignored
        #   $scrollHorizFlag, $scrollVertFlag
        #                   - Flags set to TRUE if the scolled window, in which the drawing area
        #                       appears, scrolls; set to FALSE otherwise
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #                   - The position of the entry in the table
        #
        # Optional arguments
        #   $width, $height - The width and height of the pixmap, in pixels. If not specified, a
        #                       default size of 300x200 is used
        #
        # Return values
        #   'undef' on improper arguments, or if a GA::Obj::DrawingArea can't be created
        #   Otherwise returns the GA::Obj::DrawingArea created

        my (
            $self, $table, $colour, $initialFunc, $clickFunc, $motionFunc, $scrollHorizFlag,
            $scrollVertFlag, $leftAttach, $rightAttach, $topAttach, $bottomAttach, $width, $height,
            $check
        ) = @_;

        # Local variables
        my $drawingAreaObj;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $colour || ! defined $scrollHorizFlag
            || ! defined $scrollVertFlag || ! defined $leftAttach || ! defined $rightAttach
            || ! defined $topAttach || ! defined $bottomAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addDrawingArea', @_);
        }

        # Check that the position in the table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return undef;
        }

        # Create a GA::Obj::DrawingArea to store all the values needed by the various drawing
        #   functions supplied by GA::Generic::EditWin
        $drawingAreaObj = Games::Axmud::Obj::DrawingArea->new();
        if (! $drawingAreaObj) {

            return undef;
        }

        # Set default width/height, if necessary
        if (! defined $width) {

            $width = 300;
        }

        if (! defined $height) {

            $height = 200;
        }

        # Set the default background colour, if not specified
        if (! $colour) {

            $colour = 'white_gc';
        }

        # Create a scrolled window
        my $scrolledWin = Gtk2::ScrolledWindow->new();
        $scrolledWin->set_size_request($width, $height);
        my $hAdjustment = $scrolledWin->get_hadjustment();
        $scrolledWin->set_border_width(3);

        # Set the scrolling policy
        if ($scrollHorizFlag && $scrollVertFlag) {
            $scrolledWin->set_policy('always','always');
        } elsif ($scrollHorizFlag) {
            $scrolledWin->set_policy('always', 'never');
        } elsif ($scrollVertFlag) {
            $scrolledWin->set_policy('never', 'always');
        } else {
            $scrolledWin->set_policy('never', 'never');
        }

        # Create a viewport
        my $viewPort = Gtk2::Viewport->new(undef,undef);
        # Add the viewport to the scrolled window
        $scrolledWin->add($viewPort);
        # Add the scrolled window to the table
        $table->attach_defaults($scrolledWin, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        # Create the drawing area
        my $drawingArea = Gtk2::DrawingArea->new();

        # Add an event box for detecting the user's mouse
        my $eventBox = Gtk2::EventBox->new();
        $eventBox->add($drawingArea);
        $eventBox->add_events(['pointer-motion-mask', 'pointer-motion-hint-mask']);

        # Detect mouse clicks over the drawing area
        $eventBox->signal_connect ('button-press-event' => sub {

            my ($widget, $event) = @_;

            if (! $clickFunc) {

                return undef;

            } else {

                # Inform the specified function of the co-ords of the mouse above the drawing area
                return $self->$clickFunc($drawingAreaObj, $event->x, $event->y);
            }
        });

        # Detect mouse motion over the drawing area
        $eventBox->signal_connect ('motion-notify-event' => sub {

            my ($widget, $event) = @_;

            if (! $motionFunc) {

                return undef;

            } else {

                # Inform the specified function of the co-ords of the mouse above the drawing area
                return $self->$motionFunc($drawingAreaObj, $event->x, $event->y);
            }
        });

        # Add the event box, containing the drawing area, to the viewport
        $viewPort->add($eventBox);

        # Set IVs in the Games::Axmud::Obj::DrawingArea
        $drawingAreaObj->ivPoke('width', $width);
        $drawingAreaObj->ivPoke('height', $height);
        $drawingAreaObj->ivPoke('scrolledWin', $scrolledWin);
        $drawingAreaObj->ivPoke('hAdjustment', $hAdjustment);
        $drawingAreaObj->ivPoke('viewPort', $viewPort);
        $drawingAreaObj->ivPoke('drawingArea', $drawingArea);
        $drawingAreaObj->ivPoke('eventBox', $eventBox);

        # Set events for the drawing area
        $drawingArea->set_events ([
            'exposure-mask',
            'leave-notify-mask',
            'button-press-mask',
            'pointer-motion-mask',
            'pointer-motion-hint-mask',
        ]);

        # Two signals used to handle the backing pixmap
        $drawingArea->signal_connect('expose_event' => sub {

            # Redraw the screen from the backing pixmap

            my $widget = shift;    # GtkWidget      *widget
            my $event  = shift;    # GdkEventExpose *event

            $widget->window->draw_drawable(
                $widget->style->fg_gc($widget->state),
                $drawingAreaObj->pixmap,
                $event->area->x,
                    $event->area->y,
                $event->area->x,
                    $event->area->y,
                $event->area->width,
                    $event->area->height,
            );

            return FALSE;
        });

        $drawingArea->signal_connect('configure_event' => sub {

            # Create a new backing pixmap of the appropriate size

            my $widget = shift;    # GtkWidget         *widget
            my $event  = shift;    # GdkEventConfigure *event

            # Local variables
            my ($pixmap, $graphicsContext, $colourMap);

            # Create a pixmap
            $pixmap = Gtk2::Gdk::Pixmap->new(
                $widget->window,
                $widget->allocation->width,
                $widget->allocation->height,
                -1,
            );

            $pixmap->draw_rectangle(
                $widget->style->$colour,
                TRUE,
                0, 0,
                $widget->allocation->width,
                $widget->allocation->height,
            );

            # Create a GDK graphics context
            $graphicsContext = Gtk2::Gdk::GC->new($pixmap);

            # Create a colour map
            $colourMap = $pixmap->get_colormap();

            # Store these objects
            $drawingAreaObj->ivPoke('pixmap', $pixmap);
            $drawingAreaObj->ivPoke('graphicsContext', $graphicsContext);
            $drawingAreaObj->ivPoke('colourMap', $colourMap);

            # Set a default foreground colour
            $graphicsContext->set_foreground($drawingAreaObj->getColour('black'));

            # Now draw something!
            if ($initialFunc) {

                $self->$initialFunc($drawingAreaObj);
            }

            return TRUE;
        });

        return $drawingAreaObj;
    }

    sub addSimpleCanvas {

        # Adds a Gnome2::Canvas to the table which is coloured in, using a single colour
        # (Call $self->fillSimpleCanvas to change the colour)
        #
        # Example calls:
        #   my ($frame, $canvas, $canvasObj) = $self->addSimpleCanvas($table, '#FF0000', '#FFFFFF',
        #       6, 7, 6, 7,
        #       50, 50);
        #   my ($frame, $canvas, $canvasObj) = $self->addSimpleCanvas($table, 'red', undef,
        #       6, 7, 6, 7);
        #
        # Expected arguments
        #   $table          - The Gtk2::Table displayed in the current tab
        #   $colour         - The initial colour of the canvas. Can be any valid Axmud colour tag
        #                       (e.g. 'red', 'x255', '#FF0000')
        #   $noColour       - If $colour is not specified or if it is invalid, this colour is used.
        #                       If $noColour is also not specified or invalid, then no colour is
        #                       drawn (no canvas object is drawn on the canvas)
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #                   - The position of the canvas in the table
        #
        # Optional arguments
        #   $width, $height - The size, in pixels, of the canvas. If not specified, a default size
        #                       of 30x30 is used
        #
        # Return values
        #   An empty list on improper arguments or if the table coordinates don't make sense
        #   Otherwise, a list in the form
        #       (Gtk2::Frame, Gnome2::Canvas, Gnome2::Canvas::Rect)
        #   ...where the last value will be 'undef' if no colour was drawn

        my (
            $self, $table, $colour, $noColour, $leftAttach, $rightAttach, $topAttach, $bottomAttach,
            $width, $height, $check
        ) = @_;

        # Local variables
        my (
            $type, $canvasObj,
            @emptyList,
        );

        # Check for improper arguments
        if (
            ! defined $table || ! defined $leftAttach || ! defined $rightAttach
            || ! defined $topAttach || ! defined $bottomAttach || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->addSimpleCanvas', @_);
            return @emptyList;
        }

        # Check that the position in table makes sense
        if (! $self->checkPosn($leftAttach, $rightAttach, $topAttach, $bottomAttach)) {

            return @emptyList;
        }

        # Use default $colour/width/height, if not specified
        if ($colour) {

            ($type) = $axmud::CLIENT->checkColourTags($colour);
        }

        if (! $colour || ! $type ) {

            # Check the neutral colour
            if ($noColour) {

                ($type) = $axmud::CLIENT->checkColourTags($noColour);
            }

            if (! $type) {

                # No colour is drawn
                $colour = undef;

            } else {

                # Use the neutral colour
                $colour = $noColour;
            }
        }

        # Make sure we have an RGB tag, not a different kind of colour tag
        if ($colour) {

            $colour = $axmud::CLIENT->returnRGBColour($colour);
        }

        # Use default width/height, if values not specified
        if (! $width) {

            $width = 30;
        }

        if (! $height) {

            $height = 30;
        }

        # Create a frame
        my $frame = Gtk2::Frame->new(undef);
        $frame->set_border_width(0);
        $frame->set_size_request($width, $height);

        # Create the canvas
        my $canvas = Gnome2::Canvas->new();
        # Set the canvas size
        $canvas->set_scroll_region(0, 0, $width, $height);
        # Add the canvas to the frame
        $frame->add($canvas);

        # Add the frame to the table
        $table->attach_defaults($frame, $leftAttach, $rightAttach, $topAttach, $bottomAttach);

        # Fill the canvas with colour (if a colour was specified)
        if ($colour) {

            $canvasObj = $self->fillSimpleCanvas($canvas, undef, $colour, $width, $height);
        }

        return ($frame, $canvas, $canvasObj);
    }

    sub fillSimpleCanvas {

        # Sets the background colour of the canvas drawn in the earlier call to
        #   $self->addSimpleCanvas
        #
        # Expected arguments
        #   $canvas         - The existing Gnome2::Canvas
        #
        # Optional arguments
        #   $oldObj         - The existing Gnome2::Canvas::Rect, if there is one. Set to 'undef' if
        #                       this function is being called by $self->addSimpleCanvas, or if no
        #                       colour was drawn on the earlier call to ->addSimpleCanvas
        #   $colour         - The colour to draw on the canvas. Can be any valid Axmud colour tag
        #                       (e.g. 'red', 'x255', '#FF0000')
        #   $noColour       - If $colour is not specified or if it is invalid, this colour is used.
        #                       If $noColour is also not specified or invalid, then no colour is
        #                       drawn (no canvas object is drawn on the canvas)
        #
        # Optional arguments
        #   $width, $height - The size, in pixels, of the canvas. If not specified, a default size
        #                       of 30x30 is used
        #
        # Return values
        #   'undef' on improper arguments
        #   The replacement Gnome2::Canvas::Rect otherwise

        my ($self, $canvas, $oldObj, $colour, $noColour, $width, $height, $check) = @_;

        # Local variables
        my ($type, $partX, $partY, $canvasObj);

        # Check for improper arguments
        if (! defined $canvas || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->fillSimpleCanvas', @_);
        }

        # Use default $colour/width/height, if not specified
        if ($colour) {

            ($type) = $axmud::CLIENT->checkColourTags($colour);
        }

        if (! $colour || ! $type ) {

            # Check the neutral colour
            if ($noColour) {

                ($type) = $axmud::CLIENT->checkColourTags($noColour);
            }

            if (! $type) {

                # No colour is drawn
                $colour = undef;

            } else {

                # Use the neutral colour
                $colour = $noColour;
            }
        }

        # Make sure we have an RGB tag, not a different kind of colour tag
        if ($colour) {

            $colour = $axmud::CLIENT->returnRGBColour($colour);
        }

        # Use default width/height, if values not specified
        if (! $width) {

            $width = 30;
        }

        if (! $height) {

            $height = 30;
        }

        # Destroy the old background rectangle, if there is one
        if ($oldObj) {

            $oldObj->destroy();
        }

        # Draw the canvas object (if a colour was specified)
        if ($colour) {

            # The actual size and position is a little smaller, so that the whole of the canvas is
            #   visible, without the frame getting in the way
            # v1.0.694 - not possible to use the same trick as we used with 'main' window gauges, to
            #   get the canvas object lined up perfectly in the middle. These x/y coordinates
            #   produce something reasonable close
            $partX = int($width / 10);
            $partY = int($height / 10);

            $canvasObj = Gnome2::Canvas::Item->new(
                $canvas->root(),
                'Gnome2::Canvas::Rect',
                x1 => $partX,
                y1 => $partY,
                x2 => ($width - $partX),
                y2 => ($height - ($partY * 2)),
                fill_color => $colour,
                outline_color => '#000000',     # Black
            );

            $canvasObj->lower_to_bottom();
        }

        # Drawing complete
        return $canvasObj;
    }

    # Support functions for adding widgets

    sub checkPosn {

        # Called by $self->addLabel, etc
        # Checks the position of a widget in the Gtk2::Table, to make sure the coordinates make
        #   sense (that the right coordinate isn't lower than the left coordinate, for example)
        #
        # Expected arguments
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #       - The coordinates of the object in the page's table
        #
        # Return values
        #   'undef' on improper arguments or if the coordinates don't make sense
        #   1 otherwise

        my ($self, $leftAttach, $rightAttach, $topAttach, $bottomAttach, $check) = @_;

        # Local variables
        my ($tableWidth, $tableHeight);

        # Check for improper arguments
        if (
            ! defined $leftAttach || ! defined $rightAttach || ! defined $topAttach
            || ! defined $bottomAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkPosn', @_);
        }

        # In case this window doesn't have ->tableWidth and ->tableHeight IVs (I'm looking at you,
        #   GA::Win::Map!), use some failsafe values
        if (! exists $self->{tableWidth}) {

            # A 12x13 table, with a spare cell around every border)
            $tableWidth = 13;
            $tableHeight = 14;

        } else {

            $tableWidth = $self->{tableWidth};
            $tableHeight = $self->{tableHeight};
        }

        # Check coordinates
        if (
            $leftAttach < 0 || $topAttach < 0
            || $rightAttach > $tableWidth
            || $bottomAttach > $tableHeight
            || $rightAttach < $leftAttach || $bottomAttach < $topAttach
        ) {
            return $self->writeWarning(
                'Bad table coordinates in \'' . $self->winType . '\' window: '
                . $leftAttach . ' '
                . $rightAttach . ' '
                . $topAttach . ' '
                . $bottomAttach,
                $self->_objClass . '->checkPosn',
            );

        } else {

            return 1;
        }
    }

    ##################
    # Accessors - set

    sub add_childDestroy {

        # Called by anything

        my ($self, $winObj, $func, $argListRef, $check) = @_;

        # Local variables
        my $listRef;

        # Check for improper arguments
        if (! defined $winObj || ! defined $func || ! defined $argListRef || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_childDestroy', @_);
        }

        if (! $self->ivExists('childFreeWinHash', $winObj->number)) {

            return undef;

        } else {

            if ($self->ivExists('childDestroyHash', $winObj->number)) {

                $listRef = $self->ivShow('childDestroyHash', $winObj->number);
                push (@$listRef, $func, $argListRef);

            } else {

                $self->ivAdd(
                    'childDestroyHash',
                    $winObj->number,
                    [$func, $argListRef],
                );
            }

            return 1;
        }
    }

    sub add_childFreeWin {

        # Called by $self->createFreeWin

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_childFreeWin', @_);
        }

        $self->ivAdd('childFreeWinHash', $obj->number, $obj);

        return 1;
    }

    sub del_childFreeWin {

        # Called by GA::Generic::FreeWin->winDestroy

        my ($self, $obj, $check) = @_;

        # Local variables
        my $listRef;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_childFreeWin', @_);
        }

        if (! $self->ivExists('childFreeWinHash', $obj->number)) {

            return undef;

        } else {

            # Call some of this window's own functions to obj->number various widgets/IVs
            $listRef = $self->ivShow('childDestroyHash', $obj->number);
            if (defined $listRef) {

                do {

                    my ($func, $argListRef);

                    $func = shift @$listRef;
                    $argListRef = shift @$listRef;

                    if (defined $func && defined $argListRef) {

                        $self->$func(@$argListRef);
                    }

                } until (! @$listRef);
            }

            # Update IVs
            $self->ivDelete('childFreeWinHash', $obj->number);
            $self->ivDelete('childDestroyHash', $obj->number);

            return 1;
        }
    }

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

    sub set_owner {

        my ($self, $owner, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_owner', @_);
        }

        $self->ivPoke('owner', $owner);

        return 1;
    }

    sub set_session {

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_session', @_);
        }

        $self->ivPoke('session', $session);

        return 1;
    }

    sub set_winBox {

        my ($self, $winBox, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_winBox', @_);
        }

        $self->ivPoke('winBox', $winBox);

        return 1;
    }

    sub set_winWidget {

        my ($self, $winWidget, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_winWidget', @_);
        }

        $self->ivPoke('winWidget', $winWidget);

        return 1;
    }

    sub set_wnckWin {

        my ($self, $wnckWin, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_wnckWin', @_);
        }

        $self->ivPoke('wnckWin', $wnckWin);

        return 1;
    }

    sub set_workspaceObj {

        my ($self, $workspaceObj, $check) = @_;

        # Check for improper arguments
        if (! defined $workspaceObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_workspaceObj', @_);
        }

        $self->ivPoke('workspaceObj', $workspaceObj);

        return 1;
    }

    sub set_workspaceGridObj {

        my ($self, $gridObj, $check) = @_;

        # Check for improper arguments
        if (! defined $gridObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_workspaceGridObj', @_);
        }

        $self->ivPoke('workspaceGridObj', $gridObj);

        return 1;
    }

    ##################
    # Accessors - get

    sub number
        { $_[0]->{number} }
    sub winCategory
        { $_[0]->{winCategory} }
    sub winType
        { $_[0]->{winType} }
    sub winName
        { $_[0]->{winName} }
    sub workspaceObj
        { $_[0]->{workspaceObj} }
    sub owner
        { $_[0]->{owner} }
    sub session
        { $_[0]->{session} }
    sub pseudoCmdMode
        { $_[0]->{pseudoCmdMode} }

    sub winWidget
        { $_[0]->{winWidget} }
    sub winBox
        { $_[0]->{winBox} }
    sub wnckWin
        { $_[0]->{wnckWin} }
    sub enabledFlag
        { $_[0]->{enabledFlag} }
    sub visibleFlag
        { $_[0]->{visibleFlag} }
    sub childFreeWinHash
        { my $self = shift; return %{$self->{childFreeWinHash}}; }
    sub childDestroyHash
        { my $self = shift; return %{$self->{childDestroyHash}}; }

    sub packingBox
        { $_[0]->{packingBox} }
}

{ package Games::Axmud::Generic::WizWin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of a 'wiz' window
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - A string to use as the window title. If 'undef', a generic title is
        #                       used
        #   $editObj        - Ignored if set
        #   $tempFlag       - Ignored if set
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'wiz' window; for example, for example,
        #                       GA::PrefWin::TaskStart uses it to specify a task name and type. Set
        #                       to an empty hash if not required
        #                   - This type of window object recognises these initialisation settings:
        #
        #                       ...
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Set the values to use for some standard window IVs
        if (! $title) {

            $title = 'Wizard window';
        }

        # Setup
        my $self = {
            _objName                    => 'wiz_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => 'wiz',
            # A name for the window (for 'config' windows, the same as the window type)
            winName                     => 'wiz',
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,       # Gtk2::VBox

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $axmud::CLIENT->constFreeWinWidth,
            heightPixels                => $axmud::CLIENT->constFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $title,
            # Hash containing any number of key-value pairs needed for this particular 'wiz'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # Standard IVs for 'wiz' windows

            # Widgets
            scroller                    => undef,       # Gtk2::ScrolledWindow
            hAdjustment                 => undef,       # Gtk2::Adjustment
            vAdjustment                 => undef,       # Gtk2::Adjustment
            table                       => undef,       # Gtk2::Table
            hBox                        => undef,       # Gtk2::HBox
            tooltips                    => undef,       # Gtk2::Tooltips
            nextButton                  => undef,       # Gtk2::Button
            previousButton              => undef,       # Gtk2::Button
            cancelButton                => undef,       # Gtk2::Button

            # The default size of the table on each page
            tableWidth                  => 12,
            tableHeight                 => 32,

            # Three flags that can be set by any page, to prevent one of three buttons from being
            #   made sensitive (temporarily)
            disableNextButtonFlag       => FALSE,
            disablePreviousButtonFlag   => FALSE,
            disableCancelButtonFlag     => FALSE,

            # The names of pages, in order of appearance
            pageList                    => [
#               'example',       # Corresponds to function $self->examplePage
#               'example2',
#               'example3',
            ],
            # The number of the current page (first page is 0)
            currentPage                 => 0,

            # Two hashes for using the 'Next' / 'Previous' buttons to skip around the pages, rather
            #   than going to the actual next or previous page (as normal)
            # The current page should add an entry to the hash, if necessary; the entry is removed
            #   by ->buttonPrevious or ->buttonNext as soon as either button is clicked
            # Hashes in the form
            #   $hash{current_page_number} = page_number_if_button_clicked
            # NB The first page's number is 0, so the fourth page will be page 3, not page 4
            specialNextButtonHash       => {},
            specialPreviousButtonHash   => {},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}         # Inherited from GA::Generic::FreeWin

    sub winEnable {

        # Called by GA::Generic::Win->createFreeWin, after the call to $self->winSetup
        # After the Gtk2::Window has been setup and moved into position, makes it visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Make the window appear on the desktop
        $self->winShowAll($self->_objClass . '->winEnable');
        $self->ivPoke('enabledFlag', TRUE);

        # This type of window is usually unique to its GA::Session (only one can be open at any
        #   time, per session); inform the session it has opened
        # Exception - if $self->session isn't set at all (presumably because there are no sessions
        #   running), then there's no-one to inform
        if ($self->session) {

            $self->session->set_wizWin($self);
        }

        return 1;
    }

#   sub winDesengage {}     # Inherited from GA::Generic::FreeWin

    sub winDestroy {

        # Can be called by anything
        # Updates IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the window can't be destroyed or if it has already
        #       been destroyed
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winDestroy', @_);
        }

        if (! $self->winBox) {

            # Window already destroyed in a previous call to this function
            return undef;
        }

        # Close any 'free' windows for which this window is a parent
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Destroy the Gtk2::Window
        eval { $self->winBox->destroy(); };
        if ($@) {

            # Window can't be destroyed
            return undef;

        } else {

            $self->ivUndef('winWidget');
            $self->ivUndef('winBox');
        }

        # Inform the owner and the desktop object of this 'free' window's demise
        $axmud::CLIENT->desktopObj->del_freeWin($self);
        if ($self->owner) {

            $self->owner->del_childFreeWin($self);
        }

        # This type of window is usually unique to its GA::Session (only one can be open at any
        #   time, per session); inform the session it has closed
        # Exception - if $self->session isn't set at all (presumably because there are no sessions
        #   running), then there's no-one to inform
        if ($self->session) {

            $self->session->set_wizWin();
        }

        return 1;
    }

#   sub winShowAll {}       # Inherited from GA::Generic::Win

    sub drawWidgets {

        # Called by $self->winSetup
        # Sets up the 'wiz' window with its standard widgets
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWidgets', @_);
        }

        # Create a packing box
        my $packingBox = Gtk2::VBox->new(FALSE, 0);
        $self->winBox->add($packingBox);
        $packingBox->set_border_width(0);

        # Add a table (inside a scrolled window) in the higher area
        my $scroller = Gtk2::ScrolledWindow->new(undef, undef);
        $packingBox->pack_start($scroller, TRUE, TRUE, 0);
        $scroller->set_policy('never', 'automatic');
        $scroller->set_border_width(5);

        my $table = Gtk2::Table->new($self->tableHeight, $self->tableWidth, FALSE);
        $scroller->add_with_viewport($table);
        $table->set_col_spacings($self->spacingPixels);
        $table->set_row_spacings($self->spacingPixels);
        $table->set_border_width($self->borderPixels);

        # Add a button strip at the bottom, in a horizontal packing box
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $packingBox->pack_end($hBox, FALSE, FALSE, 5);

        # Create a Gtk2::Tooltips object, to be used by buttons on all tabs in this window
        my $tooltips = Gtk2::Tooltips->new();

        # Create 'Next'/'Previous'/'Cancel' buttons
        my ($nextButton, $previousButton, $cancelButton) = $self->enableButtons($hBox, $tooltips);

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('scroller', $scroller);
        $self->ivPoke('hAdjustment', $scroller->get_hadjustment());
        $self->ivPoke('vAdjustment', $scroller->get_vadjustment());
        $self->ivPoke('table', $table);
        $self->ivPoke('hBox', $hBox);
        $self->ivPoke('tooltips', $tooltips);
        $self->ivPoke('nextButton', $nextButton);
        $self->ivPoke('previousButton', $previousButton);
        $self->ivPoke('cancelButton', $cancelButton);

        # Set up the table with its initial contents
        $self->setupTable();

        return 1;
    }

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

    sub enableButtons {

        # Called by $self->drawWidgets
        # Creates the Next/Previous/Cancel buttons at the bottom of the window
        # Individual 'wiz' windows almost always inherit the generic ->winEnable method, but can
        #   use their own $self->enableButtons (rather than inherit this one) if they need
        #   a different set of buttons
        #
        # Expected arguments
        #   $hBox       - The horizontal packing box in which the buttons live (not yet stored as
        #                   an IV)
        #   $tooltips   - A Gtk2::Tooltips object for the buttons (not yet stored as an IV)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, a list containing the three Gtk::Button objects created

        my ($self, $hBox, $tooltips, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (! defined $hBox || ! defined $tooltips || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->enableButtons', @_);
            return @emptyList;
        }

        # Create the Next button - which also acts as a 'Finish' button once the user has
        #   finished making changes
        my $nextButton = Gtk2::Button->new('Next');
        $hBox->pack_end($nextButton, 0, 0, $self->borderPixels);
        $nextButton->get_child->set_width_chars(10);
        $nextButton->signal_connect('clicked' => sub {

            $self->buttonNext();
        });
        $tooltips->set_tip($nextButton, 'Move on to the next page');

        # Create the Previous button
        my $previousButton = Gtk2::Button->new('Previous');
        $hBox->pack_end($previousButton, 0, 0, $self->spacingPixels);
        $previousButton->get_child->set_width_chars(10);
        $previousButton->signal_connect('clicked' => sub {

            $self->buttonPrevious();
        });
        $tooltips->set_tip($previousButton, 'Go back to the previous page');
        $previousButton->set_sensitive(FALSE);    # Because 1st page is showing, starts desensitised

        # Create the Cancel button
        my $cancelButton = Gtk2::Button->new('Cancel');
        $hBox->pack_start($cancelButton, 0, 0, $self->borderPixels);
        $cancelButton->get_child->set_width_chars(10);
        $cancelButton->signal_connect('clicked' => sub {

            $self->buttonCancel();
        });
        $tooltips->set_tip($cancelButton, 'Cancel changes and close this window');

        return ($nextButton, $previousButton, $cancelButton);
    }

    sub setupTable {

        # Called by $self->winEnable
        # Creates the first page for the wizard (not really necessary to have a whole function
        #   dedicated to this task, but having one keeps the design of 'wiz' windows consistent
        #   with the design of 'edit'/'pref' windows)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($func, $rows);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupTable', @_);
        }

        # Get the name of the function for the first page
        $func = $self->ivIndex('pageList', $self->currentPage) . 'Page';
        # Call the function
        $rows = $self->$func();

        if (defined $rows) {

            # Resize the table, using the default width, but only as many rows as we actually need
            $self->table->resize($rows, $self->tableWidth);
        }

        return 1;
    }

    sub expandTable {

        # Called by $self->buttonPrevious and ->buttonNext
        # Changes the page currently visible in the 'wiz' window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($func, $rows);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->expandTable', @_);
        }

        # Empty the table used for the existing page
        foreach my $widget ($self->table->get_children()) {

            $axmud::CLIENT->desktopObj->removeWidget($self->table, $widget);
        }

        # Get the name of the function for the new current page
        $func = $self->ivIndex('pageList', $self->currentPage) . 'Page';
        # Call the function
        $rows = $self->$func();

        if (defined $rows) {

            # Resize the table, using the default width, but only as many rows as we actually need
            $self->table->resize($rows, $self->tableWidth);
        }

        # Set button sensititives ($self->disableNextButtonFlag, etc, override the usual rules, if
        #   they are set)

        # If it's the first page, the 'Previous' button must not be sensitive
        if ($self->currentPage == 0) {

            $self->previousButton->set_sensitive(FALSE);

            if (! $self->disableNextButtonFlag) {
                $self->nextButton->set_sensitive(TRUE);
            } else {
                $self->nextButton->set_sensitive(FALSE);
            }

            # Make sure the 'Next' button has the right label
            $self->nextButton->set_label('Next');
            $self->nextButton->get_child->set_width_chars(10);

        # If it's the last page, the 'Next' button must be converted to a 'Finish' button
        } elsif ($self->currentPage >= ((scalar $self->pageList) - 1)) {

            if (! $self->disablePreviousButtonFlag) {
                $self->previousButton->set_sensitive(TRUE);
            } else {
                $self->previousButton->set_sensitive(FALSE);
            }

            $self->nextButton->set_sensitive(TRUE);
            $self->nextButton->set_label('Finish');
            $self->nextButton->get_child->set_width_chars(10);

        # For all other pages, both buttons are sensitised
        } else {

            if (! $self->disableNextButtonFlag) {
                $self->nextButton->set_sensitive(TRUE);
            } else {
                $self->nextButton->set_sensitive(FALSE);
            }

            if (! $self->disablePreviousButtonFlag) {
                $self->previousButton->set_sensitive(TRUE);
            } else {
                $self->previousButton->set_sensitive(FALSE);
            }

            # Make sure the 'Next' button has the right label
            $self->nextButton->set_label('Next');
            $self->nextButton->get_child->set_width_chars(10);
        }

        # Reset the disable flags. It's up to individual pages to set them, when they're needed
        $self->ivPoke('disableNextButtonFlag', FALSE);
        $self->ivPoke('disablePreviousButtonFlag', FALSE);
        $self->ivPoke('disableCancelButtonFlag', FALSE);

        # Make sure the window has scrolled to the top
        $self->hAdjustment->set_value(0);
        $self->vAdjustment->set_value(0);

        # Make the page visible
        $self->winShowAll($self->_objClass . '->expandTable');

        return 1;
    }

    sub saveChanges {

        # Generic ->saveChanges function which doesn't do anything other than to close the 'wiz'
        #   window
        # Each 'wiz' window should have its own ->saveChanges function
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->saveChanges', @_);
        }

        # Close the 'wiz' window
        $self->winDestroy();

        return 1;
    }

    sub getPageString {

        # Can be called by any ->XXXPage function
        # Returns a string in the format 'page a/b', where 'a' is the number of the current page,
        #   and 'b' the number of the last page
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getPageString', @_);
        }

        return 'Page ' . ($self->currentPage + 1) . '/' . (scalar $self->pageList);
    }

    # Standard callbacks

    sub buttonCancel {

        # 'Cancel' button callback
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonCancel', @_);
        }

        # Close the window
        $self->winDestroy();

        return 1;
    }

    sub buttonPrevious {

        # 'Previous' button callback
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonPrevious', @_);
        }

        # Reset the hash of functions to call when a child window is closed, ready for it to be
        #   refilled
        $self->ivEmpty('childDestroyHash');

        # Has a special rule been set for the current page?
        if ($self->ivExists('specialPreviousButtonHash', $self->currentPage)) {

            # Go to the specified page, instead of the next one
            $self->ivPoke(
                'currentPage',
                $self->ivShow('specialPreviousButtonHash', $self->currentPage),
            );

        } elsif ($self->currentPage > 0) {

            # Just go to the previous page (unless, for some unlikely reason, we're already there)
            $self->ivDecrement('currentPage');
        }

        # Cancel any special rules - it's up to the new page to set them, as and when required
        $self->ivEmpty('specialNextButtonHash');
        $self->ivEmpty('specialPreviousButtonHash');

        # Display the page
        $self->expandTable();

        return 1;
    }

    sub buttonNext {

        # 'Next' button callback
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->buttonNext', @_);
        }

        # If we're on the last page, the 'Finish' button has been clicked
        if ($self->currentPage >= ((scalar $self->pageList) - 1)) {

            $self->saveChanges();

        # Otherwise, it's the 'Next' button. Set the next page
        } else {

            # Reset the hash of functions to call when a child window is closed, ready for it to be
            #   refilled
            $self->ivEmpty('childDestroyHash');

            # Has a special rule been set for the current page?
            if ($self->ivExists('specialNextButtonHash', $self->currentPage)) {

                # Go to the specified page, instead of the next one
                $self->ivPoke(
                    'currentPage',
                    $self->ivShow('specialNextButtonHash', $self->currentPage),
                );

            } else {

                # Just go to the next page
                $self->ivIncrement('currentPage');
            }

            # Cancel any special rules - it's up to the new page to set them, as and when required
            $self->ivEmpty('specialNextButtonHash');
            $self->ivEmpty('specialPreviousButtonHash');

            # Display the page
            $self->expandTable();
        }

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scroller
        { $_[0]->{scroller} }
    sub hAdjustment
        { $_[0]->{hAdjustment} }
    sub vAdjustment
        { $_[0]->{vAdjustment} }
    sub table
        { $_[0]->{table} }
    sub hBox
        { $_[0]->{hBox} }
    sub tooltips
        { $_[0]->{tooltips} }
    sub nextButton
        { $_[0]->{nextButton} }
    sub previousButton
        { $_[0]->{previousButton} }
    sub cancelButton
        { $_[0]->{cancelButton} }

    sub tableWidth
        { $_[0]->{tableWidth} }
    sub tableHeight
        { $_[0]->{tableHeight} }

    sub disableNextButtonFlag
        { $_[0]->{disableNextButtonFlag} }
    sub disablePreviousButtonFlag
        { $_[0]->{disablePreviousButtonFlag} }
    sub disableCancelButtonFlag
        { $_[0]->{disableCancelButtonFlag} }

    sub pageList
        { my $self = shift; return @{$self->{pageList}}; }
    sub currentPage
        { $_[0]->{currentPage} }

    sub specialNextButtonHash
        { my $self = shift; return %{$self->{specialNextButtonHash}}; }
    sub specialPreviousButtonHash
        { my $self = shift; return %{$self->{specialPreviousButtonHash}}; }
}

# Package must return true
1
