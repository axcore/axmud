# Copyright (C) 2011-2024 A S Lewis
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU
# Lesser Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser Public License for more details.
#
# You should have received a copy of the GNU Lesser Public License along with this program. If not,
# see <http://www.gnu.org/licenses/>.
#
#
# Language::Axbasic::Subroutine, based on Language::Basic by Amir Karger

{ package Language::Axbasic::Subroutine;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Subroutine::ISA = qw(
        Language::Axbasic
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Script->parse
        # The class that handles a subroutine
        #
        # Expected arguments
        #   $scriptObj  - Blessed reference of the parent LA::Script
        #   $subName    - A name for the subroutine
        #
        # Return values
        #   'undef' on improper arguments or if a subroutine with the name $subName already exists
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $subName, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $scriptObj || ! defined $subName || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that a subroutine with this name doesn't already exist
        if ($scriptObj->ivExists('subNameHash', $subName)) {

            return $scriptObj->setDebug(
                'Can\'t create Language::Axbasic::Subroutine object; subroutine or function'
                . ' named \'' . $subName . '\' - already exists',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $class,      # Name Axbasic objects after their class
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # The parent LA::Script
            scriptObj                   => $scriptObj,

            # IVs
            # ----

            # The subroutine name
            name                        => $subName,
            # The position of this subroutine in LA::Script's subroutine/function stack (unknown at
            #   the moment)
            stackPosn                   => undef,

            # Code block stack (loops such as FOR..NEXT, DO..WHILE, etc)
            # Contains a list of LA::Statements in which the block started
            blockStackList              => [],

            # ->blockStackList is used during the ->implement stage. We also use separate lists
            #   for each kind of code block, used exclusively during the ->parse stage - mainly so
            #   that the start of a code block can be matched with the end
            # Special stack for DO..UNTIL code blocks
            doStackList                 => [],
            # Special stack for WHILE..LOOP code blocks
            whileStackList              => [],
            # Special stack for SELECT CASE..END SELECT code blocks
            selectStackList             => [],
            # Special stack for multi-line IF...END IF blocks
            ifStackList                 => [],

            # The SUB statement with which the subroutine was declared
            declareStatement            => undef,
            # The END SUB statement with which the subroutine was terminated
            terminateStatement          => undef,
            # The CALL statement from which the subroutine was called
            callStatement               => undef,
            # The LA::Expression::Arglist with which the subroutine was declared
            argListObj                  => undef,
            # If the subroutine is called from a statement like 'LET a$ = CALL...', the variable (a$
            #   in this example) to which the subroutine's return value is assigned
            # (In a straight 'CALL...' statement, this is set to 'undef')
            returnVar                   => undef,
            # The return value type - 'string' or 'numeric'
            returnVarType               => undef,

            # Local variable hashes

            # Local scalar variables
            #   ->localScalarHash{scalar_name} = blessed_reference_to_scalar_object;
            # (the object is a LA::Variable::Scalar::String or LA::Variable::Scalar::Numeric)
            localScalarHash             => {},
            # Local array variables
            #   ->localArrayHash{array_name} = blessed_reference_to_array_object;
            # (the object is a LA::Variable::Array::String or LA::Variable::Array::Numeric)
            localArrayHash              => {},
        };

        bless $self, $class;

        # Update the parent LA::Script
        $scriptObj->add_subName($subName, $self);

        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    sub set_argListObj {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_argListObj', @_);
        }

        # Update IVs
        $self->ivPoke('argListObj', $obj);

        return 1;
    }

    sub set_blockStackList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, @list) = @_;

        # (No improper arguments to check - @list can be empty)

        $self->ivPoke('blockStackList', @list);

        return 1;
    }

    sub push_blockStackList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_blockStackList', @_);
        }

        # Update IVs
        $self->ivPush('blockStackList', $obj);

        return 1;
    }

    sub pop_blockStackList {

        # Returns 'undef' on improper arguments
        # Returns the popped value on success (or 'undef' if the IV is empty)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pop_blockStackList', @_);
        }

        # Update IVs
        return $self->ivPop('blockStackList');
    }

    sub set_callStatement {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_callStatement', @_);
        }

        # Update IVs
        $self->ivPoke('callStatement', $obj);

        return 1;
    }

    sub set_declareStatement {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_declareStatement', @_);
        }

        # Update IVs
        $self->ivPoke('declareStatement', $obj);

        return 1;
    }

    sub push_doStackList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_doStackList', @_);
        }

        # Update IVs
        $self->ivPush('doStackList', $obj);

        return 1;
    }

    sub pop_doStackList {

        # Returns 'undef' on improper arguments
        # Returns the popped value on success (or 'undef' if the IV is empty)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pop_doStackList', @_);
        }

        # Update IVs
        return $self->ivPop('doStackList');
    }

    sub push_ifStackList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_ifStackList', @_);
        }

        # Update IVs
        $self->ivPush('ifStackList', $obj);

        return 1;
    }

    sub pop_ifStackList {

        # Returns 'undef' on improper arguments
        # Returns the popped value on success (or 'undef' if the IV is empty)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pop_ifStackList', @_);
        }

        # Update IVs
        return $self->ivPop('ifStackList');
    }

    sub add_localArray {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $name || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_localArray', @_);
        }

        # Update IVs
        $self->ivAdd('localArrayHash', $name, $obj);

        return 1;
    }

    sub set_localArrayHash {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, %hash) = @_;

        # (No improper arguments to check - @list can be empty)

        $self->ivPoke('localArrayHash', %hash);

        return 1;
    }

    sub add_localScalar {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $name || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_localScalar', @_);
        }

        # Update IVs
        $self->ivAdd('localScalarHash', $name, $obj);

        return 1;
    }

    sub set_localScalarHash {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, %hash) = @_;

        # (No improper arguments to check - @list can be empty)

        $self->ivPoke('localScalarHash', %hash);

        return 1;
    }

    sub push_selectStackList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_selectStackList', @_);
        }

        # Update IVs
        $self->ivPush('selectStackList', $obj);

        return 1;
    }

    sub set_returnVar {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_returnVar', @_);
        }

        # Update IVs
        $self->ivPoke('returnVar', $value);

        return 1;
    }

    sub set_returnVarType {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_returnVarType', @_);
        }

        # Update IVs
        $self->ivPoke('returnVarType', $value);

        return 1;
    }

    sub pop_selectStackList {

        # Returns 'undef' on improper arguments
        # Returns the popped value on success (or 'undef' if the IV is empty)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pop_selectStackList', @_);
        }

        # Update IVs
        return $self->ivPop('selectStackList');
    }

    sub set_stackPosn {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $num, $check) = @_;

        # Check for improper arguments
        if (! defined $num || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_stackPosn', @_);
        }

        # Update IVs
        $self->ivPoke('stackPosn', $num);

        return 1;
    }

    sub set_terminateStatement {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_terminateStatement', @_);
        }

        # Update IVs
        $self->ivPoke('terminateStatement', $obj);

        return 1;
    }

    sub push_whileStackList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_whileStackList', @_);
        }

        # Update IVs
        $self->ivPush('whileStackList', $obj);

        return 1;
    }

    sub pop_whileStackList {

        # Returns 'undef' on improper arguments
        # Returns the popped value on success (or 'undef' if the IV is empty)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pop_whileStackList', @_);
        }

        # Update IVs
        return $self->ivPop('whileStackList');
    }

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub name
        { $_[0]->{name} }
    sub stackPosn
        { $_[0]->{stackPosn} }

    sub blockStackList
        { my $self = shift; return @{$self->{blockStackList}}; }

    sub doStackList
        { my $self = shift; return @{$self->{doStackList}}; }
    sub whileStackList
        { my $self = shift; return @{$self->{whileStackList}}; }
    sub selectStackList
        { my $self = shift; return @{$self->{selectStackList}}; }
    sub ifStackList
        { my $self = shift; return @{$self->{ifStackList}}; }

    sub declareStatement
        { $_[0]->{declareStatement} }
    sub terminateStatement
        { $_[0]->{terminateStatement} }
    sub callStatement
        { $_[0]->{callStatement} }
    sub argListObj
        { $_[0]->{argListObj} }
    sub returnVar
        { $_[0]->{returnVar} }
    sub returnVarType
        { $_[0]->{returnVarType} }

    sub localScalarHash
        { my $self = shift; return %{$self->{localScalarHash}}; }
    sub localArrayHash
        { my $self = shift; return %{$self->{localArrayHash}}; }
}

{ package Language::Axbasic::Subroutine::String;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Subroutine::String::ISA = qw(
        Language::Axbasic::Subroutine
        Language::Axbasic::String
    );
}

{ package Language::Axbasic::Subroutine::Numeric;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Subroutine::Numeric::ISA = qw(
        Language::Axbasic::Subroutine
        Language::Axbasic::Numeric
    );
}

# Package must return a true value
1
