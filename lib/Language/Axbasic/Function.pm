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
# Language::Axbasic::Function, based on Language::Basic by Amir Karger

{ package Language::Axbasic::Function;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::ISA = qw(
        Language::Axbasic
    );

    # Sub-classes
    {
        package Language::Axbasic::Function::Intrinsic;
        package Language::Axbasic::Function::Defined;
    }

    ##################
    # Constructors

    sub new {

        # Called by LA::Expression::Function->new
        #
        # Paraphrased from Language::Basic:
        # The class that handles user-defined and intrinsic functions in Axbasic
        #
        # A Function can be either an intrinsic Axbasic function, like int() or chr$(), or a
        #   user-defined function, defined with the 'def' command (NB Unlike Language::Basic,
        #   user-defined functions don't have to begin with the letters FN)
        # The ->checkArgs method checks that the right number and type of function arguments were
        #   specified
        # The ->evaluate method actually calculates the value of the function, using any specified
        #   aguments
        #
        # ->new puts the function into LA::Script's function lookup table, as well as blessing the
        #   subclass into existence
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference of the parent LA::Script
        #   $funcName       - The function's name
        #
        # Optional arguments
        #   $argTypeString  - (When called by LA::Function::Intrinsic->initialise) the value for
        #                       $self->argTypeString
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object (blessed into the function subclass) on
        #       success

        my ($class, $scriptObj, $funcName, $argTypeString, $check) = @_;

        # Local variables
        my ($type, $subClass);

        # Check for improper arguments
        if (! defined $class || ! defined $scriptObj || ! defined $funcName || defined $check) {

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

            # Name of the function
            funcName                    => $funcName,
            # What type of function this is: 'string' or 'numeric'
            funcType                    => undef,       # Set below
            # A string, listing the number and type of arguments the function takes. If a function
            #   takes a String and two Numeric arguments, the string will be 'SNN'. A semicolon
            #   separates required from optional arguments
            # For intrinsic functions, set by ->initialise. For user-defined functions, set by
            #   ->declare
            argTypeString               => $argTypeString,
            # For user-defined functions, a list of LA::Variable::Lvalues (set by ->declare); an
            #   empty list for intrinsic functions
            argList                     => [],
            # For user-defined functions, an expression which defines the function ('undef' for
            #   intrinsic functions). Set by LA::Statement::def->parse
            defFuncExp                  => undef,
        };

        # Put this function in LA::Script's lookup table. (If a function with the same name already
        #   exists - even if it is an intrinsic function - the old function is overwritten)
        $scriptObj->add_funcName($funcName, $self);

        # If the function name ends with a $, it's a string function, otherwise it's a numeric
        #   function
        if ($funcName =~ /\$$/) {
            $type = 'String';
        } else {
            $type = 'Numeric';
        }

        $self->{'funcType'} = lc($type);

        # Create the subclass object and return it
        if ($class =~ m/Language::Axbasic::Function::Defined/) {

            # User-defined functions
            $subClass = $class . '::' . $type;
            bless $self, $subClass;

        } else {

            # Intrinsic functions
            bless $self, $class;
        }
    }

    ##################
    # Methods

    sub checkArgs {

        # Called by LA::Expression::Function->new
        # Given an LA::Expression::ArgList object, checks the arguments to make sure they are of the
        #   correct number and type
        # NB unlike original Language::Basic, we give up at the first terror
        #
        # Expected arguments
        #   $argListObj     - A LA::Expression::ArgList object containing the argument list
        #
        # Return values
        #   'undef' on improper arguments, or if there's an error
        #   1 if the arguments check out

        my ($self, $argListObj, $check) = @_;

        # Local variables
        my (
            $typeString, $min, $max,
            @args,
        );

        # Check for improper arguments
        if (! defined $argListObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkArgs', @_);
        }

        # Import the argument list from the LA::Expression::ArgList object
        @args = $argListObj->argList;

        # Import this function's argument type string
        $typeString = $self->argTypeString;
        # From the type string, set the minimum and maximum number of arguments
        if ($typeString =~ s/(.*);/$1/) {
            $min = length($1);              # Optional arguments
        } else {
            $min = length($typeString);     # No optional arguments
        }

        $max = length($typeString);

        if (scalar @args < $min || scalar @args > $max) {

            return $self->scriptObj->setError(
                'wrong_number_of_arguments',
                $self->_objClass . '->checkArgs',
            );
        }

        # Check each argument type in turn
        OUTER: foreach my $type (split (m//, $typeString)) {

            my ($arg, $argType);

            $arg = shift @args;
            if (! defined $arg) {

                # There may not be any optional args
                last OUTER;
            }

            if (! (ref($arg) =~ m/(String|Numeric)$/)) {

                return $self->scriptObj->setDebug(
                    'Improbable error in Language::Axbasic::Function::Defined->checkArgs',
                    $self->_objClass . '->checkArgs',
                );

            } else {

                $argType = substr($1, 0, 1);
            }

            if ($argType ne $type) {

                if ($type eq 'N') {

                    return $self->scriptObj->setError(
                        'function_expected_numeric_argument_but_received_string',
                        $self->_objClass . '->checkArgs',
                    );

                } else {

                    return $self->scriptObj->setError(
                        'function_expecteds_string_argument_but_received_numeric',
                        $self->_objClass . '->checkArgs',
                    );
                }
            }
        }

        # All the arguments check out
        return 1;
    }

    ##################
    # Accessors - set

    sub set_defFuncExp {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $expression, $check) = @_;

        # Check for improper arguments
        if (! defined $expression || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_defFuncExp',
                @_,
            );
        }

        # Update IVs
        $self->ivPoke('defFuncExp', $expression);

        return 1;
    }

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub funcName
        { $_[0]->{funcName} }
    sub funcType
        { $_[0]->{funcType} }
    sub argTypeString
        { $_[0]->{argTypeString} }
    sub argList
        { my $self = shift; return @{$self->{argList}}; }
    sub defFuncExp
        { $_[0]->{defFuncExp} }
}

