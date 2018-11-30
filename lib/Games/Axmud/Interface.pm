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
# Games::Axmud::Interface::XXX
# Code that handles interfaces (triggers, alias, macros, timers and hooks)

{ package Games::Axmud::Interface::Active;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Interface Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->injectInterface, ->createIndepInterface and ->createInterface
        # Creates a new instance of the active interface object
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Depending on which
        #   profiles are current ones, and how many current profiles have interfaces with the same
        #   name, an interface can be 'active' or 'inactive' and 'independent' or 'dependent'
        #
        # 'Independent' interfaces are normally created by the user, and stored in a cage associated
        #   with a particular profile
        # When a profile becomes a current profile, and provided that there are no other superior
        #   profile which have an interface with the same ->name, each of its interfaces becomes
        #   'active'
        # When an interface becomes active, GA::Session creates this object, copying into it the
        #   attributes from the parent GA::Interface::Trigger / ::Alias / ::Macro / ::Timer
        #   / ::Hook object
        # When the interface becomes inactive again, this object gets destroyed (but the parent
        #   interface continues to exist)
        #
        # 'Dependent' interfaces are normally created by parts of the Axmud code immediately before
        #   this object is created. As soon as this object becomes inactive, the parent
        #   dependent interface is destroyed, as well.
        #
        # Expected arguments
        #   $session        - The GA::Session which created this object
        #   $category       - 'trigger', 'alias', 'macro', 'timer' or 'hook'
        #   $indepFlag      - TRUE if the interface is 'independent' (when the interface fires, the
        #                       response depends on the value of the parent interface's
        #                       ->response IV)
        #                   - FALSE if the interface is 'dependent' (when the interface fires, the
        #                       ->response IV is ignored and, instead, a method call is made)
        #
        # Optional arguments
        #   $parent         - The inactive interface (a GA::Interface::Trigger etc object) whose
        #                       attributes are copied into this one; specified when the calling
        #                       function is GA::Session->injectInterface. If 'undef', attributes
        #                       must be set by the calling function
        #   $assocProf      - The inactive interface's associated profile, specified when the
        #                       calling function is GA::Session->injectInterface ('undef'
        #                       otherwise)
        #   $assocProfCategory
        #                   - If $assocProf is specified, its category ('undef' otherwise)
        #
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $session, $category, $indepFlag, $parent, $assocProf, $assocProfCategory,
            $check,
        ) = @_;

        # Local variables
        my $modelObj;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $category || ! defined $indepFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'active_interface',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # The parent GA::Session object
            session                     => $session,
            # The parent inactive interface (if any)
            parent                      => $parent,

            # Interface IVs
            # -------------

            # A unique name (within the session) for this active interface (max 32 chars)
            name                        => undef,       # Set below or by the calling function
            # The interface's number (matches a key in GA::Session->interfaceNumHash)
            number                      => undef,       # Set by GA::Session->addInterface
            # The category of interface ('trigger', 'alias', 'macro', 'timer' or 'hook')
            category                    => $category,
            # TRUE if an independent interface, FALSE if dependent
            indepFlag                   => $indepFlag,

            # Standard attributes (inherited from the parent)
            stimulus                    => undef,       # Set below or by the calling function
            response                    => undef,       # Set below or by the calling function
            enabledFlag                 => undef,       # Set below or by the calling function

            # Category-dependent attributes
            attribHash                  => {},          # Set below or by the calling function

            # Independent interface IVs
            # Blessed reference of the associated profile (if any)
            assocProf                   => undef,       # Set below or by the calling function
            # The associated profile's category (if there is an associated profile)
            assocProfCategory           => undef,       # Set below or by the calling function

            # Dependent interface IVs (used in place of ->response)
            callClass                   => undef,       # Set by the calling function
            callMethod                  => undef,       # Set by the calling function

            # A hash of properties, whose keys and values can be set to anything, and checked
            #   by anything when the interface fires
            propertyHash                => {},
        };

        # Bless the object into existence
        bless $self, $class;

        # If a parent inactive interface was specified, copy its attributes to this object
        if ($parent) {

            $self->{name} = $parent->name;
            $self->{stimulus} = $parent->stimulus;
            $self->{response} = $parent->response;
            $self->{enabledFlag} = $parent->enabledFlag;

            $self->{attribHash} = {$parent->attribHash};

            $self->{assocProf} = $assocProf;
            $self->{assocProfCategory} = $assocProfCategory;

        } else {

            # When there's no parent inactive interface, we need to set ->attribHash (so that the
            #   call from GA::Session->setupInterface to $self->modifyAttribs will work - the rest
            #   of the IVs are set by GA::Session->setupInterface)
            $modelObj = $axmud::CLIENT->ivShow('interfaceModelHash', $category);
            $self->{attribHash} = {$modelObj->optionalAttribHash};
        }

        return $self;
    }

    ##################
    # Methods

    sub becomeEnabled {

        # Called by $self->set_enabledFlag and GA::Generic::Cmd->modifyInterface
        # When a disabled active timer interface becomes enabled, we need to reset a few IVs
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->becomeEnabled', @_);
        }

        if ($self->category eq 'timer') {

            # If the timer fires every second, but has been disabled for 30 seconds, enabling it
            #   will cause the timer to fire 30 times while it tries to catch up
            # The next firing time should be $self->stimulus seconds after now (actually,
            #   $self->stimulus seconds after the last spin of the timer loop
            $self->session->ivAdd(
                'timerHash',
                $self->number,
                ($self->session->sessionTime + $self->stimulus),
            );
        }

        return 1;
    }

    ##################
    # Accessors - set

    sub set_callClass {

        my ($self, $callClass, $check) = @_;

        # Check for improper arguments
        if (! defined $callClass || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_callClass', @_);
        }

        $self->ivPoke('callClass', $callClass);

        return 1;
    }

    sub set_callMethod {

        my ($self, $callMethod, $check) = @_;

        # Check for improper arguments
        if (! defined $callMethod || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_callMethod', @_);
        }

        $self->ivPoke('callMethod', $callMethod);

        return 1;
    }

    sub set_enabledFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_enabledFlag', @_);
        }

        if ($flag) {

            if (! $self->enabledFlag) {

                # Disabled timers need to have some IVs set when they become enabled
                $self->becomeEnabled();
            }

            $self->ivPoke('enabledFlag', TRUE);

        } else {

            $self->ivPoke('enabledFlag', FALSE);
        }

        return 1;
    }

    sub set_number {

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_number', @_);
        }

        $self->ivPoke('number', $number);

        return 1;
    }

    sub add_property {

        my ($self, $key, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $key || ! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_property', @_);
        }

        # Update IVs
        $self->ivAdd('propertyHash', $key, $value);

        return 1;
    }

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }
    sub parent
        { $_[0]->{parent} }

    sub name
        { $_[0]->{name} }
    sub number
        { $_[0]->{number} }
    sub category
        { $_[0]->{category} }
    sub indepFlag
        { $_[0]->{indepFlag} }

    sub stimulus
        { $_[0]->{stimulus} }
    sub response
        { $_[0]->{response} }
    sub enabledFlag
        { $_[0]->{enabledFlag} }

    sub attribHash
        { my $self = shift; return %{$self->{attribHash}}; }

    sub assocProf
        { $_[0]->{assocProf} }
    sub assocProfCategory
        { $_[0]->{assocProfCategory} }

    sub callClass
        { $_[0]->{callClass} }
    sub callMethod
        { $_[0]->{callMethod} }

    sub propertyHash
        { my $self = shift; return %{$self->{propertyHash}}; }
}

