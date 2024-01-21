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
# Language::Axbasic::Expression, based on Language::Basic by Amir Karger

{ package Language::Axbasic::Expression;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::ISA = qw(
        Language::Axbasic
    );

    # Paraphrased from Language::Basic:
    # Every Axbasic statement is made up of keywords (like 'data', 'print', 'if' etc) and
    #   expressions
    # Expressions include not just the standard arithmetic and boolean expressions (like 1 + 2), but
    #   also lvalues (scalar variables or arrays), functions and constants
    # Axbasic expressions are represented by various objects of subclasses of LA::Expression
    # Most LA::Expressions are in turn made up of other LA::Expressions
    # For example, a LA::Expression::Arithmetic may be made up of two
    #   LA::Expression::Multiplicatives and a 'plus'
    # 'Atoms' (indivisible LA::Expressions) include things like LA::Expression::Constants and
    #   LA::Expression:Lvalues (variables)
    #
    # The LA::Expression hierarchy
    #
    # A bunch of LA::Expression subclasses represent various kinds of BASIC expressions. These
    #   subclasses closely follow the BASIC syntax diagram.
    # Expressions can be classified in two ways, which are sort of vertical and horizontal. One
    #   classification method is what subexpressions (if any) an expression is made of. For example,
    #   an Arith. Exp. is made up of one or more Mult. Exps. connected by plus or minus signs, while
    #   a Mult. Exp. is made up of one or more Unary Exps. This is a hierarchical (or vertical)
    #   distinction, important for building up the tree of objects that represent a BASIC
    #   expression.
    #
    # (Note that not all levels in the hierarchy have to be filled. We don't bother making an
    #   Arith. Exp. which contains just one Mult. Exp. which contains just one Unary Exp.
    #   Instead, we just use the Unary Exp. itself (when it's safe to do so!)
    #
    # The second way of classifying expressions is by their return type. A String Exp. is a string
    #   constant, a string variable, a string function, or some other expression whose value when
    #   evaluated will be a string. A Numeric Exp. evaluates to a number, and a Boolean to a True or
    #   False value.  This distinction is important for typechecking and finding syntax errors in
    #   BASIC code.  (Note that in BASIC -- unlike Perl or C -- you can't "cast" a boolean value
    #   into an integer or string. This actually makes parsing more difficult.)
    #
    # Some expressions don't exactly fit any of these distinctions.  For example, an ArgList
    #   evaluates to a list of expressions, each of which may be Numeric or Boolean.
    #
    # Subclass methods
    #
    # Each subclass has (at least) two methods:
    #
    #   ->new
    #       - Takes a class and a LA::TokenGroup (and possibly some other args). It shifts one or
    #           more tokens from the token group, parsing them, creating a new object of that class,
    #           and setting various IVs in the object, which it returns
    #       - If the tokens don't match the class, ->new returns 'undef'
    #       - If an expression contains just one subexpression often we'll just return the
    #           subexpression.  So if an Arith. Exp.  contains just one Mult. Exp., we'll just
    #           return the Axbasic:Expression::Multiplicative object and not a
    #           LA::Expression:::Arithmetic object.
    #
    #   ->evaluate
    #       - Actually calculates the value of the expression. For a string or numeric constant or
    #           variable, that just means taking the stored value of that object. For other
    #           Expressions, you actually need to do some calculations

    # Sub-classes
    {
        package Language::Axbasic::Expression::LogicalOr;
        package Language::Axbasic::Expression::LogicalAnd;
        package Language::Axbasic::Expression::Relational;

        package Language::Axbasic::Expression::Arithmetic;
        package Language::Axbasic::Expression::Multiplicative;
        package Language::Axbasic::Expression::Unary;

        package Language::Axbasic::Expression::Lvalue;
        package Language::Axbasic::Expression::ArgList;
        package Language::Axbasic::Expression::Function;
        package Language::Axbasic::Expression::Subroutine;
        package Language::Axbasic::Expression::Constant;

        package Language::Axbasic::Expression::Numeric;
        package Language::Axbasic::Expression::String;
        package Language::Axbasic::Expression::Boolean;
    }

    ##################
    # Constructors

#   sub new {}          # Each subclass must have its own ->new

    sub setReturnType {

        # Paraphrased from Language::Basic:
        # Most expressions have a "return type" that's String, Boolean, or Numeric.
        # (Arglists don't, since they hold a list of expressions.)
        #
        # An arithmetic expression is a LA::Expression::Arithmetic::Numeric if it's made up of
        #   LA::Expression::Multiplicative::Numeric expressions, but
        #   LA::Expression::Arithmetic::String if it's got a LA::Unary::String in it. We never mix
        #   expression types (except within Arglists)
        # This sub therefore blesses an object to its String/Numeric/Boolean subclass depending on
        #   the type of the sub-expression (and returns the newly blessed object.)
        #
        # Usually the sub-expression is itself a LA::Expression, but not always. We test for subexps
        #   of, e.g., LA::String rather than LA::Expression::String, because we may be setting
        #   return type based on a LA::Variable::String or LA::Function::String, which aren't
        #   LA::Expressions.
        #
        # Expected arguments
        #   $subExp     - The subexpression
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-blessed object on success

        my ($self, $subExp, $check) = @_;

        # Local variables
        my (
            $class, $subClass, $type,
            @typeList,
        );

        # Check for improper arguments
        if (! defined $subExp || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setReturnType', @_);
        }

        $class = $self->_objClass;
        if ($class ne ref($self)) {

            return $self->scriptObj->setDebug(
                'Error refining class ' . $class . ' (mismatched class)',
                $self->_objClass . '->setReturnType',
            );
        }

        # Don't re-bless this object if it is already blessed
        @typeList = qw(String Numeric Boolean);
        foreach my $word (@typeList) {

            if ($self->isa('Language::Axbasic::Expression::' . $word)) {

                return $self;
            }
        }

        # Get the return type
        OUTER: foreach my $word (@typeList) {

            # LA::Function::String
            if ($subExp->isa('Language::Axbasic::' . $word)) {

                $type = $word;
                last OUTER;
            }
        }

        if (! defined $type) {

            return $self->scriptObj->setDebug(
                'Error refining class ' . $class,
                $self->_objClass . '->setReturnType',
            );
        }

        # Bless the subclass
        $subClass = $class . '::' . $type;
        bless $self, $subClass;

        return $self;
    }

    ##################
    # Methods

#   sub evaluate {}     # Each subclass must have its own ->evaluate

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Language::Axbasic::Expression::Arithmetic;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Arithmetic::ISA = qw(
        Language::Axbasic::Expression
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Paraphrased from Language::Basic:
        # An arithmetic expression is a set of multiplicative expressions connected by plus or minus
        #   signs. (String expressions can only be connected by plus, which is the Axbasic
        #   concatenation operator.)
        #
        # In Axbasic, Arithmetic expressions can't contain Boolean expressions. However, parentheses
        #   can confuse things.
        # LA::Expression::Relational is one of:
        #   (1) LA::Expression::Arithmetic Rel. Op. LA::Expression::Arithmetic
        #   (2) (Logical Or)
        # It calls LA::Expression::Arithmetic->new with 'maybe_boolean' sometimes, to tell
        #   LA::Expression::Arithemetic->new that if it finds a (parenthesisesed) Boolean
        #   expression, it's just case #2 above. (Otherwise, a Boolean subexpression is an error.)
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of the line's token group
        #
        # Optional arguments
        #   $maybeBoolean   - Set to 'maybe_boolean' or 'undef'
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Otherwise returns either the blessed reference to this object, or the blessed reference
        #       to a multiplicative expression object

        my ($class, $scriptObj, $tokenGroupObj, $maybeBoolean, $check) = @_;

        # Local variables
        my (
            $expression, $token,
            @expList, @opList,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $tokenGroupObj || ! defined $scriptObj
            || (defined $maybeBoolean && $maybeBoolean ne 'maybe_boolean')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Test the expression to see if it evaluates to a simple Boolean value. If $maybeBoolean is
        #   set, return the Boolean value; otherwise Boolean values constitute an error
        $expression = Language::Axbasic::Expression::Multiplicative->new(
            $scriptObj,
            $tokenGroupObj,
            $maybeBoolean,
        );

        if (! defined $expression) {

            return undef;

        } elsif ($expression->isa('Language::Axbasic::Expression::Boolean')) {

            if ($maybeBoolean) {

                return $expression;

            } else {

                return $scriptObj->setError(
                    'expected_non-boolean_expression',
                    $class . '->new',
                );
            }
        }

        # The do..until loop is necessary in case we have an expression like 1+2+3
        # It will effectively evaluate the +, - operators left to right
        push (@expList, $expression);

        # An arithmetic expression is a set of multiplicative expressions connected by plus or minus
        #   signs. Convert the expression into a series of multiplicative expressions and
        #   corresponding operators (we already have the first multiplicative expression in the
        #   sequence, $expressionressions[0], so the first token to look for is an operator)
        do {

            $token = $tokenGroupObj->shiftTokenIfCategory('arithmetic_operator');

            if (defined $token) {

                # Push the operator (represented by $token) and the expression that follows it into
                #   the lists @opList and @expList
                push (@opList, $token->tokenText);

                $expression = Language::Axbasic::Expression::Multiplicative->new(
                    $scriptObj,
                    $tokenGroupObj,
                );

                if (! defined $expression) {

                    return undef;

                } elsif ($expression->isa('Language::Axbasic::Expression::Boolean')) {

                    return $scriptObj->setError(
                        'expected_non-boolean_expression',
                        $class . '->new',
                    );
                }

                push (@expList, $expression);
            }

        } until (! defined $token);

        # If there's only one multiplicative expression, don't bother creating an arithmetic
        #   expression object. Just return the multiplicative expression
        if (! @opList) {

            return $expression;
        }

        # Otherwise, create an arithmetic expression object

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

            expList                     => \@expList,
            opList                      => \@opList,
        };

        bless $self, $class;
        # Bless to LA::Expression::String or ::Numeric
        $self->setReturnType($expression);

        return $self;
    }

    ##################
    # Methods

#   sub evaluate {}     # Each subclass must have its own ->evaluate

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub expList
        { my $self = shift; return @{$self->{expList}}; }
    sub opList
        { my $self = shift; return @{$self->{opList}}; }
}