{ package Language::Axbasic::Function::Intrinsic;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::ISA = qw(
        Language::Axbasic::Function
    );

    ##################
    # Constructors

    sub initialise {

        # Called by LA::Script->new
        # Sets up Axbasic's intrinsic (pre-defined) functions and creates entries for each function
        #   in LA::Script's function lookup table
        #
        # Expected arguments:
        #   $scriptObj    - Blessed reference of the parent LA::Script
        #
        # Return values:
        #   'undef' on improper arguments, or if there is an error
        #   1 otherwise

        my ($class, $scriptObj, $check) = @_;

        # Local variables
        my (
            $subClass, $string,
            @funcList,
            %funcHash,
        );

        # Check for improper arguments
        if (! defined $scriptObj || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->initialise', @_);
        }

        # Import the pre-defined function hash, which states which arguments are required for each
        #   function
        %funcHash = $scriptObj->funcArgHash;

        # Create each function in turn
        foreach my $funcName (keys %funcHash) {

            if (! ($funcName =~ m/\$$/)) {

                $subClass = 'Language::Axbasic::Function::Intrinsic::Numeric::' . $funcName;

            } else {

                $string = $funcName;
                $string =~ s/\$$//;
                $subClass = 'Language::Axbasic::Function::Intrinsic::String::' . $string;
            }

            if (! $subClass->new($scriptObj, $funcName, $funcHash{$funcName})) {

                return $scriptObj->setDebug(
                    'Can\'t set up intrinsic function ' . $funcName . '\'',
                    $class . '->initialise',
                );
            }
        }

        # Initialisation complete
        return 1;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Language::Axbasic::Function::Intrinsic::String;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::ISA = qw(
        Language::Axbasic::Function::Intrinsic
        Language::Axbasic::Function::String
    );
}

{ package Language::Axbasic::Function::Intrinsic::Numeric;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ISA = qw(
        Language::Axbasic::Function::Intrinsic
        Language::Axbasic::Function::Numeric
    );
}

{ package Language::Axbasic::Function::Defined;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Defined::ISA = qw(
        Language::Axbasic::Function
    );

    # Paraphrased from Language::Basic
    # This class handles functions defined by the user in 'def' statements

    ##################
    # Constructors

    ##################
    # Methods

    sub declare {

        # Called by LA::Expression::Function->new
        # Declares how many arguments, and of which type, the newly-defined function should expect.
        #   Sets the IVs $self->argTypeString and $self->argListObj
        #
        # Expected arguments
        #   @argList    - A list of LA::Variable::Lvalue objects which are the arguments to the
        #                   function (e.g., x in 'def myfunc(x)')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, @argList) = @_;

        # Local variables
        my $argTypeString;

        # (No improper arguments to check)

        foreach my $arg (@argList) {

            my $class = ref($arg);

            if (! ($class =~ /(String|Numeric)$/)) {

                return $self->scriptObj->setDebug('Type error', $self->_objClass . '->declare');

            } else {

                # $argTypeString is a string made up of S (for String) or N (Numeric) characters in
                #   sequence, showing the Axbasic function's expected argument types
                $argTypeString .= substr($1, 0, 1);
            }
        }

        # Set IVs
        $self->ivPoke('argTypeString', $argTypeString);
        $self->ivPoke('argList', @argList);

        return 1;
    }

    sub evaluate {

        # Called by LA::Expression::Function->evaluate
        # Actually evaluate the function with the specified arguments
        #
        # Paraphrased from Language::Basic:
        # Set each parameter (in the ->variables IV) to the value given in the arguments, then
        #   evaluate the expression
        # Just in case the user has a fn(x) and uses x elsewhere in the script, save the value of x
        #   just before we set x based on the argument (this is a poor man's version of variable
        #   scoping)
        #
        # Expected arguments
        #   @args       - The arguments with which to evaluate the function
        #
        # Return values
        #   'undef' on improper arguments, or if the ->defFuncExp IV is not defined
        #   Otherwise returns the value of the function

        my ($self, @args) = @_;

        # Local variables
        my (
            $varObj, $returnValue,
            @lvalueList, @saveVars,
        );

        # (No improper arguments to check)

        # Check the function has been defined (no reason why it shouldn't have been)
        if (! defined $self->defFuncExp) {

            return $self->scriptObj->setError(
                'function_not_defined',
                $self->_objClass . '->evaluate',
            );
        }

        # Import the list of LA::Variable::Lvalues objects, which are the arguments to the function
        #   (e.g., x in 'def myfunc(x)')
        @lvalueList = $self->argList;

        # Process the list of LA::Variable::Lvalues objects, which are the arguments to the function
        #   (e.g., x in 'def myfunc(x)')
        foreach my $lvalue (@lvalueList) {

            # Get a blessed reference to a variable object. If it's a scalar, returns that object;
            #   if it's an array, returns the object specified by the argument list (e.g. the value
            #   of array(5,6) )
            $varObj = $lvalue->variable;

            # Save the value of the variable, so we can give the variable a temporary value, and
            #   restore the old value afterwards
            push (@saveVars, $varObj->value);
            $varObj->set(shift @args);
        }

        # Evaluate the expression that defines the function
        $returnValue = $self->defFuncExp->evaluate();
        if (! defined $returnValue) {

            return undef;
        }

        # Now restore the values of the variable objects that we changed a few moments ago
        foreach my $lvalue (@lvalueList) {

            $varObj = $lvalue->variable;
            $varObj->set(shift @saveVars);
        }

        # Return the value of the function
        return $returnValue;
    }

    ##################
    # Accessors - set

     ##################
    # Accessors - get
}

{ package Language::Axbasic::Function::Defined::String;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Defined::String::ISA = qw(
        Language::Axbasic::Function::Defined
        Language::Axbasic::Function::String
    );
}

{ package Language::Axbasic::Function::Defined::Numeric;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Defined::Numeric::ISA = qw(
        Language::Axbasic::Function::Defined
        Language::Axbasic::Function::Numeric
    );
}

{ package Language::Axbasic::Function::String;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::String::ISA = qw(
        Language::Axbasic::Function
        Language::Axbasic::String
    );
}

{ package Language::Axbasic::Function::Numeric;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Numeric::ISA = qw(
        Language::Axbasic::Function
        Language::Axbasic::Numeric
    );
}

### Pure BASIC functions (numeric) ###

{ package Language::Axbasic::Function::Intrinsic::Numeric::abs;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::abs::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ABS (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return abs($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::acos;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::acos::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ACOS (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $value;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $value = Math::Trig::acos($arg);

        # $value is in radians by default. Convert to degrees, if required
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            $value = Math::Trig::rad2deg($value);
        }

        return $value;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::angle;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::angle::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ANGLE (x, y)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'NN')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # Local variables
        my ($arctan, $value);

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Check that both arguments are non-zero numbers
        if (! $args[0] && ! $args[1]) {

            return $self->scriptObj->setError(
                'invalid_matching_arguments',
                $self->_objClass . '->evaluate',
            );
        }

        # We give a range of angles, in radians, equivalent to -180o < @ <= 180
        # Use the arctan function to find the angle of the tangent, since we have both the opposite
        #   ($args[1]) and the adjacent ($args[0])

        # First deal with special cases (so we don't divide by 0)
        if (! $args[0]) {

            if ($args[1] > 0) {
                $value = Math::Trig::deg2rad(90);
            } else {
                $value = Math::Trig::deg2rad(-90);
            }

        } elsif (! $args[1]) {

            if ($args[0] > 0) {
                $value = Math::Trig::deg2rad(0);
            } else {
                $value = Math::Trig::deg2rad(180);
            }

        } else {

            $arctan = Math::Trig::atan($args[1] / $args[0]);

            # Otherwise, tan is opposite / adjacent...
            if ($args[0] > 0 && $args[1] > 0) {

                $value = $arctan;

            } elsif ($args[0] < 0 && $args[1] > 0) {

                $value = Math::Trig::deg2rad(180) + $arctan;

            } elsif ($args[0] < 0 && $args[1] < 0) {

                $value = Math::Trig::deg2rad(-180) + $arctan;

            } else {

                $value = $arctan;
            }
        }

        # Convert from radians to degrees, if required
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            $value = Math::Trig::rad2deg($value);
        }

        return $value;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::asc;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::asc::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ASC (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $value;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $value = ord($arg);

        if ($value < 0 || $value > 127) {

            return $self->scriptObj->setError(
                'character_STRING_out_of_range',
                $self->_objClass . '->evaluate',
                'STRING', $arg,
            );

        } else {

            return $value;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::asin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::asin::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ASIN (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $value;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $value = Math::Trig::asin($arg);

        # $value is in radians by default. Convert to degrees, if required
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            $value = Math::Trig::rad2deg($value);
        }

        return $value;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::atn;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::atn::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ATN (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $value;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $value = Math::Trig::atan($arg);

        # $value is in radians by default. Convert to degrees, if required
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            $value = Math::Trig::rad2deg($value);
        }

        return $value;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ceil;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ceil::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # CEIL (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return POSIX::ceil($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::cos;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::cos::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # COS (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Use radians (default) or degrees?
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            # Convert to radians
            $arg = Math::Trig::deg2rad($arg);
        }

        # Evaluate the function and return the value
        return cos($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::cosh;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::cosh::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # COSH (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return Math::Trig::cosh($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::cot;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::cot::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # COT (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $value;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # The value of $arg cannot be 0 (because this would cause division by 0)
        if (! $arg) {

            return $self->scriptObj->setError(
                'number_NUM_out_of_range',
                $self->_objClass . '->evaluate',
                'NUM', $arg,
            );
        }

        # Use radians (default) or degrees?
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            # Convert to radians
            $arg = Math::Trig::deg2rad($arg);
        }

        # Evaluate the function and return the value
        return Math::Trig::cot($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::cpos;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::cpos::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # CPOS (string, substring)
    # CPOS (string, substring, n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SS;N')
        #
        # Expected arguments
        #   $string, $subString, $position
        #       - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, $string, $subString, $posn) = @_;

        # Local variables
        my (
            $result,
            @charList,
        );

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (defined $posn) {

            # $posn must not be zero or a negative number
            if ($posn < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->evaluate',
                    'NUM', $posn,
                );
            }

            # $posn must be rounded
            $posn = substr(
                $posn + 0.5,
                0,
                length(int($posn + 0.5)),
            );

            # Finally, Perl's index() function uses the number 0 for the first character in the
            #   string, but True BASIC uses the number 1
            $posn--;
        }

        # If either string is a null string, True BASIC returns 0
        if (! $string || ! $subString) {

            return 0;
        }

        # Evaluate the function for each character in $subString
        @charList = split(//, $subString);
        foreach my $char (@charList) {

            if (defined $posn) {
                $result = index($string, $char, $posn);
            } else {
                $result = index($string, $char);
            }

            if ($result != -1) {

                # Look for 'g' in 'disgust' - Perl returns 3, but True BASIC returns 4
                return ($result + 1);
            }
        }

        # No character in the substring was found in the string
        return 0;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::cposr;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::cposr::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # CPOSR (string, substring)
    # CPOSR (string, substring, n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SS;N')
        #
        # Expected arguments
        #   $string, $subString, $posn
        #       - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, $string, $subString, $posn) = @_;

        # Local variables
        my (
            $result,
            @charList,
        );

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (defined $posn) {

            # $posn must not be zero or a negative number
            if ($posn < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->evaluate',
                    'NUM', $posn,
                );
            }

            # $posn must be rounded
            $posn = substr(
                $posn + 0.5,
                0,
                length(int($posn + 0.5)),
            );

            # Finally, Perl's index() function uses the number 0 for the first character in the
            #   string, but True BASIC uses the number 1
            $posn--;
        }

        # If either string is a null string, True BASIC returns 0
        if (! $string || ! $subString) {

            return 0;
        }

        # Evaluate the function for each character in $subString
        @charList = split(//, $subString);
        foreach my $char (@charList) {

            if (defined $posn) {
                $result = rindex($string, $char, $posn);
            } else {
                $result = rindex($string, $char);
            }

            if ($result != -1) {

                # Look for 'g' in 'disgust' - Perl returns 3, but True BASIC returns 4
                return ($result + 1);
            }
        }

        # No character in the substring was found in the string
        return 0;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::csc;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::csc::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # CSC (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # The value of $arg cannot be 0 (because this would cause division by 0)
        if (! $arg) {

            return $self->scriptObj->setError(
                'number_NUM_out_of_range',
                $self->_objClass . '->evaluate',
                'NUM', $arg,
            );
        }

        # Use radians (default) or degrees?
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            # Convert to radians
            $arg = Math::Trig::deg2rad($arg);
        }

        # Evaluate the function and return the value
        return Math::Trig::csc($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::date;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::date::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # DATE ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Get the time and date
        my (
            $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear,
            $daylightSavings,
        ) = localtime();

        # Return a value in the form YYDDD
        return (sprintf("%02d", $yearOffset % 100) . $dayOfYear);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::deg;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::deg::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # DEG (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return Math::Trig::rad2deg($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::eof;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::eof::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # EOF (channel)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $channelObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Check that the file channel exists
        if (! $self->scriptObj->ivExists('fileChannelHash', $arg)) {

            # File channel not open
            return 0;

        } else {

            $channelObj = $self->scriptObj->ivShow('fileChannelHash', $arg);

            if (eof($channelObj->fileHandle)) {

                # End of file reached, or filehandle not open
                return 1;

            } else {

                # End of file not reached
                return 0;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::exp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::exp::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # EXP (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return exp($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::fp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::fp::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # FP (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return ($arg - int($arg));
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::int;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::int::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # INT (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if ($arg < 0) {
            return (int($arg) - 1);
        } else {
            return (int($arg));
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ip;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ip::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # IP (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return int($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::len;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::len::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # LEN (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return length($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::log;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::log::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # LOG (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return log($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::log2;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::log2::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # LOG2 (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return (log($arg) / log(2));
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::log10;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::log10::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # LOG10 (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return (log($arg) / log(10));
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::match;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::match::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # MATCH (string, regex)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SS')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # Local variables
        my ($string, $regex);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        ($string, $regex) = @args;

        if ($string =~ m/$regex/) {
            return 1;
        } else {
            return 0;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::matchi;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::matchi::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # MATCHI (string, regex)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SS')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # Local variables
        my ($string, $regex);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        ($string, $regex) = @args;

        if ($string =~ m/$regex/i) {
            return 1;
        } else {
            return 0;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::max;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::max::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # MAX (x, y)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'NN')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if ($args[0] > $args[1]) {
            return $args[0];
        } else {
            return $args[1];
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::min;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::min::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # MIN (x, y)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'NN')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if ($args[0] < $args[1]) {
            return $args[0];
        } else {
            return $args[1];
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::mod;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::mod::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # MOD (x, y)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'NN')
        #
        # Evaluates the function using the supplied arguments
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return ($args[0] % $args[1]);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ncpos;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ncpos::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # NCPOS (string, substring)
    # NCPOS (string, substring, n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SS;N')
        #
        # Expected arguments
        #   $string, $subString, $position
        #       - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, $string, $subString, $posn) = @_;

        # Local variables
        my (
            $result,
            @charList,
        );

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (defined $posn) {

            # If $string is a null string, True BASIC returns 0;
            if (! $string) {

                return 0;

            # If $subString is a null string, True BASIC returns the starting position
            } elsif (! $subString) {

                return $posn;
            }

            # $posn must not be zero or a negative number
            if ($posn < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->evaluate',
                    'NUM', $posn,
                );
            }

            # $posn must be rounded
            $posn = substr($posn + 0.5, 0, length(int($posn + 0.5)));

            # Finally, Perl's index() function uses the number 0 for the first character in the
            #   string, but True BASIC uses the number 1
            $posn--;

        } else {

            # If either string is a null string, True BASIC returns 0
            if (! $string || ! $subString) {

                return 0;
            }

            # We start the search at (Perl) character position 0
            $posn = 0;
        }

        # Evaluate the function for each character in $string
        @charList = split(//, $string);
        for (my $count = $posn; $count < length $string; $count++) {

            $result = index($subString, $charList[$count]);

            if ($result == -1) {

                # The character doesn't appear in the substring
                return ($count + 1);
            }
        }

        # No character in the string was found in the substring
        return 0;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ncposr;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ncposr::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # NCPOSR (string, substring)
    # NCPOSR (string, substring, n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SS;N')
        #
        # Expected arguments
        #   $string, $subString, $posn
        #       - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, $string, $subString, $posn) = @_;

        # Local variables
        my  (
            $result,
            @charList,
        );

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (defined $posn) {

            # If $string is a null string, True BASIC returns 0;
            if (! $string) {

                return 0;

            # If $subString is a null string, True BASIC returns the starting position
            } elsif (! $subString) {

                return $posn;
            }

            # $posn must not be zero or a negative number
            if ($posn < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->evaluate',
                    'NUM', $posn,
                );
            }

            # $posn must be rounded
            $posn = substr(
                $posn + 0.5,
                0,
                length(int($posn + 0.5)),
            );

            # Finally, Perl's index() function uses the number 0 for the first character in the
            #   string, but True BASIC uses the number 1
            $posn--;

        } else {

            # If the string is a null string, True BASIC returns 0
            if (! $string) {

                return 0;

            # If the substring is a null string but the string isn't, True BASIC returns the length
            #   of the string
            } elsif (! $subString) {

                return length($string);
            }

            # We start the search at the (Perl) end of the string
            $posn = (length($string) - 1);
        }

        # Evaluate the function for each character in $string
        @charList = split(//, $string);
        for (my $count = $posn; $count >= 0; $count--) {

            $result = index($subString, $charList[$count]);

            if ($result == -1) {

                # The character doesn't appear in the substring
                return ($count + 1);
            }
        }

        # No character in the string was found in the substring
        return 0;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::pi;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::pi::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # PI ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return Math::Trig::pi();
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::pos;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::pos::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # POS (string, substring)
    # POS (string, substring, n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SS;N')
        #
        # Expected arguments
        #   $string, $subString, $posn
        #       - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, $string, $subString, $posn) = @_;

        # Local variables
        my $result;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (defined $posn) {

            # $posn must not be zero or a negative number
            if ($posn < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->evaluate',
                    'NUM', $posn,
                );
            }

            # $posn must be rounded
            $posn = substr(
                $posn + 0.5,
                0,
                length(int($posn + 0.5)),
            );

            # Finally, Perl's index() function uses the number 0 for the first character in the
            #   string, but True BASIC uses the number 1
            $posn--;
        }

        # If $string is null but $substring is not, True BASIC returns 0
        if (! $string && $subString) {

            return 0;

        } elsif (! $subString) {

            if (defined $posn) {

                # If $subString is null, True BASIC returns the starting position
                return ($posn + 1);

            } else {

                # If $subString is null, True BASIC returns 1
                return 1;
            }
        }

        # Evaluate the function and return the value
        if (defined $posn) {
            $result = index($string, $subString, $posn);
        } else {
            $result = index($string, $subString);
        }

        if ($result == -1) {

            # $subString not found - True BASIC returns 0
            return 0;

        } else {

            # Look for 'gust' in 'disgust' - Perl returns 3, but True BASIC returns 4
            return ($result + 1);
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::posr;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::posr::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # POSR (string, substring)
    # POSR (string, substring, n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SS;N')
        #
        # Expected arguments
        #   $string, $subString, $posn
        #       - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, $string, $subString, $posn) = @_;

        # Local variables
        my $result;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (defined $posn) {

            # $posn must not be a negative number
            if ($posn < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->evaluate',
                    'NUM', $posn,
                );
            }

            # $posn must be rounded
            $posn = substr($posn + 0.5, 0, length(int($posn + 0.5)));

            # Finally, Perl's index() function uses the number 0 for the first character in the
            #   string, but True BASIC uses the number 1
            $posn--;
        }

        # If $string is null but $substring is not, True BASIC returns 0
        if (! $string && $subString) {

            return 0;

        } elsif (! $subString) {

            if (defined $posn) {

                # If $subString is null, True BASIC returns the starting position
                return ($posn + 1);

            } else {

                # If $subString is null, True BASIC returns 1
                return 1;
            }
        }

        # Evaluate the function and return the value
        if (defined $posn) {
            $result = rindex($string, $subString, $posn);
        } else {
            $result = rindex($string, $subString);
        }

        if ($result == -1) {

            # $subString not found - True BASIC returns 0
            return 0;

        } else {

            # Look for 'gust' in 'disgust' - Perl returns 3, but True BASIC returns 4
            return ($result + 1);
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::rad;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::rad::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # RAD (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return Math::Trig::deg2rad($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::remainder;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::remainder::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # REMAINDER (x, y)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'NN')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return ($args[0] % $args[1]);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::rnd;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::rnd::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # RND (n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $value;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return rand($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::round;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::round::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ROUND (x)
    # ROUND (x, n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N;N')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # Local variables
        my ($number, $decimals);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $number = shift @args;
        $decimals = shift @args;
        if (! defined $decimals) {

            $decimals = 0;
        }

        return sprintf("%." . $decimals . "f", $number);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::sec;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::sec::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SEC (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $value;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # $arg must not be (pi/2) + (k * pi), where k is any integer
        if (
            (
                (($arg - (Math::Trig::pi / 2)) / Math::Trig::pi)
                    == int (($arg - (Math::Trig::pi / 2)) / Math::Trig::pi)
            ) || (
                # Don't know why we need to use 'eq' instead of '==' in the case of k = 0, but we
                #   do...
                $arg eq (Math::Trig::pi / 2)
            )
        ) {
            return $self->scriptObj->setError(
                'number_NUM_out_of_range',
                $self->_objClass . '->evaluate',
                'NUM', $arg,
            );
        }

        # Use radians (default) or degrees?
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            # Convert to radians
            $arg = Math::Trig::deg2rad($arg);
        }

        # Evaluate the function and return the value
        return Math::Trig::sec($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::sgn;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::sgn::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SGN (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if ($arg > 0) {
            return 1;
        } elsif ($arg < 0) {
            return -1;
        } else {
            return 0;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::sin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::sin::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SIN (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Use radians (default) or degrees?
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            # Convert to radians
            $arg = Math::Trig::deg2rad($arg);
        }

        # Evaluate the function and return the value
        return sin($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::sinh;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::sinh::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SINH (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return &sinh($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::sqr;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::sqr::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SQR (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Don't try to get the square root of a negative number
        if ($arg < 0) {

            return $self->scriptObj->setError(
                'number_NUM_out_of_range',
                $self->_objClass . '->evaluate',
                'NUM', $arg,
            );
        }

        # Evaluate the function and return the value
        return sqrt($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::tan;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::tan::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # TAN (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # $arg must not be (pi/2) + (k * pi), where k is any integer
        if (
            (
                (($arg - (Math::Trig::pi / 2)) / Math::Trig::pi)
                    == int (($arg - (Math::Trig::pi / 2)) / Math::Trig::pi)
            ) || (
                # Don't know why we need to use 'eq' instead of '==' in the case of k = 0, but we
                #   do...
                $arg eq (Math::Trig::pi / 2)
            )
        ) {
            return $self->scriptObj->setError(
                'number_NUM_out_of_range',
                $self->_objClass . '->evaluate',
                'NUM', $arg,
            );
        }

        # Use radians (default) or degrees?
        if ($self->scriptObj->ivShow('optionStatementHash', 'angle') eq 'degrees') {

            # Convert to radians
            $arg = Math::Trig::deg2rad($arg);
        }

        # Evaluate the function and return the value
        return Math::Trig::tan($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::tanh;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::tanh::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # TANH (x)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument lisT
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $value;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # $arg must not be (pi/2) + (k * pi), where k is any integer
        if (
            (
                (($arg - (Math::Trig::pi / 2)) / Math::Trig::pi)
                    == int (($arg - (Math::Trig::pi / 2)) / Math::Trig::pi)
            ) || (
                # Don't know why we need to use 'eq' instead of '==' in the case of k = 0, but we
                #   do...
                $arg eq (Math::Trig::pi / 2)
            )
        ) {
            return $self->scriptObj->setError(
                'number_NUM_out_of_range',
                $self->_objClass . '->evaluate',
                'NUM', $arg,
            );
        }

        # Evaluate the function and return the value
        return Math::Trig::tanh($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::time;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::time::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # TIME

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Get the time
        my ($second, $minute, $hour) = localtime();

        # Return the number of seconds since midnight
        return ( ($hour * 3600) + ($minute * 60) + $second);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::trunc;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::trunc::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # TRUNC (x)
    # TRUNC (x, n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N;N')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # Local variables
        my ($number, $decimals, $value);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $number = shift @args;
        $decimals = shift @args;
        if (! defined $decimals) {

            $decimals = 0;
        }

        if ($decimals < 0) {

            return undef;

        } elsif ($decimals == 0) {

            $value = substr(
                $number + ( '0.' . '0' x $decimals ),
                0,
                $decimals + length(int($number))
            );

        } else {

            $value = substr(
                $number + ( '0.' . '0' x $decimals ),
                0,
                $decimals + length(int($number)) + 1
            );
        }

        return $value;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::val;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::val::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # VAL (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return ($arg + 0);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::version;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::version::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # VERSION

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return $axmud::BASIC_VERSION;
    }
}

### Pure BASIC functions (string) ###

{ package Language::Axbasic::Function::Intrinsic::String::chr;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::chr::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # CHR$ (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if ($arg < 0 || $arg > 127) {

            return $self->scriptObj->setError(
                'number_NUM_out_of_range\'NUM\'',
                $self->_objClass . '->evaluate',
                'NUM', $arg,
            );

        } else {

            return (chr($arg));
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::date;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::date::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # DATE$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Get the time and date
        my (
            $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear,
            $daylightSavings
        ) = localtime();

        my $year = 1900 + $yearOffset;

        # Return the date in the form "YYYYMMDD".
        return ($year . sprintf("%02d", ($month + 1)) . sprintf("%02d", $dayOfMonth));
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::lcase;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::lcase::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # LCASE$ (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return lc($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::ltrim;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::ltrim::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # LTRIM$ (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $arg =~ s/^\s+//;

        return uc($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::mid;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::mid::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # MID$ (string, offset)
    # MID$ (string, offset, length)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SN;N')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # Local variables
        my ($string, $index, $length);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        ($string, $index, $length) = @args;
        # Axbasic strings index from 1
        $index--;

        if (defined $length) {
            return substr($string, $index, $length);
        } else {
            return substr($string, $index);
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::repeat;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::repeat::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # REPEAT$ (string, n)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SN')
        #
        # Expected arguments
        #   $string, $number
        #       - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, $string, $number) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # $number must not be a negative number
        if ($number < 0) {

            return $self->scriptObj->setError(
                'number_NUM_out_of_range',
                $self->_objClass . '->evaluate',
                'NUM', $number,
            );
        }

        # $number must be rounded
        $number = substr(
            $number + 0.5,
            0,
            length(int($number + 0.5)),
        );

        return ($string x $number);
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::rtrim;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::rtrim::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # RTRIM$ (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $arg =~ s/\s+$//;

        return uc($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::str;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::str::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # STR$ (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return $arg . '';
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::time;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::time::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # TIME$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Get the time
        my ($second, $minute, $hour) = localtime();

        # Return the time in the form "HH:MM:SS"
        return (
            sprintf("%02d", ($hour))
            . ':' . sprintf("%02d", ($minute))
            . ':' . sprintf("%02d", ($second)),
        );
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::trim;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::trim::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # TRIM$ (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $arg =~ s/^\s+//;
        $arg =~ s/\s+$//;

        return uc($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::ucase;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::ucase::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # UCASE$ (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return uc($arg);
    }
}

### Axmud-dependent functions (numeric) ###

{ package Language::Axbasic::Function::Intrinsic::Numeric::addfirstroom;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::addfirstroom::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ADDFIRSTROOM ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapWin;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapWin = $self->scriptObj->session->mapWin;

        if (! $mapWin || ! $mapWin->currentRegionmap || $mapWin->currentRegionmap->gridRoomHash) {

            # Automapper window not open, no current regionmap or the current regionmap isn't
            #   empty
            return 0;
        }

        # Attemp to add a first room
        if (! $mapWin->addFirstRoomCallback()) {

            # Operation failed
            return 0;

        } else {

            # Return the number of the room created
            return $mapWin->mapObj->currentRoom->number;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::addlabel;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::addlabel::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ADDLABEL (string, x, y, z)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SNNN')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # Local variables
        my ($mapObj, $wmObj, $regionObj, $regionmapObj, $xPos, $yPos, $zPos, $labelObj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        $wmObj = $mapObj->worldModelObj;

        if (
            ! $mapObj->currentRoom
            || ! $args[0]
        ) {
            # No current room or empty label string
            return 0;
        }

        # Get the current room's parent regionmap
        $regionObj = $wmObj->ivShow('modelHash', $mapObj->currentRoom->parent);
        $regionmapObj = $wmObj->ivShow('regionmapHash', $regionObj->name);
        if (! $regionmapObj) {

            # Failsafe
            return 0;
        }

        # Get the current room's coordinates on the grid, and add (or subtract) the relative
        #   coordinates in the argument list
        $xPos = $mapObj->currentRoom->xPosBlocks + $args[1];
        $yPos = $mapObj->currentRoom->yPosBlocks + $args[2];
        $zPos = $mapObj->currentRoom->zPosBlocks + $args[3];

        # Check that the gridblock is valid
        if (! $regionmapObj->checkGridBlock($xPos, $yPos, $zPos)) {

            return 0;
        }

        # Attempt to add the label
        $labelObj = $wmObj->addLabel(
            $self->scriptObj->session,
            TRUE,       # Update Automapper windows now
            $regionmapObj,
            ($xPos * $regionmapObj->blockWidthPixels),
            ($yPos * $regionmapObj->blockHeightPixels),
            $zPos,
            $args[0],
        );

        if (! $labelObj) {
            return 0;
        } else {
            return $labelObj->number;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::addregion;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::addregion::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ADDREGION (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $regionObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $regionObj = $self->scriptObj->session->worldModelObj->addRegion(
            $self->scriptObj->session,
            TRUE,       # Update Automapper windows now
            $arg,
        );

        if (! $regionObj) {
            return 0;
        } else {
            return $regionObj->number;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::addroom;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::addroom::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ADDROOM (x, y, z)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'NNN')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # Local variables
        my ($mapObj, $wmObj, $regionObj, $regionmapObj, $xPos, $yPos, $zPos, $roomObj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        $wmObj = $mapObj->worldModelObj;

        if (! $mapObj->currentRoom ) {

            # No current room
            return 0;
        }

        # Get the current room's parent regionmap
        $regionObj = $wmObj->ivShow('modelHash', $mapObj->currentRoom->parent);
        $regionmapObj = $wmObj->ivShow('regionmapHash', $regionObj->name);
        if (! $regionmapObj) {

            # Failsafe
            return 0;
        }

        # Get the current room's coordinates on the grid, and add (or subtract) the relative
        #   coordinates in the argument list
        $xPos = $mapObj->currentRoom->xPosBlocks + $args[0];
        $yPos = $mapObj->currentRoom->yPosBlocks + $args[1];
        $zPos = $mapObj->currentRoom->zPosBlocks + $args[2];

        # Check that the gridblock is valid and not occupied by an existing room
        if (
            ! $regionmapObj->checkGridBlock($xPos, $yPos, $zPos)
            || $regionmapObj->fetchRoom($xPos, $yPos, $zPos)
        ) {
            return 0;
        }

        # Attempt to add the room
        $roomObj = $wmObj->addRoom(
            $self->scriptObj->session,
            TRUE,               # Update Automapper windows now
            $regionmapObj->name,
            $xPos,
            $yPos,
            $zPos,
        );

        if (! $roomObj) {
            return 0;
        } else {
            return $roomObj->number;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::addtempregion;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::addtempregion::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ADDTEMPREGION ()
    # ADDTEMPREGION (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form ';S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my (
            $wmObj, $count, $name, $regionObj,
            %regionHash,
        );

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $wmObj = $self->scriptObj->session->worldModelObj;

        # If a region name wasn't specified, we have to create one in the form 'temp_x'. To protect
        #   against infinite loops, give up at 9999
        if (! $arg) {

            # Get a convenient hash of region names for quick lookup
            foreach my $obj ($wmObj->ivValues('regionModelHash')) {

                if ($obj->name) {

                    $regionHash{$obj->name} = undef;
                }
            }

            # First temporary region would be called 'temp_1'
            $count = 0;
            do {

                $count++;
                my $string = 'temp_' . $count;

                if (! exists $regionHash{$string}) {

                    # We can use this name
                    $name = $string;
                }

            } until ($name || $count >= 9999);

        } else {

            $name = $arg;
        }

        if (! $name) {

            # Could not find a name for the temporary region
            return 0;
        }

        # Add the temporary region
        $regionObj = $wmObj->addRegion(
            $self->scriptObj->session,
            TRUE,       # Update Automapper windows now
            $name,
            undef,      # No parent region
            TRUE,       # Temporary region
        );

        if (! $regionObj) {
            return 0;
        } else {
            return $regionObj->number;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::closemap;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::closemap::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # CLOSEMAP ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapWin;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapWin = $self->scriptObj->session->mapWin;
        if (! $mapWin) {

            # The window is already closed
            return 1;

        } else {

            # Try to close the window
            $mapWin->winDestroy();

            if (! $self->scriptObj->session->mapWin) {

                # Window closed successfully
                return 1;

            } else {

                # Could not close window
                return 0;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::counttask;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::counttask::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # COUNTTASK (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my @list;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Get a list of tasks in the current tasklist which match $arg. The ->findTask function
        #   usually accepts the string '-a', but this Axbasic function does not
        if ($arg ne '-a') {

            @list = Games::Axmud::Generic::Cmd->findTask($self->scriptObj->session, $arg);
        }

        return scalar @list;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::delregion;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::delregion::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # DELREGION (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($wmObj, $regionmapObj, $obj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $wmObj = $self->scriptObj->session->worldModelObj;

        # Find a region model object whose name matches $arg
        $regionmapObj = $wmObj->ivShow('regionmapHash', $arg);
        if ($regionmapObj) {

            $obj = $wmObj->ivShow('modelHash', $regionmapObj->number);
        }

        if (! $obj) {

            # No region whose name matches $arg
            return 0;

        } else {

            # Delete the region and all its children (including its rooms and their contents)
            if (
                ! $wmObj->deleteRegions(
                    $self->scriptObj->session,
                    TRUE,       # Update Automapper windows now
                    $obj,
                )
            ) {
                return 0;
            } else {
                return 1;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::deltempregions;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::deltempregions::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # DELTEMPREGIONS ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (
            ! $self->scriptObj->session->worldModelObj->deleteTempRegions(
                $self->scriptObj->session,
                TRUE,       # Update Automapper windows now
            )
        ) {
            return 0;
        } else {
            return 1;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getexitdest;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getexitdest::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETEXITDEST (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($mapObj, $wmObj, $dir, $modelNum, $obj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        $wmObj = $mapObj->worldModelObj;

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        if (
            ! $mapObj->currentRoom
            || ! $mapObj->currentRoom->sortedExitList
            || $arg < 0
            || $arg >= scalar ($mapObj->currentRoom->sortedExitList)
        ) {
            # No current room, no exits in current room or invalid exit number
            return 0;

        } else {

            # Get the exit model object
            $dir = $mapObj->currentRoom->ivIndex('sortedExitList', $arg);
            $modelNum = $mapObj->currentRoom->ivShow('exitNumHash', $dir);
            if (! $modelNum || ! $wmObj->ivExists('exitModelHash', $modelNum)) {

                # Exit model object not found
                return 0;

            } else {

                $obj = $wmObj->ivShow('exitModelHash', $modelNum);
                if (! $obj->destRoom || $obj->randomType ne 'none') {

                    # Exit doesn't have a destination room, or leads to a random destination
                    return 0;

                } else {

                    # Return the numbered exit's destination room
                    return $obj->destRoom;
                }
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getexitnum;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getexitnum::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETEXITNUM (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($mapObj, $wmObj, $dir, $modelNum);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        $wmObj = $mapObj->worldModelObj;

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        if (
            ! $mapObj->currentRoom
            || ! $mapObj->currentRoom->sortedExitList
            || $arg < 0
            || $arg >= scalar ($mapObj->currentRoom->sortedExitList)
        ) {
            # No current room, no exits in current room or invalid exit number
            return 0;

        } else {

            # Get the exit model object
            $dir = $mapObj->currentRoom->ivIndex('sortedExitList', $arg);
            $modelNum = $mapObj->currentRoom->ivShow('exitNumHash', $dir);
            if (! $modelNum || ! $wmObj->ivExists('exitModelHash', $modelNum)) {

                # Exit model object not found
                return 0;

            } else {

                # Return the exit model number
                return $modelNum;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getexittwin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getexittwin::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETEXITTWIN (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($mapObj, $wmObj, $dir, $modelNum, $obj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        $wmObj = $mapObj->worldModelObj;

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        if (
            ! $mapObj->currentRoom
            || ! $mapObj->currentRoom->sortedExitList
            || $arg < 0
            || $arg >= scalar ($mapObj->currentRoom->sortedExitList)
        ) {
            # No current room, no exits in current room or invalid exit number
            return 0;

        } else {

            # Get the exit model object
            $dir = $mapObj->currentRoom->ivIndex('sortedExitList', $arg);
            $modelNum = $mapObj->currentRoom->ivShow('exitNumHash', $dir);
            if (! $modelNum || ! $wmObj->ivExists('exitModelHash', $modelNum)) {

                # Exit model object not found
                return 0;

            } else {

                $obj = $wmObj->ivShow('exitModelHash', $modelNum);
                if (! $obj->twinExit) {

                    # Exit doesn't have a twin exit
                    return 0;

                } else {

                    # Return the numbered exit's twin exit
                    return $obj->twinExit;
                }
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getlostroom;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getlostroom::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETLOSTROOM ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        if (! $mapObj->lastKnownRoom) {

            # Automapper not lost
            return 0;

        } else {

            # Automapper is lost. Return the number of the previous room
            return $mapObj->lastKnownRoom->number;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getobjectalive;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getobjectalive::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETOBJECTALIVE (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($taskObj, $roomObj, $thisObj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $taskObj = $self->scriptObj->session->locatorTask;
        if (! $taskObj) {

            # Locator task not running
            return 0;
        }

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        $roomObj = $taskObj->roomObj;
        if (
            ! $roomObj
            || ! $roomObj->tempObjList
            || $arg < 0
            || scalar $roomObj->tempObjList <= $arg
        ) {
            # Locator task doesn't know current location, current location is empty or the
            #   numbered object doesn't exist
            return 0;

        } else {

            # Return the object's ->aliveFlag
            $thisObj = $roomObj->ivIndex('tempObjList', $arg);
            if (! $thisObj->aliveFlag) {
                return 0;
            } else {
                return 1;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getobjectcount;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getobjectcount::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETOBJECTCOUNT (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($taskObj, $roomObj, $thisObj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $taskObj = $self->scriptObj->session->locatorTask;
        if (! $taskObj) {

            # Locator task not running
            return 0;
        }

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        $roomObj = $taskObj->roomObj;
        if (
            ! $roomObj
            || ! $roomObj->tempObjList
            || $arg < 0
            || scalar $roomObj->tempObjList <= $arg
        ) {
            # Locator task doesn't know current location, current location is empty or the
            #   numbered object doesn't exist
            return 0;

        } else {

            # Return the object's ->multiple
            $thisObj = $roomObj->ivIndex('tempObjList', $arg);
            if (! $thisObj->multiple) {

                # Make sure we don't return an 'undef' value (unlikely)
                return 0;

            } else {

                return $thisObj->multiple;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getregionnum;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getregionnum::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETREGIONNUM ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapWin;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapWin = $self->scriptObj->session->mapWin;
        if (! $mapWin || ! $mapWin->currentRegionmap) {

            # Automapper window closed, or no current region
            return 0;

        } else {

            # Return the number of the current region
            return $mapWin->currentRegionmap->number;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getroomexits;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getroomexits::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETROOMEXITS ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        if (! $mapObj->currentRoom || ! $mapObj->currentRoom->sortedExitList) {

            # No current room or current room has no exits
            return 0;

        } else {

            # Return the number of exits in the current room
            return (scalar $mapObj->currentRoom->sortedExitList);
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getroomnum;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getroomnum::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETROOMNUM ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;

        if (! $mapObj->currentRoom) {

            # No current room
            return 0;

        } else {

            # Return the number of the current room
            return $mapObj->currentRoom->number;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::getroomobjects;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::getroomobjects::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # GETROOMOBJECTS ()
    # GETROOMOBJECTS (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form ';S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($taskObj, $count);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $taskObj = $self->scriptObj->session->locatorTask;

        if (! $taskObj || ! $taskObj->roomObj || ! $taskObj->roomObj->tempObjList) {

            # Locator task not running, does not know current location, or current location is
            #   empty
            return 0;

        } elsif (! $arg) {

            # Return number of objects in the room
            return (scalar $taskObj->roomObj->tempObjList);

        } else {

            # Count matching things
            $count = 0;

            if (
                $arg eq 'weapon' || $arg eq 'armour' || $arg eq 'garment' || $arg eq 'char'
                || $arg eq 'minion' || $arg eq 'sentient' || $arg eq 'creature'
                || $arg eq 'portable' || $arg eq 'decoration' || $arg eq 'custom'
            ) {
                foreach my $obj ($taskObj->roomObj->tempObjList) {

                    if ($obj->category eq $arg) {

                        $count++;
                    }
                }

            } elsif ($arg eq 'living') {

                foreach my $obj ($taskObj->roomObj->tempObjList) {

                    if ($obj->aliveFlag) {

                        $count++;
                    }
                }

            } elsif ($arg eq 'not_living') {

                foreach my $obj ($taskObj->roomObj->tempObjList) {

                    if (! $obj->aliveFlag) {

                        $count++;
                    }
                }

            } else {

                # Unrecognised string
                return 0;
            }

            # Return the number of matching objects (may be 0)
            return $count;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ifacecount;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ifacecount::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # IFACECOUNT ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Return the number of LA::Notifications received and not yet processed
        return $self->scriptObj->ivNumber('notificationList');
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ifacenum;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ifacenum::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # IFACENUM ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $obj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (! $self->scriptObj->notificationList || $self->scriptObj->currentNotification < 0) {

            # The notification list is empty
            return -1;

        } else {

            # Get the current notification
            $obj = $self->scriptObj->ivIndex(
                'notificationList',
                $self->scriptObj->currentNotification,
            );

            # Return its corresponding interface number
            return $obj->number;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ifacepos;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ifacepos::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # IFACEPOS ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Return the number of index of the current LA::Notification. Perl indexes start from 0,
        #   but Axbasic indexes start from 1. (If the notification list is empty,
        #   ->currentNotification is set to -1, and this function returns 0)
        return ($self->scriptObj->currentNotification + 1);
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ifacestrings;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ifacestrings::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # IFACESTRINGS ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $obj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (! $self->scriptObj->notificationList || $self->scriptObj->currentNotification < 0) {

            # The notification list is empty
            return -1;

        } else {

            # Get the current notification
            $obj = $self->scriptObj->ivIndex(
                'notificationList',
                $self->scriptObj->currentNotification,
            );

            # Return the number of backreferences stored in it
            return $obj->ivNumber('backRefList');
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ifacetime;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ifacetime::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # IFACETIME ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $obj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (! $self->scriptObj->notificationList || $self->scriptObj->currentNotification < 0) {

            # The notification list is empty
            return -1;

        } else {

            # Get the current notification
            $obj = $self->scriptObj->ivIndex(
                'notificationList',
                $self->scriptObj->currentNotification,
            );

            # Return the time it was received
            return $obj->time;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::ismap;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::ismap::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ISMAP

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Test whether the Automapper window is open
        if (! $self->scriptObj->session->mapWin) {

            # Window not open
            return 0;

        } else {

            # Window open
            return 1;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::isscript;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::isscript::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ISSCRIPT (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my @list;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Get a list of currently-running Script tasks
        @list = Games::Axmud::Generic::Cmd->findTask($self->scriptObj->session, 'script_task');
        foreach my $taskObj (@list) {

            # If this task is running a script called $arg, return 1
            if ($taskObj->scriptName eq $arg) {

                return 1;
            }
        }

        # No Script tasks running scripts called $arg
        return 0;
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::istask;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::istask::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ISTASK ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Test whether the script is being run by a task
        if ($self->scriptObj->parentTask) {

            # Window open
            return 1;

        } else {

            # Window not open
            return 0;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::iswin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::iswin::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # ISWIN ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Test whether the script is being run by a task and, if so, the task window is open
        if ($self->scriptObj->parentTask && $self->scriptObj->parentTask->taskWinFlag) {

            # Window open
            return 1;

        } else {

            # Window not open
            return 0;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::openmap;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::openmap::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # OPENMAP ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if ($self->scriptObj->session->mapWin) {

            # The window is already open
            return 1;

        } else {

            # Try to open the window
            $self->scriptObj->session->mapObj->openWin();
            if ($self->scriptObj->session->mapWin) {

                # Window opened successfully
                return 1;

            } else {

                # Could not open window
                return 0;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::setlight;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::setlight::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SETLIGHT (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $wmObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $wmObj = $self->scriptObj->session->worldModelObj;

        # Set the light status
        $wmObj->set_lightStatus($arg);
        if ($wmObj->lightStatus ne $arg) {

            # Operation failed
            return 0;

        } else {

            # Operation succeeded
            return 1;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::setmapmode;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::setmapmode::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SETMAPMODE (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapWin;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Check that the Automapper window is open, and that a recognised string has been used
        $mapWin = $self->scriptObj->session->mapWin;

        if (! $mapWin || ($arg ne 'wait' && $arg ne 'follow' && $arg ne 'update')) {

            return 0;

        } else {

            # Make sure that the specified mode is in its lower-case form
            $arg = lc($arg);
            # Try to set the current mode
            $mapWin->setMode($arg);

            # See if the mode was correctly set
            if ($mapWin->mode eq $arg) {

                # Mode correctly set, or mode was already set
                return 1;

            } else {

                # Mode not set
                return 0;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::setregion;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::setregion::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SETREGION (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapWin;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Check that the Automapper window is open
        $mapWin = $self->scriptObj->session->mapWin;
        if (! $mapWin) {

            return 0;

        } else {

            # Set the current region. Return 1 on success, 0 on failure
            if (! $mapWin->setCurrentRegion($arg)) {
                return 0;
            } else {
                return 1;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::setregionnum;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::setregionnum::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SETREGIONNUM (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($mapWin, $obj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapWin = $self->scriptObj->session->mapWin;

        # Check that the Automapper window is open
        if (! $mapWin) {

            return 0;

        } else {

            # Check that the world model number $arg exists, and that it is a region
            $obj = $self->scriptObj->session->worldModelObj->ivShow('modelHash', $arg);
            if (! $obj || $obj->category ne 'region') {

                return 0;

            } else {

                # Set the current region. Return 1 on success, 0 on failure
                if (! $mapWin->setCurrentRegion($obj->name)) {
                    return 0;
                } else {
                    return 1;
                }
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::setroomnum;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::setroomnum::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SETROOMNUM ()
    # SETROOMNUM (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form ';N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($mapObj, $obj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;

        # Check that a valid value for $arg (if specified at all) was supplied
        if ($arg && $arg < 1) {

            return 0;
        }

        # If $arg was specified...
        if ($arg) {

            # ...check it's a valid room model object
            $obj = $self->scriptObj->session->worldModelObj->ivShow('modelHash', $arg);
            if (! $obj || $obj->category ne 'room') {

                return 0;
            }

            # Attempt to set the current room
            $mapObj->setCurrentRoom($obj);
            if (! $mapObj->currentRoom || $mapObj->currentRoom ne $obj) {

                # Set operation failed
                return 0;

            } else {

                # Set operation succeeded
                return 1;
            }

        } else {

            # Attempt to usnet the current room
            $mapObj->setCurrentRoom();
            if ($mapObj->currentRoom) {

                # Unset operation failed
                return 0;

            } else {

                # Unset operation succeeded
                return 1;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::setroomtagged;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::setroomtagged::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SETROOMTAGGED (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($mapObj, $wmObj, $number, $obj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        $wmObj = $mapObj->worldModelObj;

        # Check that $arg is a tag used by a world model room, if it was specified
        if ($arg && ! $wmObj->ivExists('roomTagHash', $arg)) {

            # The room tag isn't valid
            return 0;
        }

        # If $arg was specified...
        if ($arg) {

            # Get the corresponding room
            $number = $wmObj->ivShow('roomTagHash', $arg);
            $obj = $wmObj->ivShow('modelHash', $number);
            if (! $obj) {

                return 0;
            }

            # Attempt to set the current room
            $mapObj->setCurrentRoom($obj);
            if (! $mapObj->currentRoom || $mapObj->currentRoom ne $obj) {

                # Set operation failed
                return 0;

            } else {

                # Set operation succeeded
                return 1;
            }

        } else {

            # Attempt to usnet the current room
            $mapObj->setCurrentRoom();
            if ($mapObj->currentRoom) {

                # Unset operation failed
                return 0;

            } else {

                # Unset operation succeeded
                return 1;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::showprofile;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::showprofile::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # SHOWPROFILE ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # A value of 'undef' means 'use the current world'
        if (! defined $self->scriptObj->useProfile) {

            return $self->scriptObj->session->currentWorld->name;

        } else {

            return $self->scriptObj->useProfile;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::Numeric::timestamp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::Numeric::timestamp::ISA = qw(
        Language::Axbasic::Function::Intrinsic::Numeric
    );

    # TIMESTAMP ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $session;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $session = $self->scriptObj->session;

        return (int($session->sessionLoopObj->spinTime - $session->sessionLoopObj->startTime));
    }
}

### Axmud-dependent functions (string) ###

{ package Language::Axbasic::Function::Intrinsic::String::abbrevdir;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::abbrevdir::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # ABBREVDIR$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return $self->scriptObj->session->currentDict->abbrevDir($arg);
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::clientdate;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::clientdate::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # CLIENTDATE$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return $axmud::DATE;
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::clientname;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::clientname::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # CLIENTNAME$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return $axmud::SCRIPT;
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::clientversion;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::clientversion::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # CLIENTVERSION$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return $axmud::VERSION;
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::findtask;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::findtask::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # FINDTASK$ (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my (
            $taskObj,
            @list,
        );

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Get a list of tasks in the current tasklist which match $arg. The ->findTask function
        #   usually accepts the string '-a', but this Axbasic function does not
        if ($arg ne '-a') {

            @list = Games::Axmud::Generic::Cmd->findTask($self->scriptObj->session, $arg);
        }

        if (! @list) {

            # No matching tasks found
            return '';

        } else {

            # One or more matching tasks found. Return the first one
            $taskObj = $list[0];
            return $taskObj->uniqueName;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getexit;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getexit::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETEXIT$ (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        if (
            ! $mapObj->currentRoom
            || ! $mapObj->currentRoom->sortedExitList
            || $arg < 0
            || $arg >= scalar ($mapObj->currentRoom->sortedExitList)
        ) {
            # No current room, no exits in current room, invalid exit number or numbered exit
            #   doesn't exist
            return '';

        } else {

            # Return the numbered exit
            return $mapObj->currentRoom->ivIndex('sortedExitList', $arg);
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getexitdrawn;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getexitdrawn::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETEXITDRAWN$ (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($mapObj, $wmObj, $dir, $exitNum, $obj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        $wmObj = $mapObj->worldModelObj;

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        if (
            ! $mapObj->currentRoom
            || ! $mapObj->currentRoom->sortedExitList
            || $arg < 0
            || $arg >= scalar ($mapObj->currentRoom->sortedExitList)
        ) {
            # No current room, no exits in current room, invalid exit number or numbered exit
            #   doesn't exist
            return '';

        } else {

            # Get the exit model object
            $dir = $mapObj->currentRoom->ivIndex('sortedExitList', $arg);
            $exitNum = $mapObj->currentRoom->ivShow('exitNumHash', $dir);
            if (! $exitNum || ! $wmObj->ivExists('exitModelHash', $exitNum)) {

                # Exit model object not found
                return '';

            } else {

                $obj = $wmObj->ivShow('exitModelHash', $exitNum);
                if (! $obj->mapDir) {

                    # Exit is unallocatable
                    return '';

                } else {

                    # Return the numbered exit's primary direction
                    return $obj->mapDir;
                }
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getexitstatus;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getexitstatus::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETEXITSTATUS$ (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($mapObj, $wmObj, $dir, $exitNum, $obj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        $wmObj = $mapObj->worldModelObj;

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        if (
            ! $mapObj->currentRoom
            || ! $mapObj->currentRoom->sortedExitList
            || $arg < 0
            || $arg >= scalar ($mapObj->currentRoom->sortedExitList)
        ) {
            # No current room, no exits in current room, invalid exit number or numbered exit
            #   doesn't exist
            return '';

        } else {

            # Get the exit model object
            $dir = $mapObj->currentRoom->ivIndex('sortedExitList', $arg);
            $exitNum = $mapObj->currentRoom->ivShow('exitNumHash', $dir);
            if (! $exitNum || ! $wmObj->ivExists('exitModelHash', $exitNum)) {

                # Exit model object not found
                return '';

            } else {

                $obj = $wmObj->ivShow('exitModelHash', $exitNum);

                # Return the exit's status
                if ($obj->superFlag) {
                    return 'super';
                } elsif ($obj->regionFlag) {
                    return 'region';
                } elsif ($obj->brokenFlag) {
                    return 'broken';
                } else {
                    return 'normal';
                }
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getexittype;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getexittype::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETEXITTYPE$ (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($mapObj, $wmObj, $dir, $exitNum, $obj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        $wmObj = $mapObj->worldModelObj;

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        if (
            ! $mapObj->currentRoom
            || ! $mapObj->currentRoom->sortedExitList
            || $arg < 0
            || $arg >= scalar ($mapObj->currentRoom->sortedExitList)
        ) {
            # No current room, no exits in current room, invalid exit number or numbered exit
            #   doesn't exist
            return '';

        } else {

            # Get the exit model object
            $dir = $mapObj->currentRoom->ivIndex('sortedExitList', $arg);
            $exitNum = $mapObj->currentRoom->ivShow('exitNumHash', $dir);
            if (! $exitNum || ! $wmObj->ivExists('exitModelHash', $exitNum)) {

                # Exit model object not found
                return '';

            } else {

                $obj = $wmObj->ivShow('exitModelHash', $exitNum);

                # Return the type of exit
                if ($obj->exitOrnament eq 'impass') {

                    return 'impassable';

                } elsif ($obj->drawMode eq 'temp_alloc' || $obj->drawMode eq 'temp_unalloc') {

                    return 'unallocated';

                } elsif ($obj->destRoom) {

                    if ($obj->twinExit) {
                        return 'two_way';
                    } elsif ($obj->retraceFlag) {
                        return 'retrace';
                    } elsif ($obj->oneWayFlag) {
                        return 'one_way';
                    } elsif ($obj->randomType ne 'none') {
                        return 'random';
                    } else {
                        return 'uncertain';
                    }

                } elsif ($obj->randomType ne 'none') {

                    return 'random';

                } else {

                    return 'incomplete';
                }
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getlight;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getlight::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETLIGHT$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return $self->scriptObj->session->worldModelObj->lightStatus;
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getmapmode;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getmapmode::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETMAPMODE$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapWin;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapWin = $self->scriptObj->session->mapWin;

        if (! $mapWin || ! $mapWin->mode) {

            # Automapper window closed, or no mode set (unlikely)
            return '';

        } else {

            # Return the mode
            return $mapWin->mode;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getobject;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getobject::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETOBJECT$ (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($taskObj, $roomObj, $thisObj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $taskObj = $self->scriptObj->session->locatorTask;
        if (! $taskObj) {

            # Locator task not running
            return '';
        }

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        $roomObj = $taskObj->roomObj;
        if (
            ! $roomObj
            || ! $roomObj->tempObjList
            || $arg < 0
            || scalar $roomObj->tempObjList <= $arg
        ) {
            # Locator task doesn't know current location, current location is empty or the
            #   numbered object doesn't exist
            return '';

        } else {

            # Return the object's base string
            $thisObj = $roomObj->ivIndex('tempObjList', $arg);

            if (defined $thisObj->baseString) {
                return $thisObj->baseString;
            } else {
                return '';
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getobjectnoun;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getobjectnoun::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETOBJECTNOUN$ (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($taskObj, $roomObj, $thisObj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $taskObj = $self->scriptObj->session->locatorTask;
        if (! $taskObj) {

            # Locator task not running
            return '';
        }

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        $roomObj =  $taskObj->roomObj;
        if (
            ! $roomObj
            || ! $roomObj->tempObjList
            || $arg < 0
            || scalar $roomObj->tempObjList <= $arg
        ) {
            # Locator task doesn't know current location, current location is empty or the
            #   numbered object doesn't exist
            return '';

        } else {

            # Return the object's main noun, if set
            $thisObj = $roomObj->ivIndex('tempObjList', $arg);

            if (defined $thisObj->noun) {
                return $thisObj->noun;
            } else {
                return '';
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getobjecttype;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getobjecttype::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETOBJECTTYPE$ (number)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'N')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my ($taskObj, $roomObj, $thisObj);

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $taskObj = $self->scriptObj->session->locatorTask;
        if (! $taskObj) {

            # Locator task not running
            return '';
        }

        # Perl indexes start at 0, but Axbasic indexes start at 1
        $arg--;

        $roomObj =  $taskObj->roomObj;
        if (
            ! $roomObj
            || ! $roomObj->tempObjList
            || $arg < 0
            || scalar $roomObj->tempObjList <= $arg
        ) {
            # Locator task doesn't know current location, current location is empty or the
            #   numbered object doesn't exist
            return '';

        } else {

            # Return the object's category
            $thisObj = $roomObj->ivIndex('tempObjList', $arg);

            if (defined $thisObj) {
                return $thisObj->category;
            } else {
                return '';
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getregion;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getregion::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETREGION$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapWin;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapWin = $self->scriptObj->session->mapWin;
        if (! $mapWin || ! $mapWin->currentRegionmap) {

            # Automapper window closed, or no current region
            return '';

        } else {

            # Return the name of the current region
            return $mapWin->currentRegionmap->name;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getroomdescrip;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getroomdescrip::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETROOMDESCRIP$ ()
    # GETROOMDESCRIP$ (string)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form ';S')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;
        if (! $mapObj->currentRoom) {

            # No current room
            return '';

        } else {

            # If the user didn't specify a light status, use the current light status
            if (! $arg) {

                $arg = $mapObj->worldModelObj->lightStatus;
            }

            # Return the matching verbose descrip (if there is one) or an empty string otherwise
            if ($mapObj->currentRoom->ivExists('descripHash', $arg)) {

                return $mapObj->currentRoom->ivShow('descripHash', $arg)

            } else {

                return '';
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getroomguild;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getroomguild::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETROOMGUILD$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;

        if (! $mapObj->currentRoom || ! $mapObj->currentRoom->roomGuild) {

            # No current room, or current room has no room guild
            return '';

        } else {

            # Return the current room's room guild
            return $mapObj->currentRoom->roomGuild;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getroomsource;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getroomsource::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETROOMSOURCE$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;

        if (
            ! $mapObj->currentRoom
            || (! $mapObj->currentRoom->sourceCodePath && ! $mapObj->currentRoom->virtualAreaPath)
        ) {
            # No current room, or current room has no source code path set
            return '';

        } else {

            # Return the current room's virtual area path, if set; otherwise return its source code
            #   path
            if ($mapObj->currentRoom->virtualAreaPath) {
                return $mapObj->currentRoom->virtualAreaPath;
            } else {
                return $mapObj->currentRoom->sourceCodePath;
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getroomtag;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getroomtag::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETROOMTAG$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;

        if (! $mapObj->currentRoom || ! $mapObj->currentRoom->roomTag) {

            # No current room, or current room has no room tag
            return '';

        } else {

            # Return the current room's room tag
            return $mapObj->currentRoom->roomTag;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::getroomtitle;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::getroomtitle::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # GETROOMTITLE$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $mapObj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        $mapObj = $self->scriptObj->session->mapObj;

        if (
            ! $mapObj->currentRoom
            || ! $mapObj->currentRoom->titleList
        ) {
            # No current room, or current room has no title set
            return '';

        } else {

            # Return the current room's (first) title
            return $mapObj->currentRoom->ivFirst('titleList');
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::iface;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::iface::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # IFACE$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (! $self->scriptObj->depInterfaceName) {

            # Either no dependent interface has been created by this script, or the last attempt
            #   failed
            return '';

        } else {

            # The IV contains the name of the dependent interface
            return $self->scriptObj->depInterfaceName;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::ifacename;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::ifacename::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # IFACENAME$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $obj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (! $self->scriptObj->notificationList || $self->scriptObj->currentNotification < 0) {

            # The notification list is empty, so return an empty string
            return '';

        } else {

            # Get the current notification
            $obj = $self->scriptObj->ivIndex(
                'notificationList',
                $self->scriptObj->currentNotification,
            );

            # Return its name of the corresponding interface
            return $obj->name;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::ifacepop;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::ifacepop::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # IFACEPOP$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $obj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (! $self->scriptObj->notificationList || $self->scriptObj->currentNotification < 0) {

            # The notification list is empty, so return an empty string
            return '';

        } else {

            # Get the current notification
            $obj = $self->scriptObj->ivIndex(
                'notificationList',
                $self->scriptObj->currentNotification,
            );

            if (! $obj->backRefList) {

                # No more backrefs to return
                return '';

            } else {

                # Return the last backreference, removing it from its list
                return $obj->ivPop('backRefList');
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::ifaceshift;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::ifaceshift::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # IFACESHIFT$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $obj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (! $self->scriptObj->notificationList || $self->scriptObj->currentNotification < 0) {

            # The notification list is empty, so return an empty string
            return '';

        } else {

            # Get the current notification
            $obj = $self->scriptObj->ivIndex(
                'notificationList',
                $self->scriptObj->currentNotification,
            );

            if (! $obj->backRefList) {

                # No more backrefs to return
                return '';

            } else {

                # Return the first backreference, removing it from its list
                return $obj->ivShift('backRefList');
            }
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::ifacetext;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::ifacetext::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # IFACETEXT$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $obj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (! $self->scriptObj->notificationList || $self->scriptObj->currentNotification < 0) {

            # The notification list is empty, so return an empty string
            return '';

        } else {

            # Get the current notification
            $obj = $self->scriptObj->ivIndex(
                'notificationList',
                $self->scriptObj->currentNotification,
            );

            # Return its line of text
            return $obj->text;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::ifacetype;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::ifacetype::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # IFACETYPE$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $obj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        if (! $self->scriptObj->notificationList || $self->scriptObj->currentNotification < 0) {

            # The notification list is empty, so return an empty string
            return '';

        } else {

            # Get the current notification
            $obj = $self->scriptObj->ivIndex(
                'notificationList',
                $self->scriptObj->currentNotification,
            );

            # Return its category
            return $obj->category;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::popup;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::popup::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # POPUP$ (type, text, response)

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form 'SSS')
        #
        # Expected arguments
        #   @args   - The list of arguments supplied to the function
        #
        # Return values
        #   The return value of the function

        my ($self, @args) = @_;

        # Local variables
        my ($type, $response, $choice);

        # (No improper arguments to check)

        # Evaluate the function and return the value

        # Check that the type is one of the values permitted by GA::Generic::Win->showMsgDialogue
        #   and, if not, use a default type
        $type = $args[0];
        if (
            $type ne 'info' && $type ne 'warning' && $type ne 'error' && $type ne 'question'
        ) {
            $type = 'info';
        }

        # Substitute a hyphen for any underlines or spaces in the response
        $response = $args[2];
        $response =~ s/_/-/;
        $response =~ s/\s/-/;
        # Check that the response is one of the values permitted by
        #   GA::Generic::Win->showMsgDialogue and, if not, use a default respone
        if (
            $response ne 'none' && $response ne 'ok' && $response ne 'close'
            && $response ne 'cancel' && $response ne 'yes-no' && $response ne 'ok-cancel'
        ) {
            $response = 'ok';
        }

        # Open a 'dialogue' window to prompt the user
        $choice = $self->scriptObj->session->mainWin->showMsgDialogue(
            $self->scriptObj->name,     # Use the script name as the window's title
            $type,
            $args[1],
            $response,
        );

        if (! $choice || $choice eq 'delete-event') {
            return "";
        } else {
            return $choice;
        }
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::scriptname;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::scriptname::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # SCRIPTNAME$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # Local variables
        my $obj;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return $self->scriptObj->name;
    }
}

{ package Language::Axbasic::Function::Intrinsic::String::unabbrevdir;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Function::Intrinsic::String::unabbrevdir::ISA = qw(
        Language::Axbasic::Function::Intrinsic::String
    );

    # UNABBREVDIR$ ()

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Expression::Function->evaluate (using arguments in the form '')
        #
        # Expected arguments
        #   $arg    - The first (and only) argument in the argument list
        #
        # Return values
        #   The return value of the function

        my ($self, $arg) = @_;

        # (No improper arguments to check)

        # Evaluate the function and return the value
        return $self->scriptObj->session->currentDict->unabbrevDir($arg);
    }
}

# Package must return true
1