{ package Games::Axmud::Interface::Trigger;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Interface Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the trigger object
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Depending on which
        #   profiles are current ones, and how many current profiles have interfaces with the same
        #   name, an interface can be 'active' or 'inactive'
        #
        # This object represents an 'inactive' trigger. It is stored in a cage, attached to a
        #   particular profile
        # When the profile becomes a current profile, and provided that there are no other superior
        #   profiles which have a trigger with the same ->name, the trigger becomes 'active'
        # When a trigger becomes active, GA::Session creates a GA::Interface::Active object, copying
        #   it into its registries of active interfaces
        # When the trigger becomes inactive again, the GA::Interface::Active object is destroyed
        #   (but this object continues to exist throughout)
        #
        # Expected arguments
        #   $session        - The GA::Session which created this object (not stored as an IV)
        #   $name           - A name for the trigger which is unique within its cage, but which
        #                       could be the same as the name of other triggers in other cages
        #                       (e.g. 'mytrigger') (max 32 chars)
        #   $stimulus       - The stimulus (a pattern, for triggers)
        #   $response       - The response (an action, for triggers)
        #
        # Optional arguments
        #   $enabledFlag    - A flag, TRUE if (when the trigger becomes active) it is responsive,
        #                       FALSE if it does nothing (if 'undef', the attribute is set to TRUE).
        #
        # Return values
        #   'undef' on improper arguments or if $name, $stimulus, $response or $enabledFlag are
        #       invalid values
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $stimulus, $response, $enabledFlag, $check) = @_;

        # Local variables
        my $flag;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $stimulus
            || ! defined $response || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Translate all values of $enabledFlag into TRUE of FALSE
        if (! defined $enabledFlag || $enabledFlag) {
            $flag = TRUE;      # Default is TRUE
        } else {
            $flag = FALSE;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => TRUE,            # All IVs are private

            # Interface category
            # ------------------

            category                    => 'trigger',       # Shortcut to $self->_objClass

            # Standard interface attributes
            # -----------------------------

            name                        => $name,           # Max 32 chars
            stimulus                    => $stimulus,       # A pattern
            response                    => $response,       # Instruction (or pattern/substitution)
            enabledFlag                 => $flag,

            # Trigger attributes
            # ------------------

            # Current values for each trigger attribute (initially set to defaults)
            attribHash                  => {
                'splitter'              => FALSE,
                'split_after'           => FALSE,
                'keep_splitting'        => FALSE,
                'rewriter'              => FALSE,
                'rewrite_global'        => FALSE,
                'ignore_case'           => TRUE,
                'gag'                   => FALSE,
                'gag_log'               => FALSE,
                'need_prompt'           => FALSE,
                'need_login'            => FALSE,
                'keep_checking'         => TRUE,
                'default_pane'          => TRUE,
                'pane_name'             => '',
                'temporary'             => FALSE,
                'cooldown'              => 0,
                'style_mode'            => 0,
                'style_text'            => '',
                'style_underlay'        => '',
                'style_italics'         => 0,
                'style_underline'       => 0,
                'style_blink_slow'      => 0,
                'style_blink_fast'      => 0,
                'style_strike'          => 0,
                'style_link'            => 0,
            },

            # Ordering
            # --------

            # A hash of inactive trigger names. When this trigger becomes active, all other active
            #   triggers are checked. If their corresponding inactive triggers have names which
            #   appear in this list, then the active trigger corresponding to this object is
            #   placed BEFORE them in the ordered list of active triggers. Hash in the form
            #       $beforeHash{inactive_trigger_name} = undef
            beforeHash                  => {},
            # Hash of inactive trigger names; if corresponding active triggers exist, this object's
            #   active trigger is placed AFTER them. (NB If ->beforeHash and ->afterHash conflict,
            #   then ->beforeHash is ignored and ->afterHash is used)
            afterHash                   => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing interface; only used when the parent cage is cloned
        #
        # Expected arguments
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($self, $profName, $check) = @_;

        # Check for improper arguments
        if (! defined $profName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Setup
        my $clone = {
            _objName                    => $self->_objName,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $profName,
            _privFlag                   => TRUE,            # All IVs are private

            # Interface category
            # ------------------

            category                    => $self->category,

            # Standard interface attributes
            # -----------------------------

            name                        => $self->name,
            stimulus                    => $self->stimulus,
            response                    => $self->response,
            enabledFlag                 => $self->enabledFlag,

            # Trigger attributes
            # ------------------

            attribHash                  => {$self->attribHash},

            # Ordering
            # --------

            beforeHash                  => {$self->beforeHash},
            afterHash                   => {$self->afterHash},
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub category
        { $_[0]->{category} }

    sub name
        { $_[0]->{name} }
    sub stimulus
        { $_[0]->{stimulus} }
    sub response
        { $_[0]->{response} }
    sub enabledFlag
        { $_[0]->{enabledFlag} }

    sub attribHash
        { my $self = shift; return %{$self->{attribHash}}; }

    sub beforeHash
        { my $self = shift; return %{$self->{beforeHash}}; }
    sub afterHash
        { my $self = shift; return %{$self->{afterHash}}; }
}

{ package Games::Axmud::Interface::Alias;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Interface Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the alias object
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Depending on which
        #   profiles are current ones, and how many current profiles have interfaces with the same
        #   name, an interface can be 'active' or 'inactive'
        #
        # This object represents an 'inactive' alias. It is stored in a cage, attached to a
        #   particular profile
        # When the profile becomes a current profile, and provided that there are no other superior
        #   profiles which have an alias with the same ->name, the alias becomes 'active'
        # When an alias becomes active, GA::Session creates a GA::Interface::Active object, copying
        #   it into its registries of active interfaces
        # When the alias becomes inactive again, the GA::Interface::Active object is destroyed (but
        #   this object continues to exist throughout)
        #
        # Expected argument
        #   $session        - The GA::Session which created this object (not stored as an IV)
        #   $name           - A name for the alias which is unique within its cage, but which could
        #                       be the same as the name of other aliases in other cages (e.g.
        #                       'myalias') (max 32 chars)
        #   $stimulus       - The stimulus (a pattern, for aliases)
        #   $response       - The response (a substitution, for aliases)
        #
        # Optional arguments
        #   $enabledFlag    - A flag, TRUE if (when the alias becomes active) it is responsive,
        #                       FALSE if it does nothing (if 'undef', the attribute is set to TRUE)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $stimulus, $response, $enabledFlag, $check) = @_;

        # Local variables
        my $flag;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $stimulus
            || ! defined $response || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Translate all values of $enabledFlag into TRUE of FALSE
        if (! defined $enabledFlag || $enabledFlag) {
            $flag = TRUE;      # Default is TRUE
        } else {
            $flag = FALSE;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => TRUE,        # All IVs are private

            # Interface category
            # ------------------

            category                    => 'alias',     # Shortcut to $self->_objClass

            # Standard interface attributes
            # -----------------------------

            name                        => $name,       # Max 32 chars
            stimulus                    => $stimulus,   # A pattern
            response                    => $response,   # A substitution
            enabledFlag                 => $flag,

            # Alias attributes
            # ----------------

            # Current values for each alias attribute (initially set to defaults)
            attribHash                  => {
                'ignore_case'           => TRUE,
                'keep_checking'         => FALSE,
                'temporary'             => FALSE,
                'cooldown'              => 0,
            },

            # Ordering
            # --------

            # A hash of inactive alias names. When this alias becomes active, all other active
            #   aliases are checked. If their corresponding inactive aliases have names which
            #   appear in this list, then the active alias corresponding to this object is
            #   placed BEFORE them in the ordered list of active aliases. Hash in the form
            #       $beforeHash{inactive_trigger_name} = undef
            beforeHash                  => {},
            # Hash of inactive alias names; if corresponding active aliases exist, this object's
            #   active alias is placed AFTER them
            afterHash                   => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing interface; only used when the parent cage is cloned
        #
        # Expected arguments
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($self, $profName, $check) = @_;

        # Check for improper arguments
        if (! defined $profName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Setup
        my $clone = {
            _objName                    => $self->_objName,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $profName,
            _privFlag                   => TRUE,            # All IVs are private

            # Interface category
            # ------------------

            category                    => $self->category,

            # Standard interface attributes
            # -----------------------------

            name                        => $self->name,
            stimulus                    => $self->stimulus,
            response                    => $self->response,
            enabledFlag                 => $self->enabledFlag,

            # Alias attributes
            # ----------------

            attribHash                  => {$self->attribHash},

            # Ordering
            # --------

            beforeHash                  => {$self->beforeHash},
            afterHash                   => {$self->afterHash},
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub category
        { $_[0]->{category} }

    sub name
        { $_[0]->{name} }
    sub stimulus
        { $_[0]->{stimulus} }
    sub response
        { $_[0]->{response} }
    sub enabledFlag
        { $_[0]->{enabledFlag} }

    sub attribHash
        { my $self = shift; return %{$self->{attribHash}}; }

    sub beforeHash
        { my $self = shift; return %{$self->{beforeHash}}; }
    sub afterHash
        { my $self = shift; return %{$self->{afterHash}}; }
}

{ package Games::Axmud::Interface::Macro;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Interface Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the macro object
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Depending on which
        #   profiles are current ones, and how many current profiles have interfaces with the same
        #   name, an interface can be 'active' or 'inactive'
        #
        # This object represents an 'inactive' macro. It is stored in a cage, attached to a
        #   particular profile
        # When the profile becomes a current profile, and provided that there are no other superior
        #   profiles which have a macro with the same ->name, the macro becomes 'active'
        # When a macro becomes active, GA::Session creates a GA::Interface::Active object,
        #   copying it into its registries of active interfaces.
        # When the macro becomes inactive again, the GA::Interface::Active object is destroyed (but
        #   this object continues to exist throughout)
        #
        # Expected arguments
        #   $session        - The GA::Session which created this object (not stored as an IV)
        #   $name           - A name for the macro which is unique within its cage, but which could
        #                       be the same as the name of other macros in other cages (e.g.
        #                       'mymacro') (max 32 chars)
        #   $stimulus       - The stimulus (a key, for macros)
        #   $response       - The response (an action, for macros)
        #
        # Optional arguments
        #   $enabledFlag    - A flag, TRUE if (when the macro becomes active) it is responsive,
        #                       FALSE if it does nothing (if 'undef', the attribute is set to TRUE)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $stimulus, $response, $enabledFlag, $check) = @_;

        # Local variables
        my $flag;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $stimulus
            || ! defined $response || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Translate all values of $enabledFlag into TRUE of FALSE
        if (! defined $enabledFlag || $enabledFlag) {
            $flag = TRUE;      # Default is TRUE
        } else {
            $flag = FALSE;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => TRUE,        # All IVs are private

            # Interface category
            # ------------------

            category                    => 'macro',     # Shortcut to $self->_objClass

            # Standard interface attributes
            # -----------------------------

            name                        => $name,       # Max 32 chars
            stimulus                    => $stimulus,   # An Axmud standard keycode
            response                    => $response,   # An instruction
            enabledFlag                 => $flag,

            # Macro attributes
            # ----------------

            # Current values for each macro attribute (initially set to defaults)
            attribHash                  => {
                'temporary'             => FALSE,
                'cooldown'              => 0,
            },

            # Ordering
            # --------

            # A hash of inactive macro names. When this macro becomes active, all other active mac
            #   macros are checked. If their corresponding inactive macros have names which appear
            #   in this list, then the active macro corresponding to this object is placed BEFORE
            #   them in the ordered list of active macros. Hash in the form
            #       $beforeHash{inactive_macro_name} = undef
            beforeHash                  => {},
            # Hash of inactive macro names; if corresponding active macros exist, this object's
            #   active macro is placed AFTER them
            afterHash                   => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing interface; only used when the parent cage is cloned
        #
        # Expected arguments
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($self, $profName, $check) = @_;

        # Check for improper arguments
        if (! defined $profName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Setup
        my $clone = {
            _objName                    => $self->_objName,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $profName,
            _privFlag                   => TRUE,            # All IVs are private

            # Interface category
            # ------------------

            category                    => $self->category,

            # Standard interface attributes
            # -----------------------------

            name                        => $self->name,
            stimulus                    => $self->stimulus,
            response                    => $self->response,
            enabledFlag                 => $self->enabledFlag,

            # Macro attributes
            # ----------------

            attribHash                  => {$self->attribHash},

            # Ordering
            # --------

            beforeHash                  => {$self->beforeHash},
            afterHash                   => {$self->afterHash},
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub category
        { $_[0]->{category} }

    sub name
        { $_[0]->{name} }
    sub stimulus
        { $_[0]->{stimulus} }
    sub response
        { $_[0]->{response} }
    sub enabledFlag
        { $_[0]->{enabledFlag} }

    sub attribHash
        { my $self = shift; return %{$self->{attribHash}}; }

    sub beforeHash
        { my $self = shift; return %{$self->{beforeHash}}; }
    sub afterHash
        { my $self = shift; return %{$self->{afterHash}}; }
}

{ package Games::Axmud::Interface::Timer;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Interface Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the timer object
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Depending on which
        #   profiles are current ones, and how many current profiles have interfaces with the same
        #   name, an interface can be 'active' or 'inactive'
        #
        # This object represents an 'inactive' timer. It is stored in a cage, attached to a
        #   particular profile
        # When the profile becomes a current profile, and provided that there are no other superior
        #   profiles which have a timer with the same ->name, the timer becomes 'active'
        # When a timer becomes active, GA::Session creates a GA::Interface::Active object,
        #   copying it into its registries of active interfaces
        # When the timer becomes inactive again, the GA::Interface::Active object is destroyed (but
        #   this object continues to exist throughout)
        #
        # Expected arguments
        #   $session        - The GA::Session which created this object (not stored as an IV)
        #   $name           - A name for the timer which is unique within its cage, but which could
        #                       be the same as the name of other timers in other cages (e.g.
        #                       'mytimer') (max 32 chars)
        #   $stimulus       - The stimulus (an interval, for timers)
        #   $response       - The response (an action, for timers)
        #
        # Optional arguments
        #   $enabledFlag    - A flag, TRUE if (when the timer becomes active) it is responsive,
        #                       FALSE if it does nothing (if 'undef', the attribute is set to TRUE)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $stimulus, $response, $enabledFlag, $check) = @_;

        # Local variables
        my $flag;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $stimulus
            || ! defined $response || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Translate all values of $enabledFlag into TRUE of FALSE
        if (! defined $enabledFlag || $enabledFlag) {
            $flag = TRUE;      # Default is TRUE
        } else {
            $flag = FALSE;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => TRUE,        # All IVs are private

            # Interface category
            # ------------------

            category                    => 'timer',    # Shortcut to $self->_objClass

            # Standard interface attributes
            # -----------------------------

            name                        => $name,       # Max 32 chars
            stimulus                    => $stimulus,   # An interval
            response                    => $response,   # An instruction
            enabledFlag                 => $flag,

            # Timer attributes
            # ------------------

            # Current values for each timer attribute (initially set to defaults)
            attribHash                  => {
                'count'                 => -1,
                'initial_delay'         => 0,
                'random_delay'          => FALSE,
                'random_min'            => 0,
                'wait_login'            => TRUE,
                'temporary'             => FALSE,
            },

            # Ordering
            # --------

            # A hash of inactive timer names. When this timer becomes active, all other active
            #   timers are checked. If their corresponding inactive timers have names which appear
            #   in this list, then the active timer corresponding to this object is placed BEFORE
            #   them in the ordered list of active timers. Hash in the form
            #       $beforeHash{inactive_timer_name} = undef
            beforeHash                  => {},
            # Hash of inactive timer names; if corresponding active timers exist, this object's
            #   active timer is placed AFTER them
            afterHash                   => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing interface; only used when the parent cage is cloned
        #
        # Expected arguments
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($self, $profName, $check) = @_;

        # Check for improper arguments
        if (! defined $profName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Setup
        my $clone = {
            _objName                    => $self->_objName,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $profName,
            _privFlag                   => TRUE,            # All IVs are private

            # Interface category
            # ------------------

            category                    => $self->category,

            # Standard interface attributes
            # -----------------------------

            name                        => $self->name,
            stimulus                    => $self->stimulus,
            response                    => $self->response,
            enabledFlag                 => $self->enabledFlag,

            # Timer attributes
            # ----------------

            attribHash                  => {$self->attribHash},

            # Ordering
            # --------

            beforeHash                  => {$self->beforeHash},
            afterHash                   => {$self->afterHash},
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub category
        { $_[0]->{category} }

    sub name
        { $_[0]->{name} }
    sub stimulus
        { $_[0]->{stimulus} }
    sub response
        { $_[0]->{response} }
    sub enabledFlag
        { $_[0]->{enabledFlag} }

    sub attribHash
        { my $self = shift; return %{$self->{attribHash}}; }

    sub beforeHash
        { my $self = shift; return %{$self->{beforeHash}}; }
    sub afterHash
        { my $self = shift; return %{$self->{afterHash}}; }
}

{ package Games::Axmud::Interface::Hook;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Interface Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the hook object
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Depending on which
        #   profiles are current ones, and how many current profiles have interfaces with the same
        #   name, an interface can be 'active' or 'inactive'
        #
        # This object represents an 'inactive' hook. It is stored in a cage, attached to a
        #   particular profile
        # When the profile becomes a current profile, and provided that there are no other superior
        #   profiles which have a hook with the same ->name, the hook becomes 'active'
        # When a hook becomes active, GA::Session creates a GA::Interface::Active object, copying
        #   it into its registries of active interfaces
        # When the hook becomes inactive again, the GA::Interface::Active object is destroyed (but
        #   this object continues to exist throughout)
        #
        # Expected arguments
        #   $session        - The GA::Session which created this object (not stored as an IV)
        #   $name           - A name for the hook which is unique within its cage, but which could
        #                       be the same as the name of other hooks in other cages (e.g.
        #                       'myhook') (max 32 chars)
        #   $stimulus       - The stimulus (an event, for hooks)
        #   $response       - The response (an action, for hooks)
        #
        # Optional arguments
        #   $enabledFlag    - A flag, TRUE if (when the hook becomes active) it is responsive,
        #                       FALSE if it does nothing (if 'undef', the attribute is set to TRUE)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $stimulus, $response, $enabledFlag, $check) = @_;

        # Local variables
        my $flag;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $stimulus
            || ! defined $response || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Translate all values of $enabledFlag into TRUE of FALSE
        if (! defined $enabledFlag || $enabledFlag) {
            $flag = TRUE;      # Default is TRUE
        } else {
            $flag = FALSE;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => TRUE,        # All IVs are private

            # Interface category
            # ------------------

            category                    => 'hook',      # Shortcut to $self->_objClass

            # Standard interface attributes
            # -----------------------------

            name                        => $name,       # Max 32 chars
            stimulus                    => $stimulus,   # A hook event
            response                    => $response,   # An instruction
            enabledFlag                 => $flag,

            # Hook attributes
            # ---------------

            # Current values for each hook attribute (initially set to defaults)
            attribHash                  => {
                'temporary'             => FALSE,
                'cooldown'              => 0,
            },

            # Ordering
            # --------

            # A hash of inactive hook names. When this hook becomes active, all other active hooks
            #   are checked. If their corresponding inactive hooks have names which appear in this
            #   list, then the active hook corresponding to this object is placed BEFORE them in the
            #   ordered list of active hooks. Hash in the form
            #       $beforeHash{inactive_hook_name} = undef
            beforeHash                  => {},
            # Hash of inactive hook names; if corresponding active hooks exist, this object's
            #   active hook is placed AFTER them
            afterHash                   => {},
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing interface; only used when the parent cage is cloned
        #
        # Expected arguments
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($self, $profName, $check) = @_;

        # Check for improper arguments
        if (! defined $profName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Setup
        my $clone = {
            _objName                    => $self->_objName,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $profName,
            _privFlag                   => TRUE,            # All IVs are private

            # Interface category
            # ------------------

            category                    => $self->category,

            # Standard interface attributes
            # -----------------------------

            name                        => $self->name,
            stimulus                    => $self->stimulus,
            response                    => $self->response,
            enabledFlag                 => $self->enabledFlag,

            # Hook attributes
            # ---------------

            attribHash                  => {$self->attribHash},

            # Ordering
            # --------

            beforeHash                  => {$self->beforeHash},
            afterHash                   => {$self->afterHash},
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub category
        { $_[0]->{category} }

    sub name
        { $_[0]->{name} }
    sub stimulus
        { $_[0]->{stimulus} }
    sub response
        { $_[0]->{response} }
    sub enabledFlag
        { $_[0]->{enabledFlag} }

    sub attribHash
        { my $self = shift; return %{$self->{attribHash}}; }

    sub beforeHash
        { my $self = shift; return %{$self->{beforeHash}}; }
    sub afterHash
        { my $self = shift; return %{$self->{afterHash}}; }
}

# Package must return a true value
1