{ package Language::Axbasic::Expression::Arithmetic::String;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Arithmetic::String::ISA = qw(
        Language::Axbasic::Expression::Arithmetic
        Language::Axbasic::Expression::String
    );

    ##################
    # Constructors

#   sub new {}          # Each subclass must have its own ->new

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        # Sub-class of LA::Expression::Arithmetic whose return type has been set to 'String'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Otherwise returns the value of the expression

        my ($self, $check) = @_;

        # Local variables
        my (
            $obj, $expression, $operator, $nextExpression,
            @expList, @opList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Import the lists of expressions and operators
        @expList = $self->expList;
        # (From Language::Basic: operators ought to be all pluses, since that's all BASIC can do)
        @opList = $self->opList;

        # Evaluate the first expression, than add each successive operator-expression pair
        $obj = shift @expList;
        $expression = $obj->evaluate();
        if (! defined $expression) {

            return undef;
        }

        while ($operator = shift @opList) {

            $obj = shift @expList;
            $nextExpression = $obj->evaluate();
            if (! defined $nextExpression) {

                return undef;
            }

            if ($operator eq '&') {

                $expression .= $nextExpression;

            } else {

                return $self->scriptObj->setError(
                    'illegal_operator_in_arithmetic_expression',
                    $self->_objClass . '->evaluate',
                );
            }
        }

        # Return the value of the whole expression
        return $expression;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Language::Axbasic::Expression::Arithmetic::Numeric;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Arithmetic::Numeric::ISA = qw(
        Language::Axbasic::Expression::Arithmetic
        Language::Axbasic::Expression::Numeric
    );

    ##################
    # Constructors

#   sub new {}          # Each subclass must have its own ->new

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        # Sub-class of LA::Expression::Arithmetic whose return type has been set to 'Numeric'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Otherwise returns the value of the expression

        my ($self, $check) = @_;

        # Local variables
        my (
            $obj, $expression, $operator, $nextExpression,
            @expList, @opList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Import the lists of expressions and operators
        @expList = $self->expList;
        @opList = $self->opList;

        # Evaluate the first expression, than add each successive operator-expression pair
        $obj = shift @expList;
        $expression = $obj->evaluate();
        if (! defined $expression) {

            return undef;
        }

        # Need to check that $expression is numeric, or we'll get a funny Perl error when we try to
        #   add/subtract from it
        # NB We don't check the remaining operands because they're treated as string concatenations
        #   by Axbasic
        if (! Scalar::Util::looks_like_number($expression)) {

            return $self->scriptObj->setError(
                'type_mismatch_error',
                $self->_objClass . '->evaluate',
            );
        }

        while ($operator = shift @opList) {

            $obj = shift @expList;
            $nextExpression = $obj->evaluate;
            if (! defined $nextExpression || ! Scalar::Util::looks_like_number($nextExpression)) {

                return undef;
            }

            if ($operator eq '+') {

                $expression = $expression + $nextExpression;

            } elsif ($operator eq '-') {

                $expression = $expression - $nextExpression;

            } else {

                return $self->scriptObj->setError(
                    'illegal_operator_in_arithmetic_expression',
                    $self->_objClass . '->evaluate',
                );
            }
        }

        # Return the value of the whole expression
        return $expression;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Language::Axbasic::Expression::Multiplicative;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Multiplicative::ISA = qw(
        Language::Axbasic::Expression
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Paraphrased from Language::Basic:
        # An multiplicative expression is a set of unary expressions connected by '*' or '/'
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of the line's token group
        #
        # Optional arguments
        #   $maybeBoolean   - Set to 'maybe_boolean' or 'undef'
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Otherwise returns either the blessed reference to this object, or the blessed reference
        #       to a LA::Expression::Boolean object

        my ($class, $scriptObj, $tokenGroupObj, $maybeBoolean, $check) = @_;

        # Local variables
        my (
            $expression, $token,
            @expList, @opList,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $tokenGroupObj || ! defined $scriptObj
            || (defined $maybeBoolean && $maybeBoolean ne 'maybe_boolean')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Test the expression to see if it evaluates to a simple Boolean value. If $maybeBoolean is
        #   set, return the Boolean value; otherwise Boolean values constitute an error
        $expression
            = Language::Axbasic::Expression::Unary->new($scriptObj, $tokenGroupObj, $maybeBoolean);

        if (! defined $expression) {

            return undef;

        } elsif ($expression->isa('Language::Axbasic::Expression::Boolean')) {

            if ($maybeBoolean) {

                return $expression;

            } else {

                return $scriptObj->setError(
                    'expected_non-boolean_expression',
                    $class . '->new',
                );
            }
        }

        # The while loop is necessary in case we have an expression like 1 * 2 * 3
        # It will effectively evaluate the *, / operators left to right
        push (@expList, $expression);

        # An arithmetic expression is a set of multiplicative expressions connected by plus or minus
        #   signs. Convert the expression into a series of multiplicative expressions and
        #   corresponding operators (we already have the first multiplicative expression in the
        #   sequence, $expList[0], so the first token to look for is an operator)
        do {

            $token = $tokenGroupObj->shiftTokenIfCategory('multiplicative_operator');

            if (defined $token) {

                # Push the operator (represented by $token) and the expression that follows it into
                #   the lists @opList and @expList
                push (@opList, $token->tokenText);

                $expression = Language::Axbasic::Expression::Unary->new($scriptObj, $tokenGroupObj);
                if (! defined $expression) {

                    return undef;

                } elsif ($expression->isa('Language::Axbasic::Expression::Boolean')) {

                    return $scriptObj->setError(
                        'expected_non-boolean_expression',
                        $class . '->new',
                    );
                }

                push (@expList, $expression);
            }

        } until (! defined $token);

        # If there's only one unary expression, don't bother creating a multiplicative expression
        #   object. Just return the unary expression. (This will definitely happen in $expression
        #   is a string)
        if (! @opList) {

            return $expression;
        }

        # Otherwise, create an multiplicative expression object

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

            expList                     => \@expList,
            opList                      => \@opList,
        };

        bless $self, $class;
        # Bless to LA::Expression::String or ::Numeric
        $self->setReturnType($expression);

        return $self;
    }

    ##################
    # Methods

#   sub evaluate {}     # Each subclass must have its own ->evaluate

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub expList
        { my $self = shift; return @{$self->{expList}}; }
    sub opList
        { my $self = shift; return @{$self->{opList}}; }
}

{ package Language::Axbasic::Expression::Multiplicative::String;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Multiplicative::String::ISA = qw(
        Language::Axbasic::Expression::Multiplicative
        Language::Axbasic::Expression::String
    );

    # Paraphrased from Language::Basic:
    # There cannot possibly a LA::Expression::Multiplicative::String
    # LA::Expression::Multiplicative->new will just return a LA::Expression::Unary, since there are
    #   no string multiplying operators to find
}

{ package Language::Axbasic::Expression::Multiplicative::Numeric;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Multiplicative::Numeric::ISA = qw(
        Language::Axbasic::Expression::Multiplicative
        Language::Axbasic::Expression::Numeric
    );

    ##################
    # Constructors

#   sub new {}          # Each subclass must have its own ->new

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        # Sub-class of LA::Expression::Multiplicative whose return type has been set to 'Numeric'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Otherwise returns the value of the expression, $exp

        my ($self, $check) = @_;

        # Local variables
        my (
            $obj, $expression, $operator, $nextExpression,
            @expList, @opList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Import the lists of expressions and operators
        @expList = $self->expList;
        @opList = $self->opList;

        # Evaluate the first expression, than add each successive operator-expression pair
        $obj = shift @expList;
        $expression = $obj->evaluate();
        if (! defined $expression) {

            return undef;
        }

        # Need to check that $expression is numeric, or we'll get a funny Perl error when we try to
        #   multiply/divide it
        # N.B. We don't the remaining expressions in @expList because, as described in the
        #   opening comments for LA::Expression::Multiplicative::String, there are no string
        #   multiplications - a LA::Expression::Unary is returned instead
        if (! Scalar::Util::looks_like_number($expression)) {

            return $self->scriptObj->setError(
                'type_mismatch_error',
                $self->_objClass . '->evaluate',
            );
        }

        while ($operator = shift @opList) {

            $obj = shift @expList;
            $nextExpression = $obj->evaluate();
            if (! defined $nextExpression || ! Scalar::Util::looks_like_number($nextExpression)) {

                return undef;
            }

            if ($operator eq '*') {

                $expression = $expression * $nextExpression;

            } elsif ($operator eq '/') {

                # Need to check for division by zero
                if ($nextExpression == 0) {

                    return $self->scriptObj->setError(
                        'division_by_zero',
                        $self->_objClass . '->evaluate',
                    );

                } else {

                    $expression = $expression / $nextExpression;
                }

            } elsif ($operator eq '^') {

                $expression = $expression ** $nextExpression;

            } else {

                return $self->scriptObj->setError(
                    'illegal_operator_in_multiplicative_expression',
                    $self->_objClass . '->evaluate',
                );
            }
        }

        # Return the value of the whole expression
        return $expression;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Language::Axbasic::Expression::Unary;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Unary::ISA = qw(
        Language::Axbasic::Expression
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Paraphrased from Language::Basic:
        # A unary expression is a variable, a function, a string or numeric constant, or an
        #   arithmetic expression in parentheses, potentially with a unary minus sign
        # If we're inside a relational expression, then a parenthetical expression may be either
        #   Boolean or non-Boolean. Otherwise, it must be non-Boolean
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of the line's token group
        #
        # Optional arguments
        #   $maybeBoolean   - Set to 'maybe_boolean' or 'undef'
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Otherwise returns either the blessed reference to this object, or the blessed reference
        #       to a subclass object

        my ($class, $scriptObj, $tokenGroupObj, $maybeBoolean, $check) = @_;

        # Local variables
        my ($obj, $unary, $token);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $tokenGroupObj || ! defined $scriptObj
            || (defined $maybeBoolean && $maybeBoolean ne 'maybe_boolean')
            || defined $check
        ) {
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

            # The expression, stored by $self->new and retrieved by $self->evaluate
            expression                  => undef,
            # Flag set to TRUE if this expression contains a parenthesised expression (set to
            #   FALSE if not)
            nestedFlag                  => FALSE,
            # Set to TRUE if this expression has a unary minus in front of it (set to FALSE if not)
            unaryMinusFlag              => FALSE,
        };

        # Is there a unary minus in the expression?
        if (defined $tokenGroupObj->shiftMatchingToken('-')) {

            $self->{'unaryMinusFlag'} = TRUE;
        }

        # If a parenthesis is found, (recursively) parse what's inside
        # If $maybeBoolean is set, then a parenthesised expression might be a Boolean expression, so
        #   call LA::Expression::LogicalOr (highest level Boolean expression)
        # However, in most cases, it'll be a non-Boolean, so call with 'maybe_arithmetic' flag,
        #   which tells LA::Expression::LogicalOr not to be surprised if it finds an arithmetic
        #   expression
        if (defined $tokenGroupObj->shiftTokenIfCategory('left_paren')) {

            $self->{'nestedFlag'} = TRUE;

            # Recursively parse what's inside the parentheses
            $obj = Language::Axbasic::Expression::LogicalOr->new(
                $scriptObj,
                $tokenGroupObj,
                'maybe_arithmetic',
            );

            if (! defined $obj) {

                return undef;
            }

            # Look for the corresponding right parenthesis
            if (! defined $tokenGroupObj->shiftTokenIfCategory('right_paren')) {

                return $scriptObj->setError(
                    'mismatched_parentheses_error',
                    $class . '->new',
                );
            }

            # If we found a Boolean, make sure we're allowed to have one
            if ($obj->isa('Language::Axbasic::Expression::Boolean') && ! $maybeBoolean) {

                return $scriptObj->setError(
                    'expected_non-boolean_expression',
                    $class . '->new',
                );

            } else {

                $unary = $obj;
            }

        # However, if it's a string or numeric function...
        } elsif (
            defined (
                $obj = Language::Axbasic::Expression::Function->new($scriptObj, $tokenGroupObj)
            )
        ) {
            $unary = $obj;

        # ... or a string or numeric variable...
        } elsif (
            defined (
                $obj = Language::Axbasic::Expression::Lvalue->new($scriptObj, $tokenGroupObj)
            )
        ) {
            $unary = $obj;

        # ... or a string or numeric constant...
        } elsif (
            defined (
                $obj = Language::Axbasic::Expression::Constant->new($scriptObj, $tokenGroupObj)
            )
        ) {
            $unary = $obj;

        # ...or if it's something else, that's an error
        } else {

            $token = $tokenGroupObj->lookAhead();
            if (defined $token) {

                return $scriptObj->setError(
                    'missing_or_illegal_expression',
                    $class . '->new',
                );

            } else {

                return $scriptObj->setError(
                    'expected_unary_expression',
                    $class . '->new',
                );
            }
        }

        # If it's just an Lvalue that's not nested or minused, we can just return the Lvalue object,
        #   rather than making a unary out if it
        if (! $self->{nestedFlag} && ! $self->{unaryMinusFlag}) {

            return $unary;
        }

        # Otherwise, save the expression as an IV, and bless the object to a
        #   LA::Expression::Unary::String, ::Numeric or ::Boolean
        $self->{'expression'} = $unary;
        bless $self, $class;

        # Bless to LA::Expression::String or ::Numeric
        $self->setReturnType($self->expression);

        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the value of the expression, $value

        my ($self, $check) = @_;

        # Local variables
        my $value;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Import the saved expression and evaluate it
        $value = $self->expression->evaluate();

        # Apply the unary minus, if set
        if ($self->unaryMinusFlag) {

            $value = -$value;
        }

        return $value;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub expression
        { $_[0]->{expression} }
    sub nestedFlag
        { $_[0]->{nestedFlag} }
    sub unaryMinusFlag
        { $_[0]->{unaryMinusFlag} }
}

{ package Language::Axbasic::Expression::Unary::Numeric;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Unary::Numeric::ISA = qw(
        Language::Axbasic::Expression::Unary
        Language::Axbasic::Expression::Numeric
    );

    # $self->evaluate is inherited from LA::Expression::Unary, since it's the same for ::Numeric,
    #   ::String and ::Boolean
}

{ package Language::Axbasic::Expression::Unary::String;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Unary::String::ISA = qw(
        Language::Axbasic::Expression::Unary
        Language::Axbasic::Expression::String
    );

    # $self->evaluate is inherited from LA::Expression::Unary, since it's the same for ::Numeric,
    #   ::String and ::Boolean
}

{ package Language::Axbasic::Expression::Unary::Boolean;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Unary::Boolean::ISA = qw(
        Language::Axbasic::Expression::Unary
        Language::Axbasic::Expression::Boolean
    );

    # $self->evaluate is inherited from LA::Expression::Unary, since it's the same for ::Numeric,
    #   ::String and ::Boolean
}

{ package Language::Axbasic::Expression::Constant;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Constant::ISA = qw(
        Language::Axbasic::Expression
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # A string or a numeric constant like "17" or 32.4
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of the line's token group
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns either a LA::Expression::Constant:: subclass, or 'undef'

        my ($class, $scriptObj, $tokenGroupObj, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $tokenGroupObj
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Return a subclass, or return 'undef'
        $obj = Language::Axbasic::Expression::Constant::Numeric->new($scriptObj, $tokenGroupObj);
        if ($obj) {

            return $obj;

        } else {

            $obj = Language::Axbasic::Expression::Constant::String->new($scriptObj, $tokenGroupObj);
            if ($obj) {
                return $obj;
            } else {
                return undef;
            }
        }
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        # NB Nothing appears to set $self->expression
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the value of $self->expression

        my ($self, $check) = @_;

        # Local variables
        my $value;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Evaluate the constant, and return it
        return $self->expression->evaluate;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Language::Axbasic::Expression::Constant::Numeric;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Constant::Numeric::ISA = qw(
        Language::Axbasic::Expression::Constant
        Language::Axbasic::Expression::Numeric
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of the line's token group
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns either a LA::Expression::Constant::Numeric object, or 'undef'

        my ($class, $scriptObj, $tokenGroupObj, $check) = @_;

        # Local variables
        my $token;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $tokenGroupObj
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        $token = $tokenGroupObj->shiftTokenIfCategory('numeric_constant');
        if (! defined $token) {

            return undef;
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

            # The expression, retrieved by LA::Expression::Constant
            expression                  => undef,
            # The value of the expression, stored by $self->new and retrieved by $self->evaluate
            value                       => $token->tokenText + 0,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns $self->value

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Return the stored value
        return $self->value;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub expression
        { $_[0]->{expression} }
    sub value
        { $_[0]->{value} }
}

{ package Language::Axbasic::Expression::Constant::String;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Constant::String::ISA = qw(
        Language::Axbasic::Expression::Constant
        Language::Axbasic::Expression::String
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of the line's token group
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns either a LA::Expression::Constant::String object, or 'undef'

        my ($class, $scriptObj, $tokenGroupObj, $check) = @_;

        # Local variables
        my ($token, $tokenText);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $tokenGroupObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        $token = $tokenGroupObj->shiftTokenIfCategory('string_constant');
        if (! defined $token) {

            return undef;

        } else {

            $tokenText = $token->tokenText;
            # Remove the double quotes "..." from the token, to get the actual string constant
            #   itself
            $tokenText =~ s/^"(.*?)"/$1/;
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

            # The expression, retrieved by LA::Expression::Constant
            expression                  => undef,
            # The value of the expression, stored by $self->new and retrieved by $self->evaluate
            value                       => $tokenText,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns $self->value

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Return the stored value
        return $self->value;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub expression
        { $_[0]->{expression} }
    sub value
        { $_[0]->{value} }
}

{ package Language::Axbasic::Expression::Lvalue;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Lvalue::ISA = qw(
        Language::Axbasic::Expression
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Paraphrased from Language::Basic:
        # A settable expression: a variable, X, or one cell in an array, A(17, Q)
        # The ->variable method returns the actual LB::Variable::Scalar object referenced by this
        #   Lvalue
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of the line's token group
        #
        # Optional arguments
        #   $specialFlag    - TRUE when called by a DIM or REDIM statement, in which case we attempt
        #       to extract an LA::Expression::SpecialArgList after the identifier. FALSE (or
        #       'undef') when called by anything else, in which case we attempt to extract a normal
        #       LA::Expression::SpecialArgList after the identifier
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Otherwise returns either a LA::Expression::Lvalue:: subclass, or 'undef'

        my ($class, $scriptObj, $tokenGroupObj, $specialFlag, $check) = @_;

        # Local variables
        my ($token, $varName, $argListObj, $varObj);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $tokenGroupObj
            || defined $check
        ) {
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

            # The variable (identifier) name (e.g. A, a$, array)
            varName                     => undef,
            # For an identifier that refers to a cell in an array (e.g. A(5,6) ), blessed reference
            #   to the LA::Expression::Arglist object (representing the (5,6) )
            argListObj                  => undef,
            # Blessed reference of the corresponding LA::Variable::Scalar::xxx or
            #   LA::Variable::Array::xxx object
            varObj                      => undef,
        };

        # Extract a token comprising a whole variable identifier (e.g. A, a$, array)
        $token = $tokenGroupObj->shiftTokenIfCategory('identifier');
        if (! defined $token) {

            # Not an identifier
            return undef;
        }

        # Import the variable name from the token (ie A, a$, array)
        $varName = $token->tokenText;
        if ($scriptObj->ivExists('funcArgHash', $varName)) {

            # Using names of intrinsic functions as variables is not allowed (using names of
            #   defined functions is allowed, but the variable's value can never be retrieved)
            return undef;
        }

        # Test whether the variable refers to a cell in an array (e.g. A(5,6) ) by trying to extract
        #   an argument list
        if (! $specialFlag) {

            $argListObj = Language::Axbasic::Expression::ArgList->new(
                $scriptObj,
                $tokenGroupObj,
            );

        } else{

            $argListObj = Language::Axbasic::Expression::SpecialArgList->new(
                $scriptObj,
                $tokenGroupObj,
            );
        }

        # Lookup the variable name in variable storage (and create it, if it doesn't exist)
        $varObj = Language::Axbasic::Variable->lookup($scriptObj, $varName, $argListObj);
        if (! defined $varObj) {

            return undef;

        } else {

            # Store these values so that $self->evaluate can retrieve them
            $self->{'varName'} = $varName;
            $self->{'argListObj'} = $argListObj;
            $self->{'varObj'} = $varObj;
        }

        bless $self, $class;
        # Is this a string or numeric lvalue?
        $self->setReturnType($varObj);

        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the cell doesn't seem to exist
        #   Otherwise returns the value of the expression, $self->variable->value

        my ($self, $check) = @_;

        # Local variables
        my $var;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Check the specified cell actually exists, before asking it for the variable it holds
        $var = $self->variable();
        if (! defined $var) {

            return undef;

        } else {

            # This automatically gets the correct cell, if necessary
            return $var->value;
        }
    }

    sub variable {

        # Called by various statements which need to look up a variable stored in a particular cell
        #   of an array
        # Returns a blessed reference to a variable object. If it's a scalar, returns that object;
        #   if it's an array, returns the object specified by the argument list
        #   (e.g. the value of array(5,6) )
        # Note that this function always returns a LA::Variable::Scalar object. If the variable in
        #   this expression is an array, it returns one cell from the array
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the blessed reference of the variable object

        my ($self, $check) = @_;

        # Local variables
        my $varObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->variable', @_);
        }

        # If the variable has an argument list ($self->argListObj), evaluate each Arithemetic
        #   expression in the argument list, and get the specified cell from the array
        if (defined $self->argListObj) {

            $varObj = $self->varObj->getCell($self->argListObj->evaluate());

        } else {

            $varObj = $self->varObj;
        }

        return $varObj;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub varName
        { $_[0]->{varName} }
    sub argListObj
        { $_[0]->{argListObj} }
    sub varObj
        { $_[0]->{varObj} }
}

{ package Language::Axbasic::Expression::Lvalue::Numeric;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Lvalue::Numeric::ISA = qw(
        Language::Axbasic::Expression::Lvalue
        Language::Axbasic::Expression::Numeric
    );
}

{ package Language::Axbasic::Expression::Lvalue::String;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Lvalue::String::ISA = qw(
        Language::Axbasic::Expression::Lvalue
        Language::Axbasic::Expression::String
    );
}

{ package Language::Axbasic::Expression::Subroutine;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Subroutine::ISA = qw(
        Language::Axbasic::Expression
    );

    # Sub-classes
    {
        package Language::Axbasic::Expression::Subroutine::Numeric;
        package Language::Axbasic::Expression::Subroutine::String;
    }

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::sub->parse
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of string being parsed
        #
        # Return values
        #   'undef' on improper arguments, or if the first token in $tokenGroupObj isn't a true
        #       subroutine name (could be an lvalue)
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $tokenGroupObj, $check) = @_;

        # Local variables
        my ($token, $tokenText, $subObj, $argListObj);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $tokenGroupObj || defined $check
        ) {
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

            # The LA::Subroutine object handling this function
            subObj                      => undef,
            # Reference to the list of arguments
            argListObj                  => undef,
        };

        # Don't extract the first token in the token group if it's not a true subroutine name (could
        #   be an lvalue)
        $token = $tokenGroupObj->lookAhead();
        if (! defined $token || $token->category ne 'identifier') {

            return undef;

        } else {

            $tokenText = $token->tokenText;
        }

        # Compare the proposed subroutine name, $tokenText, with the list of existing keywords and
        #   subroutine names, and also filter out any invalid names
        if (
            defined $scriptObj->ivFind('keywordList', $tokenText)
            || ! ($tokenText =~ m/^[A-Z][A-Z0-9_]*$/i)
        ) {
            return $scriptObj->setError(
                'illegal_subroutine_name',
                $class . '->new',
            );

        } elsif ($scriptObj->ivExists('subNameHash', $tokenText)) {

            return $scriptObj->setError(
                'redefined_subroutine_error',
                $class . '->new',
            );
        }

        # Create a LA::Subroutine for this subroutine, which adds a new key-value pair to
        #   $scriptObj->subNameHash
        $subObj = Language::Axbasic::Subroutine->new(
            $scriptObj,
            $tokenText,     # Subroutine name
        );

        $self->{'subObj'} = $subObj;

        # Now we know that the first token in the token group is a subroutine, extract it
        $tokenGroupObj->shiftToken();

        # Extract the argument list. The TRUE argument means that an empty token group is treated
        #   the same an empty arglist, in this case (e.g. 'SUB hello ()' and 'SUB hello' are both
        #   acceptable)
        $argListObj
            = Language::Axbasic::Expression::ArgList->new($scriptObj, $tokenGroupObj, TRUE);
        if (! defined $argListObj) {

            return $scriptObj->setError(
                'missing_or_invalid_argument_list',
                $class . '->new',
            );
        }

        # Declare the number and type of arguments in the subroutine...
        $subObj->set_argListObj($argListObj);
        # ...and save a local copy
        $self->{'argListObj'} = $argListObj;

        # Bless the object into existence
        bless $self, $class;
        # Is it a String or Numeric Subroutine?
        $self->setReturnType($subObj);

        return $self;
    }

    ##################
    # Methods

#   sub evaluate {}     # Each subclass must have its own ->evaluate

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub subObj
        { $_[0]->{subObj} }
    sub argListObj
        { $_[0]->{argListObj} }
}

{ package Language::Axbasic::Expression::Subroutine::Numeric;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    # Set ISA for 'return type' classes
    @Language::Axbasic::Expression::Subroutine::Numeric::ISA = qw(
        Language::Axbasic::Expression::Subroutine
        Language::Axbasic::Expression::Numeric
    );
}

{ package Language::Axbasic::Expression::Subroutine::String;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    # Set ISA for 'return type' classes
    @Language::Axbasic::Expression::Subroutine::String::ISA = qw(
        Language::Axbasic::Expression::Subroutine
        Language::Axbasic::Expression::String
    );
}

{ package Language::Axbasic::Expression::Function;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Function::ISA = qw(
        Language::Axbasic::Expression
    );

    # Sub-classes
    {
        package Language::Axbasic::Expression::Function::Numeric;
        package Language::Axbasic::Expression::Function::String;
    }

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::def->parse
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of string being parsed
        #
        # Optional arguments
        #   $defining       - If defined (actually set to the string 'defining_flag') we're in a
        #                       DEF statement, so if the function doesn't exist, we should create it
        #                       rather than returning 'undef'. Otherwise set to 'undef'
        #
        # Return values
        #   'undef' on improper arguments, or if the first token in $tokenGroupObj isn't a true
        #       function name (could be an lvalue)
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $tokenGroupObj, $defining, $check) = @_;

        # Local variables
        my (
            $token, $tokenText, $funcObj, $argListObj,
            @args,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $tokenGroupObj
            || (defined $defining && $defining ne 'defining_flag')
            || defined $check
        ) {
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

            # The LA::Function object handling this function
            funcObj                     => undef,
            # Reference to the list of arguments
            argListObj                  => undef,
        };

        # Don't extract the first token in the token group if it's not a true function name (could
        #   be an lvalue)
        # NB To preserve backwards compatibility with True BASIC, 'angle' can be either a keyword
        #   or a built-in function. This is true for all 'weak' keywords, but 'angle' is the only
        #   built-in function that is also a keyword
        $token = $tokenGroupObj->lookAhead();
        if (! defined $token) {

            return undef;

        } elsif (
            $token->category eq 'keyword'
            && $scriptObj->ivExists('weakKeywordHash', $token->tokenText)
        ) {
            # Change the token type; it's the built-in function Angle(), not the keyword ANGLE
            $token->{category} = 'identifier';
            $tokenText = $token->tokenText;

        } elsif ($token->category ne 'identifier') {

            return undef;

        } else {

            $tokenText = $token->tokenText;
        }

        # Look up the function name. If it doesn't exist, the word is a variable or something
        # Alternatively, if $defining is defined, then we're in a 'def' statement and should
        #   create the function
        if (defined $defining) {

            $funcObj = Language::Axbasic::Function::Defined->new($scriptObj, $tokenText);

        } else {

            if (! $scriptObj->ivExists('funcNameHash', $tokenText)) {

                # Not a function, so must be a variable name or something
                return undef;

            } else {

                $funcObj = $scriptObj->ivShow('funcNameHash', $tokenText);
            }
        }

        $self->{'funcObj'} = $funcObj;

        # Now we know that the first token in the token group is a function, extract it
        $tokenGroupObj->shiftToken();

        # Read and extract the argument list. If we're defining the function...
        if (defined $defining) {

            # Empty parentheses aren't allowed! (and whitespace has been removed by lexing)
            $token = $tokenGroupObj->shiftTokenIfCategory('left_paren');
            if (! defined $token) {

                return $scriptObj->setError(
                    'function_called_without_arguments',
                    $class . '->new',
                );
            }

            # Extract all the arguments (separated by commas, if there is more than one)
            do {

                my $lvalueObj
                    = Language::Axbasic::Expression::Lvalue->new($scriptObj, $tokenGroupObj);

                if (! defined $lvalueObj) {
                    return undef;
                } else {
                    push (@args, $lvalueObj);
                }

            } while ($tokenGroupObj->shiftMatchingToken(','));

            $token = $tokenGroupObj->shiftTokenIfCategory('right_paren');
            if (! defined $token) {

                return $scriptObj->setError(
                    'mismatched_parentheses_error',
                    $class . '->new',
                );
            }

            # Declare the number and type of arguments in the function
            if (! $funcObj->declare(@args)) {

                return $scriptObj->setDebug(
                    'Couldn\'t declare function arguments',
                    $class . '->new',
                );
            }

        # Or if the function is already defined...
        } else {

            # Pre-defined functions are allowed to have no arguments, in some cases. We might have
            #   to extract an arglist, or not
            # e.g. These statements are both valid, because Pi() expects no arguments
            #   PRINT Pi()
            #   PRINT Pi
            # e.g. These statements are not valid, because Int() expects an argument
            #   PRINT Int()
            #   PRINT Int
            $argListObj = Language::Axbasic::Expression::ArgList->new($scriptObj, $tokenGroupObj);

            if (! defined $argListObj) {

                if (! $scriptObj->ivExists('funcArgHash', $tokenText)) {

                    # A custom function, created in a DEF statement, has been called without a
                    #   parseable arglist
                    return $scriptObj->setError(
                        'function_called_without_arguments',
                        $class . '->new',
                    );

                } elsif ($scriptObj->ivShow('funcArgHash', $tokenText)) {

                    # A pre-defined function that expects at least one argument, but has been called
                    #   without a parseable arglist
                    return $scriptObj->setError(
                        'wrong_number_of_arguments',
                        $class . '->new',
                    );
                }
            }

            if (
                ! $scriptObj->ivExists('funcArgHash', $tokenText)                     # Custom
                || ( $argListObj && $scriptObj->ivShow('funcArgHash', $tokenText) )   # Pre-defined
            ) {
                # A parseable arglist has been found (even if it is empty)
                # Check that the arguments are of the correct number and type
                if (! $funcObj->checkArgs($argListObj)) {

                    return $scriptObj->setError(
                        'function_called_with_invalid_arguments',
                        $class . '->new',
                    );

                } else {

                    $self->{'argListObj'} = $argListObj;
                }
            }

        }

        # Bless the object into existence
        bless $self, $class;
        # Is it a String or Numeric Function?
        $self->setReturnType($funcObj);

        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Can be called by anything
        # Evaluates the function (the LA::Function object stored in $self->funcObj) using the
        #   arguments stored in $self->argRefList
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error evaluating the function
        #   Otherwise returns the result of evaluating the function

        my ($self, $check) = @_;

        # Local variables
        my (
            $result,
            @args,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Evaluate the arguments in the argument list (if there are any)
        if ($self->argListObj) {

            @args = $self->argListObj->evaluate();
        }

        # Evaluate the function using those arguments
        $result = $self->funcObj->evaluate(@args);

        if (! defined $result) {

            # If the function returned 'undef', there was an error (e.g. trying to take the square
            #   root of a negative number)
            return $self->scriptObj->setError(
                'undefined_function_error',
                $self->_objClass . '->evaluate',
            );

        } else {

            return $result;
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub funcObj
        { $_[0]->{funcObj} }
    sub argListObj
        { $_[0]->{argListObj} }
}

{ package Language::Axbasic::Expression::Function::Numeric;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    # Set ISA for 'return type' classes
    @Language::Axbasic::Expression::Function::Numeric::ISA = qw(
        Language::Axbasic::Expression::Function
        Language::Axbasic::Expression::Numeric
    );
}

{ package Language::Axbasic::Expression::Function::String;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    # Set ISA for 'return type' classes
    @Language::Axbasic::Expression::Function::String::ISA = qw(
        Language::Axbasic::Expression::Function
        Language::Axbasic::Expression::String
    );
}

{ package Language::Axbasic::Expression::ArgList;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::ArgList::ISA = qw(
        Language::Axbasic::Expression
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of the line's token group
        #
        # Optional arguments
        #   $implicitFlag   - If TRUE, a non-existent arglist is acceptable, i.e. a token group
        #                       with no more tokens is treated the same as an empty arglist token,
        #                       namely '()'. If FALSE or 'undef', an empty arglist (at the very
        #                       least) is expected
        #
        # Return values
        #   'undef' on improper arguments
        #   Returns either the LA::Expression::Arglist created, or 'undef'

        my ($class, $scriptObj, $tokenGroupObj, $implicitFlag, $check) = @_;

        # Local variables
        my (
            $token,
            @args,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $tokenGroupObj || defined $check
        ) {
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

            # The arguments of the arglist, stored as a Perl list
            argList                     => [],
        };

        if (! $implicitFlag || $tokenGroupObj->lookAhead()) {

            # The arglist, if explicitly specified, must start with a left parenthesis
            $token = $tokenGroupObj->shiftTokenIfCategory('left_paren');
            if (! defined $token) {

                # Not an arglist
                return undef;
            }

            # Check for an empty arglist
            $token = $tokenGroupObj->shiftTokenIfCategory('right_paren');
            if (! defined $token) {

                # Go through the list, extracting arguments
                do {

                    my $arg = Language::Axbasic::Expression::Arithmetic->new(
                        $scriptObj,
                        $tokenGroupObj,
                    );

                    if (! defined $arg) {

                        return undef;
                    }

                    push (@args, $arg);

                } while ($tokenGroupObj->shiftMatchingToken(','));

                # The arglist must end with a right parenthesis
                $token = $tokenGroupObj->shiftTokenIfCategory('right_paren');
                if (! defined $token) {

                    return $scriptObj->setError(
                        'mismatched_parentheses_error',
                        $class . '->new',
                    );
                }
            }

            # Store the arglist, and bless this object
            $self->{'argList'} = \@args;
        }

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of values from the arglist. The values will be 'undef' for any
        #       expression that could not be evaluated; it's up to the calling function to check for
        #       that

        my ($self, $check) = @_;

        # Local variables
        my (@emptyList, @values);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Evaluate each argument, transforming the arglist into a list of values
        foreach my $arg ($self->argList) {

            push (@values, $arg->evaluate());
        }

        # Return the list of values
        return @values;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub argList
        { my $self = shift; return @{$self->{argList}}; }
}

{ package Language::Axbasic::Expression::SpecialArgList;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::SpecialArgList::ISA = qw(
        Language::Axbasic::Expression
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        # A modified form of LA::Expression::ArgList, for use with DIM statements
        # The arglist can be a simple list of expressions (A, B, C...). Each expression is expected
        #   to be an integer
        # Any of the expressions can be replaced with a pair of numeric expressions representing the
        #   lower and upper bounds of the dimension. The pair is expressed in the form 'lower TO
        #   upper'. Both expressions are expected to be integers, and 'lower' is expected to be less
        #   than 'upper'
        # Thus we could use any of the following special arglists in a DIM statement:
        #
        #   DIM data (2, 5, 10)
        #   DIM data (0 TO 2, 0 TO 5, 10 TO 20)
        #   DIM data (2, 5, 10 TO 20)
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $tokenGroupObj  - Blessed reference of the line's token group
        #
        # Return values
        #   'undef' on improper arguments
        #   Returns either the LA::Expression::Arglist created, or 'undef'

        my ($class, $scriptObj, $tokenGroupObj, $check) = @_;

        # Local variables
        my (
            $token,
            @args,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $tokenGroupObj || defined $check
        ) {
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

            # The arguments of the special arglist. Each single argument (or pair of arguments) is
            #   stored as a list reference
            argList                     => [],
        };

        # The special arglist must start with a left parenthesis
        $token = $tokenGroupObj->shiftTokenIfCategory('left_paren');
        if (! defined $token) {

            # Not an arglist
            return undef;
        }

        # Check for an empty arglist
        $token = $tokenGroupObj->shiftTokenIfCategory('right_paren');
        if (! defined $token) {

            # Go through the list, extracting single arguments orpairs of arguments
            do {

                my (
                    $arg, $arg2,
                    @miniList,
                );

                $arg = Language::Axbasic::Expression::Arithmetic->new(
                    $scriptObj,
                    $tokenGroupObj,
                );

                if (! defined $arg || ! (ref ($arg) =~ m/Numeric/)) {
                    return undef;
                } else {
                    push (@miniList, $arg);
                }

                if (defined $tokenGroupObj->shiftMatchingToken('to')) {

                    $arg2 = Language::Axbasic::Expression::Arithmetic->new(
                        $scriptObj,
                        $tokenGroupObj,
                    );

                    if (! defined $arg2 || ! (ref ($arg2) =~ m/Numeric/)) {
                        return undef;
                    } else {
                        push (@miniList, $arg2);
                    }
                }

                push (@args, \@miniList);

            } while ($tokenGroupObj->shiftMatchingToken(','));

            # The arglist must end with a right parenthesis
            $token = $tokenGroupObj->shiftTokenIfCategory('right_paren');
            if (! defined $token) {

                return $scriptObj->setError(
                    'mismatched_parentheses_error',
                    $class . '->new',
                );
            }
        }

        # Store the arglist, and bless this object
        $self->{'argList'} = \@args;


        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise evaluates the expressions in the arglist, and returns them as a list with the
        #       same structure (a list of list references, with each list reference containing
        #       either a single value or a pair of values). The value(s) will be 'undef' for any
        #       expression that could not be evaluated; it's up to the calling function to check for
        #       that

        my ($self, $check) = @_;

        # Local variables
        my (@emptyList, @values);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Evaluate each expression, transforming the arglist into a list of values
        foreach my $listRef ($self->argList) {

            my @miniList;

            foreach my $arg (@$listRef) {

                push (@miniList, $arg->evaluate());
            }

            push (@values, \@miniList);
        }

        # Return the list of values
        return @values;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub argList
        { my $self = shift; return @{$self->{argList}}; }
}

{ package Language::Axbasic::Expression::LogicalOr;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::LogicalOr::ISA = qw(
        Language::Axbasic::Expression::Boolean
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Paraphrased from Language::Basic:
        # Booleans don't care whether the stuff in them is String or Numeric, so no sub-packages are
        #   needed
        #
        # A set of LogicalAnd expressions connected by the 'or' operator
        #
        # In Axbasic, Boolean expressions can't contain non-Boolean expressions except for
        #   Relational expressions (which have two Arithmetic expressions separated by a Relational
        #   operator)
        # However, parentheses can confuse things.
        # LA::Expression::Unary is one of:
        #   (1) A constant, variable, function, etc.
        #   (2) (Arithmetic Exp.)
        #   (3) (Logical Or)
        # LA::Expression::Unary::new calls LA::Expression::LogicalOr->new with 'maybe_arithmetic'
        #   sometimes, to tell LA::Expression::LogicalOr that if it finds a (parenthesised)
        #   non-Boolean expression, it's just case #2 above. (Otherwise, a non-Boolean subexpression
        #   is an error.)
        #
        # Expected arguments
        #   $scriptObj          - Blessed reference to the parent LA::Script
        #   $tokenGroupObj      - Blessed reference of the line's token group
        #
        # Optional arguments
        #   $maybeArithmetic    - Set to 'maybe_arithmetic' or 'undef'
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Otherwise returns either the blessed reference to this object, or a LA::Expression or
        #       'undef'

        my ($class, $scriptObj, $tokenGroupObj, $maybeArithmetic, $check) = @_;

        # Local variables
        my (
            $expression,
            @expList,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $tokenGroupObj || ! defined $scriptObj
            || (defined $maybeArithmetic && $maybeArithmetic ne 'maybe_arithmetic')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Don't bother creating a LogicalOr object if the expression evaluates to a boolean value;
        #   just return the LogicalAnd object instead
        $expression = Language::Axbasic::Expression::LogicalAnd->new(
            $scriptObj,
            $tokenGroupObj,
            $maybeArithmetic,
        );

        if (! defined $expression) {

            return undef;

        } elsif (! $expression->isa('Language::Axbasic::Expression::Boolean')) {

            if ($maybeArithmetic) {

                return $expression;

            } else {

                return $scriptObj->setError(
                    'expected_boolean_expression',
                    $class . '->new',
                );
            }
        }

        # Add the first expression to @expList, and then add any following pairs of operators and
        #   expressions
        push (@expList, $expression);

        while (defined $tokenGroupObj->shiftMatchingToken('or')) {

            $expression
                = Language::Axbasic::Expression::LogicalAnd->new($scriptObj, $tokenGroupObj);

            if (! defined $expression) {

                return undef;

            } elsif (! $expression->isa('Language::Axbasic::Expression::Boolean')) {

                return $scriptObj->setError(
                    'expected_boolean_expression',
                    $class . '->new',
                );
            }

            push (@expList, $expression);
        }

        # Don't bother making a LogicalOr object if there's just one LogicalAnd
        if (@expList == 1) {

            return $expression;
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

            # The arguments from the arglist, stored as a Perl list
            expList                     => \@expList,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the value of the expression list, $self->expList

        my ($self, $check) = @_;

        # Local variables
        my (
            $obj, $expression, $nextExpression,
            @expList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Import the stored expression list
        @expList = $self->expList;

        # Evaluate the first expression in the list
        $obj = shift @expList;
        $expression = $obj->evaluate;
        if (! defined $expression) {

            return undef;
        }

        # Perform logical OR operation on each subsequent expression
        while ($nextExpression = shift @expList) {

            $expression = ($expression || $nextExpression->evaluate);
        }

        # Return the value of the whole logical OR expression list
        return $expression;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub expList
        { my $self = shift; return @{$self->{expList}}; }
}

{ package Language::Axbasic::Expression::LogicalAnd;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::LogicalAnd::ISA = qw(
        Language::Axbasic::Expression::Boolean
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Paraphrased from Language::Basic:
        # Booleans don't care whether the stuff in them is String or Numeric, so no sub-packages are
        #   needed
        #
        # A set of Relational expressions connected by the 'and' operator
        #
        # Expected arguments
        #   $scriptObj          - Blessed reference to the parent LA::Script
        #   $tokenGroupObj      - Blessed reference of the line's token group
        #
        # Optional arguments
        #   $maybeArithmetic    - Set to 'maybe_arithmetic' or 'undef'
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Otherwise returns either the blessed reference to this object, a LA::Expression or
        #       'undef'

        my ($class, $scriptObj, $tokenGroupObj, $maybeArithmetic, $check) = @_;

        # Local variables
        my (
            $expression,
            @expList,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $tokenGroupObj || ! defined $scriptObj
            || (defined $maybeArithmetic && $maybeArithmetic ne 'maybe_arithmetic')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Don't bother creating a LogicalAnd object if the expression evaluates to a boolean value;
        #   just return the Relational object instead
        $expression = Language::Axbasic::Expression::Relational->new(
            $scriptObj,
            $tokenGroupObj,
            $maybeArithmetic,
        );

        if (! defined $expression) {

            return undef;

        } elsif (! $expression->isa('Language::Axbasic::Expression::Boolean')) {

            if ($maybeArithmetic) {

                return $expression;

            } else {

                return $scriptObj->setError(
                    'expected_boolean_expression',
                    $class . '->new',
                );
            }
        }

        # Add the first expression to @expList, and then add any following pairs of operators and
        #   expressions
        push (@expList, $expression);

        while (defined $tokenGroupObj->shiftMatchingToken('and')) {

            $expression
                = Language::Axbasic::Expression::Relational->new($scriptObj, $tokenGroupObj);

            if (! defined $expression) {

                return undef;

            } elsif (! $expression->isa('Language::Axbasic::Expression::Boolean')) {

                return $scriptObj->setError(
                    'expected_boolean_expression',
                    $class . '->new',
                );
            }

            push (@expList, $expression);
        }

        # Don't bother making a LogicalAnd object if there's just one Relational
        if (@expList == 1) {

            return $expression;
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

            # The arguments from the arglist, stored as a Perl list
            expList                     => \@expList,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the value of the expression list, $self->expList

        my ($self, $check) = @_;

        # Local variables
        my (
            $obj, $expression, $nextExpression,
            @expList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Import the stored expression list
        @expList = $self->expList;

        # Evaluate the first expression in the list
        $obj = shift @expList;
        $expression = $obj->evaluate;
        if (! defined $expression) {

            return undef;
        }

        # Perform logical AND operation on each subsequent expression
        while ($nextExpression = shift @expList) {

            $expression = ($expression && $nextExpression->evaluate);
        }

        # Return the value of the whole logical OR expression list
        return $expression;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub expList
        { my $self = shift; return @{$self->{expList}}; }
}

{ package Language::Axbasic::Expression::Relational;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Relational::ISA = qw(
        Language::Axbasic::Expression::Boolean
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::xxx->parse or LA::Statement::xxx->implement
        #
        # Paraphrased from Language::Basic:
        # Usually, an LA::Expression::Relational is just LA::Expression::Arithmetic
        #   Rel. Op. LA::Expression::Arithmetic
        # However, if the first sub-expression in the LA::Expression::Relational is parenthesised,
        #   it could be either
        # (1) (Logical Or Exp.) - e.g. IF (A>B OR C>D) THEN...
        # (2) (Arith. Exp.)     - e.g. IF (A+1)>B THEN...
        # So we call the first LA::Expression::Arithmetic->new with 'maybe_boolean', so that it
        #   knows it may find a Boolean sub-expression
        # Note that in case (1), we don't need to look for a Rel. Op., because
        # IF (A > B OR C > D) > 2 is illegal.
        #
        # Rel. Exp. usually has two expressions in the 'expressions' field, and an operator in the
        #   "operator' field. However, in case (1) above, there will only be one (Boolean)
        #   expression, and no op.
        #
        # Expected arguments
        #   $scriptObj          - Blessed reference to the parent LA::Script
        #   $tokenGroupObj      - Blessed reference of the line's token group
        #
        # Optional arguments
        #   $maybeArithmetic    - Set to 'maybe_arithmetic' or 'undef'
        #
        # Return values
        #   'undef' on improper arguments, or for an error
        #   Returns either the blessed reference to this object, or 'undef'

        my ($class, $scriptObj, $tokenGroupObj, $maybeArithmetic, $check) = @_;

        # Local variables
        my (
            $numericOpRef, $stringOpRef, $type, $token, $op, $transform, $expression,
            $nextExpression, $perlOp,
            @expList,
        );

        # Check for improper arguments
        if (
            ! defined $class || ! defined $tokenGroupObj || ! defined $scriptObj
            || (defined $maybeArithmetic && $maybeArithmetic ne 'maybe_arithmetic')
            || defined $check
        ) {
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

            # Is there a 'not' in the expression? 'undef' if there isn't, otherwise set to the token
            #   containing the 'not'
            notToken                    => undef,
            # The Perl equivalent of the operator
            perlOp                      => undef,
            # What kind of operator it is ('string' or 'numeric')
            perlOpType                  => undef,
            # A list of expressions (max 2), one either side of the operator
            expList                     => [],
        };

        # Is there a 'not' in the expression?
        $token = $tokenGroupObj->shiftMatchingToken('not');
        if (defined $token) {

            $self->{notToken} = $token;
        }

        # Get the first expression
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $scriptObj,
            $tokenGroupObj,
            'maybe_boolean',
        );

        if (! defined $expression) {

            return $scriptObj->setError(
                'illegal_relational_expression',
                    $class . '->new',
            );
        }

        push (@expList, $expression);

        # If we can find a parenthesised Boolean expression, just return it
        # (Don't even look for a relational operator, since that would be illegal)
        if ($expression->isa('Language::Axbasic::Expression::Boolean')) {

            bless $self, $class;
            $self->ivPoke('expList', @expList);

            return $self;
        }

        # Otherwise, read the Relational operator
        $token = $tokenGroupObj->shiftTokenIfCategory('relational_operator');
        if (! defined $token) {

            # Found a parenthesised Arithmetic expression?
            if ($maybeArithmetic) {

                # Don't bother blessing and returning $self
                return $expression;

            } else {

                return $scriptObj->setError(
                    'illegal_relational_expression',
                    $class . '->new',
                );
            }
        }

        $op = $token->tokenText;

        # NB $nextExpression isn't allowed to be Arithmetic, so no $maybeArithmetic arg
        $nextExpression
            = Language::Axbasic::Expression::Arithmetic->new($scriptObj, $tokenGroupObj);

        if (! defined $nextExpression) {

            return $scriptObj->setError(
                'illegal_relational_expression',
                $class . '->new',
            );
        }

        push (@expList, $nextExpression);

        # Convert Axbasic operators to Perl Operators
        $stringOpRef = {
            "="  => "eq",
            ">"  => "gt",
            "<"  => "lt",
            ">=" => "ge",
            "<=" => "le",
            "<>" => "ne",
        };

        $numericOpRef = {
            "="  => "==",
            ">"  => ">",
            "<"  => "<",
            ">=" => ">=",
            "<=" => "<=",
            "<>" => "!=",
        };

        if ($expression->isa('Language::Axbasic::Expression::String')) {

            $transform = $stringOpRef;
            $type = 'string';

        } else {

            $transform = $numericOpRef;
            $type = 'numeric';
        }

        $perlOp = $transform->{$op};
        if (! defined $perlOp) {

            return $scriptObj->setError(
                'illegal_operator_STRING_in_relational_expression',
                $class . '->new()',
                'STRING', $op,
            );
        }

        bless $self, $class;

        # Store the equivalent Perl operator and bless the object into existence
        $self->ivPoke('perlOp', $perlOp);
        $self->ivPoke('perlOpType', $type);
        $self->ivPoke('expList', @expList);

        return $self;
    }

    ##################
    # Methods

    sub evaluate {

        # Called by LA::Statement::xxx->implement
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the value of the expression

        my ($self, $check) = @_;

        # Local variables
        my (
            $expression, $value, $nextExpression, $nextValue, $perlExpression, $finalValue,
            @expList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->evaluate', @_);
        }

        # Import the stored expression list
        @expList = $self->expList;

        # Evaluate the first expression in the list
        $expression = shift @expList;
        $value = $expression->evaluate;

        if (! $expression->isa('Language::Axbasic::Expression::Boolean')) {

            $nextExpression = shift @expList;
            $nextValue = $nextExpression->evaluate();

            # Paraphrased from Language::Basic:
            # We're assuming that Perl eval will get the same result as BASIC would
            # Using \Q in case we say IF a$ = "\", which should really compare with \\
            if ($self->perlOpType eq 'string') {

                $perlExpression = "\"\Q$value\E\" " . $self->perlOp . " \"\Q$nextValue\E\"";

            } elsif ($self->perlOpType eq 'numeric') {

#               # v0.6.042 - removed \E as it was generating Perl warnings
#                $perlExpression = "$value\E " . $self->perlOp . " $nextValue\E";
                $perlExpression = "$value " . $self->perlOp . " $nextValue";
            }

            $finalValue = eval $perlExpression;

        } else {

            # $expression has a nested Boolean in it. There is no $nextExpression
            $finalValue = $value;
        }

        # Apply the 'not' operator, if it was present when $self->parse checked for it
        if ($self->notToken) {

            $finalValue = ! $finalValue;
        }

        return $finalValue;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub perlOp
        { $_[0]->{perlOp} }
    sub perlOpType
        { $_[0]->{perlOpType} }
    sub notToken
        { $_[0]->{notToken} }
    sub expList
        { my $self = shift; return @{$self->{expList}}; }
}

{ package Language::Axbasic::Expression::Numeric;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Numeric::ISA = qw(
        Language::Axbasic::Expression
        Language::Axbasic::Numeric
    );
}

{ package Language::Axbasic::Expression::String;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::String::ISA = qw(
        Language::Axbasic::Expression
        Language::Axbasic::String
    );
}

{ package Language::Axbasic::Expression::Boolean;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Expression::Boolean::ISA = qw(
        Language::Axbasic::Expression
        Language::Axbasic::Boolean
    );
}

# Package must return a true value
1
