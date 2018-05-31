# Copyright (C) 2011-2018 A S Lewis
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
# Language::Axbasic::Variable, based on Language::Basic by Amir Karger

{ package Language::Axbasic::Variable;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Variable::ISA = qw(
        Language::Axbasic
    );

    # Paraphrased from Language::Basic
    # There are two sorts of variables: Arrays and Scalars. Each of those classes has a subclass for
    #   Numeric or String variables.
    # An Array needs to have full LA::Variable::Scalar objects in it, rather than just having an
    #   array of values. The reason is that, for example, you might use ARR(3) as the variable in a
    #   FOR loop. Also, the 'set' and 'value' methods apply to a LA::Variable::Scalar (since you
    #   can't set an array to a value (in Axbasic) so in order to be handle A(3)=3, A(3) needs to be
    #   an LA::Variable::Scalar.
    # The lookup method looks up a variable in the Array or Scalar lookup table (depending on
    #   whether there were parentheses after the variable name). Axbasic allows undeclared
    #   variables, so if the variable name hasn't been seen before, a new variable is created.

    # Sub-classes
    {
        package Language::Axbasic::Variable::Numeric;
        package Language::Axbasic::Variable::String;
        package Language::Axbasic::Variable::Scalar;
        package Language::Axbasic::Variable::Array;
    }

    ##################
    # Constructors

#   sub new {}          # Each subclass must have its own ->new

    sub lookup {

        # Called by LA::Expression::Lvalue->new
        #
        # Look up a variable based on its name, and create a new variable (Scalar or Array) if it
        #   doesn't exist yet
        #
        # Expected arguments
        #   $scriptObj  - Blessed reference to the parent LA::Script
        #   $varName    - The variable's identifier (e.g. A, a$, array)
        #
        # Optional arguments
        #   $argListObj - For an identifier that refers to a cell in an array, blessed reference to
        #                   the LA::Expression::Arglist that represents the list
        #               - NB Some functions that want to create an array might prefer to pass a
        #                   string like 'fake_arg_list', so that the 'if (! $argListObj)' condition
        #                   that appears in this function is TRUE
        #
        # Return values
        #   'undef' on improper arguments, or if there is an error (for example in creating a new
        #       variable)
        #   Otherwise returns the variable's blessed reference, regardless of whether or not this
        #       function had to create it

        my ($class, $scriptObj, $varName, $argListObj, $check) = @_;

        # Local variables
        my ($varObj, $currentSub);

        # Check for improper arguments
        if (! defined $scriptObj || ! defined $varName || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->lookup', @_);
        }

        # Get the current subroutine/function, which stores local variables
        $currentSub = $scriptObj->returnCurrentSub();
        if (! defined $currentSub) {

            return undef;
        }

        # If it's a scalar variable...
        if (! $argListObj) {

            if ($scriptObj->declareMode eq 'global_scalar') {

                # We're in a GLOBAL statement. Check that this variable hasn't already been declared
                #   as a global variable
                if ($scriptObj->ivExists('globalScalarHash', $varName)) {

                    return $scriptObj->setError(
                        'variable_VAR_already_declared_global',
                        $class . '->lookup',
                        'VAR', $varName,
                    );
                }

                # Otherwise, declare the global variable
                $varObj = Language::Axbasic::Variable::Scalar->new($scriptObj, $varName);
                if (! $varObj) {

                    return undef;

                } else {

                    $scriptObj->add_globalScalar($varName, $varObj);

                    return $varObj;
                }

            } elsif ($scriptObj->declareMode eq 'local_scalar') {

                # We're in a LOCAL or SUB statement. Check that this variable hasn't already been
                #   declared as a local variable
                if ($currentSub->ivExists('localScalarHash', $varName)) {

                    return $scriptObj->setError(
                        'variable_VAR_already_declared_local',
                        $class . '->lookup',
                        'VAR', $varName,
                    );
                }

                # Otherwise, declare the local variable
                $varObj = Language::Axbasic::Variable::Scalar->new($scriptObj, $varName);
                if (! $varObj) {

                    return undef;

                } else {

                    $currentSub->add_localScalar($varName, $varObj);

                    return $varObj;
                }

            } elsif ($scriptObj->declareMode eq 'sort') {

                # We're in a SORT statement (or similar), which is in the form
                #   SORT var
                # where the variable is not a scalar, but an array created by
                #   DIM var (10)

                # We don't create a new scalar variable, but instead return the array variable with
                #   the same name
                if ($currentSub->ivExists('localArrayHash', $varName)) {

                    # It's a local array variable
                    return $currentSub->ivShow('localArrayHash', $varName);

                } elsif ($scriptObj->ivExists('globalArrayHash', $varName)) {

                    # It's a scalar array variable
                    return $scriptObj->ivShow('globalArrayHash', $varName);

                } else {

                    # We have to issue an error, even when OPTION TYPO hasn't been used
                    return $scriptObj->setError(
                        'variable_VAR_not_an_array',
                        $class . '->lookup',
                        'VAR', $varName,
                    );
                }

            } elsif ($currentSub->ivExists('localScalarHash', $varName)) {

                # This variable has already been declared as a local variable in the scope of the
                #   current subroutine
                return $currentSub->ivShow('localScalarHash', $varName);

            } elsif ($scriptObj->ivExists('globalScalarHash', $varName)) {

                # This variable has already been declared as a global variable
                return $scriptObj->ivShow('globalScalarHash', $varName);

            } else {

                # The scalar hasn't been declared yet, and we're not in a GLOBAL, LOCAL or SUB
                #   statement
                if (
                    # Primitive line-numbered scripts, all variables global
                    $scriptObj->executionMode eq 'line_num'
                    # PEEK or PEEK... statement
                    || $scriptObj->declareMode eq 'peek_scalar'
                    # Script doesn't specify OPTION TYPO, forcing us to use GLOBAL or LOCAL
                    || ! $scriptObj->ivShow('optionStatementHash', 'typo')
                ) {
                    # Create the new global variable
                    $varObj = Language::Axbasic::Variable::Scalar->new($scriptObj, $varName);
                    if (! $varObj) {

                        return undef;

                    } else {

                        $scriptObj->add_globalScalar($varName, $varObj);

                        return $varObj;
                    }

                } else {

                    # The variable hasn't been declared yet
                    return $scriptObj->setError(
                        'undeclared_variable_VAR',
                        $class . '->lookup',
                        'VAR', $varName,
                    );
                }
            }

        # If it's an array variable...
        } else {

            if ($scriptObj->declareMode eq 'global_array') {

                # We're in a DIM or DIM GLOBAL statement. Check that this variable hasn't already
                #   been declared as a global array
                if ($scriptObj->ivExists('globalArrayHash', $varName)) {

                    return $scriptObj->setError(
                        'array_variable_VAR_already_declared_global',
                        $class . '->lookup',
                        'VAR', $varName,
                    );
                }

                # Otherwise, declare the global array
                $varObj = Language::Axbasic::Variable::Array->new($scriptObj, $varName);
                if (! $varObj) {

                    return undef;

                } else {

                    $scriptObj->add_globalArray($varName, $varObj);

                    return $varObj;
                }

            } elsif ($scriptObj->declareMode eq 'local_array') {

                # We're in a DIM LOCAL statement. Check that this variable hasn't already been
                #   declared as a local array
                if ($currentSub->ivExists('localScalarHash', $varName)) {

                    return $scriptObj->setError(
                        'array_variable_VAR_already_declared_local',
                        $class . '->lookup',
                        'VAR', $varName,
                    );
                }

                # Otherwise, declare the local array
                $varObj = Language::Axbasic::Variable::Array->new($scriptObj, $varName);
                if (! $varObj) {

                    return undef;

                } else {

                    $currentSub->add_localArray($varName, $varObj);

                    return $varObj;
                }

            } elsif ($currentSub->ivExists('localArrayHash', $varName)) {

                # This variable has already been declared as a local array in the scope of the
                #   current subroutine
                return $currentSub->ivShow('localArrayHash', $varName);

            } elsif ($scriptObj->ivExists('globalArrayHash', $varName)) {

                # This variable has already been declared as a global array
                return $scriptObj->ivShow('globalArrayHash', $varName);

            } elsif ($scriptObj->declareMode eq 'peek_array') {

                # We're in a PEEK or PEEK... statement, and there isn't an existing global or
                #   local array called $varName, so declare a global array
                $varObj = Language::Axbasic::Variable::Array->new($scriptObj, $varName);
                if (! $varObj) {

                    return undef;

                } else {

                    $scriptObj->add_globalArray($varName, $varObj);

                    return $varObj;
                }

            } else {

                # The array variable hasn't been declared yet, and we're not in a DIM, DIM GLOBAL or
                #   DIM LOCAL statement
                return $scriptObj->setError(
                    'undeclared_array_variable_VAR',
                    $class . '->lookup',
                    'VAR', $varName,
                );
            }
        }
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Language::Axbasic::Variable::Scalar;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Variable::Scalar::ISA = qw(
        Language::Axbasic::Variable
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Line->parse
        # The class that handles a variable or one cell in an array
        # Methods include ->value, which gets the variable's value, and ->set, which sets it
        #
        # Expected arguments
        #   $scriptObj  - Blessed reference of the parent LA::Script
        #   $varName    - The variable's name
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $varName, $check) = @_;

        # Local variables
        my ($subClass, $type);

        # Check for improper arguments
        if (! defined $class || ! defined $scriptObj || ! defined $varName || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # If the variable name ends with a $, it's a string variable, otherwise it's a numeric
        #   variable
        if ($varName =~ /\$$/) {
            $type = 'String';
        } else {
            $type = 'Numeric';
        }

        # Create a new subclass object, and return it
        $subClass = $class . '::' . $type;
        return $subClass->new($scriptObj);
    }

    ##################
    # Methods

    sub value {

        # Retrieves the scalar's value
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   The scalar's value otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->value', @_);
        }

        return $self->value;
    }

    ##################
    # Accessors - set

    sub set {

        # Sets the scalar's value
        # Generates an error if we try to assign a string value like "hello" to a numeric variable
        #
        # Expected arguments
        #   $value      - The value to set
        #
        # Return values
        #   'undef' on improper arguments
        #   $value otherwise

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set', @_);
        }

        # Can't assign a string value to a numeric variable
        if (ref($self) =~ m/Numeric/ && ! Scalar::Util::looks_like_number($value)) {

            return $self->scriptObj->setError(
                'type_mismatch_error',
                $self->_objClass . '->set',
            );

        } else {

            $self->ivPoke('value', $value);

            return $value;
        }
    }

    ##################
    # Accessors - get
}

{ package Language::Axbasic::Variable::Scalar::String;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Variable::Scalar::String::ISA = qw(
        Language::Axbasic::Variable::Scalar
        Language::Axbasic::Variable::String
    );

    ##################
    # Constructors

    sub new {

        # Creates the new LA::Variable::Scalar::String
        #
        # Expected arguments
        #   $scriptObj    - Blessed reference of the parent LA::Script
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $scriptObj || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
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

            # The initial value is an empty string for string scalar
            value                       => '',
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub value
        { $_[0]->{value} }
}

{ package Language::Axbasic::Variable::Scalar::Numeric;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Variable::Scalar::Numeric::ISA = qw(
        Language::Axbasic::Variable::Scalar
        Language::Axbasic::Variable::Numeric
    );

    ##################
    # Constructors

    sub new {

        # Creates the new LA::Variable::Scalar::Numeric
        #
        # Expected arguments
        #   $scriptObj    - Blessed reference of the parent LA::Script
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $scriptObj || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
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
            # ---

            # The initial value is zero for a numeric scalar
            value                       => 0,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub value
        { $_[0]->{value} }
}

{ package Language::Axbasic::Variable::Array;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Variable::Array::ISA = qw(
        Language::Axbasic::Variable
    );

    ##################
    # Constructors

    sub new {

        # Paraphrased from Language::Basic:
        # The class that handles an Axbasic array. Each cell in the array is a LA::Variable::Scalar
        #   object
        # Methods include ->dimension, which dimensions the array to a given size (or a default
        #   size) and ->getCell, which returns the LA::Variable::Scalar object in a given array
        #   location
        # Note that Axbasic arrays start from index #1. Empty one-dimensional arrays are allowed,
        #   but cannot be created using a DIM or REDIM statement. Multi-dimensional arrays must have
        #   a size of at least 1 for each dimension. PEEK and PEEK... statements can create empty
        #   one-dimensional arrays, when they need them.
        #
        # Expected arguments
        #   $scriptObj  - Blessed reference of the parent LA::Script
        #   $arrayName  - The array's name
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $arrayName, $check) = @_;

        # Local variables
        my ($type, $subClass);

        # Check for improper arguments
        if (! defined $class || ! defined $scriptObj || ! defined $arrayName || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
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

            arrayName                   => $arrayName,
            # A 2D, 3D or moreD array of cells
            cellList                    => [],
            # The current number of dimensions
            dimCount                    => 0,
            # Maximum size of the array - this number refers to the maximum number of cells
            arrayMaxSize                => 1000000,
        };

        # If the array name ends with a $, it's a string array, otherwise it's a numeric array
        if ($arrayName =~ /\$$/) {
            $type = 'String';
        } else {
            $type = 'Numeric';
        }

        # Create a new subclass object
        $subClass = $class . '::' . $type;
        bless $self, $subClass;
        return $self;
    }

    ##################
    # Methods

    sub dimension {

        # Called by DIM and REDIM statements
        # Re-dimension the array
        #
        # Expected arguments
        #   @sizeList   - A list of sizes for each dimension, e.g. for a 1D array, @sizeList = (5)
        #
        # Return values
        #   'undef' on improper arguments or if the array is too big
        #   1 if the redimensioning is successful

        my ($self, @sizeList) = @_;

        # Local variables
        my ($size, $subClass, $listRef);

        # Check for improper arguments
        if (! @sizeList) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->dimension', @_);
        }

        # Check that each size is a valid integer, greater than 0

        # Single-dimensional arrays
        if (scalar @sizeList == 1) {

            if ($sizeList[0] =~ m/\D/ || $sizeList[0] < 0) {

                return $self->scriptObj->setError(
                    'invalid_array_dimension_size_NUM',
                    $self->_objClass . '->dimension',
                    'NUM', $sizeList[0],
                );
            }

        # Multi-dimensional arrays
        } else {

            foreach my $dim (@sizeList) {

                if ($dim =~ m/\D/ || $dim < 1) {

                    return $self->scriptObj->setError(
                        'invalid_array_dimension_size_NUM',
                        $self->_objClass . '->dimension',
                        'NUM', $dim,
                    );
                }
            }
        }

        # Check that the total size of the array doesn't exceed the maximum size

        # Single-dimensional arrays
        if (scalar @sizeList == 1) {

            $size = $sizeList[0];

        # Multi-dimensional arrays
        } else {

            $size = 1;
            foreach my $dim (@sizeList) {

                $size *= ($dim + 1);
            }
        }

        if ($size > $self->arrayMaxSize) {

            return $self->scriptObj->setError(
                'array_exceeds_maximum_size',
                $self->_objClass . '->dimension',
            );
        }

        # Create a new array, of the right size, full of LA::Scalar::Variable objects
        $subClass = $self->_objClass;
        $subClass =~ s/Array/Scalar/;

        $self->ivPoke('dimCount', scalar @sizeList);
        $listRef = $self->createListOfLists($subClass, @sizeList);
        $self->ivPoke('cellList', @$listRef);

        return 1;
    }

    sub createListOfLists {

        # Called by $self->dimension, or by this function recursively
        # Create a list of lists in order to form the new array
        #
        # Expected arguments
        #   $subClass   - The class of objects being created
        #   @sizeList   - The size of each dimension (e.g. for a 2D 10x10 array,
        #                   @sizeList = (10,10) )
        #
        # Return values
        #   Blessed reference to the new subclass (we don't check improper arguments in this
        #       recursive function)

        my ($self, $subClass, @sizeList) = @_;

        # Local variables
        my (
            $size,
            @array,
        );

        # (Don't check improper arguments)

        if (@sizeList) {

            # Recursion
            $size = shift(@sizeList);
            @array = map {$self->createListOfLists($subClass, @sizeList)} (1 .. $size);
            # Axbasic arrays start at index #1; so the Perl array's index 0 must be 'undef'
            unshift (@array, undef);

            return \@array;

        } else {

            # End recursion
            return $subClass->new($self->scriptObj, $self->arrayName);
        }
    }

    sub getCell {

        # Get the value stored in a single cell of the array
        #
        # Expected arguments
        #   @indices    - A list of array indices, e.g. (5, 6, 1) to get the value stored in the
        #                   cell at x=5, y=6, z=1
        #
        # Return values
        #   'undef' on improper arguments or if the cell doesn't exist
        #   Otherwise returns the contents of the cell

        my ($self, @indices) = @_;

        # Local variables
        my $pointer;

        # Check for improper arguments
        if (! @indices) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getCell', @_);
        }

        if (scalar @indices != $self->dimCount) {

            return $self->scriptObj->setError(
                'subscript_out_of_bounds',
                $self->_objClass . '->getCell',
            );
        }

        # Set $pointer to the contents of the correct cell by stripping away the dimensions, one by
        #   one, until only one cell remains
        $pointer = $self->{'cellList'};
        foreach my $index (@indices) {

            my $size = scalar @$pointer;

            # The index can't be negative or greater than the array size
            if (! ($index =~ /^\d+$/) || $index < 1 || $index >= $size) {

                return $self->scriptObj->setError(
                    'subscript_out_of_bounds',
                    $self->_objClass . '->getCell',
                );
            }

            $pointer = $pointer->[$index];
        }

        if (! $pointer->isa('Language::Axbasic::Variable::Scalar')) {

            return $self->scriptObj->setDebug(
                'Strange array cell class',
                $self->_objClass . '->getCell',
            );

        } else {

            return $pointer;
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub arrayName
        { $_[0]->{arrayName} }
    sub cellList
        { my $self = shift; return @{$self->{cellList}}; }
    sub dimCount
        { $_[0]->{dimCount} }

    sub arrayMaxSize
        { $_[0]->{arrayMaxSize} }
}

{ package Language::Axbasic::Variable::Array::Numeric;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Variable::Array::Numeric::ISA = qw(
        Language::Axbasic::Variable::Array
        Language::Axbasic::Variable::Numeric
    );
}

{ package Language::Axbasic::Variable::Array::String;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Variable::Array::String::ISA = qw(
        Language::Axbasic::Variable::Array
        Language::Axbasic::Variable::String
    );
}

{ package Language::Axbasic::Variable::Numeric;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    # Set ISA for 'return type' classes
    @Language::Axbasic::Variable::Numeric::ISA = qw(
        Language::Axbasic::Variable
        Language::Axbasic::Numeric
    );
}

{ package Language::Axbasic::Variable::String;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    # Set ISA for 'return type' classes
    @Language::Axbasic::Variable::String::ISA = qw(
        Language::Axbasic::Variable
        Language::Axbasic::String
    );
}

# Package must return true
1
